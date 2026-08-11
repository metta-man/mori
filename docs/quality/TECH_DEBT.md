# Mori Technical Debt

**Observed:** 2026-07-25
**Scope:** Current repository evidence, not archived concepts

This register tracks engineering risks that remain after the documentation and archive cleanup. Priorities describe product risk, not estimated effort.

## P1 — Native Automated Test Coverage

**Evidence**

- `project.yml` defines app and extension targets but no native unit-test target.
- Native correctness is currently protected mainly by build checks, shell audits, runtime screenshots, and focused probes.
- Web flow tests exist under `www/src/test/`, so this gap is specific to the native graph.

**Risk**

Persistence, Screen Time state transitions, Life Grid date math, reset timing, recovery scoring, and localization boundaries can regress without a deterministic test failing close to the change.

**Exit criteria**

- Add a native test target through `project.yml`.
- Start with pure logic and persistence seams: `WeekArchiveCalculator`, Screen Time policies/schedule creation, reset/session timing, recovery scoring, and settings migration.
- Run the test target in CI and through the release-readiness entry point.

## P1 — Overlapping Design-System Layers

**Evidence**

- Current feature code uses both the editorial primitives in `MoriComponents.swift` / `MoriThemeTokens.swift` and the established sanctuary primitives in `MoriSanctuary*.swift`.
- Compatibility components remain beside canonical actions and tokens.
- Multiple components solve similar page, card, button, and typography jobs.

**Risk**

New work can choose a locally plausible API that produces a different visual rhythm, token set, or accessibility behaviour. Broad cleanup can also break working screens if it treats compatibility code as unused without checking cross-target usage.

**Exit criteria**

- Inventory component usage across the iOS app, widgets, watch app, and extensions.
- Nominate one preferred primitive for each job while documenting intentional exceptions.
- Migrate one reference-matched screen at a time with builds and screenshot comparison.
- Remove a compatibility API only after repository-wide usage, localization, and cross-target checks pass.

## P1 — Retired Design-Gate Assertions

**Evidence**

- The former `scripts/check_design_direction.sh` mixed deterministic source checks with ignored local screenshots, compiled artifacts, exact prose fragments, and broad bans on SF Symbols or botanical art.
- The approved reference permits botanical screen/hero illustration and standard platform controls such as back, gear, photo, trash, chevron, play, and pause.
- Current source still contains compatibility symbol adapters and some SF Symbol functional pictograms. Deciding which should become Mori bitmap art requires screen-level visual review, not a repository-wide string ban.

**Risk**

Reintroducing the old blanket assertions would make clean clones fail on missing local evidence and could encourage product UI changes made only to satisfy stale grep rules. Removing every icon-level guard, however, could let branded or feature pictograms drift back to generic symbols.

**Existing mitigation**

The deterministic source gate checks the approved references, tracked bitmap catalogs and mirrors, generated botanical recipe, localization parsing, Xcode target wiring, contrast tokens, and the ban on repeated brand marks as card wallpaper. Runtime proof is opt-in through an external evidence root.

**Exit criteria**

- Define a reviewed inventory separating platform controls from branded or functional pictograms.
- Add narrow checks for the latter without banning ordinary navigation, editing, media, or disclosure controls.
- Validate each affected surface against the approved reference before promoting a new assertion to the source gate.

## P1 — Remaining Release-Evidence Gaps

**Evidence**

`MORI_REDESIGN_RELEASE_AUDIT.md` records bounded runtime proof and explicitly lists gaps such as uninspected long-tail states, accessibility traversal, localized layouts, and some widget/watch rendering paths.

**Risk**

A green source/build gate can be mistaken for complete visual, accessibility, localization, or device coverage.

**Exit criteria**

- Close the evidence gaps listed in the release audit for the release claim being made.
- Keep evidence scoped by surface, state, locale, device class, and accessibility setting.
- Do not convert “source present” or “build passed” into a runtime rendering claim.

## P2 — Generated Project Drift

**Evidence**

- `project.yml` is authoritative while `Mori.xcodeproj` is committed generated output.
- A source-path or target-setting change can update one without the other.

**Risk**

Local builds, CI, and Xcode can resolve different target graphs or stale membership.

**Existing mitigation**

The release and compiled-artifact scripts regenerate or validate the project.

**Exit criteria**

- Keep regeneration and drift checking mandatory in CI.
- Treat any target or source-path edit as incomplete until `project.yml`, the generated project, and compiled-artifact checks agree.

## P2 — Week Archive Fetch Predicate Safety

**Evidence**

- `Services/WeekArchiveRecordStore.swift` first assigns a user predicate and then force-unwraps `request.predicate` while adding the optional year predicate.
- A removed, unrelated-history branch used an explicit predicate array for the equivalent fetch. That branch was archived, not cherry-picked, because its broader data model predates the current archive implementation.

**Risk**

The current assignment makes the unwrap appear safe, but the safety depends on nearby statement order. A later refactor could turn a routine filtered fetch into a crash.

**Exit criteria**

- Build the user and optional-year predicates in a local `[NSPredicate]`.
- Assign one `NSCompoundPredicate` without force-unwrapping mutable request state.
- Add fetch coverage for both the all-years and one-year paths.

## P2 — Archive Elapsed-Week Consistency

**Evidence**

- `Models/UserSettings.swift` calculates elapsed weeks as `archiveYearIndex * 52` plus a clamped week within the current archive year.
- `Shared/MoriWidgetSnapshot.swift` and `Models/WeekArchiveCalculator.swift` use total calendar days divided by seven.
- A removed, unrelated-history branch documented year-boundary failures from combining calendar-year and week-of-year components. Its commits were preserved in the Git bundle rather than applied to the current model.

**Risk**

The app, widgets, and generated archive records can disagree near anniversary, leap-year, or calendar-boundary dates, causing different current-week and progress states for the same archive.

**Exit criteria**

- Define one shared elapsed-week calculation with injected `Calendar` and `now` values.
- Reuse it in app settings, widgets/watch snapshots, and archive generation.
- Add tests for dates before the archive start, exact seven-day boundaries, leap days, anniversaries, and the final archive week.

## P2 — Life Grid Presentation Boundary

**Evidence**

- The current user-facing name is Life Grid.
- Stable implementation paths and types use `WeekArchive*`.
- Current user-visible strings still expose “Week Archive” in settings, Today/Log surfaces, widgets, watch widgets, accessibility text, and localization catalogs. Representative sources include `Features/Settings/SettingsView.swift`, `Features/Today/TodayWeekArchiveReferenceCard.swift`, `Widgets/MoriWidgetViews.swift`, `WatchWidgets/MoriWatchWidgets.swift`, and `Localization/*/Localizable.strings`.
- Historical screenshots and release evidence also contain the former display wording.

**Risk**

Internal terminology can leak through fallback strings, localization keys, widgets, watch surfaces, accessibility labels, analytics labels, or new documentation. A broad rename could instead destabilize persistence and cross-target contracts.

**Exit criteria**

- Keep `WeekArchive*` internals stable.
- Create a dedicated UI Task Card for the display-copy migration; follow `AGENTS.md`, including simulator screenshots and two visual-refinement passes for affected surfaces.
- Update and audit user-visible strings across native, widget, watch, accessibility, localization, and web surfaces for Life Grid.
- Add focused localization or snapshot assertions at presentation boundaries.

## P2 — Archive Link Rot

**Evidence**

Historical folders were moved under `docs/archive/` without rewriting their contents, so old root-relative instructions and cross-document links may no longer resolve.

**Risk**

Someone reading an archive for provenance may mistake a broken link for missing current source or copy an obsolete path back into active documentation.

**Exit criteria**

- Preserve historical content as-is unless there is a concrete research need.
- Use `docs/archive/README.md` and `docs/CURRENT_SOURCES.md` as the supported navigation layer.
- If a historical document is revived, revalidate every path and decision before moving any part back into active docs.

## Not Technical Debt

- Keeping `WeekArchive*` as an internal prefix is an intentional compatibility boundary.
- `docs/archive/` containing obsolete concepts is intentional provenance, provided active docs do not cite it as authority.
- Apple approval for the Family Controls entitlement is an external release dependency, not a code-quality defect.
