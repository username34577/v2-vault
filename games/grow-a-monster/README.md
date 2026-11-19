# Grow a Monster

> Throw food at your monster until it's huge. Biggest monster on the server wins.

Idea source: [[Game Ideas]] (#2). Mixes Throw Food For Animals (silly throwing, top 5) with Grow a Garden (grow + collect).

## v0.1 (built 2026-11-18)

**Core loop:** throw food → monster grows + you get coins → coins buy better food → grows faster.

- 8 plots in a ring, one per player, each with a monster built from parts (no uploads needed)
- Throw: THROW button (mobile), left click, F key, or controller R2
- Food arcs into the monster, it "gulps" (squash + particles) and grows
- Passive income: coins every second based on size
- Shop: 6 foods (Apple free → Cosmic Candy 90K)
- Leaderboard: Size + Coins
- Saving with session locking (no duplicated or lost data across servers)
- Offline earnings: 25% of income while away, max 2 hours, with a welcome-back message

**Security:** the client only sends "throw", "buy <id>", "equip <id>". The server owns prices, growth, coins, cooldowns and distance checks, and rate-limits every remote.

## Files

| File | Goes to | Job |
|---|---|---|
| `src/shared/Config.luau` | ReplicatedStorage.Shared | All numbers: foods, prices, cooldown, income |
| `src/server/Main.server.luau` | ServerScriptService | Plots, throwing, shop, income |
| `src/server/Data.luau` | ServerScriptService | Saving (session-locked) |
| `src/server/Monster.luau` | ServerScriptService | Builds, sizes and feeds the monster |
| `src/client/Client.client.luau` | StarterPlayerScripts | HUD, shop UI, throw input |

To rebalance the game, only edit `Config.luau`.

## Run it in Studio (Rojo)

1. Download Rojo for Windows from https://github.com/rojo-rbx/rojo/releases (the `windows-x86_64` zip), unzip `rojo.exe`.
2. In a terminal in that folder: `rojo plugin install` (adds the Rojo plugin to Studio).
3. `cd` into this folder (`games/grow-a-monster`) and run: `rojo serve`
4. In Studio: new **Baseplate** → **Plugins** tab → **Rojo** → **Connect**. The scripts appear.
5. Press **Play**.

To test saving in Studio: Game Settings → Security → **Enable Studio Access to API Services** (game must be published first). Without it the game still runs, it just doesn't save.

Set **Max Players to 8** (Game Settings → Places) to match the 8 plots.

## Not tested yet

Written and compile-checked, but not played in Studio yet. First playtest checklist:
- [ ] Monster spawns on your plot facing you
- [ ] Throwing works (button, click, F) and the monster grows
- [ ] Coins tick up every second; shop buys and equips
- [ ] Leave and rejoin: size and coins saved, offline coins message shows

## v0.2 ideas (from [[TikTok Notes]])

- First 30 seconds: big arrow / "Click to feed!" hint, no tutorial wall
- Robux: cheap starter pack (<10 Robux), coin packs, and auto-prompt the smallest pack when you can't afford a food ([[monetization-crash-course]])
- Rebirth: reset size for a permanent growth multiplier
- Mutations: rare foods give the monster horns, wings, colors
- Funnel analytics to see where new players quit ([[prompt-funnel-analytics]])
- Sounds on throw and gulp ([[prompt-nintendo-game-feel]])
- Server leaderboard board in the middle of the map
