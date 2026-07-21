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
- 30-second pause and breathing states
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

## 7.2 Before Feed: intent choice

### Purpose

Create a pause before opening a selected feed.

### Suggested options

- Reply to someone
- Learn
- Relax / entertainment
- Habit
- Other

The language must be non-judgmental.

If `Habit` is selected, gently offer a 30-second pause before continuing.

### Visual direction

- Editorial title
- Spacious choice rows
- One selected state
- Continue action only when appropriate
- Close remains available but secondary

---

## 7.3 Before Feed: 30-second pause

### Required composition

- compact sheet header
- title such as `Stay with the pause`
- short supporting sentence
- breathing form and countdown as one central composition
- inhale / exhale instruction close to the form
- secondary close control
- lightweight pause control

### Avoid

- hard horizontal background split
- excessive empty vertical space
- timer floating separately from the breathing visual
- oversized bottom CTA

The watercolor form should subtly expand and contract with the breathing phase.

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
2. `One small note is enough.`
3. compact Mood section
4. one-sentence field
5. optional photo row
6. Save entry
7. visible Life Grid preview

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
