---
name: game-style-spec
description: 'Build or update a game''s style spec (look, palette, UI, VFX, sound, feel) from games/_templates/STYLE-SPEC.md by asking the owner questions until it is agreed, then lock it. Use when starting a new game, before making assets, or when output looks inconsistent or "AI-made".'
---

# Game style spec

Template: `games/_templates/STYLE-SPEC.md` → `games/<game>/STYLE-SPEC.md`. One per game. Don't choose the style yourself: the owner decides; your job is to make the choices concrete and testable.

## Loop
1. **Start from the owner's words.** Ask for 1–3 games, films or images they like and one sentence on the feeling. Fill section 1 only from what they said.
2. **Ask in small rounds** (max 4 questions per round, multiple choice where possible): shape language, palette mood, UI style, sound mood, detail level, mobile priority. Offer 2–3 concrete options per question, described in words (and, if the owner wants, concept images they generate or approve).
3. **Write it down after each round** in the spec, marked Draft. Show only what changed.
4. **Make it testable:** every section ends in something checkable (hex colours, a word count, a timing in ms, a contrast ratio, a texel density). Vague words ("cool", "clean") get replaced by numbers or examples.
5. **Prove it with one sample** only if the owner asks: one prop or one UI button in the style, scored with `quality-score`. No gameplay, no full screens.
6. **Lock** when the owner says so: status Locked + date. Later changes need their OK and a changelog line.

## Rules
- References are targets for *qualities* (outline weight, palette mood), never for copying characters, logos, UI layouts or names (vault rule: original art only).
- Keep it under ~2 pages. A spec nobody reads is worse than a short one.
- Every asset task afterwards starts by reading the spec; mismatches are findings in `agent-work-review`.
