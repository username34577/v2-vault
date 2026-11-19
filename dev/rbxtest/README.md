# rbxtest: automated Roblox Studio test runs

Runs a project's test suites in the open Roblox Studio **without clicking**, saves a structured JSON report per run, and compares it with the previous run. Works for any Rojo project in this repo. Claude Code drives it with `/rbx-test <game>`.

Built and probed 2026-11-19 on Windows with Studio's built-in MCP server and Claude Code 2.1.328. See "Verified" below for what has actually been run end to end.

## How it works

```
Claude Code ──MCP execute_luau (Edit)──> StudioTestService:ExecutePlayModeAsync / ExecuteMultiplayerTestAsync(args {suite})
                                                  │ Studio starts a solo or N-player test
                                         game server: TestHarness reads GetTestArgs(), runs the suite
                                         (server suite, or asks a client via a test-only RemoteEvent)
                                                  │ StudioTestService:EndTest(report)
Claude Code <──execute_luau (Edit) reads a non-archivable StringValue── the report (JSON)
     └─ python dev/rbxtest/rbxtest.py save  → test-reports/<project>/<time>-<suite>.json + latest-<suite>.json + comparison
```

No network listener, no HttpService, no plugin to install. Everything goes through the Studio MCP and StudioTestService.

## Pieces

| File | Role |
|---|---|
| `luau/TestHarness.luau` | Server. `register(name, {side="server"\|"client", minPlayers, timeout, run})`, `start()`. Runs only in Studio when StudioTestService passed `{suite=...}`. Validates results (array of `{test, check, status=PASS\|FAIL\|INFO, detail}`, ≤500 entries, ≤200k chars JSON), accepts a client reply only from the player it asked, once; times out; ends the test with a schema-1 report |
| `luau/TestHarnessClient.luau` | Client. `register(name, fn)`, `start()`. Waits up to 20 s for the harness channel (exists only in harness sessions), runs the suite, replies |
| `rbxtest.py` | Standard library only. `sync-check <project.json>` → Luau snippet that checks every Rojo-managed script in Studio matches the files (length + FNV-1a); `save <report> --project N [--commit SHA]` → validate, save, compare, Markdown summary, exit 0/1/2; `compare old new` |
| `games/<game>/rbxtest.json` | Per-project config: name, Rojo project, suites (`mode` solo or multi, `players`, `timeoutS`) |
| `.claude/commands/rbx-test.md` | The step-by-step workflow Claude Code follows (`/rbx-test <game>`). Remote tools can't write `.claude/`; it reaches a machine through git |
| `test-reports/<project>/` | Saved reports (committed: run history) |

Report schema 1: `{schema:1, suite, status: completed|error|timeout|unknown_suite, results:[...], error?, meta:{place, placeId, startedAt, durationS, players, args, savedAt, commit}}`.

`save` exit codes: **0** completed with no FAIL and no regression · **1** FAIL, run error/timeout, or a check that went PASS→FAIL · **2** the report itself is invalid.

## The spawn snippet (step 4a)

Run in **Edit** with `execute_luau`; replace `SUITE`, `NAME` and the start line.

```lua
local STS = game:GetService("StudioTestService")
local HttpService = game:GetService("HttpService")
local out = Instance.new("StringValue")
out.Name = "_RbxTest_NAME"
out.Archivable = false -- never saved with the place
out.Value = "running"
out.Parent = game:GetService("ServerStorage")
task.spawn(function()
	local ok, res = pcall(function()
		return STS:ExecutePlayModeAsync({ suite = "SUITE" }) -- solo
		-- multi: return STS:ExecuteMultiplayerTestAsync(2, { suite = "SUITE" })
	end)
	out.Value = HttpService:JSONEncode({ ok = ok, res = if ok then res else tostring(res) })
end)
return "spawned"
```

Polling (measured): **solo** switches this Studio into Play, so Edit is unreachable until the test ends: poll `get_studio_state` until Mode is Edit, then read the value. **Multi** runs the server and each client in separate Studio processes (listed by `list_roblox_studios` with `name: null`); this Studio stays in Edit, so poll the value directly.

## Add a new project

1. Copy nothing: map the harness in the project's Rojo file, e.g. under `ReplicatedStorage`: `"TestHarness": { "$path": "../../dev/rbxtest/luau" }`.
2. Server script: `local TH = require(ReplicatedStorage.TestHarness.TestHarness)`; `TH.register("smoke", { side = "server", run = function() return { { test = "boot", check = "map loaded", status = if workspace:FindFirstChild("Map") then "PASS" else "FAIL" } } end })`; `TH.start()`.
3. Client suites (optional): `TestHarnessClient.register("ui", fn)`, `TestHarnessClient.start()` in a LocalScript; server side `TH.register("ui", { side = "client" })`.
4. Add `games/<game>/rbxtest.json` with the suites.
5. In Claude Code (Studio open on that project, Rojo connected): `/rbx-test <game>`.

Suites should return results instead of printing them; keep `detail` small (numbers, short strings).

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Sync check `ok:false`, "missing in Studio" for every file | Rojo not connected (it can drop with a WebSocket 400) | Plugins → Rojo → Connect, accept, rerun |
| Sync check "source differs" on one file | That file changed after Rojo last synced, or someone edited it in Studio | Reconnect Rojo / revert the Studio edit |
| Report `unknown_suite` | Suite name not registered on the server | Check `register` names vs `rbxtest.json` |
| Report `error: needed 2 players` | Multi test players didn't spawn within 60 s | Rerun; check Studio isn't overloaded |
| Report `timeout` | Suite didn't finish within its timeout (server) or the client never replied | Read `get_console_output` for errors; raise `timeout` if the suite is just long |
| Value stays `running` forever (solo) | Test ended without `EndTest` (stopped manually or crashed) | `start_stop_play` false; the async call then returns `nil` |
| `ExecutePlayModeAsync` errors "already running" | A test session is open | Stop it, rerun |
| Edit `execute_luau` says "Edit datamodel is not available in Play mode" | Expected during a solo run | Keep polling `get_studio_state` |

## Limits (measured, 2026-11-19)

- One multiplayer session per Studio; 1–8 clients.
- `get_console_output` is plain text, is replaced when a playtest starts, and mixes client and server lines. That's why results come back through `EndTest`, not the log.
- Performance numbers come from whatever machine runs Studio (a 60 FPS-capped PC). They are **not** proof of mobile performance.
- Input tools (`user_keyboard_input`, `user_mouse_input`) always report success; verify inside the game.

## Verified

2026-11-19, VFX Lab at commit 1b1ee63, Windows laptop, started by one double-click with no further input:

- `local` (solo): completed, 27 PASS / 0 FAIL / 3 INFO in 69 s. Matches the manual 30/30.
- `replication` (2 clients): completed, 6 PASS / 0 FAIL / 1 INFO in 17 s. Matches the manual 6/6.
- With Studio holding stale code, an earlier run stopped at the sync check, ran nothing and saved nothing.
- The absolute FPS in that run was 15 (baseline included), against 60 when run by hand, most likely because Studio was in the background. Relative overhead is still valid; absolute numbers from unattended runs aren't.

Reports: `test-reports/vfx-lab/`. Write-up: vault note *Automated Studio Test Runs (rbxtest)*.
