# Quiet hierarchy refinement

## Task card

User approved the September 7 UI review proposal: less setup and dashboard
weight on Today, intention-led Focus entries, consistent settings controls,
lighter tab chrome and fewer initial feeling choices.

Presentation scope: Today, Focus, Log, shared bottom navigation; English,
Traditional Chinese and Simplified Chinese copy. Existing working-tree changes
are preserved, including the prior living landscape and unrelated watch scheme.
No changes to stores, permissions, timers, shielding, PINs, or saved emotion IDs.

Acceptance: all modes and secondary controls remain reachable; additional
feelings can be selected, saved, restored and edited; small-screen and large-type
visual review; two visual refinement passes; signed simulator build and scoped
regression checks. No physical-device install or release.

## Implementation

- One App Limits status link replaces the kicker, protected-selection block and
  breathing parameter summary. A compact Quiet Minutes disclosure retains the
  longest session detail. Zero kept-closed feedback no longer adds a second caption.
- Three intent labels lead to existing mode routes; Essential quick start remains
  separate from opening its settings.
- All root settings controls use the same plain gear. The bottom dock is 60pt,
  with 52pt items and a restrained shadow; labels and selected accessibility trait remain.
- Four feelings initially; a named disclosure reveals the other four. Existing
  selected secondary feelings are surfaced while editing without needing expansion.

## Verification

Evidence: `/Volumes/External SSD 4TB/DeveloperData/MoriQuietHierarchy`.

- Signed simulator build passed (`build-pass1.log`). `regression.xcresult` is
  green: 66 unit tests and 6 scoped UI tests, including three-tab navigation,
  pause/resume/end, App Limits entry and minute disclosure, additional-feeling
  save/restore/edit, existing guided Log save/restore and truthful kept-closed feedback.
- Pass 1 (`pass1/`, iPhone 17e): verified the reduced Today status, four initial
  Log choices and lighter dock. Found the longer Focus title crossing into foliage.
- Pass 2 (`pass2/`, iPhone 17 Pro): constrained that title to the left text area
  and improved the Today CTA's readable, scalable type. Inspected all three roots.
- `large-type/`: inspected all three roots at accessibility XX-large on iPhone
  17e; text wraps, the Today CTA grows, and long content remains in scroll views.
  The simulator text size was restored afterwards. This is visual inspection,
  not a complete manual VoiceOver audit.
- `traditional-chinese/`: checked the new labels and feeling choices. This exposed
  untranslated existing root copy, which was supplied in both Chinese catalogs.
  English, Traditional Chinese and Simplified Chinese plist validation passed.
- Final localization-only build passed (`build-final.log`). Recaptures in
  `traditional-chinese-final/` confirm the translated Today and Focus composition;
  the earlier green test run covers the final Swift code. `git diff --check` passes.
- The system Reduce Motion UI test was not repeated for this follow-up; landscape
  rendering is unchanged. Its earlier evidence is in the living-landscape report.

No physical-device Screen Time enforcement or energy measurements were performed.
No commit, push, release, or physical-device installation was made.
