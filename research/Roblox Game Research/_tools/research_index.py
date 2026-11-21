#!/usr/bin/env python3
"""Roblox Game Research processor. Standard library only (ffmpeg optional, for video frame sheets).

    python "research/Roblox Game Research/_tools/research_index.py"                 # file the inbox, rebuild the index
    python "research/Roblox Game Research/_tools/research_index.py" --search "pet egg hatching"
    python "research/Roblox Game Research/_tools/research_index.py" --consult "redesign the shop"   # refs to read first
    python "research/Roblox Game Research/_tools/research_index.py" --check        # exit 1 if inbox or index needs work
    python "research/Roblox Game Research/_tools/research_index.py" --hook session # Claude Code SessionStart hook
    python "research/Roblox Game Research/_tools/research_index.py" --hook prompt  # Claude Code UserPromptSubmit hook

What it does (nothing is ever deleted or overwritten):
  1. Files every media file in _inbox/ into Media/<Game>/ as "<date> <original name>".
     Game = the _inbox subfolder, else the filename prefix before " - ", else a known game name or
     alias found in the filename, else _Unsorted. Duplicates (same SHA-256 as filed media) go to
     _inbox/_duplicates/. Files over 95 MB go to Media/_large/<Game>/ (git-ignored: GitHub rejects
     files over 100 MB). Unsupported files stay in the inbox and are reported.
  2. Makes contact sheets of each video (Media/<Game>/_frames/<video>/sheet_NN.jpg) when ffmpeg is
     installed, so an AI without video input can still study a recording frame by frame.
  3. Creates a stub game note from _templates/Game Research.md for any new game.
  4. Rewrites only the generated block of each game note (between the research:auto markers):
     evidence, background notes in the vault, and the features each game influenced
     (from Reference Log.md and from links in games/*/ design docs).
  5. Writes Research Index.md and research-index.json.
Media/ is the source of truth: move or rename files there freely, the next run follows.
"""
import datetime
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

SECTION = Path(__file__).resolve().parent.parent  # research/Roblox Game Research
ROOT = SECTION.parent.parent  # repo / Obsidian vault root
INBOX = SECTION / "_inbox"
MEDIA = SECTION / "Media"
LARGE = MEDIA / "_large"
GAMES = SECTION / "Games"
TEMPLATE = SECTION / "_templates" / "Game Research.md"
LOG = SECTION / "Reference Log.md"
INDEX_MD = SECTION / "Research Index.md"
INDEX_JSON = SECTION / "research-index.json"
REGISTRY = SECTION / "_tools" / "media-registry.json"
LIHFOLK_SECTIONS = ["32 Case Studies of Top Roblox Games", "59 Viral and Trend Game Teardowns", "60 High-Craft Game Teardowns"]

VIDEO = {".mp4", ".mov", ".webm", ".mkv", ".m4v", ".avi"}
IMAGE = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".heic"}
LARGE_BYTES = 95 * 1024 * 1024
WARN_BYTES = 50 * 1024 * 1024
UNSORTED = "_Unsorted"
AUTO_START, AUTO_END = "<!-- research:auto:start -->", "<!-- research:auto:end -->"
ANALYSIS_SECTIONS = ["Snapshot", "Core loop", "Mechanics", "UI and UX", "Progression and rewards",
                     "Economy and monetization", "Social and multiplayer", "First 60 seconds", "Steal and avoid"]
BAD_CHARS = re.compile(r'[<>:"/\\|?*\x00-\x1f]')


def today():
    return datetime.date.today().isoformat()


def rel(p):
    return Path(p).resolve().relative_to(ROOT).as_posix()


def norm(s):
    return re.sub(r"[^a-z0-9]", "", s.lower())


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def safe_name(s):
    s = BAD_CHARS.sub("_", s).strip(" .")
    return s or "file"


def frontmatter(text):
    m = re.match(r"---\r?\n(.*?)\r?\n---", text, re.S)
    out = {}
    if not m:
        return out
    for line in m.group(1).splitlines():
        if ":" in line and not line.startswith(" "):
            k, v = line.split(":", 1)
            v = v.strip()
            if v.startswith("[") and v.endswith("]"):
                v = [x.strip().strip("\"'") for x in v[1:-1].split(",") if x.strip()]
            else:
                v = v.strip("\"'")
            out[k.strip()] = v
    return out


def unique_path(path):
    if not path.exists():
        return path
    for n in range(2, 1000):
        cand = path.with_name(f"{path.stem} ({n}){path.suffix}")
        if not cand.exists():
            return cand
    raise RuntimeError(f"too many copies of {path}")


# --------------------------------------------------------------------------- games
def load_games():
    games = {}
    for f in sorted(GAMES.glob("*.md")):
        text = f.read_text(encoding="utf-8")
        fm = frontmatter(text)
        name = fm.get("game") or f.stem
        aliases = fm.get("aliases") or []
        if isinstance(aliases, str):
            aliases = [aliases]
        games[name] = {"file": f, "fm": fm, "text": text, "aliases": aliases}
    return games


def make_stub(game):
    GAMES.mkdir(parents=True, exist_ok=True)
    path = GAMES / f"{safe_name(game)}.md"
    if path.exists():
        return path
    tpl = TEMPLATE.read_text(encoding="utf-8") if TEMPLATE.exists() else f"# {{{{game}}}}\n\n{AUTO_START}\n{AUTO_END}\n"
    path.write_text(tpl.replace("{{game}}", game).replace("{{date}}", today()), encoding="utf-8")
    return path


def guess_game(path, games):
    """Inbox file -> game name (or None for unsorted)."""
    parts = path.relative_to(INBOX).parts
    if len(parts) > 1:
        return parts[0]
    stem = path.stem
    if " - " in stem:
        return stem.split(" - ", 1)[0].strip()
    # whole-word match ("gag_mutation" matches alias GaG, "garage" does not), or the joined name
    # inside the file name for longer names ("growagarden_clip" matches Grow a Garden)
    tokens = re.findall(r"[a-z0-9]+", stem.lower())
    joined = norm(stem)
    best = None
    for name, g in games.items():
        for cand in [name] + g["aliases"]:
            ct = re.findall(r"[a-z0-9]+", cand.lower())
            if not ct:
                continue
            hit = any(tokens[i:i + len(ct)] == ct for i in range(len(tokens) - len(ct) + 1))
            hit = hit or (len(norm(cand)) >= 6 and norm(cand) in joined)
            if hit and (best is None or len(norm(cand)) > best[1]):
                best = (name, len(norm(cand)))
    return best[0] if best else None


def canonical_game(name, games):
    n = norm(name)
    for g, info in games.items():
        if norm(g) == n or any(norm(a) == n for a in info["aliases"]):
            return g
    return name.strip()


# --------------------------------------------------------------------------- inbox
def file_inbox(registry, games, report):
    if not INBOX.exists():
        return
    known = {v["sha256"]: k for k, v in registry.items()}
    for path in sorted(INBOX.rglob("*")):
        if not path.is_file() or path.name.lower() == "readme.md" or path.name.startswith("."):
            continue
        if "_duplicates" in path.relative_to(INBOX).parts:
            continue
        ext = path.suffix.lower()
        if ext not in VIDEO | IMAGE:
            report["unsupported"].append(rel(path))
            continue
        digest = sha256(path)
        if digest in known:
            dup = unique_path(INBOX / "_duplicates" / path.name)
            dup.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(path), str(dup))
            report["duplicates"].append({"file": rel(dup), "same_as": known[digest]})
            continue
        guess = guess_game(path, games)
        game = canonical_game(guess, games) if guess else UNSORTED
        if game != UNSORTED and game not in games:
            make_stub(game)
            games.update({k: v for k, v in load_games().items() if k not in games})
            report["new_games"].append(game)
        stem = path.stem.split(" - ", 1)[1].strip() if " - " in path.stem and len(path.relative_to(INBOX).parts) == 1 else path.stem
        dated = stem if re.match(r"\d{4}-\d{2}-\d{2}", stem) else f"{today()} {stem}"
        size = path.stat().st_size
        base = LARGE if size > LARGE_BYTES else MEDIA
        dest = unique_path(base / safe_name(game) / f"{safe_name(dated)}{ext}")
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(path), str(dest))
        known[digest] = rel(dest)
        registry[rel(dest)] = {"sha256": digest, "filed": today(), "original": path.name, "bytes": size}
        report["filed"].append({"file": rel(dest), "game": game, "large": base == LARGE})
        if WARN_BYTES < size <= LARGE_BYTES:
            report["warnings"].append(f"{rel(dest)} is {size // (1 << 20)} MB: fine for git, slow for Obsidian Git on a phone")
    # remove now-empty inbox subfolders (never files)
    for d in sorted([p for p in INBOX.rglob("*") if p.is_dir()], key=lambda p: -len(p.parts)):
        if d.name != "_duplicates" and not any(d.iterdir()):
            d.rmdir()


# --------------------------------------------------------------------------- media scan
def ffmpeg_ok():
    return shutil.which("ffmpeg") is not None and shutil.which("ffprobe") is not None


def video_duration(path):
    try:
        out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of",
                              "default=nw=1:nk=1", str(path)], capture_output=True, text=True, timeout=60)
        return float(out.stdout.strip())
    except Exception:
        return None


def frame_sheets(video, report):
    """Up to 4 contact sheets of 12 frames (4x3) spread over the video."""
    out_dir = video.parent / "_frames" / video.stem
    sheets = sorted(out_dir.glob("sheet_*.jpg"))
    done = out_dir / "frames.json"  # written last: sheets without it are an interrupted run
    if sheets and done.exists() and done.stat().st_mtime >= video.stat().st_mtime:
        return sheets, json.loads(done.read_text(encoding="utf-8"))
    if not ffmpeg_ok():
        return [], {"pending": "ffmpeg not installed"}
    dur = video_duration(video)
    if not dur:
        report["warnings"].append(f"could not read the length of {rel(video)}")
        return [], {"pending": "unreadable"}
    interval = max(1.0, dur / 48)
    out_dir.mkdir(parents=True, exist_ok=True)
    for old in out_dir.glob("sheet_*.jpg"):
        old.unlink()  # our own generated sheets only
    cmd = ["ffmpeg", "-v", "error", "-y", "-i", str(video), "-vf", f"fps=1/{interval:.3f},scale=480:-2,tile=4x3",
           "-frames:v", "4", "-q:v", "5", str(out_dir / "sheet_%02d.jpg")]
    try:
        subprocess.run(cmd, check=True, capture_output=True, timeout=600)
    except Exception as e:
        report["warnings"].append(f"frame sheets failed for {rel(video)}: {e}")
        return [], {"pending": "ffmpeg error"}
    meta = {"duration_s": round(dur, 2), "seconds_between_frames": round(interval, 2), "grid": "4x3, left to right, top to bottom"}
    (out_dir / "frames.json").write_text(json.dumps(meta, indent=1) + "\n", encoding="utf-8")
    report["frames"].append(rel(video))
    return sorted(out_dir.glob("sheet_*.jpg")), meta


def scan_media(registry, report, make_frames=True):
    media = []
    if not MEDIA.exists():
        return media
    seen = set()
    for path in sorted(MEDIA.rglob("*")):
        if not path.is_file() or "_frames" in path.parts or path.suffix.lower() not in VIDEO | IMAGE:
            continue
        r = rel(path)
        seen.add(r)
        entry = registry.get(r)
        if not entry:  # added or moved by hand: match by hash, else register now
            digest = sha256(path)
            moved = next((k for k, v in registry.items() if v["sha256"] == digest and k not in seen and not (ROOT / k).exists()), None)
            entry = registry.pop(moved) if moved else {"sha256": digest, "filed": today(), "original": path.name, "bytes": path.stat().st_size}
            registry[r] = entry
        large = LARGE in path.parents
        game_dir = path.relative_to(LARGE if large else MEDIA).parts[0]
        item = {"file": r, "game": game_dir, "kind": "video" if path.suffix.lower() in VIDEO else "image",
                "bytes": path.stat().st_size, "filed": entry["filed"], "large": large}
        if item["kind"] == "video" and make_frames:
            sheets, meta = frame_sheets(path, report)
            item["frames"] = [rel(s) for s in sheets]
            item["frames_meta"] = meta
        media.append(item)
    for gone in [k for k in registry if k not in seen]:
        registry.pop(gone)
    return media


# --------------------------------------------------------------------------- reference log + mentions
LINK = re.compile(r"\[\[([^\]|#]+)(?:#[^\]|]*)?(?:\|[^\]]*)?\]\]")


def parse_log():
    rows = []
    if not LOG.exists():
        return rows
    for line in LOG.read_text(encoding="utf-8").splitlines():
        if not re.match(r"^\|\s*\d{4}-\d{2}-\d{2}\s*\|", line):
            continue
        cells = [c.strip() for c in re.split(r"(?<!\\)\|", line.strip().strip("|"))]
        if len(cells) < 5:
            continue
        cells += [""] * (6 - len(cells))
        rows.append({"date": cells[0], "project": cells[1], "feature": cells[2],
                     "refs": [m.strip().split("/")[-1] for m in LINK.findall(cells[3])],
                     "influence": cells[4], "status": cells[5]})
    return rows


def design_mentions(games):
    """Links to game notes from games/*/**.md design docs: [[Game]] mentions count as influence."""
    out = {g: [] for g in games}
    lookup = {norm(g): g for g in games}
    for f in sorted((ROOT / "games").rglob("*.md")) if (ROOT / "games").exists() else []:
        text = f.read_text(encoding="utf-8", errors="ignore")
        for target in set(LINK.findall(text)):
            g = lookup.get(norm(target.split("/")[-1]))
            if g:
                out[g].append(rel(f))
    return out


def lihfolk_background(game, aliases):
    hits = []
    keys = [norm(game)] + [norm(a) for a in aliases if len(norm(a)) >= 4]
    for sec in LIHFOLK_SECTIONS:
        d = ROOT / "LihFolk Vault V2" / sec
        if not d.exists():
            continue
        for f in sorted(d.glob("*.md")):
            title = re.sub(r"^(Case Study|Teardown) - ", "", f.stem)
            if norm(title) in keys:
                hits.append(f.stem)
    return hits


# --------------------------------------------------------------------------- game notes
def hand_part(text):
    """The note without frontmatter and without the generated block."""
    text = re.sub(r"^---\r?\n.*?\r?\n---", "", text, count=1, flags=re.S)
    return re.sub(re.escape(AUTO_START) + r".*?" + re.escape(AUTO_END), "", text, flags=re.S)


def analysis_status(text):
    body = hand_part(text)
    filled = []
    for sec in ANALYSIS_SECTIONS:
        m = re.search(r"^##\s+" + re.escape(sec) + r"\s*$(.*?)(?=^##\s|\Z)", body, re.S | re.M)
        if not m:
            continue
        content = re.sub(r"<!--.*?-->", "", m.group(1), flags=re.S).strip()
        if len(re.sub(r"[\s\-*|:#>]", "", content)) >= 20:
            filled.append(sec)
    status = "analyzed" if len(filled) >= 7 else ("in progress" if filled else "stub")
    return status, filled


def media_is_analyzed(item, notes_text):
    name = Path(item["file"]).name
    stem = Path(item["file"]).stem
    return any(name in t or stem in t for t in notes_text)


def auto_block(game, info, media, influenced, mentions, background):
    lines = [AUTO_START, "## Evidence, background and influence (generated)", "",
             f"*Rewritten by `_tools/research_index.py` on {today()}. Edit above this block, never inside it.*", ""]
    mine = [m for m in media if m["game"] == safe_name(game)]
    lines.append(f"### Evidence ({len(mine)} file{'s' if len(mine) != 1 else ''})")
    if not mine:
        lines.append("No recordings or screenshots yet. Drop them in `_inbox/` (see [[Roblox Game Research]]).")
    for m in mine:
        flag = "" if m.get("analyzed") else " **(not analyzed yet)**"
        if m["large"]:
            lines.append(f"- `{m['file']}` ({m['bytes'] // (1 << 20)} MB, kept out of git){flag}")
        elif m["kind"] == "image":
            lines.append(f"- ![[{m['file']}|320]] `{Path(m['file']).name}`{flag}")
        else:
            lines.append(f"- [[{m['file']}|{Path(m['file']).name}]]{flag}")
            for s in (m.get("frames") or [])[:1]:
                meta = m.get("frames_meta") or {}
                lines.append(f"  - Frames ({meta.get('seconds_between_frames', '?')} s apart): ![[{s}|480]]")
            if not m.get("frames") and (m.get("frames_meta") or {}).get("pending"):
                lines.append(f"  - Frame sheets pending: {m['frames_meta']['pending']}")
    lines += ["", "### Background in the vault"]
    lines += [f"- [[{b}]]" for b in background] or ["- No LihFolk case study or teardown for this game."]
    lines += ["", "### Influenced (from [[Reference Log]] and design docs)"]
    if not influenced and not mentions:
        lines.append("- Nothing yet.")
    for r in influenced:
        lines.append(f"- {r['date']} · **{r['project']}** · {r['feature']}: {r['influence']} ({r['status'] or 'status?'})")
    for f in sorted(set(mentions)):
        lines.append(f"- Linked from `{f}`")
    lines.append(AUTO_END)
    return "\n".join(lines)


def write_auto(info, block):
    text = info["file"].read_text(encoding="utf-8")
    if AUTO_START in text and AUTO_END in text:
        new = re.sub(re.escape(AUTO_START) + r".*?" + re.escape(AUTO_END), lambda _: block, text, flags=re.S)
    else:
        new = text.rstrip() + "\n\n" + block + "\n"
    if new != text:
        info["file"].write_text(new, encoding="utf-8")
        return True
    return False


# --------------------------------------------------------------------------- search
STOP = set("""a an and are as at be but by can for from has have how i if in into is it its me my of on or our
our please so that the their them then there these this to us was we what when where which while who why will
with you your make add do does let lets want need should could would game games roblox new""".split())
WORD = re.compile(r"[a-z0-9]+")


def search_corpus():
    docs = []
    for f in sorted(GAMES.glob("*.md")):
        docs.append(("game", f))
    for f in sorted((ROOT / "research").rglob("*.md")):
        if SECTION in f.parents or f.name in ("TikTok Research Index.md",):
            continue
        docs.append(("research", f))
    for sec in LIHFOLK_SECTIONS:
        for f in sorted((ROOT / "LihFolk Vault V2" / sec).glob("*.md")):
            docs.append(("lihfolk", f))
    return docs


def search(query, limit=8):
    terms = [t for t in WORD.findall(query.lower()) if t not in STOP and len(t) > 1]
    if not terms:
        return []
    boost = {"game": 1.6, "research": 1.0, "lihfolk": 1.2}
    results = []
    for kind, f in search_corpus():
        text = f.read_text(encoding="utf-8", errors="ignore")
        fm = frontmatter(text)
        body = re.sub(r"<!--.*?-->", "", hand_part(text), flags=re.S).lower()  # template prompts are not content
        title = f.stem.lower()
        tags = " ".join(fm.get("tags", []) if isinstance(fm.get("tags"), list) else [str(fm.get("tags", ""))]).lower()
        heads = " ".join(re.findall(r"^#+\s+(.*)$", body, re.M))
        score, hit_terms = 0.0, 0
        for t in terms:
            n_body = len(re.findall(r"\b" + re.escape(t), body))
            s = 5 * (t in title) + 3 * (t in tags) + 2 * (t in heads) + min(n_body, 10) * 0.4
            if s:
                hit_terms += 1
            score += s
        if score:
            score *= boost[kind] * (hit_terms / len(terms)) ** 2
            best = None
            for h in re.findall(r"^#{2,3}\s+(.*)$", hand_part(text), re.M):
                if any(t in h.lower() for t in terms):
                    best = h.strip()
                    break
            results.append({"score": round(score, 2), "kind": kind, "title": f.stem, "path": rel(f), "section": best})
    results.sort(key=lambda r: -r["score"])
    return results[:limit]


# --------------------------------------------------------------------------- index
def build(make_frames=True):
    report = {"filed": [], "duplicates": [], "unsupported": [], "new_games": [], "frames": [], "warnings": []}
    registry = json.loads(REGISTRY.read_text(encoding="utf-8")) if REGISTRY.exists() else {}
    games = load_games()
    file_inbox(registry, games, report)
    media = scan_media(registry, report, make_frames)
    games = load_games()
    for m in media:  # media in a folder with no note yet (moved by hand)
        if m["game"] not in (UNSORTED, "_large") and canonical_game(m["game"], games) not in games:
            make_stub(m["game"])
            report["new_games"].append(m["game"])
    games = load_games()
    notes_text = [hand_part(g["text"]) for g in games.values()]
    for m in media:
        m["analyzed"] = media_is_analyzed(m, notes_text)
    log = parse_log()
    mentions = design_mentions(games)
    rows = []
    for name, info in games.items():
        mine_dir = safe_name(name)
        influenced = [r for r in log if any(norm(x) == norm(name) or any(norm(x) == norm(a) for a in info["aliases"]) for x in r["refs"])]
        background = lihfolk_background(name, info["aliases"])
        if write_auto(info, auto_block(name, info, media, influenced, mentions.get(name, []), background)):
            report.setdefault("updated_notes", []).append(info["file"].stem)
        status, filled = analysis_status(info["file"].read_text(encoding="utf-8"))
        mine = [m for m in media if m["game"] == mine_dir]
        rows.append({"game": name, "note": rel(info["file"]), "genre": info["fm"].get("genre", ""),
                     "relevant_to": info["fm"].get("relevant_to", []), "status": status, "sections_filled": filled,
                     "media": len(mine), "media_unanalyzed": sum(1 for m in mine if not m["analyzed"]),
                     "influenced": [f"{r['project']}: {r['feature']}" for r in influenced],
                     "design_mentions": sorted(set(mentions.get(name, []))), "background": background})
    REGISTRY.parent.mkdir(parents=True, exist_ok=True)
    REGISTRY.write_text(json.dumps(registry, indent=1, sort_keys=True) + "\n", encoding="utf-8")
    pending_inbox = [rel(p) for p in INBOX.rglob("*") if p.is_file() and p.name.lower() != "readme.md"
                     and "_duplicates" not in p.parts] if INBOX.exists() else []
    data = {"generated": today(), "games": rows, "media": media, "decisions": log,
            "unsorted": [m["file"] for m in media if m["game"] == UNSORTED],
            "needs_analysis": [m["file"] for m in media if not m["analyzed"]], "inbox_pending": pending_inbox}
    write_index(data)
    return data, report


def write_index(data):
    L = ["---", "title: Research Index", "tags: [game-research, index]", "---", "", "# Research Index", "",
         "Generated by `_tools/research_index.py`. **Do not edit by hand; rerun the script** (Claude Code runs it at the "
         "start of every session). Machine-readable copy: `research-index.json`. Back to [[Roblox Game Research]].", ""]
    need = data["needs_analysis"]
    L += [f"**Inbox:** {len(data['inbox_pending'])} file(s) waiting · **Needs analysis:** {len(need)} · "
          f"**Unsorted:** {len(data['unsorted'])} · **Games:** {len(data['games'])} · **Logged decisions:** {len(data['decisions'])}", ""]
    L += ["## Games", "", "| Game | Genre | Status | Media (not analyzed) | Relevant to | Influenced | Background |", "|---|---|---|---|---|---|---|"]
    for g in sorted(data["games"], key=lambda r: r["game"].lower()):
        rt = ", ".join(g["relevant_to"]) if isinstance(g["relevant_to"], list) else g["relevant_to"]
        bg = ", ".join(f"[[{b}]]" for b in g["background"]) or "-"
        infl = len(g["influenced"]) + len(g["design_mentions"])
        L.append(f"| [[{g['game']}]] | {g['genre'] or '-'} | {g['status']} | {g['media']} ({g['media_unanalyzed']}) | {rt or '-'} | {infl} | {bg} |")
    L += ["", "## Needs analysis", ""]
    L += [f"- `{f}`" for f in need] or ["- Nothing waiting."]
    if data["unsorted"]:
        L += ["", "## Unsorted (move into Media/<Game>/ or rename to \"Game - name\" and drop in the inbox again)", ""]
        L += [f"- `{f}`" for f in data["unsorted"]]
    L += ["", "## Recent decisions (from [[Reference Log]])", "", "| Date | Project | Feature | References |", "|---|---|---|---|"]
    for r in sorted(data["decisions"], key=lambda r: r["date"], reverse=True)[:15]:
        L.append(f"| {r['date']} | {r['project']} | {r['feature']} | {', '.join(f'[[{x}]]' for x in r['refs'])} |")
    if not data["decisions"]:
        L.append("| - | - | - | - |")
    L.append("")
    text = "\n".join(L)
    if not INDEX_MD.exists() or INDEX_MD.read_text(encoding="utf-8") != text:
        INDEX_MD.write_text(text, encoding="utf-8")
    js = json.dumps(data, indent=1) + "\n"
    if not INDEX_JSON.exists() or INDEX_JSON.read_text(encoding="utf-8") != js:
        INDEX_JSON.write_text(js, encoding="utf-8")


# --------------------------------------------------------------------------- hooks
DECISION = re.compile(r"\b(design|redesign|add|adding|implement|build|create|overhaul|improve|change|plan|rework|"
                      r"balance|rebalance|feature|mechanic|progression|economy|monetiz|monetis|shop|onboarding|tutorial|"
                      r"reward|ui|ux|hud|level|map|gameplay|loop|retention|first 60|gamepass|game pass|pet|egg|upgrade|rebirth)", re.I)
GAME_CONTEXT = re.compile(r"\b(game|roblox|player|players|studio|grow a monster|snatch the sun|vfx lab)\b", re.I)


def context_json(event, text):
    return json.dumps({"hookSpecificOutput": {"hookEventName": event, "additionalContext": text}})


def hook_session():
    data, report = build()
    msg = []
    if report["filed"]:
        by = {}
        for f in report["filed"]:
            by[f["game"]] = by.get(f["game"], 0) + 1
        msg.append("Research inbox processed: " + ", ".join(f"{g} {n}" for g, n in by.items()) + ".")
    if report["duplicates"]:
        msg.append(f"{len(report['duplicates'])} duplicate(s) moved to _inbox/_duplicates/ (nothing deleted).")
    if report["unsupported"]:
        msg.append(f"Unsupported files left in the inbox: {', '.join(report['unsupported'][:5])}.")
    if data["needs_analysis"]:
        msg.append(f"{len(data['needs_analysis'])} reference file(s) need analysis (see research/Roblox Game Research/Research Index.md; "
                   "follow the game-research skill when the owner wants research done).")
    if data["unsorted"]:
        msg.append(f"{len(data['unsorted'])} file(s) in Media/_Unsorted need a game.")
    if msg:
        print(context_json("SessionStart", "Roblox Game Research: " + " ".join(msg)))


def hook_prompt():
    try:
        event = json.load(sys.stdin)
    except Exception:
        return
    prompt = str(event.get("prompt", ""))
    if len(prompt) < 12 or not DECISION.search(prompt) or not GAME_CONTEXT.search(prompt):
        return
    hits = search(prompt, limit=5)
    lines = ["Game-design reference check (CLAUDE.md, Game research): this request looks like a game-development decision. "
             "Before deciding, read the relevant references below (and search more with "
             "`python \"research/Roblox Game Research/_tools/research_index.py\" --consult \"...\"`), say which ones you used, "
             "and add a row to research/Roblox Game Research/Reference Log.md for any feature you design or change."]
    if hits:
        lines.append("Most relevant references:")
        for h in hits:
            where = f" (section: {h['section']})" if h["section"] else ""
            lines.append(f"- {h['path']}{where}")
    else:
        lines.append("No matching reference found in the research section; say so and consider capturing references first.")
    print(context_json("UserPromptSubmit", "\n".join(lines)))


# --------------------------------------------------------------------------- main
def main(argv):
    if "--hook" in argv:
        kind = argv[argv.index("--hook") + 1] if len(argv) > argv.index("--hook") + 1 else ""
        try:
            hook_session() if kind == "session" else hook_prompt()
        except Exception as e:  # a hook must never break the session
            print(context_json("SessionStart" if kind == "session" else "UserPromptSubmit", f"Roblox Game Research hook error: {e}"))
        return 0
    if "--search" in argv or "--consult" in argv:
        flag = "--search" if "--search" in argv else "--consult"
        q = " ".join(argv[argv.index(flag) + 1:])
        hits = search(q, limit=10)
        if "--json" in argv:
            print(json.dumps(hits, indent=1))
        else:
            for h in hits:
                sec = f"  > {h['section']}" if h["section"] else ""
                print(f"{h['score']:7.2f}  [{h['kind']}] {h['path']}{sec}")
            if not hits:
                print("no matches")
        return 0
    data, report = build(make_frames="--no-frames" not in argv)
    for f in report["filed"]:
        print(f"filed     {f['file']}" + ("  (large: git-ignored)" if f["large"] else ""))
    for d in report["duplicates"]:
        print(f"duplicate {d['file']}  (same as {d['same_as']})")
    for u in report["unsupported"]:
        print(f"skipped   {u}  (not a video or image)")
    for g in report["new_games"]:
        print(f"new game  {g}  (stub note created)")
    for v in report["frames"]:
        print(f"frames    {v}")
    for w in report["warnings"]:
        print(f"warning   {w}")
    print(f"index: {len(data['games'])} games, {len(data['media'])} media, {len(data['needs_analysis'])} need analysis, "
          f"{len(data['decisions'])} logged decisions" + ("" if ffmpeg_ok() else " (ffmpeg not found: no frame sheets)"))
    if "--check" in argv and (data["inbox_pending"] or data["needs_analysis"] or data["unsorted"]):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
