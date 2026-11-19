---
name: rbx-route-progression
description: Find unreachable objectives in a gated map for Roblox development using captured measurements or traces.
---

# Find unreachable objectives in a gated map

Walk the current blockout and list zones and directed connections in `edges`. Give each connection a `requires` key list. Use `grants` only for permanent keys obtained on entering a zone.

Copy [the working input fixture](references/example.json) and replace the example values with your capture. Run this command from the installed skill directory or point Python at the script.

```text
python scripts/check.py path/to/capture.json
```

The search follows reachable zone and key combinations. A goal with no path needs a changed route or earlier key. Add one-way drops as one directed edge. Temporary keys and multiplayer puzzles require a playtest.
