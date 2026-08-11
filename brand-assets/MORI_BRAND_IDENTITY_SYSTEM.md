# Mori Brand Identity System

**Version:** 2.1
**Updated:** 2026-07-25
**Status:** Active brand and external asset-use guide

## Scope

This document governs Mori's brand promise, external visual identity, logo family, and the boundary between brand assets and product UI.

It is not the overall UI composition source of truth. For product work:

- Approved visual direction: `DesignReferences/MORI_DESIGN_SPEC.md` and `DesignReferences/mori-approved-reference.jpeg`
- Product language and interaction: `MORI_DESIGN_SYSTEM_V2.md`
- SwiftUI APIs: `DesignSystem/MoriDesignSystemDocumentation.md` and current Swift source
- Canonical source map: `docs/CURRENT_SOURCES.md`

## Brand Promise

Mori creates a calm boundary between impulse and action.

The product helps a person:

1. pause before automatic phone use,
2. protect a quiet or focused period,
3. choose one grounded next action, and
4. keep light evidence of a life actually lived.

Mori is not a generic productivity dashboard, punishment system, or gamified habit tracker.

## Brand Character

- Calm, not passive
- Editorial, not corporate
- Tactile, not ornamental
- Direct, not motivational
- Warm, not childish
- Reflective, not mortality-driven

The emotional sequence is:

> Pause → Notice → Choose

## Visual Identity

### Material

Mori should feel like watercolor on warm paper:

- visible but quiet paper grain,
- soft botanical bitmap washes,
- deep leaf ink,
- sage and earth accents,
- generous negative space,
- restrained borders and shadows.

Primary interface surfaces are recognized through this material system. They do not need a repeated logo, seal, seedling, wordmark, or app-icon watermark.

### Core Palette

The implementation values below come from the active native token layer:

| Role | Token | Value |
| --- | --- | --- |
| Root paper | `MoriColors.sanctuaryPaper` | `#FBF7EF` |
| Raised paper | `MoriColors.sanctuarySurface` | `#FFFDF8` |
| Primary ink | `MoriColors.sanctuaryInk` | `#14392F` |
| Soft ink | `MoriColors.sanctuaryInkSoft` | `#31584B` |
| Muted ink | `MoriColors.sanctuaryMuted` | `#5F6D64` |
| Sage | `MoriColors.sanctuarySage` | `#758C6B` |
| Fern | `MoriColors.sanctuaryFern` | `#8FA883` |
| Mist | `MoriColors.sanctuaryMist` | `#AFC9CB` |
| Sand | `MoriColors.sanctuarySand` | `#D9C6A5` |
| Root | `MoriColors.sanctuaryRoot` | `#8A765F` |
| Hairline | `MoriColors.sanctuaryLine` | `#DDD6C8` |

Do not copy these hex values into new SwiftUI views. Use semantic tokens. Web implementation values live in the current styles under `www/src/`.

### Typography

- Reflective titles use an editorial serif treatment.
- Body copy and controls use the system sans-serif treatment on native platforms.
- Numerals that need comparison use a stable, readable numeric treatment.
- Hierarchy should come from type, spacing, and composition before another container is added.

Native typography is defined by `MoriTheme.Typography` and `MoriTypography`. Web typography is defined by current styles under `www/src/`; do not treat an old archive mockup as a font specification.

## Logo And App Icon

### Active Family

The paper-linework family is the only active external brand direction:

- `brand-assets/mori-paper-linework-icon-master-1024.png`
- `brand-assets/mori-paper-linework-logo.png`
- `brand-assets/mori-paper-linework-logo-reverse.png`
- `brand-assets/mori-paper-linework-wordmark.png`
- `brand-assets/mori-paper-linework-wordmark-reverse.png`
- `brand-assets/MORI_PAPER_LINEWORK_LOGO.md`

The app icon uses warm paper, deep forest linework, moss/sage landscape forms, and a restrained gold light.

### Placement

Appropriate:

- app icon and OS-managed app identity,
- App Store and TestFlight surfaces,
- website masthead or footer,
- press, launch, and external marketing material,
- exported documents that need explicit authorship.

Inappropriate:

- primary app cards,
- onboarding cards,
- repeated screen watermarks,
- widgets or watch cards used as wallpaper,
- button fills,
- empty states used repeatedly,
- decorative badges inside routine product flows.

When the interface already says “Mori” through its material and composition, another logo weakens the system.

## Product Naming

- The user-facing feature name is **Life Grid**.
- Internal Swift files, types, routes, stores, and persistence seams use the `WeekArchive*` prefix.
- UI copy, accessibility labels, marketing copy, and current product documentation must use Life Grid.
- Code-oriented documentation may use `WeekArchive*` only when naming an actual symbol or path.

Other preferred language:

- App Limit
- Before Feed
- Quiet Minutes
- Intent Count
- Deep Session or Quiet Session
- Today, Focus, and Log for the root destinations

Avoid death countdowns, earned-time language, streaks, XP, punishment, scarcity, and loud celebration.

## Product-Surface Boundary

### Native

- Root visual atmosphere comes from `MoriPaperBackground` or the existing reference-matched composition layer.
- Established cards use the sanctuary paper APIs documented in `DesignSystem/MoriDesignSystemDocumentation.md`.
- Primary artwork uses typed Mori bitmap icon APIs.
- Brand artwork is not a substitute for screen-level botanical composition.

### Web

- The active site lives under `www/src/`; server-side pulse code lives under `www/server/`.
- Use the current v2 styles and mirrored botanical bitmap assets.
- Do not revive archived mockup CSS or inline SVG motifs as brand authority.

### Widgets And Watch

- Keep the mark subordinate to useful content.
- Prefer quiet paper, one strong value or action, and a small botanical accent.
- Respect each platform's legibility and complication constraints.

## Voice

Mori copy is short, practical, and non-judgmental.

Good:

- “Why now?”
- “Turn App Limit On”
- “One quiet session protected.”
- “What would make this week feel lived?”

Avoid:

- generic welcome slogans,
- abstract productivity promises,
- guilt about time already spent,
- exaggerated praise,
- death-framed setup language,
- copy that explains decoration instead of helping the next action.

## Asset And Implementation Sources

- Brand guide: `brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md`
- Logo construction and usage: `brand-assets/MORI_PAPER_LINEWORK_LOGO.md`
- Approved UI references: `DesignReferences/`
- Native design tokens: `DesignSystem/MoriDesignTokens.swift` and `DesignSystem/MoriThemeTokens.swift`
- Native paper and sanctuary components: `DesignSystem/MoriPaperBackground.swift`, `DesignSystem/MoriSanctuarySurfaces.swift`, and `DesignSystem/MoriSanctuaryBoxBackground.swift`
- Generated art and typed bitmap icons: `Shared/MoriGeneratedArt.swift` and `Shared/MoriGeneratedArt.xcassets`
- App icon catalogs: `AppIcon.appiconset` and `DesignSystem/MoriBackgrounds.xcassets/AppIcon.appiconset`

## Brand Review Gate

Before approving a new brand or product surface:

1. Confirm the asset belongs on that surface.
2. Compare UI work with the approved images in `DesignReferences/`.
3. Verify the surface still works without decorative brand stamping.
4. Check small-size legibility and accessibility contrast.
5. Confirm Life Grid and other product language follow the naming contract.
6. Run the relevant native or web build and screenshot gate.

Historical identity concepts are retained under `docs/archive/icon-concepts/` and related archive folders for provenance only.
