---
name: rbx-hair-scalp-fit
description: Find scalp gaps, penetration, and missing fit checks on supported heads for Roblox development using captured measurements or traces.
---

# Find scalp gaps, penetration, and missing fit checks on supported heads

On each target head, sample signed separation along the scalp normal at named intended contact sites. Positive is lift from scalp and negative is penetration. Use regional allowed bands for the hairline, temple, crown, and nape. Omit designed open fringe from the contact set and call it out.

Copy [the working input fixture](references/example.json) and replace the example values with your capture. Run this command from the installed skill directory or point Python at the script.

```text
python scripts/check.py path/to/capture.json
```

A cluster of high gaps points to the cap or mount. A local negative gap near temple or ear suggests trimming clearance. Check the front hairline at player height and retest all required head variants after moving the mount.

Use the hair modeling workbench in `rbx-hair-volume-envelope` for cap, mass, lock, and fit construction.
