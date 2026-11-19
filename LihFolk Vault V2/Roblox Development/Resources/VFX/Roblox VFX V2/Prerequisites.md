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
> Cost: TL;DR ~160 tok · whole note ~1.4k tok. Read more: ## What the repo asks for · ## What the cloud session found and did (2026-11-19, two passes) · ## Your Windows PC checklist
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

Not required by the skill: Rojo (any project layout works), any paid service, or a sign-up. **Our lab** (`games/vfx-lab`, [[Roblox VFX V2/Test Lab|Test Lab]]) uses Rojo, and its sim previews use Playwright with Chromium.

## What the cloud session found and did (2026-11-19, two passes)

| Prerequisite | Before | Action | After |
|---|---|---|---|
| Claude Code | Running | none | OK |
| Python | 3.13.18 | none | OK (3.11+ needed) |
| numpy | 2.5.3 | none | OK |
| Pillow | 12.3.0 | none | OK |
| scipy | missing | `pip install --user scipy` | **1.18.1 installed** and imported |
| Node.js | v22.23.5 | none | OK, ran `studio_kit.js` and `phys_audit.js` |
| Blender | missing | investigated: no apt package; only `bpy` (Blender as a Python module) 5.x wheels exist for Python 3.13, while the repo targets Blender 4.x. Not installed (about 400 MB, unverified version), and no shipped effect needs meshes yet | **Missing here**: meshes and props not generated |
| Lune / Rokit / Aftman | missing | not installed: binary downloads from GitHub are blocked in this environment | **Missing here** |
| Roblox Studio + MCP | checked: no Studio MCP tools in the session, no shared computer folder | none possible | **Not configured here**: Studio work runs on your PC |
| Texture library | not built | `make_textures`, `make_magic_tex`, `make_painted`, `lib/build_library.py`, `lib/check_library.py` | **Built**: 2,570 textures, 0 errors, 0 QA issues (217 MB) |
| Playwright + Chromium | preinstalled | used for `tools/render_previews.js` | OK |
| three.js r128 | the sim loads it from cdnjs, which was blocked | `npm pack three@0.128.0` into scratch space, served to the page by Playwright | OK for previews (not installed anywhere permanent) |

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
