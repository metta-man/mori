# Task Card — Mori Design System v2 Prototype

## Founder Intent

Create a calm digital wellbeing companion that helps a person pause, notice, and choose before opening a feed. The interface must reduce cognitive load and feel slower within two seconds of opening.

## Build Scope

- Add a self-contained, interactive 390 × 844 mobile prototype to the existing `www` app at `/mori-v2`.
- Preserve the existing marketing route and the in-progress native SwiftUI worktree.
- Cover the core journey: Today → Before Feed → configured breathing pause → explicit continue or close; Today/Focus → Deep Session → session complete; Log → mood, one sentence, optional photo → done.
- Keep exactly three primary tabs: Today, Focus, Log. An active Focus session becomes immersive and returns to the tabs after completion. Present Settings from a floating button, never as a tab.

## Design Contract

- Visual direction: watercolor paper, muted earth tones, warm off-white, forest green, stone grey, serif titles, San Francisco/system body text, rounded opaque paper cards, subtle shadows, generous breathing room.
- Today exposes one primary next action only; secondary information remains quiet.
- Focus contains the timer, forest illustration, blocked apps, and pause/continue control only.
- Use Intent Count and Quiet Minutes; never introduce Screen Time totals, streaks, coins, XP, badges, confetti, fire, or productivity framing.
- Motion is slow and organic, with a complete `prefers-reduced-motion` fallback.
- Avoid bright blue, orange CTA, gradients except inside natural raster scenery, glassmorphism, heavy icons, busy dashboards, charts, guilt, punishment, and forced pauses.

## Interaction Contract

- Every visible primary CTA, tab, reason choice, breathing control, timer control, completion action, log control, and settings dismissal works.
- Every Before Feed reason starts the configured pause; the feed cannot continue until it completes.
- A completed 25-minute session says only: “One quiet session protected.” and “25 quiet minutes.” An intentionally ended partial session reports only truthful elapsed time.
- The prototype remains keyboard reachable and uses semantic controls, visible focus states, readable contrast, practical tap targets, labels, and reduced-motion behavior.

## Definition of Done

- Build and type checks pass.
- Browser verification is performed at 390 × 844 with Today, Before Feed, Focus, completion, Log, and Settings exercised.
- Each screen passes the question “Does this screen make the user breathe slower?” and is checked against current Apple HIG and the Mori philosophy.
- `design-qa.md` records source/implementation evidence, interaction checks, console status, comparison history, and `final result: passed`.
