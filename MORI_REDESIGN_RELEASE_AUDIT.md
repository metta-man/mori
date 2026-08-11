# Mori Redesign Release Audit

Date: 2026-06-26 HKT

## Evidence Status

This is a historical audit, not automatic proof for the current checkout. Its local payload was moved out of the repository and preserved in the dated external archive recorded against source commit `1f0ee314f936609e50fc1be6f7c05d7355508f50`.

Paths beginning with `output/` or `outputs/` below are relative to that archive's `evidence/` payload. Use `scripts/check_runtime_evidence.sh --evidence-root <archive-path>` to validate the archive manifest, checksums, commit SHA, and audits. A commit mismatch is stale evidence and must not be presented as current release proof.

## Audit Scope

This audit records the redesign evidence inspected for the active Mori product direction at the audit date:

- Screen Time-first onboarding
- Botanical watercolor visual system
- No logo, wordmark, app-icon, hourglass, funnel, seedling badge, circular emblem, or repeated leaf-mark backgrounds inside primary app surfaces
- Native app, widgets, watch, shield extensions, and web package carrying the same bitmap paper-watercolor direction

Evidence inspected:

- Native main-surface screenshots in `output/screenshot-audit/main-surfaces-2026-06-25/`
- Fresh Log, Week Archive, and Pulse refresh screenshots in `output/screenshot-audit/main-surfaces-refresh-2026-06-26/`
- Fresh Settings, First App Limit setup, Advanced App Limits lock, incorrect PIN, cooldown, unlocked, and lock-removed screenshots in `output/screenshot-audit/system-flows-2026-06-26/`
- Fresh no-logo card screenshots in `output/screenshot-audit/card-no-logo-2026-06-26/`
- Fresh Reset simplification screenshots in `output/screenshot-audit/reset-simplification-2026-06-26/`
- Fresh Pulse simplification screenshots in `output/screenshot-audit/pulse-simplification-2026-06-26/`
- Fresh Dynamic Type screenshots in `output/screenshot-audit/dynamic-type-2026-06-26/`
- Fresh zh-Hant runtime localization screenshots in `output/localization-audit/zh-hant-runtime-2026-06-26/`
- Fresh zh-Hant Advanced App Limits lock lifecycle screenshots in `output/localization-audit/zh-hant-advanced-app-limits-2026-06-26/`
- Fresh zh-Hant Gate Settings screenshots in `output/localization-audit/zh-hant-gate-settings-2026-06-26/`
- Fresh zh-Hant Pulse / Recovery screenshots in `output/localization-audit/zh-hant-pulse-recovery-2026-06-26/`
- Fresh zh-Hant Recovery ready/detail screenshots in `output/localization-audit/zh-hant-recovery-ready-detail-2026-06-26/`
- Fresh Recovery HealthKit-shaped sample service audit in `output/healthkit-audit/recovery-healthkit-samples-2026-06-26/`
- Fresh zh-Hant Watch / Widget source localization audit in `output/localization-audit/zh-hant-watch-widget-source-2026-06-26/`
- Fresh zh-Hant Watch app root runtime screenshot audit in `outputs/design-audit/watch-runtime-zh-hant-20260626/`
- Fresh Watch complication source and compiled asset audit in `outputs/design-audit/watch-complications-source-20260626/`
- Fresh iOS Widget runtime screenshot audit in `outputs/design-audit/widget-runtime-20260626/`
- Week Archive focused-year source density audit in `outputs/design-audit/week-archive-density-20260626/AUDIT.md`
- Fresh card paper material refresh audit in `outputs/design-audit/card-paper-material-refresh-20260626/`
- Native semantic accessibility runtime audit in `output/accessibility-audit/native-semantics-2026-06-26/AUDIT.md`
- Native target-order and modal-isolation runtime audit in `output/accessibility-audit/native-target-order-2026-06-26/AUDIT.md`
- Reduced Motion contract audit in `output/accessibility-audit/reduced-motion-2026-06-26/AUDIT.md`
- Web screenshots in `output/screenshot-audit/web-2026-06-26/`
- `output/screenshot-audit/main-surfaces-2026-06-25/AUDIT.md`
- `output/screenshot-audit/main-surfaces-refresh-2026-06-26/AUDIT.md`
- `output/screenshot-audit/system-flows-2026-06-26/AUDIT.md`
- `output/screenshot-audit/card-no-logo-2026-06-26/AUDIT.md`
- `output/screenshot-audit/reset-simplification-2026-06-26/AUDIT.md`
- `output/screenshot-audit/pulse-simplification-2026-06-26/AUDIT.md`
- `output/screenshot-audit/dynamic-type-2026-06-26/AUDIT.md`
- `output/localization-audit/zh-hant-runtime-2026-06-26/AUDIT.md`
- `output/localization-audit/zh-hant-advanced-app-limits-2026-06-26/AUDIT.md`
- `output/localization-audit/zh-hant-gate-settings-2026-06-26/AUDIT.md`
- `output/localization-audit/zh-hant-pulse-recovery-2026-06-26/AUDIT.md`
- `output/localization-audit/zh-hant-recovery-ready-detail-2026-06-26/AUDIT.md`
- `output/healthkit-audit/recovery-healthkit-samples-2026-06-26/AUDIT.md`
- `output/localization-audit/zh-hant-watch-widget-source-2026-06-26/AUDIT.md`
- `outputs/design-audit/watch-runtime-zh-hant-20260626/AUDIT.md`
- `outputs/design-audit/watch-complications-source-20260626/AUDIT.md`
- `outputs/design-audit/widget-runtime-20260626/AUDIT.md`
- `outputs/design-audit/week-archive-density-20260626/AUDIT.md`
- `outputs/design-audit/card-paper-material-refresh-20260626/AUDIT.md`
- `output/accessibility-audit/native-semantics-2026-06-26/AUDIT.md`
- `output/accessibility-audit/native-target-order-2026-06-26/AUDIT.md`
- `output/accessibility-audit/reduced-motion-2026-06-26/AUDIT.md`
- `output/screenshot-audit/web-2026-06-26/AUDIT.md`
- `scripts/check_design_direction.sh`
- `scripts/check_redesign_release_readiness.sh`
- `scripts/check_compiled_design_artifacts.sh`
- `scripts/check_color_contrast_tokens.sh`
- `scripts/check_zh_hant_runtime_localization_audit.sh`
- `scripts/check_zh_hant_advanced_app_limits_audit.sh`
- `scripts/check_zh_hant_gate_settings_audit.sh`
- `scripts/check_zh_hant_pulse_recovery_audit.sh`
- `scripts/check_zh_hant_recovery_ready_detail_audit.sh`
- `scripts/check_recovery_healthkit_sample_audit.sh`
- `scripts/check_zh_hant_watch_widget_source_audit.sh`
- `scripts/check_zh_hant_watch_runtime_audit.sh`
- `scripts/check_watch_complication_source_audit.sh`
- `scripts/check_widget_runtime_audit.sh`
- `scripts/check_reset_simplification_screenshot_audit.sh`
- `scripts/check_pulse_simplification_screenshot_audit.sh`
- `scripts/check_accessibility_semantics_audit.sh`
- `scripts/check_accessibility_target_order_audit.sh`
- `scripts/check_reduced_motion_contract.sh`

## User Goal And Accessibility Target

The user goal is to set one meaningful app limit, hit a pause before the next feed, and use one reset action without the app feeling like a mortality countdown or logo-driven brochure.

Accessibility target for this pass: obvious navigation, readable hierarchy, no visible text clipping, no obviously tiny primary hit targets, no visible state that relies only on old symbolic motifs, and no required continuous motion. This screenshot audit now includes core `accessibility-large` Dynamic Type runtime evidence, a token-level native/web color contrast gate, runtime semantic accessibility targets for onboarding, Today, Settings, and App Limits lock setup, runtime target-list proxy evidence for core action order and modal target isolation, a source-level Reduce Motion contract for native repeating motion and web motion surfaces, zh-Hant runtime evidence for onboarding, Today, first-layer Settings, Advanced App Limits setup/lock/management, Gate Settings coverage for Morning Gate, Before Feed detailed settings, Shortcut guide, Pulse root, Recovery permission state, Recovery deterministic ready/detail state, generated-card fallback, Recovery HealthKit-shaped sample service proof, source-level Watch / Widget localization coverage, Watch app root runtime localization evidence, Watch complication source/compiled family wiring evidence, iOS Widget Today `systemSmall`, `systemMedium`, and `systemLarge` rendered runtime evidence, Home Screen screenshot proof for Journal `systemSmall` / `systemMedium` and Pulse `systemSmall` / `systemMedium` / `systemLarge`, Lock Screen editor screenshot proof for Pulse `accessoryCircular` / `accessoryRectangular`, WidgetKit log proof for Journal `systemSmall` / `systemMedium` and Pulse `systemSmall` / `systemMedium` / `systemLarge`, Today / Pulse Lock Screen accessoryCircular / accessoryRectangular WidgetKit log evidence, and Today / Pulse `accessoryInline` descriptor, placeholder archive, and reload success evidence. It does not prove full WCAG compliance, full OS VoiceOver traversal order or Switch Control scan behavior, keyboard access, live Apple Health database sample coverage, accessoryInline live rendered layout, Watch complication rendered watch-face layout, notification delivery UI, or every localized layout.

## Step List

1. Onboarding: healthy. `00-onboarding.jpg` and `card-no-logo-2026-06-26/onboarding-no-logo-card.jpg` show App Limit-first copy, watercolor paper, quiet cards, and no funnel/hourglass/logo watermark. Source has tightened the App Limit hero card to use `MoriPlainWatercolorCardBackground` instead of any internal botanical, logo, or badge-style wallpaper.
2. Today: healthy. `01-today.jpg`, `card-no-logo-2026-06-26/today-no-logo-card.jpg`, and `card-paper-material-refresh-20260626/today-card-paper-material.jpg` foreground First App Limit and a reset CTA without old life-countdown framing or repeated brand-mark card backgrounds; shared card surfaces now route through `MoriPlainWatercolorCardBackground` with an opaque watercolor-paper backing so screen-level botanical wash does not bleed through every card.
3. Reset: healthy after simplification. `02-reset.jpg` captured the previous dense chip row; `reset-simplification-2026-06-26/reset-inline-summary.png` verifies the current runtime Reset root now uses one muted `MoriPracticeInlineSummary` (`+1 Seed / Rest / Body / Mind`) instead of dense Seed/domain pill stacks while keeping `Start this reset`, `Limit the next feed`, `Before Feed Reset`, `App Limits`, and `More reset options` in the first viewport. `reset-simplification-2026-06-26/reset-expanded-options.jpg` verifies `More reset options` expands into `Hide reset menu` without replacing the root with a management dashboard, and `reset-simplification-2026-06-26/reset-expanded-practice-cards.jpg` verifies the first expanded practice cards (`Breathe`, `Settle`, and `Pomodoro`) keep the same compact inline summary treatment.
4. Log: healthy after refresh. `main-surfaces-refresh-2026-06-26/log-refresh.jpg` verifies the final build's Daily Spark fields, placeholders, and disabled save state on quiet no-logo watercolor paper cards.
5. Week Archive: healthier after refresh and source density reduction. `main-surfaces-refresh-2026-06-26/week-archive-refresh.jpg` verifies `Weeks` copy, lighter quiet-week marks, and botanical paper styling without old Life Grid or mortality copy. After that screenshot, `week-archive-density-20260626/AUDIT.md` records the source change that makes the default week surface a focused 4 x 13 current-archive-year map with archive year, current week, and recorded-week metrics, while moving the full multi-year map behind an explicit disclosure. This reduces the first-viewport density risk; a future screenshot refresh still needs to capture the collapsed focused-year state and expanded full-map state before claiming runtime visual proof for this density pass.
6. Pulse: healthy after simplification. `main-surfaces-refresh-2026-06-26/pulse-refresh.jpg` verifies the stronger Pulse stats ribbon, readable Recovery permission CTA, concise Apple Health copy, and no washed-out footer action. `pulse-simplification-2026-06-26/pulse-topic-summary-default.jpg` verifies the current default Pulse root collapses the previous always-visible `Manage Topics` card into one compact `Pulse topics` row, hides the Recovery insight opt-in while Recovery is still in the Health permission state, and brings the first `Mind` topic insight back into the first viewport. `pulse-simplification-2026-06-26/pulse-topic-manager-expanded.jpg` and `pulse-topic-manager-expanded-edit-row.jpg` verify the explicit expanded first layer shows active topics, queued topics, and a second-level `Edit topic list` row without immediately dumping the default topic library or custom-topic input into the expanded manager. `pulse-topic-library-expanded.jpg` verifies the full topic library and custom-topic input appear only after the second deliberate tap, with `Hide topic list` still available.
7. Web desktop: healthy. `desktop.png` and `desktop-full-page.png` show the botanical watercolor direction, no brand-watermark cards, and enough first-viewport hierarchy.
8. Web mobile: healthy. `mobile.png` and `mobile-full-page.png` keep the same paper-watercolor direction without text clipping in the inspected states.
9. Settings: healthy after system-flow coverage. `system-flows-2026-06-26/settings.jpg` verifies the paper form surface, First App Limit entry point, Week Archive controls, reminder rows, and absence of old logo/countdown positioning.
10. First App Limit setup: healthy after system-flow coverage. `system-flows-2026-06-26/first-app-limit-setup.jpg` verifies Screen Time-first copy, botanical paper cards, and a visible primary `Allow Screen Time` CTA in the first viewport.
11. Advanced App Limits lock: healthy after system-flow coverage. `system-flows-2026-06-26/advanced-app-limits-lock.jpg` verifies the explicit `mori://app-limit-settings` route reaches the App Limits PIN setup/lock surface instead of the first App Limit setup flow.
12. Advanced App Limits incorrect PIN: healthy after system-flow coverage. `system-flows-2026-06-26/advanced-app-limits-incorrect-pin.jpg` verifies a wrong `000000` PIN keeps the user on the lock surface and shows `Incorrect PIN.`.
13. Advanced App Limits cooldown: healthy after system-flow coverage. `system-flows-2026-06-26/advanced-app-limits-cooldown.jpg` verifies the fifth failed PIN attempt shows `Try again in 59s.` and disables the unlock action until cooldown clears.
14. Advanced App Limits unlock: healthy after system-flow coverage. `system-flows-2026-06-26/advanced-app-limits-unlocked.jpg` verifies the Self PIN loop can unlock into the App Limits management surface after relaunch.
15. Advanced App Limits lock removal: healthy after system-flow coverage. `system-flows-2026-06-26/advanced-app-limits-lock-removed.jpg` verifies removing the PIN returns the management surface to a single `Lock App Limits` setup action instead of stale change/remove controls.
16. Dynamic Type onboarding: healthy after accessibility-large coverage. `dynamic-type-2026-06-26/onboarding-accessibility-large.jpg` verifies the forced onboarding screen keeps its App Limit hierarchy, no-logo watercolor card, and visible `Allow Screen Time` CTA at `accessibility-large`.
17. Dynamic Type Today: healthy after accessibility-large coverage. `dynamic-type-2026-06-26/today-accessibility-large.jpg` verifies Today, First App Limit, Today focus, Attention streak, and tab navigation remain readable without repeated logo or brand-mark card wallpaper.
18. Dynamic Type Settings: healthy with normal scroll tradeoff. `dynamic-type-2026-06-26/settings-accessibility-large.jpg` verifies the Settings sheet keeps App Limits and Week Archive controls readable at `accessibility-large`; lower explanatory text continues below the viewport as scrollable content.
19. Native semantic onboarding: healthy after runtime snapshot coverage. `native-semantics-2026-06-26/AUDIT.md` records `Allow Screen Time`, `Skip App Limit for now`, and the combined `App Limit setup. One app. Less gravity.` hero label.
20. Native semantic Today: healthy after runtime snapshot coverage. `native-semantics-2026-06-26/AUDIT.md` records `Settings`, `Set App Limit`, `Set one focus`, `Start reset`, `Open weeks archive`, and bottom tabs as semantic tap targets.
21. Native semantic Settings: healthy after runtime snapshot coverage. `native-semantics-2026-06-26/AUDIT.md` records `Done`, First App Limit entry, Archive Span decrement/increment, reminder switches, and `Edit`.
22. Native semantic App Limits lock setup: healthy after runtime snapshot coverage. `native-semantics-2026-06-26/AUDIT.md` records `6-digit PIN`, `Confirm PIN`, `Self PIN`, `Accountability PIN`, and `Save PIN` on the inspected First App Limit drill-in path.
22a. Native target order and modal isolation: healthy for bounded runtime target-list proof. `native-target-order-2026-06-26/AUDIT.md` records forced onboarding target order (`Allow Screen Time` then `Skip App Limit for now`), Today target order (`Settings`, `Set App Limit`, `Set one focus`, `Start reset`, `Open weeks archive`, tabs), Settings modal target isolation after hiding/disabling the underlying tab content, and App Limits PIN setup target order before and after `Save PIN` becomes enabled.
23. Reduced Motion source contract: healthy after native and web source coverage. `reduced-motion-2026-06-26/AUDIT.md` records native `accessibilityReduceMotion` guards for skeleton pulse, timer progress easing, breathing orb continuous rotation/scale/blur, and Settle leaf pulse, plus web `useReducedMotion` / `prefers-reduced-motion` coverage.
24. zh-Hant runtime localization: healthy for the core path after fresh coverage. `zh-hant-runtime-2026-06-26/onboarding-zh-hant.jpg`, `today-zh-hant.jpg`, and `settings-zh-hant.jpg` verify Traditional Chinese runtime text for App Limit-first onboarding, the Today First App Limit card, Today focus/reset/archive controls, and first-layer Settings App Limits / Week Archive copy.
25. zh-Hant Advanced App Limits lock lifecycle: healthy for the inspected lock branches. `zh-hant-advanced-app-limits-2026-06-26/app-limits-lock-self-pin-zh-hant.jpg`, `app-limits-lock-accountability-pin-zh-hant.jpg`, `app-limits-locked-entry-zh-hant.jpg`, `app-limits-incorrect-pin-zh-hant.jpg`, `app-limits-cooldown-zh-hant.jpg`, and `app-limits-unlocked-management-zh-hant.jpg` verify Traditional Chinese runtime text for the self PIN setup, accountability PIN setup, locked entry, incorrect PIN, cooldown, and unlocked management segments.
26. zh-Hant Gate Settings: healthy for the inspected Morning Gate and Before Feed branches. `zh-hant-gate-settings-2026-06-26/morning-before-feed-settings-zh-hant.jpg` and `before-feed-shortcut-guide-zh-hant.jpg` verify Traditional Chinese runtime text for Morning Gate, Before Feed detailed settings, and the Shortcut guide.
27. zh-Hant Pulse / Recovery: healthy for the inspected Pulse root and Recovery permission-state branches. `zh-hant-pulse-recovery-2026-06-26/pulse-recovery-root-zh-hant.jpg` and `pulse-topic-cards-zh-hant.jpg` verify Traditional Chinese runtime text for the Pulse root, Recovery permission card, opt-in explanation, topic summary, and lower Pulse topic-card stack. The source now stores Pulse locale identity and replaces English-looking generated cards with localized fallback cards in non-English locales.
28. zh-Hant Recovery ready/detail: healthy for deterministic runtime evidence. `zh-hant-recovery-ready-detail-2026-06-26/recovery-ready-card-zh-hant.jpg` and `recovery-detail-zh-hant.jpg` verify Traditional Chinese runtime text for the Recovery ready-state card, score, readiness labels, sleep/training metrics, and Recovery Signals detail route. This uses `-MoriUseMockRecoveryReadyForUITest` fixture data and does not claim live Apple Health database sample coverage.
29. Recovery HealthKit sample service: healthy for service-level HealthKit-shaped coverage. `recovery-healthkit-samples-2026-06-26/AUDIT.md` verifies `MoriRecoveryHealthService.snapshot(requestAuthorization:)` can produce a ready `openReady` snapshot from real `HKQuantitySample`, `HKCategorySample`, and `HKWorkout` objects through an injected `MoriRecoveryHealthSampleServing` store. This closes the previous absence of HealthKit sample-object service proof while still not claiming live user Apple Health database samples or Apple authorization-sheet coverage.
30. zh-Hant Watch / Widget source localization: healthy for source-level controls and widget component paths. `zh-hant-watch-widget-source-2026-06-26/AUDIT.md` verifies Watch Bell settings, Watch timer setup, Watch notification copy, Widget title component paths, and WidgetKit gallery metadata descriptions now have source-level zh-Hant coverage.
31. zh-Hant Watch app root runtime: healthy for the inspected root surface. `watch-runtime-zh-hant-20260626/watch-app-root.png` captured the earlier English fallback `archive week`; after rebuilding `MoriWatch`, `watch-runtime-zh-hant-20260626/watch-app-root-fixed.png` verifies the visible Watch root now shows `歸檔週`, `重置`, and `鈴聲已暫停`. Widget rendered families, notification delivery UI, and full VoiceOver traversal remain outside this proof.
32. Watch complication source/compiled proof: healthy for bounded source and compiled-asset evidence. `watch-complications-source-20260626/AUDIT.md` verifies `MoriWatchWidgets` and `MoriWatchPulseWidget` both define `.accessoryCircular`, `.accessoryCorner`, `.accessoryRectangular`, and `.accessoryInline` family branches, route to `mori://week/archive` and `mori://pulse/recovery`, use Watch-specific `Gauge`, `.accessoryCircularCapacity`, `.widgetCurvesContent()`, and `MoriBitmapIconImage` primitives, and compile into `MoriWatchWidgets.appex` with `moriIconRoots`, `moriIconPulse`, and `moriIconHeart`. This proves source wiring and compiled botanical bitmap assets only; it does not prove rendered complications on an Apple Watch face.
33. iOS Widget runtime: healthy for Today Home Screen system families, Journal / Pulse Home Screen inspected system families, Pulse Lock Screen editor accessory placement, Journal / Pulse WidgetKit system-family logs, and Today / Pulse Lock Screen circular/rectangular accessory paths. `widget-runtime-20260626/ios-home-mori-today-small-widget-fixed.jpg` shows rendered `Today`, `0 min`, `reclaimed today`, and `0%` content. `widget-runtime-20260626/ios-home-mori-today-medium-widget-fixed.jpg` shows a rendered medium Week Archive widget. `widget-runtime-20260626/ios-home-mori-today-large-widget-fixed.jpg` shows a rendered large Week Archive widget with `Week 1,566`, `38%`, `0%`, `0`, and `0 min` stats. `widget-runtime-20260626/ios-home-mori-pulse-small-widget-fixed.jpg`, `widget-runtime-20260626/ios-home-mori-pulse-medium-widget-fixed.jpg`, and `widget-runtime-20260626/ios-home-mori-pulse-large-widget-fixed.jpg` show Pulse `systemSmall`, `systemMedium`, and `systemLarge` rendered on the Home Screen. `widget-runtime-20260626/ios-home-mori-journal-pulse-small-widgets-fixed.jpg` shows Journal `systemSmall`, Pulse `systemSmall`, and Today large widgets rendered together on watercolor paper. `widget-runtime-20260626/ios-home-mori-journal-medium-widget-fixed.jpg` shows Journal `systemMedium` rendered on the Home Screen. `widget-runtime-20260626/ios-lockscreen-editor-mori-pulse-accessory-widgets.jpg` shows Pulse rectangular and circular accessory widgets placed in the Lock Screen editor with `Pulse`, `Open Pulse for today's signal`, `Bloom 0%`, `0 Seeds`, and `0%` visible. `widget-runtime-20260626/widgetkit-log-journal-pulse-widgets.txt` records request success, ready state, reload success, and live-content transitions for `MoriJournalQuickStartWidget` Journal `systemSmall` / `systemMedium` and `MoriPulseWidget` Pulse `systemSmall` / `systemMedium` / `systemLarge`. `widget-runtime-20260626/widgetkit-log-after-medium-large.txt` records `MoriWidgets`, `systemSmall`, `systemMedium`, `systemLarge`, `Content state did change to ready`, `Content load successful`, and `Transitioning from snapshot to live content`. `widget-runtime-20260626/widgetkit-log-after-fix.txt` records `Request ended for MoriPulseWidget:accessoryInline - success.`, `Reload com.mettalabs.mori.widgets:MoriPulseWidget:accessoryInline: succeeded with 1 entries`, `Request ended for MoriWidgets:accessoryInline - success.`, and `Reload com.mettalabs.mori.widgets:MoriWidgets:accessoryInline: succeeded with 1 entries`, proving only descriptor, placeholder archive, and reload success for Today / Pulse `accessoryInline`. `widget-runtime-20260626/widgetkit-log-lockscreen-accessory-attempt.txt` records `MoriWidgets:accessoryCircular`, `MoriWidgets:accessoryRectangular`, `MoriPulseWidget:accessoryCircular`, `MoriPulseWidget:accessoryRectangular`, request success, reload success, ready state, and live-content transitions, with no imageTooLarge, ArchivingError, or timelineReloadFailed. The previous blank placeholder captures remain in the same audit folder as before evidence.

## Strengths

- The onboarding surface no longer reads as old countdown, funnel, or logo-first design.
- Native and web share the same material language: warm paper, botanical wash, deep leaf ink, sage controls, and restrained card surfaces.
- Default cards now behave as quiet content containers rather than repeated brand marks; `MoriPlainWatercolorCardBackground` uses an opaque watercolor-paper backing with the dedicated `moriCardPaperWash` bitmap, and the SwiftUI `moriSanctuaryCard` / `moriSanctuaryBox` APIs no longer expose `backdrop`, `showsWave`, or `showsTexture` parameters for ordinary product cards.
- Accent-toned card boxes can now use no-logo botanical paper variants (`moriCardSageWash`, `moriCardWarmWash`, and `moriCardCoolWash`) from the generated bitmap recipe. These are paper material accents, not logo, badge, seedling, circular emblem, or wordmark wallpapers.
- Primary action materials now have explicit bitmap coverage through `moriButtonWash`, so buttons share the watercolor-paper system instead of falling back to flat synthetic slabs or brand-mark decoration.
- The active bitmap contract no longer carries `moriBotanicalCardWash`; card material stays plain paper, while botanical artwork is limited to screen-level atmosphere, bitmap icons, or deliberate small ornaments.
- Settle's Mindfulness Bell card no longer carries a decorative corner wash; its botanical theme now comes from the screen atmosphere, bitmap icon, and paper material.
- Reset root and first expanded reset-menu practice cards no longer render the previous dense Seed/domain pill row. The current runtime Reset screenshots show one quiet inline summary on watercolor paper, keeping the root and expanded card layer action-first.
- Pulse no longer opens as a topic-management dashboard by default. The current runtime Pulse screenshots show Recovery permission, one compact `Pulse topics` summary, the first topic insight in the first viewport, an explicit expanded first layer with active/queued topics plus a second-level `Edit topic list` disclosure, and the full topic library only after the second deliberate tap.
- Design infrastructure backs the visual system with gates, generated assets, screenshot checks, and compiled asset inspection, including `moriButtonWash` across the main app, shield extension, iOS widgets, Watch app, and Watch widgets.
- Web mobile and desktop evidence show responsive continuity rather than a separate marketing skin.
- Settings, First App Limit setup, Advanced App Limits lock, incorrect PIN, cooldown, unlock, and lock removal now have dedicated runtime screenshot evidence, including the new `mori://settings` route, the direct `mori://app-limit` setup route, and the explicit `mori://app-limit-settings` management route.
- Central native typography now uses SwiftUI Dynamic Type text-style tokens for the shared display, title, body, callout, caption, micro, metric, sanctuary, header, and primary button surfaces inspected in the Dynamic Type audit.
- Token-level native and web contrast checks now pass for primary ink, secondary ink, muted ink, button text, web body text, web tab text, and large accent text. The web secondary and muted text alpha values were tightened so paper-watercolor softness does not fall below the contrast gate.
- Core runtime semantic targets now have dedicated evidence for onboarding, Today, Settings, and App Limits lock setup. This closes the previous gap where accessibility was inferred from source labels and screenshots rather than verified from runtime snapshots.
- Core runtime target order and modal target isolation now have dedicated evidence. `ContentView` hides, disables, and stops hit-testing the underlying tab content and tab bar while a Mori app sheet is active; `native-target-order-2026-06-26/AUDIT.md` verifies the Settings and App Limits target lists no longer expose underlying Today root action targets.
- Reduced Motion source contracts now cover native repeating motion and web motion surfaces. Continuous skeleton, breathing, and pulse animation are guarded by `accessibilityReduceMotion`; web entrance, pulse, hover transform, and transition surfaces are guarded by `useReducedMotion` or `prefers-reduced-motion`.
- zh-Hant runtime localization now has dedicated evidence for the core daily path. The App Limit onboarding, Today first viewport, and first-layer Settings no longer rely on English-only copy in the inspected zh-Hant runtime snapshots.
- zh-Hant Advanced App Limits lock lifecycle now has dedicated evidence for the self PIN setup, accountability PIN setup, locked entry, incorrect PIN, cooldown, and unlocked management segments, closing the observed English footer and accountability instruction leak on that branch and adding runtime proof for the lock-management loop.
- zh-Hant Gate Settings now has dedicated evidence for Morning Gate, Before Feed detailed settings, and the Shortcut guide, closing the observed English literals in those inspected branches.
- zh-Hant Pulse / Recovery now has dedicated runtime evidence for the Pulse root, Recovery permission state, and generated-card fallback. MoriDailyPulse locale fallback now prevents English cached or generated cards from leaking into the inspected zh-Hant Pulse topic-card stack.
- zh-Hant Recovery ready/detail now has deterministic runtime evidence. The ready-state card and Recovery Signals detail route show score, readiness, sleep, training, and signal copy in Traditional Chinese without relying on live HealthKit state.
- Recovery service now has HealthKit-shaped sample proof. `scripts/check_recovery_healthkit_sample_audit.sh` compiles and runs `MoriRecoveryHealthService.snapshot(requestAuthorization:)` against real `HKQuantitySample`, `HKCategorySample`, and `HKWorkout` objects through an injected sample store, proving the scoring path can produce ready HRV, resting-heart-rate, sleep, respiratory-rate, and temperature signals without using the UI fixture.
- zh-Hant Watch / Widget source coverage now closes the obvious English literal path in Watch Bell settings, Watch timer setup minute labels, Watch notification messages, Widget component titles, and WidgetKit gallery metadata descriptions. This reduces the remaining Watch / Widget localization gap to rendered runtime layout proof rather than missing source keys.
- zh-Hant Watch app root runtime evidence now closes the observed `archive week` fallback on the root Watch screen. The fixed screenshot proves the inspected root surface renders `歸檔週`, `重置`, and `鈴聲已暫停` in Traditional Chinese.
- Watch complication source/compiled proof now verifies both Watch widget kinds support `.accessoryCircular`, `.accessoryCorner`, `.accessoryRectangular`, and `.accessoryInline`, route to the intended deep links, and carry compiled botanical bitmap assets. Runtime watch-face rendering remains outside this proof.
- iOS Widget runtime evidence now closes the blank Today `systemSmall` placeholder seen earlier and extends screenshot proof to Today `systemMedium` / `systemLarge`, Journal `systemSmall` / `systemMedium`, Pulse `systemSmall` / `systemMedium` / `systemLarge`, Pulse Lock Screen editor accessory placement, Journal / Pulse WidgetKit system-family render paths, Today / Pulse `accessoryCircular` / `accessoryRectangular`, and bounded Today / Pulse `accessoryInline` descriptor / placeholder archive / reload success. The fixed screenshots prove inspected Home Screen widgets render real content on watercolor paper, the Lock Screen editor screenshot proves Pulse accessories can be placed visibly, and the after-fix WidgetKit logs prove the inspected widget kinds reached ready/live states without the previous image-size failure signatures while proving only archive/reload success for `accessoryInline`.
- Week Archive now has source/build proof that the default week surface starts with a focused current-year map and keeps the full multi-year map behind disclosure. This reduces default density without deleting the long-view capability, and `bash scripts/check_redesign_release_readiness.sh --skip-web-build` passed after the change.

## UX Risks

- Week Archive no longer defaults to the dense historical map in source. The remaining risk is runtime screenshot refresh and accessibility/localization proof for the new collapsed focused-year state and expanded full-map state.
- Reset chip density is improved in the inspected root and first expanded runtime screenshots. The remaining Reset risk is full-scroll, localized, Dynamic Type, and assistive-tech coverage, not proof that the expanded menu still uses dense card chrome.
- Pulse secondary controls are improved in the inspected default, first-expanded, and second-level topic-library states. The remaining Pulse risks are accessibility and localization depth, not default dashboard density.
- Settings and Advanced App Limits use native form density. They are clear and functional, but intentionally more utilitarian than the calmer root screens.

## Accessibility Risks

- Log placeholders, disabled controls, onboarding, Today, and Settings now have fresh screenshot evidence, including `accessibility-large` coverage for core surfaces. Core onboarding, Today, Settings, and App Limits lock setup semantic targets now have runtime snapshot evidence, and token-level native/web color contrast checks now pass. This still does not prove screenshot-level contrast for every state or full accessibility compliance.
- Pulse secondary badges, permission CTA, compact topic summary, expanded first-layer topic manager, second-level topic library, and the top-left back control now have fresh screenshot evidence, and Recovery has service-level HealthKit-shaped sample proof. This still does not prove VoiceOver traversal order, live Apple Health database sample states, localized topic-library layout, or every Dynamic Type route.
- Runtime semantic snapshots prove visible labels and actionable targets on inspected surfaces. The target-order audit proves a runtime target-list proxy for core action order and verifies Settings / App Limits modal target isolation after the underlying Today tab content was hidden, disabled, and removed from hit-testing while app sheets are active. Reduced Motion source gates prove key continuous motion is guarded, but these checks do not prove full OS-level reduced-motion runtime behavior, full OS VoiceOver traversal order or Switch Control scan behavior, hardware keyboard order, actual spoken output, or hit target sizes.
- zh-Hant runtime snapshots prove the inspected core path, Advanced App Limits lock lifecycle, Gate Settings branches, Pulse / Recovery permission-state surfaces, deterministic Recovery ready/detail surfaces, and the Watch app root surface only. Widget rendered localized-layout evidence, live Apple Health database Recovery sample coverage, and long-tail settings still need separate proof before claiming complete localization.
- zh-Hant Advanced App Limits snapshots prove App Limits Lock setup, locked entry, incorrect PIN, cooldown, and unlocked App Limits management. They do not prove Watch or Widget rendered layout, live Apple Health database Recovery samples, or every long-tail route.
- zh-Hant Gate Settings snapshots prove Morning Gate, Before Feed detailed settings, and the Shortcut guide. They do not prove every picker state, every Apple authorization sheet, Watch or Widget rendered layout, live Apple Health database Recovery samples, or every long-tail settings route.
- zh-Hant Pulse / Recovery snapshots prove the Pulse root, Recovery permission-state card, Recovery opt-in copy, lower Pulse topic-card fallback behavior, and deterministic Recovery ready/detail route. The HealthKit sample service audit proves the English service scoring path with HealthKit framework object types. Together they still do not prove zh-Hant Recovery ready-state/detail screens with live user Apple Health database samples, Apple Health authorization sheets, every live Pulse follow-up answer, Watch or Widget rendered layout, or every long-tail localized route.
- zh-Hant Watch / Widget source audit proves localized source paths for the inspected Watch and Widget strings, including WidgetKit gallery metadata keys. The Watch app root runtime screenshot proves only the root Watch screen no longer leaks the observed `archive week` fallback. It does not prove Widget rendered layout across families, system gallery rendering, Apple Watch notification delivery UI, or VoiceOver order.
- Watch complication source/compiled proof verifies the two watchOS widget kinds, four supported complication families, deep links, Watch-specific source primitives, compiled WidgetKit extension identity, and compiled botanical bitmap assets. It does not prove rendered complications on an Apple Watch face, WidgetKit gallery rendering, localized rendered layout, notification delivery UI, VoiceOver order, Dynamic Type behavior, or live Apple Health database samples.
- Widget rendered proof now covers iOS Today systemSmall, systemMedium, and systemLarge via Home Screen screenshots, Journal systemSmall/systemMedium and Pulse systemSmall/systemMedium/systemLarge via Home Screen screenshots, Pulse accessoryCircular/accessoryRectangular placement via a Lock Screen editor screenshot, Pulse systemSmall/systemMedium/systemLarge and Journal systemSmall/systemMedium via WidgetKit ready/live logs, plus Today and Pulse Lock Screen accessoryCircular and accessoryRectangular via WidgetKit ready/live logs. It also proves Today and Pulse `accessoryInline` descriptor, placeholder archive, and reload success through `widgetkit-log-after-fix.txt`. It proves the inspected Home Screen widget surfaces are not blank after the dedicated `moriWidgetPaperWash` and `moriWidgetBotanicalWash` assets, proves visible Pulse accessory placement in the Lock Screen editor, and proves the inspected Lock Screen accessory paths load without the previous image-size failure signatures. It does not prove accessoryInline live rendering, final saved Lock Screen screenshots, Widget gallery localization, Watch complication watch-face rendering, notification delivery UI, or VoiceOver order.

## Evidence Limits And Verification Gaps

- Current native evidence covers the forced onboarding state, Today, Reset root simplification, Reset first expanded menu simplification, Log, Week Archive refreshed first viewport before the focused-year source change, Week Archive source/build density reduction for the focused current-year default and disclosed full map, Pulse default topic-summary simplification, Pulse expanded first-layer topic-manager simplification, Pulse second-level topic-library edit mode, Settings, First App Limit setup, Advanced App Limits PIN setup/lock entry, incorrect PIN feedback, cooldown feedback, successful PIN verification into App Limits management, PIN removal returning to a setup-only action state, source-level Reset practice card chip-density reduction, source-level Pulse topic-manager gating, `accessibility-large` Dynamic Type coverage for onboarding/Today/Settings, zh-Hant runtime coverage for onboarding/Today/first-layer Settings, zh-Hant App Limits Lock lifecycle coverage for self PIN, accountability PIN, locked entry, incorrect PIN, cooldown, and unlocked management, zh-Hant Gate Settings coverage for Morning Gate, Before Feed detailed settings, and Shortcut guide, zh-Hant Pulse / Recovery coverage for Pulse root, Recovery permission state, opt-in copy, generated-card fallback behavior, deterministic Recovery ready/detail state, HealthKit-shaped Recovery sample service coverage, zh-Hant Watch / Widget source localization coverage for inspected controls, component title paths, and WidgetKit gallery metadata keys, zh-Hant Watch app root runtime screenshot coverage, Watch complication source wiring and compiled botanical bitmap asset coverage, iOS Widget Today `systemSmall`, `systemMedium`, `systemLarge`, Journal `systemSmall`, `systemMedium`, Pulse `systemSmall`, `systemMedium`, `systemLarge`, Pulse Lock Screen editor accessory placement, Journal / Pulse WidgetKit system-family logs, Today `accessoryCircular`, Today `accessoryRectangular`, Pulse `accessoryCircular`, Pulse `accessoryRectangular`, Today `accessoryInline` descriptor / placeholder archive / reload success, and Pulse `accessoryInline` descriptor / placeholder archive / reload success evidence, runtime semantic targets for onboarding/Today/Settings/App Limits lock setup, runtime target-list proxy evidence for onboarding/Today/Settings/App Limits PIN setup order and modal target isolation, source-level reduced-motion guards for key continuous motion, and a final-build refresh for the three previously weak surfaces. It does not visually or semantically cover live Apple Health database recovery samples, every recovery data state, timer, picker, empty, Apple authorization sheets, the lower full-scroll Reset menu, localized expanded Reset layout, localized Pulse topic-library layout, refreshed runtime screenshots for the new Week Archive collapsed focused-year state and expanded full-map state, accessoryInline live rendering, final saved Lock Screen screenshots, Watch complication rendered watch-face layout, full Watch route coverage, full OS VoiceOver traversal order or Switch Control scan behavior, or every localized state.
- Current web evidence covers the landing/app-limit flow and proof cards, with token-level contrast coverage for primary, secondary, muted, button, tab, and large accent text. It does not cover every language/menu permutation, every hardcoded one-off color in future changes, or browser font fallback.
- Screenshot audit proves visible direction and major regression absence, not complete accessibility compliance.
- The worktree remains broad and dirty; this audit is evidence for design readiness, not a claim that the whole repository is clean or ready to commit unchanged.

## Release Readiness Decision

Pass with refreshed runtime evidence and non-blocking polish risks.

The inspected evidence supports the current direction: Screen Time-first, botanical watercolor, bitmap paper assets including `moriButtonWash`, no repeated card logos, no old funnel/hourglass motif, and no visible old mortality-countdown onboarding.

Fresh runtime evidence resolves the previous Log, Week Archive, Pulse default dashboard-density, Pulse expanded first-layer topic-manager, Pulse second-level topic-library, Reset root chip-density, Reset expanded first-layer menu, and Advanced App Limits incorrect-PIN/cooldown screenshot gaps for the pre-density-pass runtime surfaces. Week Archive also has source/build evidence for the focused current-year default and disclosed full-map density reduction. Settings, First App Limit setup, Advanced App Limits lock, incorrect PIN, cooldown, successful PIN unlock, PIN lock removal, Dynamic Type core surfaces, zh-Hant core runtime surfaces, zh-Hant Advanced App Limits lock lifecycle, zh-Hant Gate Settings, zh-Hant Pulse / Recovery permission-state coverage, zh-Hant Recovery deterministic ready/detail coverage, Recovery HealthKit-shaped sample service coverage, zh-Hant Watch / Widget source coverage, zh-Hant Watch app root runtime coverage, Watch complication source/compiled coverage, semantic accessibility targets, target-list proxy order and modal-isolation evidence, reduced-motion source contracts, and token-level contrast checks now have dedicated evidence. Do not mark the broader goal complete from this audit alone: the remaining release pass still needs a reviewable change set and broader runtime/accessibility coverage if the claim is "whole infrastructure and UI design complete."

Dynamic Type core surfaces, semantic accessibility targets, reduced-motion source contracts, and token-level contrast checks now have dedicated evidence; zh-Hant core runtime surfaces now have dedicated evidence too.

zh-Hant Advanced App Limits lock lifecycle, zh-Hant Gate Settings, zh-Hant Pulse / Recovery permission-state coverage, zh-Hant Recovery deterministic ready/detail coverage, Recovery HealthKit-shaped sample service coverage, zh-Hant Watch / Widget source coverage, zh-Hant Watch app root runtime coverage, Watch complication source/compiled coverage, iOS Widget Today `systemSmall`, `systemMedium`, `systemLarge`, Journal `systemSmall`, `systemMedium`, Pulse `systemSmall`, `systemMedium`, `systemLarge`, Pulse Lock Screen editor accessory placement, Journal / Pulse WidgetKit system-family logs, Today `accessoryCircular`, Today `accessoryRectangular`, Pulse `accessoryCircular`, Pulse `accessoryRectangular`, and bounded Today / Pulse `accessoryInline` descriptor / placeholder archive / reload success evidence now have dedicated evidence too, while accessoryInline live rendering, final saved Lock Screen screenshots, Watch complication rendered watch-face layout, full Watch route coverage, live Apple Health database sample coverage, and other long-tail localized layouts remain outside this localized runtime proof.

## Required Verification Commands

Run these before treating the redesign as release-ready:

```sh
bash scripts/check_redesign_release_readiness.sh
bash scripts/check_web_screenshot_audit.sh
bash scripts/check_main_surface_screenshot_audit.sh
bash scripts/check_reset_simplification_screenshot_audit.sh
bash scripts/check_pulse_simplification_screenshot_audit.sh
bash scripts/check_main_surface_refresh_screenshot_audit.sh
bash scripts/check_system_flow_screenshot_audit.sh
bash scripts/check_dynamic_type_screenshot_audit.sh
bash scripts/check_zh_hant_runtime_localization_audit.sh
bash scripts/check_zh_hant_advanced_app_limits_audit.sh
bash scripts/check_zh_hant_gate_settings_audit.sh
bash scripts/check_zh_hant_pulse_recovery_audit.sh
bash scripts/check_zh_hant_recovery_ready_detail_audit.sh
bash scripts/check_recovery_healthkit_sample_audit.sh
bash scripts/check_zh_hant_watch_widget_source_audit.sh
bash scripts/check_zh_hant_watch_runtime_audit.sh
bash scripts/check_watch_complication_source_audit.sh
bash scripts/check_widget_runtime_audit.sh
bash scripts/check_color_contrast_tokens.sh
bash scripts/check_accessibility_semantics_audit.sh
bash scripts/check_accessibility_target_order_audit.sh
bash scripts/check_reduced_motion_contract.sh
```

When using XcodeBuildMCP instead of the shell native build, run `build_sim` for the `Mori` scheme and then:

```sh
bash scripts/check_compiled_design_artifacts.sh
```
