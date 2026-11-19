---
name: rbx-animation-phase-retime
description: Plan retiming around planted contacts and motion landmarks for Roblox development using captured measurements or traces.
---

# Plan retiming around planted contacts and motion landmarks

List corresponding source and target event times in order, including a selected start and end. Use distinctive anchors such as left contact, toe-off, right contact, and recovery. Choose a sensible stretch band for that motion.

Copy [the working input fixture](references/example.json) and replace the example values with your capture. Run this command from the installed skill directory or point Python at the script.

```text
python scripts/check.py path/to/capture.json
```

Each segment reports target duration divided by source duration. A very compressed segment usually needs changed contact timing or new poses. Keep the anchor order monotonic and resample with the approved mapping before comparing motion curves.
