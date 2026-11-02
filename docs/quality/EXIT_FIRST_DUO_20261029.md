# Exit-first flow and iPhone Duo implementation

Status: implementation draft; native build, simulator evidence and visual acceptance pending.

Base: release9 (`81828b7`) plus the reviewed Oct 28 Today contrast port (`27e95db`).
The release9 allowance revision, history generation, idempotent confirmation,
expiry and stale-shield recovery are preserved. The scheduled-protection
prototype remains gated off.

## Changed behavior

Before Feed now offers an immediate offline handoff, optional configured
breathing, or deliberate use with an explicitly chosen time. Reason and return
anchor are optional. Existing allowances keep their original deadline, including
when the user chooses to put their phone aside. Reminders only schedule when
already enabled and authorized, and match anchors to the exact allowance end.
On iOS 26.5+, the shield primary action requests the supported parental-control
app handoff; earlier systems keep the existing close/queued-route fallback.

Replacement and urge selections no longer fabricate completed minutes or seeds.
Action evidence is optional Codable metadata; missing legacy replacement evidence
is treated as estimated. Historical values remain intact. Daily, weekly, Life Grid and Watch-summary quiet totals use the same evidence
rule. Recovery no longer treats a selected alternative as a completed activity. This is a product-flow change,
not evidence that real-world phone use has improved.

Today exposes live allowance expiry and the next action; onboarding offers value
before Screen Time permission and no longer enables Morning Gate implicitly.
English, Traditional Chinese and Simplified Chinese are included.

## Adaptive layout

Xcode 27.1+ is the supported Duo build toolchain (Swift 6.4; iOS 27.1 SDK).
Root navigation uses system tabs on iOS 27.1+, and the existing paper dock on
older iOS. Controls move together into an unobstructed interaction region on an
active book/tabletop division. Log uses state-preserving AnyLayout columns and
Life Grid adopts ArrangementView outside its scroll views. Root reading widths
are bounded and landscape is enabled in source and generated project settings.
The old compiler branches retain available-width and safe-area fallback behavior;
they are not evidence of full Duo support. Xcode 27.0 is not a supported Duo build.

Apple references:
- https://developer.apple.com/iphone-duo/prepare/
- https://developer.apple.com/videos/play/tech-talks/111463/
- https://developer.apple.com/documentation/managedsettings/shieldactionresponse/openparentalcontrolsapp
- https://developer.apple.com/xcode/system-requirements

## Verification

- Added model coverage for immediate exit, optional breath, explicit time,
  optional reason, duplicate selection, legacy decoding, original expiry and
  book/tabletop control geometry.
- Updated existing breath/intent UI tests for the approved flow; added immediate
  exit, handoff through backgrounding, deliberate use, and landscape/large-TC cases.
- Source parse and diff whitespace checked locally. The execution environment is
  Linux and has no Xcode, Swift compiler, Ruby or plutil. Native build, full scheme,
  generated-project idempotence, on-device Screen Time and screenshot QA require
  the macOS CI / Apple toolchain. No native pass is asserted by this document.
- Before release: run compact/expanded/half-fold/tabletop transitions mid-timer and
  mid-journal draft, light/dark, EN/TC, largest Dynamic Type, VoiceOver and Reduce
  Motion. Capture native screenshots and complete the two reference refinement
  passes required by AGENTS.md. Verify shield app handoff and expiry on a device.

## Local checks and publication status

The modified Swift sources passed tree-sitter syntax comparison with the base;
three unchanged parser limitations in the existing gate store are excluded from
that comparison. This is syntax inspection, not Swift compilation. English,
Traditional Chinese and Simplified Chinese string tables parsed; Info.plist,
shared schemes, project YAML and workflow YAML parsed. The iPhone orientations
agree between the source configuration and Info.plist. `git diff --check` passed.

`bash scripts/run_native_tests.sh` stopped at `Required command not found:
xcodebuild`. A workspace-only Swift toolchain installation was also attempted;
the official release service returned HTTP 403. No unit/UI runtime pass or
native screenshot comparison has been claimed. The added UI cases include Log
draft retention through rotation/backgrounding and large-text Traditional Chinese.

Publication destination: `codex/mori-exit-first-duo-20261029`, draft PR to `main`
in `metta-man/mori`. An earlier automatic review blocked publication pending
explicit destination approval. The user subsequently approved pushing this new
branch, opening the draft PR and running CI on 2026-11-01 (Hong Kong time).
Publication is now authorized; native validation remains pending CI results.
