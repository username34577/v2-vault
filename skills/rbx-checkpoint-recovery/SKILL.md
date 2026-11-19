---
name: rbx-checkpoint-recovery
description: Verify checkpoint spawn and restored route state for Roblox development using captured measurements or traces.
---

# Verify checkpoint spawn and restored route state

Play from the normal entrance, activate each affected checkpoint, then die or reset. Record the actual spawn and unlocked route identifiers alongside the expected values. Include a case where a checkpoint was visible but never activated.

Copy [the working input fixture](references/example.json) and replace the example values with your capture. Run this command from the installed skill directory or point Python at the script.

```text
python scripts/check.py path/to/capture.json
```

Sort the issues by wrong spawn, lost route unlocks, and unintended unlocks. Reproduce at the named death point. Rejoin recovery is a separate case from immediate respawn.
