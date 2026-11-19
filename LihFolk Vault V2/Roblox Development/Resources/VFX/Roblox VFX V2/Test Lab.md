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
> - Added 2026-11-19 so Studio results are measured, not eyeballed.
> - Run B on PC, then in the device emulator, then (best) on a real phone through Studio's Test on device or a private server.
>
> Cost: TL;DR ~140 tok · whole note ~3.2k tok. Read more: ## Automated suite (run in Studio) · ## Results in Studio (fill in)
<!-- tldr:end -->

Part of [[Roblox VFX V2]]. Related: [[Roblox VFX V2/Integration|Integration]] · [[Roblox VFX V2/Examples|Examples]] · [[Roblox VFX V2/Troubleshooting|Troubleshooting]]

`games/vfx-lab/` (at the repo root, next to `games/snatch-the-sun/`) is a minimal Rojo project for testing effects in Roblox Studio before they go into a game. It uses the same layout as the other games (`src/shared` → `ReplicatedStorage.Shared`, `src/server` → `ServerScriptService.VFXLab`, `src/client` → `StarterPlayerScripts.VFXLabClient`), and every effect in it runs through the code a real game would use.

> [!warning] Studio test status: NOT RUN YET
> No test in this note has been executed inside Roblox Studio. Three cloud sessions (2026-11-19) built and checked the lab outside Studio; the third tried to start Studio testing and could not: no Studio MCP tools in the session, and no computer of yours shared with it (Rojo, Studio and the MCP all run on your Windows PC). Everything under *Verified outside Studio* is a simulated or static check. Rows under *Results in Studio* stay "not run" until someone runs them.

## Studio test status log

| Date | Where | What happened |
|---|---|---|
| 2026-11-19 (automated) | Laptop, rbxtest | First no-click run: local 27 PASS / 0 FAIL / 3 INFO, replication 6/6. Absolute FPS throttled to 15 (baseline too), relative overhead still passes. See [[Automated Studio Test Runs (rbxtest)]] |
| 2026-11-19 (pass 3) | Cloud session | Attempted Studio testing: **blocked**, PC not reachable (no Studio MCP tools, no shared computer). Built the automated suite below and `tools/windows_setup_check.ps1`. Nothing run in Studio |

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

## Automated suite (run in Studio)

Added 2026-11-19 so Studio results are measured, not eyeballed. Client: `src/client/LabTests.luau`; server: `src/server/LabTests.luau`. Each check prints `[VFXLab test] PASS|FAIL|INFO ...`, and each suite ends with one line `VFXLAB_RESULTS {json}` to paste below.

| Priority | Suite and check | Pass condition |
|---|---|---|
| 1. Rendering | local: SunBurst / SunVictory build on Low, Medium, High | Emitters created; light counts by preset (Low drops flash lights) |
| 1. Rendering (looks) | `LabTests.freeze(name, age)` then a screenshot, `LabTests.unfreeze()` | **Judged by eye**: no automated pass. Ages to capture: SunBurst 0.05 / 0.15 / 0.4, SunVictory 0.2 / 0.6 / 1.1, SunAura 1.0 |
| 2. Replication | replication (server, **needs 2+ clients**): aura on player 1 seen by all; steal burst played on all (each client's own played counter rises); aura moves to player 2 on all; victory on all; aura gone after drop | Every client answers as expected (the server asks each client what it shows) |
| 3. Camera | local: kit switches to Scriptable; restored to Custom + own Humanoid after the effect; FOV restored; second cinematic denied; **death mid-cinematic releases the guard**; correct after respawn | As stated (the suite kills you once via a lab-only remote) |
| 4. Sun visibility | local: carrier aura on Low, Medium, High has all emitters enabled, Rate > 0, and its light on | Light must stay on Low (gameplay cue). Day/dusk looks: screenshot with key L |
| 5. Performance | local: 1 aura + a SunBurst every 0.25 s for 5 s per preset | p95 frame ≤ 16.7 ms (reported with avg FPS, worst ms, the player's saved graphics level) |
| 6. Cleanup / memory | local: 200 bursts + 50 aura attach/detach + 3 kit plays, then wait | Runtime folder empty, no leftover attachments or kit folders, runner counters 0, `Stats.InstanceCount` back within ±50; memory (total and `GraphicsParticles`) reported |

**How to run, by hand:** `rojo serve` in `games/vfx-lab`, connect, then
1. **Play** (solo), press **T**. Read Output, copy the `VFXLAB_RESULTS` line.
2. **Test tab → Clients and Servers → Local Server, 2 players → Start.** On either client press **Y**; read the **server** Output.
3. Lower-end settings: set Studio's rendering quality level to its lowest (Studio Settings → Rendering; menu names vary by Studio version, see [[Lighting Untextured Art in Roblox]]), set the lab to **Low** (key Q), press **T** again. Then **Test → Device** with a phone profile and repeat. Studio on a PC does not slow the CPU down to a phone's, so a real phone run is the only true mobile number.

**How to run with Claude Code on your PC** (Studio MCP connected): ask it to call `list_roblox_studios`, start a play test, run `require(game.Players.LocalPlayer.PlayerScripts.VFXLabClient.LabTests).runLocal()` in the **Client** context, read `get_console_output`, and take `screen_capture`s after `freeze(...)`. The two-client test still needs Studio's Local Server with 2 players. Per the vault's [[Roblox Studio MCP Server]] note, check whether the MCP can reach those extra windows (each has its own `studio_id`).

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

Only results from a real Studio run go here. Paste each `VFXLAB_RESULTS` line under the table.

| Date | Device / settings | Suite or test | Result | Notes |
|---|---|---|---|---|
| 2026-11-19 13:30 | PC (Lenovo LOQ 15, RTX 4060), Studio Play Solo, graphics Automatic | local suite (T), old perf test | 29 checks, 26 PASS, 3 FAIL | The 3 FAILs were the performance checks: absolute p95 <= 16.7 ms at Studio's 60 FPS cap (test-design issue, fixed in a74599e) |
| 2026-11-19 13:51 | same PC and settings | local suite (T), baseline-relative perf test (a74599e) | **30 checks, 0 FAIL** | New INFO line: no-effects baseline |
| 2026-11-19 | PC, Studio **Server + 2 clients** (Player1, Player2) | replication suite (Y) | **6/6 PASS** (+1 INFO: clients = 2) | Aura seen on all clients; steal burst on every client; aura leaves old carrier and appears on the new one on all clients; victory on every client; aura gone everywhere after drop |
| (not run) | PC, lowest graphics, lab Low | local suite (T) | not run yet | |
| (not run) | Device emulator (phone) | local suite (T) + keys 1-6 | not run yet | |
| (not run) | Real phone | keys 1-6, B | not run yet | |
| (not run) | PC | visual check of frozen phases (screenshots) | not run yet | |

| Preset | Device | avg FPS | p95 ms | worst ms | played / culled / capped |
|---|---|---|---|---|---|
| Baseline (no effects) | PC RTX 4060, Studio solo, 60 FPS cap | 60 | 17.9 | 18.7 | n/a |
| Low | PC RTX 4060, Studio solo | 60 | 17.8 (−0.1 vs baseline) | 18.9 | |
| Medium | PC RTX 4060, Studio solo | 59 | 17.7 (−0.2) | 18.9 | |
| High | PC RTX 4060, Studio solo | 60 | 17.8 (−0.1) | 18.7 | |

**2026-11-19 performance: what is and isn't proven.**
- The first run's 3 FAILs were a test-design issue: the check demanded absolute p95 <= 16.7 ms, but Studio caps at 60 FPS, so the no-effects baseline itself is p95 17.9 ms. All three presets measured the same.
- Fix (`a74599e`): measure a 5 s no-effects baseline first; pass if effects add <= 2 ms p95 and keep >= 95 % of baseline FPS. Absolute avg FPS, p95 and worst frame are still recorded for every preset (table above).
- Result on this PC: effects add **no measurable cost** (−0.2 to −0.1 ms, i.e. within noise).
- **This does NOT prove mobile performance.** At a 60 FPS cap on an RTX 4060 there is lots of headroom, so cost stays hidden until it exceeds the frame budget. A phone has far less headroom. Still needed: Device emulator run (not real hardware either), a **real phone** (Studio "Play on device" / published test place), and MicroProfiler CPU/GPU ms per effect for a direct cost number.

Still not run: phone emulator, real phone, lowest graphics, visual check of frozen phases.
