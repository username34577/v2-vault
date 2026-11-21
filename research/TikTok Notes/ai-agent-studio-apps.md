---
title: "Multi-agent 'game studio' apps (RO Automation pitch)"
creator: "@trevsagents"
source: https://www.tiktok.com/@trevsagents/video/7702919742880845087
saved: 2026-11-20
verified: 2026-11-20
tags: [tiktok, agents, tools, unverified]
---

# Multi-agent "game studio" apps (RO Automation pitch)

**Creator:** @trevsagents · Back to [[TikTok Notes]]

| Video | Claim |
|---|---|
| [How the #6 Roblox dev makes 3 games a week](https://www.tiktok.com/@trevsagents/video/7702919742880845087) (99s, 137K) | An app called "RO Automation" runs ~15 agents that pitch an idea, pick a look (stud/stylised/realistic), and build for hours unattended. He shows a 2-hour build with an intro cutscene, a shop, an index and props, plus a broken animation (a character running in place). Agents are "trained" on an Obsidian vault of 240,000+ words from a top developer. |
| [Workflow of a 1.3B Robux/year dev](https://www.tiktok.com/@trevsagents/video/7710385877444332830) (122s) | 8 agents on 3 games, a task queue left running overnight, an asset library search, a VFX/asset generator ("black hole aura"), thumbnail and TikTok promo generation, and a review tab to approve, polish or reject. ~2,000-member Discord. |

## Checked
- **"RO Automation", "#6 developer", "1.3B Robux/year":** **Unverified.** No public product page or independent source found. It's an ad for a paid tool via Discord.
- **The approach: Verified** as mainstream. Roblox itself announced agentic Studio features in April 2026 (plans as mini design docs, parallel agents, AI playtesting) and says 44% of its top 1,000 creators use Assistant or third-party AI via MCP.
- **"Trained on a vault": Partially Verified.** It means the agents read notes at run time (retrieval), not model training. That's what your LihFolk vault already does.

## Compared with your setup
You already have the core pieces: the vault + `AGENTS.md` lookup, Rojo, Studio MCP, `rbxtest` automated test runs, `council-method` and `quality-score` for review. What these apps add is a **task queue + review inbox** UI and long unattended runs. The review-before-merge step is the part worth copying; unattended overnight builds without tests are how you get "running in place" bugs.

## Worth it?
As a product: skip until there's independent proof. As a pattern (queue → agents → screenshots → human review): useful.
