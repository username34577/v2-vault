---
title: Reference Log
tags: [game-research, decisions]
---

# Reference Log

Which references influenced which feature. One row per design decision, newest at the bottom. `_tools/research_index.py` reads this table and shows each row on the referenced game's note (section *Influenced*) and in the [[Research Index]]. Back to [[Roblox Game Research]].

**Rules**
- Add a row whenever a feature is designed, changed or dropped because of a reference, or when the references were consulted and rejected (say so in *How*).
- *References*: wikilinks. Game notes (`[[Grow a Garden]]`), LihFolk case studies, TikTok notes and market notes all count. Only links to game notes show up on game notes.
- *Status*: proposed · decided · built · dropped.
- Rows marked *(backfilled)* were reconstructed on 2026-11-21 from the design docs named in the row.

| Date | Project | Feature / decision | References | How they influenced it | Status |
|---|---|---|---|---|---|
| 2026-11-18 | grow-a-monster | Core concept: throw food at your monster until it's huge | [[Throw Food For Animals]], [[Grow a Garden]], [[Top Roblox Games - Nov 2026]] | Mixes silly throwing (Throw Food For Animals, top 5) with grow/collect (Grow a Garden). *(backfilled: `research/Game Ideas.md`)* | built |
| 2026-11-19 | grow-a-monster | v0.2 art direction: bright, cute-cartoony, cozy, rounded | [[Grow a Garden]] | Owner's brief: "like Grow a Garden", goofy edge. *(backfilled: `games/grow-a-monster/README.md`)* | built |
| 2026-11-19 | grow-a-monster | v0.2 first 30 seconds: bouncing arrow and "Tap to feed" hint, no tutorial wall | [[funnels-and-tutorial-lockout]], [[five-game-improvements]] | TikTok research: fix the first 30 seconds without locking players in a tutorial. *(backfilled: `games/grow-a-monster/README.md`)* | built |
| 2026-11-19 | snatch-the-sun | Name "Snatch the Sun", not "Steal the ___" | [[Steal a Brainrot]], [[Steal An Egg]], [[Top Roblox Games - Nov 2026]] | The "Steal a ___" space is crowded; a trendy title gets clicks but gameplay keeps players. *(backfilled: `games/snatch-the-sun/DESIGN.md`)* | decided |
| 2026-11-19 | snatch-the-sun | Grab-and-hold loop with steal counterplay | [[Steal a Brainrot]], [[Steal An Egg]] | The design cites the steal/collect trend. Its counterplay rules (Sun Overload, 1 s no-catch after a throw) match the teardowns' "visible timer + counterplay" advice; that link is inferred, not stated in the doc. *(backfilled: `games/snatch-the-sun/DESIGN.md`, `research/Top Roblox Games - Nov 2026.md`)* | proposed |
