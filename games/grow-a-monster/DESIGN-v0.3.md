---
title: Grow a Monster - v0.3 Design
date: 2026-11-19
tags: [design, grow-a-monster, monetization]
---

# Grow a Monster — v0.3 Design (expand + monetize + look better)

Back to [[README]] · Ideas: [[Game Ideas]] · Market: [[Top Roblox Games - Nov 2026]] · Tips: [[TikTok Notes]]

## What the top games do (research, Nov 2026)

| Game | Systems that keep people playing | Money |
|---|---|---|
| **Grow a Garden** | Rotating seed shop restock (~5 min), server-wide **weather** that causes **mutations** (value multipliers), **pets** that give passive boosts (equip up to 3), eggs, offline growth, seasonal events, daily quests | Robux shortcuts placed at "friction" moments; cosmetics as status |
| **Throw Food For Animals** | **Throw meter** (skill), **Throw Power** training at pull-up stands, 15 zones farther out, better food attracts rarer animals that earn passive cash | Food + power boosts |
| **Steal An Egg** | Steal eggs → hatch timer → pets earn cash; **Rebirth** resets cash for a permanent multiplier; speed/jump training gates biomes; bats/traps; **Index** (collection completion rewards) | Passes + boosts |
| **Steal a Brainrot** | Steal/protect loop, events | VIP pass 499 R$, 2x Money pass 119 R$ |

Warning sign: huge hits decline fast without updates (Steal a Brainrot lost ~30% of monthly visits within months of its peak). Plan for regular updates.

**Honest overlap note:** Throw Food For Animals already owns "throw food far to attract animals." Our difference: **one monster you raise and customize** (identity + flex), not a zoo of animals. Lean into that.

## Fixes from the v0.2 playtest (do these first)

Seen in Studio on 2026-11-19:
1. **Monster is tiny and far away.** At Size 1 it's a dot on the plot. Start the monster at ~14 studs tall, stand the player ~20 studs in front of it, camera facing it. The monster is the star; it should fill a third of the screen at spawn.
2. **Giant tree trunks block the camera at spawn.** Move/shrink trees near player spawns so the first view is clear.
3. **Income shows +0/sec at Size 1.** Start income at 1/sec minimum.
4. **Plots are empty flat grass.** Add a monster stage/bed, a food crate, a fence gate, the owner's sign facing the player, and decor that grows with progress.

## New systems (priority order)

### 1. Throw meter (skill)
Hold to charge, release on the sweet spot. **Perfect = 2x growth + "PERFECT!" pop + extra particles.** Keeps clicking fun instead of mindless. Mobile: same meter on the THROW button.

### 2. Arm Day training (Throw Power)
A gym station in the hub (pull-up bar, dumbbells). Training raises **Throw Power**, which multiplies growth per throw. Better gym equipment costs coins. Copies the proven Throw Food For Animals training loop.

### 3. Mutations
Every bite has a small chance to give the monster a **mutation** with a permanent income multiplier and a visual: Golden (x2), Frozen (x3), Electric (x4), Rainbow (x6), Cosmic (x10). Mutations stack (cap at 3). Shown on the name tag and leaderboard. This is Grow a Garden's best hook.

### 4. Server events (every ~10 min, random)
- **Food Rain**: free food falls from the sky, run and grab it
- **Golden Hour**: 3x mutation chance
- **Hungry Hour**: 2x growth
- **Monster Show**: 2-minute contest, biggest growth wins a prize
Banner + countdown for everyone. Gives a reason to stay online.

### 5. Rotating food shop (restock every 5 min)
Keep the 6 base foods always available. Add **rare foods** that appear in limited stock per restock (Spicy Pepper, Glow Mushroom, Star Fruit, Dragon Egg Omelette...) with higher growth and mutation chance. Restock timer on screen. Reason to come back.

### 6. Mini-monster pets (eggs → helpers)
Buy eggs with coins, hatch after a short timer, equip up to 3 mini-monsters. They **auto-throw food** at your monster and give boosts (+growth, +coins, +mutation luck). Rarity tiers Common → Legendary. **Index** screen: complete a set for a permanent bonus.

### 7. Rebirth → Evolution
At size milestones (1K, 10K, 100K...), rebirth resets Size and Coins but gives a **permanent multiplier** and a new **evolution form** (baby → teen → beast → titan → cosmic) with a different look. Keeps foods, pets, mutations. Classic retention engine.

### 8. Daily rewards + quests
Login streak calendar (7 days), 3 daily quests ("Throw 200 food", "Get 1 perfect streak of 10", "Hatch an egg"). Rewards: coins, eggs, rare food.

### 9. Light social: Snack Thief (v0.4, optional)
Sneak onto another plot and steal from their food crate; owners can bonk thieves. Taps into the #1 steal trend without making it the whole game. Do this only after 1–8 work.

## Monetization (Roblox-compliant)

Rules first:
- Use the vault's `roblox-monetization-compliance` skill and the DataStore/receipt notes. **ProcessReceipt must be idempotent and saved** before granting (high stakes: real money).
- **Paid random items** (eggs bought with Robux) must show odds before purchase. Keep Robux eggs out of v0.3 to stay safe; eggs are coins-only.
- No fake urgency, no misleading prices, nothing that blocks progress unless you pay.

### Game passes (one-time)
| Pass | Price | What it does |
|---|---|---|
| 2x Coins | 149 R$ | Double coin income forever |
| Auto Throw | 199 R$ | Throws for you (toggle), great for AFK |
| VIP | 349 R$ | 1.5x growth, VIP name tag + chat tag, VIP hat for your monster |
| Lucky Monster | 249 R$ | 2x mutation chance |
| +1 Pet Slot | 129 R$ | Equip 4 mini-monsters |

### Developer products (repeatable)
| Product | Price | Notes |
|---|---|---|
| **Starter Pack** | 9 R$ | One-time per player: coins + Burger unlock + a cute hat. The <10 R$ "first purchase" trick from the TikTok notes |
| Coin packs (S/M/L/XL) | 19 / 49 / 99 / 249 R$ | Amount scales with the player's income so they stay useful |
| Growth Potion (15 min, 2x) | 39 R$ | |
| Instant Restock | 25 R$ | Refreshes your rare-food stock |
| Skip Hatch | 15 R$ | |
| **Food Rain for Everyone** | 199 R$ | Triggers a server event with the buyer's name on the banner; social flex like Grow a Garden "admin abuse" moments |

### Where to show them (friction moments, not pop-up spam)
- Click a food you can't afford → prompt the **smallest coin pack that covers it**, then auto-buy the food (from [[monetization-crash-course]])
- Restock timer → small "Restock now" button
- Hatch timer → "Skip" button
- After a rebirth → offer Growth Potion once
- Show paid stuff **in the world**: a VIP pad at the hub, a gold "2x" sign by the shop, VIP monsters wearing the hat
- Starter Pack offered once after ~3 minutes of play, never spammed

## Making it look like the top games

Honest limit: games built only from scripted Parts top out at "clean but simple." The top games use **custom meshes** (made in Blender). Biggest visual win per hour:
1. **The monster as a real mesh** (one sculpted body + evolution forms), made in Blender. Claude Code running **locally** can drive Blender; or generate with Tripo/Meshy and clean up.
2. Food as meshes (6–12 small models).
3. Keep the map in parts/terrain for now; it already reads well.

Upload meshes through Studio (Asset Manager / Import 3D), then reference the asset IDs in Config. Never invent asset IDs.

## Build order
1. v0.2 playtest fixes (above)
2. Throw meter + Arm Day training
3. Mutations + server events
4. Rotating shop + rare foods
5. Monetization (passes, products, receipt handling) + friction-moment prompts
6. Mini-monster pets + Index
7. Rebirth/evolution
8. Daily rewards + quests
9. Mesh art pass (monster first)
