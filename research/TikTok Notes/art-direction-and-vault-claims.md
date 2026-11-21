---
title: "Art direction from references, and what Obsidian vaults really do"
creator: "@flow4devs, @jacobunfiltered, @captainamado, @trulyrbx, @lihfolk"
source: https://www.tiktok.com/@flow4devs/video/7704509240500604174
saved: 2026-11-20
verified: 2026-11-20
tags: [tiktok, art-direction, ui, obsidian, workflow]
---

# Art direction from references, and what Obsidian vaults really do

Back to [[TikTok Notes]] · Vault reference: [[Obsidian Vaults for AI Agents - Structure, Graph and Theming]], [[obsidian-vault-for-ai]], [[ui-from-reference-images]], `skills/lihfolk-ui`

## Art direction from references
| Video | Method |
|---|---|
| [@flow4devs: the only thing you need to make models with AI](https://www.tiktok.com/@flow4devs/video/7704509240500604174) (46s, 18K) | Pick a target look (his example: Borderlands). Describe everything: black outlines, hand-painted textures, VFX style, mood. Iterate concept images in ChatGPT until close, then give the images + prompt to Claude and tell it to **ask you questions until you agree on the look**. Expect a few hours of misses; once one asset is right, it can repeat the style. |
| [@jacobunfiltered: "ungatekeeping" the UI method](https://www.tiktok.com/@jacobunfiltered/video/7701179731667979551) (38s, 136K) | Screenshot every screen of ~20 top games (50K–100K CCU), give them to Claude, and have it work out what makes them good, then build your UI from that. |

**Checked: Partially Verified.** The method matches the vault; results are the creators' own.
- Both match the vault's approach (reference coverage, style notes, `rbx-reference-coverage` skill). Claude doesn't "train itself" on screenshots; it reads them in that session. Save the findings as a **style note in the game's folder** so later sessions reuse them.
- **Recreating a top game's UI one-to-one is copying.** The vault rule is original art and names. Learn the hierarchy, spacing and feedback, not the exact look.
- A target look from a famous franchise (Borderlands) is fine as a *style* reference (cel shading, outlines); don't copy its characters or logos.

## Claims about Obsidian vaults
| Video | Claim | Status |
|---|---|---|
| [@jacobunfiltered: Obsidian vault is OP](https://www.tiktok.com/@jacobunfiltered/video/7701558627760426271) (84s, 137K) | Thousands of references in a vault make Claude copy them "to a T", and it "reduces usage because it's hard-coded in memory". | **Partially Verified.** A vault helps because Claude **reads the relevant notes** each session. It isn't memory. It saves tokens only if notes are small and found by search (your vault's TL;DR + `vault.py` setup), not if Claude reads thousands of files. |
| [@captainamado: Obsidian burning credits](https://www.tiktok.com/@captainamado/video/7707842281126087949) (19s) | Connecting Obsidian "wrong" burns credits; you need a skill that turns the vault into a graph instead of words. | **Partially Verified.** Reading whole vaults is what burns tokens. Your vault already fixes this with an index, TL;DRs and search, the same goal as graph tools like Graphify ([[token-saving-plugins]]). No specific skill named; unverified. |
| [@trulyrbx: "Obsidian skills that stop Claude being an idiot"](https://www.tiktok.com/@trulyrbx/photo/7704860090578291998) (photo post, 14 slides) | Lists `/chronos`, `/inherit`, `/smart-branches`, `/refractor`, `/moc`, `/visual`, `/experiment`, `/cleanup`, `/inoculate`, `/pill`, `/bundle`, `/budget`, `/assemble`. | **Unverified.** Names and one-line descriptions only, no source, caption "skills are larp". Several overlap what you have: `/moc` = your index notes, `/pill` (log past errors so they don't repeat) = `SYMPTOMS.md` + the weekly mistakes-to-rules idea, `/budget` = TL;DR token costs. |
| [@lihfolk: 40GB+ Obsidian vault](https://www.tiktok.com/@lihfolk/video/7701541453754862861) (82s, 708K) | The vault you're already using; "light" version is all the knowledge, "full" adds ~30GB of modelling assets. | **Verified** by your setup (v2-vault is LihFolk Vault V2). |

## Worth it?
The art-direction loop (describe → concept images → Claude asks questions → lock a style note) is worth doing for your next game. The vault claims add nothing new; your vault is ahead of them.
