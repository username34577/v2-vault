# Review: Roblox Game Research section

**Verdict: READY FOR APPROVAL** · 2026-11-21 · base `origin/main` · head `a057e86` (+ uncommitted)

## Changed files
(uncommitted only)

**agent instructions**
- `??` .claude/settings.json
- `M` CLAUDE.md
- `??` skills/game-research/SKILL.md
- `M` skills/lihfolk/references/vault-map.md

**notes**
- `??` research/Roblox Game Research/Games/Fish It.md
- `??` research/Roblox Game Research/Games/Grow a Garden.md
- `??` research/Roblox Game Research/Games/Steal An Egg.md
- `??` research/Roblox Game Research/Games/Steal a Brainrot.md
- `??` research/Roblox Game Research/Games/Throw Food For Animals.md
- `??` research/Roblox Game Research/Reference Log.md
- `??` research/Roblox Game Research/Research Index.md
- `??` research/Roblox Game Research/Roblox Game Research.md
- `??` research/Roblox Game Research/_inbox/README.md
- `??` research/Roblox Game Research/_templates/Game Research.md

**other**
- `M` .gitignore
- `??` research/Roblox Game Research/_tools/media-registry.json
- `??` research/Roblox Game Research/_tools/research_index.py
- `??` research/Roblox Game Research/_tools/test_research_index.py
- `??` research/Roblox Game Research/research-index.json

## Evidence
- (no code changed: notes/config only)

## Screenshots
- none

## High-stakes areas touched (read the vault notes' Common mistakes + Checklist)
- none detected

## Owner decision
- [ ] Approve  - [ ] Ask for changes  - [ ] Reject
- Notes:

## Diff (first 400 lines)
```diff
diff --git a/.gitignore b/.gitignore
index bf8de71..f14899a 100644
--- a/.gitignore
+++ b/.gitignore
@@ -28,3 +28,6 @@ LihFolk Vault V2/.smart-env/
 # lint tool downloads (luau-lsp Roblox definitions)
 dev/lint/.cache/
 sourcemap.json
+
+# game research: videos over 95 MB stay local (GitHub rejects files over 100 MB)
+research/Roblox Game Research/Media/_large/
diff --git a/CLAUDE.md b/CLAUDE.md
index 5c17ccd..7e5941c 100644
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -23,3 +23,8 @@ Follow AGENTS.md for Roblox work in this repo.
 - End of a work session: log verified lessons with the `session-learning` skill (`learning/`).
 - New game: style spec first (`game-style-spec`); before ads or launch: `first-60-seconds-review`.
 
+## Game research (consult before major decisions)
+
+- Before a major game-development decision (a new feature or system, economy or monetization, UI redesign, onboarding or progression change), consult the references and say which ones you used: `python "research/Roblox Game Research/_tools/research_index.py" --consult "..."`, then follow the `game-research` skill. A UserPromptSubmit hook in `.claude/settings.json` adds the top matches to prompts that look like design decisions.
+- Log each such decision as a row in `research/Roblox Game Research/Reference Log.md` (which references influenced which feature).
+- New recordings and screenshots go in `research/Roblox Game Research/_inbox/`; the SessionStart hook files them and rebuilds the index. Hub: `research/Roblox Game Research/Roblox Game Research.md`.
diff --git a/skills/lihfolk/references/vault-map.md b/skills/lihfolk/references/vault-map.md
index 327f2dc..178719e 100644
--- a/skills/lihfolk/references/vault-map.md
+++ b/skills/lihfolk/references/vault-map.md
@@ -31,7 +31,7 @@ Loaded on demand by the `lihfolk` router. `<VAULT>` is the absolute vault path t
 
 ## Specialist skills in this plugin
 
-Prefer these when the task matches: `quality-score` (every generated asset or system must score at least 8.5/10), `council-method` (objective verdicts; the user-facing command is `/lihfolk:council`), `lihfolk-ui` (house menu style), `lihfolk-assets` (original models, materials, skies, animations and VFX from the local asset pack: search its catalogues before modelling from scratch), `lihfolk-vfx` (slashes, impacts, projectiles, auras, AoE telegraphs, shields, beams, camera shake, hit-stop, VFX replication), `lihfolk-figma` (Figma frames to Roblox UI, design tokens, VFX texture sheets), `lihfolk-sfx` (layered, pooled combat and UI sounds synced to the same markers, sourced only from premium licensed sounds: Roblox-licensed Creator Store audio or a library the user owns), `lihfolk-systems`, `lihfolk-worldbuilding` (maps, levels, biomes, towns, dungeons, lobbies, obby areas, terrain: layout, composition and dressing with a placement and audit toolkit), `lihfolk-tutorial` (tutorials, onboarding and FTUE that keep first-time players), `roblox-blender-modeling`, `roblox-trend-game`, `roblox-player-sims` (simulated kid/teen playtesters that find boredom and confusion, then fix and re-run), `first-60-seconds-review` (scored review of a new player's first minute), `game-style-spec` (per-game style spec, owner decides), `agent-work-review` (review packet with diff, lint, tests and screenshots before approval), `session-learning` (verified lessons into `learning/`), `roblox-system-builder`, `roblox-ui-builder`, `roblox-secure-remotes`, `roblox-datastore-safety`, `roblox-performance-audit`, `roblox-debugging`, `roblox-anti-exploit-review`, `roblox-monetization-compliance`, `roblox-asset-import`.
+Prefer these when the task matches: `quality-score` (every generated asset or system must score at least 8.5/10), `council-method` (objective verdicts; the user-facing command is `/lihfolk:council`), `lihfolk-ui` (house menu style), `lihfolk-assets` (original models, materials, skies, animations and VFX from the local asset pack: search its catalogues before modelling from scratch), `lihfolk-vfx` (slashes, impacts, projectiles, auras, AoE telegraphs, shields, beams, camera shake, hit-stop, VFX replication), `lihfolk-figma` (Figma frames to Roblox UI, design tokens, VFX texture sheets), `lihfolk-sfx` (layered, pooled combat and UI sounds synced to the same markers, sourced only from premium licensed sounds: Roblox-licensed Creator Store audio or a library the user owns), `lihfolk-systems`, `lihfolk-worldbuilding` (maps, levels, biomes, towns, dungeons, lobbies, obby areas, terrain: layout, composition and dressing with a placement and audit toolkit), `lihfolk-tutorial` (tutorials, onboarding and FTUE that keep first-time players), `roblox-blender-modeling`, `roblox-trend-game`, `roblox-player-sims` (simulated kid/teen playtesters that find boredom and confusion, then fix and re-run), `first-60-seconds-review` (scored review of a new player's first minute), `game-style-spec` (per-game style spec, owner decides), `agent-work-review` (review packet with diff, lint, tests and screenshots before approval), `session-learning` (verified lessons into `learning/`), `game-research` (consult reference games before design decisions, analyze new recordings, log which references shaped each feature), `roblox-system-builder`, `roblox-ui-builder`, `roblox-secure-remotes`, `roblox-datastore-safety`, `roblox-performance-audit`, `roblox-debugging`, `roblox-anti-exploit-review`, `roblox-monetization-compliance`, `roblox-asset-import`.
 
 ## Reference images
 
diff --git a/.claude/settings.json b/.claude/settings.json
new file mode 100644
index 0000000..8612828
--- /dev/null
+++ b/.claude/settings.json
@@ -0,0 +1,26 @@
+{
+  "hooks": {
+    "SessionStart": [
+      {
+        "hooks": [
+          {
+            "type": "command",
+            "command": "echo `# <#` >/dev/null; for p in python python3; do \"$p\" -c 1 >/dev/null 2>&1 && exec \"$p\" \"$CLAUDE_PROJECT_DIR/research/Roblox Game Research/_tools/research_index.py\" --hook session; done; exit 0 #> >$null; python \"$env:CLAUDE_PROJECT_DIR\\research\\Roblox Game Research\\_tools\\research_index.py\" --hook session; exit 0",
+            "timeout": 300
+          }
+        ]
+      }
+    ],
+    "UserPromptSubmit": [
+      {
+        "hooks": [
+          {
+            "type": "command",
+            "command": "echo `# <#` >/dev/null; for p in python python3; do \"$p\" -c 1 >/dev/null 2>&1 && exec \"$p\" \"$CLAUDE_PROJECT_DIR/research/Roblox Game Research/_tools/research_index.py\" --hook prompt; done; exit 0 #> >$null; python \"$env:CLAUDE_PROJECT_DIR\\research\\Roblox Game Research\\_tools\\research_index.py\" --hook prompt; exit 0",
+            "timeout": 15
+          }
+        ]
+      }
+    ]
+  }
+}
diff --git a/research/Roblox Game Research/Games/Fish It.md b/research/Roblox Game Research/Games/Fish It.md
new file mode 100644
index 0000000..a9f7e75
--- /dev/null
+++ b/research/Roblox Game Research/Games/Fish It.md	
@@ -0,0 +1,64 @@
+---
+type: game-research
+game: Fish It
+aliases: [Fish It!]
+genre: idle fishing, collection, RNG
+relevant_to: []
+created: 2026-11-21
+tags: [game-research]
+---
+
+# Fish It
+
+Part of [[Roblox Game Research]]. Write what YOU saw in the recordings and screenshots below; cite the file name (e.g. `2026-11-21 shop open.png`) or the frame sheet next to each observation, so the index can mark that file as analyzed. Label claims you didn't see yourself: **Verified** (official source), **Partially verified**, **Unverified**. Seven or more filled sections = "analyzed".
+
+## Snapshot
+<!-- Genre, players/visits with date and source, the one-line pitch, why it's successful. -->
+#10 by concurrent players on 2026-11-18 (~60K CCU; tracker numbers, Unverified) per `research/Top Roblox Games - Nov 2026.md`. Background: LihFolk [[Teardown - Fish It]] (secondary).
+
+## Core loop
+<!-- The repeating 10-60 s loop, as a chain: do X -> get Y -> spend on Z -> do X faster. -->
+
+## Mechanics
+<!-- Systems that make the loop work: randomness, scarcity, timers, collisions, social mechanics. -->
+
+## UI and UX
+<!-- HUD layout, buttons, shop, notifications, mobile layout. Cite screenshots. -->
+
+## Progression and rewards
+<!-- What grows, how fast, what unlocks when; reward cadence in the first hour. -->
+
+## Economy and monetization
+<!-- Currencies, sinks, prices, game passes, dev products, what is fair or pushy. -->
+
+## Social and multiplayer
+<!-- Trading, stealing, co-op, leaderboards, showing off. -->
+
+## First 60 seconds
+<!-- What a new player sees and does, second by second, from the recording. -->
+
+## Steal and avoid
+<!-- For our games: what to borrow (and how to make it ours) and what to avoid. -->
+
+## Open questions
+<!-- Things to capture next time (a screen you haven't recorded, a price you couldn't see). -->
+Capture next:
+- Seconds to the first catch on a fresh account.
+- How luck boosts are shown (numbers or vibes?).
+- Catch reveal animation and rarity feedback (frame by frame).
+- AFK rules and limits.
+
+<!-- research:auto:start -->
+## Evidence, background and influence (generated)
+
+*Rewritten by `_tools/research_index.py` on 2026-11-21. Edit above this block, never inside it.*
+
+### Evidence (0 files)
+No recordings or screenshots yet. Drop them in `_inbox/` (see [[Roblox Game Research]]).
+
+### Background in the vault
+- [[Teardown - Fish It]]
+
+### Influenced (from [[Reference Log]] and design docs)
+- Nothing yet.
+<!-- research:auto:end -->
diff --git a/research/Roblox Game Research/Games/Grow a Garden.md b/research/Roblox Game Research/Games/Grow a Garden.md
new file mode 100644
index 0000000..759d620
--- /dev/null
+++ b/research/Roblox Game Research/Games/Grow a Garden.md	
@@ -0,0 +1,65 @@
+---
+type: game-research
+game: Grow a Garden
+aliases: [GaG]
+genre: farming simulator, idle
+relevant_to: [grow-a-monster]
+created: 2026-11-21
+tags: [game-research]
+---
+
+# Grow a Garden
+
+Part of [[Roblox Game Research]]. Write what YOU saw in the recordings and screenshots below; cite the file name (e.g. `2026-11-21 shop open.png`) or the frame sheet next to each observation, so the index can mark that file as analyzed. Label claims you didn't see yourself: **Verified** (official source), **Partially verified**, **Unverified**. Seven or more filled sections = "analyzed".
+
+## Snapshot
+<!-- Genre, players/visits with date and source, the one-line pitch, why it's successful. -->
+Background only (no first-hand capture yet): LihFolk [[Case Study - Grow a Garden]] (secondary). Our use so far: Grow a Monster's art direction ("bright, cute, cozy, like Grow a Garden", `games/grow-a-monster/README.md`).
+
+## Core loop
+<!-- The repeating 10-60 s loop, as a chain: do X -> get Y -> spend on Z -> do X faster. -->
+
+## Mechanics
+<!-- Systems that make the loop work: randomness, scarcity, timers, collisions, social mechanics. -->
+
+## UI and UX
+<!-- HUD layout, buttons, shop, notifications, mobile layout. Cite screenshots. -->
+
+## Progression and rewards
+<!-- What grows, how fast, what unlocks when; reward cadence in the first hour. -->
+
+## Economy and monetization
+<!-- Currencies, sinks, prices, game passes, dev products, what is fair or pushy. -->
+
+## Social and multiplayer
+<!-- Trading, stealing, co-op, leaderboards, showing off. -->
+
+## First 60 seconds
+<!-- What a new player sees and does, second by second, from the recording. -->
+
+## Steal and avoid
+<!-- For our games: what to borrow (and how to make it ours) and what to avoid. -->
+
+## Open questions
+<!-- Things to capture next time (a screen you haven't recorded, a price you couldn't see). -->
+Capture next:
+- The first two minutes from a fresh account: buy, plant, collect, upgrade, with timestamps.
+- The shared shop restock timer and what players do when it hits zero.
+- How mutations and weather multipliers are shown on screen (screenshot each).
+- Offline growth: what a returning player sees on join.
+
+<!-- research:auto:start -->
+## Evidence, background and influence (generated)
+
+*Rewritten by `_tools/research_index.py` on 2026-11-21. Edit above this block, never inside it.*
+
+### Evidence (0 files)
+No recordings or screenshots yet. Drop them in `_inbox/` (see [[Roblox Game Research]]).
+
+### Background in the vault
+- [[Case Study - Grow a Garden]]
+
+### Influenced (from [[Reference Log]] and design docs)
+- 2026-11-18 · **grow-a-monster** · Core concept: throw food at your monster until it's huge: Mixes silly throwing (Throw Food For Animals, top 5) with grow/collect (Grow a Garden). *(backfilled: `research/Game Ideas.md`)* (built)
+- 2026-11-19 · **grow-a-monster** · v0.2 art direction: bright, cute-cartoony, cozy, rounded: Owner's brief: "like Grow a Garden", goofy edge. *(backfilled: `games/grow-a-monster/README.md`)* (built)
+<!-- research:auto:end -->
diff --git a/research/Roblox Game Research/Games/Steal An Egg.md b/research/Roblox Game Research/Games/Steal An Egg.md
new file mode 100644
index 0000000..5e8be13
--- /dev/null
+++ b/research/Roblox Game Research/Games/Steal An Egg.md	
@@ -0,0 +1,65 @@
+---
+type: game-research
+game: Steal An Egg
+aliases: []
+genre: steal / collect tycoon, pets
+relevant_to: [snatch-the-sun]
+created: 2026-11-21
+tags: [game-research]
+---
+
+# Steal An Egg
+
+Part of [[Roblox Game Research]]. Write what YOU saw in the recordings and screenshots below; cite the file name (e.g. `2026-11-21 shop open.png`) or the frame sheet next to each observation, so the index can mark that file as analyzed. Label claims you didn't see yourself: **Verified** (official source), **Partially verified**, **Unverified**. Seven or more filled sections = "analyzed".
+
+## Snapshot
+<!-- Genre, players/visits with date and source, the one-line pitch, why it's successful. -->
+#1 on Roblox by concurrent players on 2026-11-18 (~600K-1.2M CCU, 11.5B visits, launched 2026-07-25; tracker numbers, Unverified) per `research/Top Roblox Games - Nov 2026.md`. Background: LihFolk [[Teardown - Steal An Egg]] (secondary).
+
+## Core loop
+<!-- The repeating 10-60 s loop, as a chain: do X -> get Y -> spend on Z -> do X faster. -->
+
+## Mechanics
+<!-- Systems that make the loop work: randomness, scarcity, timers, collisions, social mechanics. -->
+
+## UI and UX
+<!-- HUD layout, buttons, shop, notifications, mobile layout. Cite screenshots. -->
+
+## Progression and rewards
+<!-- What grows, how fast, what unlocks when; reward cadence in the first hour. -->
+
+## Economy and monetization
+<!-- Currencies, sinks, prices, game passes, dev products, what is fair or pushy. -->
+
+## Social and multiplayer
+<!-- Trading, stealing, co-op, leaderboards, showing off. -->
+
+## First 60 seconds
+<!-- What a new player sees and does, second by second, from the recording. -->
+
+## Steal and avoid
+<!-- For our games: what to borrow (and how to make it ours) and what to avoid. -->
+
+## Open questions
+<!-- Things to capture next time (a screen you haven't recorded, a price you couldn't see). -->
+Capture next:
+- Grab and hatch an egg from a fresh account: seconds to first egg.
+- Speed upgrades and biome gates: what the HUD shows.
+- Theft counterplay: grace window, lock timer, steal-back route.
+- Egg odds display vs what hatches.
+
+<!-- research:auto:start -->
+## Evidence, background and influence (generated)
+
+*Rewritten by `_tools/research_index.py` on 2026-11-21. Edit above this block, never inside it.*
+
+### Evidence (0 files)
+No recordings or screenshots yet. Drop them in `_inbox/` (see [[Roblox Game Research]]).
+
+### Background in the vault
+- [[Teardown - Steal An Egg]]
+
+### Influenced (from [[Reference Log]] and design docs)
+- 2026-11-19 · **snatch-the-sun** · Name "Snatch the Sun", not "Steal the ___": The "Steal a ___" space is crowded; a trendy title gets clicks but gameplay keeps players. *(backfilled: `games/snatch-the-sun/DESIGN.md`)* (decided)
+- 2026-11-19 · **snatch-the-sun** · Grab-and-hold loop with steal counterplay: The design cites the steal/collect trend. Its counterplay rules (Sun Overload, 1 s no-catch after a throw) match the teardowns' "visible timer + counterplay" advice; that link is inferred, not stated in the doc. *(backfilled: `games/snatch-the-sun/DESIGN.md`, `research/Top Roblox Games - Nov 2026.md`)* (proposed)
+<!-- research:auto:end -->
diff --git a/research/Roblox Game Research/Games/Steal a Brainrot.md b/research/Roblox Game Research/Games/Steal a Brainrot.md
new file mode 100644
index 0000000..01db524
--- /dev/null
+++ b/research/Roblox Game Research/Games/Steal a Brainrot.md	
@@ -0,0 +1,65 @@
+---
+type: game-research
+game: Steal a Brainrot
+aliases: []
+genre: steal tycoon, idle, PvP
+relevant_to: [snatch-the-sun]
+created: 2026-11-21
+tags: [game-research]
+---
+
+# Steal a Brainrot
+
+Part of [[Roblox Game Research]]. Write what YOU saw in the recordings and screenshots below; cite the file name (e.g. `2026-11-21 shop open.png`) or the frame sheet next to each observation, so the index can mark that file as analyzed. Label claims you didn't see yourself: **Verified** (official source), **Partially verified**, **Unverified**. Seven or more filled sections = "analyzed".
+
+## Snapshot
+<!-- Genre, players/visits with date and source, the one-line pitch, why it's successful. -->
+Background only: LihFolk [[Case Study - Steal a Brainrot]] (secondary). `research/Top Roblox Games - Nov 2026.md` places it at the start of the "steal / collect" trend (2026-11-18, Unverified tracker numbers).
+
+## Core loop
+<!-- The repeating 10-60 s loop, as a chain: do X -> get Y -> spend on Z -> do X faster. -->
+
+## Mechanics
+<!-- Systems that make the loop work: randomness, scarcity, timers, collisions, social mechanics. -->
+
+## UI and UX
+<!-- HUD layout, buttons, shop, notifications, mobile layout. Cite screenshots. -->
+
+## Progression and rewards
+<!-- What grows, how fast, what unlocks when; reward cadence in the first hour. -->
+
+## Economy and monetization
+<!-- Currencies, sinks, prices, game passes, dev products, what is fair or pushy. -->
+
+## Social and multiplayer
+<!-- Trading, stealing, co-op, leaderboards, showing off. -->
+
+## First 60 seconds
+<!-- What a new player sees and does, second by second, from the recording. -->
+
+## Steal and avoid
+<!-- For our games: what to borrow (and how to make it ours) and what to avoid. -->
+
+## Open questions
+<!-- Things to capture next time (a screen you haven't recorded, a price you couldn't see). -->
+Capture next:
+- A steal from both sides: the thief's screen and the owner's alerts.
+- Base lock timer and counterplay (what the owner can do, how long).
+- The shared conveyor/shop: how rare items create races.
+- New-player protection in the first session.
+
+<!-- research:auto:start -->
+## Evidence, background and influence (generated)
+
+*Rewritten by `_tools/research_index.py` on 2026-11-21. Edit above this block, never inside it.*
+
+### Evidence (0 files)
+No recordings or screenshots yet. Drop them in `_inbox/` (see [[Roblox Game Research]]).
+
+### Background in the vault
+- [[Case Study - Steal a Brainrot]]
+
+### Influenced (from [[Reference Log]] and design docs)
+- 2026-11-19 · **snatch-the-sun** · Name "Snatch the Sun", not "Steal the ___": The "Steal a ___" space is crowded; a trendy title gets clicks but gameplay keeps players. *(backfilled: `games/snatch-the-sun/DESIGN.md`)* (decided)
+- 2026-11-19 · **snatch-the-sun** · Grab-and-hold loop with steal counterplay: The design cites the steal/collect trend. Its counterplay rules (Sun Overload, 1 s no-catch after a throw) match the teardowns' "visible timer + counterplay" advice; that link is inferred, not stated in the doc. *(backfilled: `games/snatch-the-sun/DESIGN.md`, `research/Top Roblox Games - Nov 2026.md`)* (proposed)
+<!-- research:auto:end -->
diff --git a/research/Roblox Game Research/Games/Throw Food For Animals.md b/research/Roblox Game Research/Games/Throw Food For Animals.md
new file mode 100644
index 0000000..9e14126
--- /dev/null
+++ b/research/Roblox Game Research/Games/Throw Food For Animals.md	
@@ -0,0 +1,64 @@
+---
+type: game-research
+game: Throw Food For Animals
+aliases: []
+genre: silly throwing simulator
+relevant_to: [grow-a-monster]
+created: 2026-11-21
+tags: [game-research]
+---
+
+# Throw Food For Animals
+
+Part of [[Roblox Game Research]]. Write what YOU saw in the recordings and screenshots below; cite the file name (e.g. `2026-11-21 shop open.png`) or the frame sheet next to each observation, so the index can mark that file as analyzed. Label claims you didn't see yourself: **Verified** (official source), **Partially verified**, **Unverified**. Seven or more filled sections = "analyzed".
+
+## Snapshot
+<!-- Genre, players/visits with date and source, the one-line pitch, why it's successful. -->
+#4 by concurrent players on 2026-11-18 (~200-470K CCU, ~330M visits, so new and growing fast; tracker numbers, Unverified) per `research/Top Roblox Games - Nov 2026.md`. No LihFolk teardown yet. Grow a Monster's core idea mixes its throwing with Grow a Garden's growth (`research/Game Ideas.md`).
+
+## Core loop
+<!-- The repeating 10-60 s loop, as a chain: do X -> get Y -> spend on Z -> do X faster. -->
+
+## Mechanics
+<!-- Systems that make the loop work: randomness, scarcity, timers, collisions, social mechanics. -->
+
+## UI and UX
+<!-- HUD layout, buttons, shop, notifications, mobile layout. Cite screenshots. -->
+
+## Progression and rewards
+<!-- What grows, how fast, what unlocks when; reward cadence in the first hour. -->
+
+## Economy and monetization
+<!-- Currencies, sinks, prices, game passes, dev products, what is fair or pushy. -->
+
+## Social and multiplayer
+<!-- Trading, stealing, co-op, leaderboards, showing off. -->
+
+## First 60 seconds
+<!-- What a new player sees and does, second by second, from the recording. -->
+
+## Steal and avoid
+<!-- For our games: what to borrow (and how to make it ours) and what to avoid. -->
+
```
