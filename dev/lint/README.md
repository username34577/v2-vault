# Luau quality gate (selene + luau-lsp + StyLua)

`python dev/lint/lint.py` checks every game under `games/` (and the rbxtest harness) with three tools and fails **only on findings that are not already in `baseline.json`**. Old code keeps working; anything new has to be clean.

| Tool | Version (pinned in `rokit.toml`) | What it catches |
|---|---|---|
| **selene** | 0.32.0, `std = "roblox"` (`selene.toml`) | Lint: unused variables, shadowing, deprecated Roblox APIs and enum items, common UDim2/Color3 mistakes |
| **luau-lsp analyze** | 1.70.1, Roblox definitions + a Rojo sourcemap | Type errors with real Roblox types and cross-script `require` resolution (much more than plain `luau-analyze`) |
| **StyLua** | 2.6.0 (`stylua.toml`: tabs, 120 columns, double quotes) | Formatting. Existing files are **not** reformatted (that would touch gameplay code); they are in the baseline. New files should be formatted with `stylua <file>` |
| **rojo** | 7.7.1 | Only used here for `rojo sourcemap`. Your `tools\rojo.exe` + `Start Rojo.bat` keep serving Studio as before |
| **luau-compile** | CI job `compile` (Luau 0.744) | Every script compiles |

## One-time setup on the laptop (no admin rights)

1. Install Rokit (the Rojo team's toolchain manager; installs to your user folder, adds itself to your user PATH): follow the install line on https://github.com/rojo-rbx/rokit (Windows: download the `rokit-*-windows-x86_64.zip` release, run `rokit self-install`).
2. In the repo folder: `rokit install`. Rokit asks you to trust each tool the first time.
3. Check: `rojo --version`, `selene --version`, `stylua --version`, `luau-lsp --version` match the table.
4. Run `python dev/lint/lint.py`. The first run downloads the Roblox type definitions into `dev/lint/.cache/` (git-ignored) and selene builds its Roblox standard library in your user cache.

Optional editor support: the **Luau Language Server** extension for VS Code (same luau-lsp) and the **StyLua** extension read the same config files.

## Commands

```
python dev/lint/lint.py                        # 0 = no new findings, 1 = new findings (listed), 2 = tool missing/crashed
python dev/lint/lint.py --report lint.json     # also save every finding
python dev/lint/lint.py --update-baseline      # accept the current state (only after reviewing the new findings)
stylua games/<game>/src/<NewFile>.luau         # format a new file
```

Findings are keyed by tool + file + rule + message (no line numbers), so moving code does not create new findings, but adding one more of the same problem does.

## Verified (2026-11-20, Linux cloud workspace)

- Tools downloaded from each project's official GitHub release (single-binary zips, nothing else inside). Linux zip SHA-256:
  - rojo-7.7.1-linux-x86_64.zip `00feb4fa0829a1dd72b49df2639da519a352bfe13cadcd83969e2ba2bb5693c4`
  - selene-0.32.0-linux.zip `d3773393578580074386e69337d35b7acddfbaa9fc38964c07fa3e28436ade9b`
  - stylua-linux-x86_64.zip (2.6.0) `a485f72bbfa22e4642e77a84b5edc2611a5cab7477b34e2e709dd8f78e919895`
  - luau-lsp-linux-x86_64.zip (1.70.1) `1a2ea1ae4f98f8946cefd970a4b54853e11ab4775e6932faa7f60cf920346567`
  - luau-ubuntu.zip (0.748) `e6905c04dbccaeff54ca4986b0017f125db5aa301bcb34d0446355cbfee5bc83`
- All 39 `.luau` files compile with Luau 0.748.
- Baseline: **68 findings** (luau-lsp 30, selene 12, StyLua 26 unformatted files). Real issues worth fixing later include `Enum.KeyCode.Unknown` (deprecated, flagged by both selene and luau-lsp) in grow-a-monster's client, a `string?` passed where a string is required in VFX Lab's `Lab.client.luau`, and an unused `remote` in `TestHarness.luau`. The many "Key not found in table" errors come from tables filled in after creation; they are type-checker noise until those tables get type annotations.
- Failure detection: adding a probe file with an unused variable and a `number` returned as `string` produced **3 new findings and exit 1**; removing it returned **exit 0**; running without the tools returned **exit 2**.
- Not verified here: `rokit install` (the cloud workspace can't reach the GitHub API it uses), and the CI `lint` job (runs on the next push). In the cloud workspace selene's Roblox library had to be generated from a locally downloaded API dump because its built-in downloader rejects the workspace's TLS proxy; on the laptop and on GitHub Actions it downloads normally.
