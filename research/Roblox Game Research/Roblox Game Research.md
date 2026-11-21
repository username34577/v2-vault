---
title: Roblox Game Research
tags: [game-research, hub]
---

# Roblox Game Research

First-hand research on successful Roblox games: your recordings, screenshots and reference images, what they show about mechanics, UI, progression and design, and which of our features they shaped. It sits on top of the knowledge already in the vault and links to it instead of repeating it.

**Start here:** [[Research Index]] (generated: every game, its status, media waiting for analysis, recent decisions) · [[Reference Log]] (which references influenced which feature)

## How it fits with the rest of the vault

| Layer | Where | What |
|---|---|---|
| **First-hand research** (this section) | `research/Roblox Game Research/Games/` | Your own captures and observations, one note per game |
| Background teardowns | LihFolk [[Top Games Case Studies Start Here]], [[Viral and Trend Teardowns Start Here]], [[High-Craft Teardowns Start Here]] | 48 written teardowns; each game note links its match automatically |
| Market snapshots | [[Top Roblox Games - Nov 2026]], [[New Roblox Hits - Design Lessons (Nov 2026)]], [[Game Ideas]] | Charts, trends, idea mixes |
| Creator and video research | [[TikTok Notes]], [[TikTok Research Index]] | Dev-advice videos |
| Our games | `games/` (e.g. [[games/snatch-the-sun/DESIGN\|Snatch the Sun]]) | Design docs; `[[Game]]` links in them count as influence |

## Add a reference (phone or PC)

1. Drop recordings, screenshots or reference images into `research/Roblox Game Research/_inbox/`. Tell it which game in one of three ways:
   - put the file in a subfolder named after the game: `_inbox/Grow a Garden/shop.png`
   - or name it `Game - what it shows`: `Grow a Garden - shop restock.mp4`
   - or just include the game's name or alias in the file name (`gag_mutation.png` → Grow a Garden).
2. That's it. At the start of every Claude Code session the processor files it into `Media/<Game>/` as `<date> <name>`, makes frame sheets from videos (so Claude can study them), creates a note for a new game, and updates the index. To run it yourself: `python "research/Roblox Game Research/_tools/research_index.py"`.
3. Ask Claude to analyze it ("analyze the new Grow a Garden references"). It follows the `game-research` skill: looks at the frames, writes observations into the game note's sections, cites the file names, and labels anything it didn't see itself as Verified, Partially verified or Unverified.

**Rules the processor keeps:**
- It never deletes or overwrites anything.
- Exact duplicates go to `_inbox/_duplicates/`.
- Files over 95 MB go to `Media/_large/`, which is kept out of git (GitHub refuses files over 100 MB).
- Files it can't place go to `Media/_Unsorted/`: move them into the right game folder in Obsidian and the next run follows.

## Consult before deciding

Before a major game-development decision (a new feature, system, economy or monetization change, UI redesign, or onboarding change), Claude must check the relevant references and log the decision. This is a rule in `CLAUDE.md`. A Claude Code hook adds the most relevant references to any prompt that looks like a design decision. Search yourself with:

```
python "research/Roblox Game Research/_tools/research_index.py" --consult "shop restock timer"
```

It searches these game notes, the market and TikTok notes, and the LihFolk teardown sections. Then add a row to the [[Reference Log]]: each row shows up on the referenced game's note under *Influenced*.

## Folders

| Path | What | Edit by hand? |
|---|---|---|
| `Games/` | One note per game (from `_templates/Game Research.md`) | Yes, above the generated block |
| `_inbox/` | Drop zone | Drop files only |
| `Media/<Game>/` | Filed recordings and screenshots; `_frames/` holds generated frame sheets | Move or rename freely |
| `Reference Log.md` | Decision → references table | Yes (add rows) |
| `Research Index.md`, `research-index.json` | Generated | No |
| `_tools/` | `research_index.py` (processor, search, hooks), `test_research_index.py` (self-test), `media-registry.json` (generated) | Code only |
