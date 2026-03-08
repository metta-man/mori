# Mori Design Brief - Q2 2026

**Version:** 1.0  
**Date:** March 5, 2026  
**Designer:** Flare (Design Agent)  
**Status:** Complete - Ready for Implementation

---

## 📱 Product Overview

### App Name
**Mori** - A mindful life tracker inspired by Memento Mori philosophy

### Concept Statement
Mori transforms the ancient practice of Memento Mori ("remember you must die") into a modern, life-affirming tool. Through a visual LifeGrid, habit tracking, and gratitude journaling, users develop awareness of life's preciousness while building positive habits.

### Core Philosophy
```
"Contemplating mortality → Appreciating life → Living intentionally"
```

---

## 🎯 Target Audience

### Primary User
**Young professionals seeking mindfulness** (25-40 years old)
- Already uses meditation/mental wellness apps
- Values self-improvement and reflection
- Appreciates minimalist aesthetics
- Likely uses: Calm, Headspace, Notion, streak-based apps

### Secondary User
**Philosophy enthusiasts** (18-50 years old)
- Interested in Stoic practices
- Reads books on mindfulness/philosophy
- Seeks tools for daily reflection
- Values depth over gamification

---

## 🎨 Design Direction

### Visual Style: **Warm Minimalism**

**Core Principle:**
```
Minimalism ≠ Cold
Minimalism = Clarity with Warmth
```

### Design Pillars

1. **Visual Silence**
   - Generous white/cream space
   - No decorative clutter
   - Every element earns its place

2. **Warmth in Contrast**
   - Deep charcoal backgrounds (#0A0A0A)
   - Soft cream text (#FDF5E6)
   - Metta Gold accents (#D4AF37)
   - Balance: 70% dark, 20% light, 10% gold

3. **Typography as Voice**
   - Headlines: Cormorant Garamond Light
   - Body: Crimson Pro Regular
   - Numbers: DM Mono
   - Handwritten feel: Caveat (for personal notes)

4. **Organic Box System**
   - Non-uniform border-radius
   - Hand-drawn feel without being childish
   - CSS: `border-radius: 255px 15px 225px 15px / 15px 225px 15px 255px`

---

## 🎨 Color Palette

### Primary Palette
```css
--mori-dark: #0A0A0A;        /* Deep foundation */
--mori-cream: #FDF5E6;       /* Soft text */
--mori-gold: #D4AF37;        /* Accent moments */
--mori-green: #788c5d;       /* Life/growth */
--mori-muted: #888888;       /* Supporting text */
```

### Extended Palette
```css
--mori-cream-light: #FFF8E7; /* Hover states */
--mori-charcoal: #1A1A2E;    /* Alternative dark */
--mori-brown: #5D4037;       /* Natural accent */
--mori-gray-soft: #E8E8E8;   /* Borders/dividers */
```

### Color Psychology
- **Dark backgrounds**: Contemplation, depth, premium feel
- **Cream tones**: Warmth, paper/journal feel, approachability
- **Gold accents**: Value, significance, moments of insight
- **Green**: Life, growth, nature (used sparingly)

---

## 📐 Typography System

### Font Stack
```css
--font-display: 'Cormorant Garamond', serif;
--font-body: 'Crimson Pro', serif;
--font-mono: 'DM Mono', monospace;
--font-handwritten: 'Caveat', cursive;
```

### Size Scale
```css
--text-xs: 0.75rem;    /* 12px - captions */
--text-sm: 0.875rem;   /* 14px - secondary */
--text-base: 1rem;     /* 16px - body */
--text-lg: 1.25rem;    /* 20px - emphasis */
--text-xl: 1.5rem;     /* 24px - subheadings */
--text-2xl: 2rem;      /* 32px - headings */
--text-3xl: 3rem;      /* 48px - hero numbers */
--text-4xl: 4rem;      /* 64px - LifeGrid stats */
```

### Typography Rules
- **LifeGrid numbers**: DM Mono, 12px, #888888 (muted)
- **Day counters**: DM Mono, 64px, #D4AF37 (gold)
- **Headlines**: Cormorant Garamond Light, generous letter-spacing (0.1em)
- **Body text**: Crimson Pro, line-height 1.6
- **Personal notes**: Caveat, 18px, feels handwritten

---

## 📱 Core Screens

### 1. LifeGrid Screen (Primary)
**Purpose:** Visual representation of life in weeks

**Layout:**
```
┌─────────────────────────────────────┐
│  你的生命格子                        │
│  ┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐  │
│  │●│●│●│●│●│●│○│○│○│○│○│○│○│○│○│  │
│  │●│●│●│●│●│●│○│○│○│○│○│○│○│○│○│  │
│  │●│●│●│●│●│●│○│○│○│○│○│○│○│○│○│  │
│  │...80 rows x 52 cols...          │
│  └─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘  │
│                                     │
│  已度过: 1,872 周                   │
│  预计剩余: 2,392 周                 │
│                                     │
│  [本周反思] [查看详情]              │
└─────────────────────────────────────┘
```

**Visual Specifications:**
- Grid cells: 6px x 6px squares
- Cell spacing: 2px
- Lived weeks: #D4AF37 (gold) or #788c5d (green)
- Remaining weeks: #2A2A2A (dark, subtle)
- Current week: Pulsing subtle glow
- Grid background: #0A0A0A
- Stats below: DM Mono, gold color

### 2. The Clock Screen
**Purpose:** Real-time countdown to estimated end of life

**Layout:**
```
┌─────────────────────────────────────┐
│                                     │
│         你还有                       │
│                                     │
│        17,342                       │
│           天                         │
│                                     │
│      12 小时 34 分 56 秒             │
│                                     │
│    去创造有意义的回忆                │
│                                     │
│  [设置预期寿命] [今日反思]           │
└─────────────────────────────────────┘
```

**Visual Specifications:**
- Main number: DM Mono, 64px, #D4AF37
- Unit text: Crimson Pro, 24px, #FDF5E6
- Subtitle: Crimson Pro Italic, 18px, #888888
- Background: #0A0A0A with subtle radial gradient

### 3. Habit Tracker Screen
**Purpose:** Daily positive/negative habit logging

**Layout:**
```
┌─────────────────────────────────────┐
│  今日如何?                           │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  + 今天是美好的一天            │  │
│  │    运动 • 冥想 • 阅读          │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  - 今天有点难                  │  │
│  │    焦虑 • 疲惫 • 分心          │  │
│  └───────────────────────────────┘  │
│                                     │
│  本周: ●●●○●●○ (5/7 美好日子)       │
│                                     │
│  [添加自定义习惯]                   │
└─────────────────────────────────────┘
```

**Visual Specifications:**
- Cards: Organic box style, cream background
- Plus icon: #788c5d (green)
- Minus icon: #888888 (muted)
- Weekly dots: 12px circles
- Active dots: #D4AF37 (gold)
- Inactive dots: #2A2A2A (dark)

### 4. Gratitude Journal Screen
**Purpose:** Daily gratitude reflection

**Layout:**
```
┌─────────────────────────────────────┐
│  2026年3月5日 星期三                 │
│                                     │
│  今天，我感谢:                       │
│                                     │
│  1. _________________________ 💭    │
│     (Caveat font placeholder)       │
│                                     │
│  2. _________________________ 💭    │
│                                     │
│  3. _________________________ 💭    │
│                                     │
│  [保存] [查看历史]                  │
└─────────────────────────────────────┘
```

**Visual Specifications:**
- Date: Cormorant Garamond, 24px
- Prompts: Crimson Pro Italic, 18px
- Input fields: Caveat font, 18px, feels handwritten
- Border: Thin cream line, #E8E8E8
- Placeholder text: "今天发生的好事..."

---

## 🎭 Interaction Design

### Micro-interactions

1. **LifeGrid Cell Tap**
   - Haptic feedback (light)
   - Cell scales to 1.2x briefly
   - Shows week date tooltip

2. **The Clock Animation**
   - Seconds tick down smoothly
   - Subtle pulse on minute change
   - Gold color intensifies at day milestones

3. **Habit Check-in**
   - Card lifts on hover/press
   - Satisfying "check" animation
   - Weekly dots update with ripple effect

4. **Gratitude Save**
   - Paper tear sound (optional)
   - Gentle fade to history
   - Confirmation message with warm tone

### Navigation
- Tab bar at bottom: LifeGrid | Clock | Habits | Journal
- Minimal icons (line art)
- Active state: Gold color, thicker stroke

---

## 📐 Component Library

### Organic Box Component
```css
.organic-box {
  border-radius: 255px 15px 225px 15px / 
                 15px 225px 15px 255px;
  background: #FDF5E6;
  padding: 24px;
  box-shadow: 0 4px 20px rgba(212, 175, 55, 0.1);
}
```

### Gold Button
```css
.gold-button {
  background: #D4AF37;
  color: #0A0A0A;
  font-family: 'Crimson Pro', serif;
  font-weight: 600;
  padding: 12px 24px;
  border-radius: 8px;
  border: none;
  transition: transform 0.2s, box-shadow 0.2s;
}

.gold-button:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 30px rgba(212, 175, 55, 0.3);
}
```

### LifeGrid Cell
```css
.grid-cell {
  width: 6px;
  height: 6px;
  background: #2A2A2A;
  border-radius: 1px;
  transition: background 0.3s, transform 0.2s;
  cursor: pointer;
}

.grid-cell.lived {
  background: #D4AF37;
}

.grid-cell.current {
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}
```

---

## 📱 Platform Considerations

### iOS Specific
- Dynamic Type support for accessibility
- SF Symbols for system icons
- Haptic feedback for interactions
- Dark mode optimization (already dark-first)

### Android Specific
- Material You integration (minimal)
- Adaptive icons
- Back gesture support

### Responsive Design
- iPhone SE: Compact grid, smaller text
- iPhone Pro Max: Larger grid cells (8px)
- iPad: Side-by-side layout (Grid + Clock)

---

## 🔗 Design System Integration

### Shared with Metta Labs Ecosystem
- Uses Metta Labs color palette
- Typography consistent with BuddhaPicks
- Component library compatible with Anna Panna

### Mori-Specific Elements
- LifeGrid visualization (unique to Mori)
- The Clock concept
- Warm minimalism (vs pure minimalism)

---

## 📊 Success Metrics

### Design Validation
- User testing with 5-10 participants
- A/B test: Pure minimal vs Warm minimal
- Metrics: First impression, emotional response, daily engagement

### Post-Launch Metrics
- Daily active users (DAU)
- Average session length
- Feature usage: LifeGrid views, habit check-ins, journal entries
- User retention (7-day, 30-day)

---

## 🎯 Next Steps (Handoff to Phoenix)

### Phase 1: Core Features (Week 1-2)
1. LifeGrid visualization (80x52 grid)
2. The Clock countdown timer
3. Basic settings (birth date, life expectancy)

### Phase 2: Habits & Journal (Week 3-4)
4. Habit tracker (+/- daily check-in)
5. Gratitude journal (3 daily entries)
6. Weekly summary view

### Phase 3: Polish (Week 5-6)
7. Micro-interactions and animations
8. Onboarding flow
9. Settings and customization
10. Widget support

---

## 📎 Design Assets Location

- **Brand assets:** `~/.openclaw/workspace/projects/metta-labs-infrastructure/brand-assets/`
- **Research:** `~/.openclaw/workspace/mori_design_research.md`
- **Design files:** Figma (link TBD)
- **Component library:** Shared with Metta Labs ecosystem

---

## ✅ Design Brief Complete

**Status:** Ready for implementation  
**Assigned to:** Phoenix (Build Agent)  
**Priority:** P1 (Q2 development)  
**Dependencies:** None (standalone app)

---

_Generated by Flare (Design Agent) - March 5, 2026_
_Metta Labs Design Team_
