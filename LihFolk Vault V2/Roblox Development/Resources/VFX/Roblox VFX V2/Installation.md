---
tags: [resources, vfx, tool, setup, install, roblox-vfx, type/guide, area/vfx, level/intermediate]
source: https://github.com/1nird/roblox-vfx-v2
researched: 2026-11-19
---
# Installation

<!-- tldr:start -->
> [!tldr] TL;DR
> - `dist/rxz-roblox-vfx-v2-v2.0.0.zip` holds the same skill.
> - What `install.sh` does (read before running, 2026-11-19): it copies `skills/roblox-vfx` to `~/.claude/skills/roblox-vfx`.
> - Copy `LOCAL.template.md` to `LOCAL.md` in `~/.claude/skills/roblox-vfx/` and fill it in (fields in Prerequisites).
> - The generated assets are not in the download.
>
> Cost: TL;DR ~130 tok · whole note ~1.4k tok. Read more: ## 4. First run: build the textures and meshes (once per machine) · ## Test log
<!-- tldr:end -->

Part of [[Roblox VFX V2]]. Previous: [[Roblox VFX V2/Prerequisites|Prerequisites]] · Next: [[Roblox VFX V2/API Reference|API Reference]]

## 1. Get the files

Download the repo (**Code → Download ZIP** on https://github.com/1nird/roblox-vfx-v2) or clone it:

```bash
git clone --depth 1 https://github.com/1nird/roblox-vfx-v2
```

`dist/rxz-roblox-vfx-v2-v2.0.0.zip` holds the same skill.

## 2. Install the skill into Claude Code

**What `install.sh` does** (read before running, 2026-11-19): it copies `skills/roblox-vfx` to `~/.claude/skills/roblox-vfx`. If that folder exists, it first moves it to `~/.claude/skills-backup-<date>/` and carries your `LOCAL.md` over. It downloads nothing and runs nothing else.

macOS, Linux or Git Bash:

```bash
cd roblox-vfx-v2
bash install.sh
```

Windows (PowerShell), the same thing by hand:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills" | Out-Null
Copy-Item -Recurse "skills\roblox-vfx" "$env:USERPROFILE\.claude\skills\roblox-vfx"
```

Restart Claude Code. `roblox-vfx` should appear in the skill list. It loads by itself when you ask for an effect, for example *"use roblox-vfx to build a fire slash"*.

**Verified 2026-11-19 (cloud):** `bash install.sh` printed `installed skill roblox-vfx (v2)`, and the skill appeared in Claude Code's skill list in the same session.

## 3. Create `LOCAL.md`

Copy `LOCAL.template.md` to `LOCAL.md` in `~/.claude/skills/roblox-vfx/` and fill it in (fields in [[Roblox VFX V2/Prerequisites#Configuration with LOCAL.md|Prerequisites]]). Create the library and research folders it names, for example:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\roblox-vfx-lib\recipes", "$env:USERPROFILE\roblox-vfx-research" | Out-Null
setx ROBLOX_VFX_LIB "$env:USERPROFILE\roblox-vfx-lib"
```

## 4. First run: build the textures and meshes (once per machine)

The generated assets are not in the download. They come to about 250 MB according to the README. Run these from the skill folder:

```bash
cd sim/tex && python make_textures.py && python make_magic_tex.py && python make_painted.py
cd lib && python build_library.py        # run from the FILE (Windows multiprocessing)
python check_library.py                  # optional: flags empty / static / duplicate textures
cd ../../mesh
blender -b -P make_meshes.py             # full path to blender.exe if it is not on PATH
blender -b -P make_props.py
blender -b -P make_dragon.py
cd ../tex && python make_prop_tex.py     # needs meshes/props.json from make_props.py
```

Textures land in `sim/textures/` (the library in `sim/textures/lib/`), and meshes in the folders the Blender scripts write.

**Verified 2026-11-19 (cloud, Linux, Python 3.13):**
- `make_textures.py`, `make_magic_tex.py` and `make_painted.py` all exited 0 (about 5 minutes together, 5.4 MB).
- `build_library.py` reported 2,570 textures. Its result is in [[Roblox VFX V2/Installation#Test log|Test log]] below.
- The Blender steps were **not run** (no Blender in the cloud).

## 5. Check the install

From the skill folder:

```bash
python scripts/verify_vfx.py --self-test                 # expect: 10/10 sabotages caught
python scripts/critic_gate.py sim/effects/eclipse_rend.json
python sim/tools/sa_parent_check.py                      # expect: 0 with a SurfaceAppearance off a MeshPart
node sim/studio_kit.js sim/effects/eclipse_rend.json out # writes out/eclipse_rend.luau + .assets.json
python sim/serve.py                                      # open the printed address: 3 examples should play
```

Lune gates (from your Lune folder):

```bash
lune run <skill>/sim/tools/lune/compile_check.luau <kit.luau>
lune run <skill>/sim/tools/lune/build_check.luau <kit.luau>
```

## 6. Connect Studio

Studio work goes through Claude Code on your PC with the Studio MCP connected. Before any Studio step the skill wants proof the bridge works: `execute_luau` with `return 1`, then a screenshot. With the older `robloxstudio-mcp`: `curl -s localhost:48741/health` must show `"pluginConnected": true`.

## Upgrading

Re-run `install.sh` (or copy over the folder on Windows). It backs up the old folder and keeps `LOCAL.md`. v2 installs under the same name as v1 (`roblox-vfx`), so it upgrades v1 in place.

## Test log

| Step (cloud, 2026-11-19) | Result |
|---|---|
| `bash install.sh` | OK, skill listed by Claude Code |
| `pip install --user scipy` | scipy 1.18.1 |
| `verify_vfx.py --self-test` | 10/10 sabotages caught |
| `critic_gate.py` × 3 examples | Eclipse Rend 9 PASS · Riptide Lance 9 PASS · Crimson Detonation 1 FAIL (`no 'brief' block`) |
| `sa_parent_check.py` | 4 effects checked, 0 problems |
| `phys_audit.js` | exit 0, no output (no example has `hit` events, so nothing to audit) |
| `studio_kit.js` × 3 | `explosion_crimson` 31 textures / 12 meshes / 2,451 lines (185,221 chars) · `eclipse_rend` 11 / 0 / 1,003 · `riptide_lance` 22 / 3 / 1,109 |
| Texture generators | 3 of 3 exit 0 |
| `build_library.py` | see below |
| `emit_luau.py` + `verify_vfx.py` on a hand-written recipe | `VFXKit` emitted (10,800 chars); recipe `1 clean, 0 failure(s), 0 warning(s)` |
| Blender, Lune, Studio | not run (not available in the cloud) |

Continue with [[Roblox VFX V2/API Reference|API Reference]].
