# Mori - Habit +/- (Daily Quality Tracker) UI Mockup

**Feature**: Habit +/- - Daily Quality Tracking  
**Screen**: Main Habit Tracker View  
**Designer**: Flare  
**Date**: 2026-03-05

---

## 🎨 Visual Layout

### Screen Overview

```
┌─────────────────────────────────────────┐
│  ← Mori                            ⚙️   │ ← Top Nav (56px)
├─────────────────────────────────────────┤
│                                         │
│         How was your day?               │ ← Title (36px, Cormorant)
│                                         │
│  ┌──────────┐         ┌──────────┐     │
│  │          │         │          │     │
│  │     +    │         │     -    │     │ ← Habit Buttons (48×48px)
│  │          │         │          │     │
│  └──────────┘         └──────────┘     │
│   Good day             Bad day          │
│                                         │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │  Current Streak: 7 days  🔥        │ │ ← Streak Card
│  │  Longest Streak: 23 days           │ │
│  └────────────────────────────────────┘ │
│                                         │
│         Last 7 Days                     │
│                                         │
│    ●  ●  ○  ●  ●  ●  ○                  │ ← 7-day visual
│   M  T  W  T  F  S  S                   │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │  📊 March 2026                     │ │ ← Monthly Stats
│  │  ────────────────────────          │ │
│  │  Good days: 18 (64%)               │ │
│  │  Bad days: 10 (36%)                │ │
│  │  Best streak: 7 days               │ │
│  │  Trend: ↑ Improving                │ │
│  └────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

---

## 📐 Component Specifications

### Page Title

```swift
TitleSection {
    padding: 32px 24px 24px 24px
    textAlign: center
}

titleText {
    text: "How was your day?"
    font: "Cormorant Garamond", 36px, Regular
    color: #333333
    letterSpacing: 0.5px
}
```

### Habit Toggle Buttons

```swift
HabitButtonsView {
    display: flex
    justifyContent: center
    gap: 48px
    marginTop: 32px
    marginBottom: 48px
}

HabitButton {
    width: 48px
    height: 48px
    borderRadius: 12px
    border: 2px solid
    backgroundColor: white
    fontSize: 28px
    display: flex
    alignItems: center
    justifyContent: center
    cursor: pointer
    transition: all 0.2s ease
}

/* Positive Button */
HabitButton.positive {
    borderColor: #788c5d (Sage Green)
    color: #788c5d
}

HabitButton.positive:hover {
    backgroundColor: #F0F5EB (light sage)
    transform: scale(1.05)
}

HabitButton.positive.selected {
    backgroundColor: #788c5d
    color: white
    transform: scale(1.05)
    boxShadow: 0 4px 16px rgba(120, 140, 93, 0.3)
}

/* Negative Button */
HabitButton.negative {
    borderColor: #FF6B35 (Ember Orange)
    color: #FF6B35
}

HabitButton.negative:hover {
    backgroundColor: #FFF5F0
    transform: scale(1.05)
}

HabitButton.negative.selected {
    backgroundColor: #FF6B35
    color: white
    transform: scale(1.05)
    boxShadow: 0 4px 16px rgba(255, 107, 53, 0.3)
}

/* Button Labels */
buttonLabel {
    font: "Poppins", 12px, Medium
    color: #666666
    textAlign: center
    marginTop: 12px
}
```

### Streak Card

```swift
StreakCard {
    backgroundColor: white
    borderRadius: 16px
    padding: 24px
    margin: 0 24px 32px 24px
    boxShadow: 0 2px 8px rgba(0, 0, 0, 0.05)
    border: 1px solid #E8E8E8
}

streakRow {
    display: flex
    justifyContent: space-between
    alignItems: center
    marginBottom: 12px
}

currentStreak {
    font: "Poppins", 14px, Medium
    color: #333333
}

streakNumber {
    font: "Cormorant Garamond", 24px, SemiBold
    color: #D4AF37
}

streakFlame {
    fontSize: 24px
}

longestStreak {
    font: "Poppins", 12px, Regular
    color: #888888
}
```

### 7-Day Visualization

```swift
WeekVisualization {
    padding: 24px
    textAlign: center
}

weekTitle {
    font: "Poppins", 14px, Medium
    color: #666666
    marginBottom: 16px
}

weekDots {
    display: flex
    justifyContent: center
    gap: 12px
    marginBottom: 8px
}

DayDot {
    width: 24px
    height: 24px
    borderRadius: 50%
    display: flex
    alignItems: center
    justifyContent: center
}

DayDot.positive {
    backgroundColor: #788c5d
}

DayDot.negative {
    backgroundColor: #FF6B35
}

DayDot.neutral {
    backgroundColor: #E8E8E8
}

DayDot.today {
    border: 2px solid #D4AF37
    animation: pulse 2s infinite
}

dayLabels {
    display: flex
    justifyContent: center
    gap: 12px
}

dayLabel {
    font: "Poppins", 10px, Regular
    color: #AAAAAA
    width: 24px
    textAlign: center
}
```

### Monthly Statistics Card

```swift
MonthlyStatsCard {
    backgroundColor: white
    borderRadius: 16px
    padding: 24px
    margin: 32px 24px 48px 24px
    boxShadow: 0 2px 8px rgba(0, 0, 0, 0.05)
    border: 1px solid #E8E8E8
}

cardHeader {
    display: flex
    alignItems: center
    marginBottom: 16px
}

headerIcon {
    fontSize: 20px
    marginRight: 8px
}

headerTitle {
    font: "Poppins", 14px, SemiBold
    color: #333333
}

divider {
    height: 1px
    backgroundColor: #E8E8E8
    marginBottom: 16px
}

statRow {
    display: flex
    justifyContent: space-between
    alignItems: center
    marginBottom: 12px
}

statLabel {
    font: "Poppins", 14px, Regular
    color: #666666
}

statValue {
    font: "Poppins", 14px, SemiBold
    color: #333333
}

statValue.positive {
    color: #788c5d
}

statValue.negative {
    color: #FF6B35
}

trendIndicator {
    display: flex
    alignItems: center
    gap: 4px
}

trendArrow {
    color: #788c5d (improving)
    or: #FF6B35 (declining)
    or: #888888 (stable)
}
```

---

## 🎭 Interaction States

### Initial Load

```
1. Check if today already tracked
2. If yes: Show selected button
3. If no: Both buttons unselected
4. Load streak and weekly data
5. Animate dots appearance (fade in)
```

### Selecting a Button

```
1. User taps + or - button
2. Haptic feedback (light)
3. Button scales to 1.05
4. Background fills with color
5. Text changes to white
6. Other button deselects (if previously selected)
7. Save to database
8. Update streak counter
9. Update 7-day visualization
10. Update monthly stats
11. Show confirmation toast
```

### Confirmation Toast

```swift
ConfirmationToast {
    backgroundColor: #333333
    color: white
    padding: 12px 24px
    borderRadius: 8px
    position: bottom
    animation: slideUp 0.3s ease
    duration: 2000ms
}

message: "Day recorded as good" or "Day recorded as bad"
```

### Changing Selection

```
1. User taps opposite button
2. Previous selection clears
3. New selection highlights
4. Update database (overwrite today's entry)
5. Recalculate streak
6. Update all stats
```

---

## 🎨 Visual Effects

### Button Hover Animation

```css
.habit-btn:hover {
    transform: scale(1.05);
    transition: all 0.2s ease;
}
```

### Button Selection Animation

```css
@keyframes buttonSelect {
    0% {
        transform: scale(1);
    }
    50% {
        transform: scale(1.1);
    }
    100% {
        transform: scale(1.05);
    }
}
```

### Streak Counter Animation

```css
@keyframes countUp {
    from {
        opacity: 0;
        transform: translateY(10px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}
```

### Dot Appearance Animation

```css
.week-dot {
    opacity: 0;
    animation: fadeIn 0.3s ease forwards;
}

.week-dot:nth-child(1) { animation-delay: 0s; }
.week-dot:nth-child(2) { animation-delay: 0.05s; }
.week-dot:nth-child(3) { animation-delay: 0.1s; }
/* ... staggered for each dot */
```

---

## 📱 Responsive Behavior

### Mobile (< 768px)

```
- Button gap: 32px (smaller)
- Streak card: full width
- Weekly dots: gap 8px
- Stats card: full width
- Vertical layout for stat rows
```

### Tablet (768px - 1024px)

```
- Button gap: 48px
- Cards: 90% width, centered
- Horizontal stat rows
- Side padding: 32px
```

### Desktop (> 1024px)

```
- Button gap: 64px
- Cards: max-width 400px, centered
- Hover effects enabled
- Keyboard shortcuts (+/- keys)
```

---

## 🎨 Color Tokens Used

```css
/* Buttons */
--btn-positive: #788c5d
--btn-positive-bg: #F0F5EB
--btn-negative: #FF6B35
--btn-negative-bg: #FFF5F0

/* Dots */
--dot-positive: #788c5d
--dot-negative: #FF6B35
--dot-neutral: #E8E8E8

/* Text */
--text-primary: #333333
--text-secondary: #666666
--text-tertiary: #888888

/* Backgrounds */
--bg-card: white
--bg-primary: #FDF5E6

/* Accent */
--accent-gold: #D4AF37
```

---

## ✅ Accessibility

### VoiceOver Labels

```
- Positive button: "Mark day as good"
- Negative button: "Mark day as bad"
- Streak: "Current streak: 7 days"
- Day dot: "Monday, good day"
- Stats: "Monthly statistics: 64% good days"
```

### Color Independence

```
- Use icons (+/-) in addition to color
- Pattern fills for colorblind users
- Clear labels for all elements
```

### Tap Targets

```
- Buttons: 48×48px minimum
- Dots: 24×24px minimum
- All interactive elements accessible
```

---

## 📊 Data Requirements

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

struct MonthlyStats {
    let month: Date
    let positiveDays: Int
    let negativeDays: Int
    let percentage: Double
    let bestStreak: Int
    let trend: TrendDirection
}

enum TrendDirection {
    case improving    // +10% vs previous week
    case declining    // -10% vs previous week
    case stable       // within ±10%
}
```

---

## 🚀 Implementation Notes

### SwiftUI Components

```swift
struct HabitScreen: View {
    @State private var todayEntry: HabitEntry?
    @State private var streak: HabitStreak
    @State private var weeklyData: [HabitEntry]
    @State private var monthlyStats: MonthlyStats
    
    var body: some View {
        ScrollView {
            VStack {
                TitleSection()
                HabitButtons(selected: $todayEntry)
                StreakCard(streak: streak)
                WeekVisualization(data: weeklyData)
                MonthlyStatsCard(stats: monthlyStats)
            }
        }
        .background(Color("ZenCream"))
        .onAppear {
            loadData()
        }
    }
}

struct HabitButtons: View {
    @Binding var selected: HabitEntry?
    
    var body: some View {
        HStack(spacing: 48) {
            HabitButton(type: .positive, isSelected: selected?.isPositive == true) {
                selectEntry(isPositive: true)
            }
            
            HabitButton(type: .negative, isSelected: selected?.isPositive == false) {
                selectEntry(isPositive: false)
            }
        }
    }
    
    func selectEntry(isPositive: Bool) {
        // Save to database
        // Update streak
        // Haptic feedback
        // Show toast
    }
}
```

---

## 🖼️ Visual Preview

### Initial State

```
Centered title "How was your day?"
Two large buttons (+ and -)
White streak card below
7 dots representing last week
Monthly stats card at bottom
Cream background
```

### After Selection (Positive)

```
+ button filled with Sage Green
- button unselected (white)
Streak counter animates up (+1)
Today's dot turns green
Toast: "Day recorded as good"
Stats update (64% → 68%)
```

### Streak Achievement

```
When streak reaches milestones:
- 7 days: 🔥 Fire emoji appears
- 14 days: 🔥🔥 Double fire
- 21 days: 🔥🔥🔥 Triple fire
- 30 days: 🏆 Trophy + celebration
```

---

## 💡 Microcopy Examples

### Empty State

```
"Start tracking your daily quality
Tap + for good days, - for bad days
Build self-awareness over time"
```

### Streak Encouragement

```
Current streak: 7 days
"You're on a roll! Keep it up! 🔥"

Longest streak: 23 days
"Your record is 23 days. Can you beat it?"
```

### Trend Messages

```
Improving (↑): "You're doing better than last week! 👏"
Declining (↓): "This week has been tough. Tomorrow is a new day. 💪"
Stable (→): "Consistent progress. Stay steady. 🎯"
```

---

**Mockup Status**: ✅ COMPLETE  
**Ready for**: Phoenix Implementation  
**Design File**: SVG exports to be created separately

---

_Created by Flare — Mori Habit Tracker Screen v1.0_
