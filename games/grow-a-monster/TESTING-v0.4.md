---
title: Grow a Monster - v0.4 Test Log
date: 2026-11-19
tags: [testing, grow-a-monster]
---

# Grow a Monster — v0.4 Test Log (2026-11-19)

Design: [[DESIGN-v0.4-overhaul]] · Audit: [[AUDIT-2026-11-19]]

How it was tested: Roblox Studio Play Solo, driven through Studio MCP (client and server scripts, screenshots). Character moves were scripted (teleports and `Humanoid:MoveTo`), and prompts were triggered with `ProximityPrompt:InputHoldBegin/End`. **No human played it with a keyboard or a phone yet.**

## Verified working (seen in Studio)

| Check | Result |
|---|---|
| Output on start | No new errors or warnings. Only pre-existing ones: DataStore off in Studio, `rbxassetid://203785492` type mismatch (not from our code) |
| Spawn | New player stands in front of the monster on its stage. Objective card: "Your monster is starving! Bring 3 snacks…". Guide line points to the Grove |
| Monster | Generated + auto-rigged creature (head, body, arms, legs, feet, face). Server plays Roblox default R15 idle/walk/run/jump/fall; confirmed tracks switching idle → walk → run as distance grows. It follows you, waits beside the bridge while you're in the Grove, hops to catch snacks, and scales with Size (scale 2 at Size 1) |
| Shake | Hold prompt → snack stacks on your head, carry badge 1/3, plant hides its fruit and regrows (Apple 25 s) |
| Carry limit | 3 with Pocket, 5 after Bigger Backpack. Full hands → toast, no pickup |
| Gardener | Patrols, R15 walk/idle, yellow vision cone points forward. Carrying + in cone → caught after ~0.35 s: snacks gone, put outside the gate. Empty-handed in front of him → nothing happens |
| Feed | FEED near monster → arc, catch hop, Size/coins up. Refused (with a toast) inside the Grove or too far |
| Objectives | 1 (3 snacks) → 2 (6 snacks) → 3 (Bigger Backpack bought at stand, 150 coins deducted) → 4 (Golden Melon fed: Size 31→111, +250 coins) → 5 (Size 250, progress 111/250). Each pays coins and updates the card |
| Sounds | All new sound ids load in this experience (checked with `PreloadAsync`). Not listened to |
| Performance | ~3.8K BaseParts in Workspace (Grove ~1.1K, mostly grass blades). No per-frame server loops besides 0.2 s follow and 0.15 s sight checks |

## Not tested yet (be honest)

- **Real hands-on play:** walking the route, sneaking past the Gardener on foot, how hard/fun it feels. All movement in tests was scripted.
- **Phone layout:** the Device emulator can't be driven through MCP. Check the objective card (300 px wide) against the stats chips on a small landscape phone.
- **Multiplayer:** only one player. Untested: two monsters following through the same gate, two players caught at once, plot reuse after leave.
- **Saving:** DataStores are off in this Studio session; new fields (Backpack, Objective, ObjectiveProgress, SnacksFed) are added through `newData()` + `migrate()` but weren't round-tripped.
- **Monster at big sizes** (Size 1K+, scale up to 5): pathing through plot gates and the bridge; it teleports next to you when stuck.
- **Sound mix:** volumes are guesses.

## Known problems

- The monster model lives in `ServerStorage.MonsterRig` in the **place file**, not in Rojo. Save the place or it's lost (the game then falls back to a plain pink R15 body).
- Every player's monster is the same pink creature (plot colours no longer tint it).
- The Gardener is a default Roblox body with a part-built hat; he doesn't match the monster's quality yet.
- Milestone looks (sprout, bow, wings, crown, aura) are part-built add-ons placed by guesswork on the rig; check them at Size 25/100/1K/10K.
- Old `Shop.luau` and `Tutorial.luau` are unused in v0.4.
- No zone 2 yet: objective 5 ("Size 250") has no new place to unlock.

## Next priorities

1. A human playtest of the first 5 minutes (PC and phone emulator); tune Gardener speed/sight, regrow times, rewards.
2. Monster variety: 2–3 more generated monsters (or per-plot colour variants), then evolution forms.
3. Zone 2 unlocked by Size, with a new threat rule (not another cone).
4. Then bring back v0.3 ideas on top of this loop: mutations from rare snacks, events (Golden Hour = melon respawns), monetization (ProcessReceipt saved before granting).
