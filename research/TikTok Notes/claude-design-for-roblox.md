---
title: "Claude Design for Roblox shop UI and voxel models"
creator: "@jarvislabsreal, @crazz977"
source: https://www.tiktok.com/@jarvislabsreal/video/7695597916089535757
saved: 2026-11-20
verified: 2026-11-20
tags: [tiktok, ui, models, claude-design]
---

# Claude Design for Roblox shop UI and voxel models

Back to [[TikTok Notes]] · Vault reference: `skills/lihfolk-ui`, `skills/roblox-ui-builder`, `21 LihFolk UI Design System`, `skills/roblox-asset-import`

Both videos have no speech; reviewed frame by frame.

| Video | What's on screen |
|---|---|
| [@jarvislabsreal: new shop with Claude Design](https://www.tiktok.com/@jarvislabsreal/video/7695597916089535757) (17s, 62K) | **Before:** a stacked list shop. **After:** a horizontal row of tall item cards (Starter Pack, VIP, 2x Power, cash packs) with category tabs on the left and big green buy buttons. |
| [@crazz977: Claude design](https://www.tiktok.com/@crazz977/video/7703645968800992534) (12s, 78K) | A browser page made in Claude Design showing **12 voxel boss models** (Crab, Scorpion, Rhino, Crocodile, Frost Bear, Mammoth, Fire Beast, Sky/Night Dragon, Blood Stag…) with tabs and a **"Download all 12 for Roblox (.glb)"** button. |

## Checked
- **Claude Design: Verified** (Anthropic announcement and product page). An Anthropic Labs product (launched April 2026) for designs, prototypes and decks, including code-powered prototypes with 3D. Official exports are **PDF, PPTX, HTML**, links, and hand-off to Claude Code.
- **GLB export: Unverified.** Not an official export. The download button is something Claude built inside that page (likely three.js code generating the voxel meshes). It can work, but the models are **unverified** for Roblox import: check scale, pivot, part/triangle count and materials with `roblox-asset-import` and the `rbx-import-calibration` skill.
- **Unverified (design judgement):** the UI "after" is a real upgrade (clear value per card, one action per card). The vault's UI skills already teach this; Claude Design is just another way to mock it up before building in Studio.

## How it fits your setup
Your Claude account has Design artifacts, so you can mock a shop screen there, then build it in Studio with `roblox-ui-builder` + Rojo. Voxel props from a generated GLB are fine for prototypes; ship models that pass the vault's quality bar (`quality-score`, 8.5/10).

## Worth it?
Medium. A good before/after reference and a cheap way to explore UI layouts. Not a pipeline by itself.
