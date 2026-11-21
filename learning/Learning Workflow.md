---
title: Learning Workflow
tags: [learning, workflow, index]
---

# Learning Workflow

How Claude keeps what it learns between sessions. Reading a note isn't training: the only memory is what gets written here and promoted into the places that are read automatically (CLAUDE.md, AGENTS.md, `SYMPTOMS.md`, lint rules, skills). Run it with the `session-learning` skill ("wrap up", "what did we learn", end of any work session).

Files:
- [[Lessons Log]]: one entry per lesson, newest first. Append-only; fix mistakes in an entry by adding a correction line.
- [[Recurring Mistakes]]: mistakes that happened more than once, with the rule that now prevents them.

## Labels (same as the TikTok research)
- **Verified**: reproduced or proven in this repo (a command, test, report or official doc, linked in the entry).
- **Partially Verified**: part is proven; say which part.
- **Unverified**: a hunch or a single unexplained observation. Allowed in the log, never promoted.

## At the end of a session (5 minutes)
1. List what went wrong or took longer than it should: failed commands, wrong assumptions, things the owner had to correct, tests that caught something.
2. For each, write a [[Lessons Log]] entry: context, what happened, root cause, fix, **evidence** (command output, test report, commit, doc link), label.
3. Search [[Recurring Mistakes]] and `LihFolk Vault V2/SYMPTOMS.md` for the same mistake. If it's there, add 1 to its count and the date instead of a new row.
4. Promote (below). A lesson that changes nothing future sessions read is only half kept.

## Promotion rules
| When | Promote to |
|---|---|
| A **Verified** lesson about Roblox behaviour (a symptom with a known cause and fix) | One line in `LihFolk Vault V2/SYMPTOMS.md` (`symptom \| cause \| fix \| [[note]]`), and a Field Note if it needs more than a line |
| The same mistake twice | A row in [[Recurring Mistakes]] with a prevention rule |
| A recurring mistake that a tool can catch | Enforce it: a selene/luau-lsp/StyLua setting (`dev/lint/`), a hook rule (`hooks/scripts/rules.tsv`), or an rbxtest check. Enforced beats remembered |
| A recurring mistake about how to work (process, git, tools) | One line in `CLAUDE.md` or `AGENTS.md`, owner's OK first |
| A procedure used 3+ times | A skill under `skills/` |

Never promote **Unverified** lessons. Never store secrets, account details or anything about players in the log.

## Weekly (or every ~10 sessions)
- Reread the last week's entries; merge duplicates; close entries whose fix shipped.
- Check that promoted rules still hold (run `python dev/lint/lint.py`, the rbxtest self-test and the vault checks).
- Count what the log prevented: a mistake that stops recurring after a rule is the measurable win.
