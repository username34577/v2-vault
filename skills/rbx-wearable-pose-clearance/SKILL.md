---
name: rbx-wearable-pose-clearance
description: Find wearable clipping specific to avatar and pose for Roblox development using captured measurements or traces.
---

# Find wearable clipping specific to avatar and pose

Capture the same accessory across the supported body and pose matrix. Record conservative clearance between the problem surfaces, using positive values for separation and negative for penetration. Add your allowed intentional overlap to `min_clearance` as a negative threshold where appropriate.

Copy [the working input fixture](references/example.json) and replace the example values with your capture. Run this command from the installed skill directory or point Python at the script.

```text
python scripts/check.py path/to/capture.json
```

Fix the highest-penetration case first by adjusting mount placement or the model at the specific contact. Recheck the neutral pose after fixing an action pose. This audits recorded samples and relies on the measurement method for accuracy.
