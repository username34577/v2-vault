---
name: rbx-localized-text-fit
description: Flag actual text overflow across locales and text-size settings for Roblox development using captured measurements or traces.
---

# Flag actual text overflow across locales and text-size settings

Capture measured text bounds and the inner content rectangle for each required locale, viewport, and label. Measure after layout with the intended font and accessibility setting. Write the case names into `required`.

Copy [the working input fixture](references/example.json) and replace the example values with your capture. Run this command from the installed skill directory or point Python at the script.

```text
python scripts/check.py path/to/capture.json
```

Width failures often need wrapping or a wider column. Height failures after wrapping usually require flexible height. Review actual text for clipping versus deliberate truncation and capture both the baseline and expanded locale.
