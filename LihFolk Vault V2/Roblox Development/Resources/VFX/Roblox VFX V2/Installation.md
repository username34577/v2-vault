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
> Cost: TL;DR ~130 tok · whole note ~2.1k tok. Read more: ## 4. First run: build the textures and meshes (once per machine) · ## 6. Connect Studio
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
- `build_library.py`: **2,570 textures, 0 errors** (about 25 minutes with 3 processes); `check_library.py`: **0 issues** in every category (empty, edge-touching, static, never-fading). Total `sim/textures/` 217 MB.
- The Blender steps were **not run**: no Blender in the cloud (no apt package; only `bpy` 5.x wheels exist, the repo targets 4.x). Run them on your PC.
- **Mesh path mismatch (upstream):** the Blender generators write OBJs to `sim/meshes/`, but `obj_to_fbx.py` reads `sim/mesh/assets/meshes/`. Copy the OBJs there (or fix `SRC` in your local copy) before converting to FBX for upload.

## 5. Check the install

From the skill folder:

```bash
python scripts/verify_vfx.py --self-test                 # expect: 10/10 sabotages caught
python scripts/critic_gate.py sim/effects/eclipse_rend.json
python sim/tools/sa_parent_check.py                      # expect: 0 with a SurfaceAppearance off a MeshPart
node sim/studio_kit.js sim/effects/eclipse_rend.json out # writes out/eclipse_rend.luau + .assets.json
python sim/serve.py                                      # open the printed address: the workbench
```

`serve.py` caveats (found 2026-11-19): the page loads three.js from cdnjs (blocked on some networks); Crimson Detonation and Riptide Lance draw their meshes only after the Blender step; and recipes on stock textures draw nothing in the workbench because the stand-ins `star4.png` / `soft_dot.png` are never generated ([[Roblox VFX V2/Troubleshooting|Troubleshooting]]). `verify_vfx.py` always needs `--lib <folder>`, even for one file.

For a game, run the whole pipeline (recipes, verifier, emit, critic gate, kit export, asset manifest, Luau syntax, Roblox API names, Lune when installed) from the lab:

```bash
cd games/vfx-lab
bash tools/check.sh                                       # expect: ALL CHECKS PASSED
node tools/render_previews.js --three <path to three.min.js r128>   # sim strips in library/previews/
```

Lune gates (from your Lune folder):

```bash
lune run <skill>/sim/tools/lune/compile_check.luau <kit.luau>
lune run <skill>/sim/tools/lune/build_check.luau <kit.luau>
```

## 6. Connect Studio

Status 2026-11-19: **not configured yet**. The cloud sessions have no Studio MCP tools and no access to your PC. Studio's MCP server is local (it runs `%LOCALAPPDATA%\Roblox\mcp.bat` over stdio), so only a Claude Code session **on your Windows PC** can use it. A cloud session never can.

**Windows setup (on your PC):**

1. Check what is there (read-only, installs nothing; it also test-builds the lab with Rojo):
   ```powershell
   powershell -ExecutionPolicy Bypass -File games\vfx-lab\tools\windows_setup_check.ps1
   ```
   Written 2026-11-19 but **not run yet**: no PowerShell in the cloud session, so it is untested.
2. Studio MCP (from the vault's [[Roblox Studio MCP Server]] note): update Studio → **Assistant → ⋯ → Manage MCP Servers → Enable Studio as MCP server** (a green indicator shows connected clients). Then **Assistant Settings → MCP Servers → Quick connect → Claude Code**, or register it yourself:
   ```powershell
   claude mcp add --scope user Roblox_Studio -- cmd.exe /c "%LOCALAPPDATA%\Roblox\mcp.bat"
   ```
   Restart Claude Code. Check: `claude mcp list` shows `Roblox_Studio`; in Claude Code, `list_roblox_studios` lists your open place.
3. Rojo: install with Rokit (`rokit add rojo-rbx/rojo` in the repo) or download `rojo.exe`, then `rojo plugin install` and restart Studio.
4. Run the lab: `cd games\vfx-lab`, `rojo serve`, open a new Baseplate place → Rojo → **Connect**, then follow [[Roblox VFX V2/Test Lab|Test Lab]].

Before any Studio step the skill wants proof the bridge works: `execute_luau` with `return 1`, then a screenshot. With the older third-party `robloxstudio-mcp`: `curl -s localhost:48741/health` must show `"pluginConnected": true`.

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
| `build_library.py` | 2,570 textures, 0 errors, exit 0 |
| `check_library.py` | 0 issues, exit 0 |
| `games/vfx-lab/tools/check.sh` | ALL CHECKS PASSED (see [[Roblox VFX V2/Test Lab\|Test Lab]]) |
| `render_previews.js` | 3 strips rendered; drove a round of tuning |
| Studio MCP check | no Studio tools in the session: not configured |
| `emit_luau.py` + `verify_vfx.py` on a hand-written recipe | `VFXKit` emitted (10,800 chars); recipe `1 clean, 0 failure(s), 0 warning(s)` |
| Blender, Lune, Studio playtest | not run (not available in the cloud) |

Continue with [[Roblox VFX V2/API Reference|API Reference]].
