---
name: first-60-seconds-review
description: 'Review a playable Roblox game build for the first 60 seconds of a new player (spawn to first reward): evidence from code, Studio playtest captures and player-sim personas, scored with a fixed rubric. Use before ads, before launch, after onboarding changes. Review only: never edits gameplay.'
---

# First 60 seconds review

Why: Roblox's Recommended-for-You ranking uses **first play bounce rate** and **play-through**, and new games are tested with small ad budgets whose players decide in seconds. Every creator in the TikTok research repeated the same advice: let them play first, no wall of popups, the goal is clear in 10 seconds. This procedure checks that with evidence instead of opinion.

**Scope:** reviews an existing build and writes a report. It does not change game code. Fixes go through the normal work and `agent-work-review`.

Template: `games/_templates/FIRST-60-REVIEW.md` → copy to `games/<game>/reviews/first60-YYYY-MM-DD.md`.

## Inputs (collect before judging)
1. **Code path from join to first reward:** read the spawn, onboarding/tutorial, HUD and first-loop scripts. List every popup, menu, prompt and text a new player sees, with the line that opens it and its trigger time.
2. **Playtest captures (Studio MCP, Edit-safe):** start a solo playtest with a fresh profile (no saved data). Capture a screenshot at **0, 5, 10, 20, 30, 45 and 60 seconds** after spawn, plus the console output. Never save or publish the place. If Studio isn't available, mark the review **code-only** and say so at the top.
3. **Device views:** repeat the 0 s and 10 s captures in Studio's device emulator for a small phone and a tablet.
4. **Analytics, if the game is live:** Funnel steps and first-session numbers from Creator Hub (the owner provides them; never log in for them).

## Personas (use `roblox-player-sims`, 3 per review)
- Impatient kid (leaves at the first boring moment).
- 7-year-old who can't read (only colour, motion, icons and sound).
- Phone player on a small screen.

## Rubric (score each 0–2; total /20; ship bar 16 with no 0s)
| # | Check | 2 = | 0 = |
|---|---|---|---|
| 1 | Moving and doing the core verb | within 10 s | after 30 s or never |
| 2 | Goal understood without reading | icon/colour/motion only | needs a text panel |
| 3 | Blocking popups before first core action | none | 2 or more |
| 4 | First reward / small win | by 30 s | after 60 s |
| 5 | Next goal visible (what's coming) | shown on screen | absent |
| 6 | Text on screen | ≤ 8 words at a time, skippable | paragraphs, unskippable |
| 7 | Feedback on every core action | sound + visual | none |
| 8 | Mobile: controls and HUD | reachable, nothing overlaps | blocked or overlapping |
| 9 | Shop/monetization in first 60 s | not pushed (visible is fine) | forced open |
| 10 | Errors in console during the 60 s | none | any error |

## Output
The report (template) with: score table, timeline of the 60 s (what the player sees each step), every finding as `moment | evidence (screenshot/line) | why it hurts | suggested fix | effort`, and the top 3 fixes. Findings without evidence are labelled **Unverified**.

Then run `session-learning` if the review taught something reusable.
