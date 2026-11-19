---
name: rbx-landmark-sightlines
description: Measure landmark visibility from route decision points for Roblox development using captured measurements or traces.
---

# Measure landmark visibility from route decision points

From a representative player camera, sample rays toward distinct parts of the objective silhouette. Record how many first hits were the landmark or an explicitly allowed transparent surface was ignored. Group observations by decision point.

Copy [the working input fixture](references/example.json) and replace the example values with your capture. Run this command from the installed skill directory or point Python at the script.

```text
python scripts/check.py path/to/capture.json
```

A low fraction identifies where scenery or placement hides guidance. Move the blocking object or reframe the cue, then repeat from the same path station. This measures occlusion at sampled points and does not establish that players recognize the landmark.
