---
title: Lessons Log
tags: [learning, log]
---

# Lessons Log

Newest first. Format and rules: [[Learning Workflow]]. Recurring ones: [[Recurring Mistakes]].

Entry template:
```
### YYYY-MM-DD: short title
- Context: what I was doing
- What happened:
- Root cause:
- Fix / rule:
- Evidence: (command + result, test report, commit, doc link)
- Label: Verified | Partially Verified | Unverified
- Promoted to: (SYMPTOMS line, rule, lint, skill, or "not yet")
```

### 2026-11-20: luau-lsp gives false "Unknown require" errors unless it runs from the project folder
- Context: first Roblox type check of VFX Lab with luau-lsp + a Rojo sourcemap.
- What happened: run from the repo root, every `require(ReplicatedStorage...)` came back as `Unknown require` (14 false errors).
- Root cause: sourcemap paths are relative to the Rojo project folder.
- Fix / rule: generate the sourcemap and run `luau-lsp analyze` with the project folder as the working directory. `dev/lint/lint.py` does this.
- Evidence: same files, repo root 14× "Unknown require" vs project folder 0.
- Label: Verified
- Promoted to: `dev/lint/lint.py` (enforced)

### 2026-11-20: rbxtest passed a run where a check silently disappeared
- Context: writing self-tests for `rbxtest.py save`.
- What happened: a check that was PASS in the previous run and missing from the new one gave exit 0; a completed run with zero results also gave exit 0.
- Root cause: `compare` reported MISSING checks but only PASS→FAIL counted as a regression.
- Fix / rule: a vanished PASS check and an empty completed run now exit 1.
- Evidence: `python dev/rbxtest/test_rbxtest.py`: 2 failures before the fix, 9/9 OK after.
- Label: Verified
- Promoted to: `dev/rbxtest/rbxtest.py` + CI self-test (enforced)

### 2026-11-20: platform numbers change; check the docs, not the vault, before quoting them
- Context: TikTok favorites review.
- What happened: the vault said the Kids and Select entry threshold was 250 highly engaged players; the docs page said 100.
- Root cause: the number was lowered after the note was written.
- Fix / rule: before quoting a policy number (fees, thresholds, rates), open the official page and record the date read.
- Evidence: create.roblox.com/docs/production/publishing/kids-and-select, read 2026-11-20; vault fixed in commit 8c03f6a.
- Label: Verified
- Promoted to: not yet (needs a second occurrence for [[Recurring Mistakes]])

### 2026-11-20: tools that run checks also rewrite tracked files
- Context: committing the TikTok research.
- What happened: running `consistency.py` rewrote `_tools/reports/consistency.md` (date only), which would have gone into an unrelated commit.
- Fix / rule: after running vault checks, `git status` and restore generated reports that only changed their date before committing.
- Evidence: commit 8c03f6a excludes it after a reset.
- Label: Verified
- Promoted to: [[Recurring Mistakes]] (the agent-work review checks it)

### 2026-11-20: TikTok starts answering 403 after ~150 fast page fetches
- Context: pulling transcripts for 3 creators in a row.
- What happened: after ~140 detail fetches in a few minutes, profile and video pages returned "Access Denied" for about 10–15 minutes.
- Fix / rule: fetch in batches of 3 with a pause, and do one creator per batch.
- Evidence: 403 on @palm_dev and @bbstudios4 pages right after the @momentumcash batch (2026-11-19); the 80-favorites batch at 3-per-0.7 s finished with no 403.
- Label: Partially Verified (the exact limit is unknown)
- Promoted to: not yet

### 2026-11-20: Obsidian wiki links can't point at folders
- Context: TikTok notes linking to vault sections.
- What happened: `21 LihFolk UI Design System` and `47 Game Feel and Juice` are folders, so the links were dead.
- Fix / rule: link a note inside the folder, or write the folder name in backticks.
- Evidence: link checker over `research/TikTok Notes` reported them; 0 dead links after the fix.
- Label: Verified
- Promoted to: not yet
