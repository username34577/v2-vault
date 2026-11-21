# Style spec: <Game>

The single source of truth for how this game looks, sounds and feels. Every asset, UI screen, VFX and sound is checked against it. Built with the `game-style-spec` skill (Claude asks questions until the owner agrees). Status: **Draft** | **Locked YYYY-MM-DD** (changes after locking need the owner's OK and a changelog line).

## 1. One-line look
<e.g. "chunky hand-painted toy world, bright noon light, soft shadows"> (what someone should say after a 2-second glance)

## 2. References (original work only as targets)
| Ref | What to take from it | What NOT to take |
|---|---|---|
| | e.g. outline thickness, palette mood | characters, logos, UI layouts, names |
Store images in `games/<game>/style/refs/` (not committed if they're someone else's art; keep the links instead).

## 3. Shape language
- Main shapes (round / square / spiky) and what they mean (safe / neutral / danger):
- Proportions (chunky, realistic, stylised) and scale of the player vs props:
- Detail budget (where detail goes, where it doesn't):

## 4. Palette
| Role | Colour (hex) | Use |
|---|---|---|
| Primary | | |
| Secondary | | |
| Accent / reward | | |
| Danger | | |
| UI background | | |
| UI text | | |
Contrast rule: UI text ≥ 4.5:1 against its background (check with `rbx-ui-contrast-audit`).

## 5. Materials and lighting
- Materials (SmoothPlastic / textured / PBR) and texel density target:
- Lighting technology, time of day, Atmosphere, post-processing:
- Mobile fallback (what must still read at lowest quality):

## 6. UI
- Style (flat / 3D / sticker / ink), corner radius, stroke, fonts (max 2):
- Button states (normal / hover / pressed / disabled):
- Icon style:
- Motion (open/close timing, easing):
Build with `lihfolk-ui` / `roblox-ui-builder`.

## 7. VFX
- Shapes (stylised flipbook / soft particles / beams), colour per effect type:
- Intensity caps (screen coverage, bloom), reduced-motion behaviour:

## 8. Animation and feel
- Timing (snappy / floaty), anticipation and follow-through, hit-stop:
- Camera feedback rules:

## 9. Sound
- Palette (cartoon / realistic / synth), loudness targets, music mood:
- Sources: licensed only (Creator Store audio or an owned library); see `lihfolk-sfx`.

## 10. Do / Don't (examples the owner approved or rejected)
| Do | Don't |
|---|---|
| | |

## 11. Acceptance checks
- Every new asset is compared with sections 1–9 and scored with `quality-score` (≥ 8.5).
- A 16-year-old "is this AI-made?" pass (`roblox-player-sims`) finds no generic or mismatched pieces.

## Changelog
- YYYY-MM-DD: created
