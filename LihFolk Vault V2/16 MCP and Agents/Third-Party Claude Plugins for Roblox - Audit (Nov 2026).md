---
tags: [agents, plugins, tools, security, audit, mcp, type/reference, area/ai, level/intermediate]
---
# Third-Party Claude Plugins for Roblox - Audit (Nov 2026)

<!-- tldr:start -->
> [!tldr] TL;DR
> - Avoid: Installing a plugin because a video says "free" -> Read `plugin.json`, `.mcp.json`, `hooks/` and the privacy page first
> - Avoid: Stacking knowledge plugins on top of the vault -> One knowledge source; compare before adding
> - Avoid: Pasting API keys into chat -> Use the tool's masked config field
> - Source read: manifests, MCP servers, hooks, network endpoints, licence.
> - Data leaving the machine identified and acceptable.
> - Not a duplicate of something already in the repo.
>
> Cost: TL;DR ~160 tok · whole note ~1.1k tok. Read more: ## 1. Verdicts · ## 2. TikTok tool ideas, rechecked · ## Common mistakes · ## Checklist
<!-- tldr:end -->

Tools recommended in TikTok videos (see `research/TikTok Notes/`), inspected by reading their source on 2026-11-20. Nothing was installed or run. Labels: **Verified** (read in the source), **Unverified** (the project's own claims).

---

## 1. Verdicts

| Tool | What it is (Verified) | Licence, activity | Risks found | Verdict |
|---|---|---|---|---|
| **roblox-brain** (AkitoDevs) | Claude Code plugin: 174 Roblox knowledge entries + a Node MCP server | MIT, last commit 2026-11-15 | **Shares "lessons" with the maintainer's server by default** (topic, problem, fix, API names, random install id) until you turn it off; runs a Node process | **Skip.** Duplicates the LihFolk vault (1,300+ notes, measured search) and adds outbound data sharing |
| **Graphify** | Turns a codebase into a queryable graph; code parsed locally with tree-sitter | Apache-2.0, YC-backed, active | Python package and dependencies; docs/images use an LLM or API key; `.luau` parsed with the **Lua** grammar, so Luau type syntax may parse badly | **Not now.** The repo has ~40 game scripts and the vault's own search; revisit when a codebase grows past a few hundred files |
| **Ponytail** | Hooks and skills that push the agent toward minimal code | MIT, active | Node hooks on every session start and subagent; changes coding style globally; benchmark numbers are self-reported (**Unverified**) | **Skip.** Conflicts with the vault's quality bar and review flow |
| **OmniRoute** | Gateway that routes AI requests to 300+ providers' free tiers | MIT, very large (≈29,000 files, ~1 GB) | Needs your accounts and API keys for many providers; sends prompts and code to third parties | **Skip.** Credentials, data leaving to unknown providers, and provider terms |
| **claude-video (/watch)** | Skill: downloads a video with yt-dlp, extracts frames with ffmpeg, pulls captions; optional Gemini key | MIT, last commit 2026-09-25 | Local Python + yt-dlp + ffmpeg; a session-start hook (setup check); optional Gemini key | **Maybe later.** Free in local mode; would replace the manual browser method for research. Needs owner approval to install on the laptop |
| **ForgeGUI MCP** (elwinhe/forgegui-plugins) | Claude Code plugin for ForgeGUI asset generation | Repo active (v1.9.7) | Needs a ForgeGUI API key; generation spends paid credits; can publish to Roblox through a linked account | **Ask first.** Paid service and account permissions; only for launch-time thumbnails |

## 2. TikTok tool ideas, rechecked

| Idea | Status | Decision |
|---|---|---|
| Luau lint, types and format (selene, luau-lsp, StyLua) | Installed and gated | Done: [[Luau Toolchain and Quality Gate]] |
| Audio judge for sound design (OpenRouter audio models) | Tools verified | Needs a paid key: owner decision |
| Prompt-rewriter mod | Claude Code mods verified | Could be written in-repo; installing it changes Claude Code on the laptop: owner decision |
| AutoScale Lite, 2D Emitter (Studio plugins) | Verified | Install from the Creator Store only when UI work starts |
| Claude Design for UI mockups | Verified | Already available in the owner's Claude account; no install |

## Common mistakes

| Mistake | Why it hurts | Fix |
|---|---|---|
| Installing a plugin because a video says "free" | Free plugins can send data out or run code at every session start | Read `plugin.json`, `.mcp.json`, `hooks/` and the privacy page first |
| Stacking knowledge plugins on top of the vault | Conflicting advice and extra tokens every session | One knowledge source; compare before adding |
| Pasting API keys into chat | Keys end up in logs and history | Use the tool's masked config field |

## Checklist

- [ ] Source read: manifests, MCP servers, hooks, network endpoints, licence.
- [ ] Data leaving the machine identified and acceptable.
- [ ] Not a duplicate of something already in the repo.
- [ ] Owner approved anything paid, credentialed or system-wide.

## Related
- [[Agent Workflows - Review, Learning, Style and First 60 Seconds]]
- [[Safety Rules for AI Agents in Studio]]
