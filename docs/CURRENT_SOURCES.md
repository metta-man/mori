# Mori Current Sources

**Updated:** 2026-07-25
**Purpose:** Resolve which files govern current product, design, implementation, build targets, and release evidence.

## Conflict Resolution

Use the narrowest authoritative source for the question:

1. **Runtime behaviour and data contracts:** current source code
2. **Target membership, bundle configuration, and generated project:** `project.yml`
3. **Approved UI composition and visual direction:** `DesignReferences/MORI_DESIGN_SPEC.md` plus the approved images in `DesignReferences/`
4. **Product language and interaction constraints:** `MORI_DESIGN_SYSTEM_V2.md`
5. **SwiftUI component usage:** current files under `DesignSystem/`, indexed by `DesignSystem/MoriDesignSystemDocumentation.md`
6. **Brand identity and external asset use:** `brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md`
7. **App Limit-first onboarding:** `q2-prep/onboarding/ONBOARDING_FLOW_DESIGN.md`
8. **Verification evidence and known coverage gaps:** `MORI_REDESIGN_RELEASE_AUDIT.md`

`MORI_REDESIGN_OPERATING_MODEL.md` explains how these sources work together. `AGENTS.md` defines mandatory execution rules for UI changes.

When two documents disagree:

- Prefer source code for what the app currently does.
- Prefer `DesignReferences/` for what affected UI must look and feel like.
- Prefer `MORI_DESIGN_SYSTEM_V2.md` for current product wording and interaction constraints.
- Treat the release audit as evidence about verification status, not permission to override design.
- Treat `docs/archive/` as historical context only.

## Active Product And Design Sources

| Concern | Source |
| --- | --- |
| UI visual direction | `DesignReferences/MORI_DESIGN_SPEC.md` |
| Primary visual reference | `DesignReferences/mori-approved-reference.jpeg` |
| Detailed Today reference | `DesignReferences/mori-today-view-reference.jpg` |
| Screen-flow reference | `DesignReferences/mori-screen-flow-reference.jpg` |
| Product language and interaction | `MORI_DESIGN_SYSTEM_V2.md` |
| Redesign operating model | `MORI_REDESIGN_OPERATING_MODEL.md` |
| SwiftUI component guide | `DesignSystem/MoriDesignSystemDocumentation.md` |
| Brand and external assets | `brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md` |
| Active onboarding | `q2-prep/onboarding/ONBOARDING_FLOW_DESIGN.md` |
| Release evidence | `MORI_REDESIGN_RELEASE_AUDIT.md` |
| Known engineering debt | `docs/quality/TECH_DEBT.md` |

## Active Native Build Graph

`project.yml` is the XcodeGen source of truth. `Mori.xcodeproj` is generated output and must be committed in sync with it.

| Target | Platform | Source paths |
| --- | --- | --- |
| `Mori` | iOS app | `App/`, `Features/`, `Models/`, `DesignSystem/`, `Services/`, `Shared/`, `Localization/` |
| `MoriScreenTimeMonitor` | iOS extension | `ScreenTimeMonitor/` plus the explicit shared service files, `Shared/`, and `Localization/` listed in `project.yml` |
| `MoriShieldConfiguration` | iOS extension | `ShieldConfiguration/`, `Services/AttentionShieldStateStore.swift`, `Shared/`, `Localization/` |
| `MoriShieldAction` | iOS extension | `ShieldAction/`, the explicit shared gate/state service files, `Shared/`, `Localization/` |
| `MoriWidgets` | iOS extension | `Widgets/`, `Shared/`, `Localization/` |
| `MoriWatch` | watchOS app | `WatchApp/`, `Shared/`, `Localization/` |
| `MoriWatchWidgets` | watchOS extension | `WatchWidgets/`, `Shared/`, `Localization/` |

Do not move or archive these paths without updating `project.yml`, regenerating `Mori.xcodeproj`, and running the compiled-artifact checks.

## Active Web Sources

- Client and styles: `www/src/`
- Pulse proxy and server code: `www/server/`
- Package/build configuration: current files under `www/`

The web surface is not an Xcode target. Native and web share product language and visual direction, but each platform's current source defines its implementation details.

## Design-System API Sources

- Tokens: `DesignSystem/MoriDesignTokens.swift`, `DesignSystem/MoriThemeTokens.swift`
- Root composition: `DesignSystem/MoriPaperBackground.swift`, `DesignSystem/MoriComponents.swift`, `DesignSystem/MoriSanctuaryHeaders.swift`
- Cards: `DesignSystem/MoriSanctuarySurfaces.swift`, `DesignSystem/MoriSanctuaryBoxBackground.swift`
- Actions: `DesignSystem/MoriActionComponents.swift`
- Metrics and states: `DesignSystem/MoriSanctuaryMetrics.swift`, `DesignSystem/MoriStateComponents.swift`
- Shared modifiers: `DesignSystem/MoriViewModifiers.swift`
- Generated bitmap art and icons: `Shared/MoriGeneratedArt.swift`, `Shared/MoriGeneratedArt.xcassets`

Read exact signatures in source before adding an example to documentation.

## Naming Contract

- **Life Grid** is the display name in UI copy, product prose, accessibility labels, and new screenshot descriptions.
- `WeekArchive*` is the internal prefix for existing Swift types, files, routes, stores, and persistence seams.
- An internal path such as `Features/WeekArchive/WeekArchiveViews.swift` can and should render the display label “Life Grid”.
- Do not rename stable internal identifiers merely to align display text.

## Historical Material

All superseded work is indexed by `docs/archive/README.md`, including:

- early design briefs and personas,
- mockups and HTML prototypes,
- market and architecture research,
- icon concepts,
- historical Q2 preparation,
- superseded product specifications,
- completed task cards and QA notes.

The only active file left under `q2-prep/` is `q2-prep/onboarding/ONBOARDING_FLOW_DESIGN.md`.

## Verification Entry Points

Broad readiness:

```sh
bash scripts/check_redesign_release_readiness.sh
```

Fast documentation or web-only iteration:

```sh
bash scripts/check_redesign_release_readiness.sh --skip-native-build
```

For UI work, follow `AGENTS.md`, refresh affected screenshots, complete two visual-refinement passes, and run the focused audit commands named in `MORI_REDESIGN_RELEASE_AUDIT.md`.
