---
name: rbx-stair-profile
description: Check measured risers, treads, and landings for Roblox development using captured measurements or traces.
---

# Check measured risers, treads, and landings

Measure consecutive tread elevations and horizontal depths along the actual stair run. Supply the largest riser, shallowest tread, and largest allowed change between neighboring risers. Choose thresholds with the target avatar.

Copy [the working input fixture](references/example.json) and replace the example values with your capture. Run this command from the installed skill directory or point Python at the script.

```text
python scripts/check.py path/to/capture.json
```

Fix the exact step reported, then walk the flight in both directions at normal speed. The check measures authored geometry and leaves collision and controller behavior to Studio.
