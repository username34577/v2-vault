---
name: rbx-pivot-sweep
description: Catch moving mesh pivots that slide or rotate off axis for Roblox development using captured measurements or traces.
---

# Catch moving mesh pivots that slide or rotate off axis

In Studio, record the position and rotation-axis direction of a marked pivot at the start, midpoint, and end of a full hinge or rotation. Keep all measurements in the same parent space so moving assemblies can be compared.

Copy [the working input fixture](references/example.json) and replace the example values with your capture. Run this command from the installed skill directory or point Python at the script.

```text
python scripts/check.py path/to/capture.json
```

A drifting position suggests a bad rotation center. An axis error suggests a mismatch between the authored rig and attachment frames. Validate contact and collision over the same sweep in Studio.
