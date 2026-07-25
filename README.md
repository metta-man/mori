# Mori

Mori is a calm digital-wellbeing app for interrupting automatic phone use, protecting focused time, and keeping a light record of lived days. The native product is built with SwiftUI and Apple's Screen Time frameworks; the repository also contains widgets, a watch app, Screen Time extensions, and the Mori web surface.

## Start Here

- `docs/CURRENT_SOURCES.md` — canonical map of active specifications, implementation, targets, and evidence
- `AGENTS.md` — mandatory rules for Mori UI work
- `DesignReferences/MORI_DESIGN_SPEC.md` and `DesignReferences/mori-approved-reference.jpeg` — approved UI direction
- `MORI_DESIGN_SYSTEM_V2.md` — active product-language and interaction contract
- `DesignSystem/MoriDesignSystemDocumentation.md` — current SwiftUI component guide
- `brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md` — external brand and asset-use rules
- `q2-prep/onboarding/ONBOARDING_FLOW_DESIGN.md` — active App Limit-first onboarding contract

When sources disagree, use the precedence rules in `docs/CURRENT_SOURCES.md`. `MORI_REDESIGN_RELEASE_AUDIT.md` records verification evidence and known gaps; it does not override the approved design references or current source code.

## Active Build Graph

`project.yml` is the XcodeGen source of truth. Keep the generated `Mori.xcodeproj` in sync.

Active native sources are under:

- Main iOS app: `App/`, `Features/`, `Models/`, `DesignSystem/`, `Services/`, `Shared/`, and `Localization/`
- iOS extensions: `Widgets/`, `ScreenTimeMonitor/`, `ShieldAction/`, and `ShieldConfiguration/`
- watchOS: `WatchApp/` and `WatchWidgets/`

The active web implementation is under `www/src/` and `www/server/`.

## Terminology

- The user-facing feature name is **Life Grid**.
- Internal Swift types, files, routes, stores, and persistence seams keep the `WeekArchive*` prefix.
- Do not expose “Week Archive” as new UI copy, and do not rename stable `WeekArchive*` internals merely to change display text.

## Historical Material

Historical briefs, research, mockups, task cards, icon explorations, and superseded QA notes live under `docs/archive/`. They are retained for provenance only and are not implementation or design authority.

The one active file retained under the former Q2 workspace is:

- `q2-prep/onboarding/ONBOARDING_FLOW_DESIGN.md`

## Verification

Run the current release-readiness line with:

```sh
bash scripts/check_redesign_release_readiness.sh
```

For a fast non-native pass while iterating on documentation or web-only work:

```sh
bash scripts/check_redesign_release_readiness.sh --skip-native-build
```

UI work must also follow the screenshot and two-pass comparison requirements in `AGENTS.md`.

## Workspace Hygiene

Check tracked paths and local metadata with:

```sh
bash scripts/check_repo_hygiene.sh
```

`scripts/clean_workspace.sh` is dry-run by default and only targets an explicit repo-local allowlist. Add `--apply` to remove rebuildable caches. Runtime evidence remains protected unless `--include-evidence` is also supplied.

Archived screenshots and compiled evidence are opt-in release proof:

```sh
bash scripts/check_runtime_evidence.sh --evidence-root <archive-path>
```

The evidence manifest must match the clean checked-out commit; historical evidence is reported as stale.

## Screen Time Capability

Mori uses Apple's Screen Time APIs for optional app limits during protected flows. Release and external TestFlight builds require Apple approval for the Family Controls entitlement (`com.apple.developer.family-controls`) on the main app and relevant Screen Time extension targets.
