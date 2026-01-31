# Mori App - Technical Documentation

## Architecture Overview

### SwiftUI + SwiftData Stack

```
┌─────────────────────────────────────┐
│         MoriApp.swift               │
│  @main entry point                  │
│  - ModelContainer setup             │
│  - SwiftData schema                 │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│       ContentView.swift             │
│  Main UI View                       │
│  - @Environment(\.modelContext)     │
│  - @Query for gratitude entries     │
│  - @State for UI state              │
└─────────────────────────────────────┘
             │
             ├──────────────┐
             │              │
             ▼              ▼
┌──────────────────┐  ┌──────────────┐
│ DataModel.swift  │  │  LifeGrid    │
│                  │  │  View        │
│ GratitudeEntry   │  │  Component   │
│ @Model class     │  └──────────────┘
└──────────────────┘
```

## Data Flow

### Gratitude Entry Persistence

```
User Types Text
     │
     ▼
onChange(of: gratitudeText)
     │
     ▼
saveTodaysGratitude()
     │
     ├──> Check if entry exists for today
     │    │
     │    ├──> YES: Update existing entry
     │    │
     │    └──> NO: Create new entry
     │
     ▼
modelContext.save()
     │
     ▼
SwiftData persists to disk
```

### Life Grid Calculation

```
Birth Date Input
     │
     ▼
For each square (0 to 4,159)
     │
     ├──> Calculate week number
     │
     ├──> Add weeks to birth date
     │
     ├──> Compare to current date
     │
     └──> Set color (gray if past, blue if future)
```

## UI Component Breakdown

### ContentView Structure

```
ScrollView
  └── VStack (spacing: 30)
       ├── Death Clock Section
       │    ├── "Time Remaining" label
       │    ├── Large countdown number
       │    └── "days" label
       │
       ├── Life Grid Section  
       │    ├── "Life in Squares" title
       │    ├── "80 years × 52 weeks" subtitle
       │    └── LifeGrid component
       │         └── LazyVGrid (52 columns × 80 rows)
       │
       ├── Habit Tracking Section
       │    ├── "Habit Tracking" title
       │    ├── ForEach habit list
       │    │    └── HStack (habit name, -, +)
       │    ├── Divider
       │    └── "Today's Bonus" counter
       │
       └── Gratitude Diary Section
            ├── "Today's Gratitude" title
            ├── TextEditor
            └── "Last saved" timestamp
```

## State Management

### @State Variables

```swift
@State private var birthDate: Date
// User's birth date for calculations

@State private var todaysBonus: Int = 0
// Accumulated habit time in minutes

@State private var gratitudeText: String = ""
// Current gratitude entry text

@State private var habits: [String]
// List of tracked habits
```

### @Query

```swift
@Query(sort: \GratitudeEntry.date, order: .reverse) 
private var gratitudeEntries: [GratitudeEntry]
// Auto-updating list of all gratitude entries
// Sorted by date, newest first
```

## Color Scheme

### Dark Mode Palette

```
┌────────────────────────────┐
│ Background: .black         │  #000000
│ Primary Text: .white       │  #FFFFFF
│ Secondary Text: .gray      │  #808080
│ Section BG: .gray(0.1)     │  rgba(128,128,128,0.1)
│ Lived Squares: .gray       │  #808080
│ Future Squares: .blue      │  #007AFF
│ Positive: .green           │  #34C759
│ Negative: .red             │  #FF3B30
└────────────────────────────┘
```

## Performance Optimizations

### LazyVGrid Usage
- Loads squares on-demand as they come into view
- Reduces memory footprint for 4,160 squares
- Smooth scrolling performance

### Query Efficiency
- SwiftData @Query automatically updates view
- No manual refresh needed
- Sorted at database level

### Date Calculations
- Cached computed properties
- Calendar operations use efficient DateComponents
- Single calculation per render cycle

## Future Enhancements

Potential features that could be added:
- [ ] User-configurable birth date picker in UI
- [ ] Customizable life expectancy setting
- [ ] Export gratitude entries
- [ ] Habit statistics and trends
- [ ] Widget support for iOS home screen
- [ ] Apple Watch companion app
- [ ] Dark/Light mode toggle (currently dark only)
- [ ] Localization support
- [ ] Cloud sync via iCloud
- [ ] Reminder notifications

## Testing Checklist

When testing on a physical device or simulator:

- [ ] Death clock shows correct remaining days
- [ ] Life grid squares match expected fill pattern
- [ ] Habit +/- buttons update Today's Bonus
- [ ] Gratitude text saves and persists
- [ ] App reopens with saved gratitude entry
- [ ] UI renders correctly in portrait mode
- [ ] Scrolling is smooth with no lag
- [ ] Dark mode styling is consistent
- [ ] Text is readable with high contrast

## Build Configuration

### Minimum Deployment
- **iOS**: 17.0
- **Xcode**: 15.0
- **Swift**: 5.9

### Frameworks Used
- SwiftUI (UI framework)
- SwiftData (persistence)
- Foundation (date calculations)

### Bundle Identifier
`com.metta.Mori`

## Known Limitations

1. **Birth date is hardcoded** - Currently set in code, not via UI picker
2. **No data export** - Gratitude entries can't be exported
3. **Single user** - No multi-user support or profiles
4. **No widgets** - Home screen widgets not implemented
5. **Portrait only** - Not optimized for landscape orientation
6. **English only** - No localization support

---

*"Make time count."*
