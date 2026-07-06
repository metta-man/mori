# Mori

## Active Source Of Truth

Use these files for current product, UI, brand, and implementation direction:

- `MORI_REDESIGN_OPERATING_MODEL.md`
- `MORI_REDESIGN_RELEASE_AUDIT.md`
- `DesignSystem/MoriDesignSystemDocumentation.md`
- `brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md`
- `q2-prep/onboarding/ONBOARDING_FLOW_DESIGN.md`
- `scripts/check_design_direction.sh`
- `scripts/check_redesign_release_readiness.sh`
- `project.yml`
- Current app source under `App/`, `Features/`, `DesignSystem/`, `Shared/`, `Services/`, `Widgets/`, `WatchApp/`, `WatchWidgets/`, `ShieldAction/`, `ShieldConfiguration/`, and `ScreenTimeMonitor/`
- Current web source under `www/src/`

## Historical Archives

The `design/`, `docs/`, `mockups/`, `research/`, and `icon-concepts/` folders are historical archive/reference material only. The `q2-prep/` folder is also historical except for `q2-prep/onboarding/ONBOARDING_FLOW_DESIGN.md`, which remains the active onboarding source of truth because it is enforced by the design gate. Archived material contains earlier Life Grid, mortality, warm-minimalist, Flare, and icon explorations that are not the current implementation source of truth.

## Redesign Release Check

Run the current local release-readiness line with:

```sh
bash scripts/check_redesign_release_readiness.sh
```

For fast non-native checks while iterating:

```sh
bash scripts/check_redesign_release_readiness.sh --skip-native-build
```

## Screen Time Capability

Mori uses Apple's Screen Time APIs for optional app limits during Quiet Mode and Pomodoro. Release and external TestFlight builds require Apple approval for the Family Controls entitlement (`com.apple.developer.family-controls`) on the main app and Screen Time extension targets.
