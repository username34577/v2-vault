---
name: rbx-hair-lock-shape
description: Catch paper-thin locks and kinked tapers in sculpted hair for Roblox development using captured measurements or traces.
---

# Catch paper-thin locks and kinked tapers in sculpted hair

For each broad lock, sample root, belly, pre-tip, and optionally tip stations. Measure width and thickness in the plane perpendicular to its centerline, plus the centerline position. Mark intentionally pointed tips. Select a thickness-to-width floor and maximum bend based on the reference and style.

Copy [the working input fixture](references/example.json) and replace the example values with your capture. Run this command from the installed skill directory or point Python at the script.

```text
python scripts/check.py path/to/capture.json
```

If a lock is too thin across its body, round the profile or thicken the volume before beveling. Keep the widest or deepest section where the strand gathers mass. A late taper can end in a deliberate point. Check curves and silhouette from several views, especially the underside and profile.

Use the hair modeling workbench in `rbx-hair-volume-envelope` for cap, mass, lock, and fit construction.
