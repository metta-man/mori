# Mori - Life Expectancy SwiftUI App

Life is finite. Mori turns your "Life Expectancy" into a visual journey.

## Features

### 🕐 Death Clock
- Calculates remaining days based on life expectancy of 85 years
- Large countdown display showing days remaining
- Real-time countdown based on your birth date

### 📊 Life in Squares
- 80×52 grid visualization (80 years × 52 weeks)
- Gray squares represent weeks you've lived
- Blue squares represent weeks remaining
- Visual representation of your entire life journey

### ✅ Habit Tracking
- Simple list of habits with +/- buttons
- Each habit can add (+) or subtract (-) 10 minutes
- "Today's Bonus" counter tracks total time impact
- Green for positive, red for negative balance

### 🙏 Gratitude Diary
- Simple text editor for daily gratitude entry
- Automatically saves entries using SwiftData
- One entry per day
- Shows last saved timestamp

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Project Structure

```
Mori/
├── Mori.xcodeproj/
│   └── project.pbxproj          # Xcode project file
├── Assets.xcassets/             # App icons and colors
├── MoriApp.swift                # App entry point with SwiftData setup
├── DataModel.swift              # SwiftData model for GratitudeEntry
└── ContentView.swift            # Main UI with all features
```

## Installation & Building

1. Clone the repository:
   ```bash
   git clone https://github.com/metta-man/mori.git
   cd mori
   ```

2. Open the project in Xcode:
   ```bash
   cd Mori
   open Mori.xcodeproj
   ```

3. Select your target device (iPhone simulator or physical device)

4. Build and run the project (⌘R)

## Usage

### Setting Your Birth Date
By default, the birth date is set to January 1, 1990. To customize:
- Edit the `birthDate` state variable in `ContentView.swift`
- Set your actual birth date to get accurate calculations

### Managing Habits
- Tap the **+** button to add 10 minutes to your daily bonus
- Tap the **-** button to subtract 10 minutes
- The "Today's Bonus" counter shows your total impact
- Default habits: Exercise, Read, Meditate

### Writing Gratitude
- Tap into the text editor under "Today's Gratitude"
- Type your daily gratitude entry
- Entries are automatically saved using SwiftData
- One entry per day (overwrites if you edit multiple times)

## UI Design

The app follows a **minimalist, high-contrast dark mode** design:
- **Background**: Pure black (#000000)
- **Text**: White for primary content, gray for secondary
- **Accent Colors**: 
  - Gray for lived life squares
  - Blue for remaining life squares
  - Green for positive habits
  - Red for negative habits
- **Layout**: Vertical scrollable layout with distinct sections

## Technical Implementation

### Death Clock Calculation
```swift
- Uses DateComponents to calculate age from birth date
- Subtracts current age from life expectancy (85 years)
- Calculates remaining days using Calendar API
```

### Life Grid
```swift
- 80 rows × 52 columns = 4,160 total squares
- LazyVGrid for performance with large number of squares
- Calculates each week from birth date
- Compares to current date to determine fill color
```

### SwiftData Integration
```swift
- GratitudeEntry model with @Model macro
- ModelContainer setup in MoriApp
- Query with date sorting
- Automatic persistence to disk
```

## Customization

### Change Life Expectancy
Edit the `remainingDays` computed property in ContentView:
```swift
let lifeExpectancy = 85  // Change this value
```

### Modify Habit Time Increments
Change the increment value in button actions:
```swift
todaysBonus += 10  // Change 10 to your preferred value
```

### Add More Habits
Edit the `habits` state array:
```swift
@State private var habits: [String] = ["Exercise", "Read", "Meditate", "Your Habit"]
```

## License

This project is open source and available for personal use.

## Philosophy

> "Memento Mori" - Remember that you will die.

Mori is designed to help you visualize the finite nature of life, encouraging mindful living and gratitude for each day.

---

**Don't just count time. Make time count.**
