# Mori App Store V1 checklist

## Implemented in the repository

- Release builds route Pulse links to the on-device Recovery experience.
- iPhone and Watch widgets expose Recovery without AI Pulse content.
- Settings provides six granular deletion categories and Delete All.
- Analytics is explicit opt-in, excludes journal, photo, Health, exact-date, and app-name data, and supports remote deletion.
- Privacy manifests are included for the app, widgets, Watch app, and Screen Time extensions.
- Privacy Policy, Terms, and Support routes are available on the Mori website.
- App Store Connect export and the Apple development team are configured.

## App Store Connect / provider actions before submission

- Set `MORI_POSTHOG_API_KEY` only in the Release configuration or CI secret.
- Set `POSTHOG_PERSONAL_API_KEY`, `POSTHOG_PROJECT_ID`, and `POSTHOG_HOST` in Vercel.
- Configure PostHog event retention to 90 days or less and verify a deletion request in production.
- Complete App Privacy answers: Usage Data is optional/analytics-only and not linked for tracking; Health, journal, and photo data are not collected by the developer.
- Confirm Family Controls and HealthKit entitlements on the App Store distribution profile.
- Run archive validation, TestFlight smoke testing, and the physical iPhone + Apple Watch checklist.
- Add final App Store metadata, screenshots, age rating, support URL, privacy URL, and review notes explaining the Screen Time and HealthKit flows.
