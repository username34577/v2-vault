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
| [[Roblox VFX V2/Troubleshooting\|Troubleshooting]] | Known problems: from the repo, and found while testing it |

## Status (2026-11-19)

| Item | Status |
|---|---|
| Skill installed with the repo's `install.sh` into `~/.claude/skills/roblox-vfx` (cloud container) | **Verified**: the skill loads in Claude Code |
| `verify_vfx.py --self-test` | **Verified**: 10/10 sabotages caught |
| `critic_gate.py` on the 3 worked examples | **Verified**: Eclipse Rend 9/9 PASS, Riptide Lance 9/9 PASS, Crimson Detonation **FAIL** (no `brief` block) |
| `studio_kit.js` export of all 3 examples to Luau kits | **Verified**: 3 kits generated, syntax-checked |
| Texture generators (Python) | **Verified**: base, magic and painted textures built; library build checked (see [[Roblox VFX V2/Installation\|Installation]]) |
| `emit_luau.py` with a hand-written recipe | **Verified**: `VFXKit` emitted, recipe passes `verify_vfx.py` clean |
| Blender mesh generators, Lune gates | **Not run**: Blender and Lune are not available in the cloud session |
| Anything inside Roblox Studio | **Not tested**: needs your PC with Studio (no Studio connection from the cloud) |

## Related vault notes

- [[Particle Emitters In Depth]], [[Beams and Trails]], [[VFX Design Playbook]]
- [[Replicating VFX - Server Validates, Clients Render]], [[VFX Performance Budgets and Culling]]
- [[Official Docs - Visual Effects]] (Roblox's own docs)
- Background: the TikTok research note `research/TikTok Notes/creator-rxz-dev.md` (outside this vault folder) covers rxz's videos; this repo is the first of his skills that is public.
