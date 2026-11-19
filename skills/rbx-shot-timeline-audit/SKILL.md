---
name: rbx-shot-timeline-audit
description: Find timeline gaps, overlaps, and shot ranges outside a cutscene for Roblox development using captured measurements or traces.
---

# Find timeline gaps, overlaps, and shot ranges outside a cutscene

Export shot start and end in a single timeline clock. Record the expected sequence start and end and the time tolerance. This audit treats the shot list as a contiguous edit with one camera shot per instant.

Copy [the working input fixture](references/example.json) and replace the example values with your capture. Run this command from the installed skill directory or point Python at the script.

```text
python scripts/check.py path/to/capture.json
```

A gap means the edit has no owner at that time. An overlap means two authored shots claim the same time. Deliberate dissolves should be represented as their own shot range or checked separately in the actual editor.
