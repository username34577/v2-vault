---
name: roblox-player-sims
description: 'Simulated playtesters for a Roblox game: role-play specific kid/teen players (impatient, sound-off, first-timer, month-long regular, friend group) to find boredom, confusion and weak moments, then fix and re-run. Use for "playtest", "is my game fun", "why do players leave", "first 60 seconds", "simulate a player".'
---

# Roblox Player Sims

Source: @momentumcash's simulated-player prompts (see `research/TikTok Notes/creator-momentumcash.md`). A sim is cheap, so run several. It is **not** a replacement for real players or Funnel Analytics. It finds obvious problems before real players do.

## How to run one

1. **Gather the evidence first.** A sim with nothing to look at is a guess. Read the game's design note (`games/<game>/`), the scripts for the part being tested, and, if Studio MCP is available, play it and take screenshots. Say plainly which parts you saw and which you inferred.
2. **Pick 1–3 personas** from the table below that match the question. Don't run all of them.
3. **Walk through as that player, second by second**, for the window the persona covers (first 10 s, first 60 s, a whole session, day 30). Write what they see, what they try, what they think, and the exact moment they get bored, confused, scared off or leave.
4. **List findings** as `moment | what the player felt | why (what in the game causes it) | fix`. Rank by how many real players it would hit.
5. **Fix the top 1–3**, then **re-run the same persona** on the fixed version. Stop when that persona passes or the remaining issues are minor. Note what changed.
6. For a stronger check, run each persona as a **separate sub-agent** that hasn't seen your fixes, so it isn't grading its own work (same idea as `council-method`).

## Personas

| Persona | Window | Pass when |
|---|---|---|
| Impatient kid | first 60 s | stays engaged the whole minute |
| Impatient 8-year-old | first session | you've fixed the first 3 moments they got bored |
| 7-year-old who can't follow complicated instructions | tutorial | plays with no help and no reading |
| New player, 10-second test | first 10 s | knows the goal without reading anything |
| 8-year-old with all coins, XP, badges and rewards removed | core loop | the bare loop is still fun |
| Kid who's played daily for a month | day 30 | still has something to chase; nothing feels like a chore |
| Easily distracted kid | session | always has a next reason to keep playing |
| Kid half-watching YouTube on another screen | session | important moments are readable at a glance |
| Kid with sound off | session | no event is missed; visual feedback carries it |
| 7-year-old exploring the map for the first time | map | finds the key areas; nothing important is overlooked |
| 8-year-old joining a server of much better players | first session | not intimidated; beginners have their own way in |
| Teen who only plays with friends | group session | the game is clearly better with friends |
| Two best friends, first time | session | at least one moment worth talking about at school |
| Kid showing the game to a best friend | session | they have something to show off |
| 14-year-old showing an 8-year-old brother | first session | the younger kid manages without help |
| Kid with a friend watching over their shoulder | session | the watcher wants to join |
| Kid trying to make friends laugh | session | the game gives them tools for funny moments |
| Group of kids arguing which game to play | choice | their objections to yours are answered |
| YouTuber recording the game | session | 3 clip-worthy moments |
| 16-year-old who assumes every game is AI-made | visuals | no generic UI, mismatched art or off-style models give it away |
| 7-year-old browsing the shop | shop | every item is clear: what it does, cost, why want it |
| Kid deciding whether an upgrade is worth it | upgrade | the upgrade looks and feels worth it |
| 7-year-old picking from your thumbnail + 20 others | thumbnail | yours is the one they'd click (honestly, no misleading art) |
| Mobile player on a small phone | UI | nothing overlaps, hides or is too small to tap |
| Low-end phone | performance | steady FPS during real gameplay |

## Rules

- **Monetization sims test clarity and value, never pressure.** Do not run "make the kid spend a parent's card" or "beg for more screen time" goals. Designing to pressure children into spending or compulsive play breaks Roblox's rules for younger players and gets games reported. Use the shop/upgrade personas instead, and check purchases with `roblox-monetization-compliance`.
- Don't invent data. A sim says "likely", not "players will". Confirm with Funnel Analytics and real playtests (see `research/TikTok Notes/prompt-funnel-analytics.md`).
- Pass the fixes through the normal vault workflow: `AGENTS.md` lookup for the systems you touch, `quality-score` for assets.
