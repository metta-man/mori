# Quiet countdown refinement — 2026-09-09

## Scope

Founder-approved: Before Feed guided progress uses remaining complete breaths;
other in-app countdowns become visually quieter. Runtime durations, immutable
Before Feed configuration, completion gates, app limits and persistence remain
unchanged. Follow-your-own remains a duration timer, not measured respiration.

Large paper timers use sage (#728478); smaller/supporting time and numbers over
watercolor use muted stone (#69716C). Before Feed breath count uses body stone
(#4D5650) over the bloom. Increased Contrast restores forest ink for softened
timers. Dark Room keeps the user's dim control and uses lighter font weight and
lower base luminance. Existing phase cues, VoiceOver time values and controls
remain available; guided Before Feed VoiceOver describes phase and breath count.

Affected surfaces: guided/own Before Feed, Morning Reset, breathing phase and
session time, Deep Session, Quiet Mode, Settle timer/card, manual practice timer,
and shared Dark Room. Widgets and watchOS are outside this in-app change.

## Visual refinement

Compared to DesignReferences/mori-approved-reference.jpeg and its current
living-landscape amendment. Retained paper, art, routes and compositions.

1. Captured installed Before Feed baseline; replaced the dominant seconds with
   supporting breath count and applied quieter timer colors. Inspected Before
   Feed guided/own and Deep Session running/paused test attachments.
2. Made guided inhale/exhale the stronger cue (22pt), kept breath count secondary,
   and used darker supporting ink over watercolor to protect legibility. Reviewed
   Traditional Chinese and compact captures plus breathing, Deep Session, Quiet,
   Morning, Settle, manual practice and Dark Room surfaces.

Token contrast spot checks: sage on paper 3.54:1 (large text); muted stone on
sampled bloom #DAD6C2 3.44:1 (large text); body stone on the same bloom 5.20:1
(small breath count). These are spot checks, not exhaustive animated-pixel audits.

## Verification

- Simulator build passed on iOS 26.5.
- 35 MoriRoutingTests passed, including complete/fractional breath boundaries and
  the existing Before Feed gate/configuration/persistence tests.
- Five focused UI tests passed: default guided, configured guided, own-breath,
  live remaining-count pause/resume/completion, and Deep Session pause/resume/end.
- An initial multi-surface rerun assumed every timer relaunches idle and failed
  on a restored Quiet timer. The harness now accepts legitimate running/paused
  restoration instead of clearing timer data.
- Additional multi-surface UI test passed for Quiet, Settle, Morning and manual
  practice timers, including pause actions and screenshot attachments.
- Design direction source gate passed; git diff --check passed.

Artifacts: /Volumes/External SSD 4TB/DeveloperData/Mori-quiet-timers-qa/
(final.xcresult and surfaces-verified.xcresult plus exported screenshots).

Physical device, FamilyControls enforcement, audio/haptics and subjective
reduction in pressure are not established by simulator tests. No commit, push,
physical-device install or release was performed. Preserved the pre-existing
MoriWatch.xcscheme working-tree edit.
