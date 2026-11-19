---
description: Run a Roblox project's automated test suites in the open Studio (rbxtest) and save JSON reports
argument-hint: <game folder, e.g. vfx-lab> [suite ...]
allowed-tools: mcp__Roblox_Studio, Read, Write, Bash(python:*), Bash(py:*), Bash(git rev-parse:*), Bash(sleep:*)
---

Run the rbxtest workflow for `games/$ARGUMENTS`. Full reference: `dev/rbxtest/README.md`. Follow these steps exactly and report only what actually happened.

1. **Config.** Read `games/<project>/rbxtest.json` (name, rojoProject, suites). If extra arguments name suites, run only those.
2. **Studio.** `list_roblox_studios`; use the instance in Edit mode. If several are in Edit, run step 3 on each: the one whose sync check passes is this project (place names like "Place1" can't be trusted). If none or several pass, stop and ask. `get_studio_state` must be Edit; if it's in Play, stop: someone may be testing.
3. **Rojo sync check.** Run `python dev/rbxtest/rbxtest.py sync-check games/<project>/<rojoProject>` (no shell redirect: redirects trigger permission prompts) and pass its whole stdout to `execute_luau` (Edit). If `ok` is false, STOP and tell the user to reconnect Rojo (list the mismatched files). Do not test stale code.
4. **For each suite** (in config order):
   a. `execute_luau` (Edit) with the spawn snippet from the README, substituting the suite name, mode (`solo` → `ExecutePlayModeAsync`, `multi` → `ExecuteMultiplayerTestAsync(players, …)`) and a value name `_RbxTest_<suite>`.
   b. Poll until the result is in, up to `timeoutS`. Between polls wait with its own call (`sleep 15`), never in the same parallel batch as the status call:
      - solo: `get_studio_state` until Mode is Edit again, then read the value with `execute_luau` (Edit).
      - multi: read the value with `execute_luau` (Edit) until it is no longer `running`.
   c. On timeout: `get_console_output` (and for multi, `list_roblox_studios` to find the server instance), end the test (`execute_luau` Server: `game:GetService("StudioTestService"):EndTest({})`, or `start_stop_play` false for solo), and record a timeout.
   d. Use the Write tool (not a shell redirect) to write the value to `.rbxtest-result.json` (gitignored; overwritten each time). The value is `{"ok":..,"res":<report>}`; save only `res` (if `ok` is false or `res` is null, save a report with status "error" and the message). Then run `python dev/rbxtest/rbxtest.py save .rbxtest-result.json --project <name> --commit <git rev-parse --short HEAD>`.
   e. If the save exits non-zero, collect diagnostics: the FAIL entries, and `get_console_output` lines containing `error`, `warn`, `[VFXLab` or the suite name.
5. **Cleanup.** `execute_luau` (Edit): destroy every `ServerStorage._RbxTest_*` value; confirm `get_studio_state` is Edit. Leave `.rbxtest-result.json` in place (gitignored; the next run overwrites it).
6. **Report** to the user: one line per suite (PASS/FAIL counts, status), regressions vs the previous run, performance numbers as recorded, absolute and baseline-relative (PC numbers are not proof of mobile performance; if the baseline is far below the 60 FPS cap, say Studio was probably throttled in the background and absolute numbers from this run are not meaningful), and the saved report paths. Never claim a suite passed unless its saved report says so.

Rules: never save or publish the place; never edit Rojo-managed scripts through MCP; never run a suite while a human is in a playtest.
