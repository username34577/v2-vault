#!/usr/bin/env python3
"""Rebuild the permanent TikTok Research Index from the notes in research/TikTok Notes.

Standard library only. Run after every TikTok batch:
    python "research/TikTok Notes/_tools/tiktok_index.py"
Check a video before researching it (exit code 0 = already researched, 1 = new):
    python "research/TikTok Notes/_tools/tiktok_index.py" --has 7708469682512170253
"""
import json
import re
import sys
from pathlib import Path

NOTES = Path(__file__).resolve().parent.parent
OUT_MD = NOTES / "TikTok Research Index.md"
OUT_JSON = NOTES / "tiktok-research-index.json"
SKIP_FILES = {OUT_MD.name}
URL = re.compile(r"https://www\.tiktok\.com/@([\w.]+)/(video|photo)/(\d{15,20})")
ROW = re.compile(r"^\|\s*(\d+)\s*\|\s*@([\w.]+)\s*\|\s*\[link\]\((https://www\.tiktok\.com/[^)]+)\)\s*\|\s*([^|]+)\|\s*(.*)\|\s*$")


def frontmatter(text):
    m = re.match(r"---\n(.*?)\n---", text, re.S)
    out = {}
    if m:
        for line in m.group(1).splitlines():
            if ":" in line:
                k, v = line.split(":", 1)
                out[k.strip()] = v.strip()
    return out


def build():
    items = {}
    batch_status = {}
    for path in sorted(NOTES.glob("*.md")):
        if path.name in SKIP_FILES:
            continue
        text = path.read_text(encoding="utf-8")
        fm = frontmatter(text)
        saved = fm.get("saved", "")
        checked = fm.get("verified", "")
        for line in text.splitlines():
            r = ROW.match(line)
            if r:
                vid = URL.search(r.group(3))
                if vid:
                    batch_status[vid.group(3)] = r.group(4).strip()
        for creator, kind, vid in URL.findall(text):
            it = items.setdefault(vid, {"id": vid, "creator": "@" + creator, "type": kind,
                                        "url": f"https://www.tiktok.com/@{creator}/{kind}/{vid}",
                                        "first_researched": saved, "notes": [], "checked": ""})
            if path.stem not in it["notes"]:
                it["notes"].append(path.stem)
            if saved and (not it["first_researched"] or saved < it["first_researched"]):
                it["first_researched"] = saved
            if checked and checked > it["checked"]:
                it["checked"] = checked
    for vid, it in items.items():
        st = batch_status.get(vid, "")
        if st.startswith("skip"):
            it["outcome"] = "skipped (off-topic)"
        elif st.startswith("partial"):
            it["outcome"] = "partly reviewed"
        else:
            it["outcome"] = "noted"
        topical = [n for n in it["notes"] if not n.startswith("favorites-") and n != "TikTok Notes"]
        it["notes"] = topical or it["notes"]
    return dict(sorted(items.items(), key=lambda kv: (kv[1]["creator"].lower(), kv[0])))


def write(items):
    OUT_JSON.write_text(json.dumps({"count": len(items), "videos": list(items.values())}, indent=1) + "\n",
                        encoding="utf-8")
    creators = {}
    for it in items.values():
        creators.setdefault(it["creator"], []).append(it)
    lines = [
        "---", "title: TikTok Research Index", "tags: [tiktok, index]", "---", "",
        "# TikTok Research Index", "",
        "Every TikTok video already researched for this vault, generated from the notes by "
        "`_tools/tiktok_index.py`. **Do not edit by hand; rerun the script.** Machine-readable copy: "
        "`tiktok-research-index.json`. Back to [[TikTok Notes]].", "",
        "## Before researching a new batch",
        "1. For each video ID, run `python \"research/TikTok Notes/_tools/tiktok_index.py\" --has <id>` "
        "(or search this page for the ID). Skip anything already listed unless it needs re-checking.",
        "2. Check **Creator coverage** below: some creators were covered as a whole profile up to a date.",
        "3. Write new notes with the TikTok link, `@creator`, `saved:` and (after checking claims) `verified:` "
        "in the frontmatter, then rerun the script.", "",
        "**Verification labels used in notes:** **Verified** = confirmed by official docs or a primary source. "
        "**Partially Verified** = part confirmed, or only a secondary source. **Unverified** = no independent "
        "source, or the creator's own numbers. Notes with an empty *Checked* column are summaries from before "
        "claims were checked; treat their technical claims as Unverified.", "",
        "## Creator coverage (whole profiles)",
        "| Creator | Covered | Note |", "|---|---|---|",
        "| @momentumcash | Whole profile, 115 videos through 2026-11-19 (only the IDs cited in notes are listed below) | [[creator-momentumcash]] |",
        "| @rxz_dev | Whole profile, 3 videos through 2026-11-19 | [[creator-rxz-dev]] |",
        "| @bbstudios4 | Whole profile, 26 videos through 2026-11-18, frame by frame | [[creator-bbstudios4]] |",
        "| @palm_dev | **Incomplete**: profile blocked; only favourited videos | [[creator-palm-dev]] |",
        "| Favorites (@blank_387) | 80 newest favourites as of 2026-11-20 | [[favorites-2026-11-20]] |", "",
        f"## Videos ({len(items)})",
        "| Creator | Video | Researched | Checked | Outcome | Notes |", "|---|---|---|---|---|---|",
    ]
    for creator in sorted(creators, key=str.lower):
        for it in creators[creator]:
            notes = ", ".join(f"[[{n}]]" for n in it["notes"])
            lines.append(f"| {creator} | [{it['type']} {it['id']}]({it['url']}) | {it['first_researched']} | "
                         f"{it['checked']} | {it['outcome']} | {notes} |")
    OUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main():
    items = build()
    if len(sys.argv) == 3 and sys.argv[1] == "--has":
        it = items.get(sys.argv[2])
        print(json.dumps(it, indent=1) if it else "not researched yet")
        sys.exit(0 if it else 1)
    write(items)
    print(f"{len(items)} videos indexed -> {OUT_MD.name}, {OUT_JSON.name}")


if __name__ == "__main__":
    main()
