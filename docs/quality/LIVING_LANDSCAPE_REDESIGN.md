# Mori living landscape redesign

## Task card

- Intent: sitting in meadow grass beside one tree and a pond, with local organic
  movement. Keep Today / Focus / Log and all existing functionality.
- Scope: iPhone Today, Focus modes, running/paused/completed sessions, breathing,
  Before Feed, Log, Life Grid, and utility backgrounds.
- Preserve: stores, preferences, FamilyControls, DeviceActivity, shielding,
  PIN/recovery transaction flow, deep links, existing routes and audio semantics.
- Exclude: watchOS, widgets, web, onboarding redesign, data migrations, release.
- Acceptance: reachable actions, readable calm surfaces, two visual refinement
  passes, native regression tests, isolated simulator evidence. Device Screen
  Time enforcement and power/thermal measurements require physical QA.

## Art provenance

Generated with the built-in imagegen tool; original outputs remain in Codex's
2026-09-05 generated-images directory. Project assets live at
`DesignSystem/MoriBackgrounds.xcassets/MoriMeadow{Trunk,Crown,Reference}.imageset`.
The reference is also saved as `DesignReferences/mori-living-landscape-reference.png`.

Prompt set:
1. Wide 3:2 botanical watercolor on warm ivory paper: view from sitting in meadow
   grass beside a pale sage pond, gracious deciduous tree at right, distant hills,
   open sky at left, restrained Japanese editorial brushwork; no UI/text/people.
2. Edit the same image to remove the large tree's foliage, preserving its trunk,
   branches, meadow, pond, framing and paper texture as a registered base layer.
3. Extract only the tree crown onto a transparent PNG at the same registration,
   removing all other scenery; preserve watercolor leaf texture.

Two crown masks move at different slow rates around branch anchors. The base
painting stays fixed. Canvas draws a small number of pond strokes and grass tips;
no particle simulation, 3D engine, camera movement, or extra environment audio.

## Verification

Evidence directory: `/Volumes/External SSD 4TB/DeveloperData/MoriLivingLandscape`.

- Signed simulator build and final targeted test run: **PASS**
  (`final-verification.xcresult`, iPhone 17e, iOS 26.5).
- 66 unit tests passed, including independent motion suppression for Reduce
  Motion, low power, inactive scene, visibility and the animation preference.
- All 3 new UI tests passed: Today / Focus / Log navigation and support disclosure;
  Deep Session pause / resume / end; actual system Reduce Motion activation and
  identical landscape PNG pixels across screenshots taken three seconds apart.
- All 13 existing UI regressions passed in `signed-regression.xcresult` on
  iPhone 17 Pro: PIN transaction cases, granular deletion, Before Feed variants,
  guided Log save/restore and recovery entry. That earlier bundle has one failed
  new test due to Settings launch; it is superseded by the green targeted run.
  Together the two signed runs cover 66 unit and 16 distinct UI tests passing;
  they are not one all-green full-suite bundle.
- XcodeGen 2.45.4 regeneration is byte-for-byte idempotent. `git diff --check`
  and all three edited localization plist checks pass.
- Two visual refinement passes and final standard/compact/large-type captures
  completed. Simulator-only verification; no release, commit or physical-device
  installation was performed.

Physical Screen Time enforcement, phone/audio interruptions, actual low-power
energy/thermal behavior and manual VoiceOver traversal remain device QA work.
The unit policy test does not establish physical energy savings or frame rate.

## Visual refinement log

- Pass 1 (`pass1/`): captured Today, Focus, Log, running Deep Session, Before Feed,
  Life Grid, Settings and Quiet Mode. Reviewed against the watercolor reference
  and original editorial hierarchy. Found a repeated root tree and hard image
  joins; removed the duplicate root illustration and feathered the hero edges.
- Pass 2 (`pass2/`): captured ten core destinations. Replaced repeated Focus mode
  paintings with two compact secondary entries, strengthened the primary card's
  text clearance, blended Log/Deep Session edges and used the meadow in Life Grid.
- Compact/device-size pass (`compact-final/`, iPhone 17e): retained all primary
  actions and scrolling. Removed the Quiet Mode duplicate background, moved its
  timer into clear paper, and removed the small primary-card top seam.
- Large type pass (`accessibility-pass1/`): system accessibility XX-large category.
  Text grows and scrolls; reduced Today art height and increased the mode-card
  paper wash for accessibility sizes. Some early scripted captures caught launch
  transitions and are not accepted evidence. `accessibility-final/` contains
  settled recaptures; Today, Focus and Log were inspected for text wrapping and
  contrast. Content remains scrollable and the compact device's text size was
  restored after capture.
- Final standard captures (`final-standard/`) include ten destinations after the
  last refinements. Today retains its protection/setup status; the Focus primary
  card has no top seam; Quiet's timer stays in clear paper above the landscape.
- Final Essential refinement replaces both remaining forest hero images with the
  registered meadow and removes the duplicate page illustration. Setup stays
  still; the active fixture uses local landscape motion. This presentation-only
  follow-up passed a signed build (`build-delivery.log`) after the test runs;
  `final-standard/essential.png` and `essential-active.png` cover both states.
- Motion preview: `living-landscape-motion.mp4`. Frames 2 and 10 seconds were
  inspected. Crown motion is local; trunk and camera remain fixed. Pixel-change
  analysis is descriptive only because H.264 encoding also changes static pixels.

## Test environment correction

The first unsigned simulator run passed 66 unit tests. Its PIN UI commit did not
complete; that build omitted the simulated application entitlements. The run was
stopped and superseded by a standard Xcode simulator signing run ("Sign to Run
Locally"). No physical-device signing, user keychain data, PIN store implementation, or
lock behavior was changed. A new navigation test also initially queried a semantic mode button as
static text; its selector was corrected before rerunning.

The signed simulator run subsequently passed all three Accountability PIN UI
cases (cancellation, incomplete acknowledgements, and confirmed commit/relaunch)
and granular deletion UI. This supports the missing-entitlement diagnosis of the
unsigned run; the production transaction implementation remains untouched.

The new system Reduce Motion test initially hit Settings cold-launch timeout,
then revealed that tapping the accessibility row had not switched the control.
The test now taps the switch itself and verifies value `1` before comparing the
landscape. It passed in the final signed run, including restoring the initial
system setting. No production workaround was added for the test-harness issue.
