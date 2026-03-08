# Mori Onboarding Flow - Complete Design

**Version:** 1.0  
**Date:** March 7, 2026  
**Designer:** Flare (Design Agent)  
**Status:** Complete - Ready for Implementation  
**Task ID:** j576rzspe8ah235f8mx2peh31982dpqq

---

## 📱 Overview

### Flow Summary
A 5-step onboarding journey that introduces users to Mori's core philosophy and features, creating emotional connection before asking for data.

**Total Duration:** 90-120 seconds  
**Philosophy:** Show value first, ask data second, prompt action third

---

## 🎨 Design Principles

1. **Warm Minimalism** - Clean but not cold
2. **Emotional Connection** - Create "aha moment" at Life Grid preview
3. **Progressive Disclosure** - Introduce complexity gradually
4. **Respectful Data Collection** - Only ask what's necessary
5. **Immediate Value** - Show Life Grid before completing onboarding

---

## 📐 Screen 1: Welcome → Life Grid Introduction

### Purpose
Introduce Mori's philosophy and visual hook

### Wireframe
```
┌─────────────────────────────────────────┐
│                                         │
│         [Mori Logo in Gold]            │
│                                         │
│    ┌─────────────────────────────┐     │
│    │                             │     │
│    │   你的生命                  │     │
│    │   以格子呈现                │     │
│    │                             │     │
│    │   ┌─┬─┬─┬─┬─┬─┬─┬─┬─┐     │     │
│    │   │●│●│●│●│○│○│○│○│○│     │     │
│    │   │●│●│●│●│○│○│○│○│○│     │     │
│    │   │●│●│●│●│○│○│○│○│○│     │     │
│    │   │●│●│●│●│○│○│○│○│○│     │     │
│    │   └─┴─┴─┴─┴─┴─┴─┴─┴─┘     │     │
│    │                             │     │
│    │   每一格 = 一周             │     │
│    │                             │     │
│    └─────────────────────────────┘     │
│                                         │
│     "记住死亡，是为了更好地活着"      │
│                                         │
│         [开始探索] ──────────>         │
│                                         │
└─────────────────────────────────────────┘
```

### Component Specs

#### Mori Logo
```swift
MoriLogoView() {
    Image("mori-logo-gold")
        .frame(width: 48, height: 48)
        .foregroundColor(Color("MoriGold"))
}
```

#### Intro Grid Preview
```swift
IntroGridView() {
    LazyVGrid(columns: Array(repeating: GridItem(.fixed(6), spacing: 2), count: 9)) {
        ForEach(0..<36) { index in
            RoundedRectangle(cornerRadius: 1)
                .fill(index < 12 ? Color("MoriGold") : Color("MoriDark"))
                .frame(width: 6, height: 6)
        }
    }
    .padding(24)
    .background(Color("MoriCharcoal"))
    .cornerRadius(12)
}
```

#### Title Text
```swift
Text("你的生命\n以格子呈现")
    .font(.custom("CormorantGaramond-Light", size: 32))
    .foregroundColor(Color("MoriCream"))
    .multilineTextAlignment(.center)
    .lineSpacing(8)
```

#### Subtitle Text
```swift
Text("每一格 = 一周")
    .font(.custom("DM Mono", size: 14))
    .foregroundColor(Color("MoriGold"))
    .tracking(0.5)
```

#### Philosophy Quote
```swift
Text("\"记住死亡，是为了更好地活着\"")
    .font(.custom("Crimson Pro Italic", size: 16))
    .foregroundColor(Color("MoriMuted"))
    .padding(.top, 16)
```

#### Start Button
```swift
Button(action: { nextScreen() }) {
    Text("开始探索")
        .font(.custom("Crimson Pro SemiBold", size: 18))
        .foregroundColor(Color("MoriDark"))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color("MoriGold"))
        .cornerRadius(8)
}
.padding(.horizontal, 24)
```

### Animation Sequence

1. **Logo Fade In** (0.0s - 0.5s)
   - Opacity: 0 → 1
   - Scale: 0.8 → 1.0
   - Ease: easeOut

2. **Grid Preview Fade In** (0.3s - 0.8s)
   - Opacity: 0 → 1
   - Position: Y +20 → 0
   - Ease: easeOut

3. **Cells Reveal** (0.5s - 1.5s)
   - Each cell animates in sequence (staggered)
   - Duration: 50ms per cell
   - Ease: easeInOut

4. **Text Fade In** (1.0s - 1.3s)
   - Opacity: 0 → 1
   - Position: Y +10 → 0

5. **Button Slide Up** (1.3s - 1.6s)
   - Opacity: 0 → 1
   - Position: Y +30 → 0
   - Spring animation

### Microcopy
- **Title:** "你的生命以格子呈现"
- **Subtitle:** "每一格 = 一周"
- **Quote:** "记住死亡，是为了更好地活着"
- **Button:** "开始探索"

---

## 📅 Screen 2: Birth Date Input → Calculate Remaining Weeks

### Purpose
Collect birth date to generate personalized Life Grid

### Wireframe
```
┌─────────────────────────────────────────┐
│  [< Back]                               │
│                                         │
│     你出生在何时？                       │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │                                 │   │
│  │     📅  选择你的出生日期         │   │
│  │                                 │   │
│  │     [ DatePicker ]              │   │
│  │                                 │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  ℹ️  我们会用这个计算你的         │   │
│  │     生命格子，数据完全本地存储    │   │
│  └─────────────────────────────────┘   │
│                                         │
│  [继续] ───────────────────────────>   │
│                                         │
│  Progress: ●○○○○                       │
└─────────────────────────────────────────┘
```

### Component Specs

#### DatePicker Component
```swift
DatePicker("", selection: $birthDate, displayedComponents: .date)
    .datePickerStyle(.wheel)
    .labelsHidden()
    .frame(maxWidth: .infinity)
    .padding(.vertical, 24)
    .background(Color("MoriCharcoal"))
    .cornerRadius(12)
    .padding(.horizontal, 24)
    .accentColor(Color("MoriGold"))
```

#### Privacy Note
```swift
HStack(alignment: .top, spacing: 12) {
    Image(systemName: "info.circle")
        .foregroundColor(Color("MoriMuted"))
        .font(.system(size: 16))
    
    Text("我们会用这个计算你的生命格子，数据完全本地存储")
        .font(.custom("Crimson Pro", size: 14))
        .foregroundColor(Color("MoriMuted"))
        .lineLimit(nil)
}
.padding(16)
.background(Color("MoriCharcoal"))
.cornerRadius(8)
```

#### Progress Indicator
```swift
HStack(spacing: 8) {
    ForEach(0..<5) { index in
        Circle()
            .fill(index == 1 ? Color("MoriGold") : Color("MoriDark"))
            .frame(width: 8, height: 8)
    }
}
```

### Animation Sequence

1. **Title Slide In** (0.0s - 0.3s)
   - Opacity: 0 → 1
   - Position: X -20 → 0

2. **DatePicker Fade In** (0.2s - 0.5s)
   - Opacity: 0 → 1
   - Scale: 0.95 → 1.0

3. **Privacy Note Fade In** (0.4s - 0.7s)
   - Opacity: 0 → 1
   - Position: Y +10 → 0

4. **Button Enable** (After date selected)
   - Button opacity: 0.5 → 1.0
   - Haptic feedback

### Microcopy
- **Title:** "你出生在何时？"
- **Picker Placeholder:** "选择你的出生日期"
- **Privacy Note:** "我们会用这个计算你的生命格子，数据完全本地存储"
- **Button:** "继续"

---

## 🎨 Screen 3: Life Grid Preview → Show Their Grid

### Purpose
The "aha moment" - users see their personalized Life Grid

### Wireframe
```
┌─────────────────────────────────────────┐
│                                         │
│     你的生命格子                         │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │                                 │   │
│  │  [Full 80x52 Life Grid]        │   │
│  │  (User's actual grid)          │   │
│  │                                 │   │
│  │  1,872 weeks lived             │   │
│  │  2,392 weeks remaining         │   │
│  │                                 │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  💡  每一格都是一份礼物          │   │
│  │     让我们开始珍惜每一周         │   │
│  └─────────────────────────────────┘   │
│                                         │
│  [开始记录] ────────────────────────>   │
│                                         │
│  Progress: ●●○○○                       │
└─────────────────────────────────────────┘
```

### Component Specs

#### Full Life Grid View
```swift
LifeGridView(birthDate: birthDate) {
    ScrollView([.vertical, .horizontal]) {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(4), spacing: 2), count: 52)) {
            ForEach(0..<4160) { index in
                LifeGridCell(
                    weekIndex: index,
                    isLived: isWeekLived(index),
                    isCurrent: isCurrentWeek(index)
                )
            }
        }
        .padding(16)
    }
    .frame(height: 400)
    .background(Color("MoriDark"))
    .cornerRadius(8)
}
```

#### Life Stats
```swift
VStack(spacing: 8) {
    HStack {
        Text("已度过")
            .font(.custom("Crimson Pro", size: 14))
            .foregroundColor(Color("MoriMuted"))
        Spacer()
        Text("\(livedWeeks.formatted()) 周")
            .font(.custom("DM Mono", size: 16))
            .foregroundColor(Color("MoriGold"))
    }
    
    HStack {
        Text("预计剩余")
            .font(.custom("Crimson Pro", size: 14))
            .foregroundColor(Color("MoriMuted"))
        Spacer()
        Text("\(remainingWeeks.formatted()) 周")
            .font(.custom("DM Mono", size: 16))
            .foregroundColor(Color("MoriCream"))
    }
}
.padding(16)
.background(Color("MoriCharcoal"))
.cornerRadius(8)
```

#### Insight Card
```swift
HStack(alignment: .top, spacing: 12) {
    Text("💡")
        .font(.system(size: 24))
    
    VStack(alignment: .leading, spacing: 4) {
        Text("每一格都是一份礼物")
            .font(.custom("Crimson Pro SemiBold", size: 16))
            .foregroundColor(Color("MoriCream"))
        
        Text("让我们开始珍惜每一周")
            .font(.custom("Crimson Pro", size: 14))
            .foregroundColor(Color("MoriMuted"))
    }
}
.padding(16)
.background(Color("MoriCharcoal"))
.cornerRadius(8)
```

### Animation Sequence

1. **Title Fade In** (0.0s - 0.3s)

2. **Grid Build Animation** (0.3s - 2.0s) ⭐ KEY MOMENT
   - Grid reveals row by row
   - Each row: 100ms delay
   - Lived cells: Gold color fills in
   - Remaining cells: Subtle dark gray
   - Current week: Pulse glow effect
   - **Total duration:** 1.7 seconds
   - **Ease:** easeInOut

3. **Stats Count Up** (2.0s - 2.8s)
   - Numbers animate from 0 to actual count
   - Duration: 800ms
   - Spring animation

4. **Insight Card Fade In** (2.5s - 2.8s)
   - Opacity: 0 → 1
   - Position: Y +10 → 0

5. **Button Slide Up** (2.8s - 3.1s)

### Microcopy
- **Title:** "你的生命格子"
- **Stats:**
  - "已度过: X 周"
  - "预计剩余: X 周"
- **Insight:**
  - "每一格都是一份礼物"
  - "让我们开始珍惜每一周"
- **Button:** "开始记录"

---

## ✅ Screen 4: First Check-in → Habit +/- Tracker

### Purpose
Introduce daily habit tracking with immediate action

### Wireframe
```
┌─────────────────────────────────────────┐
│                                         │
│     今天过得如何？                       │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │                                 │   │
│  │     ＋ 今天是美好的一天          │   │
│  │       运动 • 冥想 • 阅读        │   │
│  │                                 │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │                                 │   │
│  │     － 今天有点困难              │   │
│  │       焦虑 • 疲惫 • 分心        │   │
│  │                                 │   │
│  └─────────────────────────────────┘   │
│                                         │
│  💡  每天记录，发现生活的模式          │
│                                         │
│  [继续] ────────────────────────>       │
│                                         │
│  Progress: ●●●○○                       │
└─────────────────────────────────────────┘
```

### Component Specs

#### Positive Card
```swift
VStack(spacing: 12) {
    Text("＋")
        .font(.system(size: 32, weight: .light))
        .foregroundColor(Color("MoriGreen"))
    
    Text("今天是美好的一天")
        .font(.custom("Crimson Pro SemiBold", size: 18))
        .foregroundColor(Color("MoriCream"))
    
    Text("运动 • 冥想 • 阅读")
        .font(.custom("Crimson Pro", size: 14))
        .foregroundColor(Color("MoriMuted"))
}
.frame(maxWidth: .infinity)
.padding(24)
.background(Color("MoriCharcoal"))
.cornerRadius(12)
.onTapGesture {
    selectPositive()
    hapticFeedback()
}
```

#### Negative Card
```swift
VStack(spacing: 12) {
    Text("－")
        .font(.system(size: 32, weight: .light))
        .foregroundColor(Color("MoriMuted"))
    
    Text("今天有点困难")
        .font(.custom("Crimson Pro SemiBold", size: 18))
        .foregroundColor(Color("MoriCream"))
    
    Text("焦虑 • 疲惫 • 分心")
        .font(.custom("Crimson Pro", size: 14))
        .foregroundColor(Color("MoriMuted"))
}
.frame(maxWidth: .infinity)
.padding(24)
.background(Color("MoriCharcoal"))
.cornerRadius(12)
.onTapGesture {
    selectNegative()
    hapticFeedback()
}
```

#### Insight Text
```swift
Text("💡 每天记录，发现生活的模式")
    .font(.custom("Crimson Pro", size: 14))
    .foregroundColor(Color("MoriMuted"))
    .multilineTextAlignment(.center)
```

### Animation Sequence

1. **Title Fade In** (0.0s - 0.3s)

2. **Cards Slide In** (0.2s - 0.6s)
   - Positive card: From left
   - Negative card: From right
   - Staggered by 100ms

3. **Insight Fade In** (0.5s - 0.8s)

4. **Card Selection Animation** (On tap)
   - Selected card: Scale 1.05, border glows gold
   - Other card: Fade to 0.3 opacity
   - Haptic: Light impact
   - Duration: 200ms

5. **Button Enable** (After selection)

### Microcopy
- **Title:** "今天过得如何？"
- **Positive Card:**
  - "＋ 今天是美好的一天"
  - "运动 • 冥想 • 阅读"
- **Negative Card:**
  - "－ 今天有点困难"
  - "焦虑 • 疲惫 • 分心"
- **Insight:** "每天记录，发现生活的模式"
- **Button:** "继续"

---

## 🙏 Screen 5: First Gratitude → Prompt-Based Entry

### Purpose
Introduce gratitude journaling with gentle prompt

### Wireframe
```
┌─────────────────────────────────────────┐
│                                         │
│     最后一步：写下你的感恩               │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  今天，我感谢...                 │   │
│  │                                 │   │
│  │  [TextField - Caveat font]      │   │
│  │  "一件小事，一个微笑，           │   │
│  │   或者今天的阳光 ☀️"            │   │
│  │                                 │   │
│  └─────────────────────────────────┘   │
│                                         │
│  💡  写下三件小事即可完成               │
│                                         │
│  [完成设置] ────────────────────────>   │
│                                         │
│  Progress: ●●●●○                       │
└─────────────────────────────────────────┘
```

### Component Specs

#### Gratitude Input
```swift
VStack(alignment: .leading, spacing: 12) {
    Text("今天，我感谢...")
        .font(.custom("Crimson Pro Italic", size: 18))
        .foregroundColor(Color("MoriCream"))
    
    TextField("", text: $gratitudeText, axis: .vertical)
        .font(.custom("Caveat", size: 18))
        .foregroundColor(Color("MoriCream"))
        .lineLimit(3...5)
        .textFieldStyle(.plain)
        .padding(16)
        .background(Color("MoriCharcoal"))
        .cornerRadius(8)
        .placeholder(when: gratitudeText.isEmpty) {
            Text("一件小事，一个微笑，或者今天的阳光 ☀️")
                .font(.custom("Caveat", size: 18))
                .foregroundColor(Color("MoriMuted"))
                .padding(16)
        }
}
.padding(16)
.background(Color("MoriDark"))
.cornerRadius(12)
```

#### Insight Text
```swift
Text("💡 写下三件小事即可完成")
    .font(.custom("Crimson Pro", size: 14))
    .foregroundColor(Color("MoriMuted"))
```

#### Complete Button
```swift
Button(action: { completeOnboarding() }) {
    Text("完成设置")
        .font(.custom("Crimson Pro SemiBold", size: 18))
        .foregroundColor(Color("MoriDark"))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(gratitudeText.count >= 10 ? Color("MoriGold") : Color("MoriMuted"))
        .cornerRadius(8)
}
.disabled(gratitudeText.count < 10)
.padding(.horizontal, 24)
```

### Animation Sequence

1. **Title Fade In** (0.0s - 0.3s)

2. **Input Card Fade In** (0.2s - 0.5s)
   - Opacity: 0 → 1
   - Scale: 0.95 → 1.0

3. **Cursor Blink** (0.5s onwards)
   - Text field ready for input
   - Keyboard auto-show

4. **Button State Change** (On text input)
   - When 10+ characters: Button turns gold
   - Haptic: Light impact

5. **Completion Animation** (On submit)
   - Paper tear effect (optional)
   - Fade to main app
   - Celebration confetti (subtle)

### Microcopy
- **Title:** "最后一步：写下你的感恩"
- **Prompt:** "今天，我感谢..."
- **Placeholder:** "一件小事，一个微笑，或者今天的阳光 ☀️"
- **Insight:** "写下三件小事即可完成"
- **Button:** "完成设置"

---

## 🎯 Complete Component Library

### 1. MoriButton (Primary)
```swift
struct MoriButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Crimson Pro SemiBold", size: 18))
                .foregroundColor(isDisabled ? Color("MoriMuted") : Color("MoriDark"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isDisabled ? Color("MoriCharcoal") : Color("MoriGold"))
                .cornerRadius(8)
        }
        .disabled(isDisabled)
        .padding(.horizontal, 24)
    }
}
```

### 2. MoriCard
```swift
struct MoriCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(24)
            .background(Color("MoriCharcoal"))
            .cornerRadius(12)
    }
}
```

### 3. MoriInsightBox
```swift
struct MoriInsightBox: View {
    let icon: String
    let title: String
    let subtitle: String?
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("Crimson Pro SemiBold", size: 16))
                    .foregroundColor(Color("MoriCream"))
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.custom("Crimson Pro", size: 14))
                        .foregroundColor(Color("MoriMuted"))
                }
            }
        }
        .padding(16)
        .background(Color("MoriCharcoal"))
        .cornerRadius(8)
    }
}
```

### 4. MoriProgressBar
```swift
struct MoriProgressBar: View {
    let currentStep: Int
    let totalSteps: Int = 5
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps) { index in
                Circle()
                    .fill(index < currentStep ? Color("MoriGold") : Color("MoriDark"))
                    .frame(width: 8, height: 8)
            }
        }
    }
}
```

### 5. MoriTextInput
```swift
struct MoriTextInput: View {
    @Binding var text: String
    let placeholder: String
    let minChars: Int
    
    var body: some View {
        TextField("", text: $text, axis: .vertical)
            .font(.custom("Caveat", size: 18))
            .foregroundColor(Color("MoriCream"))
            .lineLimit(3...5)
            .textFieldStyle(.plain)
            .padding(16)
            .background(Color("MoriCharcoal"))
            .cornerRadius(8)
            .overlay(
                Group {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.custom("Caveat", size: 18))
                            .foregroundColor(Color("MoriMuted"))
                            .padding(16)
                            .allowsHitTesting(false)
                    }
                }
            )
    }
}
```

---

## 🎬 Complete Animation Specifications

### Global Timing
- **Screen transitions:** 300ms
- **Element fade-in:** 200-300ms
- **Button interactions:** 150ms
- **Haptic feedback:** Light impact

### Easing Functions
```swift
extension Animation {
    static let moriEaseOut = Animation.easeOut(duration: 0.3)
    static let moriSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let moriStagger = Animation.easeInOut(duration: 0.5).delay(0.1)
}
```

### Haptic Feedback
```swift
func hapticFeedback() {
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()
}

func hapticSuccess() {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.success)
}
```

### Grid Reveal Animation (Screen 3)
```swift
func animateGridReveal() {
    for row in 0..<80 {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(row) * 0.02) {
            withAnimation(.moriEaseOut) {
                // Reveal this row's cells
                gridRows[row].isVisible = true
            }
        }
    }
    
    // Stats count-up after grid completes
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
        animateStatsCountUp()
    }
}
```

---

## 🎤 Complete Microcopy (Bilingual)

### Screen 1: Welcome
```
EN:
- Title: "Your Life in Grids"
- Subtitle: "Each cell = one week"
- Quote: "Remember death to live fully"
- Button: "Begin"

ZH:
- Title: "你的生命以格子呈现"
- Subtitle: "每一格 = 一周"
- Quote: "记住死亡，是为了更好地活着"
- Button: "开始探索"
```

### Screen 2: Birth Date
```
EN:
- Title: "When were you born?"
- Placeholder: "Select your birth date"
- Privacy: "We'll calculate your Life Grid. Data stays on your device."
- Button: "Continue"

ZH:
- Title: "你出生在何时？"
- Placeholder: "选择你的出生日期"
- Privacy: "我们会用这个计算你的生命格子，数据完全本地存储"
- Button: "继续"
```

### Screen 3: Life Grid Preview
```
EN:
- Title: "Your Life Grid"
- Stats: "X weeks lived / X weeks remaining"
- Insight: "Each cell is a gift. Let's start cherishing every week."
- Button: "Start Tracking"

ZH:
- Title: "你的生命格子"
- Stats: "已度过 X 周 / 预计剩余 X 周"
- Insight: "每一格都是一份礼物，让我们开始珍惜每一周"
- Button: "开始记录"
```

### Screen 4: Habit Check-in
```
EN:
- Title: "How's today?"
- Positive: "＋ A good day"
- Negative: "－ A difficult day"
- Insight: "Track daily to discover life patterns"
- Button: "Continue"

ZH:
- Title: "今天过得如何？"
- Positive: "＋ 今天是美好的一天"
- Negative: "－ 今天有点困难"
- Insight: "每天记录，发现生活的模式"
- Button: "继续"
```

### Screen 5: Gratitude
```
EN:
- Title: "One last step: Write your gratitude"
- Prompt: "Today, I'm grateful for..."
- Placeholder: "A small thing, a smile, or today's sunshine ☀️"
- Insight: "Write 3 small things to complete"
- Button: "Complete Setup"

ZH:
- Title: "最后一步：写下你的感恩"
- Prompt: "今天，我感谢..."
- Placeholder: "一件小事，一个微笑，或者今天的阳光 ☀️"
- Insight: "写下三件小事即可完成"
- Button: "完成设置"
```

---

## 📊 Success Metrics

### Completion Rate
- **Target:** 85% users complete all 5 steps
- **Drop-off points to monitor:** Screen 3 (after grid preview), Screen 5 (gratitude entry)

### Time Metrics
- **Target duration:** 90-120 seconds
- **Screen 3 (Grid Preview):** 3-5 seconds (auto-advance after animation)

### Engagement Metrics
- **First check-in (Screen 4):** 90% make a selection
- **Gratitude entry (Screen 5):** 80% write 10+ characters

### Emotional Response
- **Post-onboarding survey:** "How do you feel?" (Target: Inspired, Reflective)
- **NPS after onboarding:** Target 8+

---

## 🔗 Implementation Handoff

### For Phoenix (Build Agent)

**Files to create:**
1. `OnboardingView.swift` - Main container
2. `OnboardingStep1View.swift` - Welcome
3. `OnboardingStep2View.swift` - Birth date input
4. `OnboardingStep3View.swift` - Life Grid preview
5. `OnboardingStep4View.swift` - Habit check-in
6. `OnboardingStep5View.swift` - Gratitude entry

**Dependencies:**
- LifeCalculator module (for grid calculation)
- MoriDesignSystem (colors, fonts, components)
- CoreData stack (for saving user data)

**State Management:**
```swift
@StateObject var onboardingState = OnboardingState()

class OnboardingState: ObservableObject {
    @Published var currentStep: Int = 1
    @Published var birthDate: Date?
    @Published var firstHabit: HabitType?
    @Published var firstGratitude: String = ""
}
```

**Data to Save:**
- Birth date → UserDefaults or CoreData
- Life expectancy (default 80) → UserDefaults
- First habit entry → CoreData (HabitEntry entity)
- First gratitude → CoreData (GratitudeEntry entity)

---

## ✅ Design Complete - Ready for Implementation

**Deliverables:**
- ✅ 5 onboarding screen wireframes
- ✅ Complete component specs (buttons, inputs, cards)
- ✅ Animation sequences with timing
- ✅ Bilingual microcopy (EN/ZH)
- ✅ Success metrics
- ✅ Implementation handoff notes

**Next Steps:**
1. Phoenix implements OnboardingFlow (5 screens)
2. QA testing on iOS simulator
3. User testing with 5-10 participants
4. Iterate based on feedback

---

_Design by Flare (Design Agent) - March 7, 2026_  
_Mori Q2 Onboarding Flow v1.0_  
_Task ID: j576rzspe8ah235f8mx2peh31982dpqq_
