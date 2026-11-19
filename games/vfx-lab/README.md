# VFX Lab

A minimal Rojo project for testing roblox-vfx effects in Roblox Studio before they go into a game, and the home of the reusable VFX layer (`src/shared/VFX/`) and library (`library/`). First user: [[games/snatch-the-sun/DESIGN|Snatch the Sun]].

Docs in the vault: `LihFolk Vault V2/Roblox Development/Resources/VFX/Roblox VFX V2/` (start at *Roblox VFX V2*, test procedure in *Test Lab*).

## Status (2026-11-19)

- Built and checked **outside Studio**: `bash tools/check.sh` passes (recipes clean, critic gate, kit export, manifest, Luau syntax, Roblox API names). Effects previewed in the roblox-vfx browser sim (`library/previews/`).
- **First Studio run 2026-11-19 (PC):** local suite (T) 29 checks, 26 PASS, 3 FAIL (performance only, likely the 60 FPS cap; see the vault's *Test Lab* note). Replication suite (Y) and phone checks not run yet.

## Layout

```
default.project.json        Rojo: src/shared -> ReplicatedStorage.Shared, src/server -> ServerScriptService.VFXLab,
                            src/client -> StarterPlayerScripts.VFXLabClient
src/shared/VFX/             REUSABLE: copy into any game
  VFXKit.luau               generated (emit_luau.py) - SunAura, SunBurst, SunVictory
  Effects.luau              runner: quality, culling, caps, cleanup for VFXKit recipes
  Quality.luau              Low / Medium / High presets (defaults from the player's graphics level)
  CameraGuard.luau          one cinematic owns the camera at a time; always restored
  KitRunner.luau            plays Studio kits safely (screen layer only when guarded)
  Cues.luau                 the allowlist of server cues + state attributes
  Assets.luau               generated (vfx_manifest.py) - uploaded asset ids for kits
  Kits/EclipseRend.luau     generated (studio_kit.js) - camera test kit
src/server/
  VFXServer.luau            REUSABLE: oneShot (interest-filtered, rate capped), setCarrying, track
  Lab.server.luau           lab only: arena, dummy, lab request remote
src/client/
  VFXClient.luau            REUSABLE: cue listener + state attribute watcher
  Perf.luau                 REUSABLE: frame-time sampler
  Lab.client.luau           lab only: test panel
library/                    recipes, effects, kits, manifest, previews (see library/README.md)
tools/                      author_recipes.py, check.sh, vfx_manifest.py, render_previews.js,
                            crimson_brief_overlay.py, luau_syntax_check.py, api_check_lab.py
```

## Before the first run (Windows)

`powershell -ExecutionPolicy Bypass -File tools\windows_setup_check.ps1` (read-only) checks Studio, its MCP launcher, Claude Code and the `Roblox_Studio` MCP registration, Rojo and its plugin, Node, Python packages, Lune and Blender, and test-builds this project. Setup steps: the vault's *Installation* note, section 6.

## First run in Studio

1. `rojo serve` in this folder. In Studio: new **Baseplate** place → Rojo → Connect.
2. Press **Play**. The server removes the Baseplate and builds the arena (floor, pedestal, distance markers at 25-400 studs, a dummy).
3. Use the panel (top-left) or keys:

| Key | Test | Expect |
|---|---|---|
| 1 | Aura on dummy (toggle) | Gold glow on the dummy's chest, warm light on the floor; off = fades out in under 1 s |
| 2 | Steal burst on dummy | 1-frame star flash, gold puff, spark spray, light pulse |
| 3 | Victory on dummy | Gold + sky-blue fountain at the feet, star pops, soft dome, about 1.5 s |
| 4 | Steal: dummy ↔ me | Burst where the sun was; aura moves to the other character |
| 5 | Burst at 150 studs | Visible on Medium/High; **skipped on Low** (cull 120) and counted as culled |
| 6 | Burst storm | Output: `storm: 10 of 30 SunBurst cues sent (server cap 10/s)` |
| Q | Cycle quality | Panel shows Low/Medium/High; auras rebuild at the new rate; Low drops flash lights, keeps the aura light |
| 7 | Kit, gameplay mode | EclipseRend plays, camera never moves |
| C | Kit, cinematic | Camera takes the kit's shot, then **returns to Custom** about 2 s later (panel shows `camera Custom`) |
| V | Two cinematics at once | First owns the camera; second plays without screen effects |
| (button) | Repro: raw kit | Upstream bug on purpose: camera stays `Scriptable`. Press R to recover |
| R | Reset camera | Camera back to Custom on your character |
| L | Day / dusk | Check the carrier glow reads in the dark |
| 8 | Stress: 10 carriers | 10 local dummies with auras |
| B | Benchmark | About 20 s; prints a Low/Medium/High table to Output (F9) |
| X | Clear all | Everything gone; `bursts live 0`, `loops 0` |
| T | Automated local suite | about 60 s (kills your character once); prints PASS/FAIL lines and a `VFXLAB_RESULTS` line |
| Y | Automated replication suite | Needs **Test → Local Server with 2 players**; results in the **server** Output |

4. Phone check: **Test → Device** (a phone in landscape), run 1-6 and B again.
5. Copy the benchmark table and anything that looked wrong into the vault's *Test Lab* note.

EclipseRend's textures have no uploaded ids yet, so its layers draw blank or untextured. Timing, cleanup and the camera still test. To see it properly: `python tools/vfx_manifest.py --stage upload/`, bulk-import, `--set` each id, rerun `bash tools/check.sh`, sync.

## Using the layer in a game (e.g. Snatch the Sun)

Server, after gameplay has decided what happened:

```lua
local VFXServer = require(game.ServerScriptService.Game.VFXServer)
VFXServer.oneShot("SunBurst", sunPosition, 1.2)   -- stolen or dropped
VFXServer.setCarrying(newCarrier, true)           -- aura follows the attribute
VFXServer.setCarrying(oldCarrier, false)
VFXServer.oneShot("SunVictory", winnerFeet, 1)
```

Client: `require(script.Parent.VFXClient).start()` once. Everything else (quality, culling, caps, cleanup, late joiners) is handled.
