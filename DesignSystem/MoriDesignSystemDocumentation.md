# Mori SwiftUI Design System

**Status:** Active component guide
**Updated:** 2026-07-25

## Authority And Scope

This file documents the current shared SwiftUI surface. It does not replace:

- `DesignReferences/MORI_DESIGN_SPEC.md` and `DesignReferences/mori-approved-reference.jpeg` for approved composition and visual direction,
- `MORI_DESIGN_SYSTEM_V2.md` for product language and interaction constraints,
- current Swift source for exact signatures and runtime behaviour.

If an example here differs from source, source wins and this guide must be corrected. `docs/CURRENT_SOURCES.md` defines the full precedence order.

## Design Principles

1. **Watercolor paper is the material.** Root screens use paper and screen-level botanical art; ordinary cards remain quiet and opaque.
2. **One dominant action.** Use hierarchy and progressive disclosure before adding more controls.
3. **Material over marks.** App icons, logos, wordmarks, seedling badges, circular emblems, and other brand marks are not card texture.
4. **Illustration belongs to composition.** Screen atmosphere may use botanical bitmap art; repeated cards must not inherit the same painting.
5. **Typed artwork.** Use Mori bitmap icon and generated-art APIs on primary surfaces.
6. **Accessibility is part of the component.** Keep 44pt targets, Dynamic Type, contrast, semantic order, and Reduce Motion behaviour.
7. **Preserve working structure.** Follow the composition pattern already used by the affected screen unless the task explicitly includes migration.

## Source Files

| Concern | Current source |
| --- | --- |
| Core color, type, spacing, radius, motion | `MoriDesignTokens.swift` |
| Editorial semantic tokens and button styles | `MoriThemeTokens.swift` |
| Root paper and botanical screen wash | `MoriPaperBackground.swift`, `MoriBotanicalBackdrops.swift` |
| Reference-matched page composition | `MoriComponents.swift` |
| Sanctuary cards and box modifiers | `MoriSanctuarySurfaces.swift`, `MoriSanctuaryBoxBackground.swift` |
| Root headers and root scroll shell | `MoriSanctuaryHeaders.swift` |
| Actions | `MoriActionComponents.swift` |
| Metrics and state surfaces | `MoriSanctuaryMetrics.swift`, `MoriStateComponents.swift` |
| Shared view behaviour | `MoriViewModifiers.swift` |
| Typed bitmap art and icons | `Shared/MoriGeneratedArt.swift` |

## Tokens

### Semantic Editorial Tokens

`MoriTheme` is a namespace, not a runtime light/dark theme object. Its nested types provide current semantic values:

```swift
MoriTheme.Colors.paper
MoriTheme.Colors.raisedPaper
MoriTheme.Colors.ink
MoriTheme.Colors.primaryAction
MoriTheme.Typography.pageTitle
MoriTheme.Spacing.screenEdge
MoriTheme.CornerRadius.card
MoriTheme.Animation.control
```

### Sanctuary Tokens

The established botanical surfaces also use:

```swift
MoriColors.sanctuaryPaper
MoriColors.sanctuarySurface
MoriColors.sanctuaryInk
MoriColors.sanctuaryMuted
MoriColors.sanctuarySage
MoriTypography.sanctuaryRootTitle
MoriSpacing.cardPadding
MoriHitTarget.minimum
```

Use semantic tokens instead of copying literal colors or dimensions into feature code. Do not create a third token layer inside a feature.

## Root Composition

Choose the primitive already used by the screen:

- `MoriPaperBackground(variant:)` supplies full-screen paper and a screen-level botanical bitmap wash.
- `MoriRootScrollScreen` supplies the established sanctuary root header, safe-area handling, and scrolling layout.
- `MoriPage` and `MoriLandscapeBackground` supply the newer reference-matched editorial composition.
- `MoriPageHeader`, `MoriRootHeader`, `MoriSectionHeader`, and `MoriSectionTitle` provide shared hierarchy.

Example using the established sanctuary shell:

```swift
MoriRootScrollScreen(
    title: "Today",
    subtitle: "One grounded next step",
    backgroundVariant: .today
) {
    TodayContent()
}
```

Do not nest two root backgrounds. Do not add a screen painting inside every card.

## Sanctuary Cards And Boxes

For established botanical surfaces:

```swift
Content()
    .moriSanctuaryCard()

TextField("Name", text: $name)
    .padding(MoriSpacing.inputPadding)
    .moriSanctuaryBox(
        cornerRadius: MoriCornerRadius.input,
        padding: 0,
        tone: .paper,
        castsShadow: false
    )
```

`moriSanctuaryCard` and `moriSanctuaryBox` resolve through `MoriSanctuaryBoxBackground` and `MoriPlainWatercolorCardBackground`.

Available box tones are `.paper`, `.mist`, `.sage`, `.sand`, `.blue`, and `.root`. Use tone to communicate hierarchy, not to decorate every section.

Card surfaces intentionally do not expose screen-art, wave, or texture toggles. Screen-level paintings belong in `MoriPaperBackground`; a deliberate hero moment may use `MoriWatercolorHeroWash`.

Other current shared surfaces include:

- `BotanicalPanel` and `OrganicCard`
- `MoriPracticeCard`
- `MoriMetricTile` and `MoriCompactStatStrip`
- `MoriEmptyState`, `MoriPermissionState`, `MoriErrorState`, and `MoriSkeleton`

Avoid nested cards and repeated card chrome where typography and spacing are sufficient.

## Actions

`MoriPrimaryButton` is the canonical large commitment action. `MoriSecondaryButton` is the quieter alternative. Use `MoriIconButton` for a compact typed-icon action.

```swift
VStack(spacing: MoriTheme.Spacing.small) {
    MoriPrimaryButton(title: "Turn App Limit On") {
        enableAppLimit()
    }

    MoriSecondaryButton(title: "Not now") {
        dismiss()
    }
}
```

Use `MoriSanctuaryPrimaryButton` only where the existing screen needs its compact sanctuary treatment. `MoriButton` remains a watercolor compatibility component; do not choose it by default for a new reference-matched flow.

All primary actions must retain a clear enabled/disabled state, a semantic label, and at least a 44pt target.

## Forms And Sheets

Current shared modifiers include:

```swift
Form {
    SettingsContent()
}
.moriSettingsForm()
.moriKeyboardDoneToolbar()
.moriBotanicalSheetPresentation()
```

Use `moriHidesMainTabBar()` only for immersive pushed practice flows that already own navigation. Do not hide root navigation as incidental styling.

## Motion

Motion must be short, calm, and optional:

```swift
Content()
    .moriReduceMotionAnimation(
        MoriTheme.Animation.disclosure,
        value: isExpanded
    )
```

Use `moriAnimation(_:value:)` or `moriReduceMotionAnimation(_:value:)` so state changes respect Reduce Motion. Guard continuous ambient motion with `@Environment(\.accessibilityReduceMotion)` or `moriAllowsMotion`.

Never delay an action for animation or encode essential state only through motion.

## Artwork

- `MoriPaperBackground` owns root-level paper and botanical atmosphere.
- `MoriGeneratedArtImage` renders a typed `MoriGeneratedArt` asset.
- `MoriBitmapIconImage` and `MoriBitmapIconBadge` render typed UI icons.
- Card material uses the generated paper washes selected by `MoriSanctuaryBoxTone`.

Do not add inline SVG, ad hoc SF Symbol strings, or brand-lockup wallpaper to a primary surface when a typed Mori asset exists.

## Life Grid Naming

The interface and current product documentation say **Life Grid**. Internal Swift types, files, routes, stores, and persistence seams keep the `WeekArchive*` prefix.

For example, a view implemented under `Features/WeekArchive/` may display “Life Grid”. Keep localization at the presentation boundary; do not rename persisted identifiers as a visual cleanup.

## Accessibility Checklist

- Minimum interactive target: `MoriHitTarget.minimum`
- Dynamic Type can grow without hiding the primary action
- Selection is communicated by more than color
- Decorative paper and botanical art are accessibility-hidden
- VoiceOver order follows visual hierarchy
- Sheet content has an obvious dismissal path
- Reduced Motion disables repeated scale, parallax, and ambient drift
- Text remains on quiet paper or clear negative space

## Change Workflow

Before editing an affected UI:

1. Read `AGENTS.md`.
2. Inspect the approved reference image.
3. Find the existing composition and component usage in the feature source.
4. Preserve functional behaviour and persistence.
5. Implement toward the reference.
6. Build and run the affected target.
7. Capture and compare screenshots.
8. Complete at least two visual-refinement passes.
9. Run the relevant design and release gates.

The broad readiness command is:

```sh
bash scripts/check_redesign_release_readiness.sh
```

Use the focused audit commands in `MORI_REDESIGN_RELEASE_AUDIT.md` for the surfaces changed.
