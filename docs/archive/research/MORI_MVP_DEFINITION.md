# Mori MVP Definition

**Based on:** User Research + Competitor Analysis (Fia research)
**Target:** 4-6 weeks to MVP launch
**Last Updated:** 2026-02-23 11:00 HKT

---

## 🎯 MVP Core Philosophy

**"Reflective mindfulness companion"**
- Memento mori visualization (emotional impact)
- Short daily ritual loop (habit formation)
- Simple, minimal interface (no complexity)

---

## 📱 MVP Features (Must Have)

### 1. Life Grid (P0 - Core)
- 80x52 grid (age × weeks)
- Filled squares = lived weeks
- Interactive: tap to see memories
- Visual impact: see your life at a glance

**Tech:** SwiftUI Grid + CoreData
**Effort:** 2 weeks

### 2. The Clock (P0 - Core)
- Real-time countdown: "You have X days left"
- Based on life expectancy (configurable)
- Motivational message: "Make them count"

**Tech:** SwiftUI Timer + UserPreferences
**Effort:** 1 week

### 3. Habit +/- (P1 - Daily Ritual)
- Simple daily quality tracker
- One tap: good day (+) or bad day (-)
- Weekly/monthly reflection view

**Tech:** CoreData + Charts
**Effort:** 1 week

### 4. Gratitude (P1 - Journal)
- Minimal diary (3-5 sentences)
- Date-stamped entries
- Random memory recall

**Tech:** CoreData + TextEditor
**Effort:** 1 week

---

## 🚫 Post-MVP (Not Now)

- Social sharing (P2)
- Detailed analytics (P2)
- Multiple life grids (P3)
- Apple Health integration (P3)
- Widgets (P3)

---

## 👥 Target Users (from Fia research)

**Primary:** 
- HK locals 25-45, professionals
- Interest in intentional living/mindfulness

**Secondary:**
- Expats 25-50, higher income
- Bazi/metaphysics enthusiasts

---

## 📊 Success Metrics (MVP)

- Daily active users > 50
- 7-day retention > 30%
- Average session time > 2 min
- App Store rating > 4.0

---

## 🎨 Design Direction (from Flare research)

**Theme:** Warm minimalism
**Colors:** 
- Primary: 米白/米黄 (#FDF5E6, #FFF8E7)
- Secondary: 柔和灰 (#E8E8E8)
- Accent: 深棕/深灰 (#4A4A4A)

**Atmosphere:** 
- Paper/diary texture
- Warm, personal feel
- No harsh blacks/whites

---

## 🛠️ Tech Stack

- **Language:** Swift
- **Framework:** SwiftUI
- **Database:** CoreData (local first)
- **Cloud:** iCloud sync (later)
- **Architecture:** MVVM

---

## 📅 Timeline

| Week | Focus | Deliverable |
|------|-------|-------------|
| 1-2 | Life Grid | Core visualization |
| 3 | The Clock | Countdown feature |
| 4 | Habit +/- | Daily tracker |
| 5 | Gratitude | Simple journal |
| 6 | Polish + Testing | App Store ready |

---

## 🚀 Next Steps

1. ✅ Architecture design (Blaze - done)
2. ✅ User research (Fia - done)
3. ✅ Design direction (Flare - done)
4. 🔄 Implement Life Grid (assign to coding agent)
5. ⏳ Define cloud sync strategy
6. ⏳ Setup CI/CD

---

## 📝 Open Questions

- [ ] Cloud sync: iCloud vs custom backend?
- [ ] Monetization: Freemium vs paid?
- [ ] Onboarding: How to introduce memento mori concept?
- [ ] Privacy: Local-only vs cloud?

---

**Review Date:** 2026-03-01
**Launch Target:** 2026-04-01
