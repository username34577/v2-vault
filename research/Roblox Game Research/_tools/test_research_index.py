#!/usr/bin/env python3
"""Self-test for research_index.py. Builds a throwaway vault in a temp folder, runs the real script
there, checks every behaviour, and always deletes the temp folder (even when a check fails).

    python "research/Roblox Game Research/_tools/test_research_index.py"
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SECTION_NAME = "Roblox Game Research"
PNG = bytes.fromhex("89504e470d0a1a0a0000000d4948445200000001000000010806000000"
                    "1f15c4890000000d4944415478da63f8ffff3f0005fe02fea7d6a5d80000000049454e44ae426082")

results = []


def check(name, ok, detail=""):
    results.append((name, bool(ok)))
    print(f"{'PASS' if ok else 'FAIL'}  {name}" + (f"  ({detail})" if detail and not ok else ""))


def run(sec, *args, stdin=None):
    return subprocess.run([sys.executable, str(sec / "_tools" / "research_index.py"), *args],
                          input=stdin, capture_output=True, text=True, timeout=300)


def main():
    tmp = Path(tempfile.mkdtemp(prefix="research_test_"))
    try:
        sec = tmp / "research" / SECTION_NAME
        (sec / "_tools").mkdir(parents=True)
        shutil.copy2(HERE / "research_index.py", sec / "_tools" / "research_index.py")
        shutil.copytree(HERE.parent / "_templates", sec / "_templates")
        games = sec / "Games"
        games.mkdir()
        # an existing hand-written note with an alias and an analysis section
        hand = ("---\ntype: game-research\ngame: Grow a Garden\naliases: [GaG]\ngenre: farming\n---\n\n# Grow a Garden\n\n"
                "## Core loop\nPlant, wait, harvest, sell, buy better seeds. My own words stay untouched.\n\n"
                "<!-- research:auto:start -->\nold generated text\n<!-- research:auto:end -->\n\n## After the block\nAlso mine.\n")
        (games / "Grow a Garden.md").write_text(hand, encoding="utf-8")
        lih = tmp / "LihFolk Vault V2" / "32 Case Studies of Top Roblox Games"
        lih.mkdir(parents=True)
        (lih / "Case Study - Grow a Garden.md").write_text("# Case Study\n\n## Mutations\nWeather mutations multiply value.\n", encoding="utf-8")
        (tmp / "games" / "demo").mkdir(parents=True)
        (tmp / "games" / "demo" / "DESIGN.md").write_text("Inspired by [[Grow a Garden]] seed shop.\n", encoding="utf-8")
        (sec / "Reference Log.md").write_text(
            "| Date | Project | Feature / decision | References | How they influenced it | Status |\n|---|---|---|---|---|---|\n"
            "| 2026-11-21 | demo | Seed shop restock timer | [[Grow a Garden]], [[Case Study - Grow a Garden]] | Copied the restock urgency | built |\n",
            encoding="utf-8")

        inbox = sec / "_inbox"
        (inbox / "Steal a Brainrot").mkdir(parents=True)
        (inbox / "Steal a Brainrot" / "base raid.png").write_bytes(PNG)  # by subfolder
        (inbox / "Fish It - rod shop.png").write_bytes(PNG + b"1")  # by prefix
        (inbox / "gag_mutation_screen.png").write_bytes(PNG + b"2")  # by alias "GaG"
        (inbox / "random clip.png").write_bytes(PNG + b"3")  # unsorted
        (inbox / "notes.txt").write_text("not media")  # unsupported
        (inbox / "README.md").write_text("inbox readme")
        big = inbox / "Fish It - huge.mp4"
        with open(big, "wb") as f:  # sparse 96 MB file: over the git limit
            f.truncate(96 * 1024 * 1024)
        have_ffmpeg = shutil.which("ffmpeg") is not None
        if have_ffmpeg:
            subprocess.run(["ffmpeg", "-v", "error", "-f", "lavfi", "-i", "testsrc=duration=12:size=320x240:rate=10",
                            str(inbox / "Grow a Garden - first minute.mp4")], check=True, timeout=120)
        files_in = 6 if have_ffmpeg else 5  # 4 images + huge.mp4 (+ first minute.mp4 with ffmpeg)

        r = run(sec)
        check("first run exits 0", r.returncode == 0, r.stderr[-400:])
        media = sec / "Media"
        check("filed by subfolder", (media / "Steal a Brainrot").exists() and len(list((media / "Steal a Brainrot").glob("*base raid.png"))) == 1)
        check("filed by name prefix, prefix removed", len(list((media / "Fish It").glob("* rod shop.png"))) == 1)
        check("filed by alias in file name", len(list((media / "Grow a Garden").glob("*gag_mutation_screen.png"))) == 1)
        check("unknown game goes to _Unsorted", len(list((media / "_Unsorted").glob("*random clip.png"))) == 1)
        check("unsupported file left in inbox", (inbox / "notes.txt").exists())
        check("inbox README left alone", (inbox / "README.md").exists())
        check("file over 95 MB goes to git-ignored _large", len(list((media / "_large" / "Fish It").glob("*huge.mp4"))) == 1)
        check("stub note made for new games", (games / "Steal a Brainrot.md").exists() and (games / "Fish It.md").exists())
        if have_ffmpeg:
            sheets = list((media / "Grow a Garden" / "_frames").rglob("sheet_*.jpg"))
            check("video frame sheets made", len(sheets) >= 1, str(sheets))
            meta = list((media / "Grow a Garden" / "_frames").rglob("frames.json"))
            check("frame timing recorded", meta and json.loads(meta[0].read_text())["seconds_between_frames"] > 0)

        note = (games / "Grow a Garden.md").read_text(encoding="utf-8")
        check("hand-written text before the block kept", "My own words stay untouched." in note)
        check("hand-written text after the block kept", "## After the block\nAlso mine." in note)
        check("old generated text replaced", "old generated text" not in note and "## Evidence, background and influence" in note)
        check("LihFolk background linked", "[[Case Study - Grow a Garden]]" in note)
        check("Reference Log row shows as influence", "Seed shop restock timer" in note)
        check("design doc link shows as influence", "games/demo/DESIGN.md" in note)

        idx = json.loads((sec / "research-index.json").read_text(encoding="utf-8"))
        check("index lists all games", {g["game"] for g in idx["games"]} >= {"Grow a Garden", "Steal a Brainrot", "Fish It"})
        check("everything starts as needs-analysis", len(idx["needs_analysis"]) == files_in, f"{len(idx['needs_analysis'])} vs {files_in}: {idx['needs_analysis']}")
        check("index markdown written", (sec / "Research Index.md").exists())

        # analysis: mention a file in the note -> no longer needs analysis
        mutation = next((media / "Grow a Garden").glob("*gag_mutation_screen.png")).name
        (games / "Grow a Garden.md").write_text(note.replace("My own words stay untouched.",
                                                f"My own words stay untouched. Mutation popup seen in `{mutation}`."), encoding="utf-8")
        run(sec, "--no-frames")
        idx = json.loads((sec / "research-index.json").read_text(encoding="utf-8"))
        check("citing a file marks it analyzed", all(mutation not in f for f in idx["needs_analysis"]))

        # duplicates and idempotency
        (inbox / "again.png").write_bytes(PNG)  # same bytes as "base raid.png"
        before = (games / "Grow a Garden.md").read_text(encoding="utf-8")
        r = run(sec, "--no-frames")
        check("duplicate moved to _inbox/_duplicates", (inbox / "_duplicates" / "again.png").exists() and "duplicate" in r.stdout)
        check("rerun leaves notes unchanged", (games / "Grow a Garden.md").read_text(encoding="utf-8") == before)

        # manual move in Media/ is followed
        src = next((media / "_Unsorted").glob("*random clip.png"))
        (media / "Fish It").mkdir(exist_ok=True)
        shutil.move(str(src), str(media / "Fish It" / src.name))
        run(sec, "--no-frames")
        idx = json.loads((sec / "research-index.json").read_text(encoding="utf-8"))
        check("hand-moved file follows its new folder", any(m["game"] == "Fish It" and "random clip" in m["file"] for m in idx["media"]) and not idx["unsorted"])
        reg = json.loads((sec / "_tools" / "media-registry.json").read_text(encoding="utf-8"))
        check("registry keeps no stale paths", all((tmp / k).exists() for k in reg))

        # nothing lost
        all_media = [p for p in media.rglob("*") if p.is_file() and "_frames" not in p.parts]
        check("no media file lost", len(all_media) == files_in, f"{len(all_media)} vs {files_in}")

        # search + hooks
        r = run(sec, "--search", "mutation weather")
        check("search finds the LihFolk note by body text", "Case Study - Grow a Garden" in r.stdout, r.stdout)
        r = run(sec, "--hook", "prompt", stdin=json.dumps({"prompt": "Add a seed shop restock timer to my Roblox game"}))
        ok = False
        try:
            ok = "Game-design reference check" in json.loads(r.stdout)["hookSpecificOutput"]["additionalContext"]
        except Exception:
            pass
        check("prompt hook fires on a game-design request", ok, r.stdout[:300])
        r = run(sec, "--hook", "prompt", stdin=json.dumps({"prompt": "What time is it in Tokyo right now?"}))
        check("prompt hook silent on unrelated prompts", r.stdout.strip() == "", r.stdout[:200])
        r = run(sec, "--hook", "prompt", stdin="not json")
        check("prompt hook never fails on bad input", r.returncode == 0 and r.stdout.strip() == "")
        (inbox / "Fish It - bobber.png").write_bytes(PNG + b"9")
        r = run(sec, "--hook", "session")
        ok = False
        try:
            ok = "Research inbox processed: Fish It 1" in json.loads(r.stdout)["hookSpecificOutput"]["additionalContext"]
        except Exception:
            pass
        check("session hook files new media and reports it", ok and r.returncode == 0, r.stdout[:300])
        r = run(sec, "--check")
        check("--check exits 1 while work is waiting", r.returncode == 1)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
        check("temp folder removed", not tmp.exists())
    fails = sum(1 for _, ok in results if not ok)
    print(f"\n{len(results) - fails}/{len(results)} passed")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
