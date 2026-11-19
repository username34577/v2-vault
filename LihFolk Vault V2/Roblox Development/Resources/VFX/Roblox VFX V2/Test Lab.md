---
tags: [resources, vfx, tool, testing, studio, rojo, performance, roblox-vfx, type/guide, area/vfx, level/intermediate]
source: games/vfx-lab (this repo)
researched: 2026-11-19
---
# Test Lab

<!-- tldr:start -->
> [!tldr] TL;DR
> - Arena: a 600 × 160 floor, a sun pedestal with a Neon sun prop, and distance markers at 25, 50, 100, 150, 250 and 400 studs...
> - `cd games/vfx-lab` and `rojo serve`. In Studio: new Baseplate → Rojo → Connect.
> - Run B on PC, then in the device emulator, then (best) on a real phone through Studio's Test on device or a private server.
> - What the previews changed. The first renders showed the aura nearly invisible in daylight (corona at most 45 % opaque, drawn...
>
> Cost: TL;DR ~160 tok · whole note ~1.6k tok. Read more: ## Run it (on your PC) · ## Verified outside Studio (2026-11-19, cloud)
<!-- tldr:end -->

Part of [[Roblox VFX V2]]. Related: [[Roblox VFX V2/Integration|Integration]] · [[Roblox VFX V2/Examples|Examples]] · [[Roblox VFX V2/Troubleshooting|Troubleshooting]]

`games/vfx-lab/` (at the repo root, next to `games/snatch-the-sun/`) is a minimal Rojo project for testing effects in Roblox Studio before they go into a game. It uses the same layout as the other games (`src/shared` → `ReplicatedStorage.Shared`, `src/server` → `ServerScriptService.VFXLab`, `src/client` → `StarterPlayerScripts.VFXLabClient`), and every effect in it runs through the code a real game would use.

## What is in it

- **Arena:** a 600 × 160 floor, a sun pedestal with a Neon sun prop, and distance markers at 25, 50, 100, 150, 250 and 400 studs (for the culling test). A spawn pad, and a **dummy** (default R15 avatar, anchored) built with `Players:CreateHumanoidModelFromDescriptionAsync`.
- **Test panel** (top-left, keyboard shortcuts): every Snatch the Sun effect through real server cues, a quality switch, safe and unsafe camera tests, day/dusk lighting, a stress test, a benchmark, and clear-all. Live stats: FPS, worst frame, memory, live bursts and loops, played/culled/capped counts, kits playing, camera type and owner.
- **Effects:** `SunAura`, `SunBurst`, `SunVictory` (VFXKit recipes on stock textures) and the `EclipseRend` Studio kit (the camera test; its textures still need uploading, so it draws blank or untextured, but timing and the camera still test).
- **Lab-only remote** `VFXLabRequest` (allowlisted actions and targets, token bucket of 6 at 4/s) so the panel can ask the server to fire cues. Real games have no such remote: gameplay code calls `VFXServer` directly.

## Run it (on your PC)

1. `cd games/vfx-lab` and `rojo serve`. In Studio: new **Baseplate** → Rojo → **Connect**.
2. Press **Play**. The server removes the Baseplate and builds the arena.
3. Run the tests below; then **Test → Device** (a phone in landscape) and repeat 1-6 and B.
4. Write the results into the tables at the end of this note.

| Key | Test | Expect |
|---|---|---|
| 1 | Aura on dummy (toggle) | Gold glow on the chest plus a warm light on the floor; toggling off fades out in under about 1 s |
| 2 | Steal burst on dummy | 1-frame star flash, gold puff, spark spray, one light pulse |
| 3 | Victory on dummy | Gold + sky-blue fountain at the feet, star pops, a soft dome; about 1.5 s |
| 4 | Steal: dummy ↔ me | Burst where the sun was; the aura moves to the other character (state via attribute) |
| 5 | Burst at 150 studs | Plays on Medium/High; **skipped on Low** (cull distance 120) and counted as culled |
| 6 | Burst storm | Output: `storm: 10 of 30 SunBurst cues sent (server cap 10/s)` |
| Q | Cycle quality | Low drops flash lights but keeps the aura's light; auras rebuild at the new rate |
| 7 | Kit, gameplay mode | EclipseRend plays; camera never moves |
| C | Kit, cinematic | Camera takes the kit's shot, then **returns to Custom** about 2.1 s later (`DURATION` 1.6 + 0.5) |
| V | Two cinematics 0.4 s apart | First owns the camera; second plays without screen effects |
| button | Repro: raw kit | The upstream bug on purpose: camera stays `Scriptable`. Press R to recover |
| R | Reset camera | Camera back to Custom on your character |
| L | Day / dusk | The carrier glow must read in the dark (Snatch the Sun's "the sun still glows in hiding spots") |
| 8 | Stress: 10 carriers | 10 local dummies with auras |
| B | Benchmark | About 20 s: 10 carriers plus a SunBurst every 0.15 s, 5 s per preset; prints a table to Output (F9) |
| X | Clear all | `bursts live 0`, `loops 0`, nothing left in `workspace.VFXRuntime` |

## Performance workflow

1. Run **B** on PC, then in the device emulator, then (best) on a real phone through Studio's **Test on device** or a private server.
2. Compare the **p95 and worst frame ms**, not average FPS: a burst that costs 2 ms on a phone shows as a worst-frame spike long before the average moves.
3. Budget for Snatch the Sun (10 players): one aura (16 live particles, measured in the sim) plus a few bursts (25 at peak each) must keep the phone's p95 under 16.7 ms on **Medium**. If not, lower `EmitMul` / `RateMul` in `src/shared/VFX/Quality.luau` before touching the recipes.
4. Background numbers per device: [[VFX Performance Budgets and Culling]].

## Verified outside Studio (2026-11-19, cloud)

| Check | Result |
|---|---|
| `bash tools/check.sh` | ALL CHECKS PASSED: 3 recipes clean (0 failures, 0 warnings), critic gate 9/9 on Eclipse Rend and on Crimson Detonation (briefed copy), kit exported (1,003 lines, under the 200K cap), manifest built, 13 Luau files syntax-clean, Roblox API check 0 findings (vault snapshot) |
| Lune compile/build gates | Skipped: Lune not installed in the cloud |
| Sim previews (`node tools/render_previews.js`) | Strips in `games/vfx-lab/library/previews/`, rendered in roblox-vfx's own simulator via `SIM.fromRecipe` |
| Live particle counts (sim, headless, after tuning) | SunAura steady 16 (peak 18) · SunBurst peak 25 · SunVictory peak 56 (once per round) |

**What the previews changed.** The first renders showed the aura nearly invisible in daylight (corona at most 45 % opaque, drawn behind the body), the victory fountain leaving the frame (about 15+ studs up), and a faint burst puff. Fixed in `tools/author_recipes.py`: the corona is drawn in front of the carrier at 45-60 % transparency, coloured layers use `LightEmission` 0.3-0.8 so the gold survives a bright sky arena, the fountain is slower with stronger gravity, and the puff is denser.

**Sim limits.** The sim draws stock `rbxasset://` textures as stand-ins (a 4-point star, a soft dot) and does not light surfaces with PointLights. Judge timing, size, colour and density in the sim; judge the real texture look and the aura's light on the floor in Studio.

## Results in Studio (fill in)

| Date | Device | Test | Result | Notes |
|---|---|---|---|---|
| (pending) | PC | 1-16 above | not run yet | |
| (pending) | Phone emulator | 1-6, B | not run yet | |

| Preset | Device | avg FPS | p95 ms | worst ms | played / culled / capped |
|---|---|---|---|---|---|
| Low | (pending) | | | | |
| Medium | (pending) | | | | |
| High | (pending) | | | | |
