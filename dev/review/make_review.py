#!/usr/bin/env python3
"""Build a review packet for agent work before the owner approves it: what changed, the evidence
(lint, compile, tests, screenshots) and the risks, as one Markdown file in reviews/.

    python dev/review/make_review.py --title "Shop UI pass" [--base origin/main] [--shot path.png ...]

Standard library only. It runs checks but never changes code. Exit 0 = READY FOR APPROVAL,
1 = NEEDS WORK or NEEDS EVIDENCE (the packet says why), 2 = could not build the packet.
"""
import argparse
import datetime as dt
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MAX_DIFF_LINES = 400
HIGH_STAKES = [  # (label, regex on added/removed lines) - mirrors AGENTS.md "high-stakes" list
    ("player data / DataStore", r"DataStore|GetAsync|SetAsync|UpdateAsync|ProfileStore|ProfileService"),
    ("purchases / receipts", r"ProcessReceipt|MarketplaceService|PromptProductPurchase|PromptGamePassPurchase"),
    ("paid random items", r"PolicyService|ArePaidRandomItemsRestricted"),
    ("remotes / security", r"OnServerEvent|OnServerInvoke|RemoteEvent|RemoteFunction|UnreliableRemoteEvent"),
    ("HTTP / external calls", r"HttpService|RequestAsync|GetAsync\(\s*\"http"),
]
SECRET = re.compile(r"(api[_-]?key|secret|token|password|ROBLOSECURITY)\s*[:=]\s*['\"][^'\"]{8,}", re.I)
VISUAL = re.compile(r"(/client/|Gui|UI|Hud|Shop|Menu|VFX|Effect|Camera|\.rbxm)", re.I)


def git(*args):
    r = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if r.returncode != 0:
        raise RuntimeError(r.stderr.strip())
    return r.stdout


def run(cmd):
    r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")
    return r.returncode, (r.stdout + r.stderr).strip()


def changed_files(base):
    committed = git("diff", "--name-status", f"{base}...HEAD").splitlines()
    working = git("status", "--porcelain").splitlines()
    files = {}
    for line in committed:
        parts = line.split("\t")
        files[parts[-1]] = parts[0][0]
    for line in working:
        files[line[3:].strip().strip('"')] = line[:2].strip() or "M"
    for u in git("ls-files", "--others", "--exclude-standard").splitlines():  # expand untracked folders
        files.pop(u.rsplit("/", 1)[0] + "/", None)
        files[u] = "??"
    return files


def category(path):
    if path.startswith("games/") and path.endswith((".luau", ".lua")):
        return "game code"
    if path.startswith("games/"):
        return "game files"
    if path.startswith(("dev/", "hooks/", ".github/")) or path in ("rokit.toml", "selene.toml", "stylua.toml"):
        return "tools / CI"
    if path.startswith(("skills/", "agents/", "commands/", ".claude/")) or path in ("CLAUDE.md", "AGENTS.md"):
        return "agent instructions"
    if path.startswith("test-reports/"):
        return "test reports"
    if path.endswith(".md"):
        return "notes"
    return "other"


def date_only_change(path):
    try:
        d = git("diff", "-U0", "--", path)
    except RuntimeError:
        return False
    changed = [l for l in d.splitlines() if l[:1] in "+-" and not l.startswith(("+++", "---"))]
    return bool(changed) and all(re.search(r"\d{4}-\d{2}-\d{2}", l) for l in changed)


def test_evidence(game):
    folder = ROOT / "test-reports" / game
    cfg = ROOT / "games" / game / "rbxtest.json"
    if not cfg.exists():
        return "no rbxtest suites configured", None
    last_code = git("log", "-1", "--format=%cI", "--", f"games/{game}/src").strip()
    rows, fresh = [], True
    for suite in json.loads(cfg.read_text(encoding="utf-8")).get("suites", []):
        p = folder / f"latest-{suite['name']}.json"
        if not p.exists():
            rows.append(f"`{suite['name']}`: **no report**")
            fresh = False
            continue
        rep = json.loads(p.read_text(encoding="utf-8"))
        saved = rep.get("meta", {}).get("savedAt", "")
        fails = sum(1 for r in rep.get("results", []) if r.get("status") == "FAIL")
        ok = rep.get("status") == "completed" and fails == 0
        stale = bool(last_code and saved and saved < last_code) or bool(git("status", "--porcelain", f"games/{game}/src").strip())
        fresh &= ok and not stale
        rows.append(f"`{suite['name']}`: {rep.get('status')}, {fails} FAIL, saved {saved}" + (" — **older than the code**" if stale else ""))
    return "; ".join(rows), fresh


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--title", required=True)
    ap.add_argument("--base", default="origin/main")
    ap.add_argument("--shot", action="append", default=[], help="screenshot file to attach (repeatable)")
    ap.add_argument("--out")
    ap.add_argument("--skip-lint", action="store_true")
    a = ap.parse_args()

    try:
        files = changed_files(a.base)
        diff = git("diff", f"{a.base}...HEAD") + git("diff")
        for u in git("ls-files", "--others", "--exclude-standard").splitlines():  # new files: show them too
            r = subprocess.run(["git", "diff", "--no-index", "--", "/dev/null", u], cwd=ROOT,
                               capture_output=True, text=True, encoding="utf-8", errors="replace")
            diff += r.stdout
    except RuntimeError as e:
        print(f"[review] git failed: {e}", file=sys.stderr)
        return 2
    if not files:
        print("[review] nothing changed against", a.base)
        return 2

    blockers, needs = [], []
    groups = {}
    for f, st in sorted(files.items()):
        groups.setdefault(category(f), []).append(f"`{st}` {f}")
    luau = [f for f in files if f.endswith((".luau", ".lua")) and (ROOT / f).exists()]
    games = sorted({f.split("/")[1] for f in files if f.startswith("games/") and f.count("/") >= 2 and not f.split("/")[1].startswith("_")})

    # evidence
    ev = []
    if luau and shutil.which("luau-compile"):
        bad = [f for f in luau if run(["luau-compile", "--null", f])[0] != 0]
        ev.append(f"- Compile ({len(luau)} changed Luau files): " + ("OK" if not bad else f"**FAILED** {bad}"))
        if bad:
            blockers.append("compile errors")
    elif luau:
        ev.append("- Compile: luau-compile not installed here (CI compiles every push)")
    lint_inputs = luau or [f for f in files if f.startswith("dev/lint/") or f in ("selene.toml", "stylua.toml", "rokit.toml")]
    if lint_inputs and not a.skip_lint:
        code, out = run([sys.executable, "dev/lint/lint.py"])
        ev.append(f"- Lint/type/format (`dev/lint/lint.py`, exit {code}):\n```\n{out[-3000:]}\n```")
        if code == 1:
            blockers.append("new lint/type/format findings")
        elif code == 2:
            needs.append("lint tools missing: install with `rokit install`")
    if any(f.startswith("dev/rbxtest/") for f in files):
        code, out = run([sys.executable, "dev/rbxtest/test_rbxtest.py"])
        ev.append(f"- rbxtest self-test: exit {code}")
        if code:
            blockers.append("rbxtest self-test failed")
    for g in games:
        text, fresh = test_evidence(g)
        ev.append(f"- Studio tests `{g}`: {text}")
        if fresh is False and any(f.startswith(f"games/{g}/src") for f in files):
            needs.append(f"fresh passing `/rbx-test {g}` run after the last code change")

    shots = []
    for s in a.shot:
        p = Path(s)
        if not p.exists():
            needs.append(f"screenshot not found: {s}")
        else:
            shots.append(p)
    if not shots and any(VISUAL.search(f) for f in files if f.startswith("games/")):
        needs.append("screenshots (visual/UI/VFX files changed)")

    # risks
    code_diff = "\n".join(git("diff", f"{a.base}...HEAD", "--", f) + git("diff", "--", f) for f in luau)
    changed_lines = "\n".join(l for l in code_diff.splitlines() if l[:1] in "+-" and not l.startswith(("+++", "---")))
    all_changed = "\n".join(l for l in diff.splitlines() if l[:1] == "+" and not l.startswith("+++"))
    risks = [label for label, rx in HIGH_STAKES if re.search(rx, changed_lines)]
    if SECRET.search(all_changed):
        blockers.append("possible secret in the diff")
    date_only = [f for f in files if f.endswith(".md") and "reports" in f and date_only_change(f)]
    if date_only:
        needs.append("restore date-only generated report changes: " + ", ".join(date_only))

    verdict = "READY FOR APPROVAL" if not blockers and not needs else ("NEEDS WORK" if blockers else "NEEDS EVIDENCE")
    stamp = dt.datetime.now().strftime("%Y-%m-%d")
    slug = re.sub(r"[^a-z0-9]+", "-", a.title.lower()).strip("-")[:50]
    out = Path(a.out) if a.out else ROOT / "reviews" / f"{stamp}-{slug}.md"
    out.parent.mkdir(parents=True, exist_ok=True)
    diff_lines = diff.splitlines()
    md = [f"# Review: {a.title}", "",
          f"**Verdict: {verdict}** · {stamp} · base `{a.base}` · head `{git('rev-parse', '--short', 'HEAD').strip()}` (+ uncommitted)", ""]
    if blockers:
        md += ["**Blockers:** " + "; ".join(blockers), ""]
    if needs:
        md += ["**Missing evidence:** " + "; ".join(needs), ""]
    md += ["## Changed files", git("diff", "--stat", f"{a.base}...HEAD").strip() and f"```\n{git('diff', '--stat', a.base + '...HEAD').strip()}\n```" or "(uncommitted only)", ""]
    for cat in sorted(groups):
        md += [f"**{cat}**", *[f"- {x}" for x in groups[cat]], ""]
    md += ["## Evidence", *(ev or ["- (no code changed: notes/config only)"]), ""]
    md += ["## Screenshots", *([f"![[{p.name}]]" if p.is_relative_to(ROOT) else f"- {p}" for p in shots] or ["- none"]), ""]
    md += ["## High-stakes areas touched (read the vault notes' Common mistakes + Checklist)",
           *([f"- {r}" for r in risks] or ["- none detected"]), ""]
    md += ["## Owner decision", "- [ ] Approve  - [ ] Ask for changes  - [ ] Reject", "- Notes:", ""]
    md += ["## Diff" + (f" (first {MAX_DIFF_LINES} lines)" if len(diff_lines) > MAX_DIFF_LINES else ""),
           "```diff", *diff_lines[:MAX_DIFF_LINES], "```"]
    out.write_text("\n".join(md) + "\n", encoding="utf-8")
    print(f"[review] {verdict}: {out.relative_to(ROOT) if out.is_relative_to(ROOT) else out}")
    for b in blockers + needs:
        print(f"  - {b}")
    return 0 if verdict == "READY FOR APPROVAL" else 1


if __name__ == "__main__":
    sys.exit(main())
