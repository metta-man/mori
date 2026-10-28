# Homepage contrast and placeholder port

This review branch ports seven reviewed visual adjustments onto `0d4a37b277cb78e942a77e91e3efee2a3e4a48d9`: existing dark ink for the nonediting intention heading, status row and quiet-minutes row; existing opaque paper behind both row labels and the intention card; and unrestricted wrapping for the empty intention placeholder. Saved intention previews retain their two-line limit and the editor retains one to three lines.

The source is the independently recommended isolated r3 candidate, manifest SHA256 `e18f9a12e777dcbe6bf19c2f5e8f79389c12e9a5eb69b8da79690a724f2a93fe`. This is a narrow port, not that complete candidate or its older flow integration. It preserves current typography, text, actions, state, accessibility identifiers and navigation. It adds no dependencies, authorization, permission, shield or eligibility changes. Synthetic drivers, diagnostic artifacts and the ineffective r4 experiment are excluded.

## Evidence and acceptance limits

The isolated r3 native build passed. Its four synthetic homepage audits returned EN normal pass, TC normal pass, TC AX5 pass and EN AX5 fail: five of six earlier contrast findings cleared, with the original EN AX5 initial-viewport intention warning retained. A separate same-process diagnostic retained that failure and found no additional contrast issue after full reveal. Those results belong to the exact isolated r3 source; they are **not native validation of this port onto an older homepage**.

The later geometry/pixel diagnosis found ordinary scrolling beneath a sibling dock. The exported SDK issue crop contains dock pixels and offscreen black extent; the internal sampling cause is unproven. No confirmed false-positive ruling, warning suppression or acceptance closure follows. Assistive-focus/auto-scroll acceptance remains unobserved. No 9.5, manual VoiceOver/device, real OS delivery or protection reliability acceptance is claimed.

This Git publication uses lightweight source/diff checks and an independent review of the actual staged patch. A fresh native build and EN/TC normal/AX5 rendered verification of this reconciled baseline remain unrun. Publication is for code review and does not authorize or establish release readiness.
