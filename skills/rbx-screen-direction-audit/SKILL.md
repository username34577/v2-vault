---
name: rbx-screen-direction-audit
description: Flag screen-direction reversals across continuity cuts for Roblox development using captured measurements or traces.
---

# Flag screen-direction reversals across continuity cuts

For a moving subject, measure start and end x positions within the end of the outgoing shot and onset of the incoming shot. Normalize to frame width. Mark intentional reversals or neutral cutaways with `allow_reverse`.

Copy [the working input fixture](references/example.json) and replace the example values with your capture. Run this command from the installed skill directory or point Python at the script.

```text
python scripts/check.py path/to/capture.json
```

A sign flip on meaningful displacement flags a possible axis crossing. Check acting intent alongside the matched footage. A nearly stationary sample says little about direction.
