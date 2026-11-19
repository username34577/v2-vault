---
tags: [resources, vfx, tool, troubleshooting, debugging, roblox-vfx, type/troubleshooting, area/vfx, level/intermediate]
source: https://github.com/1nird/roblox-vfx-v2
researched: 2026-11-19
---
# Troubleshooting

Part of [[Roblox VFX V2]]. Previous: [[Roblox VFX V2/Integration|Integration]] · Back to [[Roblox VFX V2/Overview|Overview]]

Sources: **found 2026-11-19** = seen while testing the repo in the cloud session; **repo** = the author's measured traps in SKILL.md (the author dates them 2026-08 to 2026-11, measured in Studio). For general particle debugging see [[Particle Emitters In Depth]].

## Found while testing (2026-11-19)

| Symptom | Cause | Fix |
|---|---|---|
| After a kit plays, the player's camera stays frozen | `M.play` sets `CameraType = Scriptable` when the effect has a camera, and never sets it back | `Kit.spawn(origin, template, {screen = false})` for gameplay, or restore `CameraType = Enum.CameraType.Custom` after `Kit.DURATION` ([[Roblox VFX V2/Examples|Examples]], example 6) |
| `[<Kit>] missing texture sim:beam_paint__vt` (or any `__vt` id) | Beam/Trail textures are exported as transposed copies `<id>__vt`. The exporter's comment says `tools/sync_vt.py` writes them, but **that file is not in the repo** | Make the transposed PNG yourself before uploading (workaround below, untested in Studio) |
| `verify_vfx.py some.json` prints "no recipe library given" | The script requires `--lib` even for one file (SKILL.md shows it without) | `python scripts/verify_vfx.py --lib <folder holding the recipe>` |
| `critic_gate.py` fails `explosion_crimson.json`: "no 'brief' block" | The shipped Crimson Detonation example has no design brief | Expected for that example. Your own effects need a `brief` block (see `references/DESIGN.md` step 1) |
| `phys_audit.js` prints nothing | It only audits effects with `{"do":"hit"}` events and a sim target; none of the 3 examples have them | Not an error. It matters once your effects hit a target |
| `node: command not found` when exporting | The README's prerequisite list omits Node.js, but `studio_kit.js` needs it | Install Node.js LTS |
| A kit is close to or over the size limit | Big kits inline every instance; Crimson Detonation exports at 185,221 characters | Keep kits under 200,000 characters (see Source cap below). Split big effects, or reuse templates |
| No way to upload the textures and meshes | The repo has no upload script, despite the optional Open Cloud key in the README | Upload in Studio (Asset Manager → Bulk Import or the Creator Dashboard), meshes as **FBX from `sim/mesh/obj_to_fbx.py`**, then fill the `assets` table |

Workaround for the missing `__vt` textures (Pillow, from the skill folder). It is **not part of the repo** and has not been checked in Studio, so compare one beam against the sim before trusting it:

```bash
python -c "from PIL import Image; import sys; Image.open(sys.argv[1]).transpose(Image.Transpose.TRANSPOSE).save(sys.argv[2])" sim/textures/beam_paint.png sim/textures/beam_paint__vt.png
```

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
