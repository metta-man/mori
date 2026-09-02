# Mori Design System v2

## North Star

Mori is a calm digital wellbeing companion. It does not block, punish, reward, or optimize the person. It creates a small space between impulse and action.

Every core flow follows:

1. Pause.
2. Notice.
3. Choose.

Before a screen ships, ask: **Does this screen make the user breathe slower within two seconds?** If not, remove, soften, or defer elements until it does.

## Product Language

- Say **Intent Count**, never Screen Time total.
- Say **Quiet Minutes**, never streak, XP, coins, earned time, or productivity score.
- Say **Deep Session** or **Quiet Session**, never Pomodoro.
- Describe options without judgment: Reply to someone, Learn, Relax, Habit, Other.
- Never imply scarcity or failure at the moment of choice.
- Never praise loudly. A completion is acknowledged, not celebrated.

## Navigation

Mori has exactly three top-level destinations:

- Today
- Focus
- Log

Settings is a floating 44pt-or-larger control and opens a short modal sheet. It is never a tab.

## Visual Tokens

### Color

- Paper: `#F7F1E7`
- Raised paper: `#FBF7EF`
- Forest ink: `#203C33`
- Primary forest: `#21493C`
- Sage: `#728478`
- Stone body: `#4D5650`
- Muted stone: `#69716C`
- Hairline: forest ink at 14% opacity

Bright blue, orange CTAs, neon, synthetic gradients, and decorative frosted glass are outside the system.

### Typography

- Display: New York where available; Iowan Old Style, Palatino, then Georgia as fallbacks.
- Body and controls: San Francisco / system sans.
- Titles use sentence case, restrained weight, and short lines.
- Body text defaults to 15–17pt. Small supporting copy never carries essential meaning.
- Timers use tabular numerals without a progress ring.

### Shape and Depth

- Primary cards: 22–24pt radius.
- Controls: 14–17pt radius.
- Floating settings: circular, minimum 44 × 44pt.
- Shadows are broad, low-opacity forest ink. No stacked elevation system.
- Cards are opaque watercolor paper, not translucent glass.

### Spacing

- Screen edge: 20–22pt.
- Major section gap: 24–32pt.
- Internal card rhythm: 16–20pt.
- Empty space is functional. Do not fill it with tips, metrics, or decorative widgets.

## Motion

- Screens enter with a slow opacity change and no bounce.
- Buttons expand by roughly 1–2% while pressed.
- Ambient watercolor may drift by no more than a few points over 20+ seconds.
- The breathing image changes scale slowly and continuously.
- Motion never delays an action and never carries essential meaning.
- Reduce Motion removes parallax, repeated scaling, camera movement, and ambient drift; static art and short fades remain.

## Core Screen Contracts

### Today

- One dominant next action.
- One primary CTA.
- App Limit may appear only as a quiet status line.
- Intent Count and Quiet Minutes do not compete with the next action.
- No grid, ring, chart, quick-action cluster, or recommendation carousel.

### Before Feed

- Begin with the configured Breath Key. Fresh installs default to three Long Exhale cycles: 4 seconds in and 6 seconds out per cycle.
- `Guided breathing` lets the person choose a technique and 1 to 10 complete cycles. `Follow your own breath` offers a 10-second to 10-minute timer with no phase prompts.
- Capture the configuration when the sheet opens. Changing Settings or a custom technique must not change a breath already in progress.
- Follow-your-own mode starts with one long singing-bowl cue only on the first start. It does not replay on resume or late sound enable, and it has no completion sound.
- Keep the configured method in supporting copy. Use the restrained common title `Begin with the breath` so the breathing form, phase, and countdown remain the visual focus.
- Breath completion reveals one compact intent surface; it does not open the feed.
- Ask “Why now?” with five neutral choices and no preselection.
- Every choice follows the same plan: choose a small 2, 5, 10, or 15 minute feed boundary, then see the no-typing “Where do you want to return?” question.
- Show the return question for every reason; never gate it on Habit or recent intent history. Choosing a return activity remains optional.
- `Open for …` is enabled only after the breath, reason, and boundary are complete. The feed never opens automatically.
- `Keep feed closed` remains immediately available after the breath, without requiring any intent choices.
- A kept-closed outcome is counted as an explicit choice, never converted into invented saved minutes or an opened-window intent.
- An optional window-end notification may describe the expected expiry, but Screen Time grace expiry remains the enforcement source of truth.
- Do not show feeds remaining, time spent, warnings, or guilt copy.

### Focus

- Show only the Deep Session title, large timer, forest atmosphere, blocked-app summary, and Pause.
- Do not show a circular progress meter, score, forest-growth instruction, edit controls, or colorful app-icon strip.
- End Session appears only after pausing.

### Session Complete

For a completed 25-minute session, use exactly:

> One quiet session protected.
> 25 quiet minutes.

If the person intentionally ends early, report only the truthful elapsed whole minutes, or “A quiet moment.” Never imply that 25 minutes were protected. Actions are Continue and, only where technically reliable, Open Instagram. No “great work,” “earned,” confetti, growth metaphor, badge, or reward animation.

### Log

- Pause: one closest feeling or state, with no preselection.
- Notice: one broad context, without requiring typing.
- Choose: one gentle response, always including `Just record it`.
- One optional sentence, disclosed only when requested.
- One optional photo affordance.
- Save check-in.

Only one guided question is active at a time on the same paper surface. Earlier
answers collapse into compact editable summaries. The flow never uses a timer,
completion percentage, therapy label, forced reframing, or praise.

History, export, analytics, and archive tools stay outside the first viewport.
The Log never resembles a document editor or a dense prompt feed.

## Apple HIG Gate

The v2 implementation follows Apple’s current guidance for [design principles](https://developer.apple.com/design/human-interface-guidelines/design-principles), [tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars), [buttons](https://developer.apple.com/design/human-interface-guidelines/buttons), [typography](https://developer.apple.com/design/human-interface-guidelines/typography), [motion](https://developer.apple.com/design/human-interface-guidelines/motion), [accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility), and [modality](https://developer.apple.com/design/human-interface-guidelines/modality).

Required checks:

- Controls have a minimum 44 × 44pt hit area and visible pressed/focus state.
- A screen has one visually prominent action whenever possible.
- Selection is communicated by more than color alone.
- Small text reaches 4.5:1 contrast; large or bold text reaches 3:1.
- Decorative watercolor is hidden from assistive technology.
- VoiceOver order follows the visible hierarchy.
- Dynamic Type can grow without hiding the primary action.
- Modal flows have an obvious dismissal and never stack.
- Text sits on clear paper or quiet negative space, never on detailed forest texture.

## v2 Screen Critique

| Screen | Slower-breath test | Apple HIG check | Mori check | Result |
|---|---|---|---|---|
| Today | Large negative space and one card settle attention immediately. | One primary action; 44pt controls; three-tab hierarchy. | No dashboard, chart, streak, or competing widget. | Pass |
| Before Feed | The configured Breath Key leads into a compact intent surface before the feed opens. | Semantic controls, 44pt targets, explicit Close, Open, and Keep closed. | No preselection, guilt, scarcity, or automatic opening. | Pass |
| Before Feed breath key | Guided breathing follows the selected rhythm; follow-your-own holds a static bloom around a truthful timer. | Reduce Motion uses static art and text; Pause, Resume, and Close remain available. | Completion reveals choices instead of opening the feed. | Pass |
| Deep Session | Plain timer and misty forest replace the productivity ring. | Readable hierarchy in an immersive, self-contained session; primary tabs return after completion. | No Pomodoro language, edit cluster, or forest-growth mechanic. | Pass |
| Paused | Additional end action appears only when relevant. | Clear state text and labeled controls. | “Nothing is lost” removes performance pressure. | Pass |
| Complete | Quiet acknowledgment replaces reward language. | Two clearly labeled actions with readable contrast. | No earned time, praise, growth, or confetti. | Pass |
| Log | One calm question leads at a time; prior choices collapse before the next appears. | Semantic selectable controls, 44pt targets, editable summaries, and a clear save state. | No blank editor until requested, forced reframing, clinical labels, prompt feed, or gamified completion. | Pass |
| Settings | A short opaque sheet keeps secondary choices out of navigation. | Modal label, dismissal, switches, and background isolation. | Only quiet, relevant preferences appear. | Pass |

## Data Integrity Notes for Native Implementation

- Open-window intent and kept-closed mastery counts require explicit, distinct outcomes, not proxies based on shield-button attempts.
- A truthful lifetime Quiet Minutes value requires durable daily/lifetime buckets; the current retained action history is not sufficient for a true life total.
- “You’re opening Instagram” and “Open Instagram” should be shown only when the triggering/configured app can be identified and opened reliably. Generic production fallback copy is “You’re opening a feed” and “Continue.”
