---
title: Recurring Mistakes
tags: [learning, mistakes]
---

# Recurring Mistakes

Mistakes that happened more than once, and what now stops them. Workflow: [[Learning Workflow]]. Raw entries: [[Lessons Log]].

**Enforced** = a tool, test or hook catches it automatically. **Rule** = written instruction only (weaker; enforce when possible).

| Mistake | Times | Last seen | Prevention | How |
|---|---|---|---|---|
| Committing files a check rewrote (generated reports with only a new date) | 2 | 2026-11-20 | `git status` before commit; restore date-only report changes; commit only the reviewed paths | Rule, plus the agent-work review checklist |
| Code that passes compile but breaks with Roblox types (unknown members, nil passed as string) | baseline | 2026-11-20 | `python dev/lint/lint.py` must show 0 new findings before a change is approved | Enforced (CI `lint` job) |
| Tests that quietly stop running a check | 1 | 2026-11-20 | A vanished PASS check is a regression | Enforced (`rbxtest.py`, CI self-test) |
