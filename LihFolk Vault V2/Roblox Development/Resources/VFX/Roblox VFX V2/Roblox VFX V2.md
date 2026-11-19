---
tags: [resources, vfx, tool, claude-code-skill, roblox-vfx, type/hub, area/vfx, level/intermediate]
source: https://github.com/1nird/roblox-vfx-v2
version: "2.0.0 (commit b2a2a1d)"
researched: 2026-11-19
---
# Roblox VFX V2

**rxz Roblox VFX v2** (`1nird/roblox-vfx-v2`) is a free **Claude Code skill** for building Roblox visual effects outside Studio. Claude designs an effect as a JSON definition, you judge it frame by frame in a browser simulator of Roblox's own VFX classes, and you export a **Studio kit** (a Luau ModuleScript). A second route, the **harvester**, turns free VFX packs you own into JSON recipes and emits a runtime module called `VFXKit`.

> [!important] It is not a drop-in effects pack
> No effects ship in the box: `VFXKit.Recipes` is empty, and the three worked examples are effect *definitions* whose textures you generate and upload yourself. You get effects in your game only after you author or harvest them, upload their textures, and build the kit in Studio.

## Notes in this folder

| Note | Read it for |
|---|---|
| [[Roblox VFX V2/Overview\|Overview]] | What it does, the two routes, features, when to use it (and when the vault's own `lihfolk-vfx` skill is the better fit) |
| [[Roblox VFX V2/Prerequisites\|Prerequisites]] | Every tool it needs, what each is for, and what was installed in the cloud session |
| [[Roblox VFX V2/Installation\|Installation]] | Installing the skill (Windows and cloud), the first-run texture and mesh build, `LOCAL.md` |
| [[Roblox VFX V2/API Reference\|API Reference]] | `VFXKit.build`, the Studio kit (`buildTemplate`, `spawn`, `play`, `preload`), `HitSystem`, the CLI scripts |
| [[Roblox VFX V2/Examples\|Examples]] | Luau examples built on the real API, plus a recipe that passes the verifier |
| [[Roblox VFX V2/Integration\|Integration]] | Where everything goes in Studio and Rojo, client vs server, performance, cleanup |
| [[Roblox VFX V2/Troubleshooting\|Troubleshooting]] | Known problems: from the repo, and found while testing it, with what was fixed in our layer |
| [[Roblox VFX V2/Test Lab\|Test Lab]] | The `games/vfx-lab` Rojo project: arena, dummy, test panel, Studio test procedure, results log |

**Our layer on top of the skill** lives in `games/vfx-lab/` (repo root): a reusable runtime (`src/shared/VFX/`: quality presets, effect runner, camera guard, kit runner, cue list), multiplayer server/client modules, the VFX library with an asset manifest, the three Snatch the Sun effects, and `tools/check.sh` that validates it all. The upstream skill is left exactly as shipped.

## Status (updated 2026-11-19, third pass)

| Item | Status |
|---|---|
| Skill installed with `install.sh` into `~/.claude/skills/roblox-vfx` (cloud container) | **Verified**: loads in Claude Code |
| Full texture build: base, magic, painted, library | **Verified**: library 2,570 textures, 0 errors; `check_library.py` 0 issues (217 MB total) |
| Blender meshes and props | **Missing**: no Blender in the cloud (no apt package; only `bpy` 5.x wheels, the repo targets 4.x). None of our effects need meshes yet |
| Roblox Studio MCP | **Not configured** in the cloud session (no Studio tools, no shared computer). Studio steps run on your PC |
| `verify_vfx.py --self-test` | **Verified**: 10/10 sabotages caught |
| Critic gate on the worked examples | **Verified**: Eclipse Rend 9/9, Riptide Lance 9/9. Crimson Detonation fails only because it has no `brief`; with a brief from its own builder's docstring it passes 9/9 |
| Camera stuck after cinematic kits | **Fixed in our layer** (`CameraGuard` + `KitRunner`); upstream kit unchanged |
| Missing `sync_vt.py` (`__vt` / `__em` textures) | **Replaced** by `tools/vfx_manifest.py`; both derivations pixel-checked |
| Snatch the Sun effects (`SunAura`, `SunBurst`, `SunVictory`) | **Verified outside Studio**: 3 recipes clean, `VFXKit` emitted, previewed in the roblox-vfx sim, tuned from the previews |
| VFX Lab Rojo project | **Built and checked** (`tools/check.sh`: all passed, Roblox API check 0 findings). **Not yet run in Studio** |
| Automated Studio test suite (render, 2-client replication, camera after effect/death/respawn, sun visibility per preset, performance, cleanup/memory) | **Written, not run**: needs Studio on your PC |
| Windows setup check (`tools/windows_setup_check.ps1`) | **Written, not run** (no PowerShell or PC access from the cloud) |
| Anything inside Roblox Studio | **Not tested**: a Studio session was attempted on 2026-11-19 and was blocked (PC not reachable). Follow [[Roblox VFX V2/Test Lab\|Test Lab]] on your PC and record results there |

## Related vault notes

- [[Particle Emitters In Depth]], [[Beams and Trails]], [[VFX Design Playbook]]
- [[Replicating VFX - Server Validates, Clients Render]], [[VFX Performance Budgets and Culling]]
- [[Official Docs - Visual Effects]] (Roblox's own docs)
- Background: the TikTok research note `research/TikTok Notes/creator-rxz-dev.md` (outside this vault folder) covers rxz's videos; this repo is the first of his skills that is public.
