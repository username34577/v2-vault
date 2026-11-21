---
tags: [tooling, luau, lint, type-checking, selene, stylua, luau-lsp, rojo, ci, type/guide, area/ai, area/testing, level/intermediate]
---
# Luau Toolchain and Quality Gate

<!-- tldr:start -->
> [!tldr] TL;DR
> - Avoid: Running `luau-lsp analyze` from the repo root -> Run from `games/<game>/` (lint.py does)
> - Avoid: Reformatting old files with StyLua in a feature change -> Format only new files; reformat old ones in a separate, approved...
> - Avoid: Updating the baseline to make CI green -> Read the new findings first; only accept ones that are noise, and...
> - `python dev/lint/lint.py` shows `new 0` before a change goes to review.
> - New Luau files are StyLua-formatted.
> - Baseline changes are explained in the review packet.
>
> Cost: TL;DR ~170 tok · whole note ~1.0k tok. Read more: ## 1. What is installed and pinned · ## 3. Verified results (2026-11-20) · ## Common mistakes · ## Checklist
<!-- tldr:end -->

The repo's Luau tools and the gate that every change passes: **selene** (lint), **luau-lsp** (type checking with real Roblox types), **StyLua** (format), **luau-compile** (compiles) and **Rojo** (sourcemaps). Code and commands: `dev/lint/README.md`. Facts are **Measured** on 2026-11-20 unless labelled otherwise.

---

## 1. What is installed and pinned

| Tool | Version | Pinned in | Role |
|---|---|---|---|
| Rojo | 7.7.1 | `rokit.toml` | `rojo sourcemap` for type checking (serving Studio still uses `tools/rojo.exe`) |
| selene | 0.32.0 | `rokit.toml`, `selene.toml` (`std = "roblox"`) | Lint: unused, shadowing, deprecated APIs |
| StyLua | 2.6.0 | `rokit.toml`, `stylua.toml` (tabs, 120 columns, double quotes) | Format new files |
| luau-lsp | 1.70.1 | `rokit.toml` | `luau-lsp analyze` with Roblox definitions and a Rojo sourcemap |
| Luau | 0.748 (workspace), 0.744 (CI) | CI `compile` job | `luau-compile` |

All are free, open source, single binaries from each project's official GitHub release, installable per user with Rokit (no admin rights).

## 2. The gate

`python dev/lint/lint.py` runs the three checkers over every game and the rbxtest harness and fails only on **new** findings: findings already present are recorded in `dev/lint/baseline.json` (keyed by tool, file, rule and message, not line numbers). The CI job `lint` in `.github/workflows/game-checks.yml` runs it on every push that touches games, dev tools or the tool configs.

Exit codes: 0 no new findings, 1 new findings listed, 2 a tool is missing or crashed.

## 3. Verified results (2026-11-20)

- 39 Luau files compile.
- Baseline: **68 findings**: luau-lsp 30, selene 12, StyLua 26 unformatted files.
- Probe file with an unused local and a `number` returned as `string`: 3 new findings, exit 1. Removed: exit 0. Tools missing: exit 2. A file with a syntax error: reported by all three tools as new findings.
- Worth fixing later (not changed now, gameplay is out of scope): a deprecated `KeyCode` enum item used in grow-a-monster's client (both selene and luau-lsp flag it), a possibly-nil string passed to a `number | string` parameter in VFX Lab's lab client, an unused `remote` in the test harness.
- Most luau-lsp findings are "Key not found in table" on tables filled after creation; they're type noise until the tables get type annotations.

## 4. Where it can't run (measured)

- In the cloud workspace, selene's built-in Roblox library download fails (its TLS client rejects the workspace proxy). Workaround used: generate the library once from a downloaded API dump with a patched local build. On the laptop and GitHub Actions it downloads normally.
- `rokit install` needs the GitHub API, which the cloud workspace can't reach. Not yet run on the laptop.
- The CI `lint` job has not run yet; it runs on the next push.

## Common mistakes

| Mistake | Why it hurts | Fix |
|---|---|---|
| Running `luau-lsp analyze` from the repo root | Every cross-script `require` is "Unknown require" because the sourcemap is relative to the project folder | Run from `games/<game>/` (lint.py does) |
| Reformatting old files with StyLua in a feature change | Huge diffs that hide the real change and touch gameplay | Format only new files; reformat old ones in a separate, approved change |
| Updating the baseline to make CI green | Hides real new bugs | Read the new findings first; only accept ones that are noise, and say why in the review packet |
| Using a different Rojo version for serving than the Studio plugin expects | Sync breaks | Keep serving with the version that matches the plugin; the pinned Rojo is for sourcemaps |

## Checklist

- [ ] `python dev/lint/lint.py` shows `new 0` before a change goes to review.
- [ ] New Luau files are StyLua-formatted.
- [ ] Baseline changes are explained in the review packet.
- [ ] On a new machine: `rokit install`, then check the four versions.

## Related
- [[Automated Studio Test Runs (rbxtest)]]
- [[Agent Workflows - Review, Learning, Style and First 60 Seconds]]
