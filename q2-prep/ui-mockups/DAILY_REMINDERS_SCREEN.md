# Mori - Daily Reminders UI Mockup

**Feature**: Daily Reminders — Gentle Nudges for Mindful Living  
**Screen**: Reminders Settings + Notification Center  
**Designer**: Flare  
**Date**: 2026-03-11

---

## 🎯 Design Philosophy

**Core Principle**: Warm, not anxious. Gentle, not nagging.

Reminders should feel like a friend checking in, not an alarm demanding attention. Every message is designed to reduce stress, not create it.

---

## 📱 Screen 1: Reminders Settings

### Visual Layout

```
┌─────────────────────────────────────────┐
│  ← Settings                             │
├─────────────────────────────────────────┤
│                                         │
│  🔔 Daily Reminders                     │ ← Section Header
│  ─────────────────────────────────────  │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │  Enable Reminders         [toggle] │ │ ← Master Toggle
│  └────────────────────────────────────┘ │
│                                         │
│  Reminder Times (max 3)                 │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │  🌅 Morning                        │ │
│  │  08:00 AM                   [×]    │ │ ← Time Picker
│  │  "A gentle start to your day"      │ │
│  └────────────────────────────────────┘ │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │  ☀️ Midday                         │ │
│  │  12:00 PM                   [×]    │ │
│  │  "A moment to pause and reflect"   │ │
│  └────────────────────────────────────┘ │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │  🌙 Evening                        │ │
│  │  08:00 PM                   [×]    │ │
│  │  "Wind down with intention"        │ │
│  └────────────────────────────────────┘ │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │  + Add Reminder                    │ │ ← Add Button
│  │  (3/3 used - upgrade to Pro for   │ │
│  │   unlimited reminders)             │ │
│  └────────────────────────────────────┘ │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  💬 Message Style                       │
│                                         │
│  ○ Gentle & Warm (default)             │ ← Radio Options
│  ○ Stoic & Reflective                  │
│  ○ Minimal & Quiet                     │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  📝 Preview Messages                    │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │  Sample notification:              │ │
│  │                                    │ │
│  │  Mori                              │ │
│  │  "A gentle nudge: How's your       │ │
│  │   day going? 🌅"                   │ │
│  │                                    │ │
│  │  [Check In] [Dismiss]              │ │
│  └────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

---

## 📐 Component Specifications

### Master Toggle

```css
.reminders-toggle-container {
    background: white;
    border-radius: 16px;
    padding: 20px;
    margin: 0 24px 24px 24px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
    border: 1px solid #E8E8E8;
}

.toggle-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.toggle-label {
    font: "Poppins", 16px, Medium;
    color: #333333;
}

.toggle-switch {
    width: 52px;
    height: 28px;
    border-radius: 14px;
    background: #E8E8E8;
    position: relative;
    transition: all 0.3s ease;
    cursor: pointer;
}

.toggle-switch.active {
    background: #788c5d;
}

.toggle-knob {
    width: 24px;
    height: 24px;
    border-radius: 50%;
    background: white;
    position: absolute;
    top: 2px;
    left: 2px;
    transition: all 0.3s ease;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.toggle-switch.active .toggle-knob {
    left: 26px;
}
```

### Reminder Time Card

```css
.reminder-card {
    background: white;
    border-radius: 16px;
    padding: 20px;
    margin: 0 24px 12px 24px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
    border: 1px solid #E8E8E8;
    transition: all 0.2s ease;
}

.reminder-card:hover {
    border-color: #D4AF37;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
}

.reminder-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 8px;
}

.reminder-icon {
    font-size: 20px;
}

.reminder-name {
    font: "Poppins", 14px, Medium;
    color: #333333;
    margin-left: 8px;
}

.reminder-delete {
    width: 24px;
    height: 24px;
    border-radius: 50%;
    background: transparent;
    color: #888888;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s ease;
}

.reminder-delete:hover {
    background: #FFF5F0;
    color: #FF6B35;
}

.reminder-time {
    font: "Cormorant Garamond", 28px, SemiBold;
    color: #333333;
    margin-bottom: 4px;
}

.reminder-tagline {
    font: "Crimson Pro", 13px, Italic;
    color: #888888;
}
```

### Add Reminder Button

```css
.add-reminder-card {
    background: #FDF5E6;
    border: 2px dashed #D4AF37;
    border-radius: 16px;
    padding: 20px;
    margin: 0 24px 24px 24px;
    text-align: center;
    cursor: pointer;
    transition: all 0.3s ease;
}

.add-reminder-card:hover {
    background: #FFF9ED;
    border-color: #D4AF37;
    transform: translateY(-2px);
}

.add-reminder-card.disabled {
    opacity: 0.5;
    cursor: not-allowed;
}

.add-icon {
    font-size: 24px;
    margin-bottom: 8px;
}

.add-text {
    font: "Poppins", 14px, SemiBold;
    color: #D4AF37;
}

.add-subtext {
    font: "Poppins", 12px, Regular;
    color: #888888;
    margin-top: 4px;
}
```

### Message Style Selector

```css
.message-style-section {
    padding: 24px;
}

.section-label {
    font: "Poppins", 14px, SemiBold;
    color: #333333;
    margin-bottom: 16px;
}

.style-option {
    display: flex;
    align-items: center;
    padding: 16px;
    background: white;
    border-radius: 12px;
    margin-bottom: 8px;
    border: 2px solid transparent;
    cursor: pointer;
    transition: all 0.2s ease;
}

.style-option:hover {
    background: #FFFBF0;
}

.style-option.selected {
    border-color: #D4AF37;
    background: #FFFBF0;
}

.style-radio {
    width: 20px;
    height: 20px;
    border-radius: 50%;
    border: 2px solid #E8E8E8;
    margin-right: 12px;
    position: relative;
    transition: all 0.2s ease;
}

.style-option.selected .style-radio {
    border-color: #D4AF37;
}

.style-option.selected .style-radio::after {
    content: "";
    width: 10px;
    height: 10px;
    border-radius: 50%;
    background: #D4AF37;
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
}

.style-name {
    font: "Poppins", 14px, Medium;
    color: #333333;
}
```

### Preview Card

```css
.preview-section {
    padding: 24px;
}

.preview-card {
    background: #1A1A1A;
    border-radius: 16px;
    padding: 16px;
    margin: 0 24px;
    max-width: 320px;
}

.preview-header {
    display: flex;
    align-items: center;
    margin-bottom: 8px;
}

.preview-app-icon {
    width: 24px;
    height: 24px;
    background: #D4AF37;
    border-radius: 6px;
    margin-right: 8px;
}

.preview-app-name {
    font: "Poppins", 12px, SemiBold;
    color: white;
}

.preview-time {
    font: "Poppins", 11px, Regular;
    color: #888888;
    margin-left: auto;
}

.preview-message {
    font: "Crimson Pro", 15px, Regular;
    color: white;
    line-height: 1.5;
    margin-bottom: 12px;
}

.preview-actions {
    display: flex;
    gap: 8px;
}

.preview-action {
    padding: 8px 16px;
    border-radius: 8px;
    background: #333333;
    font: "Poppins", 12px, Medium;
    color: #D4AF37;
    cursor: pointer;
    transition: all 0.2s ease;
}

.preview-action:hover {
    background: #4A4A4A;
}
```

---

## 💬 Notification Copy Library

### Morning Messages (8:00 AM)

```
1. "A gentle nudge: How's your day going? 🌅"
2. "One week closer to your goals. Check in? ✨"
3. "Your grid is waiting. No rush, just remember. 🕰️"
4. "Good morning. What will this day hold? ☀️"
5. "Start where you are. Use what you have. 🌱"
```

### Midday Messages (12:00 PM)

```
1. "Halfway there. How's your progress? ⏳"
2. "A moment to pause. Anything worth noting? 💭"
3. "Still time to make today count. 🌿"
4. "Brief check: did you show up for yourself? 🫶"
5. "The day continues. Stay present. 🌊"
```

### Evening Messages (8:00 PM)

```
1. "Before sleep: one thing you're grateful for? 🌙"
2. "Wind down with intention. How was today? ✨"
3. "Reflect briefly. Tomorrow starts fresh. 🌟"
4. "End the day with grace. Check in? 💫"
5. "Your week continues. Rest well. 🛋️"
```

### Alternative Styles

**Stoic & Reflective**:
```
1. "Memento mori. Remember today. 🏛️"
2. "Time passes. Are you paying attention? ⏰"
3. "This moment is your life. Be here. ⚡"
```

**Minimal & Quiet**:
```
1. "Check in. 🌿"
2. "Remember today. ⏳"
3. "Your grid. 📊"
```

---

## 🎭 Interaction Flows

### Enable Reminders

```
1. User taps toggle OFF → ON
2. System requests notification permission
3. If granted:
   - Toggle animates to green
   - Default times appear (8am, 12pm, 8pm)
   - Success toast: "Reminders enabled ✨"
4. If denied:
   - Toggle stays OFF
   - Show permission help modal
```

### Add New Reminder

```
1. User taps "Add Reminder"
2. Time picker modal slides up
3. User selects time
4. Card appears with default:
   - Icon based on time (🌅 morning, ☀️ midday, 🌙 evening)
   - Default tagline
5. User can customize tagline
6. Tap "Save" to confirm
```

### Delete Reminder

```
1. User taps [×] on reminder card
2. Confirmation toast: "Remove this reminder?"
3. User confirms
4. Card animates out (slide left + fade)
5. Show success: "Reminder removed"
```

---

## 📱 Responsive Behavior

### Mobile (< 768px)

```
- Cards: Full width, 16px padding
- Time display: 24px (smaller)
- Add button: Full width
- Preview: Max 280px, centered
```

### Tablet+ (≥ 768px)

```
- Cards: Max 480px, centered
- Time display: 28px
- Side padding: 32px
- Hover effects enabled
```

---

## 🎨 Color Tokens

```css
/* Reminder Cards */
--reminder-bg: white
--reminder-border: #E8E8E8
--reminder-hover-border: #D4AF37
--reminder-delete-hover: #FF6B35

/* Toggle */
--toggle-off: #E8E8E8
--toggle-on: #788c5d
--toggle-knob: white

/* Add Button */
--add-bg: #FDF5E6
--add-border: #D4AF37
--add-hover-bg: #FFF9ED

/* Style Selector */
--style-border: transparent
--style-selected-border: #D4AF37
--style-hover-bg: #FFFBF0

/* Preview */
--preview-bg: #1A1A1A
--preview-action-bg: #333333
--preview-action-hover: #4A4A4A
```

---

## ✅ Accessibility

- All toggles have clear labels
- Time picker is keyboard accessible
- Delete buttons have confirmation
- Color isn't only indicator (icons + text used)
- Focus states visible

---

## 🚀 Implementation Notes

### Data Model

```swift
struct Reminder {
    let id: UUID
    var time: Date // Time only (hour + minute)
    var isEnabled: Bool
    var label: String // "Morning", "Midday", "Evening"
    var tagline: String
    var messageStyle: MessageStyle
}

enum MessageStyle: String {
    case gentleWarm = "gentle_warm"
    case stoicReflective = "stoic_reflective"
    case minimalQuiet = "minimal_quiet"
}
```

### Permission Handling

```swift
func requestNotificationPermission() async -> Bool {
    let center = UNUserNotificationCenter.current()
    let options: UNAuthorizationOptions = [.alert, .sound, .badge]
    do {
        return try await center.requestAuthorization(options: options)
    } catch {
        return false
    }
}
```

---

**Mockup Status**: ✅ COMPLETE  
**Ready for**: Phoenix Implementation

---

_Created by Flare — Mori Daily Reminders Screen v1.0_
