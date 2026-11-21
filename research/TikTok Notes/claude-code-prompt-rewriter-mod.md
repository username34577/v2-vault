---
title: "Claude Code mod: rewrite rough prompts with one button"
creator: "@justinyun"
source: https://www.tiktok.com/@justinyun/video/7710054945336200461
length_sec: 30
theme: Workflow
saved: 2026-11-20
verified: 2026-11-20
tags: [tiktok, claude-code, mods, prompting, verified]
---

# Claude Code mod: rewrite rough prompts with one button

**Creator:** @justinyun · **Length:** 30s · [Watch](https://www.tiktok.com/@justinyun/video/7710054945336200461) · Back to [[TikTok Notes]]

## What he says
Prompt Claude Code: *"Make me a Claude mod that rewrites my rough prompt into a better one before I send it. Add a Prompt Master button so I can run it in one click."* Claude installs a mod, and a Prompt Master option appears next to the prompt box. (**Unverified**: his exact mod isn't shown or published.)

## Checked
- **Mods: Verified** (Claude Code docs and announcement). Small TypeScript functions in Claude Code (CLI and the desktop app's Code tab). They can **rewrite a prompt before it reaches the model** (`prompt.submit`), add buttons and panes, and you can ask Claude to write one. They ship inside plugins.
- **Safety: Verified** (Claude Code docs): a mod runs with your permissions and can see every prompt and tool call, and your environment variables. Only install mods from sources you trust. One you ask Claude to write yourself is the safe case.
- **Cost: Unverified estimate:** a rewrite step adds a model call per prompt. Use a button (opt-in), not an every-prompt rewrite.

## How it fits
Same idea as the "master prompt from another AI" tip ([[ai-master-prompt-for-maps]], [[creator-rxz-dev]]), but built in. For Roblox work, a rewriter that adds "check the vault first (AGENTS.md step 1), name the game folder, state the done-condition" would be the useful version.

## Worth it?
Yes, small and real. **Not installed.** Needs your OK (see the recommendations in [[favorites-2026-11-20]]).
