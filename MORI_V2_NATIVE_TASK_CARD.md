# Task Card — Mori Design System v2 Native App

## Founder Intent

Carry the approved Mori v2 language into the production SwiftUI app without turning simplification into feature deletion. The app should feel slower within two seconds, while existing capabilities remain available through calm secondary sections, sheets, and pushed views.

## Product Contract

- The core loop is **Pause → Notice → Choose**.
- The first viewport of each root tab is intentionally sparse; deeper functions use progressive disclosure.
- Navigation has exactly three root tabs: **Today**, **Focus**, and **Log**.
- Settings is a floating 44pt-or-larger control, never a tab.
- Core UI uses **Intent Count**, **Quiet Minutes**, **Deep Session**, and **Quiet Session** language.
- Core views never expose Pomodoro, streak, XP, coin, earned-time, seed-reward, growth, guilt, or scarcity framing.

## Existing Function Map

### Today

- Keep App Limit status and setup.
- Keep Before Feed and Morning Reset entry points.
- Keep the editable Today focus.
- Keep Week Archive access.
- Present one dominant next action first; place configuration and archive functions behind a quiet secondary disclosure.

### Focus

- Make Deep Session the primary action.
- Keep breathing library, quiet timer, Quiet Mode, mindfulness bell, app-limit integration, guided breathing, sound, haptics, animation, dark room, duration, break, and cycle controls.
- During an active Deep Session, show only title, timer, forest atmosphere, blocked-app summary, and Pause. Reveal Resume/End and secondary controls only after pausing or before starting.
- Keep existing timer persistence and Screen Time behaviors while removing Pomodoro and reward language from user-facing copy.

### Before Feed

- Add the neutral “Why now?” intent step: Reply to someone, Learn, Relax, Habit, Other.
- Do not preselect a reason.
- Every reason continues into the configured Before Feed reset length; the timer starts automatically.
- Keep the feed locked for the full reset. Completion reveals a final Continue action and never unlocks automatically.
- Record a dedicated intent event; do not infer Intent Count from elapsed screen time or shield-button attempts.
- Keep Screen Time grace-window behavior and use generic feed copy where the app identity cannot be opened reliably.

### Log

- Lead with mood, one sentence, optional photo, and Done.
- Keep Daily Spark, pattern detail, Week Archive, random memory, history, previous-day entry, import/export, iCloud restore, and existing photo management below the primary log surface or in the existing action menu.
- Keep saved data and persistence formats compatible.

### Settings

- Keep App Limits, archive calibration, reminders, language, onboarding restart, data clearing, and about information.
- Present Settings as an opaque paper sheet with an obvious Done action.

## Design-System Implementation

- Align shared color, typography, radius, spacing, shadow, motion, and hit-target tokens with `MORI_DESIGN_SYSTEM_V2.md`.
- Reuse the existing watercolor and bitmap assets; do not replace them with code-drawn illustrations or emoji.
- Use serif display hierarchy and system body text with Dynamic Type.
- Keep controls at least 44 × 44pt, selections redundant beyond color, decorative art hidden from VoiceOver, and Reduce Motion respected.
- Avoid glassmorphism, progress rings in Deep Session, bright accents, dense dashboards, and text placed directly on detailed art.

## Engineering Constraints

- Preserve unrelated dirty worktree changes.
- Prefer adapting existing stores, routes, timers, Screen Time services, and journal persistence over parallel implementations.
- Internal legacy type and key names may remain for data compatibility, but user-facing copy must follow Mori v2.
- Do not claim a specific feed app can be reopened unless the native integration can identify and open it reliably.

## Definition of Done

- Today, Focus, Log, Before Feed configured pause, active/paused/completed Deep Session, and Settings are implemented in SwiftUI.
- Existing feature entry points remain reachable from the appropriate root view.
- The main iOS app target builds for an iPhone simulator.
- Core flows are exercised in the simulator at a compact and a modern iPhone size.
- Reference and simulator screenshots are compared in `design-qa.md`.
- Every generated screen is critiqued against Apple HIG and the Mori philosophy, with no remaining P0/P1/P2 findings and `final result: passed`.
