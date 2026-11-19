---
name: rbx-material-bindings
description: Find missing or crossed material maps after import for Roblox development using captured measurements or traces.
---

# Find missing or crossed material maps after import

Record required channel-to-asset IDs per named mesh or material slot in `expected`. Read the actual bound values from Studio for those same identifiers. Use the same identifier format in both captures.

Copy [the working input fixture](references/example.json) and replace the example values with your capture. Run this command from the installed skill directory or point Python at the script.

```text
python scripts/check.py path/to/capture.json
```

Follow the reported mesh and channel back to its export or binding step. Check the final asset in light that reveals changes in normals and roughness. This compares assignments and leaves source pixels and permissions to separate checks.
