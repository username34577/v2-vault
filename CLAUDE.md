# CLAUDE.md

Follow AGENTS.md for Roblox work in this repo.

## Git workflow (owner's standing instruction)

- Commit to `main`. Do not create branches or pull requests unless the owner asks for one.
- Ask the owner before every push to GitHub.
- Before committing, pull the latest `main` so the commit doesn't conflict with changes synced from Obsidian (Obsidian Git auto-commits and pushes every 10 minutes).
- Keep commit messages short and say what changed.
- Never force-push to `main`.

## Automated Studio tests (rbxtest)

- Run a game's test suites in the open Studio with `/rbx-test <game folder>` (e.g. `/rbx-test vfx-lab`). It checks Rojo sync, runs each suite through StudioTestService (solo or multi-client, no clicking), and saves JSON reports to `test-reports/<game>/` with a comparison against the previous run.
- How it works, adding a project, troubleshooting: `dev/rbxtest/README.md`.
- Prefer the Studio MCP tools over screenshots and mouse automation. Never save/publish the place or edit Rojo-managed scripts through MCP.

## Quality gate and work habits

- Before any change goes to the owner: `python dev/lint/lint.py` must show `new 0` (selene, luau-lsp, StyLua; setup in `dev/lint/README.md`), and major changes get a review packet: `python dev/review/make_review.py --title "..."` (skill `agent-work-review`).
- New Luau files are formatted with `stylua`. Don't reformat existing files unless the owner asks.
- End of a work session: log verified lessons with the `session-learning` skill (`learning/`).
- New game: style spec first (`game-style-spec`); before ads or launch: `first-60-seconds-review`.

