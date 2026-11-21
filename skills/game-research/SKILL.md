---
name: game-research
description: 'Roblox game research: consult reference games before design decisions, analyze new recordings and screenshots, and log which references influenced each feature. Use for "analyze the new references", "what do top games do for X", before designing or changing a feature, economy, monetization, UI or onboarding.'
---

# Game research

Hub: `research/Roblox Game Research/Roblox Game Research.md`. Tool: `research/Roblox Game Research/_tools/research_index.py`.

## A. Before a major game-development decision (required by CLAUDE.md)
1. `python "research/Roblox Game Research/_tools/research_index.py" --consult "<the decision in plain words>"`. It searches our game notes, the market and TikTok notes, and the LihFolk teardowns. Read the top 3-5 hits that actually match (the TL;DR first, then the matching section).
2. In your reply, name the references you used and what each says about this exact case, including where they disagree with our own results (tests, design docs). If nothing matches, say so. References are evidence, not rules: the owner and the game's design doc decide.
3. After the decision, add one row to `Reference Log.md` (date, project, feature, references as wikilinks, how they influenced it, status), then rerun the tool so the game notes show it.

## B. Analyze new references (when the owner asks)
1. Run the tool (it also runs at session start). Open `Research Index.md` → *Needs analysis*.
2. For each file: images, read the image; videos, read the frame sheets in `Media/<Game>/_frames/<video>/` (`frames.json` gives the seconds between frames; grid 4x3, left to right, top to bottom). For long or important videos, extract more frames with ffmpeg into a scratch folder, never into the vault.
3. Write observations into the game note's sections (Core loop, Mechanics, UI and UX, Progression and rewards, Economy and monetization, Social and multiplayer, First 60 seconds, Steal and avoid). **Cite the file name** next to each observation; that marks the file analyzed. Give timings from frames (frame N × seconds between frames).
4. Label anything not seen in our own media: **Verified** (official source), **Partially verified**, **Unverified**. Don't copy the LihFolk teardown: link it and add only what our footage shows or contradicts.
5. Rerun the tool; report in 3 lines: files analyzed, biggest new insight, open questions for the next capture.

## C. Rules
- Never edit inside the `<!-- research:auto -->` block, `Research Index.md`, `research-index.json` or `_tools/media-registry.json`: they are generated.
- Never delete media. To re-file, move it within `Media/` (the tool follows).
- Don't commit files over 95 MB (the tool puts them in the git-ignored `Media/_large/`).
- Changing the tool: run `_tools/test_research_index.py` (all checks must pass).
