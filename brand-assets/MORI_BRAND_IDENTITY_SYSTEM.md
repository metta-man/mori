# Mori Brand Identity System

**Version:** 2.0
**Date:** June 24, 2026
**Status:** Active product/design source of truth
**Current build:** SwiftUI iOS app, watch app, widgets, Screen Time extensions, localized landing site, and Vercel pulse proxy

---

## Executive Summary

Mori is a calm attention operating system, not a generic habit tracker. The product promise is simple: help the user reclaim attention, record proof of a life actually lived, and return to the next small practice.

The current design direction is botanical watercolor on paper: warm washi surfaces, deep leaf ink, generated bitmap art, compact root navigation, and minimal ceremony. Keep the interface quiet, tactile, and fast. Remove anything that exists only because wellness apps usually have it.

---

## First-Principles Product Gate

Every feature must pass one of these tests:

1. **Return attention:** Does it reduce compulsive checking, feeds, or avoidable context switching?
2. **Record proof:** Does it help the user capture a meaningful practice, reflection, or recovered minute?
3. **Improve the next action:** Does it make the next practice clearer or easier?

If a feature fails all three, delete it. If a screen needs explanation text to justify itself, simplify the screen before adding more copy. If a flow can be completed in one step, do not make it three.

Use this order for future redesign work:

1. Question the requirement.
2. Delete the non-essential path.
3. Simplify the remaining interaction.
4. Speed up the loop.
5. Automate only after the loop is proven.

---

## Core Philosophy

**Attention → Presence**
*"Notice the pull → add one real limit → return to the next lived minute"*

**Visual Style:** **Botanical watercolor paper**
```
Minimalism is not emptiness.
Minimalism is lower cognitive load.
```

Mori should feel like opening a quiet paper field, not operating a dashboard.

---

## Product Architecture

### App Shell

- Root app entry: `App/MoriApp.swift`
- Root navigation shell: `App/ContentView.swift`
- Active tabs: Today, Reset, Log
- Global sheets: Before Feed reset, Morning Gate reset, Recovery/Pulse
- Cross-surface state: `UserSettings`, shared app group defaults, notification deep links, widget context publishing

The root shell intentionally uses a custom bottom tab bar, not native `TabView`, so immersive practice flows can hide the root controls and keep bottom safe-area treatment consistent.

### Service Layer

- Screen Time protection: `AttentionShieldManager`, `BeforeFeedGate`, `MoriScreenTimeShared`
- Recovery and pulse signals: `MoriRecoveryHealthService`, `MoriRecoveryStore`, `MoriClarityStore`, `MoriLLMService`
- Watch/widget sync: `MoriWatchSettingsSync`, `MoriWidgetSnapshot`
- Web pulse proxy: `www/server/pulse/*`

New infrastructure should plug into these seams rather than creating parallel state channels.

---

## Color System

### Active Sanctuary Palette
```swift
MoriColors.sanctuaryPaper       #FBF7EF
MoriColors.sanctuarySurface     #FFFDF8
MoriColors.sanctuaryInk         #14392F
MoriColors.sanctuaryInkSoft     #31584B
MoriColors.sanctuaryMuted       #5F6D64
MoriColors.sanctuarySage        #758C6B
MoriColors.sanctuaryFern        #8FA883
MoriColors.sanctuaryMist        #AFC9CB
MoriColors.sanctuarySand        #D9C6A5
MoriColors.sanctuaryRoot        #8A765F
MoriColors.sanctuaryLine        #DDD6C8
```

## Typography System

### Font Scale
```swift
MoriTypography.display      // 48pt Light (large hero numbers)
MoriTypography.title1      // 28pt Semibold (screen titles)
MoriTypography.title2      // 22pt Semibold (section headers)
MoriTypography.body        // 17pt Regular (main content)
MoriTypography.callout      // 16pt Regular (secondary info)
MoriTypography.caption      // 14pt Regular (labels, hints)
MoriTypography.micro        // 12pt Medium (timestamps)
MoriTypography.largeMetric  // 64pt Rounded (archive/recovery metrics)
```

### Font Stack
```css
--font-display: 'Cormorant Garamond', serif;      // Headlines
--font-body: 'Crimson Pro', serif;                // Body text
--font-mono: 'DM Mono', monospace;                // Numbers/Week Archive
--font-handwritten: 'Caveat', cursive;           // Personal notes
```

---

## UI Components

### Current Components
- **MoriPaperBackground**: Root bitmap watercolor paper wrapper
- **MoriRootHeader / MoriPageHeader**: Compact screen heading system
- **MoriPracticeCard / BotanicalPanel / OrganicCard**: Sanctuary card surfaces
- **MoriMetricTile / MoriCompactStatStrip**: Dense status components
- **MoriBitmapIconImage / MoriBitmapIconBadge**: Generated botanical icon pipeline
- **MoriViewModifiers**: App theme, forms, keyboard toolbar, root tab hiding

### Design System Features
- **Spacing**: 4pt grid system (space1-space8)
- **Corner Radius**: Small (8pt), Medium (12pt), Large (16pt)
- **Animations**: Gentle, purposeful motion (standard 0.3s)
- **Shadows**: Subtle depth for cards and buttons
- **Hit Targets**: Accessibility-compliant (44pt minimum)

Avoid nested cards. Avoid decorative surfaces that do not carry interaction or information. Use generated bitmap icons for primary surfaces; add a Mori bitmap asset when a matching icon does not exist.

---

## 📱 App Icon Design ✅

### Current Implementation: Paper Linework App Icon
**Source:** Generated raster PNG, not SVG
**Background:** Warm paper `#F7F5F0` / `#FFF8EA`
**Linework:** Deep forest ink `#173D32`
**Canopy/landscape:** Moss and sage greens
**Seed/light:** Soft gold `#D8B86F`

The active app icon uses a soft circular paper-linework landscape. Layered moss forms suggest terrain, breath, and quiet growth without using literal trees or Japanese motifs. The mark was selected because it best matches the latest Mori UI references: warm paper, thin green linework, soft watercolor texture, and a premium calm/wellness tone. Do not place logo lockups, app-icon art, seedling badges, or circular brand emblems inside primary app screens unless an OS surface or external marketing surface requires branding.

**Assets Generated:**
- iOS: 1024x1024, 180x180, 167x167, 152x152, 120x120, 76x76, 60x60, 29x29
- Android review exports: 192x192, 144x144, 96x96, 72x72, 48x48
- External lockups: horizontal PNG logo, reverse PNG logo, exact `Mori` wordmark PNG, and reverse wordmark PNG
- Review: Creative Production moodboard plus Canva board

### Brand Asset Rule

The paper-linework family is the only active brand direction. Do not add alternate logo families to `brand-assets/` or active app catalogs. Historical explorations belong in research/archive material, not in the active brand source of truth.

---

## Product Surfaces

### Core App Screens
1. **Today:** App Limits, reset suggestions, proof strip, and week archive preview
2. **Reset:** settle timer, breathing library, Pomodoro, quiet mode, mindfulness bell
3. **Log:** gratitude writing, daily spark, history, random memory
4. **Week Archive:** week/month/archive views calibrated by archive start date and archive span
5. **Pulse:** source-backed recovery and information diet cards

### Web Surface
- `www/src/App.tsx` is a localized brand/early-access site.
- `www/server/pulse/*` is the live-source pulse proxy used by app-side recovery and topic cards.

---

## Technical Implementation

### Swift Design System
- **DesignSystem/MoriDesignTokens.swift**: Color, typography, spacing, radius, animation tokens
- **DesignSystem/MoriSanctuaryComponents.swift**: Active botanical paper component layer
- **DesignSystem/MoriViewModifiers.swift**: Theme, form, keyboard, and root tab modifiers
- **Shared/MoriGeneratedArt.swift**: Generated art and bitmap icon wrappers

### Infrastructure
- **project.yml** remains the XcodeGen source for targets and bundle settings.
- The iOS app, Screen Time extensions, widgets, watch app, shared localization, and generated art must stay in one project graph.
- The pulse proxy must validate request shape, prefer live sources when available, and fail closed when live search is required but source coverage is missing.

---

## 📊 User Research ✅

### Personas Developed
1. **Sarah Chen** (Primary): Young professional, mindfulness user
2. **Marcus Thompson** (Secondary): Philosophy professor, intellectual depth
3. **Emma Rodriguez** (Tertiary): Designer, aesthetic appreciation
4. **David Park** (Edge Case): Retired, accessibility needs

### Design Validation
- User interviews planned for primary persona
- A/B testing of warm vs pure minimalism
- Emotional response validation for Week Archive concept

---

## Execution Roadmap

### Now
- [x] Root app shell builds with custom bottom navigation.
- [x] Generated brand/icon assets are wired into SwiftUI and web.
- [x] Web package builds with the localized brand site and pulse proxy sources.

### Next
- [ ] Run simulator screenshots for Today, Reset, Log, Week Archive, and Pulse after each major UI pass.
- [x] Remove v1 component APIs and card/input compatibility aliases from the active DesignSystem surface.
- [ ] Add focused tests around pulse request validation and source coverage.

### Later
- [ ] Review historical mockups for reference value; archive or delete anything non-authoritative.
- [ ] Make pricing and App Store links real before public web launch.
- [ ] Audit localization coverage before TestFlight.

---

## Asset Inventory

### Active Source Files
- **Brand source of truth**: `brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md`
- **Logo source of truth**: `brand-assets/MORI_PAPER_LINEWORK_LOGO.md`
- **Design system source of truth**: `DesignSystem/MoriDesignSystemDocumentation.md`
- **Swift design system**: `DesignSystem/MoriDesignTokens.swift`, `DesignSystem/MoriSanctuaryComponents.swift`, `DesignSystem/MoriActionComponents.swift`, `DesignSystem/MoriStateComponents.swift`
- **Generated bitmap assets**: `Shared/MoriGeneratedArt.swift`, `Shared/MoriGeneratedArt.xcassets`
- **App icon catalogs**: `AppIcon.appiconset`, `DesignSystem/MoriBackgrounds.xcassets/AppIcon.appiconset`

---

## Quality Gates

### Required Before Claiming Done
- iOS simulator build succeeds for `Mori`.
- Web build succeeds with `pnpm --dir www build`.
- Main flows render without overlapping text on iPhone-size and iPad-size screens.
- Root tabs use Mori-generated assets where available.
- New source-backed pulse behavior either returns citations or explicitly degrades to local fallback copy.

### Design Requirements
- Botanical watercolor paper palette is dominant.
- Buttons and controls have stable tap targets.
- Cards are used for actual grouped content, not section decoration.
- Screen copy is short enough to scan in one breath.
- Any new feature names the user action it improves.

---

## Handoff Package

### For Build Agents
1. **Start here:** `brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md`
2. **Swift app shell:** `App/ContentView.swift`, `App/MoriApp.swift`
3. **Design tokens/components:** `DesignSystem/MoriDesignTokens.swift`, `DesignSystem/MoriSanctuaryComponents.swift`
4. **Generated assets:** `Shared/MoriGeneratedArt.swift`, `Shared/MoriGeneratedArt.xcassets`, `brand-assets/*`
5. **Web/pulse:** `www/src/App.tsx`, `www/src/i18n.ts`, `www/server/pulse/*`

### Task Card Template
```markdown
Goal:
User action improved:
Requirement owner:
Delete-first check:
Files likely touched:
Acceptance:
- iOS build:
- Web build if touched:
- Screenshot/simulator proof:
```

---

## 📞 Support & Documentation

### Design Reference
- **Design Brief**: Botanical watercolor paper, App Limit-first attention recovery
- **Color Philosophy**: Warm paper, deep green ink, restrained botanical accents
- **Typography**: Serif display for reflective moments; system text for controls and dense utility
- **Component Style**: Organic but controlled, never ornamental for its own sake

### Technical Support
- **Design Tokens**: MoriDesignTokens.swift
- **Components**: MoriSanctuaryComponents.swift and MoriComponents.swift
- **Icons**: Generated app icons, lockups, and bitmap UI icons

---

## Current Completion Claim

Do not call the full redesign complete until the simulator UI has been visually inspected across the main app surfaces and the active source, docs, and compiled artifact gates pass without exceptions.
