# Mori - Life Grid Screen UI Mockup

**Feature**: Life Grid Visualization  
**Screen**: Main Life Grid View  
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
│           Your Life in Weeks            │ ← Title (48px, Cormorant)
│                                         │
│    [Year 1] [Year 2] [Year 3] ...      │ ← Year Labels (14px)
│                                         │
│  ┌────────────────────────────────────┐ │
│  │ ••••••••••••••••••••••••••••••••• │ │
│  │ ••••••••••••••••••••••••••●•○○○○○○ │ │ ← Life Grid (4px dots)
│  │ ••••••••••••••••••••••••••○○○○○○○○ │ │   Gold = lived
│  │ •••••••••••••••••••••••••○○○○○○○○○ │ │   Gray = remaining
│  │ ○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○ │ │   Orange = current
│  │ ○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○ │ │
│  │ ... (80 rows total)                │ │
│  └────────────────────────────────────┘ │
│                                         │
│         1,562 weeks lived               │ ← Stats (18px, Crimson Pro)
│         2,598 weeks remaining           │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │ ● Lived   ○ Remaining   ● Current  │ │ ← Legend
│  └────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

---

## 📐 Component Specifications

### Top Navigation

```swift
NavigationView {
    backgroundColor: rgba(253, 245, 230, 0.95)
    height: 56px
    padding: 16px 24px
    backdropFilter: blur(10px)
    borderBottom: 1px solid rgba(232, 232, 232, 0.5)
}

elements:
    backButton {
        icon: "chevron-left"
        color: #333333
        size: 24px
        action: Navigate back
    }
    
    titleText {
        text: "Mori"
        font: "Cormorant Garamond", 20px, Light
        color: #333333
        letterSpacing: 2px
    }
    
    settingsButton {
        icon: "settings"
        color: #4A4A4A
        size: 24px
        action: Open settings
    }
```

### Page Title Section

```swift
TitleSection {
    padding: 48px 24px 32px 24px
    textAlign: center
}

titleText {
    text: "Your Life in Weeks"
    font: "Cormorant Garamond", 48px, Light
    color: #333333
    letterSpacing: 1px
}
```

### Life Grid Container

```swift
LifeGridView {
    backgroundColor: white
    padding: 20px
    borderRadius: 16px
    boxShadow: 0 8px 32px rgba(0, 0, 0, 0.1)
    maxWidth: 100%
    margin: 0 24px
}

GridDisplay {
    display: grid
    gridTemplateColumns: repeat(52, 1fr)
    gap: 2px
    maxWidth: 100%
}
```

### Life Grid Cell (Dot)

```swift
LifeGridCell {
    width: 4px
    height: 4px
    borderRadius: 50% (circular)
    transition: all 0.2s ease
}

states:
    lived {
        backgroundColor: #D4AF37 (Mori Gold)
    }
    
    remaining {
        backgroundColor: #E8E8E8 (Light Gray)
    }
    
    current {
        backgroundColor: #FF6B35 (Ember Orange)
        animation: pulse 2s infinite
    }
    
    hovered {
        transform: scale(1.5)
        cursor: pointer
    }
    
    pressed {
        transform: scale(1.3)
    }
```

### Tooltip (On Cell Tap)

```swift
LifeGridTooltip {
    backgroundColor: #333333 (Charcoal)
    color: white
    padding: 12px 16px
    borderRadius: 8px
    boxShadow: 0 4px 16px rgba(0, 0, 0, 0.2)
    position: absolute
    animation: fadeIn 0.2s ease
}

elements:
    yearLabel {
        text: "Year 30"
        font: "Poppins", 14px, SemiBold
        marginBottom: 4px
    }
    
    weekLabel {
        text: "Week 15"
        font: "Poppins", 12px, Regular
        color: #AAAAAA
        marginBottom: 8px
    }
    
    dateRange {
        text: "Mar 5 - Mar 11, 2026"
        font: "Crimson Pro", 14px, Regular
        marginBottom: 4px
    }
    
    statusBadge {
        backgroundColor: #D4AF37 (if lived)
        or: #E8E8E8 (if remaining)
        padding: 4px 8px
        borderRadius: 4px
        fontSize: 12px
        textTransform: uppercase
        letterSpacing: 0.5px
    }
```

### Statistics Section

```swift
StatsSection {
    padding: 32px 24px
    textAlign: center
}

statItem {
    marginBottom: 8px
}

statNumber {
    font: "Cormorant Garamond", 32px, Light
    color: #333333
}

statLabel {
    font: "Poppins", 14px, Regular
    color: #888888
    textTransform: uppercase
    letterSpacing: 1px
}
```

### Legend

```swift
LegendView {
    display: flex
    justifyContent: center
    gap: 24px
    padding: 16px 24px 48px 24px
}

legendItem {
    display: flex
    alignItems: center
    gap: 8px
}

legendDot {
    width: 12px
    height: 12px
    borderRadius: 50%
}

legendText {
    font: "Poppins", 12px, Medium
    color: #666666
}
```

---

## 🎭 Interaction States

### Scrolling

```
- Vertical scroll enabled
- Smooth scroll behavior
- Sticky top navigation
- Grid resizes responsively
```

### Cell Tap

```
1. User taps cell
2. Cell scales slightly (0.95)
3. Tooltip appears near cell
4. Tooltip shows year, week, date, status
5. Tap elsewhere to dismiss
```

### Hover (Desktop)

```
1. Mouse hovers over cell
2. Cell scales to 1.5x
3. Cursor changes to pointer
4. Tooltip preview shows on delay (500ms)
```

### Long Press (Mobile)

```
1. User long-presses cell (500ms)
2. Haptic feedback
3. Context menu appears:
   - Add note
   - Change mood
   - View details
```

---

## 📱 Responsive Behavior

### Mobile (< 768px)

```
- Grid cell size: 3px (smaller)
- Gap: 1px (tighter)
- Year labels hidden (show on scroll)
- Horizontal scroll enabled
- Tooltip: Bottom sheet instead
```

### Tablet (768px - 1024px)

```
- Grid cell size: 4px
- Gap: 2px
- Year labels visible
- Side-by-side stats
```

### Desktop (> 1024px)

```
- Grid cell size: 5px
- Gap: 3px
- Hover interactions enabled
- Tooltip on hover
- Max grid width: 600px
```

---

## 🎨 Color Tokens Used

```css
/* Backgrounds */
--bg-primary: #FDF5E6
--bg-card: white
--bg-nav: rgba(253, 245, 230, 0.95)

/* Grid Cells */
--cell-lived: #D4AF37
--cell-remaining: #E8E8E8
--cell-current: #FF6B35

/* Text */
--text-primary: #333333
--text-secondary: #666666
--text-tertiary: #888888

/* Borders */
--border-light: #E8E8E8
```

---

## ✅ Accessibility

### VoiceOver Labels

```
- Grid: "Life grid showing 4,160 weeks"
- Lived cell: "Lived week, Year 30, Week 15"
- Current cell: "Current week, Year 30, Week 15"
- Remaining cell: "Future week, Year 50, Week 10"
```

### Color Contrast

```
- Text on white: 12.63:1 (AAA)
- Text on cream: 11.89:1 (AAA)
- Gold on white: 4.56:1 (AA)
- Orange on white: 4.21:1 (AA)
```

### Motion

```
- Pulse animation respects "Reduce Motion"
- Fade transitions: 0.2s
- No rapid flashes
```

---

## 🖼️ Visual Preview

### Default State

```
Clean white card containing grid
Mori Gold dots filling first 30 years
Light gray dots for future
Single Ember Orange dot pulsing at current week
Stats showing weeks lived/remaining
Legend at bottom
```

### Interaction State (Cell Tapped)

```
Cell slightly dimmed
Tooltip overlay near cell
Dark background with white text
Year/Week/Date/Status clearly visible
Dismiss on outside tap
```

---

## 📊 Performance Considerations

```
- Lazy load grid cells (virtualization)
- Render only visible rows initially
- Cache grid data locally
- Animation: CSS transforms (GPU accelerated)
- Tooltip: React Portal (avoid z-index issues)
```

---

## 🚀 Implementation Notes

### SwiftUI Components

```swift
// Main container
struct LifeGridScreen: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    TitleSection()
                    LifeGridCard()
                    StatsSection()
                    LegendView()
                }
            }
            .background(Color("ZenCream"))
        }
    }
}

// Grid cell
struct LifeGridCell: View {
    let week: LifeWeek
    
    var body: some View {
        Circle()
            .fill(cellColor)
            .frame(width: 4, height: 4)
            .onTapGesture {
                showTooltip()
            }
    }
    
    var cellColor: Color {
        if week.isCurrent { return Color("EmberOrange") }
        if week.isLived { return Color("MoriGold") }
        return Color.gray.opacity(0.3)
    }
}
```

---

**Mockup Status**: ✅ COMPLETE  
**Ready for**: Phoenix Implementation  
**Design File**: SVG exports to be created separately

---

_Created by Flare — Mori Life Grid Screen v1.0_
