---
tags: [resources, vfx, tool, setup, roblox-vfx, type/reference, area/vfx, level/intermediate]
source: https://github.com/1nird/roblox-vfx-v2
researched: 2026-11-19
---
# Prerequisites

<!-- tldr:start -->
> [!tldr] TL;DR
> - Claude Code installed and signed in.
> - Roblox Studio, with the official Studio MCP enabled and connected to Claude Code (from the skill: run a trivial `execute_luau`...
> - Python 3.11+ on PATH, then `pip install numpy scipy pillow`.
> - Node.js (current LTS) on PATH.
> - Blender 4.x. Note the full path to `blender.exe` (usually under `C:/Program Files/Blender Foundation/Blender <version>/`).
> - Lune through Rokit or Aftman, in a tools folder whose `rokit.toml` / `aftman.toml` lists it.
>
> Cost: TL;DR ~160 tok · whole note ~1.2k tok. Read more: ## What the repo asks for · ## What this cloud session found and did (2026-11-19) · ## Your Windows PC checklist
<!-- tldr:end -->

Part of [[Roblox VFX V2]]. Previous: [[Roblox VFX V2/Overview|Overview]] · Next: [[Roblox VFX V2/Installation|Installation]]

## What the repo asks for

| Need | For | Required? |
|---|---|---|
| **Claude Code** | Running the skill at all (it is instructions for Claude) | Always |
| **Roblox Studio** with an MCP bridge (Roblox's official Studio MCP, recommended; or the third-party `robloxstudio-mcp`) | Building kits in Edit mode, harvesting packs, captures, playtests | Always, for anything in Studio |
| **Python 3.11+** | All `scripts/*.py`, texture generators, gates, `sim/serve.py` | Always |
| **numpy, scipy, Pillow** (`pip install numpy scipy pillow`) | Texture and library generators, contact sheets | For textures |
| **Blender 4.x** | `sim/mesh/make_meshes.py`, `make_props.py`, `make_dragon.py`, `obj_to_fbx.py`, `sim/blender/volume_flipbook.py` | For meshes and props |
| **Node.js** | `sim/studio_kit.js` (kit export), `sim/tools/phys_audit.js`, running `vfxsim.js` headless | For export. The README never lists Node, but the export command is `node sim/studio_kit.js` |
| **A browser Claude can drive** | Judging effects in the sim workbench (`app.strip(...)` frame strips) | For the authoring loop |
| **Lune** (in a folder whose `aftman.toml` or `rokit.toml` lists it) | `sim/tools/lune/compile_check.luau` and `build_check.luau`, the pre-Studio gates | For the gates |
| **Roblox Open Cloud API key** in an environment variable | Only if a script uploads assets for you. Only the variable's NAME goes in `LOCAL.md`, never the key | Optional |
| A Roblox account that **owns** the packs you harvest | `InsertService` refuses assets you have not taken, even free ones | Harvest route only |

Not required: Rojo (any project layout works; see [[Roblox VFX V2/Integration|Integration]] for a Rojo layout), any paid service, or a sign-up.

## What this cloud session found and did (2026-11-19)

| Prerequisite | Before | Action | After |
|---|---|---|---|
| Claude Code | Running | none | OK |
| Python | 3.13.18 | none | OK (3.11+ needed) |
| numpy | 2.5.3 | none | OK |
| Pillow | 12.3.0 | none | OK |
| scipy | missing | `pip install --user scipy` | **1.18.1 installed** and imported |
| Node.js | v22.23.5 | none | OK, ran `studio_kit.js` and `phys_audit.js` |
| Blender | missing | not installed: a large system install, and the mesh steps are better run on your PC | **Missing here** |
| Lune / Rokit / Aftman | missing | not installed: binary downloads from GitHub are blocked in this environment | **Missing here** |
| Roblox Studio + MCP | not reachable from the cloud | none possible | **Needs your PC** |

The cloud container is temporary: the installed skill, scipy and the generated textures are lost when it is recycled. For lasting use, install on your PC ([[Roblox VFX V2/Installation|Installation]]).

## Your Windows PC checklist

1. Claude Code installed and signed in.
2. Roblox Studio, with the official Studio MCP enabled and connected to Claude Code (from the skill: run a trivial `execute_luau` such as `return 1`, then a `screen_capture`, to prove the bridge works).
3. Python 3.11+ on PATH, then `pip install numpy scipy pillow`.
4. Node.js (current LTS) on PATH.
5. Blender 4.x. Note the full path to `blender.exe` (usually under `C:/Program Files/Blender Foundation/Blender <version>/`).
6. Lune through Rokit or Aftman, in a tools folder whose `rokit.toml` / `aftman.toml` lists it.
7. Optional: a Roblox Open Cloud key with asset upload permission, stored in a user environment variable.

## Configuration with LOCAL.md

The skill reads machine settings from `LOCAL.md`. Copy `LOCAL.template.md` to `LOCAL.md` in the skill folder and fill in:

| Field | Meaning |
|---|---|
| `ROBLOX_VFX_LIB` | Your recipe library folder (also an env var of the same name). Keep it **outside** the skill folder and outside cloud-synced folders |
| Studio bridge | Which MCP runs `execute_luau` and screenshots |
| Sink port | `recipe_server.py` port, default `48752` |
| Blender | Full path to `blender.exe` |
| Lune folder | Folder whose toolchain file lists Lune |
| VFX research folder | Where heavy downloads and frame strips go (outside the skill) |
| Open Cloud key | The NAME of the env var holding the key |
| Texture library and meshes | Write "built" after the first run |

`LOCAL.md` is ignored by the repo's `.gitignore` and is never packaged.

Continue with [[Roblox VFX V2/Installation|Installation]].
