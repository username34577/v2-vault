# Roblox development skills for Claude

This ZIP contains 55 skills. Each has a scoped job, a runnable tool, and a sample input or capture instructions. Most accept JSON measurements or a log from a test run. Use the skills that match the feature you are editing. Continue using your existing Roblox plugin, quality review, and Blender setup.

## Start here

- **Reference build or map detail.** Start with reference coverage. Add the map kit audit only if the build uses modular seams. Use the map tools for measured player routes, progression gates, and scenery placement.
- **Animation.** Start with motion breakdown and its animation workbench. It explains timing, easing, pitch, yaw, roll, weight, and advanced layering. Use the separate diagnostics for phase timing, feet, loops, blending, props, and synced FX.
- **Hair.** Start with the volume envelope and its hair workbench. Measure the main hair mass on the target head, then use lock shape to check thickness and taper, and scalp fit to inspect the mount on actual heads.

To audit a feature, ask Claude to collect actual inputs from the project, run the matching tool, and show or link the output. Each tool returns 0 for a clean result, 1 for findings, and 2 for invalid input. A passing fixture demonstrates the script. A task passes only for the actual inputs, recorded frames, or traces.

## Installation

- **Claude Code.** Extract the ZIP and copy only the desired folders from `skills/` into the project's `.claude/skills/` directory. Keep each skill's scripts and references with it. [Claude Code skill setup](https://code.claude.com/docs/en/skills)
- **Claude web or desktop.** To install a custom skill, compress its folder as an individual ZIP with that folder at the ZIP root, then upload under **Customize → Skills**. [Claude custom skill setup](https://support.claude.com/en/articles/12512198-how-to-create-custom-skills)
- **Requirements.** Python 3.8 or newer. The texture preview also uses Pillow. The hair geometry sampler runs inside Blender. Studio capture, import, and playtests require access to the actual test project.

Example for Claude

> Use the motion breakdown skill on this clip. Mark the contact phases, compare torso pitch/yaw/roll, hip height, hand height, and root travel from matching samples, then render the curve report. Fix the biggest unintended difference and rerun it with the same sample definitions.

## Skill index

### Reference matching

- [rbx-reference-coverage](skills/rbx-reference-coverage/SKILL.md) — Compare screenshots and flag missing features or drifting landmarks.

### Map building

- [rbx-map-kit-audit](skills/rbx-map-kit-audit/SKILL.md) — Measure gap, facing, and twist at paired seams.
- [rbx-route-progression](skills/rbx-route-progression/SKILL.md) — Find unreachable objectives in a gated map.
- [rbx-stair-profile](skills/rbx-stair-profile/SKILL.md) — Check measured risers, treads, and landings.
- [rbx-route-clearance](skills/rbx-route-clearance/SKILL.md) — Find the tightest avatar clearance along a route.
- [rbx-spawn-travel-balance](skills/rbx-spawn-travel-balance/SKILL.md) — Compare spawn-to-objective travel times.
- [rbx-checkpoint-recovery](skills/rbx-checkpoint-recovery/SKILL.md) — Verify checkpoint spawn and restored route state.
- [rbx-landmark-sightlines](skills/rbx-landmark-sightlines/SKILL.md) — Measure landmark visibility from route decision points.
- [rbx-prop-support-audit](skills/rbx-prop-support-audit/SKILL.md) — Check for floating or buried set dressing at its support points.
- [rbx-streaming-reentry](skills/rbx-streaming-reentry/SKILL.md) — Detect missed bindings across streamed area reentry.

### Cinematics

- [rbx-cutscene-cue-audit](skills/rbx-cutscene-cue-audit/SKILL.md) — Find missing, duplicated, and mistimed authored or observed cues.
- [rbx-shot-timeline-audit](skills/rbx-shot-timeline-audit/SKILL.md) — Find timeline gaps, overlaps, and shot ranges outside a cutscene.
- [rbx-screen-direction-audit](skills/rbx-screen-direction-audit/SKILL.md) — Flag screen-direction reversals across continuity cuts.
- [rbx-foot-plant-drift](skills/rbx-foot-plant-drift/SKILL.md) — Measure foot sliding during an intended planted interval.
- [rbx-animation-loop-seam](skills/rbx-animation-loop-seam/SKILL.md) — Measure pose and velocity jumps at an animation loop seam.
- [rbx-rig-channel-coverage](skills/rbx-rig-channel-coverage/SKILL.md) — Find animation tracks that do not bind to the target Roblox rig.
- [rbx-prop-handoff-audit](skills/rbx-prop-handoff-audit/SKILL.md) — Find pose or grip jumps when a cutscene prop changes owner.
- [rbx-effect-window-audit](skills/rbx-effect-window-audit/SKILL.md) — Catch active trails or emitters that survive an interrupted action.

### VFX

- [rbx-vfx-texture-preflight](skills/rbx-vfx-texture-preflight/SKILL.md) — Preview atlases and catch opaque, empty, or incorrectly divided cells.
- [rbx-particle-peak-budget](skills/rbx-particle-peak-budget/SKILL.md) — Estimate peak live particles under overlapping bursts.
- [rbx-vfx-cue-legibility](skills/rbx-vfx-cue-legibility/SKILL.md) — Audit which important visual cues survive low-quality settings.
- [rbx-impact-grounding](skills/rbx-impact-grounding/SKILL.md) — Check that effects sit on the intended surface after contact.
- [rbx-beam-span-continuity](skills/rbx-beam-span-continuity/SKILL.md) — Find gaps or width pops between visible Beam segments.
- [rbx-vfx-screen-overlap](skills/rbx-vfx-screen-overlap/SKILL.md) — Measure how much of a critical target an effect covers on screen.

### Modeling

- [rbx-import-calibration](skills/rbx-import-calibration/SKILL.md) — Detect mesh scale and facing changes during Roblox import.
- [rbx-pivot-sweep](skills/rbx-pivot-sweep/SKILL.md) — Catch moving mesh pivots that slide or rotate off axis.
- [rbx-uv-texel-density](skills/rbx-uv-texel-density/SKILL.md) — Detect inconsistent texel density across neighboring surface groups.
- [rbx-material-bindings](skills/rbx-material-bindings/SKILL.md) — Find missing or crossed material maps after import.
- [rbx-wearable-pose-clearance](skills/rbx-wearable-pose-clearance/SKILL.md) — Find wearable clipping specific to avatar and pose.
- [rbx-asset-access-matrix](skills/rbx-asset-access-matrix/SKILL.md) — Identify assets that fail under normal player access.

### Gameplay

- [rbx-round-transition-audit](skills/rbx-round-transition-audit/SKILL.md) — Detect illegal or stale round phase transitions.
- [rbx-character-resource-lifetime](skills/rbx-character-resource-lifetime/SKILL.md) — Find resources that survive their owning character generation.
- [rbx-replication-audience](skills/rbx-replication-audience/SKILL.md) — Audit who actually receives shared or private gameplay state.
- [rbx-movement-course](skills/rbx-movement-course/SKILL.md) — Measure motion feel with repeatable course splits and stopping distances.
- [rbx-npc-stuck-recovery](skills/rbx-npc-stuck-recovery/SKILL.md) — Find NPCs that stay stuck too long before recovering.
- [rbx-interaction-cardinality](skills/rbx-interaction-cardinality/SKILL.md) — Catch duplicate or lost gameplay commits from a single action.
- [rbx-camera-handoff-audit](skills/rbx-camera-handoff-audit/SKILL.md) — Check control restoration after camera ownership changes.
- [rbx-hit-feedback-agreement](skills/rbx-hit-feedback-agreement/SKILL.md) — Catch visible hit feedback that disagrees with confirmed outcomes.

### UI and audio

- [rbx-ui-hit-bounds](skills/rbx-ui-hit-bounds/SKILL.md) — Find controls that leave a safe area or collide with another target.
- [rbx-gamepad-focus-paths](skills/rbx-gamepad-focus-paths/SKILL.md) — Find unreachable gamepad controls and focus traps.
- [rbx-localized-text-fit](skills/rbx-localized-text-fit/SKILL.md) — Flag actual text overflow across locales and text-size settings.
- [rbx-ui-contrast-audit](skills/rbx-ui-contrast-audit/SKILL.md) — Measure contrast for text and state cues on rendered backgrounds.
- [rbx-spatial-audio-range](skills/rbx-spatial-audio-range/SKILL.md) — Find gameplay sounds that carry too far or vanish too early.
- [rbx-audio-peak-audit](skills/rbx-audio-peak-audit/SKILL.md) — Measure peak signal and clipped sample counts in a gameplay audio file.

### Performance

- [rbx-frame-time-regression](skills/rbx-frame-time-regression/SKILL.md) — Compare repeatable frame-time captures before and after a change.
- [rbx-instance-retention-audit](skills/rbx-instance-retention-audit/SKILL.md) — Detect steady instance growth after repeated gameplay cycles.

### Advanced animation

- [rbx-motion-breakdown](skills/rbx-motion-breakdown/SKILL.md) — Break an animation into comparable motion curves.
- [rbx-animation-phase-retime](skills/rbx-animation-phase-retime/SKILL.md) — Plan retiming around planted contacts and motion landmarks.
- [rbx-curve-easing-audit](skills/rbx-curve-easing-audit/SKILL.md) — Check sampled animation easing for hard edges, overshoot, and abrupt speed changes.
- [rbx-animation-layer-conflicts](skills/rbx-animation-layer-conflicts/SKILL.md) — Find unintended joints claimed by simultaneous animation layers.
- [rbx-dual-rig-contact](skills/rbx-dual-rig-contact/SKILL.md) — Check maintained contacts between actors or props across a choreography window.
- [rbx-locomotion-rate-fit](skills/rbx-locomotion-rate-fit/SKILL.md) — Check in-place locomotion playback rate against actual movement speed.

### Hair modeling

- [rbx-hair-volume-envelope](skills/rbx-hair-volume-envelope/SKILL.md) — Measure hairstyle mass against calibrated front, side, and top references.
- [rbx-hair-lock-shape](skills/rbx-hair-lock-shape/SKILL.md) — Catch paper-thin locks and kinked tapers in sculpted hair.
- [rbx-hair-scalp-fit](skills/rbx-hair-scalp-fit/SKILL.md) — Find scalp gaps, penetration, and missing fit checks on supported heads.
