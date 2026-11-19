---
name: rbx-prop-handoff-audit
description: Find pose or grip jumps when a cutscene prop changes owner for Roblox development using captured measurements or traces.
---

# Find pose or grip jumps when a cutscene prop changes owner

At the handoff frame, record the last position and direction under the outgoing owner and the first under the incoming owner in the same world frame. Sample an anchor on the prop and the prop's forward vector before the handoff.

Copy [the working input fixture](references/example.json) and replace the example values with your capture. Run this command from the installed skill directory or point Python at the script.

```text
python scripts/check.py path/to/capture.json
```

Fix the incoming hold offset when the visible prop jumps. A matching point with a bad angle means the mount rotation is wrong. Check for duplicate visible props around the handoff in playback.
