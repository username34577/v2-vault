#!/usr/bin/env python3
"""rbxtest: helpers for automated Roblox Studio test runs (standard library only).

Commands
  sync-check <project.json>            Print a Luau snippet that checks Studio's scripts match the Rojo files.
                                       Run it with execute_luau (Edit); it returns JSON {ok, checked, mismatches}.
  save <report.json> --project NAME    Validate a StudioTestService report, save it under
       [--reports DIR] [--commit SHA]  test-reports/NAME/, compare with the previous run of the same suite,
                                       print a Markdown summary. Exit 0 = all PASS, 1 = FAIL/regression, 2 = bad report.
  compare <old.json> <new.json>        Print the comparison between two saved reports.

Report schema 1 (from luau/TestHarness.luau):
  {schema:1, suite, status: completed|error|timeout|unknown_suite, results:[{test,check,status,detail?}],
   error?, meta:{place, startedAt, durationS, players, args}}
"""
import argparse
import datetime as dt
import json
import os
import re
import sys

STATUSES = {"PASS", "FAIL", "INFO"}
RUN_STATUSES = {"completed", "error", "timeout", "unknown_suite"}
MAX_RESULTS = 500


# ---------------------------------------------------------------- Rojo sync check
SCRIPT_RE = re.compile(r"^(?P<name>.+?)(?P<kind>\.server|\.client)?\.(?:luau|lua)$")


def fnv1a(data: bytes) -> int:
    h = 0x811C9DC5
    for b in data:
        h ^= b
        h = (h * 0x01000193) & 0xFFFFFFFF
    return h


def _walk_tree(node, inst_path, base_dir, out):
    """Collect (instance_path, file) for every script a Rojo tree node maps."""
    if "$path" in node:
        _walk_fs(os.path.join(base_dir, node["$path"]), inst_path, out)
    for key, child in node.items():
        if key.startswith("$") or not isinstance(child, dict):
            continue
        _walk_tree(child, inst_path + [key], base_dir, out)


def _walk_fs(path, inst_path, out):
    if os.path.isfile(path):
        m = SCRIPT_RE.match(os.path.basename(path))
        if m:
            out.append((inst_path, path))
        return
    if not os.path.isdir(path):
        return
    entries = sorted(os.listdir(path))
    for init in ("init.server.luau", "init.client.luau", "init.luau", "init.server.lua", "init.client.lua", "init.lua"):
        if init in entries:
            out.append((inst_path, os.path.join(path, init)))
            break
    for e in entries:
        if e.startswith("init.") or e.startswith("."):
            continue
        full = os.path.join(path, e)
        if os.path.isdir(full):
            _walk_fs(full, inst_path + [e], out)
        else:
            m = SCRIPT_RE.match(e)
            if m:
                out.append((inst_path + [m.group("name")], full))


def sync_check(project_file):
    with open(project_file, encoding="utf-8") as f:
        project = json.load(f)
    base = os.path.dirname(os.path.abspath(project_file))
    pairs = []
    _walk_tree(project["tree"], [], base, pairs)
    expected = []
    for inst_path, file in pairs:
        with open(file, "rb") as fh:
            src = fh.read().replace(b"\r\n", b"\n")
        expected.append({"path": inst_path, "len": len(src), "fnv": fnv1a(src), "file": os.path.relpath(file, base)})
    data = json.dumps(expected)
    # Luau long-bracket level chosen so the JSON can't close it.
    level = 1
    while ("]" + "=" * level + "]") in data:
        level += 1
    eq = "=" * level
    return f"""local HttpService = game:GetService("HttpService")
local expected = HttpService:JSONDecode([{eq}[{data}]{eq}])
local function fnv(s)
	local h = 0x811C9DC5
	for i = 1, #s do
		h = bit32.bxor(h, string.byte(s, i))
		-- 32-bit FNV prime multiply, split to stay exact in doubles
		local lo = bit32.band(h, 0xFFFF) * 0x01000193
		local hi = bit32.rshift(h, 16) * 0x01000193
		h = (lo + bit32.band(hi, 0xFFFF) * 65536) % 4294967296
	end
	return h
end
local mismatches, checked = {{}}, 0
for i, e in expected do
	local inst = game
	for _, name in e.path do
		inst = inst and inst:FindFirstChild(name)
	end
	if not inst then
		table.insert(mismatches, {{ file = e.file, problem = "missing in Studio" }})
	elseif not inst:IsA("LuaSourceContainer") then
		table.insert(mismatches, {{ file = e.file, problem = "not a script: " .. inst.ClassName }})
	else
		local src = string.gsub(inst.Source, "\\r\\n", "\\n")
		checked += 1
		if #src ~= e.len or fnv(src) ~= e.fnv then
			table.insert(mismatches, {{ file = e.file, problem = "source differs", studioLen = #src, fileLen = e.len }})
		end
	end
	if i % 20 == 0 then task.wait() end
end
return HttpService:JSONEncode({{ ok = #mismatches == 0, checked = checked, expected = #expected, mismatches = mismatches }})
"""


# ---------------------------------------------------------------- reports
def validate(report):
    errs = []
    if not isinstance(report, dict):
        return ["report is not a JSON object"]
    if report.get("schema") != 1:
        errs.append("schema must be 1")
    if not isinstance(report.get("suite"), str) or not re.fullmatch(r"[A-Za-z0-9_.-]{1,64}", report.get("suite") or ""):
        errs.append("suite must be a short name (letters, digits, _ . -)")
    if report.get("status") not in RUN_STATUSES:
        errs.append(f"status must be one of {sorted(RUN_STATUSES)}")
    res = report.get("results")
    if not isinstance(res, list):
        errs.append("results must be a list")
    else:
        if len(res) > MAX_RESULTS:
            errs.append("too many results")
        for i, r in enumerate(res):
            if not isinstance(r, dict) or not isinstance(r.get("test"), str) or not isinstance(r.get("check"), str):
                errs.append(f"result {i}: needs string test and check")
            elif r.get("status") not in STATUSES:
                errs.append(f"result {i}: status must be PASS/FAIL/INFO")
    return errs


def key(r):
    return f"{r['test']} / {r['check']}"


def counts(report):
    c = {"PASS": 0, "FAIL": 0, "INFO": 0}
    for r in report["results"]:
        c[r["status"]] += 1
    return c


def numeric_details(r):
    d = r.get("detail")
    if not isinstance(d, dict):
        return {}
    return {k: v for k, v in d.items() if isinstance(v, (int, float)) and not isinstance(v, bool)}


def compare(old, new):
    lines = []
    o = {key(r): r for r in old["results"]}
    n = {key(r): r for r in new["results"]}
    for k in n:
        if k in o and o[k]["status"] != n[k]["status"]:
            tag = "REGRESSION" if n[k]["status"] == "FAIL" else ("FIXED" if o[k]["status"] == "FAIL" else "CHANGED")
            lines.append(f"- **{tag}** {k}: {o[k]['status']} -> {n[k]['status']}")
    for k in n:
        if k not in o:
            lines.append(f"- NEW check: {k} ({n[k]['status']})")
    for k in o:
        if k not in n:
            lines.append(f"- MISSING check (was {o[k]['status']}): {k}")
    perf = []
    for k in n:
        if k in o and n[k]["test"] == "performance":
            on, nn = numeric_details(o[k]), numeric_details(n[k])
            deltas = [f"{m} {on[m]} -> {nn[m]}" for m in nn if m in on and on[m] != nn[m]]
            if deltas:
                perf.append(f"- {k}: " + ", ".join(deltas))
    out = ["### Compared with previous run", f"Previous: {old['meta'].get('startedAt', '?')}"]
    out += lines or ["- No status changes."]
    if perf:
        out += ["", "Performance numbers (previous -> now):"] + perf
    return "\n".join(out), any(l.startswith("- **REGRESSION**") for l in lines)


def summary(report):
    c = counts(report)
    meta = report.get("meta", {})
    out = [
        f"## {report['suite']}: {report['status']}  ({c['PASS']} PASS, {c['FAIL']} FAIL, {c['INFO']} INFO)",
        f"Place {meta.get('place', '?')} | players {', '.join(meta.get('players') or []) or '-'} | {meta.get('durationS', '?')} s | started {meta.get('startedAt', '?')}",
    ]
    if report.get("error"):
        out.append(f"**Run error:** {report['error']}")
    fails = [r for r in report["results"] if r["status"] == "FAIL"]
    if fails:
        out.append("### Failures")
        for r in fails:
            out.append(f"- {key(r)}  detail: {json.dumps(r.get('detail'))}")
    perf = [r for r in report["results"] if r["test"] == "performance"]
    if perf:
        out.append("### Performance (recorded every run; PC numbers are not proof of mobile performance)")
        for r in perf:
            out.append(f"- [{r['status']}] {r['check']}: {json.dumps(r.get('detail'))}")
    return "\n".join(out)


def cmd_save(a):
    with open(a.report, encoding="utf-8-sig") as f:
        raw = f.read()
    if len(raw) > 2_000_000:
        print("report file too large", file=sys.stderr)
        return 2
    try:
        report = json.loads(raw)
    except json.JSONDecodeError as e:
        print(f"not valid JSON: {e}", file=sys.stderr)
        return 2
    errs = validate(report)
    if errs:
        print("invalid report:\n- " + "\n- ".join(errs), file=sys.stderr)
        return 2
    if not re.fullmatch(r"[A-Za-z0-9_.-]{1,64}", a.project):
        print("bad project name", file=sys.stderr)
        return 2
    folder = os.path.join(a.reports, a.project)
    os.makedirs(folder, exist_ok=True)
    report.setdefault("meta", {})
    report["meta"]["savedAt"] = dt.datetime.now().astimezone().isoformat(timespec="seconds")
    if a.commit:
        report["meta"]["commit"] = a.commit
    prev_path = os.path.join(folder, f"latest-{report['suite']}.json")
    prev = None
    if os.path.exists(prev_path):
        with open(prev_path, encoding="utf-8") as f:
            prev = json.load(f)
    stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    out_path = os.path.join(folder, f"{stamp}-{report['suite']}.json")
    n = 2
    while os.path.exists(out_path):
        out_path = os.path.join(folder, f"{stamp}-{report['suite']}-{n}.json")
        n += 1
    for p in (out_path, prev_path):
        with open(p, "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2)
    text = summary(report)
    regression = False
    if prev:
        cmp_text, regression = compare(prev, report)
        text += "\n\n" + cmp_text
    print(text)
    print(f"\nSaved {out_path}")
    ok = report["status"] == "completed" and counts(report)["FAIL"] == 0 and not regression
    return 0 if ok else 1


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    s1 = sub.add_parser("sync-check")
    s1.add_argument("project")
    s2 = sub.add_parser("save")
    s2.add_argument("report")
    s2.add_argument("--project", required=True)
    s2.add_argument("--reports", default="test-reports")
    s2.add_argument("--commit")
    s3 = sub.add_parser("compare")
    s3.add_argument("old")
    s3.add_argument("new")
    a = p.parse_args()
    if a.cmd == "sync-check":
        print(sync_check(a.project))
        return 0
    if a.cmd == "save":
        return cmd_save(a)
    with open(a.old, encoding="utf-8") as f:
        old = json.load(f)
    with open(a.new, encoding="utf-8") as f:
        new = json.load(f)
    print(compare(old, new)[0])
    return 0


if __name__ == "__main__":
    sys.exit(main())
