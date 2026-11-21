---
title: "Sound design with Claude Code: an audio judge loop"
creator: "@oddblockstudios"
source: https://www.tiktok.com/@oddblockstudios/video/7708469682512170253
length_sec: 44
theme: Audio / workflow
saved: 2026-11-20
verified: 2026-11-20
tags: [tiktok, audio, sfx, claude-code, openrouter, verified]
---

# Sound design with Claude Code: an audio judge loop

**Creator:** @oddblockstudios · **Length:** 44s · 74K plays · [Watch](https://www.tiktok.com/@oddblockstudios/video/7708469682512170253) · Back to [[TikTok Notes]]

Vault reference: `skills/lihfolk-sfx`, [[Sound Design for Games]], [[Combat Sound Design and Feedback]], [[Agent Review Loops and Guardrails in Practice]]

## What the video shows
Narration is short ("get an OpenRouter key, paste the prompt, done in 20 minutes"). The real method is on his screen (read from frames):
- He gets an **OpenRouter** API key and filters models by audio output (Google Lyria 3 Clip/Pro, OpenAI GPT Audio).
- Claude Code builds the weapon's sound set, then an **audio-capable model acts as a judge**: it listens to the reel and writes notes ("the equip and reload sound like a normal rifle, the hit is muddy, the Popper hit gets lost under rapid fire"). Claude fixes, rebuilds, and re-judges. The reel went to "6 to 8 out of 10".
- Each preview plays **old set, gap, new set**, so a human can compare.
- The new set is **"layered real Pro Sound Effects recordings"** (**Unverified** beyond his screen; the library and licence aren't shown): licensed library sounds layered together, **not** AI-generated audio. AI is the editor and critic.

## Checked
- **OpenRouter audio models: Verified** (OpenRouter docs and model pages). Lyria 3 Clip is $0.04 per 30-second clip, Lyria 3 Pro $0.08 per song, GPT Audio is token-priced. Audio output needs `modalities` + `audio` params and **streaming** on the Chat Completions API.
- **Lyria is a music model: Verified** short loops and stingers, not ideal for weapon one-shots. That fits what he did: real recordings for the SFX, AI to judge.
- **Licensing: Verified** against the vault rules. Layering a library you own a licence for is fine. `lihfolk-sfx` already requires licensed sources only (Creator Store audio or a library you own). Roblox's audio upload rules still apply ([[Music Licensing and Audio Upload Rules for 2026]]).

## How to use it here
The vault's SFX skill already covers layering, pooling and sync. The **new idea is the listening critic**: an audio-input model scoring the reel against written notes, plus old-vs-new A/B previews. It's the same blind-review pattern as `council-method`, applied to sound. It needs an OpenRouter key (paid, per request).

## Worth it?
Yes. Best workflow video in the batch, and honest: AI judges, real sounds ship.
