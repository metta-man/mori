# Mori Design Specification

**Status:** Approved visual direction
**Reference image:** `DesignReferences/mori-approved-reference.jpeg`
**Primary platforms:** iOS and watchOS
**Implementation:** SwiftUI

---

## 1. Product Definition

Mori is a calm digital-wellbeing app that helps users interrupt automatic phone use, protect focused time, and keep a light record of their days.

Mori is **not** a productivity dashboard, habit tracker, punishment system, or settings utility.

The core interaction model is:

> Pause → Notice → Choose

Mori should never shame the user for opening an app. It should create a small space in which the user can decide consciously.

### Product promise

- Reduce automatic social-media opening.
- Protect quiet or focused sessions with app limits.
- Encourage reflection without requiring extensive journaling.
- Let users see the shape of their days without turning life into scores.

### Emotional target

Opening Mori should feel like entering a quiet landscape: slow, clear, warm, and spacious.

---

## 2. Non-Negotiable Functional Safety

All existing working functionality must remain available unless a task explicitly says otherwise.

Preserve:

- FamilyControls authorization
- app and website selection
- DeviceActivity schedules
- ManagedSettings shielding
- Before Feed Reset
- intent selection
- configurable Before Feed breath key and intentional open-window choice
- Deep Session
- Quiet Mode
- Offline Reset
- duration selection
- blocked-app selection
- pause, resume, and completion states
- Daily Log
- mood selection
- text note
- photo attachment
- archive data
- Life Grid month and year views
- day detail
- reminders
- language
- app and data settings
- current persistence and navigation

Do not rewrite the data model merely to achieve a visual change. Refactor presentation, hierarchy, and progressive disclosure first.

---

## 3. Approved Visual Source of Truth

The approved reference image is:

`DesignReferences/mori-approved-reference.jpeg`

Additional approved screen references are:

- `DesignReferences/mori-today-view-reference.jpg` — detailed Today composition and floating-dock treatment
- `DesignReferences/mori-screen-flow-reference.jpg` — Today, Life Grid, Focus, Deep Session, and Log flow overview

For the Today root screen, use the detailed Today reference when it provides more specific layout or chrome guidance; use the primary reference for the broader Mori visual language.

This image is the primary visual source of truth for:

- composition
- information hierarchy
- typography scale
- spacing
- card proportions
- illustration placement
- navigation treatment
- interaction density
- visual tone

For Log, the guided-check-in contract in section 7.8 supersedes the exact input
controls shown in the reference image. The reference remains authoritative for
the paper surface, editorial hierarchy, card proportions, navigation, and Life
Grid relationship.

Do not interpret the reference loosely. A UI task involving the screens shown in the reference is a **reference-matching task**, not an opportunity to invent a different design.

Before editing SwiftUI for visual work:

1. Open and inspect the reference image.
2. Compare the current screen against the corresponding reference screen.
3. Identify visible differences.
4. Implement toward the reference.
5. Run the app and capture screenshots.
6. Compare again and complete at least two visual-refinement passes.

---

## 4. Design Principles

### 4.1 One clear action

Every screen must have one obvious primary action. No more than two secondary actions should visibly compete with it.

### 4.2 Progressive disclosure

Mori may contain many functions, but not every function should appear at the top level.

Advanced controls should appear only when needed through:

- a compact row
- a bottom sheet
- a disclosure group
- a detail screen

Avoid generic rows named “More for today,” “More quiet tools,” or “More from your Log” when a meaningful named feature can be shown directly.

### 4.3 Calm, not empty

Whitespace should create rhythm and focus. Large unused areas with one plain card do not count as calm design.

Use background illustration, typography, spacing, and subtle grouping to make the screen feel intentional.

### 4.4 Illustration belongs to the composition

Watercolor imagery must be integrated into the interface. It must not look like a wallpaper placed behind generic cards.

Illustrations may:

- emerge from the lower edge
- fade into the paper background
- sit behind a timer
- define a mode card
- create depth around a floating panel

Avoid hard rectangular image crops unless the approved reference uses one.

### 4.5 Reflection, not performance

Do not introduce:

- streaks
- XP
- coins
- scores
- completion percentages
- confetti
- competitive metrics
- achievement badges

Use quiet measures such as:

- quiet minutes
- days remembered
- most common tone
- intent count

---

## 5. Visual Language

### Colour

Primary palette:

- warm cream / paper off-white
- deep forest green
- muted sage
- soft stone grey
- restrained moss and earth tones
- muted rose for difficult days
- muted ochre for neutral days

Avoid:

- bright blue productivity UI
- saturated orange calls to action
- neon colours
- high-contrast gradients

### Typography

Use an editorial hierarchy.

**Display titles**

- elegant serif
- large but not oversized
- forest green
- generous line spacing

**Body and controls**

- San Francisco / system sans-serif
- compact
- softer grey-green
- avoid excessive bold weights

Typography should establish hierarchy before adding another container.

### Containers

Use fewer, richer containers.

- Soft rounded corners
- restrained borders
- minimal shadows
- subtle warm fill
- varied treatment according to purpose

Do not put every section in an identical white rounded card.

### Buttons

A large dark-green filled button is reserved for a real commitment action, such as starting a session.

For lighter actions, prefer:

- circular play controls
- compact text actions
- soft bordered rows
- low-emphasis secondary buttons

Do not use a large banking-app CTA on every screen.

### Motion

Motion should be slow and organic.

- gentle fades
- subtle parallax
- watercolor breathing expansion
- no bounce-heavy transitions
- no celebratory explosions

### Root-screen chrome and safe areas

Today, Focus, and Log must feel like one continuous illustrated paper surface, not content placed below system navigation chrome.

**Non-negotiable:** the watercolor surface extends through the top safe area and behind the native status bar. Root screens must not expose any `UINavigationBar` background, blur/material, shadow, divider, or colour boundary.

- Hide the default `UINavigationBar` appearance entirely on root screens. Keep the `NavigationStack` for routing, but render no native navigation-bar background or separator.
- Build each root title, supporting line, and Settings control as a custom in-content header.
- Place the paper and watercolor artwork at the outermost root layer and extend that layer behind the status bar with `.ignoresSafeArea(edges: .top)` or an equivalent top-safe-area treatment. Header controls may respect safe-area insets; the artwork must not stop at them.
- Keep the system status bar native and visually natural over the artwork. Do not draw a replacement time, signal, or battery display.
- Do not show a navigation-bar divider, material strip, hard colour handoff, or horizontal seam below the status area.
- Where two background layers meet, use a short fade or mask so the transition reads as one continuous watercolor field.
- Preserve `NavigationStack` and existing routes. Pushed detail screens may use deliberate back-navigation chrome, but hiding root chrome must not remove their navigation behaviour.

In SwiftUI, do not apply a visible `.toolbarBackground` to a root-screen navigation bar. During screenshot QA, inspect the full strip from the top pixel through the custom header: artwork must remain continuous and no navigation-bar edge may be visible.

---

## 6. Information Architecture

Primary navigation contains three tabs only:

1. Today
2. Focus
3. Log

Settings remain available through a small top-right control.

Pushed detail screens such as Life Grid should normally hide the main tab bar.

---

## 7. Screen Specifications

## 7.1 Today

### Purpose

Answer:

> What is the best mindful action now?

Today is not a dashboard or feature directory.

### Required hierarchy

1. `Today`
2. short supporting line
3. Before Feed / current app-limit state
4. one primary reset action
5. quiet-minute or intent summary
6. optional secondary context

### Visual direction

- One dominant composition
- Warm paper background
- Subtle landscape integration
- Watercolor continues behind the native status bar with no navigation-bar background or divider
- Custom header has generous breathing room below the status area
- Clear primary action
- No repeated generic “More…” card

### Content behaviour

If an app limit is active, show the selected app or protected set in a concise way.

Do not make analytics more visually prominent than the next action.

---

## 7.2 Before Feed: breath key and intent choice

### Purpose

Turn the interruption into a small passage ritual before opening a selected
feed. The first state is one configured Breath Key. Fresh installs default to
one Long Exhale breath: 4 seconds in, 6 seconds out. Do not stack another pause
or timer after the Breath Key.

Settings expose two bounded styles:

- `Guided breathing`: choose a technique and 1 to 10 complete cycles.
- `Follow your own breath`: choose 10 seconds to 10 minutes, with no inhale,
  hold, or exhale phase prompts.

Capture an immutable configuration snapshot when the sheet opens so live
Settings or custom-technique changes cannot alter an active session. Guided
duration is the exact selected pattern duration multiplied by its cycle count;
round only the displayed countdown upward.

### Suggested options

- Reply to someone
- Learn
- Relax / entertainment
- Just checking
- Other

The language must be non-judgmental.

After the breath completes, reveal one compact intent surface. No choice is
preselected. After any reason is selected:

- ask `What would be enough?` and let the person choose a small feed boundary
- show `After this?` / `Where do you want to return?` for every reason once a boundary is selected
- offer Work, Study, Someone, Rest, Move, and Sleep without requiring typing
- keep the return activity optional
- keep `Keep feed closed` available without requiring a reason, boundary, or return activity
- enable `Open for …` only after both a reason and boundary are selected

The feed never opens automatically. Opening creates only the selected 2, 5, 10,
or 15 minute window; the existing Screen Time grace expiry remains responsible
for reapplying the shield.

### Visual direction

- Editorial title
- Compact 44pt choice chips or rows on one paper surface
- One selected state
- One explicit `Open for …` action only when appropriate
- One quiet `Keep feed closed` action
- Close remains available but secondary

---

## 7.3 Before Feed: configurable breath key

### Required composition

- compact sheet header
- one restrained common title, `Begin with the breath`; keep the configured
  style, technique, cycles, and duration in the supporting summary rather than
  turning the mode name into the headline
- short supporting sentence
- breathing form and truthful countdown as one central composition
- guided technique, phase, and cycle progress close to the form
- for follow-your-own, a static breathing form and timer without phase prompts
- secondary close control
- lightweight Pause / Resume control once the timer starts

### Avoid

- hard horizontal background split
- excessive empty vertical space
- timer floating separately from the breathing visual
- oversized bottom CTA
- a mode-name headline that competes with the breathing form

In guided mode, the watercolor form should subtly expand and contract with the
breathing phase. Under Reduce Motion, use static art, phase text, and the
countdown instead of repeated scaling. Follow-your-own mode keeps the form
static and uses one long singing-bowl A cue only on its first start. The cue
must not replay on resume or after sound is enabled late; stopping, pausing, or
closing stops it. Follow-your-own has no completion sound. Breath completion
reveals the intent controls; it never opens the feed by itself.

---

## 7.4 Focus home

### Purpose

Let the user choose how they want to protect attention.

Show three visible modes:

### Deep Session

- Work, study, or create with apps blocked.
- Forest path or protected-forward-motion visual.
- Strongest visual priority.

### Quiet Mode

- Read, rest, meditate, or sit quietly.
- Fog, still lake, or slower visual contrast.

### Offline Reset

- Walk, stretch, make tea, or leave the screen.
- Open sky, distant landscape, and more negative space.

### Required card content

- title
- short description
- default duration
- compact circular start action

Do not hide Quiet Mode and Offline Reset behind `More quiet tools`.

---

## 7.5 Deep Session setup

Keep setup concise.

Default visible controls:

- duration
- blocked apps summary
- Start Deep Session

Advanced controls belong under `Session options`, including breaks, cues, and other session preferences.

---

## 7.6 Active Deep Session

### Required composition

- centered title
- restrained subtitle
- full-page or lower-half watercolor forest
- large circular progress ring integrated with the scene
- remaining time in the centre
- one circular pause control
- floating blocked-app panel
- compact Session options row if needed

The timer and landscape must read as a single composition.

Do not use a large white timer card over an unrelated background.

---

## 7.7 Session complete

Use quiet copy:

> One quiet session protected.

Then show the protected duration.

Primary action:

- Continue

Optional secondary action:

- Add a short reflection

No celebration effects, scores, or social sharing.

---

## 7.8 Log

### Purpose

Enable a meaningful daily record with minimal effort.

### Required hierarchy

1. `Log`
2. `One small check-in is enough.`
3. one active guided question inside a single paper card
4. `Pause`: choose the closest feeling or state
5. `Notice`: choose the broad life context
6. `Choose`: choose a gentle response, including `Just record it`
7. compact editable summaries of completed choices
8. optional one-sentence disclosure
9. optional photo row
10. Save check-in
11. visible Life Grid preview

The three questions reveal progressively on the same paper surface. Do not show
all choices as a dense tag wall or split the flow into onboarding-style pages.
No option is preselected. `Just record it` must remain available so the person
can complete the check-in without reframing or solving the feeling.

Specific feelings map to the existing Good, Neutral, and Difficult Life Grid
tones. The finer feeling, context, and response selections remain editable when
the person returns to today's entry.

The sentence editor stays hidden until requested unless an existing sentence is
being edited. Do not show a timer, progress percentage, clinical method label,
forced-positive copy, or celebratory completion treatment.

Do not replace Life Grid preview with `More from your Log`.

### Life Grid preview

Include:

- `Life Grid`
- current month summary
- text similar to `July · 11 days remembered`
- recent-day mini grid
- subtle disclosure indicator

The preview must look like accumulated days, not a menu row.

---

## 7.9 Life Grid month

### Header

- subtle standard back control
- centered title: `Life Grid`
- subtitle: `See the shape of your days.`
- compact Month / Year segmented control

### Calendar

- softly tinted date cells
- fine outline for today
- lower opacity for future dates
- near-transparent treatment for no entry
- no thick cell borders
- no oversized containing white card
- no main tab bar while pushed

Mood tone is primarily represented by the cell background.

Secondary indicators may show note, photo, or quiet session. Never show more than two indicators in one cell.

Use a restrained legend only when needed.

Integrate a landscape into the lower part of the page.

---

## 7.10 Life Grid day detail

Open a tall bottom sheet over a dimmed grid.

Include:

- date
- mood / tone
- saved sentence
- photo summary
- quiet minutes
- `View full entry`

The sheet should feel like an editorial memory card, not a dense utility form.

---

## 7.11 Life Grid year

Show all 12 months as compact mini grids on one vertically scrollable page.

Optional summaries, maximum three:

- Days remembered
- Quiet minutes
- Most common tone

The year view is a memory map, not an analytics dashboard.

---

## 7.12 Settings

Settings may use a conventional list because it is a utility screen.

Retain:

- App Limits
- Week / Life Grid archive access where still required
- Reminders
- Language
- App and Data
- About Mori

Use lower card height, restrained separators, and minimal shadows. Settings should not visually compete with Today, Focus, or Log.

---

## 8. Reusable SwiftUI Components

Create or refine reusable components where they improve visual consistency:

- `MoriPageHeader`
- `MoriModeCard`
- `MoriLifeGridPreview`
- `MoriCalendarCell`
- `MoriLandscapeBackground`
- `MoriPrimaryButton`
- `MoriFloatingPanel`
- `MoriMoodSelector`
- `MoriDayDetailSheet`

Do not over-abstract. Accurate visual matching is more important than building a generic component library.

---

## 9. Forbidden Patterns

Do not introduce:

- generic settings-card layouts on top-level screens
- repeated full-width “More…” rows
- large empty backgrounds with one plain card
- wallpaper plus unrelated white rectangles
- identical card treatment for every function
- bright productivity colours
- Material Design patterns
- glassmorphism
- heavy gradients
- thick shadows
- aggressive gamification

---

## 10. Validation Procedure

For every significant UI task:

1. Read this specification.
2. Open the approved reference image.
3. Capture the current implementation before editing where practical.
4. Implement the requested scope.
5. Run the app.
6. Capture all affected screens.
7. Compare screenshots side by side with the approved reference.
8. Perform at least two visual-refinement passes.
9. Verify that existing functions remain reachable and working.

### Visual review questions

For every affected screen, confirm:

1. Is the primary action obvious within two seconds?
2. Is secondary content competing with it?
3. Is illustration integrated rather than decorative wallpaper?
4. Are there unnecessary white cards?
5. Is typography doing enough of the hierarchy work?
6. Does the amount of visual content match the reference?
7. Does the screen feel calm rather than unfinished?
8. Does it still look like a generic utility app?

If the answer to question 8 is yes, continue iterating.

---

## 11. Definition of Done

A Mori visual task is complete only when:

- the affected screens visibly approach the approved reference
- major elements and proportions match the intended composition
- existing functionality remains intact
- no top-level screen has regressed into a settings-style directory
- root-screen watercolor continues behind the status bar with no visible navigation-bar background, divider, or seam
- screenshots have been reviewed after implementation
- at least two visual-refinement passes have been completed
