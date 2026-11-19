---
tags: [resources, vfx, tool, troubleshooting, debugging, roblox-vfx, type/troubleshooting, area/vfx, level/intermediate]
source: https://github.com/1nird/roblox-vfx-v2
researched: 2026-11-19
---
# Troubleshooting

Part of [[Roblox VFX V2]]. Previous: [[Roblox VFX V2/Integration|Integration]] · Back to [[Roblox VFX V2/Overview|Overview]]

Sources: **found 2026-11-19** = seen while testing the repo in the cloud session; **repo** = the author's measured traps in SKILL.md (the author dates them 2026-08 to 2026-11, measured in Studio). For general particle debugging see [[Particle Emitters In Depth]].

## Found while testing (2026-11-19), with status

Status: **fixed** = solved in our layer (`games/vfx-lab`, upstream untouched) · **explained** = investigated, nothing to fix · **open** = still needs action.

| Symptom | Cause | Status and fix |
|---|---|---|
| After a cinematic kit, the player's camera stays frozen | `M.play` sets `CameraType = Scriptable` when the effect defines a camera and never sets it back. The kit's shake/FOV driver unbinds itself and is not the problem | **Fixed**: play kits through `KitRunner.play(..., {cinematic = true})`. It takes the camera via `CameraGuard` (one owner at a time) and restores type, subject and FOV after `DURATION + 0.5` s, on death or respawn, or when the camera is replaced. Ordinary moves use `{screen = false}`. The lab's "Repro: raw kit" button shows the original bug |
| `[<Kit>] missing texture sim:<id>__vt` / `__em` | `studio_kit.js` asks for transposed Beam/Trail textures (`__vt`) and premultiplied emissive masks (`__em`) and says `tools/sync_vt.py` writes them. **That file is not in the repo, the zip or its history** (one commit) | **Fixed**: `tools/vfx_manifest.py` writes both into `library/derived/` (transpose and RGB × alpha, both pixel-checked) and lists them for upload |
| No upload tooling | The README mentions an optional Open Cloud key, but **no upload script ships** (searched the repo, zip and history) | **Explained / manual**: upload in Studio (Asset Manager → Bulk Import) only the files `vfx_manifest.py --stage upload/` copies, then record ids with `--set`. An Open Cloud uploader is not part of our layer either (it would need your key) |
| `critic_gate.py` fails `explosion_crimson.json`: "no 'brief' block" | Its builder `build_explosion.py` predates the brief rule; the gate stops at the first FAIL | **Explained**: with a brief built only from the builder's own docstring (`tools/crimson_brief_overlay.py`, a copy in the lab) it passes **9/9**. The effect is fine; its metadata is missing |
| Stock-texture recipes draw **nothing** in the sim | `vfxrender.js` maps stock `rbxasset://` textures to stand-ins `star4` and `soft_dot` (also the fallback), but **no generator writes those PNGs** | **Fixed for previews**: `tools/render_previews.js` serves the skill's own `spark_star4.png` / `glow_soft.png` in their place. In the workbench itself it is still **open** (upstream) |
| The sim page shows no three.js / blank workbench | `sim/index.html` loads three.js r128 from `cdnjs.cloudflare.com`; blocked in some networks (it was in the cloud session) | **Fixed for previews**: `render_previews.js --three <file>` serves a local copy (`npm pack three@0.128.0` → `package/build/three.min.js`) |
| `obj_to_fbx.py` converts nothing | `make_meshes.py` / `make_props.py` write OBJs to `sim/meshes/`, but `obj_to_fbx.py` reads `sim/mesh/assets/meshes/` | **Open (upstream)**: copy the OBJs there before converting, or edit the `SRC` path in your local copy |
| Blender meshes and props are missing | No Blender in the cloud session: no apt package, and only `bpy` 5.x wheels exist for its Python 3.13, while the repo targets Blender 4.x | **Open**: run the mesh step on your PC with Blender 4.x (see [[Roblox VFX V2/Installation\|Installation]]). Nothing we ship needs meshes yet: the three Snatch the Sun effects use stock textures and EclipseRend needs 0 meshes |
| Roblox Studio MCP not available | The cloud session has no Studio MCP tools and no shared computer | **Open**: Studio steps run in Claude Code on your PC with the official Studio MCP enabled; check it with `execute_luau` (`return 1`) plus a screenshot |
| `verify_vfx.py some.json` prints "no recipe library given" | It requires `--lib` even for one file (SKILL.md shows it without) | **Explained**: always pass `--lib <folder>`; `tools/check.sh` does |
| A hand-written recipe fails `verify_vfx.py` with "N of 31 properties missing" | The verifier requires every ParticleEmitter property (that is how it catches bad harvests) | **Fixed for authoring**: generate recipes with `tools/author_recipes.py` (fills all 31 from Roblox defaults) |
| `phys_audit.js` prints nothing | It only audits effects with `{"do":"hit"}` events and a sim target | **Explained**: not an error |
| `node: command not found` when exporting | The README omits Node.js, but `studio_kit.js` needs it | Install Node.js LTS |
| A kit near the 200,000-character Source cap | Big kits inline every instance; Crimson Detonation exports at 185,221 characters | `tools/check.sh` fails any kit at or over 200,000 |
| SKILL.md says rig animation and afterimages are not exported | The current `studio_kit.js` does export `M.animate` and `M.ghost` | **Explained**: docs out of date. `M.animate` needs an **R6** caster; on R15 it warns "caster is not an R6 rig" and skips |

## Studio and assets (repo)

| Symptom | Cause | Fix |
|---|---|---|
| Emitter exists but draws nothing | A dead texture path: `rbxasset://textures/smoke.png`, `fire.png`, `particle.png` and most of `textures/particles/` render nothing, with no error | Only five stock paths work: `textures/particles/sparkles_main.dds`, `fire_main.dds`, `smoke_main.dds`, `textures/explosion.png`, `textures/sparkle.png`. `verify_vfx.py` flags the rest |
| Effect builds at the world origin | Built on an Attachment under a Model or Folder (no world position) | Build on a **BasePart**; `VFXKit.build` asserts this |
| A burst effect never stops | A burst layer kept `Rate > 0`, so it bursts **and** streams | `Rate = 0` on burst layers (VFXKit sets it; `verify_vfx.py` fails it) |
| A Beam or Trail builds but draws nothing | `Attachment0`/`Attachment1` not wired | Recipes record `endpoints`; VFXKit wires them. Hand-built ones must set both |
| Aura particles are born inside the torso | A shaped emitter under an Attachment ignores its Shape and spawns from one point | Put shaped emitters straight under the Part; give particles size or outward speed |
| Particles twice the expected size | `ParticleEmitter.Size` is half the drawn width (Size 4 draws 8 studs) | Builders author the visible width; `roblox_units.py` halves it on write |
| "Asset content representation is being generated" for 30+ minutes | A fresh mesh upload is still processing, and Studio keeps the failure for the session | Save, restart the Studio window, run again. Do one full warm play before recording |
| Mesh imports facing backwards | OBJ → FBX conversion turns meshes 180° about Y | Convert with `sim/mesh/obj_to_fbx.py` (adds the half turn) |
| Crater or surface shows as a solid tinted square at first | `PreloadAsync` on a SurfaceAppearance does not fetch its maps | Kits' `M.preload` asks for every map and MeshId by id; call it at join |
| A 260° or 720° spin turns the wrong way or not at all | CFrame tweens take the short way round | Use the sim's `spin` action (exported to kits) instead of a CFrame tween |
| `Enum.EasingStyle["Constant"]` error | Not a real easing style in Roblox | The kit's `easeV` treats Constant as a step key |
| Kit fails to compile: too many locals | Luau allows 200 locals per function | Current `studio_kit.js` stores instances in a table `I[n]`; re-export old kits |
| Script installs as nothing / `Unable to assign property Source` | Source over 200,000 characters | `emit_luau.py --data-dir` splits the data into chunk modules; curate fewer recipes |
| A tint turns an effect murky or does nothing | The texture carries its own colour (or the layer's Color is black) | Tint only greyscale layers; check the cached texture first |
| Glow looks grey | World lighting pulls it down | `LightInfluence = 0` on glow layers |
| A dark aura reads as red candy floss | An additive glow over black flames | `LightEmission = 0` on dark auras |

## Harvesting and the MCP (repo)

| Symptom | Cause | Fix |
|---|---|---|
| "User is not authorized to access Asset" on a free pack | Free packs must be **taken** into your inventory first; `InsertService` refuses otherwise | Press Get / Add to Inventory on the Creator Store while signed in |
| Harvested emitters are missing most properties | The MCP's generic property reader returns 6 of 31 ParticleEmitter properties | Harvest through `payload.py harvest` (an explicit property walk), never `get_instance_properties` |
| `execute_luau` returns success with no prints | Any yield in the script drops every print | Do the work in `task.spawn`, write progress to a `StringValue`, read it with a second call |
| Screenshot fails | Studio must be foregrounded and maximised, not just un-minimised | Bring Studio to the front |
| `CurrentCamera.CFrame` in Edit mode won't stick | Studio's camera script overwrites it | See SKILL.md trap 10 |
| Every MCP call times out while `/health` says `pluginConnected: true` | Two `robloxstudio-mcp` servers on ports 48741 and 48742; the plugin talks to one, your tools to the other | `curl -s localhost:48741/health; curl -s localhost:48742/health`, then follow SKILL.md "When the MCP is connected but every call times out" |
| Large harvest never arrives | `PostAsync` refuses big bodies | `payload.py --sink ''` forces chunked print output (SKILL.md trap 12) |

## Cloud-session limits

- **No Studio in the cloud.** Kit building, harvesting, captures and playtests need Claude Code on the PC that runs Studio.
- **No Blender or Lune here** (GitHub binary downloads are blocked in this environment), so the mesh generators and Lune gates were not run.
- **The container is temporary.** The installed skill, scipy and generated textures are lost when it is recycled; reinstall per [[Roblox VFX V2/Installation|Installation]].

Back to [[Roblox VFX V2]].
