# Mori Redesign Operating Model

## Current Design Promise

Mori is a Screen Time-first calm app with a botanical watercolor interface. The product promise is simple: help the user put a limit between impulse and feed, then offer one quiet reset path.

The active visual system is watercolor paper, botanical bitmap washes, deep leaf ink, sage controls, and restrained spacing. App logo art belongs in OS, marketing, and external brand surfaces. It does not belong inside primary app cards, onboarding cards, widgets, or repeated decorative UI backgrounds. Mori should be recognizable by material, rhythm, and restraint, not by stamping the mark across the app.

## First-Principles Product Rules

1. Delete before polishing.
2. App Limit and Screen Time flows are the primary onboarding path.
3. Cards are content containers, not brand billboards.
4. Botanical art is screen atmosphere, hero support, or a tiny functional accent, not repeated card wallpaper.
5. Bitmap assets are the visual material source; synthetic SVG/gradient motif work is not the current direction.
6. Every active UI surface must point at the same design system, generated project, and CI gates.

## Active Source Of Truth

- `DesignSystem/MoriDesignSystemDocumentation.md`
- `brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md`
- `MORI_REDESIGN_RELEASE_AUDIT.md`
- `q2-prep/onboarding/ONBOARDING_FLOW_DESIGN.md`
- `project.yml`
- `scripts/check_design_direction.sh`
- `scripts/check_redesign_release_readiness.sh`
- `scripts/check_compiled_design_artifacts.sh`
- `scripts/check_web_screenshot_audit.sh`
- `scripts/check_main_surface_screenshot_audit.sh`
- Current app source under `App/`, `Features/`, `DesignSystem/`, `Shared/`, `Services/`, `Widgets/`, `WatchApp/`, `WatchWidgets/`, `ShieldAction/`, `ShieldConfiguration/`, and `ScreenTimeMonitor/`
- Current web source under `www/src/`

The `design/`, `docs/`, `mockups/`, `research/`, and `icon-concepts/` folders are historical archives only. `q2-prep/` is historical except for the onboarding design file above.

## Retired Concepts

Do not reintroduce these as product direction:

- Mortality-countdown onboarding
- Old life-grid naming or UI framing
- Location or life-expectancy setup
- Hourglass, funnel, old time-seed, forest-ring, or badge-seal motifs
- Logo, wordmark, app-icon, paper-linework mark, seedling, circular emblem, or leaf-mark art used as an in-app surface background
- Flat cream-panel UI that ignores the watercolor paper material
- SF Symbol-first visual language on product surfaces

Migration code may keep legacy compatibility names only at data boundary seams, and those boundaries must stay covered by `scripts/check_design_direction.sh`.

## Surface Rules

Native root screens should use `MoriPaperBackground` with a screen-level botanical bitmap variant. Native cards should use `moriSanctuaryBox` / `MoriSanctuaryBoxBackground`, backed by `MoriPlainWatercolorCardBackground`, so repeated cards read as quiet opaque watercolor paper rather than translucent windows into the same logo, badge, paper-linework, or app-icon wallpaper. A card may use botanical tone through color, generated paper grain (`moriCardSageWash`, `moriCardWarmWash`, `moriCardCoolWash`), iconography, or a deliberately small hero accent; it must not use the brand mark as the texture.

Web cards should use the mirrored `www/src/assets/botanical/card-paper.png` bitmap material. Web and native icons should use typed Mori bitmap icon APIs instead of ad hoc symbol strings or inline SVG artwork.

Widgets and watch surfaces should keep the same rule: quiet paper cards, botanical accent only when it adds hierarchy.

## Infrastructure Contract

The generated Xcode project must be produced from `project.yml` and committed in sync. CI verifies this by running `xcodegen generate` and checking `Mori.xcodeproj` for drift.

Before treating the redesign as shippable, run the full local release-readiness line:

```sh
bash scripts/check_redesign_release_readiness.sh
```

For a fast non-native pass while iterating on docs or web-only materials, run:

```sh
bash scripts/check_redesign_release_readiness.sh --skip-native-build
```

For visual release checks, refresh the screenshot evidence first, then validate the audit files:

```sh
bash scripts/check_web_screenshot_audit.sh
bash scripts/check_main_surface_screenshot_audit.sh
```

The goal is not "a prettier theme." The goal is one integrated product system: source files, generated assets, project configuration, CI checks, screenshots, and app copy all saying the same thing.
