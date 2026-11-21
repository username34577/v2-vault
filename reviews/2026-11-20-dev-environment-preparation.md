# Review: Dev environment preparation

**Verdict: READY FOR APPROVAL** · 2026-11-20 · base `origin/main` · head `8c03f6a` (+ uncommitted)

## Changed files
(uncommitted only)

**agent instructions**
- `M` CLAUDE.md
- `??` skills/agent-work-review/SKILL.md
- `??` skills/first-60-seconds-review/SKILL.md
- `??` skills/game-style-spec/SKILL.md
- `M` skills/lihfolk/references/vault-map.md
- `??` skills/session-learning/SKILL.md

**game files**
- `??` games/_templates/FIRST-60-REVIEW.md
- `??` games/_templates/STYLE-SPEC.md

**notes**
- `??` LihFolk Vault V2/16 MCP and Agents/Agent Workflows - Review, Learning, Style and First 60 Seconds.md
- `M` LihFolk Vault V2/16 MCP and Agents/Automated Studio Test Runs (rbxtest).md
- `??` LihFolk Vault V2/16 MCP and Agents/Luau Toolchain and Quality Gate.md
- `??` LihFolk Vault V2/16 MCP and Agents/Third-Party Claude Plugins for Roblox - Audit (Nov 2026).md
- `M` LihFolk Vault V2/INDEX.md
- `M` LihFolk Vault V2/INDEX_SLIM.md
- `??` learning/Learning Workflow.md
- `??` learning/Lessons Log.md
- `??` learning/Recurring Mistakes.md
- `??` reviews/README.md

**other**
- `M` .gitignore

**tools / CI**
- `M` .github/workflows/game-checks.yml
- `??` dev/lint/README.md
- `??` dev/lint/baseline.json
- `??` dev/lint/lint.py
- `M` dev/rbxtest/README.md
- `M` dev/rbxtest/rbxtest.py
- `??` dev/rbxtest/test_rbxtest.py
- `??` dev/review/make_review.py
- `??` rokit.toml
- `??` selene.toml
- `??` stylua.toml

## Evidence
- Lint/type/format (`dev/lint/lint.py`, exit 0):
```
[lint] 2 projects · findings: luau-lsp 30, selene 12, stylua 26 · baseline 68 · new 0 · fixed 0
```
- rbxtest self-test: exit 0

## Screenshots
- none

## High-stakes areas touched (read the vault notes' Common mistakes + Checklist)
- none detected

## Owner decision
- [ ] Approve  - [ ] Ask for changes  - [ ] Reject
- Notes:

## Diff (first 400 lines)
```diff
diff --git a/.github/workflows/game-checks.yml b/.github/workflows/game-checks.yml
index 1ce136c..a2dd23b 100644
--- a/.github/workflows/game-checks.yml
+++ b/.github/workflows/game-checks.yml
@@ -6,6 +6,9 @@ on:
       - "games/**"
       - "dev/**"
       - ".github/workflows/game-checks.yml"
+      - "selene.toml"
+      - "stylua.toml"
+      - "rokit.toml"
   pull_request:
     paths:
       - "games/**"
@@ -24,6 +27,8 @@ jobs:
           unzip -q luau.zip -d "$HOME/luau"
       - name: rbxtest helper self-check
         run: python3 dev/rbxtest/rbxtest.py sync-check games/vfx-lab/default.project.json > /dev/null
+      - name: rbxtest report handling (exit codes, regressions, invalid reports)
+        run: python3 dev/rbxtest/test_rbxtest.py
       - name: Every game script compiles
         run: |
           status=0
@@ -34,3 +39,22 @@ jobs:
             fi
           done < <(find games dev -name '*.luau' -o -name '*.lua' | sort)
           exit $status
+
+  lint:
+    # selene + luau-lsp (Roblox types) + StyLua through dev/lint/lint.py; fails only on findings
+    # that are not in dev/lint/baseline.json. Versions match rokit.toml.
+    runs-on: ubuntu-latest
+    steps:
+      - uses: actions/checkout@v4
+      - name: Install pinned Luau tools
+        run: |
+          mkdir -p "$HOME/bin" && cd "$HOME/bin"
+          get() { curl -sSfL -o t.zip "$1" && unzip -oq t.zip && rm t.zip; }
+          get https://github.com/rojo-rbx/rojo/releases/download/v7.7.1/rojo-7.7.1-linux-x86_64.zip
+          get https://github.com/Kampfkarren/selene/releases/download/0.32.0/selene-0.32.0-linux.zip
+          get https://github.com/JohnnyMorganz/StyLua/releases/download/v2.6.0/stylua-linux-x86_64.zip
+          get https://github.com/JohnnyMorganz/luau-lsp/releases/download/1.70.1/luau-lsp-linux-x86_64.zip
+          chmod +x rojo selene stylua luau-lsp
+          echo "$HOME/bin" >> "$GITHUB_PATH"
+      - name: No new lint, type or format findings
+        run: python3 dev/lint/lint.py --report lint-report.json
diff --git a/.gitignore b/.gitignore
index f5825af..bf8de71 100644
--- a/.gitignore
+++ b/.gitignore
@@ -24,3 +24,7 @@ LihFolk Vault V2/.smart-env/
 # rbxtest temp files
 .rbxtest-sync.luau
 .rbxtest-result.json
+
+# lint tool downloads (luau-lsp Roblox definitions)
+dev/lint/.cache/
+sourcemap.json
diff --git a/CLAUDE.md b/CLAUDE.md
index 4af2ae9..5c17ccd 100644
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -15,3 +15,11 @@ Follow AGENTS.md for Roblox work in this repo.
 - Run a game's test suites in the open Studio with `/rbx-test <game folder>` (e.g. `/rbx-test vfx-lab`). It checks Rojo sync, runs each suite through StudioTestService (solo or multi-client, no clicking), and saves JSON reports to `test-reports/<game>/` with a comparison against the previous run.
 - How it works, adding a project, troubleshooting: `dev/rbxtest/README.md`.
 - Prefer the Studio MCP tools over screenshots and mouse automation. Never save/publish the place or edit Rojo-managed scripts through MCP.
+
+## Quality gate and work habits
+
+- Before any change goes to the owner: `python dev/lint/lint.py` must show `new 0` (selene, luau-lsp, StyLua; setup in `dev/lint/README.md`), and major changes get a review packet: `python dev/review/make_review.py --title "..."` (skill `agent-work-review`).
+- New Luau files are formatted with `stylua`. Don't reformat existing files unless the owner asks.
+- End of a work session: log verified lessons with the `session-learning` skill (`learning/`).
+- New game: style spec first (`game-style-spec`); before ads or launch: `first-60-seconds-review`.
+
diff --git a/LihFolk Vault V2/16 MCP and Agents/Automated Studio Test Runs (rbxtest).md b/LihFolk Vault V2/16 MCP and Agents/Automated Studio Test Runs (rbxtest).md
index 4d8922e..11493ce 100644
--- a/LihFolk Vault V2/16 MCP and Agents/Automated Studio Test Runs (rbxtest).md	
+++ b/LihFolk Vault V2/16 MCP and Agents/Automated Studio Test Runs (rbxtest).md	
@@ -10,7 +10,7 @@ tags: [mcp, studio, testing, agents, tooling, type/guide, area/ai, area/testing,
 > - Both match the earlier manual results. Reports: `test-reports/vfx-lab/20261119-142030-local.json` and...
 > - Windows-only setup tested so far; needs Studio open with the MCP server on and Rojo connected.
 >
-> Cost: TL;DR ~130 tok · whole note ~1.3k tok. Read more: ## 1. What the Studio MCP can and can't do (measured) · ## 3. Verified results (2026-11-19, VFX Lab, commit 1b1ee63)
+> Cost: TL;DR ~130 tok · whole note ~1.5k tok. Read more: ## 1. What the Studio MCP can and can't do (measured) · ## 3. Verified results (2026-11-19, VFX Lab, commit 1b1ee63)
 <!-- tldr:end -->
 
 rbxtest lets Claude Code run a game's test suites in the open Roblox Studio with no clicking. It checks that Rojo is in sync, starts each suite through StudioTestService (solo or multi-client), captures the exact results as JSON, saves a report per run and compares it with the previous one. Code and full reference: `dev/rbxtest/README.md` in the repo. Claude Code command: `/rbx-test <game folder>`.
@@ -73,6 +73,10 @@ Both match the earlier manual results. Reports: `test-reports/vfx-lab/20261119-1
 
 The manual run had a 60 FPS baseline. Here even the no-effects baseline was 15 FPS, so the effects are not the cause. The likely cause is that Studio was behind other windows during the run. That hasn't been tested yet. The relative check still passes, but **absolute FPS from an unattended run is not meaningful**, and none of this says anything about phones.
 
+### Report handling, tested without Studio (2026-11-20)
+
+`python dev/rbxtest/test_rbxtest.py` (9 cases, also in CI) checks the part that decides pass or fail. It found and fixed two gaps: a check that passed last run and **disappeared** now counts as a regression, and a **completed run with no results** now fails. Clean run exit 0; FAIL, error, timeout, unknown suite, PASS→FAIL and vanished checks exit 1; malformed reports exit 2 and nothing is saved. The Studio side has not been re-run since this change; the next `/rbx-test vfx-lab` on the laptop confirms it end to end.
+
 ## 4. Known limits
 
 - Windows-only setup tested so far; needs Studio open with the MCP server on and Rojo connected.
diff --git a/LihFolk Vault V2/INDEX.md b/LihFolk Vault V2/INDEX.md
index e1ca970..4fb942a 100644
--- a/LihFolk Vault V2/INDEX.md	
+++ b/LihFolk Vault V2/INDEX.md	
@@ -541,10 +541,12 @@ topic or tag, then open only the notes you need. Generated by `_tools/build_inde
 - AI-Ready Project Boilerplate - Repo Layout Agents Navigate Well | 16 MCP and Agents/AI-Ready Project Boilerplate - Repo Layout Agents Navigate Well.md | agents, ai, workflow, rojo, repo-layout, documentation, claude-code | ~2.3k tok | An agent's speed and accuracy on a Roblox project depend less on the model than on the repo.
 - Agent Handoff Notes - Project State and Resume Templates | 16 MCP and Agents/Agent Handoff Notes - Project State and Resume Templates.md | agents, ai, workflow, handoff, documentation, claude-code | ~2.1k tok | AI agents forget everything between sessions, and long sessions get compacted.
 - Agent Review Loops and Guardrails in Practice | 16 MCP and Agents/Agent Review Loops and Guardrails in Practice.md | agents, mcp, guardrails, review, hooks, permissions, verification, claude-code | ~6.3k tok | Safety Rules for AI Agents in Studio lists the rules an agent working in Roblox Studio should follow: Edit...
-- Automated Studio Test Runs (rbxtest) | 16 MCP and Agents/Automated Studio Test Runs (rbxtest).md | mcp, studio, testing, agents, tooling | ~1.3k tok | rbxtest lets Claude Code run a game's test suites in the open Roblox Studio with no clicking.
+- Agent Workflows - Review, Learning, Style and First 60 Seconds | 16 MCP and Agents/Agent Workflows - Review, Learning, Style and First 60 Seconds.md | agents, workflow, review, learning, onboarding, style | ~880 tok | Four repeatable procedures that make Claude's work checkable and keep what it learns.
+- Automated Studio Test Runs (rbxtest) | 16 MCP and Agents/Automated Studio Test Runs (rbxtest).md | mcp, studio, testing, agents, tooling | ~1.5k tok | rbxtest lets Claude Code run a game's test suites in the open Roblox Studio with no clicking.
 - Blender MCP | 16 MCP and Agents/Blender MCP.md | mcp, blender, ai, agents, modeling, pipeline | ~4.0k tok | A Blender MCP server lets an AI agent inspect and change a running Blender: list collections and objects...
 - Built-In Studio MCP vs Community MCP Servers - Migration Guide | 16 MCP and Agents/Built-In Studio MCP vs Community MCP Servers - Migration Guide.md | mcp, studio, agents, migration, tooling | ~2.1k tok | Between 2025 and 2026 most Roblox AI setups ran on one of two kinds of bridge: Roblox's open-source...
 - Case Study - Building a Game with AI Agents | 16 MCP and Agents/Case Study - Building a Game with AI Agents.md | case-study, mcp, agents, production, workflow | ~3.4k tok | This is the story of the reference project used throughout this vault: a live action game on Roblox built...
+- Luau Toolchain and Quality Gate | 16 MCP and Agents/Luau Toolchain and Quality Gate.md | tooling, luau, lint, type-checking, selene, stylua, luau-lsp, rojo, ci | ~1.0k tok | The repo's Luau tools and the gate that every change passes: selene (lint), luau-lsp (type checking with...
 - MCP Workflows for Building Worlds | 16 MCP and Agents/MCP Workflows for Building Worlds.md | mcp, agents, world-building, terrain, workflow | ~3.6k tok | An AI agent connected to Studio through MCP can place thousands of props, sculpt terrain, dress zones and...
 - MCP Workflows for Scripting and Debugging | 16 MCP and Agents/MCP Workflows for Scripting and Debugging.md | mcp, agents, scripting, debugging, luau, workflow | ~4.7k tok | Writing Luau is the part of game development AI agents do best, and the part where an agent connected to...
 - Multiple Agents in One Studio | 16 MCP and Agents/Multiple Agents in One Studio.md | mcp, agents, coordination, studio, workflow, collaboration | ~3.2k tok | One agent working in Studio is a power tool.
@@ -552,6 +554,7 @@ topic or tag, then open only the notes you need. Generated by `_tools/build_inde
 - Safety Rules for AI Agents in Studio | 16 MCP and Agents/Safety Rules for AI Agents in Studio.md | mcp, agents, safety, rules, studio, workflow | ~3.5k tok | An AI agent with the Roblox Studio MCP Server has the same power over your place as you do at the command...
 - Setting Up MCP Clients | 16 MCP and Agents/Setting Up MCP Clients.md | mcp, setup, claude, cursor, vscode, agents | ~3.6k tok | An MCP server does nothing until a client (host application) is configured to start or connect to it.
 - Studio Plugins and Local HTTP Bridges | 16 MCP and Agents/Studio Plugins and Local HTTP Bridges.md | plugins, http, tooling, studio, bridges, mcp | ~4.6k tok | Long before MCP, developers connected Roblox Studio to the outside world with a simple trick: Studio can...
+- Third-Party Claude Plugins for Roblox - Audit (Nov 2026) | 16 MCP and Agents/Third-Party Claude Plugins for Roblox - Audit (Nov 2026).md | agents, plugins, tools, security, audit, mcp | ~1.1k tok | Tools recommended in TikTok videos (see research/TikTok Notes/), inspected by reading their source on...
 - What Is MCP | 16 MCP and Agents/What Is MCP.md | mcp, ai, agents, protocol, tooling | ~4.8k tok | The Model Context Protocol (MCP) is an open protocol that lets an AI application (Claude Desktop, Claude...
 - Writing Your Own MCP Server | 16 MCP and Agents/Writing Your Own MCP Server.md | mcp, python, typescript, plugins, tooling, agents | ~5.7k tok | The official Roblox Studio MCP Server gives agents general tools: run Luau, read scripts, capture the screen.
 
diff --git a/LihFolk Vault V2/INDEX_SLIM.md b/LihFolk Vault V2/INDEX_SLIM.md
index 15215a9..e70ca15 100644
--- a/LihFolk Vault V2/INDEX_SLIM.md	
+++ b/LihFolk Vault V2/INDEX_SLIM.md	
@@ -540,10 +540,12 @@ One line per note: `title | path | tags | ~whole-note tokens`. Grep it for an AP
 - AI-Ready Project Boilerplate - Repo Layout Agents Navigate Well | 16 MCP and Agents/AI-Ready Project Boilerplate - Repo Layout Agents Navigate Well.md | agents, ai, workflow, rojo, repo-layout, documentation, claude-code | ~2.3k tok
 - Agent Handoff Notes - Project State and Resume Templates | 16 MCP and Agents/Agent Handoff Notes - Project State and Resume Templates.md | agents, ai, workflow, handoff, documentation, claude-code | ~2.1k tok
 - Agent Review Loops and Guardrails in Practice | 16 MCP and Agents/Agent Review Loops and Guardrails in Practice.md | agents, mcp, guardrails, review, hooks, permissions, verification, claude-code | ~6.3k tok
-- Automated Studio Test Runs (rbxtest) | 16 MCP and Agents/Automated Studio Test Runs (rbxtest).md | mcp, studio, testing, agents, tooling | ~1.3k tok
+- Agent Workflows - Review, Learning, Style and First 60 Seconds | 16 MCP and Agents/Agent Workflows - Review, Learning, Style and First 60 Seconds.md | agents, workflow, review, learning, onboarding, style | ~880 tok
+- Automated Studio Test Runs (rbxtest) | 16 MCP and Agents/Automated Studio Test Runs (rbxtest).md | mcp, studio, testing, agents, tooling | ~1.5k tok
 - Blender MCP | 16 MCP and Agents/Blender MCP.md | mcp, blender, ai, agents, modeling, pipeline | ~4.0k tok
 - Built-In Studio MCP vs Community MCP Servers - Migration Guide | 16 MCP and Agents/Built-In Studio MCP vs Community MCP Servers - Migration Guide.md | mcp, studio, agents, migration, tooling | ~2.1k tok
 - Case Study - Building a Game with AI Agents | 16 MCP and Agents/Case Study - Building a Game with AI Agents.md | case-study, mcp, agents, production, workflow | ~3.4k tok
+- Luau Toolchain and Quality Gate | 16 MCP and Agents/Luau Toolchain and Quality Gate.md | tooling, luau, lint, type-checking, selene, stylua, luau-lsp, rojo, ci | ~1.0k tok
 - MCP Workflows for Building Worlds | 16 MCP and Agents/MCP Workflows for Building Worlds.md | mcp, agents, world-building, terrain, workflow | ~3.6k tok
 - MCP Workflows for Scripting and Debugging | 16 MCP and Agents/MCP Workflows for Scripting and Debugging.md | mcp, agents, scripting, debugging, luau, workflow | ~4.7k tok
 - Multiple Agents in One Studio | 16 MCP and Agents/Multiple Agents in One Studio.md | mcp, agents, coordination, studio, workflow, collaboration | ~3.2k tok
@@ -551,6 +553,7 @@ One line per note: `title | path | tags | ~whole-note tokens`. Grep it for an AP
 - Safety Rules for AI Agents in Studio | 16 MCP and Agents/Safety Rules for AI Agents in Studio.md | mcp, agents, safety, rules, studio, workflow | ~3.5k tok
 - Setting Up MCP Clients | 16 MCP and Agents/Setting Up MCP Clients.md | mcp, setup, claude, cursor, vscode, agents | ~3.6k tok
 - Studio Plugins and Local HTTP Bridges | 16 MCP and Agents/Studio Plugins and Local HTTP Bridges.md | plugins, http, tooling, studio, bridges, mcp | ~4.6k tok
+- Third-Party Claude Plugins for Roblox - Audit (Nov 2026) | 16 MCP and Agents/Third-Party Claude Plugins for Roblox - Audit (Nov 2026).md | agents, plugins, tools, security, audit, mcp | ~1.1k tok
 - What Is MCP | 16 MCP and Agents/What Is MCP.md | mcp, ai, agents, protocol, tooling | ~4.8k tok
 - Writing Your Own MCP Server | 16 MCP and Agents/Writing Your Own MCP Server.md | mcp, python, typescript, plugins, tooling, agents | ~5.7k tok
 
diff --git a/dev/rbxtest/README.md b/dev/rbxtest/README.md
index 4ca8656..2c3a579 100644
--- a/dev/rbxtest/README.md
+++ b/dev/rbxtest/README.md
@@ -31,7 +31,9 @@ No network listener, no HttpService, no plugin to install. Everything goes throu
 
 Report schema 1: `{schema:1, suite, status: completed|error|timeout|unknown_suite, results:[...], error?, meta:{place, placeId, startedAt, durationS, players, args, savedAt, commit}}`.
 
-`save` exit codes: **0** completed with no FAIL and no regression · **1** FAIL, run error/timeout, or a check that went PASS→FAIL · **2** the report itself is invalid.
+`save` exit codes: **0** completed with at least one result, no FAIL and no regression · **1** FAIL, run error/timeout/unknown suite, a check that went PASS→FAIL, a previously passing check that disappeared, or a completed run with no results · **2** the report itself is invalid (nothing is saved).
+
+Self-test (no Studio needed): `python dev/rbxtest/test_rbxtest.py` runs 9 cases covering every exit path; it also runs in CI.
 
 ## The spawn snippet (step 4a)
 
diff --git a/dev/rbxtest/rbxtest.py b/dev/rbxtest/rbxtest.py
index 80a5af1..caa8afc 100644
--- a/dev/rbxtest/rbxtest.py
+++ b/dev/rbxtest/rbxtest.py
@@ -181,7 +181,9 @@ def compare(old, new):
             lines.append(f"- NEW check: {k} ({n[k]['status']})")
     for k in o:
         if k not in n:
-            lines.append(f"- MISSING check (was {o[k]['status']}): {k}")
+            # A check that used to PASS and silently disappeared counts as a regression.
+            tag = "**REGRESSION** " if o[k]["status"] == "PASS" else ""
+            lines.append(f"- {tag}MISSING check (was {o[k]['status']}): {k}")
     perf = []
     for k in n:
         if k in o and n[k]["test"] == "performance":
@@ -193,7 +195,7 @@ def compare(old, new):
     out += lines or ["- No status changes."]
     if perf:
         out += ["", "Performance numbers (previous -> now):"] + perf
-    return "\n".join(out), any(l.startswith("- **REGRESSION**") for l in lines)
+    return "\n".join(out), any("**REGRESSION**" in l for l in lines)
 
 
 def summary(report):
@@ -263,7 +265,10 @@ def cmd_save(a):
         text += "\n\n" + cmp_text
     print(text)
     print(f"\nSaved {out_path}")
-    ok = report["status"] == "completed" and counts(report)["FAIL"] == 0 and not regression
+    if report["status"] == "completed" and not report["results"]:
+        print("\nRun completed with no results: treated as a failure (a suite must report at least one check).")
+    ok = (report["status"] == "completed" and bool(report["results"]) and counts(report)["FAIL"] == 0
+          and not regression)
     return 0 if ok else 1
 
 
diff --git a/skills/lihfolk/references/vault-map.md b/skills/lihfolk/references/vault-map.md
index 421fc22..327f2dc 100644
--- a/skills/lihfolk/references/vault-map.md
+++ b/skills/lihfolk/references/vault-map.md
@@ -31,7 +31,7 @@ Loaded on demand by the `lihfolk` router. `<VAULT>` is the absolute vault path t
 
 ## Specialist skills in this plugin
 
-Prefer these when the task matches: `quality-score` (every generated asset or system must score at least 8.5/10), `council-method` (objective verdicts; the user-facing command is `/lihfolk:council`), `lihfolk-ui` (house menu style), `lihfolk-assets` (original models, materials, skies, animations and VFX from the local asset pack: search its catalogues before modelling from scratch), `lihfolk-vfx` (slashes, impacts, projectiles, auras, AoE telegraphs, shields, beams, camera shake, hit-stop, VFX replication), `lihfolk-figma` (Figma frames to Roblox UI, design tokens, VFX texture sheets), `lihfolk-sfx` (layered, pooled combat and UI sounds synced to the same markers, sourced only from premium licensed sounds: Roblox-licensed Creator Store audio or a library the user owns), `lihfolk-systems`, `lihfolk-worldbuilding` (maps, levels, biomes, towns, dungeons, lobbies, obby areas, terrain: layout, composition and dressing with a placement and audit toolkit), `lihfolk-tutorial` (tutorials, onboarding and FTUE that keep first-time players), `roblox-blender-modeling`, `roblox-trend-game`, `roblox-player-sims` (simulated kid/teen playtesters that find boredom and confusion, then fix and re-run), `roblox-system-builder`, `roblox-ui-builder`, `roblox-secure-remotes`, `roblox-datastore-safety`, `roblox-performance-audit`, `roblox-debugging`, `roblox-anti-exploit-review`, `roblox-monetization-compliance`, `roblox-asset-import`.
+Prefer these when the task matches: `quality-score` (every generated asset or system must score at least 8.5/10), `council-method` (objective verdicts; the user-facing command is `/lihfolk:council`), `lihfolk-ui` (house menu style), `lihfolk-assets` (original models, materials, skies, animations and VFX from the local asset pack: search its catalogues before modelling from scratch), `lihfolk-vfx` (slashes, impacts, projectiles, auras, AoE telegraphs, shields, beams, camera shake, hit-stop, VFX replication), `lihfolk-figma` (Figma frames to Roblox UI, design tokens, VFX texture sheets), `lihfolk-sfx` (layered, pooled combat and UI sounds synced to the same markers, sourced only from premium licensed sounds: Roblox-licensed Creator Store audio or a library the user owns), `lihfolk-systems`, `lihfolk-worldbuilding` (maps, levels, biomes, towns, dungeons, lobbies, obby areas, terrain: layout, composition and dressing with a placement and audit toolkit), `lihfolk-tutorial` (tutorials, onboarding and FTUE that keep first-time players), `roblox-blender-modeling`, `roblox-trend-game`, `roblox-player-sims` (simulated kid/teen playtesters that find boredom and confusion, then fix and re-run), `first-60-seconds-review` (scored review of a new player's first minute), `game-style-spec` (per-game style spec, owner decides), `agent-work-review` (review packet with diff, lint, tests and screenshots before approval), `session-learning` (verified lessons into `learning/`), `roblox-system-builder`, `roblox-ui-builder`, `roblox-secure-remotes`, `roblox-datastore-safety`, `roblox-performance-audit`, `roblox-debugging`, `roblox-anti-exploit-review`, `roblox-monetization-compliance`, `roblox-asset-import`.
 
 ## Reference images
 
diff --git a/LihFolk Vault V2/16 MCP and Agents/Agent Workflows - Review, Learning, Style and First 60 Seconds.md b/LihFolk Vault V2/16 MCP and Agents/Agent Workflows - Review, Learning, Style and First 60 Seconds.md
new file mode 100644
index 0000000..adb35a1
--- /dev/null
+++ b/LihFolk Vault V2/16 MCP and Agents/Agent Workflows - Review, Learning, Style and First 60 Seconds.md	
@@ -0,0 +1,65 @@
+---
+tags: [agents, workflow, review, learning, onboarding, style, type/guide, area/ai, level/intermediate]
+---
+# Agent Workflows - Review, Learning, Style and First 60 Seconds
+
+<!-- tldr:start -->
+> [!tldr] TL;DR
+> - Avoid: Approving from a summary instead of the packet -> Read the verdict and blockers; open the diff for anything high-stakes
+> - Avoid: Logging lessons without evidence -> Every entry has a command, report, commit or doc link; Unverified...
+> - Avoid: Writing a style spec with vague words -> Hex colours, word counts, timings, contrast ratios
+> - Major change → packet in `reviews/` with verdict READY FOR APPROVAL (or explained exceptions).
+> - End of session → lessons logged with evidence; repeats counted.
+> - Before ads or launch → first 60 seconds review ≥ 16/20 with no zeros.
+>
+> Cost: TL;DR ~190 tok · whole note ~880 tok. Read more: ## 1. The four workflows · ## 2. Review verdicts · ## Common mistakes · ## Checklist
+<!-- tldr:end -->
+
+Four repeatable procedures that make Claude's work checkable and keep what it learns. Each is a skill in `skills/` (any agent can follow it as plain instructions) with a template or script. Set up 2026-11-20.
+
+---
+
+## 1. The four workflows
+
+| Workflow | Skill | Files | Output |
+|---|---|---|---|
+| Agent work review | `agent-work-review` | `dev/review/make_review.py`, `reviews/` | A packet per change: diff, compile, lint (new findings only), Studio test freshness, screenshots, high-stakes flags, verdict |
+| Session learning | `session-learning` | `learning/Lessons Log.md`, `learning/Recurring Mistakes.md`, `learning/Learning Workflow.md` | Verified lessons with evidence, promoted into SYMPTOMS, lint, hooks or rules |
+| First 60 seconds review | `first-60-seconds-review` | `games/_templates/FIRST-60-REVIEW.md` | A scored report (/20, bar 16) of a new player's first minute, from code + playtest captures + personas |
+| Game style spec | `game-style-spec` | `games/_templates/STYLE-SPEC.md` | A per-game spec with testable numbers (hex colours, word counts, timings), locked by the owner |
+
+## 2. Review verdicts
+
+- **READY FOR APPROVAL**: compiles, no new lint/type/format findings, fresh passing Studio tests for touched games with suites, screenshots for visual changes.
+- **NEEDS WORK**: a blocker (compile error, new finding, failed self-test, possible secret).
+- **NEEDS EVIDENCE**: proof is missing (stale or missing test run, missing screenshots, tools not installed).
+
+High-stakes areas found in changed Luau (DataStore, receipts, paid random items, remotes, HTTP) are listed so the matching vault notes' *Common mistakes* and *Checklist* get read (AGENTS.md rule).
+
+## 3. Verified (2026-11-20)
+
+- Review script on this change set: READY FOR APPROVAL (notes, tools and skills only).
+- Probe: a DataStore write plus an unused local added to a game script → NEEDS WORK, "player data / DataStore" flagged, both new findings listed; reverted.
+- Probe: code appended after a module's final `return` → compile failure reported as a blocker.
+- High-stakes flags read only changed Luau, so documentation that mentions DataStores doesn't trigger them.
+
+## Common mistakes
+
+| Mistake | Why it hurts | Fix |
+|---|---|---|
+| Approving from a summary instead of the packet | Claude's confidence isn't evidence | Read the verdict and blockers; open the diff for anything high-stakes |
+| Logging lessons without evidence | Wrong lessons get promoted and repeated | Every entry has a command, report, commit or doc link; Unverified ones are never promoted |
+| Writing a style spec with vague words | Nothing can be checked against "clean" or "cool" | Hex colours, word counts, timings, contrast ratios |
+| Reviewing onboarding from code only and not saying so | Misses what players actually see | Mark the report **code-only** at the top |
+
+## Checklist
+
+- [ ] Major change → packet in `reviews/` with verdict READY FOR APPROVAL (or explained exceptions).
+- [ ] End of session → lessons logged with evidence; repeats counted.
+- [ ] Before ads or launch → first 60 seconds review ≥ 16/20 with no zeros.
+- [ ] Before making assets for a game → its style spec is Locked.
+
+## Related
+- [[Luau Toolchain and Quality Gate]]
+- [[Automated Studio Test Runs (rbxtest)]]
+- [[Agent Review Loops and Guardrails in Practice]]
diff --git a/LihFolk Vault V2/16 MCP and Agents/Luau Toolchain and Quality Gate.md b/LihFolk Vault V2/16 MCP and Agents/Luau Toolchain and Quality Gate.md
new file mode 100644
index 0000000..d0ac0e6
--- /dev/null
+++ b/LihFolk Vault V2/16 MCP and Agents/Luau Toolchain and Quality Gate.md	
@@ -0,0 +1,72 @@
+---
+tags: [tooling, luau, lint, type-checking, selene, stylua, luau-lsp, rojo, ci, type/guide, area/ai, area/testing, level/intermediate]
+---
+# Luau Toolchain and Quality Gate
+
+<!-- tldr:start -->
+> [!tldr] TL;DR
+> - Avoid: Running `luau-lsp analyze` from the repo root -> Run from `games/<game>/` (lint.py does)
+> - Avoid: Reformatting old files with StyLua in a feature change -> Format only new files; reformat old ones in a separate, approved...
+> - Avoid: Updating the baseline to make CI green -> Read the new findings first; only accept ones that are noise, and...
+> - `python dev/lint/lint.py` shows `new 0` before a change goes to review.
+> - New Luau files are StyLua-formatted.
+> - Baseline changes are explained in the review packet.
+>
+> Cost: TL;DR ~170 tok · whole note ~1.0k tok. Read more: ## 1. What is installed and pinned · ## 3. Verified results (2026-11-20) · ## Common mistakes · ## Checklist
+<!-- tldr:end -->
+
+The repo's Luau tools and the gate that every change passes: **selene** (lint), **luau-lsp** (type checking with real Roblox types), **StyLua** (format), **luau-compile** (compiles) and **Rojo** (sourcemaps). Code and commands: `dev/lint/README.md`. Facts are **Measured** on 2026-11-20 unless labelled otherwise.
+
+---
+
+## 1. What is installed and pinned
+
+| Tool | Version | Pinned in | Role |
+|---|---|---|---|
+| Rojo | 7.7.1 | `rokit.toml` | `rojo sourcemap` for type checking (serving Studio still uses `tools/rojo.exe`) |
+| selene | 0.32.0 | `rokit.toml`, `selene.toml` (`std = "roblox"`) | Lint: unused, shadowing, deprecated APIs |
+| StyLua | 2.6.0 | `rokit.toml`, `stylua.toml` (tabs, 120 columns, double quotes) | Format new files |
+| luau-lsp | 1.70.1 | `rokit.toml` | `luau-lsp analyze` with Roblox definitions and a Rojo sourcemap |
+| Luau | 0.748 (workspace), 0.744 (CI) | CI `compile` job | `luau-compile` |
+
+All are free, open source, single binaries from each project's official GitHub release, installable per user with Rokit (no admin rights).
+
+## 2. The gate
+
+`python dev/lint/lint.py` runs the three checkers over every game and the rbxtest harness and fails only on **new** findings: findings already present are recorded in `dev/lint/baseline.json` (keyed by tool, file, rule and message, not line numbers). The CI job `lint` in `.github/workflows/game-checks.yml` runs it on every push that touches games, dev tools or the tool configs.
+
+Exit codes: 0 no new findings, 1 new findings listed, 2 a tool is missing or crashed.
+
+## 3. Verified results (2026-11-20)
+
+- 39 Luau files compile.
+- Baseline: **68 findings**: luau-lsp 30, selene 12, StyLua 26 unformatted files.
+- Probe file with an unused local and a `number` returned as `string`: 3 new findings, exit 1. Removed: exit 0. Tools missing: exit 2. A file with a syntax error: reported by all three tools as new findings.
+- Worth fixing later (not changed now, gameplay is out of scope): a deprecated `KeyCode` enum item used in grow-a-monster's client (both selene and luau-lsp flag it), a possibly-nil string passed to a `number | string` parameter in VFX Lab's lab client, an unused `remote` in the test harness.
+- Most luau-lsp findings are "Key not found in table" on tables filled after creation; they're type noise until the tables get type annotations.
+
+## 4. Where it can't run (measured)
+
+- In the cloud workspace, selene's built-in Roblox library download fails (its TLS client rejects the workspace proxy). Workaround used: generate the library once from a downloaded API dump with a patched local build. On the laptop and GitHub Actions it downloads normally.
+- `rokit install` needs the GitHub API, which the cloud workspace can't reach. Not yet run on the laptop.
+- The CI `lint` job has not run yet; it runs on the next push.
+
+## Common mistakes
+
+| Mistake | Why it hurts | Fix |
+|---|---|---|
+| Running `luau-lsp analyze` from the repo root | Every cross-script `require` is "Unknown require" because the sourcemap is relative to the project folder | Run from `games/<game>/` (lint.py does) |
+| Reformatting old files with StyLua in a feature change | Huge diffs that hide the real change and touch gameplay | Format only new files; reformat old ones in a separate, approved change |
+| Updating the baseline to make CI green | Hides real new bugs | Read the new findings first; only accept ones that are noise, and say why in the review packet |
+| Using a different Rojo version for serving than the Studio plugin expects | Sync breaks | Keep serving with the version that matches the plugin; the pinned Rojo is for sourcemaps |
+
+## Checklist
+
+- [ ] `python dev/lint/lint.py` shows `new 0` before a change goes to review.
+- [ ] New Luau files are StyLua-formatted.
+- [ ] Baseline changes are explained in the review packet.
+- [ ] On a new machine: `rokit install`, then check the four versions.
+
+## Related
+- [[Automated Studio Test Runs (rbxtest)]]
+- [[Agent Workflows - Review, Learning, Style and First 60 Seconds]]
diff --git a/LihFolk Vault V2/16 MCP and Agents/Third-Party Claude Plugins for Roblox - Audit (Nov 2026).md b/LihFolk Vault V2/16 MCP and Agents/Third-Party Claude Plugins for Roblox - Audit (Nov 2026).md
new file mode 100644
index 0000000..213b9cb
--- /dev/null
+++ b/LihFolk Vault V2/16 MCP and Agents/Third-Party Claude Plugins for Roblox - Audit (Nov 2026).md	
@@ -0,0 +1,60 @@
+---
+tags: [agents, plugins, tools, security, audit, mcp, type/reference, area/ai, level/intermediate]
+---
+# Third-Party Claude Plugins for Roblox - Audit (Nov 2026)
+
+<!-- tldr:start -->
+> [!tldr] TL;DR
+> - Avoid: Installing a plugin because a video says "free" -> Read `plugin.json`, `.mcp.json`, `hooks/` and the privacy page first
+> - Avoid: Stacking knowledge plugins on top of the vault -> One knowledge source; compare before adding
+> - Avoid: Pasting API keys into chat -> Use the tool's masked config field
+> - Source read: manifests, MCP servers, hooks, network endpoints, licence.
+> - Data leaving the machine identified and acceptable.
+> - Not a duplicate of something already in the repo.
+>
+> Cost: TL;DR ~160 tok · whole note ~1.1k tok. Read more: ## 1. Verdicts · ## 2. TikTok tool ideas, rechecked · ## Common mistakes · ## Checklist
+<!-- tldr:end -->
+
+Tools recommended in TikTok videos (see `research/TikTok Notes/`), inspected by reading their source on 2026-11-20. Nothing was installed or run. Labels: **Verified** (read in the source), **Unverified** (the project's own claims).
+
+---
+
+## 1. Verdicts
+
+| Tool | What it is (Verified) | Licence, activity | Risks found | Verdict |
+|---|---|---|---|---|
+| **roblox-brain** (AkitoDevs) | Claude Code plugin: 174 Roblox knowledge entries + a Node MCP server | MIT, last commit 2026-11-15 | **Shares "lessons" with the maintainer's server by default** (topic, problem, fix, API names, random install id) until you turn it off; runs a Node process | **Skip.** Duplicates the LihFolk vault (1,300+ notes, measured search) and adds outbound data sharing |
+| **Graphify** | Turns a codebase into a queryable graph; code parsed locally with tree-sitter | Apache-2.0, YC-backed, active | Python package and dependencies; docs/images use an LLM or API key; `.luau` parsed with the **Lua** grammar, so Luau type syntax may parse badly | **Not now.** The repo has ~40 game scripts and the vault's own search; revisit when a codebase grows past a few hundred files |
+| **Ponytail** | Hooks and skills that push the agent toward minimal code | MIT, active | Node hooks on every session start and subagent; changes coding style globally; benchmark numbers are self-reported (**Unverified**) | **Skip.** Conflicts with the vault's quality bar and review flow |
+| **OmniRoute** | Gateway that routes AI requests to 300+ providers' free tiers | MIT, very large (≈29,000 files, ~1 GB) | Needs your accounts and API keys for many providers; sends prompts and code to third parties | **Skip.** Credentials, data leaving to unknown providers, and provider terms |
+| **claude-video (/watch)** | Skill: downloads a video with yt-dlp, extracts frames with ffmpeg, pulls captions; optional Gemini key | MIT, last commit 2026-09-25 | Local Python + yt-dlp + ffmpeg; a session-start hook (setup check); optional Gemini key | **Maybe later.** Free in local mode; would replace the manual browser method for research. Needs owner approval to install on the laptop |
+| **ForgeGUI MCP** (elwinhe/forgegui-plugins) | Claude Code plugin for ForgeGUI asset generation | Repo active (v1.9.7) | Needs a ForgeGUI API key; generation spends paid credits; can publish to Roblox through a linked account | **Ask first.** Paid service and account permissions; only for launch-time thumbnails |
```
