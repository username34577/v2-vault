---
title: Snatch the Sun - Design (v0.1)
date: 2026-11-19
tags: [design, snatch-the-sun, monetization]
status: planned
---

# Snatch the Sun — Design v0.1

> Grab the sun, hold it to earn coins, and don't get punched.

Previous project (archived, not deleted): [[games/grow-a-monster/README|Grow a Monster]]. Market notes: [[Top Roblox Games - Nov 2026]] · [[TikTok Notes]] · [[Game Ideas]]

## Name

Working title **Snatch the Sun!** Other options, in order: **Sunbrawl**, **Sun Snatchers**, **Hot Sun!**

Why not "Steal the Sun": the "Steal a ___" space is crowded ("Steal the Moon", "Steal a Planet", "Steal a Sun Brainrot" all exist). "Steal the Moon" (a co-op rope-pulling trainer) peaked at ~3K CCU on 2026-10-24 and was at ~7% of that two weeks later: a trendy title gets clicks, gameplay keeps players.

Checked 2026-11-19: web search found no Roblox game named "Snatch the Sun", "Sunbrawl" or "Sun Snatchers". **Search Roblox directly before publishing** to be sure.

## Direction: chaotic party game (decided)

Not competitive PvP. Reasons: matches what's trending (ragdoll chaos, mobile, shareable clips), forgives lag and new players, losing is funny. A ranked mode can come later.

## Core loop (round ≈ 3 minutes, 2–10 players)

1. The sun drops in the middle of the arena. Everyone races for it.
2. The carrier **glows**, moves at a **fixed small speed penalty** (no escalating slowdown) and **earns coins every second**.
3. Everyone else tries to knock it loose.
4. **Sun Overload** (see below) forces the sun to change hands regularly.
5. Round end: longest total hold wins the round bonus. Smaller rewards for steals and knockouts, so players who never hold it still earn.

### Moves (3 big buttons on mobile)
- **Punch**: fills the target's **stagger meter** (visible). Full meter = **~1 s ragdoll** (short, funny, not frustrating) and the sun pops loose.
- **Dash**: short burst with a cooldown, for chasing or escaping.
- **Throw** (carrier only): toss the sun away. A thrown sun **can't be caught for 1 s**, so friends can't farm by passing it back and forth.

### Sun Overload (signature mechanic)
- 10 s held: the sun pulses. 20 s: visible energy waves. 30 s: **overload**.
- Overload blasts **everyone nearby back equally, the carrier included**, and launches the sun to a **random spot**. It's a chaotic reset, never a defensive advantage for the holder.
- Decision every hold: keep it for more coins, or throw it somewhere safer before it blows.
- Timings are starting values for playtesting, not final balance.

### Fairness rules
- 3 s spawn protection.
- Upgrades are capped; skill and chaos decide most rounds.
- Short rounds, so a loss never stings.

## Bots (required in v0.1)
Empty or near-empty servers have no game. Fill to a minimum of ~4 players with bots that chase the sun, punch, dash, and sometimes throw. They must look believable (not perfect aim, small reaction delays). Bots leave as real players join. This is real work: budget for it.

## Map v0.1
One floating sky arena: bridges, bounce pads, ledges to fall off, a few dark hiding spots (the sun still glows there). Hazards: spinning arms, fans. Falling = ragdoll, respawn in 3 s.

## Gloves (progression + main revenue)
Gloves are **different, not strictly better**. Each has a trade-off:

| Glove | Strength | Weakness | How to get |
|---|---|---|---|
| Starter | Balanced | Nothing special | Free |
| Heavy | Big knockback | Slow wind-up | Coins |
| Speed | Fast jabs, longer dash | Weak hits | Coins |
| Magnet | Pulls a loose sun toward you | Short range | Coins |
| Bounce | Launches people upward | No stagger damage | Coins |
| Fire (Robux) | Burn trail that slows chasers | Same power budget as earned gloves | 149–499 R$, or a long grind |
| Lightning (Robux) | Short chain stun | Same power budget | Robux or grind |

Earned stat bonuses are allowed but **capped at about +10–20% over Starter**. Robux gloves are flashy and unique, balanced against earned gloves. Avoid a Robux-only glove that is simply the best.

## Monetization

Rules: no fake urgency, no misleading prices, ProcessReceipt saved before granting (use `skills/roblox-monetization-compliance`). No paid random items in v0.1.

**Game passes:** 2x Coins 149 R$ · VIP 299 R$ (gold tag, VIP sun glow, +10% coins, a VIP glove) · Extra Glove Slot 99 R$ · Emote Pack 99 R$ · Auto-Collect 79 R$

**Robux gloves:** 149–499 R$, one new glove every 1–2 weeks (recurring income).

**Developer products:** Starter Pack 9 R$ (once) · Coin packs 19/49/99/249 R$ · 30-min 2x Boost 39 R$ · Sun Storm (5 suns for the whole server, buyer's name on the banner) 149 R$ · Instant Respawn 5 R$

**Later:** season pass (free + 399 R$ paid track), rotating daily cosmetics shop (sun skins, knockout effects, trails, poses 49–199 R$), private servers (~100 R$/month).

**v0.1 ships only:** Starter Pack, 2x Coins, 2–3 Robux gloves.

## Social
Built for friend groups. Ragdoll fails = free TikTok clips. Server board: "Longest Sun Hold". Knockout emotes.

## First 30 seconds
Spawn → arrow to the sun → grab it → coins pour in → someone punches you. The whole game is learned in ~20 s.

## v0.1 scope (build this, nothing more)
1. One arena with hazards and respawn
2. Sun pickup, carry glow, fixed speed penalty, coins per second
3. Punch + stagger meter + 1 s ragdoll, Dash, Throw with 1 s no-catch
4. Sun Overload
5. 3-minute rounds, round results, rewards for hold/steal/knockout
6. Bots filling to ~4 players
7. Glove system with Starter + 2 earned gloves + 2 Robux gloves (cosmetic-level visuals, balanced)
8. Starter Pack + 2x Coins pass
9. Saving (reuse the session-locked `Data.luau` pattern from Grow a Monster)
10. Mobile controls tested on a phone

**Out of v0.1:** season pass, daily shop, private servers, team mode, ranked, extra maps, seasonal suns.

## How we'll know it works
1. 3–5 friends play it (one on a phone).
2. Watch: do they laugh, do they queue another round without being asked, how long they stay.
3. If yes → cheap ad test (3–5 honest thumbnails, cost per play, per [[roblox-ads-and-thumbnails]]). If no → fix combat feel before adding anything.

## Risks
- Combat feel and lag (test on phone early)
- Empty servers (bots + small server size)
- Simple games need regular updates (new maps, gloves, seasonal suns)
