# Morning / bedtime protection prototype

Standalone package only: not registered in Mori's Xcode project. Tests request no Screen Time permission and change no real shield.

## Semantics and migration

“First phone use during your morning window” means the first eligible DeviceActivity callback delivered during that configured interval. The persisted 30-minute default starts at delivery, never an inferred unlock/wake time. Duplicate callbacks cannot extend it. An absolute running morning deadline survives relaunch, duration edits and time-zone changes.

Bedtime has an independent enable and explicitly selected local start/end. Calendar endpoint days come from the configured overnight relationship, not from searching after a shifted start. Skipped endpoints use the next valid time on their intended day; if both collapse to the same instant, that date has no window. Repeated endpoints both use the first occurrence; a short folded-hour window does not reopen on the second occurrence. Import legacy enabled/start/duration via ProtectionConfiguration's legacy initializer and the existing completion day via ProtectionState. Existing users retain fixed-time morning mode; bedtime stays disabled. No existing history is deleted.

## Required host integration — not activated

1. Add the core to application and monitor extension targets. Supply a dedicated app-group file URL for ProtectionFileStore. Do not reuse/overwrite BeforeFeed history. Validate app-group migration before writes.
2. Expose configurable morning mode/detection start/end/duration (30-minute default), plus independent bedtime start/end/enable. Preserve existing choices until explicitly changed. Add no direct bypass.
3. Native adapter registers repeating morning detection and separate bedtime boundaries. Encode revision in activity names; reject stale callbacks. Forward morning intervalDidStart to morningFirstUse, other boundaries and app foreground to reconciliation. Delivered callbacks are not exact unlock events.
4. Use ProtectionRuntime with the shared ProtectionFileStore: the same file lock spans read, durable pending marker, scheduling, contribution writes and acknowledgement. Effects must be bounded synchronous functions, not detached Tasks. Never reenter storage from effects or wait for another process requiring the same lock. All scheduled state/settings writers must participate in this lock. Register a separately named supported expiry rendezvous; never stop/restart the callback's own schedule inside that callback. Require effectsApplied AND the fresh plan showing the captured scopes unshielded before showing access open; a historical duplicate grant receipt alone does not establish current access.
5. applyScheduledContribution must recompute the existing passive-gate union, preserving independent BeforeFeed, explicit focus and PIN requirements. Update app/category/domain selections consistently; never clear the entire ManagedSettings store.
6. Reuse existing BeforeFeed breathing → intention → allowance confirmation UI. Capture a ProtectionBreathTicket at flow entry, submit only after actual completion AND confirmation. Cancellation/abandonment invalidates it. Coordinate the existing BeforeFeed allowance with scheduled contributions before showing access as open: a scheduled grant alone cannot clear an unrelated shield.
7. Allowances are scoped to captured window IDs and clipped to each window end. They do not complete the whole morning/bedtime window. Duplicate confirmation returns its receipt without extending access. Resume/extension callbacks reconcile expired grants.

## Side-effect ordering and recovery — corrected core

ProtectionStorage.exclusive holds one advisory App Group file lock across the entire operation, including synchronous effects and acknowledgement. An old callback cannot release a snapshot then apply it after a newer writer. Callback `at` is event metadata only; runtime samples its injected clock after locking, again after scheduling/before applying, and after OS writes. Eligibility and expired scopes are recomputed. A newly encountered calendar scope needs its own registration; same rule name does not authorize a different dated window.

Pending recovery is persisted before side effects. Effects acknowledgement stores both actually applied rule names AND window IDs. Failure/interruption leaves a pending marker. Fresh foreground/extension callbacks retry from the persisted state; host startup must reconcile pending recovery before reporting enforcement. OS effects and storage are not an atomic transaction: a write can succeed and its acknowledgement fail, so retries must replace the complete scoped contribution idempotently. No event is shown as successful until acknowledged.

Registration failure does not block removing expired or unauthorized contributions. Cleanup uses only still-valid previously applied window IDs; it never enables a new window without registration. A newly confirmed allowance is rolled back whenever its required re-lock registration is invalid: initial failure, replacement failure after scheduling delay, pre-apply deadline invalidation, or post-effect invalidation. Rollback restores only that operation's allowance/receipt/order and grant-owned epoch; it preserves advanced clock, reboot recovery/retirement and independently invalidated epochs, then reconciles at the current logical time. Expired bedtime is removed while an originally applied, still-live morning scope remains shielded. Historical duplicate receipts are not treated as newly created grants. Effects failure may leave its durable mutation pending and returns no successful receipt; reconciliation resolves it. Existing BeforeFeed/focus/PIN contributions must remain independently composed by the native adapter.

After EVERY contribution write, including a compensation, runtime samples/advances the clock and reconciles again before acknowledgement. Expired applied scopes are removed under the same lock; plans/lastAppliedWindowIDs are computed from the latest sample. A failed allowance attempt remains pending and unsuccessful even if its scopes have since expired. The operation has a fixed bound: one initial write plus at most three additional writes (one grant compensation and at most two strictly removing writes for morning/bedtime). There is no unbounded retry loop. A future rule expansion or unexpected bound exhaustion returns an unsuccessful pending outcome; it never claims enforcement.

## Voluntary clock contract — isolated revision awaiting independent review

Persist the original absolute session end once. Normal app/extension handoffs and a coherent reboot preserve that end and any still-valid allowance. Process UUIDs identify live samples only: they are not boot identities, faults or handoff budgets. There is no private boot API or wall-minus-uptime inference.

Each live process keeps one continuous elapsed anchor for each dated session using public mach_continuous_time, including sleep. Earliest valid expiry wins. Its existing anchor remains usable after another process has updated the persisted ledger. A new process does not manufacture elapsed evidence from persisted wall time. Forward clock corrections can expire earlier; backward corrections cannot prolong a session while a coherent live anchor is available. Fixed-time and first-use morning sessions preserve their original end across duration, trigger and time-zone edits.

An interprocess wall sample more than120seconds behind saved logical time, without an existing live projection, is an explicit material-discrepancy policy for review. Retire only the currently affected dated scheduled scopes and record recovery; do not invent an extra countdown. Retired dated scopes cannot be resurrected by a revision edit. Malformed morning dates retire only that morning contribution, preserving bedtime. Invalid clocks or unreadable state cannot activate protection: remove only the owned scheduled contribution, keep corrupt state bytes/preferences/independent restrictions, and record pending recovery. Removal must remain permitted when new activation eligibility is disabled.

This is voluntary local scheduling, not tamper-proof enforcement. Undetected clock manipulation between processes cannot be reliably detected without trusted time. No exact unattended DeviceActivity callback or removal timing is promised. Real device validation and independent review remain required before activation. The previous five-minute reboot/debit prototype is preserved in frozen evidence and is superseded only in this isolated candidate.

## Native adapter plan — not activated

1. Keep the corrected core outside shipping target membership until accepted. Start native work from current integrated mood source; never regenerate/revert its reviewed changes.
2. Implement and separately validate the clock provider using public continuous-time facilities and process-local anchors on iOS. No boot identity is required; do not treat a normal process change as a fault. Confirm sleep, app termination, extension process changes, clock rollback/forward, time zone and reboot.
3. Implement synchronous DeviceActivity registration with current revision/window ID names, documented minimum intervals and existing repeating expiry rendezvous. Registration failures remain durable pending. Foreground reconcile and later valid callback deliveries retry. No claim of exact unattended callback timing.
4. Implement scheduled contribution replacement through Mori's existing composed shield policy. All app/extension writers must share one coordination protocol/lock order; no named ManagedSettings store may be cleared globally. Refresh authorization/selection before each actual effect; revocation and stale revision must reject activation.
5. Ticket capture also runs against freshly loaded/reconciled state under coordination, using logical clock time. Cancellation invalidates epoch and creates no allowance. Confirmation waits for scheduling/OS acknowledgement, then checks current captured-window accessibility plus independent BeforeFeed/focus/PIN restrictions before reporting access open.
6. Fault-test cross-process interruption before effects, after effects/before acknowledgement, registration failure, callback expiry, overlapping contributions and concurrent configuration edits on a signed physical device. Persist pending state and retry from fresh state; do not replay a cached snapshot.

## Native acceptance pending

Pure tests exercise synthetic callbacks, persistence, DST/time-zone changes, cancellation and expiry; they do not establish real DeviceActivity delivery or cross-process ManagedSettings behavior. Apple callbacks depend on device use/system delivery. Verify minimum scheduling intervals, extension execution and registration from a callback on a signed physical device. An expiry rendezvous is not proof of exact unattended re-lock. Foreground recovery remains necessary. Do not advertise exact first-unlock detection or exact unattended expiry.

No backend/APNs infrastructure, suspension keepalive, new health claim or cadence change is introduced. Shipping source, permissions and device settings remain unchanged.

## Review copy

| English | Traditional Chinese |
|---|---|
| First phone use during your morning window | 朝早時段首次使用電話 |
| Morning window | 朝早時段 |
| Protect for 30 minutes after detection | 偵測到使用後，保護 30 分鐘 |
| Existing fixed-time settings stay until you change them. | 更改前會保留你原本設定的固定時間。 |
| Bedtime protection | 睡前保護 |
| Start / End | 開始／結束 |
| Take a short breathing break for temporary access. | 做個短呼吸練習，暫時使用。 |
| Your protection window continues after this break. | 暫時使用後，保護時段會繼續。 |
| Protection could not be updated. Please try again. | 暫時未能更新保護設定，請再試。 |

Reuse Mori theme/layout and existing Reduce Motion breathing. No new UI has been rendered or visually accepted here.


## Independent review follow-up — four fixes, still inactive

Critical joint compensation uses throwing preference writes and fresh checked reads. A missing/corrupt preference is not proof of successful removal. Matching newly introduced BeforeFeed grace is removed without purging history; actual restriction repair must acknowledge before scheduled rollback/journal deletion. Durable ownership is used even if a partially applied partner commit returned no receipt. Independently replaced grace and prior receipts remain untouched.

Every retained joint journal is unfinished, including an acknowledged record whose final fresh-access check or compensation failed. The file-backed journal/recovery primitive is shared by native code and pure failure/relaunch tests. Removal, repair or scheduled compensation failures retain the record for retry; malformed journal bytes are preserved. Acknowledgement alone never skips compensation.

Capability checks read continuous-clock availability without sampling/pruning session anchors. A defensive state:nil sample is non-mutating. The regression chain is live processA→stateless probe→extension writerB→resumedA after sleep and backward wall correction.

The preview no longer presents the production BeforeFeed reset sheet. Its dedicated breathing view uses the existing pure breathing snapshot/ink-bloom visual with a sealed ProtectionPreviewSession: concrete memory storage, participant, journal and effects only. Start/cancel/incomplete-confirm/complete-confirm are exercised without persistent data or native Screen Time framework effects. Production eligibility remains false. This revision has not been executed as a native preview; static dependency guard and pure lifecycle tests establish isolation for review, not native UI appearance.


## Checked repair inputs — follow-up P1

Acknowledged BeforeFeed repair now loads one immutable checked snapshot of every policy-critical input before any contribution write. It calls the actual selection-persistence and active-session-store checked loaders: absent records retain documented defaults, while fresh read, property-list type, JSON decode or invalid date/value errors throw. Profiles/default and dedicated selections for all features, migration flags, active-session metadata, current-shield feature, gate/grace flags, hidden-lock flags and legacy morning settings are validated. Owner marker/read failures also stop repair. The repair path never constructs the legacy selection store (which can migrate/write), calls normalizing/clearing getters, or interprets decoder failure as no active Focus.

The contribution plan and token acknowledgement use that captured snapshot, not a later fallback loader. On snapshot failure the framework effect closure is unreachable and the retained journal is not deleted. Active Focus/PIN remains untouched. Valid expired sessions are represented without clearing metadata during the read stage. Restoration permits later selective compensation; it does not erase existing receipt/history.

A macOS Foundation probe compiles the actual production profile/session models, selection/session checked loaders, checked preferences and repair snapshot. With a valid preference migration marker,10 malformed type/decode/date/flag/metadata cases retain journal and the independent restriction fixture before effects; restoration permits selective recovery. FamilyControls token encoding and UI/platform adapters are explicit local test shims: this is evidence for checked-loader ordering, not native framework token decoding or real ManagedSettings enforcement. Native UI/device activation remains off pending independent recheck.


## Concrete filesystem absence — follow-up P1

Critical persistence paths no longer preflight fileExists. ProtectionFileIO directly reads/removes and classifies only concrete Cocoa/POSIX not-found errors as absence; an underlying EACCES/EIO/ENOTDIR/ELOOP is never hidden by a broad Cocoa code. Preference reads/removal/migration/marker validation, journal prepare/recover/deletion and state-store initialization now propagate non-not-found errors. Ownership marker reads and explicit cleanup use the same boundary; uncertain shared ownership suppresses legacy resurrection without claiming native enforcement. Unreadable or malformed recovery diagnostics are preserved rather than replaced by an empty log.

The83-test suite retains all previous77 tests. A real non-root filesystem fixture leaves the preference migration marker valid while a per-key symlink targets a directory without search permission. The former fileExists preflight returns false, but the direct read throws; repair effects remain unreachable, independent Focus/journal remain unchanged, and restoration permits selective recovery. Deterministic read/removal fault tests and genuine absence tests exercise the same snapshot/journal implementation. The actual native-loader Foundation probe also continues to pass10 prior fault/restoration cases with its explicitly documented FamilyControls/UI shims. No native UI/device activation is performed.


## Scoped internal-testing release — 2026-10-12

The earlier scope statements in this document describe dated prototype evidence.
The current scoped release keeps the reviewed inactive protection core, Before Feed
allowance and breathing changes, and Settings/App Limits viewport changes. It
excludes the memory-only settings/breathing preview, DEBUG device-trial routes,
new synthetic UI hooks, unrelated Journal/Health-sharing work, and the separate
Live Activity behavior change. Pure host regression tests remain in this package;
ProtectionPreviewSession is excluded from native app/monitor target membership.
Production eligibility remains OFF. This release is an internal testing candidate;
large-text visual checks and real OS delivery/reliability remain unverified.
