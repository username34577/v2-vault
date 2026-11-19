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
> Cost: TL;DR ~130 tok · whole note ~3.0k tok. Read more: ## Where things go in Studio · ## The reusable layer (games/vfx-lab)
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
- **Screen effects only for the player they belong to.** Use `Kit.spawn(origin, template, {screen = false})` for moves someone else casts and for ordinary moves (**repo**: "so a move someone else throws never grades or blanks this player's screen"). Allow the screen layer (camera, FOV punch, letterbox, grades) only for the local player's own ultimates, through `KitRunner` + `CameraGuard` so the camera always comes back (see below).
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

## The reusable layer (games/vfx-lab)

Built and checked 2026-11-19 (outside Studio). Copy `src/shared/VFX/`, `src/server/VFXServer.luau`, `src/client/VFXClient.luau`, `src/client/Perf.luau`, `library/` and `tools/` into a game. API details: [[Roblox VFX V2/API Reference#6. Our integration layer|API Reference]]. Test procedure: [[Roblox VFX V2/Test Lab|Test Lab]].

### Library structure

| Path | Holds | Edited by |
|---|---|---|
| `library/recipes/*.json` | VFXKit recipes, named by **role** (`SunBurst`) | `tools/author_recipes.py` (fills all 31 emitter properties) |
| `library/effects/*.json` | Authored effect definitions for Studio kits | You or a roblox-vfx builder |
| `library/kits/` | `studio_kit.js` output | `tools/check.sh` |
| `library/manifest.json` | Used generated assets: file, sha256, Roblox id, status | `tools/vfx_manifest.py` (`--set` for ids) |
| `library/previews/` | Sim frame strips + metrics | `tools/render_previews.js` |
| `src/shared/VFX/VFXKit.luau`, `Kits/*.luau`, `Assets.luau` | Generated Luau | `tools/check.sh` |

### Quality presets (`src/shared/VFX/Quality.luau`)

Defaults from the player's Roblox graphics level (1-3 Low, 4-7 Medium, 8-10 High, Automatic → Medium); `Quality.set` overrides it.

| Setting | Low | Medium | High | Applied to |
|---|---|---|---|---|
| `EmitMul` (burst counts) | 0.45 | 0.75 | 1 | `handle.emit(mult)`; kits' `EmitCount` attribute |
| `RateMul` (continuous rate) | 0.5 | 0.75 | 1 | VFXKit `rate_mul`; kits' starting `Rate` |
| `MaxBursts` (alive at once) | 4 | 8 | 16 | Extra one-shots are skipped, never queued |
| `MaxKits` | 1 | 2 | 3 | Studio kits playing at once |
| `CullDistance` (studs) | 120 | 220 | 400 | One-shots further from the camera are skipped |
| `DecorativeLights` | off | on | on | Flash/pulse PointLights; gameplay (constant) lights stay when `keepLights` |
| `ScreenEffects` | off | on | on | Camera, FOV punch, grades, overlays for your own cinematics |

Effects marked `important` (the round result) skip culling and the cap. A quality change rebuilds every looping effect at the new rate. Limit: a kit's timeline `set Rate` events are not scaled.

### Multiplayer pattern

| Effect kind | Server does | Client does | Why |
|---|---|---|---|
| **State** (the carrier's aura) | `VFXServer.setCarrying(model, on)`: sets the `CarryingSun` attribute on a model tagged `VFXActor` | `VFXClient` watches tagged models' attributes and attaches/detaches `SunAura` on the root | Attributes replicate: late joiners, respawns and streaming are right with nothing to resend |
| **One-shot** (steal burst, victory) | `VFXServer.oneShot(cue, position, power)`: allowlist (`Cues.luau`), power clamped, per-cue rate cap (SunBurst 10/s), sent only to players within the cue's radius (250 studs; victory to everyone) | Validates the payload (name, Vector3, finite numbers), then `Effects.burst` with quality, culling and caps | The server decides *that* it happened; clients decide *how it looks*. The remote has no server handler, so clients cannot send through it |
| **Cinematic** (an ultimate) | Sends a one-shot cue to everyone | The caster's own client may use `KitRunner.play(..., {cinematic = true})`; every other client plays it with `{screen = false}` | Nobody else's screen is graded or hijacked |

Vault background: [[Replicating VFX - Server Validates, Clients Render]].

## Cleanup

| What | Guaranteed by |
|---|---|
| One-shot bursts | `Effects.burst` destroys its host part (or the tagged attachments) after the recipe's duration or longest particle life, plus 0.25 s |
| Looping effects | `Effects.detach` stops emitting, lets live particles finish, then destroys. The part leaving the game (character removed) auto-detaches |
| Tagged actors | `VFXClient` detaches everything for a model when its `VFXActor` tag goes away |
| Round end / teleport | `Effects.clear()` destroys everything at once |
| Studio kits | `Kit.play` destroys `h.folder` and its Lighting effects after `DURATION + 1`; `KitRunner` destroys any leftover folder at `DURATION + 1.2` |
| Camera | `CameraGuard`: restores after the cinematic, at a safety timeout, on death or respawn, or when the camera is replaced |
| VFXKit rebuilds | Same name + suffix on the same part replaces, never duplicates (upstream behaviour) |
| HitSystem targets | `HitSystem.reset` undoes a kit's edits to the target (**repo**) |

## Assets: upload only what is used

1. `bash tools/check.sh` (regenerates kits and the manifest).
2. `python tools/vfx_manifest.py --stage upload/`: copies only files still needing an id. For the lab that is **11 of 2,570** generated textures; the Snatch the Sun recipes need none (stock textures).
3. Studio → Asset Manager → Bulk Import the `upload/` folder.
4. `python tools/vfx_manifest.py --set sim:<id>=rbxassetid://<n>` for each, then `bash tools/check.sh` again; `Assets.luau` now carries the ids for `Kit.buildTemplate`.
5. Before release: `python tools/vfx_manifest.py --strict` (exit 1 if anything used has no current id).

## Fitting it to this vault's games

- **Snatch the Sun** (`games/snatch-the-sun`, design stage): its three effects are in the lab (`SunAura`, `SunBurst`, `SunVictory`). Copy the layer into the game's Rojo project and call `VFXServer` from gameplay: [[Roblox VFX V2/Examples#9. Snatch the Sun wiring|Examples]].
- For cozy pops and pickups, the vault's own `lihfolk-vfx` skill plus [[Collectible Pickup FX - Idle Glint, Magnet Pull and Collect Pop]] is lighter. Use Roblox VFX V2 when a move deserves a set piece.
- Score finished effects with `skills/quality-score/rubrics/vfx.md`.

Continue with [[Roblox VFX V2/Troubleshooting|Troubleshooting]].
