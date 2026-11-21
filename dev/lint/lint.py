#!/usr/bin/env python3
"""Luau quality gate for every game in this repo: selene (lint), luau-lsp (Roblox type check), StyLua (format).

Standard library only. Tools come from PATH (installed with Rokit from rokit.toml, see dev/lint/README.md).

    python dev/lint/lint.py                    # check: fail only on findings that are NOT in the baseline
    python dev/lint/lint.py --report out.json  # also write every finding as JSON
    python dev/lint/lint.py --update-baseline  # accept the current findings as the new baseline (review first!)

Exit codes: 0 no new findings · 1 new findings (listed) · 2 a tool is missing or crashed.
Findings are keyed by tool + file + rule + message (no line numbers), counted, and compared with
dev/lint/baseline.json, so moving code around does not create "new" findings but adding a problem does.
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.request
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASELINE = Path(__file__).resolve().parent / "baseline.json"
CACHE = Path(__file__).resolve().parent / ".cache"
DEFS_URL = "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau"
HARNESS = "dev/rbxtest/luau"
LSP_LINE = re.compile(r"^(?P<file>.+?\.luau?)(?: \[[^\]]*\])?\((?P<line>\d+),(?P<col>\d+)\): (?P<code>[A-Za-z]+): (?P<msg>.*)$")


def fail(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)


def tool(name):
    path = shutil.which(name)
    if not path:
        fail(f"[lint] missing tool: {name}. Install the pinned toolchain (rokit install), see dev/lint/README.md")
    return path


def run(cmd, cwd=ROOT):
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, encoding="utf-8", errors="replace")


def rel(path, base):
    p = Path(path)
    if not p.is_absolute():
        p = (base / p)
    try:
        return p.resolve().relative_to(ROOT).as_posix()
    except ValueError:
        return p.as_posix()


def definitions(explicit):
    if explicit:
        return explicit
    CACHE.mkdir(exist_ok=True)
    defs = CACHE / "globalTypes.d.luau"
    if not defs.exists():
        urllib.request.urlretrieve(DEFS_URL, defs)
    return str(defs)


def projects():
    return sorted(p for p in (ROOT / "games").glob("*/default.project.json"))


def selene_findings(targets):
    res = run([tool("selene"), "--display-style=json2", "--no-summary", *targets])
    out = []
    for line in res.stdout.splitlines():
        try:
            d = json.loads(line)
        except json.JSONDecodeError:
            continue
        if d.get("type") != "Diagnostic":
            continue
        lab = d.get("primary_label") or {}
        out.append({"tool": "selene", "file": rel(lab.get("filename", "?"), ROOT), "code": d.get("code", "?"),
                    "severity": d.get("severity", "?").lower(), "line": (lab.get("span") or {}).get("start_line", 0) + 1,
                    "message": d.get("message", "")})
    if res.returncode not in (0, 1) or ("error" in res.stderr.lower() and not out):
        sys.stderr.write(res.stderr)
        fail("[lint] selene failed to run")
    return out


def lsp_findings(project, defs):
    proj_dir = project.parent
    with tempfile.TemporaryDirectory() as tmp:
        smap = Path(tmp) / "sourcemap.json"
        r = run([tool("rojo"), "sourcemap", project.name, "-o", str(smap)], cwd=proj_dir)
        if r.returncode != 0:
            sys.stderr.write(r.stderr)
            fail(f"[lint] rojo sourcemap failed for {project}")
        targets = ["src"]
        if f'"../../{HARNESS}"' in project.read_text(encoding="utf-8"):
            targets.append(f"../../{HARNESS}")
        r = run([tool("luau-lsp"), "analyze", "--platform=roblox", f"--sourcemap={smap}",
                 f"--definitions=@roblox={defs}", *targets], cwd=proj_dir)
    out = []
    for line in (r.stdout + "\n" + r.stderr).splitlines():
        m = LSP_LINE.match(line.strip())
        if m:
            code = m["code"]
            out.append({"tool": "luau-lsp", "file": rel(m["file"], proj_dir), "code": code,
                        "severity": "error" if code.endswith("Error") else "warning",
                        "line": int(m["line"]), "message": m["msg"].strip()})
    return out


def stylua_findings(targets):
    r = run([tool("stylua"), "--check", "--output-format=summary", *targets])
    out = []
    for line in (r.stdout + "\n" + r.stderr).splitlines():
        line = line.strip()
        m = re.match(r"error: could not format file (.+?\.luau?): (.*)", line)
        if m:
            out.append({"tool": "stylua", "file": rel(m[1], ROOT), "code": "parse-error", "severity": "error",
                        "line": 0, "message": m[2][:200]})
            continue
        if line.endswith((".luau", ".lua")) and not line.startswith("error"):
            out.append({"tool": "stylua", "file": rel(line, ROOT), "code": "not-formatted", "severity": "warning",
                        "line": 0, "message": "file is not StyLua-formatted"})
    if r.returncode not in (0, 1) and not out:
        sys.stderr.write(r.stderr)
        fail("[lint] stylua failed to run")
    return out


def key(f):
    return f"{f['tool']}|{f['file']}|{f['code']}|{f['message']}"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--update-baseline", action="store_true")
    ap.add_argument("--report")
    ap.add_argument("--defs", help="path to globalTypes.d.luau (otherwise downloaded once into dev/lint/.cache)")
    args = ap.parse_args()

    projs = projects()
    targets = [p.parent.joinpath("src").relative_to(ROOT).as_posix() for p in projs] + [HARNESS]
    findings = selene_findings(targets) + stylua_findings(targets)
    defs = definitions(args.defs)
    for p in projs:
        findings += lsp_findings(p, defs)

    seen, unique = set(), []
    for f in findings:  # luau-lsp reports a module once per requiring script; keep one copy per location
        loc = (f["tool"], f["file"], f["line"], f["code"], f["message"])
        if loc not in seen:
            seen.add(loc)
            unique.append(f)
    findings = unique
    counts = Counter(key(f) for f in findings)
    if args.report:
        Path(args.report).write_text(json.dumps({"findings": findings}, indent=1), encoding="utf-8")
    if args.update_baseline:
        BASELINE.write_text(json.dumps(dict(sorted(counts.items())), indent=1) + "\n", encoding="utf-8")
        print(f"[lint] baseline updated: {sum(counts.values())} findings, {len(counts)} distinct")
        return 0

    base = json.loads(BASELINE.read_text(encoding="utf-8")) if BASELINE.exists() else {}
    new = {k: n - base.get(k, 0) for k, n in counts.items() if n > base.get(k, 0)}
    fixed = sum(max(0, n - counts.get(k, 0)) for k, n in base.items())
    by_tool = Counter(f["tool"] for f in findings)
    print(f"[lint] {len(projs)} projects · findings: " + ", ".join(f"{t} {n}" for t, n in sorted(by_tool.items()))
          + f" · baseline {sum(base.values())} · new {sum(new.values())} · fixed {fixed}")
    if new:
        print("[lint] NEW findings (not in baseline):")
        for f in findings:
            if new.get(key(f), 0) > 0:
                print(f"  {f['file']}:{f['line']}  [{f['tool']} {f['code']}] {f['message']}")
                new[key(f)] -= 1
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
