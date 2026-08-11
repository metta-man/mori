# Mori Redesign Operating Model

## Current Product Promise

Mori is a Screen Time-first calm app with a botanical watercolor interface. It helps the user place a deliberate boundary between impulse and feed, choose a quiet reset, and keep light evidence of lived time.

The active visual system is watercolor paper, botanical bitmap washes, deep leaf ink, sage controls, editorial hierarchy, and restrained spacing. Brand marks belong on OS, store, marketing, and other external brand surfaces. Primary app cards, onboarding cards, widgets, and repeated UI backgrounds are recognized by material and rhythm, not by stamping the logo across them.

## First-Principles Rules

1. Delete before polishing.
2. App Limit and Screen Time flows lead onboarding.
3. Each screen has one clear job and one dominant next action.
4. Cards contain meaningful groups; they are not brand billboards.
5. Botanical art provides screen atmosphere, hero support, or a small functional accent.
6. Bitmap assets are the active visual-material source; ad hoc SVG or synthetic gradient motifs are not.
7. Preserve working behaviour and data integrity while changing presentation.
8. Source files, generated project configuration, documentation, screenshots, and gates must describe the same product.

## Source-Of-Truth Hierarchy

The complete map and conflict rules live in `docs/CURRENT_SOURCES.md`.

1. Runtime behaviour and target membership: current source plus `project.yml`
2. Approved UI composition and visual direction: `DesignReferences/MORI_DESIGN_SPEC.md` and the images in `DesignReferences/`
3. Product language and interaction constraints: `MORI_DESIGN_SYSTEM_V2.md`
4. SwiftUI component usage: `DesignSystem/MoriDesignSystemDocumentation.md` and the corresponding Swift files
5. Brand identity and external asset use: `brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md`
6. App Limit-first onboarding: `q2-prep/onboarding/ONBOARDING_FLOW_DESIGN.md`
7. Verification state and evidence limits: `MORI_REDESIGN_RELEASE_AUDIT.md`

`MORI_REDESIGN_RELEASE_AUDIT.md` can prove or qualify implementation status, but it does not supersede the approved visual reference. Historical work is under `docs/archive/` and is never active direction.

## Product Terminology

- **Life Grid** is the user-facing name in UI copy, product prose, accessibility labels, and new screenshots.
- `WeekArchive*` remains the internal prefix for Swift types, feature paths, stores, routes, and persistence seams.
- Treat this as an intentional presentation boundary. Do not leak the internal name into new UI, and do not destabilize persisted or cross-target identifiers for a cosmetic rename.

## Retired Direction

Do not reintroduce:

- Mortality-countdown onboarding or death-framed setup copy
- Legacy mortality-first framing around Life Grid
- Location or life-expectancy setup
- Hourglass, funnel, old time-seed, forest-ring, or badge-seal motifs
- Logo, wordmark, app-icon, paper-linework mark, seedling, circular emblem, or leaf-mark art as an in-app surface background
- Flat cream panels that ignore the approved watercolor-paper composition
- SF Symbol-first artwork on primary product surfaces
- Streaks, XP, coins, confetti, competitive scores, or punitive progress language

Legacy compatibility names may remain at data-boundary seams when required for persistence or migration. Keep those seams explicit and covered by the design-direction gate.

## Surface Contract

For native root screens, begin with the composition already used by the affected feature. Current shared primitives include `MoriPaperBackground`, `MoriPage`, `MoriRootScrollScreen`, `MoriPageHeader`, and `MoriRootHeader`. Do not migrate a working screen between composition layers as incidental cleanup.

Use `.moriSanctuaryCard(...)` or `.moriSanctuaryBox(...)` for the established sanctuary card treatment. These surfaces resolve through `MoriSanctuaryBoxBackground` and `MoriPlainWatercolorCardBackground`, keeping repeated cards opaque and quiet. Card surfaces do not accept screen-level artwork parameters.

Use `MoriPrimaryButton` for the canonical commitment action, `MoriSecondaryButton` for a quieter alternative, and typed Mori bitmap icon APIs for primary artwork. Generated paper washes such as `moriCardPaperWash`, `moriCardSageWash`, `moriCardWarmWash`, `moriCardCoolWash`, and `moriButtonWash` are material assets, not brand marks.

Web cards mirror the paper treatment through current assets and styles under `www/src/`. Widgets and watch surfaces follow the same rule: quiet paper, clear hierarchy, and botanical accent only where it communicates function.

## Functional Safety

UI work must preserve, unless explicitly changed:

- FamilyControls authorization and selection
- DeviceActivity schedules and ManagedSettings shielding
- Before Feed and App Limit state
- Quiet/deep-session timing and interruption behaviour
- persistence, app-group data, notifications, deep links, and widget/watch sync
- navigation reachability and dismissal
- accessibility semantics and reduced-motion behaviour

## Infrastructure Contract

`project.yml` is the XcodeGen source of truth. The generated `Mori.xcodeproj` must remain in sync. Active native source paths are listed in `docs/CURRENT_SOURCES.md`.

Run the full readiness line before treating a broad redesign change as shippable:

```sh
bash scripts/check_redesign_release_readiness.sh
```

For a fast documentation or web-only pass:

```sh
bash scripts/check_redesign_release_readiness.sh --skip-native-build
```

For affected UI, refresh screenshot evidence and run the relevant audit scripts named in `MORI_REDESIGN_RELEASE_AUDIT.md`. A green source gate is not a substitute for the two visual-refinement passes required by `AGENTS.md`.
