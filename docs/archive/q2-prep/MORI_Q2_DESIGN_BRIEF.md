# Mori Q2 Design Brief

**Project**: Mori - Life Tracker & Mindfulness Companion  
**Author**: Flare (Design Agent)  
**Date**: 2026-03-05  
**Status**: Q2 Prep Complete - Ready for Development  
**Target Launch**: 2026-06-01 (Q2 2026)

---

## 🎯 Project Overview

### Vision Statement
> **"Transform awareness of mortality into a daily practice of intentional living"**

Mori is a minimalist life tracker that combines memento mori visualization with daily mindfulness rituals. Users see their life as a grid of weeks, track daily quality, and practice gratitude—all designed to cultivate presence and purpose.

### Core Philosophy
**"Warm Minimalism"** — Tranquil simplicity with emotional depth

### Value Proposition
- **Visual Impact**: See your entire life at a glance (80×52 grid)
- **Daily Ritual**: 3-minute practice (habit tracking + gratitude)
- **Mindful Reflection**: Memento mori framed with compassion, not fear

---

## 👥 Target Users

### Primary Persona: Overloaded Professional
- **Demographics**: 25-40, urban, professional
- **Context**: High-stress work, evening wind-down ritual
- **Pain Point**: Needs quick perspective reset
- **Value**: 3-minute daily clarity ritual

### Secondary Persona: Reflective Self-Improver
- **Demographics**: 20-35, growth-oriented
- **Context**: Morning routine, journaling habit
- **Pain Point**: Wants structured reflection
- **Value**: Guided prompts with meaning focus

### Tertiary Persona: Spiritual Explorer
- **Demographics**: 25-45, contemplative
- **Context**: Life transitions, seeking depth
- **Pain Point**: Wants mortality practice without fear
- **Value**: Compassionate memento mori framing

---

## 🎨 Design Direction

### Brand Personality
- **Warm**: Welcoming, gentle, compassionate
- **Contemplative**: Reflective, intentional, meaningful
- **Minimal**: Clean, uncluttered, breathing room
- **Refined**: Elegant, thoughtful, premium feel

### Visual Language

#### Color Palette
- **Primary**: Mori Gold (#D4AF37) - Wisdom, preciousness, enlightenment
- **Background**: Zen Cream (#FDF5E6) - Calm, paper-like, journal feel
- **Text**: Charcoal (#333333) - Serious, grounded, readable
- **Accent**: Ember Orange (#FF6B35) - Urgency, current week
- **Success**: Sage Green (#788c5d) - Positive habits, growth

#### Typography
- **Headings**: Cormorant Garamond (elegant, contemplative)
- **Body**: Crimson Pro (readable, warm)
- **UI**: Poppins (modern, clear)
- **Chinese**: Noto Serif TC (cultural, refined)

#### Design Principles
1. **Tranquil Simplicity** — Every element has purpose
2. **Breathing Room** — Generous whitespace, not cramped
3. **Warmth Over Cold** — Soft tones, welcoming feel
4. **Precision with Soul** — Careful detail, human touch

### Mood Board Keywords
- Paper texture
- Journal pages
- Soft morning light
- Minimalist zen
- Warm minimalism
- Contemplative space
- Quiet reflection

---

## 📱 MVP Feature Set

### P0 - Core Features (4-6 weeks)

#### 1. Life Grid Visualization
**Purpose**: Visualize entire life as 4,160 weeks (80 years)

**Specs**:
- 80×52 grid (rows = years, columns = weeks)
- Filled cells: lived weeks (Mori Gold)
- Empty cells: remaining weeks (light gray)
- Current week: Ember Orange with pulse animation
- Interactive: tap cell to see date range
- Responsive: scales on different screen sizes

**Data**:
- User birth date input (onboarding)
- Life expectancy (default 80, adjustable)
- Real-time calculation of weeks lived/remaining

**User Story**:
> "As a user, I want to see my life at a glance so that I feel motivated to make each week count."

**Effort**: 2 weeks

---

#### 2. The Clock (Countdown)
**Purpose**: Real-time reminder of time remaining

**Specs**:
- Large countdown display: days, hours, minutes, seconds
- Based on life expectancy calculation
- Motivational micro-copy:
  - "You have X days left to create memories"
  - "Make them count"
- Optional: hide countdown for users who find it stressful

**User Story**:
> "As a user, I want to see my remaining time so that I stay motivated to live intentionally."

**Effort**: 1 week

---

#### 3. Habit +/- (Daily Quality Tracker)
**Purpose**: Simple daily quality check-in

**Specs**:
- One-tap interaction: good day (+) or bad day (-)
- Visual: two large buttons (plus/minus)
- Weekly/monthly reflection view
- Streak tracking (current streak, longest streak)
- Trend visualization (last 7 days, last 30 days)

**User Story**:
> "As a user, I want to quickly track my day quality so that I build self-awareness over time."

**Effort**: 1 week

---

#### 4. Gratitude Journal
**Purpose**: Daily reflection practice

**Specs**:
- Minimal diary input (3-5 sentences suggested)
- Date-stamped entries
- Optional prompts:
  - "Today I'm grateful for..."
  - "A small joy I noticed..."
  - "I want to remember this moment..."
  - "Someone I appreciate today..."
  - "Something I learned..."
- Random memory recall feature
- Browse past entries by date

**User Story**:
> "As a user, I want to record daily gratitude so that I cultivate appreciation and presence."

**Effort**: 1 week

---

### P1 - Polish Features (Post-MVP)
- Weekly reflection prompts
- Monthly summary reports
- Export data (JSON/CSV)
- Widgets (iOS/Android)
- Dark mode

### P2 - Future Features
- Social sharing
- Detailed analytics
- Multiple life grids
- Apple Health integration
- Guided meditations

---

## 🛠️ Technical Architecture

### Tech Stack
- **Frontend**: SwiftUI (iOS native)
- **Database**: CoreData (local-first)
- **Cloud Sync**: iCloud (CloudKit)
- **Architecture**: MVVM + Repository Pattern
- **Language**: Swift 5.9+

### Key Decisions
1. **Local-first**: Data stored on device, cloud sync optional
2. **Privacy-first**: No external analytics, no tracking
3. **Native**: SwiftUI for best iOS experience
4. **Simplicity**: Minimal dependencies, fast performance

### File Structure
```
Mori/
├── MoriApp.swift
├── Models/
│   ├── UserProfile.swift
│   ├── LifeWeek.swift
│   ├── HabitEntry.swift
│   └── GratitudeEntry.swift
├── ViewModels/
│   ├── LifeGridViewModel.swift
│   ├── ClockViewModel.swift
│   ├── HabitViewModel.swift
│   └── GratitudeViewModel.swift
├── Views/
│   ├── LifeGrid/
│   ├── Clock/
│   ├── Habit/
│   └── Gratitude/
├── Repositories/
├── Services/
└── Design/
    ├── DesignTokens.swift
    └── Color+Mori.swift
```

---

## 📊 Success Metrics

### MVP Launch Targets (Q2 2026)
- **Daily Active Users**: 50+
- **7-Day Retention**: 30%+
- **Average Session Duration**: 2+ minutes
- **App Store Rating**: 4.0+
- **Daily Ritual Completion**: 40%+ of DAU

### Engagement Metrics
- **Life Grid Views**: 3+ per week
- **Habit Entries**: 5+ per week
- **Gratitude Entries**: 3+ per week
- **Streak Retention**: 20%+ maintain 7-day streak

### Quality Metrics
- **Crash Rate**: <0.1%
- **Load Time**: <2s initial launch
- **Accessibility**: WCAG AA compliance

---

## 🗓️ Q2 2026 Timeline

### Phase 1: Foundation (Weeks 1-2) — Apr 1-14
**Development**:
- Xcode project setup
- CoreData model implementation
- Design tokens implementation
- PersistenceController configuration
- Basic navigation structure

**Deliverables**:
- ✅ Project structure complete
- ✅ Design system integrated
- ✅ Basic navigation working

---

### Phase 2: Core Features (Weeks 3-4) — Apr 15-28
**Development**:
- LifeCalculator algorithms
- LifeGrid View + ViewModel
- TheClock View + countdown
- Habit +/- system
- Basic UI layouts

**Deliverables**:
- ✅ Life Grid visualization working
- ✅ Countdown timer functional
- ✅ Habit tracking implemented

---

### Phase 3: Polish (Weeks 5-6) — Apr 29 - May 12
**Development**:
- Gratitude journal system
- iCloud sync testing
- UI polish + animations
- Micro-copy integration
- Error handling

**Deliverables**:
- ✅ Gratitude journal complete
- ✅ Cloud sync tested
- ✅ UI polished

---

### Phase 4: Testing & Launch (Weeks 7-8) — May 13 - Jun 1
**Activities**:
- TestFlight beta testing (2 weeks)
- Bug fixes and performance optimization
- App Store submission
- Marketing material preparation
- Launch announcement

**Deliverables**:
- ✅ App Store approved
- ✅ Marketing materials ready
- ✅ Public launch on Jun 1

---

## 💰 Monetization Strategy

### Pricing Model
**Freemium + Subscription**

#### Free Tier
- Life Grid visualization (core)
- Basic countdown
- 7-day habit history
- 10 gratitude entries

#### Pro Monthly: $4.99/month
- Unlimited habit history
- Unlimited gratitude entries
- Cloud sync (iCloud)
- Export data
- Dark mode
- Priority support

#### Pro Annual: $39.99/year (33% discount)
- All Pro Monthly features
- Annual reflection reports
- Early access to new features

### Revenue Targets (Conservative)
- **Month 1**: 100 free users, 5 Pro ($25)
- **Month 3**: 500 free users, 25 Pro ($125/month)
- **Month 6**: 1,000 free users, 50 Pro ($250/month)

---

## 🚀 Go-to-Market Strategy

### Launch Channels
1. **Product Hunt**: Launch day feature
2. **App Store ASO**: "mindfulness", "memento mori", "life tracker"
3. **Content Marketing**: Blog posts on stoicism, mindfulness
4. **Social Media**: Instagram/TikTok wellness creators
5. **Communities**: Reddit r/stoicism, r/mindfulness

### Messaging Framework
**Tagline**: "Face time. Choose meaning. Live lighter."

**Key Messages**:
- For stressed professionals: "3 minutes a day to reset your perspective"
- For self-improvers: "Turn awareness into daily practice"
- For spiritual seekers: "Compassionate memento mori for modern life"

### Content Strategy
- **Blog**: Weekly posts on intentional living, stoicism, mindfulness
- **Newsletter**: Monthly reflection prompts, app updates
- **Social**: Daily quotes, user stories, behind-the-scenes

---

## 📦 Design Handoff Package

### For Phoenix (Implementation Agent)

#### Documentation
1. ✅ **Design Brief** (this document)
2. ✅ **Design System v1.0** (`design-systems/mori/MORI_DESIGN_SYSTEM_V1.md`)
3. ✅ **Architecture Design** (`mori/research/MORI_ARCHITECTURE_DESIGN.md`)
4. ✅ **MVP Definition** (`mori/research/MORI_MVP_DEFINITION.md`)
5. ✅ **User Personas** (`mori/research/MORI_USER_PERSONAS_V1.md`)
6. ✅ **Market Research** (`mori/research/MORI_MARKET_RESEARCH_BRIEF.md`)

#### Design Assets
- **Color Tokens**: All CSS variables defined
- **Typography Scale**: Font sizes, weights, line heights
- **Component Specs**: Buttons, cards, modals, inputs
- **Spacing System**: 8px base grid
- **Icon Set**: Lucide Icons (specific icons listed)
- **Responsive Breakpoints**: Mobile-first approach

#### Implementation Notes
1. **Start with**: Design tokens → Core components → Life Grid
2. **Priority**: Life Grid is P0, most impactful feature
3. **Testing**: Test on multiple iOS devices, accessibility audit
4. **Performance**: Optimize grid rendering (lazy loading)

---

## ✅ Q2 Prep Checklist

### Research & Planning
- [x] User personas defined
- [x] Market research complete
- [x] Competitive analysis done
- [x] Feature prioritization set
- [x] Technical architecture designed
- [x] Design system complete
- [x] Timeline established

### Design Documentation
- [x] Design brief written
- [x] Feature specifications documented
- [x] Component library designed
- [x] Color/typography/s spacing tokens defined
- [x] Icon set selected
- [x] Responsive design planned

### Handoff to Development
- [x] All documentation complete
- [x] Design assets ready
- [x] Technical specs clear
- [x] Implementation notes provided
- [x] Success metrics defined
- [x] Timeline communicated

### Ready for Q2 Development
- [x] **Status**: ✅ COMPLETE
- [x] **Handoff**: Ready for Phoenix
- [x] **Start Date**: April 1, 2026
- [x] **Launch Target**: June 1, 2026

---

## 📝 Open Questions for Stakeholder Review

### Product Decisions
1. **Life Expectancy Default**: Should we use 80 or allow region-based defaults?
2. **Countdown Visibility**: Should countdown be optional from day 1?
3. **Data Export Format**: JSON, CSV, or both?
4. **Onboarding Flow**: 3-step vs 5-step initial setup?

### Technical Decisions
1. **Cloud Sync Timing**: Real-time vs batch sync?
2. **Offline Mode**: Full offline support vs limited?
3. **Analytics**: Local analytics only or optional external?
4. **Widgets**: iOS only or cross-platform (Android)?

### Business Decisions
1. **Pricing Validation**: Test $4.99 vs $7.99 monthly anchor?
2. **Free Tier Limits**: 7 days vs 14 days habit history?
3. **Annual Discount**: 33% vs 40% discount?
4. **Launch Geography**: US only or global from day 1?

---

## 🎯 Next Steps

### Immediate Actions (This Week)
1. ✅ Stakeholder review of design brief
2. ⏳ Answer open questions
3. ⏳ Finalize pricing strategy
4. ⏳ Prepare marketing materials

### Pre-Development (March 2026)
1. ⏳ Phoenix onboarded to Mori project
2. ⏳ Development environment setup
3. ⏳ Sprint planning for Phase 1
4. ⏳ Design QA process established

### Development Kickoff (April 1, 2026)
1. ⏳ Begin Phase 1: Foundation
2. ⏳ Weekly standups with stakeholders
3. ⏳ Bi-weekly demos of progress
4. ⏳ User testing after Phase 2

---

## 📞 Contact & Communication

### Project Team
- **Design Lead**: Flare (Design Agent)
- **Development Lead**: Phoenix (Implementation Agent)
- **Product Owner**: Lumi (PM Agent)
- **Stakeholder**: [Human Name]

### Communication Channels
- **Daily Updates**: Mission Control (Convex tasks)
- **Weekly Sync**: Telegram (Fire Squad)
- **Design Reviews**: Figma (when ready)
- **Code Reviews**: GitHub PRs

### Documentation Links
- **Design System**: `design-systems/mori/MORI_DESIGN_SYSTEM_V1.md`
- **Architecture**: `mori/research/MORI_ARCHITECTURE_DESIGN.md`
- **MVP Spec**: `mori/research/MORI_MVP_DEFINITION.md`
- **Q2 Prep**: `mori/q2-prep/` (this folder)

---

**Status**: ✅ Q2 DESIGN PLANNING COMPLETE  
**Handoff**: Ready for Phoenix implementation  
**Launch Target**: June 1, 2026

---

_Created by Flare (Design Agent) — Mori Q2 Design Brief_  
_Powered by Metta Labs Brand Guidelines_
