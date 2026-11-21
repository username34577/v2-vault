#!/usr/bin/env python3
"""Self-tests for rbxtest.py (the part that runs outside Studio): report validation, saving, comparison
and the exit codes that tell Claude whether a run failed. Standard library only.

    python dev/rbxtest/test_rbxtest.py        (also runs in CI)
"""
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
TOOL = HERE / "rbxtest.py"
ROOT = HERE.parents[1]


def report(status="completed", results=None, suite="local", **extra):
    r = {"schema": 1, "suite": suite, "status": status,
         "results": results if results is not None else [
             {"test": "boot", "check": "map loaded", "status": "PASS"},
             {"test": "performance", "check": "fps", "status": "INFO", "detail": {"fps": 60}},
         ],
         "meta": {"place": "Probe", "startedAt": "2026-11-20T00:00:00Z", "durationS": 1, "players": ["P1"]}}
    r.update(extra)
    return r


class RbxTestSave(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def save(self, rep, name="r.json"):
        p = self.dir / name
        p.write_text(rep if isinstance(rep, str) else json.dumps(rep), encoding="utf-8")
        res = subprocess.run([sys.executable, str(TOOL), "save", str(p), "--project", "probe",
                              "--reports", str(self.dir / "reports")], capture_output=True, text=True)
        return res.returncode, res.stdout + res.stderr

    def test_clean_run_passes(self):
        code, out = self.save(report())
        self.assertEqual(code, 0, out)
        saved = list((self.dir / "reports" / "probe").glob("*.json"))
        self.assertEqual(len(saved), 2)  # timestamped + latest-local.json
        latest = json.loads((self.dir / "reports" / "probe" / "latest-local.json").read_text())
        self.assertIn("savedAt", latest["meta"])

    def test_fail_result_fails(self):
        code, out = self.save(report(results=[{"test": "boot", "check": "map loaded", "status": "FAIL"}]))
        self.assertEqual(code, 1, out)
        self.assertIn("Failures", out)

    def test_run_error_and_timeout_fail(self):
        for st in ("error", "timeout", "unknown_suite"):
            code, out = self.save(report(status=st, results=[], error="x"), name=f"{st}.json")
            self.assertEqual(code, 1, f"{st}: {out}")

    def test_regression_pass_to_fail_detected(self):
        self.assertEqual(self.save(report())[0], 0)
        code, out = self.save(report(results=[{"test": "boot", "check": "map loaded", "status": "FAIL"}]), "2.json")
        self.assertEqual(code, 1, out)
        self.assertIn("REGRESSION", out)

    def test_missing_passing_check_fails(self):
        self.assertEqual(self.save(report())[0], 0)
        code, out = self.save(report(results=[{"test": "performance", "check": "fps", "status": "INFO"}]), "2.json")
        self.assertEqual(code, 1, out)
        self.assertIn("MISSING", out)

    def test_empty_completed_run_fails(self):
        code, out = self.save(report(results=[]))
        self.assertEqual(code, 1, out)

    def test_invalid_reports_rejected(self):
        bad = [
            "not json",
            json.dumps({"schema": 2, "suite": "local", "status": "completed", "results": []}),
            json.dumps(report(suite="../../etc")),
            json.dumps(report(results=[{"test": "a", "check": "b", "status": "MAYBE"}])),
            json.dumps(report(status="finished")),
        ]
        for i, b in enumerate(bad):
            code, out = self.save(b, name=f"bad{i}.json")
            self.assertEqual(code, 2, f"case {i}: {out}")
        self.assertFalse((self.dir / "reports" / "probe").exists(), "invalid reports must not be saved")

    def test_saved_history_reports_still_valid(self):
        for p in (ROOT / "test-reports").glob("*/latest-*.json"):
            code, out = self.save(p.read_text(encoding="utf-8"), name=p.name)
            self.assertNotEqual(code, 2, f"{p}: {out}")

    def test_sync_check_emits_snippet(self):
        res = subprocess.run([sys.executable, str(TOOL), "sync-check", str(ROOT / "games/vfx-lab/default.project.json")],
                             capture_output=True, text=True)
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertIn("return", res.stdout)


if __name__ == "__main__":
    unittest.main(verbosity=2)
