# Reusable Block Lists — 2026-09-07

## Delivered behavior

Settings → Block Lists opens the existing App Limits PIN gate when configured.
Users can create any number of named lists, select apps and websites, rename,
edit, and delete with a centered confirmation alert. Empty lists may be saved
as drafts; empty and duplicate names are rejected. Back/Cancel discards editor
changes. The editor and app chooser push within the Settings navigation stack.

App Limits, onboarding app selection, and session app-limit pickers offer
**Load Block List** when saved lists exist. Loading replaces only the local
picker draft; the existing **Done** action commits through AppLimitManager.
Empty saved lists cannot be loaded. Essential Mode remains an allow-list and
does not offer block-list loading.

Lists are reusable snapshots, not live references. Saving, renaming, or deleting
a saved list never rewrites the default/feature selection or reapplies shields.
To apply later edits, load the list again and confirm Done. There is no automatic
schedule, active-list switch, or change to existing protection semantics.

## Persistence and privacy

- New App Group key: `mori_saved_block_lists_v1`; existing selections are untouched.
- Stable UUIDs, names, and Codable FamilyActivitySelection values.
- Matches existing enforcement support for individual apps and websites;
  category tokens are removed and the editor explains individual selection.
- Corrupt library data is retained; mutation fails instead of overwriting it.
- Existing ScreenTimeSelectionPersistence.clearAll removes the library as part
  of the existing Screen Time/data reset path.
- English, Traditional Chinese, and Simplified Chinese copy included.

## Visual refinement

Approved reference: DesignReferences/mori-approved-reference.jpeg, with the
active still-paper Settings constraint in MORI_DESIGN_SYSTEM_V2.md.

1. Initial screenshots exposed a stacked editor sheet and white system form
   rows. Changed the editor to a pushed destination and gave rows Mori paper.
2. Reviewed the smaller iPhone screenshots, including centered deletion and
   keyboard visibility. Added a vertical fallback for app counts at larger text
   sizes and explicit back navigation for the pushed native app chooser.

Evidence directory:
`/Volumes/External SSD 4TB/DeveloperData/MoriBlockLists/`

- `pass1.xcresult`: four persistence tests and English CRUD UI test passed.
- `pass2.xcresult`: same five tests passed on the compact iPhone simulator after
  the navigation/paper refinement.
- `final.xcresult`: all 70 native unit tests and both UI tests passed.
- `localized-verified.xcresult`: both UI tests passed again after correcting the
  inherited English fallback labels; final Chinese screenshots were inspected.
- Exported screenshots are under `pass1-shots/`, `pass2-shots/`, `final-shots/`, and `verified-shots/`.
- Settings/App Limits source contracts, localization plist syntax, and
  `git diff --check` passed.

## Remaining device verification

Simulator tests validate list management and app compilation, not real Family
Controls authorization, opaque app-token selection, or ManagedSettings shielding.
On a signed device, verify choosing actual apps, reloading saved selections,
cancelling a loaded selection, applying via Done, PIN-gated entry, and unchanged
active/default selections after editing/deleting a saved list. The native picker
and loaded-list menu require this device-level review. No physical installation,
commit, push, or release was performed for this task.
