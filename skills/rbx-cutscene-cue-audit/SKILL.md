---
name: rbx-cutscene-cue-audit
description: Check cutscene and animation VFX cue timing against actual Roblox animation markers or a runtime cue log. Use for mistimed contacts, missed impacts, duplicate cues, and repeatable cutscene verification.
---

# Cutscene cue audit

Give each shot a timeline range. For visual cues, name the visible event and record its intended time from the start of the shot or the shared timeline. Use source frame divided by source frame rate when converting a zero-based frame number. Use an existing animation or cutscene workflow to author the change.

Copy [the example cue sheet](references/cues.example.json) and set the track, marker, timing, and tolerance for each cue. For authored timing, collect actual markers from the saved animation or sequence using [the Studio snapshot instructions](references/studio-markers.md). For suspected runtime duplication or timing bugs, use a separate sheet for observed events captured in the relevant playtest, with times relative to the same shot or sequence origin.

```text
python <skill-directory>/scripts/check_cues.py cues.json
```

The audit reports missing and extra occurrences and lists the time error for each matched cue. Include every occurrence of the same cue under that track, including duplicates in the actual log. Add shot offsets consistently before comparing a clip-local log to a shared timeline. Keep deliberate unrelated events outside the log for this audit.

Resolve timestamp mismatches by checking playback rate, blends, timeline origin, and which clip owns the marker. Replay the same test after fixing it. For trails or continuous bursts, include separate on and off events. Test skip and interruption separately and check that camera control returns, enabled effects clear, and replay starts cleanly. Cue timing evidence does not establish visual quality or the cleanup result.
