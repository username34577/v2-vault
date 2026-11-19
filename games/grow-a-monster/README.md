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

## v0.2: visual overhaul (2026-11-19)

Look: bright, cute-cartoony, cozy (Grow a Garden with a goofy edge). One palette in `Config.Palette`, SmoothPlastic everywhere, Neon only on small accents. Gameplay, remotes, rate limits and `Data.luau` are unchanged.

- **Map:** a floating island over a sea of drifting clouds, with a chunky rock underside, hanging vines and 4 bobbing mini-islands. The hub has a sunny spawn pad and a 4-sided BIGGEST MONSTERS board. There are 8 fenced plots with giant flowers, rocks, a feeding spot and an owner sign. Lighting is set at ~2:30 PM: warm sun, blue-lavender shadows and haze, Terrain clouds, soft bloom and a warm colour grade. If you fall off, you're put back on your plot (fade + whoosh).
- **Monster:** a chubby jelly blob with big derpy eyes (one bigger), a big mouth with a tongue and one tooth, blush, little arms and feet, and spots. It breathes, hops, blinks, opens wide and raises its arms when food is coming, and squashes when it gulps. Looks unlock at size 25 (leaf sprout), 100 (horns), 1K (wings), 10K (crown) and 100K (sparkle aura).
- **Food:** apple, burger, cake, pizza slice, golden steak and cosmic candy, each built from parts and toy-sized.
- **UI:** coin/size chips, a next-look progress bar, a big SHOP button with a "!" badge, and a big THROW button with the equipped food (kept clear of the phone jump button). The shop has 3D food cards, BEST VALUE / NEXT UP tags, "x faster" chips, a savings progress bar and a shine on buys you can afford. One responsive scale keeps taps at 44 px or more and text at 12 px or more.
- **Feel:** floating "+X", crumbs, coins flying to the counter, a gulp/throw/coin/buy/milestone/click sound for each action, a small screen bump on Cake and bigger, confetti on purchases, sparkles on milestones.
- **First 30 seconds:** "Feed me!" plus a bouncing arrow over your monster, a "Tap to feed your monster!" pill (wording per device), and on phones an arrow at THROW. It all fades after 3 bites. Later, an arrow points at SHOP the first time you can afford new food.

**How it stays secure:** the server keeps an invisible hitbox ball per monster (same size and range check as v0.1) and still decides when food lands, the growth and the coins. Clients draw the monster and the food themselves. A new `Fx` remote goes **server → client only** (thrown / eaten / fell), so there is nothing new a client can send.

## Files

| File | Goes to | Job |
|---|---|---|
| `src/shared/Config.luau` | ReplicatedStorage.Shared | All numbers and colours: foods, prices, palette, lighting, map, monster, feel, tutorial, sound IDs |
| `src/shared/Build.luau` | ReplicatedStorage.Shared | Part helpers (ball, ellipsoid, cylinder, wedge) |
| `src/shared/Props.luau` | ReplicatedStorage.Shared | Flowers, trees, bushes, rocks, crown |
| `src/shared/FoodModels.luau` | ReplicatedStorage.Shared | The 6 food shapes |
| `src/shared/Format.luau` | ReplicatedStorage.Shared | 1.2K / 3.4M number format |
| `src/server/Main.server.luau` | ServerScriptService | Plots, throwing, shop, income, leaderboard, fall safety |
| `src/server/World.luau` | ServerScriptService | Island, hub, plots, signs, lighting |
| `src/server/Monster.luau` | ServerScriptService | Monster hitbox + size |
| `src/server/Data.luau` | ServerScriptService | Saving (session-locked), unchanged |
| `src/client/Client.client.luau` | StarterPlayerScripts | Entry: input, server sync, cues |
| `src/client/MonsterView.luau` | StarterPlayerScripts | Draws and animates every monster |
| `src/client/FoodFlight.luau` | StarterPlayerScripts | Thrown food arcs |
| `src/client/Decor.luau` | StarterPlayerScripts | Cloud sea + bobbing mini-islands |
| `src/client/UI.luau`, `Hud.luau`, `Shop.luau` | StarterPlayerScripts | UI kit, HUD, shop |
| `src/client/Feel.luau`, `Tutorial.luau`, `Sound.luau` | StarterPlayerScripts | Juice, first-30-seconds hint, sounds |

To rebalance or restyle the game, only edit `Config.luau`.

## Run it in Studio (Rojo)

1. Download Rojo for Windows from https://github.com/rojo-rbx/rojo/releases (the `windows-x86_64` zip), unzip `rojo.exe`.
2. In a terminal in that folder: `rojo plugin install` (adds the Rojo plugin to Studio).
3. `cd` into this folder (`games/grow-a-monster`) and run: `rojo serve`
4. In Studio: new **Baseplate** → **Plugins** tab → **Rojo** → **Connect**. The scripts appear.
5. Press **Play**. The map, lighting and monsters are built by code when the game starts, so Edit mode still looks like the empty Baseplate. That's expected. The script removes the Baseplate and its spawn.

Things that can only be done in Studio:
- **Lighting → LightingStyle = Realistic** (one click). The script tries to set it, but if scripts aren't allowed to, the soft shadows won't show.
- **Sounds:** open the Creator Store (Toolbox → Audio), pick free sounds, and paste their IDs into `Config.Sounds` (each slot says what it's for). Empty slots are skipped silently.
- To test saving: Game Settings → Security → **Enable Studio Access to API Services** (game must be published first).
- Set **Max Players to 8** (Game Settings → Places) to match the 8 plots.
- Phone check: **Test → Device** emulator (e.g. iPhone 14 landscape) and play a minute.

## v0.2 playtest checklist (not run in Studio yet)

- [ ] Spawn → you land on your plot facing your monster; your name is on the sign
- [ ] Island, cloud sea and mini-islands look right; no default grey sky; nothing floats or pokes through
- [ ] Monster breathes, hops, blinks; mouth opens as food flies in; squashes on the bite
- [ ] Each food looks like its name (shop icons and thrown food)
- [ ] "+X" pops above the mouth, coins fly to the counter, screen bumps on Cake and up
- [ ] New player: "Feed me!" arrow + hint, gone after 3 bites; SHOP arrow when Burger is affordable
- [ ] Shop: tags, x-faster chips, shine, progress fill; buy → confetti + EQUIPPED; can't afford → toast
- [ ] Size 25/100 → sprout/horns pop in with a toast (use the command bar to set Size if needed)
- [ ] Jump off the island → fade, back on your plot
- [ ] Phone emulator: THROW not under the jump button, nothing under the notch, text readable
- [ ] Leaderboard board lists players by size

## Next ideas (from [[TikTok Notes]])

- Robux: cheap starter pack (<10 Robux), coin packs, and auto-prompt the smallest pack when you can't afford a food ([[monetization-crash-course]])
- Rebirth: reset size for a permanent growth multiplier
- Mutations: rare foods give the monster special colours (size milestones already add horns, wings and a crown)
- Funnel analytics to see where new players quit ([[prompt-funnel-analytics]])
