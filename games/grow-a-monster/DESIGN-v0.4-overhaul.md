---
title: Grow a Monster - v0.4 Overhaul Design
date: 2026-11-19
tags: [design, grow-a-monster]
status: proposed
---

# Grow a Monster — v0.4 Overhaul: "Snack Grove"

Why: [[AUDIT-2026-11-19]] · Evidence: [[New Roblox Hits - Design Lessons (Nov 2026)]] · Replaces the build order in [[DESIGN-v0.3]] (its monetization/pets/rebirth ideas come back *after* this loop is fun).

## The concept stays; the verb changes

The concept was **"raise a monster by feeding it."** That stays. What changes is *how you get the food*. Today food is free and infinite, so feeding is just clicking. In v0.4, **food is something you go out and win**, and your monster is a companion that walks with you.

## Core loop (one run ≈ 1–3 minutes)

1. **Hungry monster.** Your monster's belly rumbles; a banner gives the objective (e.g. "Bring 5 snacks from the Snack Grove"). A path guide points the way.
2. **Walk out together.** Your monster follows you (walk/run animations). At the Grove gate it sits and waits: *"Too loud for the Grove — I'll wait here!"*
3. **Forage.** Snack plants grow goofy food: Apple Bushes (+1), Burger Shrubs (+3), a Cake Tree (+10), and one **Golden Melon** (+50). **Hold to shake** a plant; snacks pop out and stack on your head. Your carry limit starts at 3.
4. **Don't get caught.** The **Grumpy Gardener** patrols the Grove. He has a visible vision cone. If he sees you carrying snacks: he yells, bonks you, and **you drop everything**. Tall grass hides you. The best snacks grow closest to his path.
5. **Bring it home.** Leave the gate and your monster runs to you. **Throw** snacks to it: it jumps and catches them. Growth, coins, crumbs, a happy reaction.
6. **Objective complete → reward.** Coins, a bigger monster, and the next objective.

**Decisions every run:** carry more (risky) or bank what you have; go for the Cake Tree / Golden Melon near the Gardener or play safe.

## First 5 minutes

| Time | What happens |
|---|---|
| 0:00 | Spawn beside your monster. Objective: "Your monster is starving! Bring 3 snacks from the Snack Grove." Guide line to the gate |
| ~0:30 | At the gate: monster sits. You shake your first Apple Bush |
| ~1:00 | First feed: catch animation, "+X", growth. Objective 2: "Bring 5 snacks" |
| ~2:00 | You meet the Gardener (first challenge). Getting caught once teaches the rule |
| ~3–4:00 | Objective 3: "Steal the Golden Melon" — the real challenge. Reward: big growth + new look |
| ~5:00 | Coins buy the **Bigger Backpack** (carry 5). Teaser: a boulder blocks the next zone — "Grow your monster to Size 250 to smash it" |

## Why players repeat

Plants regrow (about 45 s); the Golden Melon respawns every few minutes. Backpack and Sneaky Shoes upgrades change how you play. Size unlocks the next zone (the monster smashes the boulder). Later: mutations, events and pets from v0.3 attach to this loop.

## Monster redesign

- **Rigged R15 creature**, generated with Roblox's avatar generator through Studio MCP (`generate_avatar`). It gets a real head, torso, arms, legs, feet and joints, so it can walk, run, sit, jump and catch.
- Animations: Roblox's default R15 walk/run/idle/jump, read from a live character's `Animate` script, so no asset ids are invented. Custom catch/happy/sit animations come from `generate_animation` if quality holds.
- Grows with `Model:ScaleTo` (a capped scale, so it never overflows the plot again).
- **Honest limit:** AI-generated meshes are a fast prototype, not hand-sculpted art. If the result isn't good enough, the fallback is a Blender sculpt (manual or a separate session), uploaded through Studio's 3D importer.

## Server authority (unchanged rules)

The server owns: plant cooldowns, what you carry, Gardener detection (server raycasts and vision cone), drops, feeding results, coins, upgrades. The client only asks "shake <plant>" (ProximityPrompt, range checked), "throw", "buy <upgrade>". Saved fields are added through `Data.newData()` + `migrate()`. Old food ownership stays saved, untouched.

## Vertical slice scope (build this first)

1. The generated, rigged monster following you, with walk/run/idle/sit.
2. Snack Grove zone: 6–8 plants, tall grass, a gate.
3. Grumpy Gardener: patrol route, vision cone, catch → drop.
4. Carry stack + throw-to-feed with a catch animation.
5. 3 objectives with rewards, plus the Bigger Backpack upgrade.
6. Sounds for shake, pickup, caught, catch, reward (Creator Store ids found in Studio, never invented).

Out of the slice: zone 2, monetization, pets, rebirth, mutations.
