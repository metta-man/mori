# Mori - Premium Upsell UI Mockup

**Feature**: Premium Tier — Enhanced Mindfulness Features  
**Screen**: Paywall + Upgrade Flow  
**Designer**: Flare  
**Date**: 2026-03-11

---

## 🎯 Design Philosophy

**Core Principle**: Value-first, not fear-based.

The premium experience should feel like an invitation to deeper practice, not a gate blocking essential features. Emphasize what users gain, not what they lose.

---

## 📱 Screen 1: Premium Paywall (Modal)

### Visual Layout

```
┌─────────────────────────────────────────┐
│                                    [×]  │ ← Close Button
├─────────────────────────────────────────┤
│                                         │
│            ✨ Mori Pro ✨               │ ← Hero Title
│                                         │
│     "Deepen your practice with         │ ← Tagline
│      unlimited features"                │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │                                    │ │
│  │  🌿 Unlimited Habits               │ │ ← Feature 1
│  │     Track as many habits as you    │ │
│  │     want — no limits               │ │
│  │                                    │ │
│  │  📖 Unlimited Gratitude            │ │ ← Feature 2
│  │     Full journal history, forever  │ │
│  │                                    │ │
│  │  📊 Advanced Insights              │ │ ← Feature 3
│  │     See your patterns over time    │ │
│  │                                    │ │
│  │  📤 Data Export                    │ │ ← Feature 4
│  │     Download CSV or JSON anytime   │ │
│  │                                    │ │
│  │  ⚡ Priority Support               │ │ ← Feature 5
│  │     Get help when you need it      │ │
│  │                                    │ │
│  └────────────────────────────────────┘ │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │    🌟 RECOMMENDED                  │ │ ← Yearly Plan (Highlighted)
│  │    ─────────────────────────       │ │
│  │    $49.99 / year                   │ │
│  │    Save 17% vs monthly             │ │
│  │    ≈ $4.17 / month                 │ │
│  │                                    │ │
│  │    [●] Selected                    │ │
│  └────────────────────────────────────┘ │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │    Monthly                         │ │ ← Monthly Plan
│  │    ─────────────────────────       │ │
│  │    $4.99 / month                   │ │
│  │                                    │ │
│  │    [ ] Select                      │ │
│  └────────────────────────────────────┘ │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │       Upgrade to Pro               │ │ ← CTA Button
│  └────────────────────────────────────┘ │
│                                         │
│         7-day free trial • Cancel       │ ← Trust Signals
│         anytime • Secure payment        │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  By continuing, you agree to our        │ ← Legal
│  Terms of Service and Privacy Policy    │
│                                         │
└─────────────────────────────────────────┘
```

---

## 📱 Screen 2: Feature Gate (In-Context Upsell)

### When Creating 6th Habit (Free User)

```
┌─────────────────────────────────────────┐
│  ← New Habit                           │
├─────────────────────────────────────────┤
│                                         │
│  ┌────────────────────────────────────┐ │
│  │                                    │ │
│  │     🌿 Unlock Unlimited Habits     │ │
│  │                                    │ │
│  │     You've reached your limit of   │ │
│  │     5 habits on the free plan.     │ │
│  │                                    │ │
│  │     Upgrade to Pro to track as     │ │
│  │     many habits as you want.       │ │
│  │                                    │ │
│  │     ┌──────────────────────────┐   │ │
│  │     │  Upgrade to Pro →        │   │ │ ← Primary CTA
│  │     └──────────────────────────┘   │ │
│  │                                    │ │
│  │     ┌──────────────────────────┐   │ │
│  │     │  Continue with 5 habits  │   │ │ ← Secondary CTA
│  │     └──────────────────────────┘   │ │
│  │                                    │ │
│  └────────────────────────────────────┘ │
│                                         │
│  Your current habits:                   │
│                                         │
│  ✅ Meditation (streak: 12 days)        │
│  ✅ Exercise (streak: 5 days)           │
│  ✅ Reading (streak: 8 days)            │
│  ✅ Journal (streak: 3 days)            │
│  ✅ Water (streak: 15 days)             │
│                                         │
└─────────────────────────────────────────┘
```

### When Viewing Old Gratitude Entries (>30 days)

```
┌─────────────────────────────────────────┐
│  ← Gratitude History                    │
├─────────────────────────────────────────┤
│                                         │
│  📅 February 2026                       │
│  ─────────────────────────────────────  │
│  Feb 28                                 │
│  "Today I'm grateful for..."            │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │  🔒 Unlock Full History            │ │
│  │                                    │ │
│  │  Free users can view last 30 days. │ │
│  │  Upgrade to Pro for unlimited      │ │
│  │  access to your entire journal.    │ │
│  │                                    │ │
│  │  [Upgrade to Pro →]                │ │
│  │                                    │ │
│  │  You have 127 entries waiting.     │ │
│  └────────────────────────────────────┘ │
│                                         │
│  📅 January 2026 (locked)               │
│  📅 December 2025 (locked)              │
│                                         │
└─────────────────────────────────────────┘
```

---

## 📐 Component Specifications

### Modal Container

```css
.premium-modal {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.6);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
    backdrop-filter: blur(8px);
    animation: fadeIn 0.3s ease;
}

@keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
}

.premium-card {
    background: #FDF5E6;
    border-radius: 24px;
    padding: 32px 24px;
    max-width: 400px;
    width: 90%;
    max-height: 90vh;
    overflow-y: auto;
    box-shadow: 0 24px 64px rgba(0, 0, 0, 0.3);
    animation: slideUp 0.4s ease;
}

@keyframes slideUp {
    from {
        opacity: 0;
        transform: translateY(40px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}
```

### Hero Section

```css
.premium-hero {
    text-align: center;
    margin-bottom: 32px;
}

.premium-badge {
    display: inline-block;
    background: linear-gradient(135deg, #D4AF37 0%, #E8C547 100%);
    color: #333333;
    padding: 6px 16px;
    border-radius: 20px;
    font: "Poppins", 12px, SemiBold;
    letter-spacing: 1px;
    margin-bottom: 16px;
}

.premium-title {
    font: "Cormorant Garamond", 32px, SemiBold;
    color: #333333;
    margin-bottom: 8px;
}

.premium-tagline {
    font: "Crimson Pro", 16px, Regular;
    color: #666666;
    line-height: 1.6;
}
```

### Feature List

```css
.feature-list {
    background: white;
    border-radius: 16px;
    padding: 24px;
    margin-bottom: 24px;
    border: 1px solid #E8E8E8;
}

.feature-item {
    display: flex;
    align-items: flex-start;
    padding: 12px 0;
    border-bottom: 1px solid #F5F5F5;
}

.feature-item:last-child {
    border-bottom: none;
}

.feature-icon {
    font-size: 20px;
    margin-right: 12px;
    flex-shrink: 0;
}

.feature-content {
    flex: 1;
}

.feature-name {
    font: "Poppins", 14px, SemiBold;
    color: #333333;
    margin-bottom: 2px;
}

.feature-desc {
    font: "Poppins", 12px, Regular;
    color: #888888;
}
```

### Pricing Cards

```css
.pricing-section {
    margin-bottom: 24px;
}

.pricing-card {
    background: white;
    border-radius: 16px;
    padding: 20px;
    margin-bottom: 12px;
    border: 2px solid #E8E8E8;
    cursor: pointer;
    transition: all 0.2s ease;
    position: relative;
}

.pricing-card:hover {
    border-color: #D4AF37;
}

.pricing-card.selected {
    border-color: #D4AF37;
    background: #FFFBF0;
}

.pricing-card.recommended {
    border-color: #D4AF37;
}

.recommended-badge {
    position: absolute;
    top: -10px;
    right: 16px;
    background: #D4AF37;
    color: #333333;
    padding: 4px 12px;
    border-radius: 12px;
    font: "Poppins", 10px, Bold;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

.pricing-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 8px;
}

.pricing-name {
    font: "Poppins", 14px, Medium;
    color: #333333;
}

.pricing-price {
    font: "Cormorant Garamond", 24px, SemiBold;
    color: #333333;
}

.pricing-period {
    font: "Poppins", 12px, Regular;
    color: #888888;
}

.pricing-save {
    font: "Poppins", 12px, Medium;
    color: #788c5d;
    margin-top: 4px;
}

.pricing-monthly {
    font: "Poppins", 11px, Regular;
    color: #888888;
    margin-top: 2px;
}
```

### CTA Button

```css
.cta-button {
    width: 100%;
    padding: 18px;
    background: linear-gradient(135deg, #D4AF37 0%, #B8942D 100%);
    color: #333333;
    font: "Poppins", 16px, SemiBold;
    border-radius: 12px;
    border: none;
    cursor: pointer;
    transition: all 0.2s ease;
    margin-bottom: 12px;
}

.cta-button:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 24px rgba(212, 175, 55, 0.4);
}

.cta-button:active {
    transform: translateY(0);
}
```

### Trust Signals

```css
.trust-signals {
    text-align: center;
    margin-bottom: 24px;
}

.trust-text {
    font: "Poppins", 12px, Regular;
    color: #888888;
    line-height: 1.6;
}

.trust-bullets {
    display: flex;
    justify-content: center;
    gap: 8px;
    flex-wrap: wrap;
}

.trust-bullet {
    display: flex;
    align-items: center;
    gap: 4px;
}

.trust-icon {
    color: #788c5d;
    font-size: 12px;
}
```

### Close Button

```css
.close-button {
    position: absolute;
    top: 16px;
    right: 16px;
    width: 36px;
    height: 36px;
    border-radius: 50%;
    background: rgba(0, 0, 0, 0.05);
    border: none;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s ease;
}

.close-button:hover {
    background: rgba(0, 0, 0, 0.1);
}

.close-icon {
    color: #666666;
    font-size: 18px;
}
```

---

## 🎭 Feature Gate Component

```css
.feature-gate {
    background: white;
    border-radius: 16px;
    padding: 24px;
    margin: 16px;
    border: 2px dashed #D4AF37;
    text-align: center;
}

.gate-icon {
    font-size: 40px;
    margin-bottom: 16px;
}

.gate-title {
    font: "Cormorant Garamond", 20px, SemiBold;
    color: #333333;
    margin-bottom: 8px;
}

.gate-desc {
    font: "Poppins", 14px, Regular;
    color: #666666;
    line-height: 1.6;
    margin-bottom: 20px;
}

.gate-primary-btn {
    width: 100%;
    padding: 14px;
    background: #D4AF37;
    color: #333333;
    font: "Poppins", 14px, SemiBold;
    border-radius: 10px;
    border: none;
    cursor: pointer;
    margin-bottom: 8px;
    transition: all 0.2s ease;
}

.gate-primary-btn:hover {
    background: #B8942D;
}

.gate-secondary-btn {
    width: 100%;
    padding: 14px;
    background: transparent;
    color: #888888;
    font: "Poppins", 14px, Regular;
    border-radius: 10px;
    border: 1px solid #E8E8E8;
    cursor: pointer;
    transition: all 0.2s ease;
}

.gate-secondary-btn:hover {
    border-color: #CCCCCC;
    color: #666666;
}

.gate-stat {
    font: "Poppins", 12px, Medium;
    color: #D4AF37;
    margin-top: 12px;
}
```

---

## 📱 Upgrade Flow

### Step 1: Trigger

```
Triggers:
1. Creating 6th habit → Feature gate modal
2. Viewing gratitude >30 days → Feature gate inline
3. Tapping "Pro" badge in settings → Full paywall
4. Tapping "Insights" tab → Feature gate
5. Export button → Feature gate
```

### Step 2: Selection

```
1. User sees paywall with features
2. Default: Yearly selected (highlighted)
3. Can switch to Monthly
4. Price updates in CTA
```

### Step 3: Payment (Stripe)

```
1. User taps "Upgrade to Pro"
2. Stripe Checkout opens (web) / Apple Pay (iOS)
3. User completes payment
4. Success animation
5. Premium features unlock immediately
```

### Step 4: Confirmation

```
┌─────────────────────────────────────────┐
│                                         │
│              ✅                         │
│                                         │
│     Welcome to Mori Pro! ✨             │
│                                         │
│     You now have access to all          │
│     premium features.                   │
│                                         │
│     [Start Exploring]                   │
│                                         │
└─────────────────────────────────────────┘
```

---

## 💬 Copy Guidelines

### Do's ✅

```
- "Unlock unlimited habits"
- "Deepen your practice"
- "Continue your journey"
- "Support your growth"
- "You have [X] entries waiting"
```

### Don'ts ❌

```
- "You've hit your limit" (negative framing)
- "Upgrade now or lose access" (fear-based)
- "Don't miss out" (FOMO tactics)
- "Only $4.99" (minimizing cost)
- "Best value" (comparative language)
```

---

## 🎨 Color Tokens

```css
/* Premium Theme */
--premium-gold: #D4AF37
--premium-gold-light: #E8C547
--premium-gold-dark: #B8942D
--premium-gradient: linear-gradient(135deg, #D4AF37 0%, #E8C547 100%)

/* Cards */
--card-bg: white
--card-border: #E8E8E8
--card-selected-bg: #FFFBF0
--card-selected-border: #D4AF37

/* Text */
--text-primary: #333333
--text-secondary: #666666
--text-tertiary: #888888

/* Success */
--success: #788c5d

/* Feature Gate */
--gate-border: #D4AF37 (dashed)
--gate-bg: white
```

---

## 📊 Free vs Pro Comparison

| Feature | Free | Pro |
|---------|------|-----|
| Life Grid | ✅ Full | ✅ Full |
| Habits | 5 max | ♾️ Unlimited |
| Gratitude | 30 days | ♾️ Unlimited |
| Reminders | 3 max | ♾️ Unlimited |
| Insights | Basic | Advanced |
| Export | ❌ | ✅ CSV/JSON |
| Support | Community | Priority |

---

## 📱 Responsive Behavior

### Mobile (< 400px)

```
- Modal: Full screen (no padding)
- Title: 28px
- Feature items: Smaller padding
- Pricing cards: Stacked, full width
- CTA: Fixed at bottom
```

### Tablet+ (≥ 400px)

```
- Modal: Centered, max 400px
- Title: 32px
- Padding: 32px
- Hover effects enabled
```

---

## ✅ Accessibility

- All buttons have clear labels
- Color contrast meets WCAG AA
- Price is in text, not just color
- Close button is keyboard accessible
- Focus trap within modal
- Escape key closes modal

---

## 🚀 Implementation Notes

### Data Model

```swift
struct Subscription {
    let id: String
    let userId: String
    let tier: Tier
    let startDate: Date
    let expiryDate: Date?
    let stripeSubscriptionId: String?
    let isActive: Bool
}

enum Tier: String {
    case free = "free"
    case pro = "pro"
}

struct Pricing {
    let monthlyPrice: Decimal // 4.99
    let yearlyPrice: Decimal  // 49.99
    let yearlySavings: Int    // 17%
    let yearlyMonthlyEquivalent: Decimal // 4.17
}
```

### Feature Gates

```swift
func canAccessFeature(_ feature: PremiumFeature) -> Bool {
    switch feature {
    case .unlimitedHabits:
        return subscription.tier == .pro || habits.count < 5
    case .unlimitedGratitude:
        return subscription.tier == .pro || gratitudeEntries.count <= 30
    case .advancedInsights:
        return subscription.tier == .pro
    case .dataExport:
        return subscription.tier == .pro
    case .prioritySupport:
        return subscription.tier == .pro
    }
}
```

### Stripe Integration

```swift
func createCheckoutSession(tier: Tier, interval: BillingInterval) async throws -> URL {
    let priceId = interval == .monthly 
        ? "price_monthly_pro" 
        : "price_yearly_pro"
    
    let session = try await stripe.checkout.sessions.create(
        mode: .subscription,
        lineItems: [.init(price: priceId, quantity: 1)],
        successUrl: "mori://subscription/success",
        cancelUrl: "mori://subscription/cancel"
    )
    
    return session.url!
}
```

---

**Mockup Status**: ✅ COMPLETE  
**Ready for**: Phoenix Implementation

---

_Created by Flare — Mori Premium Upsell Screen v1.0_
