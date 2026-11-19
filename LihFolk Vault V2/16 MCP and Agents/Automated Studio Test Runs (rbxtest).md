---
tags: [mcp, studio, testing, agents, tooling, type/guide, area/ai, area/testing, level/intermediate]
---
# Automated Studio Test Runs (rbxtest)

<!-- tldr:start -->
> [!tldr] TL;DR
> - Solo test: Studio switches to Play, so Edit can't be reached until the test ends.
> - Read `games/<game>/rbxtest.json` (suites, mode, players, timeout).
> - Both match the earlier manual results. Reports: `test-reports/vfx-lab/20261119-142030-local.json` and...
> - Windows-only setup tested so far; needs Studio open with the MCP server on and Rojo connected.
>
> Cost: TL;DR ~130 tok · whole note ~1.3k tok. Read more: ## 1. What the Studio MCP can and can't do (measured) · ## 3. Verified results (2026-11-19, VFX Lab, commit 1b1ee63)
<!-- tldr:end -->

rbxtest lets Claude Code run a game's test suites in the open Roblox Studio with no clicking. It checks that Rojo is in sync, starts each suite through StudioTestService (solo or multi-client), captures the exact results as JSON, saves a report per run and compares it with the previous one. Code and full reference: `dev/rbxtest/README.md` in the repo. Claude Code command: `/rbx-test <game folder>`.

Facts are **as of November 2026**, measured on the Lenovo LOQ 15 with Studio's built-in MCP server (39 tools). See [[Roblox Studio MCP Server]] for the tool set and [[Safety Rules for AI Agents in Studio]] for working rules.

---

## 1. What the Studio MCP can and can't do (measured)

| Capability | Works? | How |
|---|---|---|
| Find open Studios, read Edit/Play state | Yes | `list_roblox_studios`, `get_studio_state` |
| Inspect the DataModel | Yes | `search_game_tree`, `inspect_instance` |
| Read and search scripts | Yes | `script_read`, `script_grep`, `script_search` |
| Set properties | No dedicated tool | Use `execute_luau` |
| Run Luau in Edit, Server or Client | Yes | `execute_luau`; a 70 s call worked |
| Start/stop Play Solo | Yes | `start_stop_play` |
| Multi-client playtest | Not via `start_stop_play` | `StudioTestService:ExecuteMultiplayerTestAsync` from `execute_luau` |
| Read Output | Partly | `get_console_output`: plain text, replaced each playtest, client and server mixed. Not reliable for results |
| Screenshots / video / input | Yes | Input tools always report success, so verify by state, not by their return value |
| Run tests and get exact results | Yes | StudioTestService: the server calls `EndTest(report)` and the report comes back as the return value of the async call |

Behaviour worth knowing:
- **Solo test:** Studio switches to Play, so Edit can't be reached until the test ends. Poll `get_studio_state` until it's Edit again.
- **Multi-client test:** runs as separate Studio instances (server + each client, `name` is null). The original stays in Edit, so you poll a value there.
- **Rojo can silently disconnect** (WebSocket 400). That is why every run starts with a sync check: it hashes each Rojo-managed file in Python and in Luau and refuses to test stale code.

## 2. How a run works

1. Read `games/<game>/rbxtest.json` (suites, mode, players, timeout).
2. Pick the Studio in Edit mode whose sync check passes.
3. Sync check (`rbxtest.py sync-check`) through `execute_luau`. Stop if any file differs.
4. Per suite: spawn the StudioTestService call into a background thread, poll, then save the returned report with `rbxtest.py save`, which validates it, writes `test-reports/<game>/<timestamp>-<suite>.json` plus `latest-<suite>.json`, and prints REGRESSION / FIXED / NEW / MISSING and performance deltas against the previous run.
5. Clean up the temporary values. Never save or publish the place.

In the game, `TestHarness` (server) and `TestHarnessClient` decide which suite to run from `GetTestArgs()` and only act in Studio test sessions, so normal play and live servers are untouched. Results are validated (shape, status values, size limits) before they're accepted.

## 3. Verified results (2026-11-19, VFX Lab, commit 1b1ee63)

First fully automated run, started by a double-click and finished with no further input:

| Suite | Mode | Status | PASS / FAIL / INFO | Time | Manual run before |
|---|---|---|---|---|---|
| local | solo | completed | 27 / 0 / 3 | 69 s | 30/30 |
| replication | 2 clients | completed | 6 / 0 / 1 | 17 s | 6/6 |

Both match the earlier manual results. Reports: `test-reports/vfx-lab/20261119-142030-local.json` and `20261119-142122-replication.json`.

**Safety check proven:** an earlier run, with Studio holding stale code, stopped at the sync check, ran no suites and saved nothing.

### Performance: absolute numbers were throttled

| Run | p95 frame | avg FPS | vs baseline |
|---|---|---|---|
| Baseline (no effects) | 67.9 ms | 15 | — |
| Low | 68.0 ms | 14 | +0.1 ms, 0.99× |
| Medium | 67.9 ms | 15 | −0.1 ms, 1.00× |
| High | 68.0 ms | 15 | +0.1 ms, 0.99× |

The manual run had a 60 FPS baseline. Here even the no-effects baseline was 15 FPS, so the effects are not the cause. The likely cause is that Studio was behind other windows during the run. That hasn't been tested yet. The relative check still passes, but **absolute FPS from an unattended run is not meaningful**, and none of this says anything about phones.

## 4. Known limits

- Windows-only setup tested so far; needs Studio open with the MCP server on and Rojo connected.
- One Studio per project at a time; don't run while a person is playtesting.
- `get_console_output` isn't used for results, only for diagnostics on failure.
- Mobile performance still needs the device emulator, a real phone and MicroProfiler.

## 5. Adding a project

1. Add `"TestHarness": {"$path": "../../dev/rbxtest/luau"}` under ReplicatedStorage in the Rojo project.
2. Register suites with `TestHarness.register(...)` on the server (and `TestHarnessClient.register` for client suites), then call `start()`.
3. Add `games/<game>/rbxtest.json`.
4. Run `/rbx-test <game>`.
