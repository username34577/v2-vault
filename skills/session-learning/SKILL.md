---
name: session-learning
description: 'End-of-session capture: record verified lessons, recurring mistakes and fixes in learning/, and promote them into SYMPTOMS, lint, hooks or rules. Use for "wrap up", "what did we learn", end of a work session.'
---

# Session learning

Full rules: `learning/Learning Workflow.md`. Log: `learning/Lessons Log.md`. Recurring: `learning/Recurring Mistakes.md`.

1. **Collect** from this session only: failed commands, wrong assumptions, owner corrections, test or lint failures, anything that took more than one try. Skip the things that just worked.
2. **Write one entry per lesson** at the top of the log using the entry template. Every entry needs **evidence**: the command and its result, a test report path, a commit, or an official doc link with the date read. Label it **Verified**, **Partially Verified** or **Unverified**.
3. **Check for repeats**: grep `learning/Recurring Mistakes.md` and `LihFolk Vault V2/SYMPTOMS.md` for the same mistake. A repeat bumps the count and date; a second occurrence adds a row with a prevention rule.
4. **Promote** (only Verified lessons):
   - Roblox symptom with cause and fix → one line in `SYMPTOMS.md` (`symptom | cause | fix | [[note]]`).
   - A tool can catch it → enforce it in `dev/lint/` config, `hooks/scripts/rules.tsv`, or an rbxtest check. Prefer this.
   - Process mistake → propose one line for `CLAUDE.md` or `AGENTS.md`, and ask the owner first.
5. **Report** to the owner in 3 lines max: lessons added, what was promoted, anything waiting for their OK.

Never log secrets, account data or player data. Don't invent lessons to fill the log: an empty session is a fine result.
