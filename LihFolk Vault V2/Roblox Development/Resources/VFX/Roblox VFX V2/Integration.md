---
tags: [resources, vfx, tool, integration, studio, rojo, roblox-vfx, type/guide, area/vfx, level/intermediate]
source: https://github.com/1nird/roblox-vfx-v2
researched: 2026-11-19
---
# Integration

<!-- tldr:start -->
> [!tldr] TL;DR
> - Prefer one-shot `:Emit(n)` (`handle.emit`) over continuous `Rate` for event-driven effects.
> - Keep aura lifetimes under about 1 s: long-lived, large, soft particles cause the most overdraw.
> - `LightInfluence = 0` on glowing layers. `LightEmission` is free brightness; a `PointLight` is not, so use at most one, pulsed...
> - Working code for each is in Examples.
>
> Cost: TL;DR ~130 tok · whole note ~2.0k tok. Read more: ## Where things go in Studio · ## Client vs server
<!-- tldr:end -->

Part of [[Roblox VFX V2]]. Previous: [[Roblox VFX V2/Examples|Examples]] · Next: [[Roblox VFX V2/Troubleshooting|Troubleshooting]]

How to get effects from this skill into a Roblox game: where each piece lives, who runs it, and how to keep it cheap and clean. Rules marked **repo** come from the repo's SKILL.md or source; **vault** points to a note in this vault; **untested** means nobody has checked it in Studio yet for this game.

## Where things go in Studio

| Piece | Type | Put it in | Why |
|---|---|---|---|
| `VFXKit` (from `emit_luau.py`) | ModuleScript | `ReplicatedStorage` (or beside the script that requires it) | Clients build effects; the server can also require it for character-owned effects (`CharacterVFX.server.lua` looks in ServerScriptService or ReplicatedStorage, **repo**) |
| `VFXKit` data chunks (`--data-dir`) | ModuleScripts | Children/siblings as `emit_luau.py` writes them | Keeps every Source under Roblox's 200,000-character cap (**repo**, trap 19) |
| Kit module `<name>.luau` (from `studio_kit.js`) | ModuleScript | `ReplicatedStorage.VFX.<Name>` | Required by the client at runtime and by the command bar in Edit mode |
| Kit **template** (made by `buildTemplate`) | Folder | `ReplicatedStorage.VFX.Templates.<Name>`, built once in Edit mode and **saved with the place** | Runtime scripts may not set `MeshId`/`ColorMap`, so the template must already exist (**repo**) |
| Uploaded textures and meshes | Assets | Your account or group (the one that owns the experience) | Kits hold `rbxassetid://` ids; meshes need the inner MeshId |
| Effect runtime script | LocalScript | `StarterPlayerScripts` (or `StarterCharacterScripts` for per-character auras) | Kits are documented as LocalScript-driven (**repo**) |
| Character aura / landing burst (optional) | Script | `ServerScriptService` (`CharacterVFX.server.lua`) | Server-built effects inside the character replicate to everyone without a remote (**repo**) |
| `HitSystem` (optional) | ModuleScript | `ReplicatedStorage` | The repo uses it client-side on a locally spawned target (see below) |

### Rojo layout

Rojo cannot carry the Edit-mode template, because it is built in Studio from uploaded ids. Sync the code with Rojo and keep the template in the saved place (or export it as a model file):

```
src/shared/VFXKit.luau            -> ReplicatedStorage.Shared.VFXKit      (emit_luau.py output)
src/shared/VFX/EclipseRend.luau   -> ReplicatedStorage.Shared.VFX.EclipseRend (studio_kit.js output)
src/client/MoveFx.client.luau     -> StarterPlayerScripts
(Studio only) ReplicatedStorage.Shared.VFX.Templates.EclipseRend         (buildTemplate, saved in the place)
```

If Rojo manages `ReplicatedStorage.Shared.VFX` with `$path`, it may remove a `Templates` folder it does not know about. Keep the templates in a folder Rojo does not own (for example `ReplicatedStorage.VFXTemplates`) and point your scripts there.

## Triggering effects from Luau

| You want | Call | Notes |
|---|---|---|
| One-shot hit or explosion (harvest route) | `VFXKit.build(name, part, opts).emit(mult)` | Build once and keep the handle when it is re-fired often; building the same name again replaces it |
| Looping aura (harvest route) | `handle.setEnabled(true/false)`, `handle.destroy()` | `opts.suffix` for a second independent copy |
| Authored move or ultimate | `local h = Kit.spawn(origin, template, opts)` → set `h.caster` / `h.target` → `Kit.play(h)` | `play` cleans up after `DURATION + 1` s |
| Preload | `Kit.preload(template)` at join | **repo**: preload every template at join, not right before play |

Working code for each is in [[Roblox VFX V2/Examples|Examples]].

## Client vs server

- **Render on clients, decide on the server** (**vault**: [[Replicating VFX - Server Validates, Clients Render]]). The server validates the action, then sends `(effect name, CFrame/position, small numbers)` to nearby clients, and each client plays it. Never let a client's remote choose damage or targets because of an effect.
- **Studio kits are client-only by design** (**repo**): `buildTemplate` runs in Edit mode, `spawn` + `play` in a LocalScript. `spawn` parents the clone to `workspace`, so a kit played on one client is seen only by that client. Fire it on every client that should see it.
- **Screen effects only for the player they belong to.** Use `Kit.spawn(origin, template, {screen = false})` for moves someone else casts and for ordinary moves (**repo**: "so a move someone else throws never grades or blanks this player's screen"). Allow the screen layer (camera, FOV punch, letterbox, grades) only for the local player's own ultimates, and restore the camera afterwards ([[Roblox VFX V2/Troubleshooting|Troubleshooting]]).
- **`VFXKit` on the server** is fine for effects that live inside a character (auras), because they replicate with the character (**repo**: `CharacterVFX.server.lua`). For one-shot world effects prefer clients, because server-built particles cost every client and the network.
- **`HitSystem` is a showcase module.** It drives a target the client spawned locally (`spawnTarget`) and uses its own collision groups. In a multiplayer game the server owns real characters' health and physics. Reuse its *rules* (three-step limp, root in the lift, collision groups, planted get-up), not the module as-is (**untested** in a live game).

## Performance (repo rules plus vault budgets)

- Prefer one-shot `:Emit(n)` (`handle.emit`) over continuous `Rate` for event-driven effects. Continuous emitters cost every frame.
- Keep aura lifetimes under about 1 s: long-lived, large, soft particles cause the most overdraw.
- `LightInfluence = 0` on glowing layers. `LightEmission` is free brightness; a `PointLight` is not, so use at most one, pulsed for about 0.3 s.
- Curate, don't ship the library: emit only the recipes a game uses. The author measured a 1,813-recipe library at a projected 4.7 MB of Luau.
- Watch Source size: a kit over 200,000 characters installs as nothing. Crimson Detonation's kit is already 185,221 characters (measured 2026-11-19).
- Preload templates and every MeshId/ColorMap at join; first-play hitches come from assets streaming in.
- Budget numbers per device: [[VFX Performance Budgets and Culling]]. Particle tuning: [[Particle Emitters In Depth]].

## Cleanup

- `Kit.play(h)` destroys `h.folder` and the Lighting effects it moved, then calls `h.restoreStage` if `applyStage` was used. It does **not** restore the camera type.
- `VFXKit` handles: call `handle.destroy()` when the owner dies or the effect ends. A host part you create for a world position needs its own `Debris:AddItem` or `Destroy`.
- Tag-based replacement: `VFXKit.build` with the same name on the same part destroys the old attachments first, so rebuilding does not leak.
- After a kit hits a `HitSystem` target, `HitSystem.reset` undoes the kit's edits to the target (scale, hidden parts, joints, added instances). Kits hide target parts rather than destroy them so reset can bring them back (**repo**).

## Fitting it to this vault's games

- **Snatch the Sun** (`games/snatch-the-sun`, design stage) and the archived **Grow a Monster** use a Rojo layout with `src/shared` → `ReplicatedStorage.Shared` and a server-to-client cue remote. Put `VFXKit.luau` in `src/shared`, play effects in the client modules on the server's cue, and keep templates out of Rojo's managed folders.
- For cozy pops and pickups, the vault's own `lihfolk-vfx` skill plus [[Collectible Pickup FX - Idle Glint, Magnet Pull and Collect Pop]] is lighter. Use Roblox VFX V2 when a move deserves a set piece.
- Score finished effects with `skills/quality-score/rubrics/vfx.md`; its source list already names "the `roblox-vfx` playbook if installed".

Continue with [[Roblox VFX V2/Troubleshooting|Troubleshooting]].
