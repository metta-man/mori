# Mori - The Clock (Countdown) Screen UI Mockup

**Feature**: The Clock - Real-Time Countdown  
**Screen**: Main Countdown View  
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
│                                         │
│                                         │
│                                         │
│              15,482                     │ ← Days (64px, Cormorant)
│              days                       │
│                                         │
│         12  :  34  :  56                │ ← Time (36px, Poppins)
│        hours  min    sec                │
│                                         │
│                                         │
│   "You have time to create memories"    │ ← Message (18px, Crimson)
│                                         │
│                                         │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │  🔔 Remind me daily at 8:00 AM     │ │ ← Daily reminder toggle
│  └────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

---

## 📐 Component Specifications

### Page Layout

```swift
CountdownScreen {
    backgroundColor: #FDF5E6 (Zen Cream)
    padding: 0
    display: flex
    flexDirection: column
    justifyContent: center
    alignItems: center
    minHeight: 100vh
}
```

### Main Countdown Number

```swift
CountdownNumberView {
    textAlign: center
    marginBottom: 16px
}

daysNumber {
    text: "15,482" (dynamic)
    font: "Cormorant Garamond", 64px, Light
    color: #333333
    lineHeight: 1.1
    letterSpacing: -2px
    animation: subtleFade 1s ease on number change
}

daysLabel {
    text: "days"
    font: "Poppins", 14px, Regular
    color: #888888
    textTransform: uppercase
    letterSpacing: 2px
    marginTop: 8px
}
```

### Time Breakdown

```swift
TimeBreakdownView {
    display: flex
    justifyContent: center
    gap: 24px
    marginTop: 32px
}

timeUnit {
    textAlign: center
    minWidth: 80px
}

timeValue {
    font: "Poppins", 36px, Light
    color: #333333
    fontVariant: tabular-nums
}

timeLabel {
    font: "Poppins", 12px, Regular
    color: #AAAAAA
    textTransform: uppercase
    letterSpacing: 1px
    marginTop: 4px
}

separator {
    font: "Poppins", 36px, Light
    color: #E8E8E8
    animation: blink 1s infinite
}
```

### Motivational Message

```swift
MotivationalMessageView {
    marginTop: 48px
    padding: 0 24px
    textAlign: center
}

message {
    font: "Crimson Pro", 18px, Italic
    color: #666666
    lineHeight: 1.8
    maxWidth: 400px
}

/* Message rotation (change every 10 seconds) */
messages: [
    "You have time to create memories",
    "Make them count",
    "Every week is a gift",
    "Live intentionally",
    "Your time is now",
    "Cherish each moment",
    "Today is precious"
]
```

### Daily Reminder Toggle

```swift
ReminderCard {
    backgroundColor: white
    borderRadius: 16px
    padding: 20px 24px
    boxShadow: 0 2px 8px rgba(0, 0, 0, 0.05)
    marginTop: 64px
    maxWidth: 400px
    width: 90%
}

reminderRow {
    display: flex
    alignItems: center
    justifyContent: space-between
}

bellIcon {
    icon: "bell"
    size: 20px
    color: #D4AF37
    marginRight: 12px
}

reminderText {
    font: "Poppins", 14px, Medium
    color: #333333
    flex: 1
}

toggle {
    width: 48px
    height: 28px
    borderRadius: 14px
    backgroundColor: #E8E8E8 (off) or #D4AF37 (on)
    transition: 0.3s ease
}

toggleKnob {
    width: 24px
    height: 24px
    borderRadius: 50%
    backgroundColor: white
    boxShadow: 0 2px 4px rgba(0, 0, 0, 0.1)
}
```

---

## 🎭 Interaction States

### Real-Time Update

```
Every second:
1. Calculate time remaining
2. Update seconds value (fade animation)
3. If seconds reach 0, update minutes
4. If minutes reach 0, update hours
5. Colon separator blinks
```

### Toggle Reminder

```
1. User taps toggle
2. Haptic feedback
3. Toggle slides to on position
4. Background changes to Mori Gold
5. Notification permission request (if first time)
6. Confirmation toast: "Daily reminder set for 8:00 AM"
```

### Message Rotation

```
Every 10 seconds:
1. Current message fades out (opacity 1 → 0)
2. New message fades in (opacity 0 → 1)
3. Random selection from message pool
4. Smooth transition (0.5s)
```

### Settings Access

```
1. User taps ⚙️ icon
2. Navigate to settings screen
3. Options:
   - Show/hide countdown
   - Change reminder time
   - Adjust life expectancy
   - Theme settings
```

---

## 🎨 Visual Effects

### Number Change Animation

```css
@keyframes subtleFade {
    0% {
        opacity: 1;
        transform: translateY(0);
    }
    50% {
        opacity: 0.5;
        transform: translateY(-4px);
    }
    100% {
        opacity: 1;
        transform: translateY(0);
    }
}
```

### Colon Blink Animation

```css
@keyframes blink {
    0%, 100% {
        opacity: 1;
    }
    50% {
        opacity: 0.3;
    }
}
```

### Toggle Animation

```css
.toggle-on {
    background-color: #D4AF37;
    transform: translateX(20px);
}

.toggle-off {
    background-color: #E8E8E8;
    transform: translateX(0);
}
```

---

## 🌓 Alternative View: "Focus on Today" Mode

When user disables countdown in settings:

```
┌─────────────────────────────────────────┐
│  ← Mori                            ⚙️   │
├─────────────────────────────────────────┤
│                                         │
│                                         │
│                                         │
│         Focus on today                  │ ← Title (48px)
│                                         │
│        Thursday, March 5                │ ← Date (36px)
│            2026                         │
│                                         │
│                                         │
│  "The present moment is the only        │ ← Quote
│   moment available to us, and           │
│   it is the door to all moments."       │
│                — Thich Nhat Hanh        │
│                                         │
│                                         │
│                                         │
│                                         │
└─────────────────────────────────────────┘
```

---

## 📱 Responsive Behavior

### Mobile (< 768px)

```
- Days number: 48px (smaller)
- Time: 24px
- Message: 16px
- Vertical stack for time units
- Reminder card: full width (90%)
```

### Tablet (768px - 1024px)

```
- Days number: 64px
- Time: 36px
- Message: 18px
- Horizontal time layout
- Centered reminder card
```

### Desktop (> 1024px)

```
- Days number: 72px (larger)
- Time: 42px
- Message: 20px
- Hover effects on interactive elements
- Keyboard shortcuts (R = toggle reminder)
```

---

## 🎨 Color Tokens Used

```css
/* Background */
--bg-primary: #FDF5E6

/* Text */
--text-primary: #333333
--text-secondary: #666666
--text-tertiary: #888888
--text-disabled: #AAAAAA

/* Interactive */
--toggle-on: #D4AF37
--toggle-off: #E8E8E8

/* Accent */
--icon-gold: #D4AF37
```

---

## ✅ Accessibility

### VoiceOver Labels

```
- Days number: "15,482 days remaining"
- Time: "12 hours, 34 minutes, 56 seconds"
- Toggle: "Daily reminder toggle, currently off"
- Message: "Motivational message: [read message]"
```

### Dynamic Type Support

```
- Support text scaling up to 200%
- Maintain proportions
- No truncation
```

### Reduce Motion

```
- Disable colon blink animation
- Simplify number fade to instant change
- Remove message fade transition
```

---

## 📊 Performance Considerations

### Timer Implementation

```swift
// Use Timer, not DispatchQueue.main.asyncAfter
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
    self.updateCountdown()
}

// Pause when app backgrounded
// Resume when app foregrounded
// Avoid battery drain
```

### Memory Management

```
- Single timer instance
- Invalidate on screen dismiss
- Cache calculated end date
- Use @State for reactive updates
```

---

## 🚀 Implementation Notes

### SwiftUI Components

```swift
struct ClockScreen: View {
    @State private var countdown = CountdownResult()
    @State private var showReminder = false
    @State private var currentMessageIndex = 0
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            DaysNumberView(countdown.days)
            TimeBreakdownView(countdown)
            MotivationalMessageView(messages[currentMessageIndex])
            ReminderToggle(isOn: $showReminder)
        }
        .background(Color("ZenCream"))
        .onReceive(timer) { _ in
            updateCountdown()
        }
    }
}

struct DaysNumberView: View {
    let days: Int
    
    var body: some View {
        VStack {
            Text("\(days)")
                .font(.custom("CormorantGaramond-Light", size: 64))
                .foregroundColor(Color("Charcoal"))
            
            Text("days")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.gray)
        }
    }
}
```

---

## 🖼️ Visual Preview

### Default State

```
Large centered days number (15,482)
Smaller time breakdown below (12:34:56)
Italic motivational message at bottom
Reminder toggle card at very bottom
Cream background, calm and centered
```

### Interaction State (Toggle On)

```
Toggle background: Mori Gold
Confirmation toast appears
Notification icon animates
Text updates: "Reminder set"
```

---

## 💾 Data Requirements

```swift
struct UserPreferences {
    var showCountdown: Bool
    var dailyReminderEnabled: Bool
    var reminderTime: Date
    var lifeExpectancy: Int
    var birthDate: Date
}
```

---

**Mockup Status**: ✅ COMPLETE  
**Ready for**: Phoenix Implementation  
**Design File**: SVG exports to be created separately

---

_Created by Flare — Mori Clock Screen v1.0_
