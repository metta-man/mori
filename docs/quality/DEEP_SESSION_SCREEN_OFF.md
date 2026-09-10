# Deep Session: screen-off timing and keep-screen-on

Date: 2026-09-09

## Delivered behavior

Deep Session accounts for elapsed wall time, not the number of UI timer callbacks.
It reconciles missed focus/short-break/long-break boundaries and completion on
return to the foreground. Pausing first reconciles time and then stops accounting;
resume starts a new timestamp anchor while preserving fractional active seconds.
Completion is idempotent. Early end also stops the clock.

A local AppStorage setting, mori_deep_session_keep_screen_on, defaults to false.
The native toggle is available under Session options before and during a session
and in Dark Room. Keep-screen-on is scoped to a foreground running session and
released on pause, completion, background, cleanup and exit. Deep Session's black
presentation respects that preference rather than implicitly forcing wakefulness.

Foreground breathing/audio/haptic work stops while inactive and resumes from the
current phase. This does not promise background audio or an alarm while suspended.
No background execution entitlement, silent-audio workaround or polling service
was introduced. See Apple's [background execution guidance](https://developer.apple.com/documentation/uikit/extending-your-app-s-background-execution-time)
and [idle timer property](https://developer.apple.com/documentation/uikit/uiapplication/isidletimerdisabled).

## Screen Time boundary

The existing current-focus timed App Limit remains scheduled independently of the
UI, and resume refreshes its deadline. This patch does not add OS scheduling of
future focus blocks during background suspension. When catch-up reaches a later
focus block, the current block is reconciled on return; missed background focus
coverage is not retroactively reported as an App-Limited Deep Session achievement.
Screen-off timer continuity is therefore separate from unattended cross-cycle
FamilyControls enforcement. The latter requires its own scheduling implementation
and physical-device acceptance; this is a known existing architecture limit.

This change covers lock/background suspension with the session retained in memory.
It does not introduce recovery of a Deep Session after force-quit or OS termination.

## Validation

- Debug simulator build passed on iOS 26.5.
- Design direction source gate and git diff whitespace checks passed.
- 39 MoriRoutingTests passed, including new elapsed-time catch-up, fractional
  pause/resume, duplicate update/completion, and fourth-cycle long-break tests.
- UI tests passed for background/foreground continuity, paused background
  stability, toggle use during a session, persistence into setup after relaunch,
  Dark Room availability, and existing pause/resume/end flow (four test methods).
- An initial setup UI query used the visible title instead of the existing
  accessibility label Show session options; corrected the harness and reran both
  setting tests successfully. Runtime timing tests remained passing.
- Manual Simulator Device > Lock showed a black display and the lock-screen AX
  tree. Device > Home returned to the same running session: about 23:25 before
  locking and 21:13 after unlocking. The session was then manually paused.
- Two visual passes against the approved paper/landscape references: first added
  the native setting; second moved it before the active cue toolbar and reduced
  helper-copy emphasis so the requested setting is visible without extra scrolling.
  Setup, active and Dark Room screenshots inspected after the final pass.

Artifacts: /Volumes/External SSD 4TB/DeveloperData/Mori-screen-off-qa/
- pass1.xcresult: initial 38 unit + 3 UI pass
- final.xcresult: 39 unit + background and existing session UI pass; old settings
  query failed (retained as evidence)
- settings-verified.xcresult: corrected persistent-setting and Dark Room UI pass
- deep-session-screen-options.png, deep-session-setup-screen-options.png,
  deep-session-dark-screen-options.png

Physical iPhone auto-lock/side-button behavior, hardware cues and multi-cycle
shield enforcement have not been device-verified. No commit, push, physical
install or release was performed. Prior quiet-countdown edits and the unrelated
MoriWatch.xcscheme change were preserved.
