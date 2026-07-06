# Mori Onboarding Flow - Active Design

**Version:** 2.0
**Status:** Active source of truth
**Last updated:** 2026-06-25

---

## Product Decision

Onboarding is App Limit-first.

The first-run experience should help the user switch on the Screen Time-backed App Limit flow before introducing any broader product philosophy. The promise is simple: choose the apps that usually pull attention away, set the limit, and leave onboarding with protection already working.

No brand mark, seedling badge, circular emblem, app icon, or wordmark should be used as the card background, screen watermark, or repeated decorative motif. The app can have a brand identity, but the interface should feel like watercolor on paper, not like a stamped brochure.

---

## Jobs Taste Gate

1. **One job:** get App Limit configured or let the user intentionally skip it.
2. **One material:** textured watercolor paper with botanical wash.
3. **One hierarchy:** title, short supporting copy, app selection state, primary action.

Delete anything that does not help those three things.

---

## Visual Direction

### Background

- Use `MoriPaperBackground(variant: .onboarding)`.
- Use `BotanicalBackdropOnboarding` as the screen-level wash through `MoriPaperBackground`, not as a repeated card motif.
- Keep the paper texture visible and quiet.
- Avoid dark launch-poster layouts, countdown framing, badge seals, seedling emblems, or repeated brand marks.

### Cards

- Use `.moriSanctuaryCard(...)` or `.moriSanctuaryBox(...)`.
- Card surfaces use `MoriPlainWatercolorCardBackground` with an opaque watercolor-paper backing and the dedicated `moriCardPaperWash` bitmap: quiet no-logo watercolor paper texture. Botanical paintings belong on screen backgrounds, hero visuals, or deliberately tiny functional accents, not every card and not bleeding through every card.
- Accent boxes may use `moriCardSageWash`, `moriCardWarmWash`, or `moriCardCoolWash` as paper-material variants. These are faint botanical watercolor texture variants, not logo, seedling badge, circular emblem, or wordmark wallpapers.
- Cards must not opt into screen/hero artwork. `moriSanctuaryCard` and `moriSanctuaryBox` do not expose `backdrop`, `showsWave`, or `showsTexture` parameters.
- Cards should read as material: paper grain, hairline border, soft shadow.
- Cards must not use app-icon art, brand lockups, wordmarks, seedling marks, circular emblems, leaf marks, or badge art as background imagery.

### Icons

- Use `MoriBitmapIcon` and `MoriBitmapIconImage`.
- Use botanical bitmap icons only for controls, status rows, and small badges.
- Add a new bitmap icon when the existing set does not cover the action.
- Do not render SF Symbol strings directly in onboarding UI.

---

## Screen Structure

### Surface

`MoriOnboardingView` hosts exactly one onboarding surface:

```swift
MoriPaperBackground(variant: .onboarding) {
    OnboardingAppLimitsScreen(onComplete: completeOnboarding)
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
}
```

### Primary Surface

`OnboardingAppLimitsScreen` delegates the real setup UI to `FirstAppLimitSetupSurface` with onboarding copy.

Required states:

- Screen Time permission not granted
- Permission granted but no app selection
- App selection present but App Limit disabled
- App Limit ready
- Skip path

Required primary actions:

- `Turn App Limit On`
- `Finish with App Limit on`
- `Skip App Limit for now`

---

## Copy

Copy should be practical and action-led.

Good:

- `Turn App Limit On`
- `Finish with App Limit on`
- `Skip App Limit for now`
- `Choose the apps that pull you off track.`
- `Mori can hold the boundary when your attention is tired.`

Avoid:

- Death-framed setup copy
- Countdown framing
- Generic welcome slogans
- Abstract productivity promises before the App Limit is configured
- Brand-first headlines

---

## Acceptance Criteria

- First launch opens directly into the App Limit setup flow.
- The old multi-step onboarding journey is not reachable.
- The old conversion-shape motif is absent.
- Cards use watercolor paper and botanical wash only.
- No card or screen uses brand-mark, app-icon, wordmark, or badge artwork as a background.
- The screen works on compact iPhone sizes without clipped text.
- `scripts/check_design_direction.sh` passes.

---

## Implementation Map

- `Features/Onboarding/MoriOnboardingView.swift`
- `Features/Onboarding/MoriOnboardingAppLimitsView.swift`
- `Features/Onboarding/MoriOnboardingSupport.swift`
- `Features/ScreenTime/FirstAppLimitSetupView.swift`
- `DesignSystem/MoriPaperBackground.swift`
- `DesignSystem/MoriSanctuarySurfaces.swift`
- `DesignSystem/MoriBotanicalBackdrops.swift`
- `Shared/MoriGeneratedArt.swift`
