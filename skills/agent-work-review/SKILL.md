---
name: agent-work-review
description: 'Before the owner approves agent work (code, tools, instructions): build a review packet with the diff, lint/type/compile results, fresh rbxtest evidence, screenshots for visual changes and high-stakes flags, using dev/review/make_review.py. Use before any push, any "is this ready?", and after every major change.'
---

# Agent work review

No major change is approved on a description alone. The owner gets a packet with evidence, and the packet decides the verdict, not Claude's confidence.

## Steps
1. **Finish the evidence first**
   - Code changed in a game with `rbxtest.json` → run `/rbx-test <game>` after the last edit (the packet flags reports older than the code).
   - UI, HUD, VFX, camera or other visual change → capture before/after screenshots in Studio (MCP screenshot tool, Edit-safe) into `reviews/shots/`.
   - New Luau files → `stylua <file>`.
2. **Build the packet:** `python dev/review/make_review.py --title "<what changed>" --shot reviews/shots/<file>.png ...`
   It writes `reviews/YYYY-MM-DD-<title>.md`: changed files by category, compile result, `dev/lint/lint.py` (new findings only), rbxtest self-test if the harness changed, latest Studio test status per touched game, screenshots, high-stakes areas touched (DataStore, receipts, paid random items, remotes, HTTP), possible secrets, date-only generated files, and the diff.
3. **Fix until the verdict is READY FOR APPROVAL**, or explain each remaining item in the packet's Notes.
   - **NEEDS WORK** = blocker (compile error, new lint/type finding, failed self-test, possible secret).
   - **NEEDS EVIDENCE** = missing proof (stale or missing Studio test run, missing screenshots, tools not installed).
4. **High-stakes areas:** for each flagged area, read the vault note's full *Common mistakes* and *Checklist* (AGENTS.md rule) and say in the packet which items you checked. For data, purchases or security, also get an independent review (`council-method`, Quick tier at least).
5. **Show the owner** the verdict, blockers and the packet path. Commit only the paths listed in the packet. **Push only after the owner says yes.**

## What counts as major
Anything that touches game code, `dev/` tools, CI, hooks, `CLAUDE.md`/`AGENTS.md`/skills, or more than ~5 files. Notes-only research can skip the packet but still needs the vault checks.
