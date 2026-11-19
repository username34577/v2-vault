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
