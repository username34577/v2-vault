---
tags: [agents, workflow, review, learning, onboarding, style, type/guide, area/ai, level/intermediate]
---
# Agent Workflows - Review, Learning, Style and First 60 Seconds

<!-- tldr:start -->
> [!tldr] TL;DR
> - Avoid: Approving from a summary instead of the packet -> Read the verdict and blockers; open the diff for anything high-stakes
> - Avoid: Logging lessons without evidence -> Every entry has a command, report, commit or doc link; Unverified...
> - Avoid: Writing a style spec with vague words -> Hex colours, word counts, timings, contrast ratios
> - Major change → packet in `reviews/` with verdict READY FOR APPROVAL (or explained exceptions).
> - End of session → lessons logged with evidence; repeats counted.
> - Before ads or launch → first 60 seconds review ≥ 16/20 with no zeros.
>
> Cost: TL;DR ~190 tok · whole note ~880 tok. Read more: ## 1. The four workflows · ## 2. Review verdicts · ## Common mistakes · ## Checklist
<!-- tldr:end -->

Four repeatable procedures that make Claude's work checkable and keep what it learns. Each is a skill in `skills/` (any agent can follow it as plain instructions) with a template or script. Set up 2026-11-20.

---

## 1. The four workflows

| Workflow | Skill | Files | Output |
|---|---|---|---|
| Agent work review | `agent-work-review` | `dev/review/make_review.py`, `reviews/` | A packet per change: diff, compile, lint (new findings only), Studio test freshness, screenshots, high-stakes flags, verdict |
| Session learning | `session-learning` | `learning/Lessons Log.md`, `learning/Recurring Mistakes.md`, `learning/Learning Workflow.md` | Verified lessons with evidence, promoted into SYMPTOMS, lint, hooks or rules |
| First 60 seconds review | `first-60-seconds-review` | `games/_templates/FIRST-60-REVIEW.md` | A scored report (/20, bar 16) of a new player's first minute, from code + playtest captures + personas |
| Game style spec | `game-style-spec` | `games/_templates/STYLE-SPEC.md` | A per-game spec with testable numbers (hex colours, word counts, timings), locked by the owner |

## 2. Review verdicts

- **READY FOR APPROVAL**: compiles, no new lint/type/format findings, fresh passing Studio tests for touched games with suites, screenshots for visual changes.
- **NEEDS WORK**: a blocker (compile error, new finding, failed self-test, possible secret).
- **NEEDS EVIDENCE**: proof is missing (stale or missing test run, missing screenshots, tools not installed).

High-stakes areas found in changed Luau (DataStore, receipts, paid random items, remotes, HTTP) are listed so the matching vault notes' *Common mistakes* and *Checklist* get read (AGENTS.md rule).

## 3. Verified (2026-11-20)

- Review script on this change set: READY FOR APPROVAL (notes, tools and skills only).
- Probe: a DataStore write plus an unused local added to a game script → NEEDS WORK, "player data / DataStore" flagged, both new findings listed; reverted.
- Probe: code appended after a module's final `return` → compile failure reported as a blocker.
- High-stakes flags read only changed Luau, so documentation that mentions DataStores doesn't trigger them.

## Common mistakes

| Mistake | Why it hurts | Fix |
|---|---|---|
| Approving from a summary instead of the packet | Claude's confidence isn't evidence | Read the verdict and blockers; open the diff for anything high-stakes |
| Logging lessons without evidence | Wrong lessons get promoted and repeated | Every entry has a command, report, commit or doc link; Unverified ones are never promoted |
| Writing a style spec with vague words | Nothing can be checked against "clean" or "cool" | Hex colours, word counts, timings, contrast ratios |
| Reviewing onboarding from code only and not saying so | Misses what players actually see | Mark the report **code-only** at the top |

## Checklist

- [ ] Major change → packet in `reviews/` with verdict READY FOR APPROVAL (or explained exceptions).
- [ ] End of session → lessons logged with evidence; repeats counted.
- [ ] Before ads or launch → first 60 seconds review ≥ 16/20 with no zeros.
- [ ] Before making assets for a game → its style spec is Locked.

## Related
- [[Luau Toolchain and Quality Gate]]
- [[Automated Studio Test Runs (rbxtest)]]
- [[Agent Review Loops and Guardrails in Practice]]
