# VFX library (reusable)

The effects a game ships, kept as **source** (recipes and effect definitions) with everything else generated from it. Copy this folder plus `tools/` and `src/shared/VFX/` into any game.

| Folder / file | What | Edit by hand? |
|---|---|---|
| `recipes/*.json` | VFXKit recipes (roblox-vfx recipe format), one per effect, named by **role** (`SunBurst`, not a pack name) | No: generate from `tools/author_recipes.py` |
| `effects/*.json` | Authored effect definitions for the Studio-kit route (roblox-vfx sim format) | Yes (or from a roblox-vfx builder) |
| `effects/*.briefed.json` | Investigation copies (e.g. Crimson Detonation with a brief); never exported | No |
| `kits/*.luau`, `kits/*.assets.json` | `studio_kit.js` output for each effect | No: `tools/check.sh` regenerates |
| `manifest.json` | Every generated texture/mesh the game **uses**: file, sha256, Roblox id, status | Only via `vfx_manifest.py --set` (and the `note` field) |
| `derived/` | `__vt` / `__em` textures made by `vfx_manifest.py` (git-ignored, rebuilt on demand) | No |
| `previews/*.png`, `previews/metrics.json` | Sim frame strips from `tools/render_previews.js` | No |

## Rules

1. **Ship narrow.** Only recipes the game calls go in `recipes/`; only effects it plays go in `effects/`. The roblox-vfx library (~2,570 textures) stays on your machine.
2. **Upload only what the manifest lists.** `python tools/vfx_manifest.py --stage upload/` copies exactly the files still needing an id (11 for the lab, out of 2,500+ generated). Bulk-import that folder in Studio (Asset Manager), then record each id:
   `python tools/vfx_manifest.py --set sim:eclipse_paint=rbxassetid://123456`
3. **Stock textures first.** Recipes on the five stock `rbxasset://` textures need no upload and no moderation; all three Snatch the Sun effects use them.
4. **Stale means re-upload.** If a generated texture changes after upload, its status becomes `stale` and it drops out of `Assets.luau` until you upload it again and `--set` the new id.
5. **Release gate:** `python tools/vfx_manifest.py --strict` exits 1 while any used asset has no current id.
6. **Kits under 200,000 characters.** `check.sh` fails a bigger kit (Roblox Source cap).

## Generated Luau

| File | From |
|---|---|
| `src/shared/VFX/VFXKit.luau` | `emit_luau.py --lib library/recipes` |
| `src/shared/VFX/Kits/<Name>.luau` | `studio_kit.js` (copied from `kits/`) |
| `src/shared/VFX/Assets.luau` | `vfx_manifest.py` (uploaded, current ids only) |
