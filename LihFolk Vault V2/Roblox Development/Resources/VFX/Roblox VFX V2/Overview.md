---
tags: [resources, vfx, tool, claude-code-skill, roblox-vfx, type/reference, area/vfx, level/intermediate]
source: https://github.com/1nird/roblox-vfx-v2
researched: 2026-11-19
---
# Overview

<!-- tldr:start -->
> [!tldr] TL;DR
> - Browser simulator (`sim/vfxsim.js` + `sim/vfxrender.js`, three.js) of ParticleEmitter, Beam, Trail, Part/MeshPart...
> - Harvest: free pack in your inventory -> Studio place -> payload.py harvest + recipe_server.py -> recipe JSON in your library...
> - Claude Code is required. The skill is written as instructions for Claude, so there is no stand-alone app or Studio plugin.
> - Continue with Prerequisites.
>
> Cost: TL;DR ~140 tok · whole note ~1.6k tok. Read more: ## Main features (from the repo) · ## Limits to know up front
<!-- tldr:end -->

Part of [[Roblox VFX V2]]. Next: [[Roblox VFX V2/Prerequisites|Prerequisites]] · [[Roblox VFX V2/Installation|Installation]]

**rxz Roblox VFX v2** (package `rxz-roblox-vfx-v2`, version 2.0.0, by rxz) is a Claude Code skill named `roblox-vfx`. The repo holds no Roblox place, model or plugin. It is instructions (`SKILL.md`, 1,300 lines) plus Python, JavaScript and Luau tooling that Claude runs for you. It is free to use in commercial Roblox games and free to change, but not for resale, and `LICENSE.txt` must stay with any copy you pass on.

## The two routes

| Route | What you do | What you get in Studio | Best for |
|---|---|---|---|
| **Author** (the main route) | Claude writes an effect definition (`sim/effects/<name>.json`, usually from a Python builder), you judge it in the browser sim, then export it | A **Studio kit**: `<name>.luau` with `buildTemplate` / `spawn` / `play`, plus `<name>.assets.json` listing the textures and meshes to upload | Signature moves, ultimates, anime-style set pieces. Every texture and mesh is generated, so it is yours |
| **Harvest** (fast path) | Take free Creator Store VFX packs into your account, read every emitter out of Studio into JSON recipes, curate a few | A **`VFXKit`** ModuleScript: `VFXKit.build(name, part, opts)` returns `emit` / `setEnabled` / `destroy` | Placeholders and prototypes. The pack's textures stay someone else's work |

## Main features (from the repo)

- **Browser simulator** (`sim/vfxsim.js` + `sim/vfxrender.js`, three.js) of ParticleEmitter, Beam, Trail, Part/MeshPart, PointLight/SpotLight, Highlight, ColorCorrectionEffect and BloomEffect, using Roblox's property names. It is deterministic: `seek(t)` replays at 1/60 s. It also runs under Node.
- **Generated assets:** maths-made textures, magic circles, painted looks, a library of about 2,570 sprites, flipbooks and beam strips, plus Blender scripts for VFX meshes and props (rocks, craters, swords, books, a phoenix, a dragon).
- **Calibration against Studio** (the author's measurements, dated 2026-10-27): for example, ParticleEmitter `Size` draws at twice its value, and SurfaceAppearance emissive never blooms.
- **Set-piece layer** for ultimates: FOV punch, focus lines, letterbox, impact frames, camera cuts.
- **`HitSystem.luau`**: a target that reacts like a body (flinch, knockback, launch, ragdoll, get up planted on the floor). It is built for an R6 showcase target driven on the client.
- **Quality gates:** `critic_gate.py` (checks a definition against the design rules), `verify_vfx.py` (recipe defect checks with a self-test), `sa_parent_check.py`, `phys_audit.js`, and Lune compile and build checks for kits.
- **Harvester tooling:** `payload.py`, `recipe_server.py`, `classify_lib.py`, `find_vfx.py`, `curate.py`, `assemble_kit.py`, `emit_luau.py`, `emit_scenes.py`, `compose.py`.

## How it works, end to end

```
Author:  brief -> builder (Python) -> effect JSON -> browser sim + strips + critic gate
         -> node sim/studio_kit.js -> kit .luau + assets.json
         -> upload textures (and meshes as FBX) -> buildTemplate(assets) in Studio EDIT mode
         -> Kit.spawn(origin, template) + Kit.play(h) from a LocalScript at runtime

Harvest: free pack in your inventory -> Studio place -> payload.py harvest + recipe_server.py
         -> recipe JSON in your library -> classify / find / curate -> emit_luau.py -> VFXKit
         -> VFXKit.build(name, part, opts).emit()
```

## Limits to know up front

- **Claude Code is required.** The skill is written as instructions for Claude, so there is no stand-alone app or Studio plugin.
- **The Studio steps need Roblox Studio with an MCP bridge** (Roblox's official Studio MCP, or the third-party `robloxstudio-mcp`). From a cloud session there is no Studio. Do Studio work in Claude Code on your PC.
- **Nothing ships ready to drop in.** There are no harvested effects, and the generated textures and meshes are not in the download (you build them in the first run).
- **Uploads are manual.** Kits reference `sim:` texture ids that you must upload and map to `rbxassetid://` ids. The repo has no upload script (see [[Roblox VFX V2/Troubleshooting|Troubleshooting]]).
- **Docs and code disagree on rig export.** SKILL.md says the caster's rig animation and ghost afterimages are not exported, but the current `sim/studio_kit.js` does emit `M.animate(h, character)` and `M.ghost(...)`. Treat both as untested until you see them work in Studio. The sim's stand-in target (`simOnly` parts) is never exported, so put a dummy at the origin to judge scale.
- **The author's quality bar is high-effort.** RULE ZERO says "if an effect needs a thing, make the thing", including Blender meshes. Expect long agent runs per effect.

## When to use it, and when not

| Situation | Use |
|---|---|
| A cozy or simulator game needs small pops, coin bursts or sparkles | The vault's own `lihfolk-vfx` skill and notes such as [[Collectible Pickup FX - Idle Glint, Magnet Pull and Collect Pop]] are lighter. Roblox VFX V2 is overkill |
| A combat or anime game needs signature moves, slashes, beams or ultimates | **Roblox VFX V2, authoring route** |
| You own good free packs and need placeholders today | **Roblox VFX V2, harvest route** to `VFXKit` |
| You need hit reactions on a target | `HitSystem.luau` as a reference. It is tuned for a client-side showcase target, so read [[Roblox VFX V2/Integration|Integration]] first |

## Repository layout

| Path | What |
|---|---|
| `README.md`, `install.sh`, `LICENSE.txt`, `package.json` | Docs, installer, licence, package metadata (v2.0.0) |
| `dist/rxz-roblox-vfx-v2-v2.0.0.zip` | The same skill as a zip |
| `tools/build.mjs`, `tools/zip.py` | The author's packaging scripts (not needed to use it) |
| `skills/roblox-vfx/SKILL.md` | The skill itself: rules, traps, routes |
| `skills/roblox-vfx/references/` | `VFXKit.lua` (runtime template), `HitSystem.luau`, `CharacterVFX.server.lua`, design, styles, beats, the measured corpus |
| `skills/roblox-vfx/sim/` | Simulator, workbench server, 3 worked effects, texture and mesh generators, gate tools |
| `skills/roblox-vfx/scripts/` | Harvester and export scripts; `scripts/luau/` holds the Luau bodies they assemble |

Continue with [[Roblox VFX V2/Prerequisites|Prerequisites]].
