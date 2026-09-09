# Settings, icons and Today refinement — 2026-09-08

## Task card

Founder approved: simplify Settings language/grouping, unify functional icons,
then reduce excess Today spacing. Additional deliverable: Figma comparison.

Scope: presentation and English/Traditional/Simplified Chinese copy. Preserve
existing dirty Block Lists work, routes, stores, permission, PIN, timer and
shielding behavior. No commit, push, release or physical-device installation.

Acceptance: grouped Settings links remain reachable; app-list template semantics
are explicit; icons remain labeled with >=44pt controls; Today retains the living
landscape, primary action and secondary destinations; two visual passes, compact
and large-text checks plus relevant existing UI regression tests.

Figma: https://www.figma.com/design/YVb5HQM2cT06hElefy7ug0?node-id=1-2
Evidence: `/Volumes/External SSD 4TB/DeveloperData/MoriSettingsRefinement`.
Pre-existing tracked diff and the Block Lists view are preserved under `before/`.

## Design decisions

- Group App Limits and Block Lists under App use; Life Grid, Reminders and
  Language under Personal preferences; App and Data and About under Data and about.
- App Limits uses one compact linked row with live state, not an introductory card
  containing a second apparent button. Links retain their original destinations.
- Settings rows use scalable body/subheadline text with wrapping.
- Typed `MoriInterfaceIcon` renders monochrome SF Symbols for settings and root
  navigation. The source bitmap artwork and symbols elsewhere remain intact.
- Today landscape aspect ratio changes from 1.5 to 1.8 (about 17% less height);
  the separate accessibility-size ratio remains 3.2. Quiet-summary top padding
  changes from 18 to 8pt. Landscape rendering/motion gates do not change.

## Verification

- Simulator builds passed (`build-pass1.log`, `build-pass2.log`). An initial
  placement of the new icon view in Shared failed in the widget target; moving
  it into app-only `MoriActionComponents.swift` resolved that dependency.
- Pass 1 inspected Traditional Chinese Today, Settings and App Limits on iPhone
  17e. It exposed centered wrapped row text and a cropped tree crown.
- Pass 2 fixes row alignment and pins only Today artwork to its top edge. The
  default artwork alignment remains centered for other consumers. Inspected all
  three final captures in `after/`; Figma contains both before and after images,
  with editable notes. The Figma render was inspected for missing/clipped content.
- Block Lists create/rename/cancel/delete/relaunch and Traditional Chinese XXXL
  tests passed (2 tests in `regression.xcresult`). The English navigation tests
  initially inherited the prior Chinese app-language setting: the failure tree
  showed Chinese buttons where the test expected English. The existing test
  launch helper now sets the app locale explicitly. Both navigation tests pass
  in `navigation-rerun.xcresult` (three roots and Today status/quiet details).
- Largest accessibility size: Today primary action can be reached by scrolling;
  Settings first rows wrap without truncation. Full lower Settings navigation
  at that largest size was not verified through CUA; the separate XXXL Block
  Lists navigation test passed. This is not a full VoiceOver audit.
- English, Traditional and Simplified Chinese catalogs pass `plutil -lint`;
  `git diff --check` passes. No functional stores or protection behavior changed.
- No physical-device install, Screen Time enforcement QA, commit, push or release.
