---
name: rbx-uv-texel-density
description: Detect inconsistent texel density across neighboring surface groups for Roblox development using captured measurements or traces.
---

# Detect inconsistent texel density across neighboring surface groups

From the DCC UV editor or a mesh measurement export, record summed UV face area, corresponding world surface area in square studs, and texture dimensions. Use absolute UV area and select related surfaces with a shared intended density.

Copy [the working input fixture](references/example.json) and replace the example values with your capture. Run this command from the installed skill directory or point Python at the script.

```text
python scripts/check.py path/to/capture.json
```

Compare the estimated pixels per stud to the chosen target. Correct UV scale on outliers before rebuilding texture detail. The result is an area-based average and stretched islands still need visual inspection.
