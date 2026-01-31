# Mori App - Quick Reference Card

## 🚀 Quick Start

```bash
# Clone and open in Xcode
git clone https://github.com/metta-man/mori.git
cd mori/Mori
open Mori.xcodeproj
# Press ⌘R to build and run
```

## 📱 Features at a Glance

| Feature | Description | Implementation |
|---------|-------------|----------------|
| **Death Clock** | Remaining days countdown | DateComponents, life expectancy: 85 years |
| **Life Grid** | 80×52 week visualization | Gray (lived) / Blue (remaining) |
| **Habits** | +/- time tracking | ±10 minutes per tap |
| **Gratitude** | Daily journal | SwiftData auto-save |

## 🎨 Color Palette

```swift
Background:      .black              // #000000
Primary Text:    .white              // #FFFFFF
Secondary:       .gray               // #808080
Lived Weeks:     .gray               // #808080
Future Weeks:    .blue               // #007AFF
Positive:        .green              // #34C759
Negative:        .red                // #FF3B30
```

## 📊 Grid Calculations

```
Total Squares:  80 years × 52 weeks = 4,160 squares
Square Size:    4×4 points
Grid Spacing:   1 point
Component:      LazyVGrid (efficient rendering)
```

## 🔧 Key State Variables

```swift
@State var birthDate: Date           // User's birth date
@State var todaysBonus: Int = 0      // Habit time tracker
@State var gratitudeText: String     // Current entry
@State var habits: [String]          // Habit list
```

## 💾 Data Model

```swift
@Model
class GratitudeEntry {
    var date: Date    // Entry date
    var text: String  // Entry content
}
```

## 🎯 Computed Properties

```swift
remainingDays: Int
// Calculates: (85 - currentAge) in days
// Uses: Calendar.dateComponents
```

## 📐 Layout Structure

```
ScrollView
  └── VStack(spacing: 30)
       ├── deathClockSection
       ├── lifeGridSection
       ├── habitTrackingSection
       └── gratitudeDiarySection
```

## ⚙️ Requirements

- **iOS**: 17.0+
- **Xcode**: 15.0+
- **Swift**: 5.9+
- **Frameworks**: SwiftUI, SwiftData, Foundation

## 🔄 Data Persistence

```
User types → onChange → saveTodaysGratitude()
                     ↓
           Check if entry exists
                     ↓
           Update or create new
                     ↓
           modelContext.save()
                     ↓
           SwiftData persists
```

## 🎛️ Customization Points

**Birth Date** (line 8 in ContentView.swift):
```swift
@State private var birthDate = Calendar.current.date(
    from: DateComponents(year: 1990, month: 1, day: 1)
) ?? Date()
```

**Life Expectancy** (in remainingDays computed property):
```swift
let lifeExpectancy = 85  // Change this
```

**Habits** (line 11 in ContentView.swift):
```swift
@State private var habits = ["Exercise", "Read", "Meditate"]
```

**Time Increment** (in button actions):
```swift
todaysBonus += 10  // Change this
todaysBonus -= 10  // Change this
```

## 📖 Documentation Files

| File | Purpose |
|------|---------|
| `README.md` | Project overview |
| `USAGE.md` | Installation & usage guide |
| `TECHNICAL.md` | Architecture details |
| `UI_DESIGN.md` | Visual mockups |
| `IMPLEMENTATION_SUMMARY.md` | Complete checklist |

## 🧪 Testing Checklist

- [ ] Death clock shows correct days
- [ ] Life grid renders 4,160 squares
- [ ] Gray/blue colors match lived/remaining
- [ ] Habit +/- updates bonus counter
- [ ] Gratitude text saves and persists
- [ ] App reopens with saved data
- [ ] UI is dark mode throughout
- [ ] Text has high contrast

## 📞 Key Functions

```swift
loadTodaysGratitude()      // Loads entry on app launch
saveTodaysGratitude(text)  // Saves/updates entry
isWeekLived(weekNumber)    // Checks if week has passed
```

## 🎨 Typography Scale

```
72pt Bold    → Death clock number
Headline     → Section titles
Default      → Body text
Title3 Bold  → Bonus counter
Caption      → Timestamps
```

## ⚡ Performance Features

- **Lazy Loading**: LazyVGrid for 4000+ squares
- **Reactive UI**: @Query auto-updates
- **Efficient Calcs**: Computed properties cached
- **Single Pass**: One calculation per render

## 🔐 Security & Quality

✅ Swift syntax validated  
✅ Code review passed  
✅ No security vulnerabilities  
✅ Proper error handling  
✅ SwiftData persistence  

---

**Built with SwiftUI + SwiftData**  
*Memento Mori - Remember you will die*
