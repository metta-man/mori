# Mori App - UI Mockup

```
┌─────────────────────────────────────────┐
│                                         │
│              MORI APP                   │
│         (Dark Mode, Black BG)           │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│        ┌─────────────────────┐         │
│        │  Time Remaining     │         │
│        │                     │         │
│        │      31,025         │  ← Large
│        │                     │    number
│        │       days          │         │
│        └─────────────────────┘         │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│        ┌─────────────────────┐         │
│        │ Life in Squares     │         │
│        │ 80 years × 52 weeks │         │
│        │                     │         │
│        │ ▓▓▓▓▓▓▓▓▓░░░░░░░░░ │         │
│        │ ▓▓▓▓▓▓▓▓▓░░░░░░░░░ │  ← Grid:
│        │ ▓▓▓▓▓▓▓▓▓░░░░░░░░░ │    ▓=gray
│        │ ▓▓▓▓▓▓▓▓▓░░░░░░░░░ │    ░=blue
│        │ ...  (80 rows)     │         │
│        │                     │         │
│        └─────────────────────┘         │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│        ┌─────────────────────┐         │
│        │  Habit Tracking     │         │
│        │                     │         │
│        │  Exercise    ⊖  ⊕   │         │
│        │  Read        ⊖  ⊕   │         │
│        │  Meditate    ⊖  ⊕   │         │
│        │  ─────────────────  │         │
│        │  Today's Bonus:     │         │
│        │         +30 mins    │  ← Green
│        │                     │    if +
│        └─────────────────────┘         │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│        ┌─────────────────────┐         │
│        │ Today's Gratitude   │         │
│        │                     │         │
│        │  ┌───────────────┐  │         │
│        │  │ I am grateful │  │  ← Text
│        │  │ for...        │  │    Editor
│        │  │               │  │         │
│        │  │               │  │         │
│        │  └───────────────┘  │         │
│        │                     │         │
│        │  Last saved: 2:34pm │         │
│        └─────────────────────┘         │
│                                         │
└─────────────────────────────────────────┘

Legend:
  ⊕ = Plus button (green)
  ⊖ = Minus button (red)
  ▓ = Gray square (lived weeks)
  ░ = Blue square (remaining weeks)
```

## Color Reference

### Section Backgrounds
All sections have a subtle gray background:
```
.background(Color.gray.opacity(0.1))
```

### Death Clock
- Title: White
- Number: White, 72pt bold
- Subtitle: Gray

### Life Grid
- Title: White
- Lived squares: Gray (#808080)
- Future squares: Blue (#007AFF)
- Each square: 4×4 points with 1pt spacing

### Habit Tracking
- Habit names: White
- Minus button: Red circle with minus icon
- Plus button: Green circle with plus icon
- Today's Bonus: Green (if positive) / Red (if negative)

### Gratitude Diary
- Title: White
- TextEditor background: Gray (0.2 opacity)
- Text: White
- Timestamp: Gray, small font

## Interaction Flow

```
┌────────────────┐
│ Launch App     │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Calculate      │
│ Remaining Days │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Render Life    │
│ Grid (4160 sq) │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Load Today's   │
│ Gratitude      │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Display UI     │
└────────────────┘


User Actions:
┌──────────────────────────────────┐
│                                  │
│  Tap + → Add 10 mins             │
│                                  │
│  Tap - → Subtract 10 mins        │
│                                  │
│  Type text → Auto-save entry     │
│                                  │
│  Scroll → View full grid         │
│                                  │
└──────────────────────────────────┘
```

## Responsive Layout

The app uses SwiftUI's adaptive layouts:

```
ScrollView
  └── VStack(spacing: 30)
       └── .padding()
            └── Sections expand to full width
                 └── .frame(maxWidth: .infinity)
```

Each section:
1. Expands to available width
2. Has consistent 30pt vertical spacing
3. Uses 12pt corner radius
4. Has padding around content

## Typography Hierarchy

```
┌──────────────────────────────────────┐
│ Level 1: Section Titles             │
│   .font(.headline)                   │
│   Color: .white                      │
│                                      │
│ Level 2: Large Numbers (Death Clock)│
│   .font(.system(size: 72, bold))     │
│   Color: .white                      │
│                                      │
│ Level 3: Body Text (Habits)         │
│   Default font                       │
│   Color: .white                      │
│                                      │
│ Level 4: Captions & Timestamps      │
│   .font(.caption)                    │
│   Color: .gray                       │
│                                      │
│ Level 5: Bonus Counter              │
│   .font(.title3, bold)               │
│   Color: .green or .red (dynamic)    │
└──────────────────────────────────────┘
```

## Animation Potential

Current implementation is static. Potential animations:
- Death clock countdown (live ticking)
- Grid squares flipping when week changes
- Habit buttons scale on tap
- Bonus counter increment animation
- Gratitude save confirmation fade

---

*This mockup represents the iOS 17+ SwiftUI implementation.*
