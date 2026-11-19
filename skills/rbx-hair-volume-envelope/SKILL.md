---
name: rbx-hair-volume-envelope
description: Measure hairstyle mass against calibrated front, side, and top references for Roblox development using captured measurements or traces.
---

# Measure hairstyle mass against calibrated front, side, and top references

Align head origin and axes using shared landmarks. Where possible calibrate against known head width or height in two views. Sample the outer hair mass at named sections such as crown, temple, and nape. Record width, depth, and height with the same definitions on the model. Use a measured design target when a reference cannot establish depth.

Copy [the working input fixture](references/example.json) and replace the example values with your capture. Run this command from the installed skill directory or point Python at the script.

```text
python scripts/check.py path/to/capture.json
```

A missing or thin side-view section flags a flat shell even when the front silhouette looks right. Adjust the cap and biggest volumes before adding locks. Review front, profile, and three-quarter views in neutral light. Cross-section measurements supplement the visual silhouette and leave strand detail for a separate check.

Use the [hair modeling workbench](references/hair-modeling-workbench.md) to block large shapes and collect head-space measurements with the Blender section sampler.
