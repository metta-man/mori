# Before Feed and Morning Gate

This document describes the current implementation of Mori's Before Feed and
Morning Gate Screen Time flows. The source of truth is still the Swift code in
`Features/ScreenTime`, `Services`, `Shared`, and `ScreenTimeMonitor`.

## Shared Concepts

Both flows use Apple's Screen Time APIs:

- `FamilyControls` stores the user's selected app and web-domain tokens.
- `ManagedSettingsStore.shield` shows Mori's Screen Time shield before a selected
  app or web domain opens.
- `ManagedSettingsStore.application.blockedApplications` optionally hides app
  icons from the Home Screen and App Library.
- `DeviceActivityMonitor` is used for passive callbacks when a window starts or
  ends.

Both flows use the same selection model:

- `Use default block list` on: the flow uses Mori's global default block list.
- `Use default block list` off: the flow uses its own custom list.
- Only individual app and web-domain tokens are persisted. Category selections
  are intentionally stripped so broad categories do not accidentally catch apps
  like messaging tools.
- `Hide app icons` only applies to application tokens. Web domains can be
  shielded, but cannot be hidden as Home Screen icons.

When more than one passive gate is active, Mori merges their effective
selections before applying the Screen Time shield. If any active gate has icon
hiding enabled, Mori applies `blockedApplications` for the application tokens of
the hide-enabled gates.

## Before Feed

Before Feed is a "reset before opening a feed app" flow.

### Settings

The Before Feed section exposes:

- `Protect feed app launches`: enables the native Screen Time gate.
- `Hide feed app icons`: uses `blockedApplications` for selected feed app tokens
  outside the open window.
- `Use default block list`: decides whether `Feed apps` edits the global default
  list or the Before Feed custom list.
- `Reset length`: the length of the reset timer.
- `Open window`: how long selected feed apps stay open after the reset completes.
- `Breathing`: optional breathing guidance during the reset.

### Preconditions

Before Feed can apply a gate only when:

- Screen Time authorization is available.
- `Protect feed app launches` is on.
- The effective Before Feed selection has at least one app or web-domain token.
- The app is not currently inside the Before Feed open window.

### Launch Flow

1. User opens a selected feed app.
2. iOS presents Mori's Screen Time shield.
3. The shield action records a pending Before Feed reset request and closes the
   feed app.
4. The user opens Mori. If a pending request exists, Mori shows the Before Feed
   reset screen.
5. The user completes the reset timer.
6. Mori saves an open-window expiry time, clears the shield, starts the Before
   Feed Live Activity when available, and schedules a DeviceActivity grace
   monitor.
7. During the open window, selected feed apps are allowed.
8. When the open window expires, Mori clears the grace state and reapplies the
   passive Screen Time gate.

iOS does not allow the shield extension to jump directly into Mori. Shortcuts can
be used as a fallback to open Mori, but Shortcuts cannot return the user to the
triggering feed app.

### Open Window and Re-Lock

The open window is stored as `beforeFeedGraceUntil` in the app-group defaults.
Mori uses three paths to re-lock after the window:

- DeviceActivity callback for `.moriBeforeFeedGrace`.
- A foreground reconciliation when Mori next refreshes gate state.
- An in-app fallback task scheduled for the grace expiry.

The grace schedule is treated as idempotent. Mori avoids repeatedly stopping and
restarting the same DeviceActivity schedule during the open window because that
can cause iOS to drop the terminal callback.

### Live Activity

Before Feed starts a Live Activity for the open window when:

- iOS supports ActivityKit for Live Activities.
- Live Activities are enabled.
- The open-window end date is still in the future.

The Live Activity counts down to the window end. It should never count upward;
the content state clamps remaining seconds to zero.

### Debugging

The App Limits screen includes a Screen Time Monitor health panel for Before
Feed. It records recent events with trace IDs, policy names, token counts,
display names, and grace-window state.

Useful events include:

- `Grace saved`: reset completed and open window saved.
- `Grace monitor scheduled`: DeviceActivity schedule was registered.
- `Grace monitor fired` / `Grace monitor ended`: iOS delivered the monitor
  callback.
- `Grace expired`: Mori cleared the open window.
- `Shield lock applied`: Mori reapplied a normal shield lock.
- `Hidden app lock applied`: Mori applied shield plus `blockedApplications`.
- `Shield cleared`: Mori cleared the shield and icon restrictions.

A healthy post-window trace should show the grace window ending and a shield or
hidden-app lock being applied again.

## Morning Gate

Morning Gate is a scheduled morning window that blocks selected apps until the
user completes Morning Reset.

### Settings

The Morning Gate section exposes:

- `Morning Gate`: enables the scheduled morning gate.
- `Hide morning app icons`: uses `blockedApplications` for selected morning app
  tokens while Morning Gate is active.
- `Use default block list`: decides whether `Morning apps` edits the global
  default list or the Morning Gate custom list.
- `Start time`: the daily start time.
- `Morning window`: the duration of the scheduled window.
- `Breathing`: optional breathing guidance during Morning Reset.

### Active Window

Morning Gate computes the active window from:

- `morningGateStartHour`
- `morningGateStartMinute`
- `morningGateDurationSeconds`

The gate applies when:

- Morning Gate is enabled.
- The current time is inside the active window.
- The current window's `dateKey` has not already been completed.
- The effective Morning Gate selection has at least one app or web-domain token.

### Reset Flow

1. During the morning window, Mori applies the Morning Gate shield to selected
   apps and web domains.
2. If the user opens Mori from the shield or from the app, Mori can show Morning
   Reset.
3. Completing Morning Reset saves the current window's `dateKey` as completed.
4. Mori clears the active Morning Gate shield for that window.
5. When the morning window ends, the DeviceActivity monitor refreshes passive
   gates. If Before Feed should still apply, Before Feed is reapplied.

Morning Gate does not use the Before Feed open-window timer. Its allow period is
the configured morning window, and completion is tracked once per date key.

## Icon Hiding Policy

Normal shield mode:

- Applies `managedStore.shield.applications`.
- Applies `managedStore.shield.webDomains`.
- Clears `managedStore.application.blockedApplications`.

Hidden app lock mode:

- Applies the same app and web-domain shield.
- Also applies `managedStore.application.blockedApplications` for selected app
  tokens.
- Clears icon hiding again when the shield is cleared or a normal shield policy
  replaces it.

Because `blockedApplications` uses app tokens only, a selection with only web
domains can still be shielded but will not hide any icons.

## Interaction With Active Sessions

Timed reset sessions and passive gates share the same shield store. Mori protects
active sessions from being overridden:

- If an active session has not expired, passive gates preserve it.
- When an active session expires, Mori clears the session and refreshes passive
  gates.
- If both Morning Gate and Before Feed are active, Before Feed is treated as the
  current feature for display/debug purposes, while the effective selection is
  still merged.

## iOS Constraints

These are platform constraints, not app bugs:

- A Screen Time shield extension cannot directly launch Mori.
- Shortcuts can open Mori but cannot reliably return the user to the app that
  triggered the automation.
- URL schemes like `mori://` may be blocked from personal automations.
- DeviceActivity callbacks are not guaranteed to arrive immediately; Mori uses
  foreground reconciliation and an in-app fallback to reduce this risk.
- `blockedApplications` can make app icons disappear. This is expected when a
  `Hide ... app icons` toggle is on.

## Main Source Files

- `Features/ScreenTime/ScreenTimeSettingsView.swift`
- `Features/ScreenTime/ScreenTimeGateSettingsSections.swift`
- `Services/AttentionShieldManager.swift`
- `Services/AttentionShieldPassiveGatePolicy.swift`
- `Services/AttentionShieldApplier.swift`
- `Services/BeforeFeedGateStore.swift`
- `Shared/MoriMorningGate.swift`
- `Shared/MoriScreenTimeShared.swift`
- `ScreenTimeMonitor/MoriScreenTimeMonitorExtension.swift`
