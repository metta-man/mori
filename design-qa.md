# Mori Log reference rebuild — Design QA (2026-07-21)

## Comparison target

- Approved visual source: `DesignReferences/mori-approved-reference.jpeg`, Log panel at the upper left.
- Written source of truth: `DesignReferences/MORI_DESIGN_SPEC.md`.
- Normalized 430 × 932 reference: `artifacts/mori-log-redesign-20260721/reference-log-normalized-430x932.png`.
- Final runtime capture from the final compiled source: `artifacts/mori-log-redesign-20260721/final-1290x2796.png` and `final-430x932.png`.
- Required same-canvas comparison: `artifacts/mori-log-redesign-20260721/comparison-final.png`.
- Focused comparisons: `comparison-header-final.png`, `comparison-form-final.png`, and `comparison-preview-dock-final.png`.
- Baseline and refinement evidence: `runtime-baseline-1290x2796.png`, `baseline-430x932.png`, `comparison-pass1.png` through `comparison-pass4.png`, and the corresponding pass captures.
- Accessibility evidence: `accessibility-extra-large-1290x2796.png`, `accessibility-extra-large-grid-1290x2796.png`, and `accessibility-extra-large-scrolled-1290x2796.png`.

## Viewport and state

- Native SwiftUI on the iPhone 15 Pro Max Mori QA simulator, iOS 26.5, 430 × 932 pt / 1290 × 2796 px, light appearance, Dynamic Type `large`.
- The production Log root was opened through `mori://log?source=deep_link` after launching with the existing UI-test onboarding bypass. The visible screen, actions, stores, navigation stack, and floating dock are production components rather than a static mock.
- The simulator has no saved mood or Log entry for today, but it does contain one real non-mood activity record. No state is fabricated: Save starts disabled and the preview truthfully reads `July · 1 day remembered` with one quiet sage cell.
- Final accessibility geometry at standard type: header Log x20/y66; Log actions and Settings each 44 × 44 pt at x306/y68 and x358/y68; mood choices each 109.3 × 97 pt; photo target 353 × 51 pt; Save 352 × 50 pt; visible Life Grid card x20/y665 at 390 × 177 pt; floating tab targets each 126 × 58 pt.

## Findings and complete visible-difference list

No actionable P0, P1, or P2 visual difference remains. The following visible differences are intentional or truthful P3 source/runtime variations:

- The concept illustrates `Good` selected, `July · 11 days remembered`, and a mixture of colored mood cells. The simulator has no current mood selection and one real non-mood activity day, so all three mood cards start unselected and the grid truthfully shows `July · 1 day remembered` with one pale-sage recorded cell.
- The concept uses a legacy edge-attached three-tab treatment. Production retains the separately approved premium floating 74 pt material dock with 18 pt gutters, 16 pt bottom reveal, and the canonical `Today`, `Focus`, and `Log` destinations.
- Native SF calendar, gear, photo, plus, tab, and status glyph strokes differ subtly from the photographed concept's painted or older-platform marks. Their size, alignment, hierarchy, and 44 pt targets match.
- The production mood faces use Mori's reusable native mood component. Their mouth/eye strokes are slightly cleaner than the hand-painted concept while the green/ochre/terracotta tone mapping and selected-state behavior match.
- Real watercolor paper and card textures have naturally different wet-edge contours and a slightly more opaque raised-paper surface. The warm paper, pale sage field, restrained border/shadow, and continuous top-safe-area wash match the approved composition.

No other obvious visible mismatch remains in the full or focused side-by-side comparisons.

## Required fidelity surfaces

- Top chrome: passed. The journal watercolor continues behind the native status bar; the default navigation bar, background, divider, and toolbar chrome remain hidden.
- Header: passed. The custom editorial serif Log title, support line, generous top breathing room, and two quiet circular actions match the approved coordinates and hierarchy.
- Entry card: passed. The panel spans x19–411 and y163–644 with a 20 pt radius, warm paper, subtle line and soft shadow. Mood heading/support copy, three 97 pt choices, sentence field, single-line optional-photo row, and 50 pt Save action align to the reference.
- Life Grid: passed. The former `More from your Log` disclosure is absent. A production-backed Life Grid card occupies x20/y665 at approximately 390 × 177 pt, uses a 10 × 3 rolling-day grid, a localized month summary, real mood tones, separately represented non-mood recorded days, and opens the existing Week Archive.
- Typography, copy, and color: passed. The visible root copy matches the approved reference; serif/sans hierarchy, forest ink, sage, ochre, terracotta, muted secondary text, and warm raised paper use the existing Mori system.
- Asset quality: passed. The screen uses the real journal botanical backdrop and card-paper wash with platform iconography; no placeholder image, emoji, handcrafted SVG, ASCII mark, or code-drawn watercolor substitute was added.
- Dock clearance: passed. The first viewport ends cleanly at the Life Grid and detached dock. Preserved secondary Log tools begin below the reserved dock clearance and remain scroll-reachable.

## Visible mismatch and automatic-refinement history

1. Baseline — the title was too small and high; the main panel was roughly 60 pt too short; mood controls were generic `+ / ○ / −` glyphs; the photo action wrapped into two lines; the primary action said `Done`; and the forbidden `More from your Log` row appeared instead of a Life Grid.
2. Pass 1 — introduced the editorial header, Mori face mood controls, exact single-line photo copy, `Save entry`, and a truthful 10 × 3 Life Grid. Remaining differences: the form was about 15 pt short, the preview sat about 22 pt high, its paper texture bled outside the corner mask, and secondary tools showed behind the dock.
3. Pass 2 — corrected note/photo/Save geometry and the main-card-to-preview rhythm. Remaining differences: the Life Grid card background still overflowed its intended bounds and lower content could enter the first viewport.
4. Pass 3 — clipped the preview texture, refined the disabled sage fill, and moved secondary content below the dock reserve. Remaining differences: the main card ended about 7 pt early and a small Daily Spark edge remained visible near the dock.
5. Pass 4 — matched the 644 pt panel bottom, 21 pt Life Grid gap, preview content offset, and 842 pt preview bottom; restored uninterrupted journal watercolor; added navigation-specific dock hiding for Week Archive; rebuilt, relaunched, and regenerated full and focused comparisons.
6. Final data-semantics refinement — independent review found that mood-only data could undercount remembered days. The preview now deduplicates Daily Spark, journal, mindful-action, settle-session, and habit dates; distinguishes a remembered non-mood day from a neutral mood; refreshes after Daily Spark and lifecycle reloads; and localizes the remembered-day label. The current-source build and comparisons were regenerated. No obvious actionable visual difference remains.

## Behavior, accessibility, scope, and verification

- Selecting `Good` on the running app changed the real form state and enabled `Save today's log`; Save starts disabled when neither mood nor note is present. No test entry was persisted into the clean comparison data.
- The existing note editor, six-photo PhotosPicker flow, photo removal, dual journal/habit persistence, haptics, difficult-day pattern prompt, previous-day logging, recent-entry opening, export/import, iCloud restore, app-limit lifecycle, and scene cleanup remain wired through the original screen/view model callbacks.
- Daily Spark, conditional Pattern details, Week Archive, Random memory, Log history, and Recent Log remain below the reference-matched first viewport. Accessibility-tree inspection and simulator scrolling confirmed their real controls remain enabled and reachable.
- Tapping Life Grid opened the existing Week Archive. The pushed detail now hides the root floating dock, and Back restored the Log root and dock.
- The preview deduplicates the same five dated source families used by Week Archive. Log observes Daily Spark, clarity-action, and settle-session counts and refreshes on journal/habit lifecycle events, so newly recorded days update without inventing a mood.
- VoiceOver exposes 44 × 44 pt header actions, three 109 × 97 pt mood buttons, a 353 × 51 pt photo action, a 352 × 50 pt Save action, one combined Life Grid label/value, and three 126 × 58 pt tab targets.
- At Dynamic Type `accessibility-extra-large`, the mood choices stack vertically, text wraps, the full form remains scrollable, the 10 × 3 grid remains inside its card, and all retained secondary tools remain readable and reachable without truncating their actions.
- Final build: `xcodebuild -project Mori.xcodeproj -scheme Mori -configuration Debug -destination 'platform=iOS Simulator,id=35FCA784-6B78-43A1-8BE6-B35CBAE64A0B' -derivedDataPath .codex-build/LogRedesignDerivedData build` → `** BUILD SUCCEEDED **`.
- English, Traditional Chinese, and Simplified Chinese remembered-day strings pass `plutil -lint`.
- The repository has no XCTest/UI-test target. Production-route simulator interaction, accessibility-tree inspection, Dynamic Type captures, full/focused reference comparisons, and the exact native build provide the proportionate regression evidence for this scoped redesign.
- `rg --fixed-strings 'More from your Log' Features DesignSystem` returns no production match, and `git diff --check` passes.
- Independent final re-review confirmed the composite remembered-day semantics, truthful non-mood rendering, refresh paths, build correctness, and preservation of all reviewed Log actions; it found no remaining blocker.

final result: passed

---

# Mori active Deep Session reference rebuild — Design QA (2026-07-21)

## Comparison target

- Approved visual source: `DesignReferences/mori-approved-reference.jpeg`, active Deep Session panel at the lower right.
- Written source of truth: `DesignReferences/MORI_DESIGN_SPEC.md`.
- Normalized 430 × 932 reference: `artifacts/mori-active-deep-session-20260721/reference-active-normalized-430x932.png`.
- Final runtime capture from the final compiled source: `artifacts/mori-active-deep-session-20260721/runtime-final3-1290x2796.png` and `final3-430x932.png`.
- Required same-canvas comparison: `artifacts/mori-active-deep-session-20260721/comparison-final3.png`.
- Focused comparisons: `comparison-header-final3.png`, `comparison-ring-controls-final3.png`, and `comparison-panels-final3.png`.
- Interaction/accessibility evidence: `options-expanded-final-430x932.png`, `paused-final-430x932.png`, `accessibility-extra-large-430x932.png`, `accessibility-options-stacked-430x932.png`, and `accessibility-options-scrolled-430x932.png`.
- Baseline and iteration evidence: `comparison-baseline.png` and `comparison-pass1.png` through `comparison-pass7.png`.
- Task boundary and generated-asset record: `task-card.md` and `generated-asset-provenance.md` in the same artifact directory.

## Viewport and state

- Native SwiftUI on the iPhone 15 Pro Max Mori QA simulator, iOS 26.5, 430 × 932 pt / 1290 × 2796 px, light appearance, Dynamic Type `large`.
- Status time is fixed to 9:41. The native status bar remains over the artwork; no replacement status glyphs are drawn.
- The active view was reached through the production Focus → Deep Session route. A launch fixture only starts the real session clock automatically after the route opens.
- Comparison state is the first focus phase of the existing 25-minute Deep Session. The clock and progress marker remain live.
- The simulator has no configured Focus app selection, so the runtime truthfully reports `0 apps` and `No apps selected`.
- Final measured geometry: Back and overflow each 44 × 44 pt at y60; title y116.5; subtitle y158; timer visual 293.5 × 293.5 at x68.25/y198.25; Pause 66 × 66 pt at x182/y541; blocked panel 390.8 × 135.8 pt at x19.6/y631.6; options disclosure target 44 × 44 pt at x366/y807.7.

## Findings and complete visible-difference list

No actionable P0, P1, or P2 visual difference remains. The following visible differences are intentional, truthful P3 source/runtime variations rather than unfinished layout work:

- The photographed concept omits or predates the current Dynamic Island treatment. Runtime preserves the simulator's native Dynamic Island and current iOS signal, Wi-Fi, and battery glyphs.
- The reference freezes `24:53` with its illustrative progress dot near eight o'clock. Runtime shows the actual remaining time and corresponding live progress segment near the top of the ring; falsifying the clock to copy the still would break behavior.
- The reference illustrates four named app icons plus an add tile. The simulator has no selected apps, so runtime shows the real `0 apps` state with a neutral lock-shield tile and `No apps selected`; no app identity is invented.
- The watercolor is a purpose-made production raster with naturally different wet edges, individual tree silhouettes, and a slightly cooler mist layer. Its pale central corridor, side-framing conifers, foreground density, tall right tree, full-height crop, and bottom paper fade match the approved composition.
- The small runtime botanical mark is the closest platform leaf symbol; the reference uses a hand-painted sprig. Back/overflow strokes likewise have tiny platform-symbol differences while retaining the approved size and placement.

No other obvious visible mismatch remains in the full or focused side-by-side comparisons.

## Required fidelity surfaces

- Top chrome: passed. Paper and watercolor continue from the top pixel through the native status area and custom header. There is no navigation-bar background, material, divider, shadow line, or colour seam.
- Immersive composition: passed. The active screen is one full-bleed forest scene rather than a sheet, modal card, or image rectangle. The artwork continues behind the timer, Pause control, panels, and bottom breathing room.
- Header and typography: passed. Bare 44 pt Back/overflow targets, quiet botanical mark, 31 pt serif title, supporting subtitle, and large monospaced serif timer match the reference hierarchy.
- Timer and control: passed. The ring is approximately 288 pt with a restrained 5.5 pt track; the selected phase tint is deep forest green. Pause/Resume is an icon-only 66 pt raised-paper circle with a restrained shadow.
- Lower hierarchy: passed. The blocked-app panel is 135 pt high and the Session options row is 69 pt high, each with 390 pt width, 22 pt continuous corners, translucent warm paper, a low-opacity hairline, and soft shadow.
- Asset quality: passed. `MoriActiveDeepSessionValley.png` is a real 852 × 1846 raster generated with the built-in image-generation tool from the approved composition and Mori palette references. The production project contains no placeholder rectangle, emoji, ASCII mark, handcrafted SVG, or code-drawn landscape substitute.

## Visible mismatch and automatic-refinement history

1. Baseline — the active experience was a rounded sheet with a visible navigation strip, a square lake image with hard edges, no reference-sized ring, a compressed blocked summary, and a full-width dark Pause button. Session options and overflow were absent.
2. Pass 1 — introduced the full-screen composition, custom header, timer ring, circular control, blocked panel, and options row. Remaining differences: small bitmap control marks, weak title/time scale, an obvious top chrome transition, and the former landscape crop.
3. Pass 2 — replaced visible controls with appropriate platform symbols, corrected type and measured geometry, and connected the truthful blocked-app count. The top navigation/status handoff remained visible.
4. Passes 3–4 — tested navigation-background hiding and safe-area ownership. Native chrome was removed, but the upper art wash still changed too abruptly under the status area.
5. Pass 5 — added a measured warm-paper top wash over the continuous full-bleed asset. The visible divider/seam disappeared.
6. Pass 6 — refined art scale and bottom fade. The tall right conifer and foreground density were still vertically displaced.
7. Pass 7 — applied the final 1.16 crop, upward offset, and bottom paper fade. Header, ring, Pause, blocked panel, options row, tall conifer, and foreground now align with the approved coordinates.
8. Final refinement — replaced tiny option bitmaps with legible system symbols, gave `End quietly` a full 44 pt target, stacked expanded options at accessibility Dynamic Type to remove `Session…` truncation, restored the existing four-cycle default after independent review, rebuilt, relaunched, and recaptured the final full and focused comparisons.

## Behavior, accessibility, scope, and verification

- Pause freezes the real clock; Resume restarts it. The paused capture exposes a 66 pt Resume target and a 92 × 44 pt `End quietly` target without colliding with the blocked panel.
- Session options expands in place. Sound, Haptics, Animation, and Dark Room each expose a 44 × 44 pt control, update their real persisted setting, and were toggled off/on in the simulator. Dark Room enters and exits its preserved existing surface.
- Back opens the existing `End this Deep Session?` confirmation instead of silently discarding state. `End and leave` tears down the session and returns to the production Focus root.
- Existing clock, completion, sound/haptic feedback, App Limit start/end, DeviceActivity, ManagedSettings, persistence, and shield ownership remain in the detail/lifecycle coordinators; the redesign adds presentation and callback plumbing rather than a parallel session model.
- Back and overflow are 44 × 44 pt, Pause/Resume is 66 × 66 pt, End is 44 pt high, and option toggles are 44 × 44 pt. The timer and blocked selection expose combined spoken labels and real state values.
- At Dynamic Type `accessibility-extra-large`, the screen switches to a scroll layout. Title/support copy expand, the blocked summary wraps without clipping, and expanded options use two rows; a short scroll reveals all four controls at full size.
- Active-only scope guard passed. Task-start and final SHA-256 values are identical for `PomodoroPracticeSurfaces.swift` (`d367160b349d7a2c22d245305fac93c58bf854750ec794ac58654ef3da1fd662`), `PomodoroSetupViews.swift` (`2f89044432916a829a07c95955a3f0206dd1ba1b2978a346f6438fb2aa61db0c`), `PomodoroSettingsViews.swift` (`407a7b5d79f947f5138edee94f90e6edf776ae545f04916ce5e46ee2e6eb28a1`), `SettleView.swift` (`9b7e37f25ba829bd6dca62873de11144a07017d8d455c9121a9c9d7867b233a5`), `TodayView.swift` (`ce549c96c2ee1ac1326c970ef194dbb8fd7db15a7633382e23d39e8d5cd1b6d0`), and `App/ContentView.swift` (`8e695e518108854055d026d09cac6ad7a879f5ca17348d63ba75154cab3c8491`). Their unrelated pre-existing dirty diffs were preserved.
- Final build: `xcodebuild -project Mori.xcodeproj -scheme Mori -configuration Debug -destination 'platform=iOS Simulator,id=35FCA784-6B78-43A1-8BE6-B35CBAE64A0B' -derivedDataPath .codex-build/ActiveDeepSessionDerivedData build -quiet` → exit 0.
- The repository has no XCTest/UI-test target. Production-route simulator interaction, accessibility-tree geometry, state captures, and the exact native build provide the proportionate regression evidence for this scoped visual change.
- `git diff --check` passes.
- Independent final reviewer found no P0–P3 issue in the scoped active Deep Session candidate and returned `Pass` after verifying the restored four-cycle default and the setup-file baseline hashes.

final result: passed

---

# Mori Focus reference rebuild — Design QA (2026-07-21)

## Comparison target

- Approved visual source: `DesignReferences/mori-approved-reference.jpeg`, Focus panel.
- Written source of truth: `DesignReferences/MORI_DESIGN_SPEC.md`.
- Normalized 430 × 932 reference: `artifacts/mori-focus-redesign-20260721/reference-focus-normalized.png`.
- Final runtime capture: `artifacts/mori-focus-redesign-20260721/runtime-final-1290x2796.png` and `final-430x932.png`.
- Required same-canvas comparison: `artifacts/mori-focus-redesign-20260721/comparison-final.png`.
- Focused comparisons: `comparison-header.png`, `comparison-cards.png`, and `comparison-dock.png`.
- Baseline evidence: `baseline-focus.png`, `comparison-baseline-side-by-side.png`, and `comparison-baseline-difference.png`.
- Iteration evidence: `comparison-pass1.png` through `comparison-pass9.png`.

## Viewport and state

- Native SwiftUI on the iPhone 15 Pro Max Mori QA simulator, iOS 26.5, 430 × 932 pt / 1290 × 2796 px, light appearance, Dynamic Type `large`.
- Status time is fixed to 9:41 for comparison. The system status bar remains native; the modern simulator Dynamic Island is not recreated or hidden.
- Focus is the selected production root tab. The custom floating dock remains visible, and all cards use their real production actions.
- Final accessibility geometry: header title x29/y66, Settings 46 × 46 pt at x363/y66, Deep Session x24/y178.7 at 385 × 215 pt, Quiet Mode x24/y405.7 at 385 × 208 pt, and Offline Reset x24/y625.7 at 385 × 208 pt.

## Findings

No actionable P0, P1, or P2 visual difference remains in the Focus-owned composition.

- [P3] The photographed concept uses older status-bar hardware/chrome; the simulator truthfully retains the native Dynamic Island and current iOS status glyphs.
- [P3] The source panel shows the earlier edge-attached navigation treatment. Production retains the separately approved 74 pt floating material dock, 18 pt horizontal gutters, 16 pt bottom reveal, and canonical three destinations.
- [P3] Watercolor wet-edge contours are not pixel-identical. Production uses Mori's real forest-path and lake rasters; the three subjects, text-safe areas, tonal hierarchy, and crops match the reference composition.
- [P3] Quiet Mode is intentionally labelled `15 min` on the reference-matched root card while its preserved existing detail flow still defaults to 10 minutes. The redesign did not change timer behaviour or persistence.

## Required fidelity surfaces

- Top chrome: passed. Watercolor/paper continues through the top safe area, the root navigation bar and toolbar background are hidden, and no divider, material strip, hard colour handoff, or seam is visible.
- Header: passed. Custom serif title, two-line support copy, bare gear control, x/y placement, and breathing space align to the reference.
- Card hierarchy and geometry: passed. Deep Session, Quiet Mode, and Offline Reset are simultaneously visible in the required order with measured 215/208/208 pt heights, 12 pt gaps, 18 pt radii, and full-card actions.
- Card content: passed. Titles, exact short descriptions, 25/15/8 minute capsules, subtle leaf marks, and 48 pt forest play controls match the reference hierarchy.
- Illustration: passed. Deep uses a protected forward forest path, Quiet uses a cooler still-lake crop, and Offline uses a lighter distant-mountain composition with more negative space. All are real raster watercolor assets.
- Dock clearance: passed. The third card ends above the detached dock; wallpaper remains visible around the material surface, and scrolling reveals the preserved Focus support disclosure.

## Visible mismatch and automatic-refinement history

1. Baseline — only Deep Session was prominent; Quiet Mode and Offline Reset were hidden behind a generic tools disclosure. The subtitle, card proportions, art integration, hierarchy, and first-viewport density did not match.
2. Pass 1 — restored the three visible modes and reference order. Remaining mismatches: tiny glyphs, oversized card titles, pale generic imagery, incorrect duration treatment, and weak card edges.
3. Pass 2 — corrected glyph scale, title scale, duration capsules, borders, shadows, and card geometry. Remaining mismatches: Quiet art was too warm and Offline art lacked mountain density.
4. Pass 3 — introduced the lake composition and stronger distant landscape. Remaining mismatches: Quiet had an oversized right tree; Offline had a visible crop seam and remained too pale.
5. Pass 4 — balanced Quiet's tree mass and lake horizon. Remaining mismatch: Offline looked too forest-heavy.
6. Pass 5 — replaced the generic Offline wash with a measured mountain/forest crop. Remaining mismatches: Quiet's crop exposed too much sky; Offline still needed lower mountain placement.
7. Pass 6 — moved both crops to expose the lake and deeper mountain layers. Geometry, header, text, and dock were aligned; Quiet remained slightly desaturated and Offline slightly too warm.
8. Pass 7/8 — restored colour to Quiet and tested the dedicated open-sky mountain wash for Offline. The dedicated wash was visibly too empty, so it was rejected rather than accepted as a false final pass.
9. Pass 9 — retained the denser mountain source for Offline, reduced the ochre cast, preserved the lake crop, rebuilt, relaunched, and performed the full and focused side-by-side review.
10. Pass 10/final — independent review found that the visually seamless top still relied on the parent shell beneath a transparent mask. The mask was removed so the Focus root itself owns an opaque paper-and-watercolor field through the status area; the rebuilt comparison remains seamless. Only the accepted P3 source/platform variations above remain.

## Behavior, accessibility, scope, and verification

- Final build: `xcodebuild -project Mori.xcodeproj -scheme Mori -configuration Debug -destination 'platform=iOS Simulator,id=35FCA784-6B78-43A1-8BE6-B35CBAE64A0B' -derivedDataPath .codex-build/FocusRedesignDerivedData build` → `** BUILD SUCCEEDED **`.
- Deep Session opens its existing setup route; the root dock hides on the pushed screen and Back restores Focus.
- Quiet Mode opens the existing Quiet Mode sheet; Offline Reset opens the existing eight-minute Walk / Offline Reset sheet; Settings opens and dismisses the existing Settings sheet.
- Focus support remains scroll-reachable and expands to Breathing, Quiet Session, Mindfulness Bell, Before Feed, App Limits, and Daily Check-In. Quiet Mode and Offline Reset are not duplicated there.
- VoiceOver exposes each mode as one full-card button with the mode title, duration value, and descriptive hint. Settings remains 46 × 46 pt; tab targets remain 126 × 58 pt.
- Dynamic Type `accessibility-extra-large` expands cards instead of clipping them. Scrolling brings Offline Reset and Focus support fully above the dock. Evidence: `accessibility-extra-large-1290x2796.png` and `accessibility-extra-large-scrolled-1290x2796.png`.
- Today scope guard passed. `Features/Today/TodayView.swift` remains `ce549c96c2ee1ac1326c970ef194dbb8fd7db15a7633382e23d39e8d5cd1b6d0`; `Features/Today/TodaySupportViews.swift` remains `5c4fb3dc4b5dc529704b5e17e4aa97251ba5d81eeae81ec8ac3da08b17f68415`.
- Independent final re-review after the pass-10 root-background correction found no P0/P1/P2 issue and returned `Pass`.
- `git diff --check` passes. The repository contains unrelated pre-existing dirty changes; this QA claim covers `Features/Settle/SettleView.swift`, the Focus-specific extensions in `DesignSystem/MoriComponents.swift` and `DesignSystem/MoriSanctuaryComponents.swift`, the top-chrome rule in `DesignReferences/MORI_DESIGN_SPEC.md`, and the listed QA artifacts.

final result: passed

---

# Mori Home premium shell refinement — Design QA (2026-07-21)

## Comparison target

- Approved Today visual source: `/Users/lumilux/.codex/state/plugins/product-design/assets/mori-approved-today-view-mockup.jpg`.
- Written source of truth: `DesignReferences/MORI_DESIGN_SPEC.md`.
- Normalized reference: `artifacts/mori-home-premium-20260721/reference-430x932.png`.
- Final runtime capture: `artifacts/mori-home-premium-20260721/runtime-final-1290x2796.png` and `final-430x932.png`.
- Required same-canvas comparison: `artifacts/mori-home-premium-20260721/comparison-final.png`.
- Focused comparisons: `comparison-top.png` and `comparison-dock.png`.
- Durable three-root-tab evidence: `artifacts/mori-home-premium-20260721/root-tabs-final.png`, plus the full-resolution Focus and Log captures in the same directory.
- Before/after and iteration evidence: `before-after.png`, `pass1-430x932.png`, `pass2-430x932.png`, and `pass3-430x932.png`.

## Viewport and state

- Native SwiftUI on the iPhone 15 Pro Max Mori QA simulator, iOS 26.5, 430 × 932 pt / 1290 × 2796 px, light appearance, Dynamic Type `large`.
- The Home shell fills the whole device canvas. The watercolor sits behind the system status area; no navigation-bar surface, divider, or default tab-bar background is present.
- Final measured header geometry: title x45/y87, Settings x356/y87 at 44 × 44 pt, subtitle y134, and hero top approximately y171.
- Final measured dock geometry: x18/y842, 394 × 74 pt, 32 pt continuous radius, 16 pt bottom reveal; tab targets are 126 × 58 pt.
- Runtime data remains truthful: the simulator has no FamilyControls selection, so it shows App Limit setup, one minute, and 0/0 quiet metrics rather than the concept's illustrative Instagram/30 seconds/42/17 state.

## Findings

No actionable P0, P1, or P2 visual differences remain in the affected Home shell.

- [P3] The source concept has a legacy four-item dock and flower glyph. Production preserves Mori's canonical three destinations (`Today`, `Focus`, `Log`) and their established system symbols.
- [P3] Runtime app-limit and quiet-minute data differs from the illustrative source by design; production persistence and FamilyControls data are not fabricated for visual matching.
- [P3] The modern simulator status-bar insets and native glyphs differ slightly from the photographed older-device chrome.
- [P3] The watercolor's individual wet-edge contours and the Settings leaf shadow are not pixel-identical, while composition, palette, subject placement, and visual weight match.

## Required fidelity surfaces

- Top chrome: passed. The navigation bar is hidden; a custom editorial header breathes below the natural system status bar, with artwork and paper wash continuing through the safe area.
- Layout and hierarchy: passed. Header, hero, metrics, intention, Other resets, and dock align to the reference rhythm at the same viewport.
- Bottom dock: passed. A detached 74 pt `ultraThinMaterial` surface uses an 18 pt horizontal inset, 32 pt radius, soft white tint, forest-green 8% shadow at radius 30/y12, 46% inactive treatment, and deep-green selection.
- Typography and color: passed. Native serif/sans hierarchy, forest ink, warm paper, sage neutrals, and restrained contrast retain the Calm / Apple Journal / Japanese stationery direction.
- Imagery: passed. Existing real watercolor rasters remain visible above, below, and around the floating dock; no placeholder or code-drawn artwork is used.
- Motion and functionality: passed. Tab changes use a restrained opacity transition with Reduce Motion support; routes, stores, Screen Time behavior, and immersive tab-bar hiding are preserved.
- Root-shell continuity: passed. Focus now uses the same focus paper scene beneath the status region, a short masked scene handoff, and an explicitly hidden navigation-bar background; the previous hard horizontal seam is absent. Log remains continuous without a new overlay.

## Automatic refinement history

1. Pass 1 established a full-height Home canvas and replaced the narrow legacy overlay with the measured floating 74 pt dock. Remaining issues were a visible safe-area handoff, over-strong inactive icons, and an underline-style selection treatment.
2. Pass 2 matched material tint, 32 pt corner geometry, 16 pt bottom reveal, soft shadow, 46% inactive state, and deep-green selected state. A hard horizontal handoff remained below the status region.
3. Pass 3 and final extended the paper/watercolor field through the safe area, added a short masked watercolor fade, and increased normal header top padding to 45 pt. The top row discontinuity fell from roughly 17–25 RGB levels to about 1–2, while title, hero, metrics, and intention aligned with the reference.
4. Independent review found the same old safe-area handoff on Focus and requested durable evidence for every root tab affected by the global dock. The Focus shell background was matched to its V2 paper scene, its scene fades smoothly through the system region, and the hidden navigation bar now also hides its background. `root-tabs-final.png` records Today, Focus, and Log after this correction.

## Behavior, accessibility, and verification

- Final build: `xcodebuild -project Mori.xcodeproj -scheme Mori -configuration Debug -destination 'platform=iOS Simulator,id=35FCA784-6B78-43A1-8BE6-B35CBAE64A0B' -derivedDataPath .codex-build/HomePremiumDerivedData build` → `** BUILD SUCCEEDED **`.
- Today, Focus, and Log all switch through the production shell and keep 126 × 58 pt tab targets.
- Today, Focus, and Log were captured after the final build. No default tab bar, navigation divider, clipped wallpaper, or hard safe-area handoff remains in the three-root-tab board.
- Focus → Deep Session opens successfully and the floating dock is absent on the immersive pushed route; Back restores the Focus root and dock.
- Today Settings opens and dismisses its production sheet.
- Dynamic Type `accessibility-extra-large` remains scrollable; after scrolling, intention and Other resets remain reachable above the dock. Evidence: `accessibility-extra-large-1290x2796.png` and `accessibility-extra-large-scrolled-1290x2796.png`.
- Accessibility geometry and journey evidence: `artifacts/mori-home-premium-20260721/accessibility-verification.json`; every visible Home control meets or exceeds 44 pt in both dimensions.
- Independent technical/visual re-review after the Focus safe-area correction found no remaining P0/P1/P2 issue and returned `Pass`.
- The worktree contains unrelated pre-existing changes. This QA claim covers the Home shell changes in `App/ContentView.swift`, `App/MoriAppTabBar.swift`, `DesignSystem/MoriViewModifiers.swift` (`MoriMainTabBarMetrics` only), `DesignSystem/MoriSanctuaryComponents.swift` (root-scene fade only), `Features/Today/TodayView.swift`, `Features/Today/TodaySupportViews.swift`, and `Features/Settle/SettleView.swift` (navigation-bar background hiding only), plus the listed QA artifacts. Other dirty-worktree metric and feature changes are excluded from this claim.

final result: passed

---

# Mori Today mockup rebuild — Design QA (2026-07-21)

## Comparison target

- Primary visual source: `/Users/lumilux/.codex/state/plugins/product-design/assets/mori-approved-today-view-mockup.jpg`.
- Original user attachment: `/tmp/codex-remote-attachments/019f7fa1-9161-75c2-b97f-e136f9c551aa/01F35A7D-6220-495D-994C-B82A67447917/1-Photo-1.jpg`.
- Written source of truth: `DesignReferences/MORI_DESIGN_SPEC.md`.
- Normalized reference: `artifacts/mori-today-redesign-20260721/reference-430x932.png`.
- Final runtime capture: `artifacts/mori-today-redesign-20260721/runtime-final-1290x2796.png` and `final-430x932.png`.
- Required full same-canvas comparison: `artifacts/mori-today-redesign-20260721/comparison-final.png`.
- Focused comparisons: `comparison-hero-final.png` and `comparison-summary-final.png` in the same artifact directory.
- Iteration evidence: `comparison-pass1.png` through `comparison-pass4.png`.

## Viewport and state

- Implementation: native SwiftUI on the iPhone 15 Pro Max Mori QA simulator, iOS 26.5, 430 × 932 pt / 1290 × 2796 px, light appearance, Dynamic Type `large`.
- The photographed concept was cropped to its phone content and normalized to 430 × 932 for a single side-by-side comparison canvas. The source photo is not a native iPhone aspect ratio, so circular glyphs are slightly vertically stretched in the normalized reference.
- Final simulator state uses real production persistence. The intention was entered through the visible editor and confirmed to persist after process relaunch.
- The simulator has no authorized FamilyControls selection, so its truthful runtime state is `APP LIMIT SETUP`, a one-minute configured pause, and zero recorded quiet metrics. The source image shows an illustrative active Instagram selection, 30 seconds, 42 quiet minutes, and 17 longest minutes.
- Production code does not fake that source data: a sole real app or domain renders through `FamilyControls.Label(token)`, duration comes from app-group settings, and both quiet metrics come from persisted Mori actions.

## Findings

No actionable P0, P1, or P2 visual differences remain in the Today-owned composition.

- [P3] Runtime content state differs from the source: App Limit setup versus active Instagram, one minute versus 30 seconds, and 0/0 versus 42/17. This is truthful simulator data, not a layout mismatch. The active layout has dedicated spacing and native token rendering.
- [P3] The source mockup contains a legacy four-item floating tab bar. The production app retains its canonical three-tab shell (`Today`, `Focus`, `Log`) because the request limits changes to Today and `MORI_DESIGN_SPEC.md` defines three tabs.
- [P3] Watercolor wet-edge contours, individual botanical shapes, and the native leaf/settings glyph are not pixel-identical to the concept drawing. Composition, palette, text-safe area, subject placement, and visual weight match.
- [P3] The concept's photographed status bar has older-device horizontal insets, while the iPhone 15 Pro Max simulator uses modern system insets. The app does not draw or override system chrome.
- [P3] The normalized photographed reference has slight vertical stretching and softer text rasterization; the runtime keeps native aspect ratio and type rendering.

## Required fidelity surfaces

- Hierarchy and geometry: passed. Header title begins at x45/y88; the hero begins at x32/y173 and is 368 × 318 pt; metrics, intention, and Other resets align to the measured reference rhythm.
- Typography: passed. Editorial serif title hierarchy, condensed compact supporting text, uppercase app-limit kicker, metric numerals, and intention copy match the reference scale and density.
- Hero art: passed. `MoriTodayBeforeFeedForest` is a real generated raster with left-side text safety, pale sun, right-side conifers, winding lower-right path, paper grain, and edge fade. No SVG/CSS/code-drawn placeholder is used.
- Background art: passed. `BotanicalBackdropToday` supplies the top foliage and `MoriDeepSessionForest` supplies a restrained bottom lake/forest anchor.
- Surfaces and controls: passed. Hero, 80 pt metrics card, 82 pt intention card, compact 176 × 51 pt CTA, softer measured radii, restrained borders/shadows, and 44 pt minimum hit targets are present.
- Functional mapping: passed. Settings, App Limits, Before Feed Reset, intention edit/persistence, Morning Reset, and Week Archive retain their existing routes and stores.

## Automatic refinement history

1. Pass 1 — `comparison-pass1.png`
   - [P1] Header and hero were about 36–52 pt too high.
   - [P1] CTA copy truncated; the protected-set icon/row was too wide.
   - [P2] Metrics were 98 pt instead of 80 pt, labels wrapped, intention was too tall, and the lake scene was too dominant.
   - Fixes: measured header/card offsets, compacted CTA typography and padding, reduced metrics/icon geometry, shortened truthful setup copy, reduced intention height, and softened the bottom art.

2. Pass 2 — `comparison-pass2.png`
   - Main cards reached the correct x/y positions and heights.
   - [P2] CTA/reassurance remained 2–7 pt high, selection icon/text began too far right, and radii were slightly too round.
   - Fixes: refined row icon width/gap, CTA/reassurance rhythm, and hero/summary/intention radii.

3. Pass 3 — `comparison-pass3.png`
   - [P2] Header subtitle was still 8 pt too close to the title, while the active one-line subtitle needed different vertical rhythm from the two-line setup state.
   - Fixes: matched the 13 pt header gap while preserving hero y173, and added data-aware active/setup spacing without changing functionality.

4. Pass 4 and final — `comparison-pass4.png`, `comparison-final.png`
   - Header, hero, CTA, metrics, intention, Other resets, and lower landscape have no remaining P0/P1/P2 mismatch.
   - The final capture uses a persisted intention matching the source text and a clean 9:41 status bar.

## Behavior, accessibility, and verification

- `xcodebuild -project Mori.xcodeproj -scheme Mori -configuration Debug -destination 'platform=iOS Simulator,id=35FCA784-6B78-43A1-8BE6-B35CBAE64A0B' -derivedDataPath .codex-build/TodayRedesignDerivedData build`: passed after every refinement; final result `** BUILD SUCCEEDED **`.
- Settings opens and dismisses its production sheet.
- App Limit row opens the existing locked App Limits flow in the current permission state.
- Begin quiet pause opens the production Before Feed sheet even without Screen Time permission.
- Intention editor accepts text, saves through `TodayFocusDraftStore`, and retained the value after app process relaunch.
- Other resets expands/collapses; Morning Reset opens; Week Archive navigates and returns successfully.
- Dynamic Type `accessibility-extra-large` scrolls without truncating the header, hero, setup row, CTA, reassurance, or metrics. Evidence: `accessibility-extra-large-1290x2796.png`.
- Accessibility evidence: `final-accessibility-tree.json` and `other-resets-expanded-accessibility-tree.json`; all visible Today controls are at least 44 pt.
- `git diff --check` passes for the Today files and new asset metadata.
- Scope audit: this Today rebuild's owned runtime changes are limited to `Features/Today/TodayView.swift`, `Features/Today/TodaySupportViews.swift`, and the Today-specific hero imageset. The worktree also contains unrelated pre-existing changes, which are excluded from this claim; QA artifacts/documentation do not affect runtime screens.

final result: passed

---

# Mori Design System v2 — Design QA

## Comparison target

- Source visual truth: `/tmp/codex-remote-attachments/019f6b22-d255-78e0-9cf8-c1dd9ef460a9/1F2B6D15-8296-4F40-9DCD-2E308421D765/1-Photo-1.jpg`
- Interactive implementation: `http://localhost:4173/mori-v2`
- Final full-view comparison: `outputs/mori-v2/comparisons/source-top-flow-vs-implementation-final.png`
- Focused completion comparison: `outputs/mori-v2/comparisons/session-complete-focused-comparison-final.png`
- Primary captures: `outputs/mori-v2/browser/today-final-390x844.png`, `before-feed-final-390x844.png`, `before-feed-habit-final-390x844.png`, `breathing-final-390x844.png`, `focus-final-390x844.png`, `session-complete-final-390x844.png`, `log-final-390x844.png`, `settings-final-390x844.png`, and `quiet-notes-final-390x844.png`.
- Compact captures: `outputs/mori-v2/browser/today-compact-final-320x568.png`, `before-feed-habit-compact-final-320x568.png`, `focus-compact-final-320x568.png`, `focus-paused-compact-final-320x568.png`, and `session-ended-early-compact-final-320x568.png`.

## Viewport and state

- Primary prototype canvas: 390 × 844 CSS px.
- Compact verification: 320 × 568 CSS px, plus scroll-reachability checks for short/landscape layouts.
- iOS safe areas are handled with `env(safe-area-inset-top)` and `env(safe-area-inset-bottom)` for screens, tab bar, floating Settings, sheet, and toast.
- The source image is direction, not a pixel-clone contract where it conflicts with the written Mori philosophy. Dashboard cards, progress rings, app-icon strips, reward copy, scarcity copy, and the `Me` tab were intentionally removed.

## Slower-breath and Apple HIG critique

| Screen | “Does this make the user breathe slower?” | Apple HIG check | Mori philosophy check | Result |
|---|---|---|---|---|
| Today | Yes — a long quiet field leads to one paper card and one CTA. | Three clear primary destinations, 44pt+ controls, safe-area-aware layout. | No dashboard, chart, streak, or competing widget. | Pass |
| Before Feed | Yes — neutral language and unselected reasons lead into the configured pause without warning or scarcity. | Semantic radio group, full-row targets, clear Back/Close paths. | No preselection, guilt, or automatic unlock. | Pass |
| Before Feed pause | Yes — the watercolor ring expands slowly for the configured reset length. | Timer is non-chatty to VoiceOver; only phase changes are announced; Reduce Motion is respected. | The feed remains closed until completion and a final intentional Continue. | Pass |
| Deep Session | Yes — the plain timer sits in mist and forest with no productivity ring. | Immersive active state, deadline-accurate timer, clear Pause, reachable compact controls. | No Pomodoro, score, growth mechanic, edit cluster, or app-icon strip. | Pass |
| Paused | Yes — “Nothing is lost” removes urgency and End appears only when relevant. | State and actions are explicit, labelled, and 44pt+. | No penalty or loss framing. | Pass |
| Complete / early end | Yes — the acknowledgment is quiet and visually still. | Truthful elapsed time, clear actions, focus moves to the new region. | No “great work,” “earned,” confetti, or false 25-minute claim. | Pass |
| Log | Yes — mood, one sentence, optional photo, and Done remain the only entry controls. | Draft survives tab changes; photo can be removed; saved/short layouts scroll. | No editor chrome or analytics in the entry viewport. | Pass |
| Quiet Notes | Yes — Intent Count and Quiet Minutes stay collapsed until deliberately requested. | Expansion is labelled and keyboard reachable; values update from prototype actions. | Metrics are text-only, secondary, and non-gamified. | Pass |
| Settings | Yes — one opaque sheet contains only quiet preferences. | Dialog label, Escape, focus trap/restoration, persistent switches, background isolation. | Settings is a floating action, never a fourth tab. | Pass |

## Findings and automatic redesign history

1. The source Today screen read as a dashboard and the source Focus screen reused productivity patterns. The redesign cut Today to one next action and made an active Focus session immersive.
2. Low-contrast secondary actions over forest art were moved onto opaque paper controls; muted text and inactive tabs were raised to readable contrast.
3. Tiny padded bitmap glyphs were optically enlarged while retaining 44pt+ hit targets.
4. Safe-area offsets, compact scrolling, saved-Log scrolling, and immersive Focus reachability were added after HIG review.
5. Reward-coded completion copy and the false early-end 25-minute claim were replaced with neutral, truthful copy.
6. Breathing and Focus timers were changed to absolute deadlines with visibility recalculation so background throttling cannot extend the promise.
7. Settings gained modal focus containment, Escape, restoration, persistent switch state, and a layer above toasts.
8. Log analytics were removed from the entry screen. Stateful Intent Count and Quiet Minutes now live in an optional post-save disclosure.
9. Watercolor PNGs were optimized to WebP; the v2 route avoids the marketing route's render-blocking web-font request.

No actionable P0, P1, or P2 visual, interaction, accessibility, or packaging findings remain.

## Required fidelity surfaces

- Typography: New York/system serif hierarchy for titles and San Francisco/system sans serif for body; no remote-font dependency on v2.
- Color: warm paper, forest ink, stone/sage neutrals, no bright blue/orange/neon or glass treatment.
- Imagery: real watercolor raster assets with slow parallax; no CSS-drawn scenery or placeholder art.
- Layout: opaque rounded paper cards, restrained shadows, one visually dominant action, substantial negative space.
- Motion: gentle fades/scale/parallax only; `prefers-reduced-motion` removes nonessential transforms and timing remains functional.
- Copy: pause/notice/choose language; no punishment, scarcity, streak, score, XP, coins, badges, fire, or productivity framing.

## Behavior, accessibility, and verification

- Today → Before Feed → any reason → configured breathing pause → explicit open/close works.
- Today → Focus → pause/resume → early/full completion works; an active session uses an absolute deadline.
- Log draft, mood-only save, optional file selection/removal, saved state, and Quiet Notes work across tab changes.
- Settings focus trap, Shift-Tab wrap, Escape, focus restoration, switch persistence, and toast layering work.
- Screen transitions focus labelled regions; the numeric breathing countdown is not announced every second.
- Decorative watercolor is hidden from assistive technology; controls are semantic and keyboard reachable.
- Automated regression suite: 6/6 passed.
- TypeScript: passed.
- Standard library build, declarations, stylesheet export, ESM/CJS artifacts, and CommonJS smoke test: passed.
- Vercel/app build and optimized asset bundle: passed.
- Bitmap asset mirror check and `git diff --check`: passed.
- Browser interaction checks at 390 × 844 and 320 × 568: passed; no console issues observed.

final result: passed

---

# Mori Design System v2 — Native SwiftUI QA

## Comparison target

- Source direction: `/tmp/codex-remote-attachments/019f6b22-d255-78e0-9cf8-c1dd9ef460a9/1F2B6D15-8296-4F40-9DCD-2E308421D765/1-Photo-1.jpg`
- Source/native comparison: `artifacts/mori-v2-native/reference-comparison.png`
- Final compact flow board: `artifacts/mori-v2-native/native-flow-board.png`
- Primary compact captures: `today-se.png`, `before-feed-se.png`, `before-feed-habit-se.png`, `focus-se.png`, `deep-session-setup-se.png`, `deep-session-active-se.png`, `deep-session-complete-se.png`, `log-se.png`, `quiet-mode-se.png`, `week-archive-se.png`, `settings-se.png`, and `practice-verification-se.png` in `artifacts/mori-v2-native/`.
- Modern-device captures: Today, Before Feed, Focus, Log, and all Deep Session states on the iPhone 15 Pro Max simulator in the same artifact directory.

## Viewport and implementation state

- Compact verification: iPhone SE, 375 × 667 pt / 750 × 1334 px.
- Modern verification: iPhone 15 Pro Max, 430 × 932 pt.
- The implementation is native SwiftUI and uses the production routes, stores, timers, Screen Time integration, Log persistence, archive data, reminders, and settings controls.
- Launch arguments only select deterministic QA states; they do not replace runtime behavior.
- The source image is an art-direction reference. Its progress rings, feed-budget dashboard, app-icon strip, fourth tab, reward copy, and loud completion language were intentionally not copied because they conflict with the written Mori contract.

## Slower-breath and Apple HIG critique

| Screen | “Does this make the user breathe slower?” | Apple HIG check | Mori philosophy check | Result |
|---|---|---|---|---|
| Today | Yes — one large next-action card sits in an open paper field. | Three clear tabs, 44pt+ controls, Dynamic Type, safe-area-aware layout. | Intent Count and Quiet Minutes are secondary; no dashboard, ring, streak, or competing CTA. | Pass |
| Before Feed | Yes — the unselected reasons create a neutral choice before the configured pause starts. | Full-row radio targets, explicit selection state, Close path, VoiceOver values. | Why now? remains nonjudgmental and cannot unlock the feed directly. | Pass |
| Before Feed pause | Yes — one watercolor breath field carries the configured reset length. | Large Pause/Resume controls, explicit completion Continue, Reduce Motion respected. | The feed stays closed through the reset and completion never opens it automatically. | Pass |
| Focus root | Yes — one Deep Session card precedes a folded tools row. | Clear hierarchy and persistent three-tab navigation. | Breathing, timers, limits, bell, check-in, and offline reset remain available without crowding the first viewport. | Pass |
| Deep Session setup | Yes — forest art, one timer, one CTA, folded options. | Scroll-safe on compact devices; settings remain reachable; controls exceed 44pt. | No Pomodoro, cycle score, progress ring, or reward preview. | Pass |
| Deep Session active | Yes — timer, forest, blocked-app summary, and Pause only. | State is explicit; pause target is large; absolute timer behavior is preserved. | No productivity chrome or unnecessary controls. | Pass |
| Deep Session complete | Yes — still paper, one sentence, one duration, one Continue action. | Clear completion state and action, no hidden navigation conflict. | No confetti, praise, seed, XP, or scarcity language. | Pass |
| Log | Yes — mood, one sentence, optional photo, Done. | Photo removal, persistence, import/export, history, and settings remain accessible. | Advanced Log functions are folded below the first task; no journaling-software dashboard. | Pass |
| Quiet Mode | Yes — a single large timer leads; duration and secondary choices are folded. | High-contrast 44pt back target, compact scrolling, accessible timer. | The old ring, duration cluster, six-metric dashboard, score, and reward copy were removed. | Pass |
| Week Archive | Yes — current week and optional browsing replace an exposed contribution grid. | Back and rows meet target size; segmented Week/Month navigation remains native. | The map stays folded, no score/trend is shown, and “Nothing needed from you” avoids guilt. | Pass |
| Settings | Yes — one App Limits row and calm collapsed categories. | Done and rows meet target size; standard pickers, steppers, alerts, and toggles are preserved. | No dense corporate Form; archive, reminders, language, app data, and About use progressive disclosure. | Pass |
| Offline reset | Yes — one plain timer and one Start action. | Clear Close path, semantic timer value, minimum targets, no visual-only state. | The productivity ring and disabled completion clutter were removed; copy emphasizes choice. | Pass |

## Preserved functions

- Today: App Limit status/setup, Before Feed, Morning Reset, editable focus, Week Archive.
- Focus: Deep Session, breathing library, Quiet Session timer, Quiet Mode, mindfulness bell, Before Feed, App Limits, Daily Check-In, and Walk / Offline Reset.
- Deep Session: duration, break lengths, repeats, breathing cues, sound, haptics, forest movement, dark room, and blocked-app selection remain in Session options.
- Log: mood, sentence, photo, Daily Spark, patterns, archive, random memory, history, previous entries, import/export, iCloud restore, and photo management.
- Settings: App Limits, archive calibration, reminders, language, onboarding restart, saved-check-in clearing, and About.
- Existing persistence keys and internal `Pomodoro` / `seed` model identifiers remain only where required for stored-data migration and compatibility.

## Findings and automatic redesign history

1. The source Today dashboard and Deep Session ring increased cognitive load. Today was reduced to one action and active Deep Session to timer, forest, blocked apps, and Pause.
2. The generated forest initially overflowed its measured slot. It was constrained with a bounded aspect-fill layout and rechecked at compact and modern sizes.
3. The primary CTA icon lacked contrast. A warm paper circle was added behind the bitmap icon.
4. Completion initially retained navigation chrome. The completion state now hides it and keeps one clear Continue action.
5. Reachable legacy sheets still surfaced Seeds, reward pills, streak copy, and celebratory completion language. Visible copy and badges were neutralized while models and stored data remained intact.
6. Quiet Mode still looked like a productivity timer with a progress ring, preset cluster, and six metrics. The timer became plain and large; options and secondary functions moved behind disclosure; only Quiet Minutes remains visible in its optional day summary.
7. Week Archive exposed a contribution-style grid. The current week is now the default action and the archive map stays folded until deliberately requested.
8. Offline verification retained a progress ring and disabled completion control. The ring was removed and completion appears only when relevant.
9. Settings used a dense system Form. It was rebuilt as an opaque paper screen with calm category disclosures, while native controls and destructive confirmations remain intact.
10. Localized user-facing Pomodoro values were replaced with Deep Session equivalents in English, Traditional Chinese, and Simplified Chinese; internal keys remain for compatibility.

No actionable P0, P1, or P2 visual, interaction, accessibility, or packaging findings remain in the implemented native v2 flow.

## Verification

- `xcodebuild -project Mori.xcodeproj -scheme Mori -configuration Debug -destination 'platform=iOS Simulator,id=35FCA784-6B78-43A1-8BE6-B35CBAE64A0B' -derivedDataPath /tmp/mori-derived build -quiet`: passed.
- Runtime launch and deterministic-state capture on iPhone SE: passed.
- Modern-device layout review on iPhone 15 Pro Max: passed.
- Swift parse checks for the revised Quiet Mode, Settings, Week Archive, and practice-verification views: passed.
- English, Traditional Chinese, and Simplified Chinese strings files: `plutil -lint` passed.
- `git diff --check`: passed.
- The Xcode project currently has no XCTest test target, so no unit/UI test suite was available to run; the production scheme build and simulator journeys are the executable verification.

final result: passed

---

# Mori Zen Breathing — Design QA

## Comparison target

- Source visual truth: `outputs/design-audit/mori-zen-motion-20260710/source-fullscreen-breathing.png`
- Latest implementation screenshot: `outputs/design-audit/mori-zen-motion-20260710/runtime/breathing-qa-pass.png`
- Final full-view comparison: `outputs/design-audit/mori-zen-motion-20260710/comparisons/source-vs-implementation-pass4.png`
- Motion evidence: `outputs/design-audit/mori-zen-motion-20260710/runtime/breathing-motion-final.mp4`
- Motion frame comparison: `outputs/design-audit/mori-zen-motion-20260710/comparisons/motion-frame-a-vs-b.png`
- Completion evidence: `outputs/design-audit/mori-zen-motion-20260710/runtime/breathing-completion-pass.png`
- Small-device evidence: `outputs/design-audit/mori-zen-motion-20260710/runtime/breathing-se-pass-v2.png`

## Viewport and state

- Source: 852 × 1846 px portrait, normalized as the visual truth.
- Implementation: iPhone 15 Pro Max Simulator, 430 × 932 pt / 1290 × 2796 px, normalized to 852 × 1846 px for comparison.
- Responsive check: iPhone SE Simulator, 375 × 667 pt.
- Theme: light botanical paper.
- State: active breathing; the source captures `Inhale` at phase countdown `4`, while the deterministic runtime fixture captures the animated `Exhale` transition at countdown `1` and 41 seconds remaining.
- Expected platform difference: the production app keeps the native iOS status bar and home indicator; the concept image omits system chrome.

## Findings

No actionable P0, P1, or P2 fidelity findings remain.

- [P3] Background washes are not pixel-identical.
  - Location: top-left canopy and bottom landscape.
  - Evidence: both use pale sage/mist/ochre watercolor layers, but the generated production assets have naturally different wet-edge contours.
  - Impact: the selected art direction and hierarchy are preserved.
  - Follow-up: none required unless exact contour tracing becomes a goal.

## Required fidelity surfaces

- Fonts and typography: passed. The phase uses a restrained serif title, the phase countdown uses an ultra-light rounded numeric face with monospaced digits, and the remaining-time/control copy stays quiet and readable. No clipping or wrapping appears on the Pro Max or SE captures.
- Spacing and layout rhythm: passed. The phase cue, large watercolor bloom, remaining-time label, compact capsule control, and bottom landscape follow the source's single-column hierarchy. The active screen contains no concentric rings, progress bar, toggle cluster, or oversized bottom bar.
- Colors and visual tokens: passed. Warm watercolor paper, deep botanical ink, pale sage/mist washes, and restrained ochre use Mori's sanctuary tokens. `scripts/check_color_contrast_tokens.sh` passes.
- Image quality and asset fidelity: passed. Both visible hero washes are real generated raster assets with alpha, 1x/2x/3x variants, organic edges, and no rectangular halo. There are no placeholder, inline SVG, procedural blob, or code-drawn substitutes.
- Copy and content: passed. `Inhale`, localized remaining time, `Pause`/`Resume`, completion copy, and Quiet Minutes summary are coherent and concise. English, zh-Hant, and zh-Hans remaining-time, close, pause/resume, settings, and countdown accessibility keys are present and parseable.

## Behavior and accessibility

- The notification fixture opens the active full-screen session and auto-starts without the old setup flash.
- The breathing clock drives phase label, phase seconds, total remaining time, and watercolor motion. Motion evidence shows the bloom expanding during inhale and contracting/softening during exhale.
- Pause and Resume are wired to the existing session clock; paused state retains the current phase visual instead of resetting.
- Natural timer completion transitions to the dedicated botanical completion surface instead of the ring-heavy setup screen.
- The global breathing-library sheet now injects the settle route action, so Start can push a breathing session instead of silently doing nothing.
- The sheet uses a heterogeneous `NavigationPath`, so both breathing-library details and settle-session routes navigate safely in the same stack.
- Main-tab changes use a calm opacity dissolve; sheets use the warm botanical paper presentation.
- Reduce Motion disables bloom transforms and screen-transition animation while leaving timing, text, sound, and haptics functional. `scripts/check_reduced_motion_contract.sh` passes.
- Interactive controls meet a 44 pt minimum target and have explicit accessibility labels/hints.

## Focused comparison evidence

A separate crop was not needed: the final side-by-side comparison is retained at 1846 px tall, where the phase typography, countdown stroke, close icon, watercolor edge quality, remaining-time copy, button radius/shadow, and bottom landscape are all clearly readable. Motion is evaluated separately in the two-frame comparison and MP4 evidence.

## Comparison history

1. Pass 0 — `comparisons/source-vs-implementation-pass0.png`
   - [P1] The first ink asset rendered an opaque white rectangle.
   - [P2] The title/countdown treatment was too heavy, the bloom was undersized, and the Pause control was much too wide.
   - Fixes: converted the watercolor to a feathered alpha asset, removed the isolated compositing behavior, changed the countdown to an ultra-light rounded face, expanded the bloom, and reduced the control width.

2. Pass 1 — `comparisons/source-vs-implementation-pass1.png`
   - The P1 rectangle was fixed.
   - [P2] The active screen still lacked the source's botanical bottom landscape and the compact control/visual proportions were not yet close enough.
   - Fixes: generated a dedicated bottom landscape raster asset, refined title scale, expanded the bloom without changing layout height, and narrowed the Pause capsule.

3. Pass 2 — `comparisons/source-vs-implementation-pass2.png`
   - Typography, bloom, alpha edge, and control width matched the intended hierarchy.
   - [P2] The bottom landscape began too low and read as a shallow footer rather than an atmospheric foreground.
   - Fix: increased the measured landscape slot so the translucent hills rise behind the remaining-time label and control like the source.

4. Pass 3 — `comparisons/source-vs-implementation-pass3.png`
   - Post-fix comparison has no remaining P0/P1/P2 differences.
   - Expected native status-bar/home-indicator chrome and organic watercolor contour variation are accepted.

5. Pass 4 — `comparisons/source-vs-implementation-pass4.png`
   - Reviewer follow-up fixed heterogeneous sheet navigation, increased the close-mark contrast, and completed English/Traditional Chinese/Simplified Chinese accessibility localization.
   - Rebuilt and recaptured from current source; independent re-review found no remaining P0/P1/P2 issues.

## Verification

- iOS app source-check build: passed (`** BUILD SUCCEEDED **`).
- Runtime launch/capture: passed on iPhone 15 Pro Max and iPhone SE Simulators.
- Natural completion: passed.
- Animation capture: passed.
- Reduce Motion contract: passed.
- Color contrast tokens: passed.
- Localization parsing: passed through the design-direction gate.
- Repository design-direction gate: one pre-existing, out-of-scope shield icon contract issue remains (`moriIconBeforeFeedReset` versus `moriIconLeaf`); the breathing redesign introduces no gate failure.
- Canonical multi-target scheme remains blocked in this Xcode installation by a missing watchOS 26.5 Simulator runtime. The iOS app was built and run from a temporary project copy with only the Watch dependency/embed step omitted; no production project dependency was changed for that workaround.

## Implementation checklist

- [x] Full-screen breathing direction implemented.
- [x] Concentric circles and progress bar removed from the active session.
- [x] Animated watercolor ink wired to the breathing phase.
- [x] Compact botanical Pause/Resume control implemented.
- [x] Dedicated completion surface implemented.
- [x] Calm root-view and modal presentation treatment implemented.
- [x] Reduce Motion and small-screen behavior verified.
- [x] Final source/implementation comparison passed.

final result: passed
