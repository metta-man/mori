# Mori Feature Specification (MVP)

**Version**: 1.0  
**Date**: 2026-03-05  
**Author**: Flare (Design Agent)  
**Status**: Complete - Ready for Implementation

---

## Feature 1: Life Grid Visualization

### Overview
**Priority**: P0 (Core Feature)  
**Effort**: 2 weeks  
**Dependencies**: None

### User Stories

#### US 1.1: View Life Grid
> "As a user, I want to see my entire life as a grid of weeks so that I understand the finite nature of time."

**Acceptance Criteria**:
- GIVEN I have entered my birth date
- WHEN I open the app
- THEN I see an 80×52 grid (4,160 cells)
- AND filled cells show lived weeks (Mori Gold)
- AND empty cells show remaining weeks (light gray)
- AND current week is highlighted (Ember Orange)

#### US 1.2: Interact with Grid Cells
> "As a user, I want to tap a cell to see its date range so that I can reflect on specific periods of my life."

**Acceptance Criteria**:
- GIVEN I am viewing the life grid
- WHEN I tap a cell
- THEN I see a tooltip showing:
  - Year number (e.g., "Year 30")
  - Week number (e.g., "Week 15")
  - Date range (e.g., "Mar 5 - Mar 11, 2026")
  - Status ("Lived" or "Future")

#### US 1.3: Configure Life Expectancy
> "As a user, I want to adjust my life expectancy so that the grid reflects my personal circumstances."

**Acceptance Criteria**:
- GIVEN I am in settings
- WHEN I change life expectancy (default 80)
- THEN the grid updates to reflect new total weeks
- AND my data is preserved

### Technical Specifications

#### Data Model
```swift
struct LifeWeek {
    let id: UUID
    let weekIndex: Int           // 0-4159
    let yearIndex: Int           // 0-79
    let weekOfYear: Int          // 1-52
    let startDate: Date
    let endDate: Date
    let isLived: Bool
    var mood: String?            // Optional
    var note: String?            // Optional
}
```

#### Grid Calculation
```swift
func calculateLifeWeeks(birthDate: Date, lifeExpectancy: Int) -> [LifeWeek] {
    // Total weeks = lifeExpectancy * 52
    // For each week:
    //   - Calculate start/end dates
    //   - Determine if lived (endDate < Date())
    //   - Assign weekIndex, yearIndex, weekOfYear
}
```

#### Performance Requirements
- **Initial Load**: <500ms to render grid
- **Scroll Performance**: 60fps smooth scrolling
- **Memory**: <50MB for grid data

#### UI Components
1. **LifeGridView**: Main container (ScrollView + LazyVGrid)
2. **LifeGridCell**: Individual cell component
3. **LifeGridTooltip**: Cell detail tooltip
4. **LifeGridLegend**: Color legend (lived/remaining/current)

#### Styling
- **Cell Size**: 4px × 4px (mobile), 6px × 6px (tablet)
- **Cell Gap**: 2px
- **Grid Padding**: 16px all sides
- **Scroll Direction**: Vertical

---

## Feature 2: The Clock (Countdown)

### Overview
**Priority**: P0 (Core Feature)  
**Effort**: 1 week  
**Dependencies**: User birth date

### User Stories

#### US 2.1: View Countdown
> "As a user, I want to see a real-time countdown of my remaining time so that I feel urgency to live intentionally."

**Acceptance Criteria**:
- GIVEN I have entered my birth date
- WHEN I view the Clock screen
- THEN I see:
  - Days remaining (large number)
  - Hours, minutes, seconds (smaller)
  - Motivational message
- AND countdown updates every second

#### US 2.2: Toggle Countdown Visibility
> "As a user, I want to hide the countdown if I find it stressful so that I can use the app comfortably."

**Acceptance Criteria**:
- GIVEN I am in settings
- WHEN I toggle "Show Countdown" OFF
- THEN the Clock screen shows alternative content:
  - "Focus on today" message
  - Current date/time
  - Inspirational quote

### Technical Specifications

#### Countdown Algorithm
```swift
func calculateCountdown(birthDate: Date, lifeExpectancy: Int) -> CountdownResult {
    let endOfLife = Calendar.current.date(
        byAdding: .year, 
        value: lifeExpectancy, 
        to: birthDate
    )!
    
    let components = Calendar.current.dateComponents(
        [.day, .hour, .minute, .second],
        from: Date(),
        to: endOfLife
    )
    
    return CountdownResult(
        days: max(0, components.day ?? 0),
        hours: max(0, components.hour ?? 0),
        minutes: max(0, components.minute ?? 0),
        seconds: max(0, components.second ?? 0)
    )
}
```

#### Performance Requirements
- **Update Frequency**: 1 second
- **Battery Impact**: Minimal (use Timer, not DispatchQueue)
- **Accuracy**: ±1 second

#### UI Components
1. **CountdownView**: Main container
2. **CountdownNumberView**: Large number display
3. **CountdownLabelView**: Time unit labels
4. **MotivationalMessageView**: Dynamic messages

#### Styling
- **Number Size**: 64px (display font)
- **Label Size**: 14px (UI font)
- **Message Size**: 16px (body font)
- **Alignment**: Center

#### Motivational Messages (Rotation)
1. "You have X days left to create memories"
2. "Make them count"
3. "Every week is a gift"
4. "Live intentionally"
5. "Your time is now"

---

## Feature 3: Habit +/- (Daily Quality Tracker)

### Overview
**Priority**: P1 (Core Feature)  
**Effort**: 1 week  
**Dependencies**: None

### User Stories

#### US 3.1: Track Daily Quality
> "As a user, I want to quickly mark my day as good or bad so that I build self-awareness over time."

**Acceptance Criteria**:
- GIVEN it is a new day
- WHEN I open the Habit screen
- THEN I see two large buttons: (+) and (-)
- WHEN I tap (+)
- THEN my day is recorded as positive
- AND the button changes to green
- AND I see a confirmation message

#### US 3.2: View Weekly Trend
> "As a user, I want to see my last 7 days so that I understand patterns in my wellbeing."

**Acceptance Criteria**:
- GIVEN I have tracked at least 7 days
- WHEN I view the Habit screen
- THEN I see a 7-day visual:
  - Each day as a colored dot
  - Green = positive, Orange = negative, Gray = no data
- AND I see streak information:
  - Current streak (consecutive + days)
  - Longest streak

#### US 3.3: View Monthly Summary
> "As a user, I want to see my monthly statistics so that I reflect on overall trends."

**Acceptance Criteria**:
- GIVEN I have tracked at least 30 days
- WHEN I view the Monthly Summary
- THEN I see:
  - Total positive days
  - Total negative days
  - Percentage positive
  - Best streak
  - Trend direction (improving/declining/stable)

### Technical Specifications

#### Data Model
```swift
struct HabitEntry {
    let id: UUID
    let date: Date
    let isPositive: Bool
    let createdAt: Date
    var note: String?
}

struct HabitStreak {
    let currentStreak: Int
    let longestStreak: Int
    let totalPositiveDays: Int
    let totalNegativeDays: Int
    let lastWeekTrend: TrendDirection
}

enum TrendDirection {
    case improving    // +10% vs previous week
    case declining    // -10% vs previous week
    case stable       // within ±10%
}
```

#### Streak Calculation
```swift
func calculateStreak(entries: [HabitEntry]) -> HabitStreak {
    // Sort entries by date (newest first)
    // Find current streak (consecutive + days from today)
    // Find longest streak in history
    // Calculate totals
    // Compare last 7 days vs previous 7 days for trend
}
```

#### Performance Requirements
- **Save Entry**: <100ms
- **Load History**: <300ms for 365 days
- **Streak Calculation**: <50ms

#### UI Components
1. **HabitButtonView**: (+) and (-) buttons
2. **HabitStreakView**: Streak display
3. **HabitWeekView**: 7-day visualization
4. **HabitMonthView**: Monthly statistics

#### Styling
- **Button Size**: 48px × 48px
- **Button Radius**: 12px
- **Button Gap**: 16px
- **Active Button**: Scale 1.05 on tap

---

## Feature 4: Gratitude Journal

### Overview
**Priority**: P1 (Core Feature)  
**Effort**: 1 week  
**Dependencies**: None

### User Stories

#### US 4.1: Write Gratitude Entry
> "As a user, I want to write a short daily gratitude note so that I cultivate appreciation."

**Acceptance Criteria**:
- GIVEN it is a new day
- WHEN I open the Gratitude screen
- THEN I see a text input field
- AND I see optional prompts
- WHEN I type my entry and save
- THEN my entry is date-stamped
- AND I see a confirmation

#### US 4.2: Use Writing Prompts
> "As a user, I want to choose from prompts so that I overcome writer's block."

**Acceptance Criteria**:
- GIVEN I am writing a new entry
- WHEN I tap "Choose Prompt"
- THEN I see prompt options:
  - "Today I'm grateful for..."
  - "A small joy I noticed..."
  - "I want to remember this moment..."
  - "Someone I appreciate today..."
  - "Something I learned..."
- WHEN I select a prompt
- THEN it appears as a placeholder in the text field

#### US 4.3: Browse Past Entries
> "As a user, I want to read past entries so that I reflect on my journey."

**Acceptance Criteria**:
- GIVEN I have written entries
- WHEN I open the Gratitude History
- THEN I see entries sorted by date (newest first)
- AND each entry shows:
  - Date
  - Prompt (if used)
  - Content (preview, tap to expand)
- WHEN I tap an entry
- THEN I see the full content

#### US 4.4: Random Memory Recall
> "As a user, I want to see a random past entry so that I rediscover forgotten moments."

**Acceptance Criteria**:
- GIVEN I have written entries
- WHEN I tap "Random Memory"
- THEN I see a random past entry
- AND I see its original date
- AND I can tap "Another Memory" for a new random entry

### Technical Specifications

#### Data Model
```swift
struct GratitudeEntry {
    let id: UUID
    let date: Date
    let content: String
    var promptType: String?
    let createdAt: Date
    var updatedAt: Date
}

enum GratitudePrompt: String, CaseIterable {
    case today = "Today I'm grateful for..."
    case smallJoy = "A small joy I noticed..."
    case moment = "I want to remember this moment..."
    case person = "Someone I appreciate today..."
    case growth = "Something I learned..."
}
```

#### Validation
- **Content Length**: Min 10 chars, Max 500 chars
- **One Entry Per Day**: Enforce single entry per date
- **Auto-save**: Save draft every 30 seconds while editing

#### Performance Requirements
- **Save Entry**: <100ms
- **Load History**: <500ms for 365 entries
- **Random Recall**: <50ms

#### UI Components
1. **GratitudeEditorView**: Text input area
2. **PromptChipView**: Prompt selection chips
3. **GratitudeListView**: Entry history
4. **GratitudeDetailView**: Full entry view
5. **RandomMemoryView**: Random recall modal

#### Styling
- **Input Height**: 120px minimum
- **Input Padding**: 16px
- **Prompt Chips**: Horizontal scroll, wrap allowed
- **Entry Preview**: 3 lines max, tap to expand

---

## Cross-Cutting Concerns

### Accessibility (All Features)
- [ ] VoiceOver support for all interactive elements
- [ ] Dynamic Type support (text scaling)
- [ ] Reduce Motion support (simplify animations)
- [ ] High Contrast Mode support
- [ ] Minimum tap target: 44px × 44px

### Error Handling (All Features)
- [ ] Network errors (cloud sync failures)
- [ ] Data validation errors (invalid dates, empty fields)
- [ ] Permission errors (notifications, iCloud)
- [ ] User-friendly error messages
- [ ] Retry mechanisms

### Analytics (All Features)
- [ ] Track feature usage (opt-in only)
- [ ] Track engagement metrics
- [ **NO** external tracking (privacy-first)
- [ ] Local analytics only
- [ ] User can export their data

### Localization (All Features)
- [ ] English (US) - primary
- [ ] Traditional Chinese (zh-Hant) - secondary
- [ ] Japanese (ja) - future
- [ ] Date/number formatting per locale
- [ ] RTL language support (future)

---

## Testing Requirements

### Unit Tests
- [ ] LifeCalculator algorithms (100% coverage)
- [ ] Streak calculations (100% coverage)
- [ ] Date formatting (100% coverage)
- [ ] Data validation (100% coverage)

### Integration Tests
- [ ] CoreData CRUD operations
- [ ] CloudKit sync scenarios
- [ ] Navigation flows
- [ ] Error handling flows

### UI Tests
- [ ] Onboarding flow
- [ ] Life Grid interaction
- [ ] Habit tracking flow
- [ ] Gratitude writing flow

### Performance Tests
- [ ] Grid rendering (target: <500ms)
- [ ] Countdown updates (target: 1s interval)
- [ ] List scrolling (target: 60fps)
- [ ] Memory usage (target: <100MB total)

### Accessibility Tests
- [ ] VoiceOver navigation
- [ ] Dynamic Type scaling
- [ ] Color contrast ratios
- [ ] Keyboard navigation

---

## Implementation Priority

### Sprint 1 (Week 1-2): Foundation
- [ ] Design tokens implementation
- [ ] CoreData models
- [ ] Basic navigation
- [ ] Life Grid View (basic)

### Sprint 2 (Week 3-4): Core Features
- [ ] Life Grid (complete)
- [ ] The Clock (countdown)
- [ ] Habit +/- (basic tracking)

### Sprint 3 (Week 5-6): Polish
- [ ] Habit +/- (trends, streaks)
- [ ] Gratitude Journal (complete)
- [ ] Cloud sync
- [ ] UI polish

### Sprint 4 (Week 7-8): Testing & Launch
- [ ] Testing (all types)
- [ ] Bug fixes
- [ ] Performance optimization
- [ ] App Store submission

---

**Feature Specification Status**: ✅ COMPLETE  
**Ready for**: Phoenix implementation  
**Review Date**: 2026-03-05

---

_Created by Flare (Design Agent) — Mori Feature Specification v1.0_
