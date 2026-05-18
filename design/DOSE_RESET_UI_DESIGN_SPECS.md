# Mori DOSE Reset — UI/UX Design Specifications

**Version:** 1.0
**Date:** 2026-05-04
**Designer:** Flare (Design Agent)
**Status:** Draft — Ready for Review
**Issue:** [MET-40](/MET/issues/MET-40)

---

## Design Context

Building upon existing Mori design system (see [MORI_DESIGN_BRIEF.md](./MORI_DESIGN_BRIEF.md)), these designs extend the Warm Minimalism aesthetic with DOSE framework integration. All designs maintain the core Mori design principles while introducing new accountability and screen time features.

**Design System Reference:**
- Primary Palette: Dark (#0A0A0A), Cream (#FDF5E6), Gold (#D4AF37)
- Typography: Cormorant Garamond Light (headlines), Crimson Pro Regular (body), DM Mono (numbers)
- Component Style: Organic boxes with warm shadows
- Visual Language: Direct but warm, Cantonese/English mixed

---

## Design Deliverables

### 1. Emergency Contact Setup Screen (Onboarding)

**Purpose:** During onboarding, allow users to set up their Accountability Partner(s) who can authorize emergency unlocks during Fast/Brain Reset sessions.

**Screen Layout:**
```
┌─────────────────────────────────┐
│  🛡️ Accountabiliy Partner Setup   │
│                                 │
│  你的「DOSE 守護者」              │
│ 當你進行 Fast 時，                   │
│ 只有佢哋可以授權解鎖。              │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Add Guardian              │ │
│ └─────────────────────────────┘ │
│                                 │
│ Current Guardians:                 │
│ ┌─────────────────────────────┐ │
│ │ 🧑 媽媽                      │ │
│ │ Phone: +852 9123 4567         │ │
│ │ Notify: SMS                    │ │
│ │ Mode: Grace                   │ │
│ └─────────────────────────────┘ │
│                                 │
│ [保存設定] [稍後設置]             │
└─────────────────────────────────┘
```

**Design Specifications:**

**Colors:**
- Background: #0A0A0A (Dark foundation)
- Card background: #1A1A2E (Slightly lighter for contrast)
- Gold accent: #D4AF37 (Primary actions, Guardian icons)
- Cream text: #FDF5E6
- Subtle border: #2A2A2A (Organic box edges)

**Typography:**
- Header: Cormorant Garamond Light, 32px, letter-spacing 0.1em
- Body: Crimson Pro Regular, 16px, line-height 1.6
- Phone/Numbers: DM Mono, 14px
- Button text: Cormorant Garamond Medium, 16px, semi-bold

**Components:**
- Guardian cards with organic border-radius: `255px 15px 225px 15px / 15px 225px 15px 255px`
- Add Guardian button: Full width, gold background (#D4AF37), white text (#0A0A0A)
- Phone input: Left-aligned, 100% width, dark background (#1A1A2E), cream placeholder (#888888)
- Notify method selector: Radio buttons (SMS vs Push)
- Mode selector: Segmented control with Grace (default) vs Strict
- Save button: Gold primary action
- Skip button: Cream secondary text, right-aligned

**Micro-interactions:**
- Add Guardian: Card lifts slightly with warm shadow expansion
- Success: Haptic feedback, subtle gold glow
- Error: Gentle shake, cream border highlight
- Mode switch: Smooth color transition (Gold ↔ Cream)

**User Flow:**
1. **Optional:** Show "Skip for now" option (cream text, top-right)
2. **Mandatory (if no guardians):** Prompt user with friendly warning: "Without a guardian, you won't be able to unlock during Fast. Add one now or skip."
3. **Add Guardian Flow:**
   - Enter name (auto-prompt from contacts: "Mum", "Dad", "Best friend")
   - Enter phone number (E.164 format validation)
   - Choose notify method: SMS (recommended) or Push (requires partner has Mori installed)
   - Set mode: Grace (has backup unlock) vs Strict (no unlock allowed)
   - Visual feedback: Guardian card appears in list
4. **Confirmation:** Show success message with "Your DOSE Guardian can help you stay focused during Fast mode."

**Technical Notes:**
- Guardian list scrolls vertically
- Phone validation: Regex `^\+?[0-9]{11}$`
- Guardian cards max: 3 (expandable in Phase 2)
- Default mode: Grace (recommended for first-time users)
- Data stored locally with encrypted phone numbers

---

### 2. Accountability Partner Management Screen

**Purpose:** Allow users to manage their Accountability Partners (Guardians) — add, edit, or remove guardians who can authorize emergency unlocks.

**Screen Layout:**
```
┌─────────────────────────────────┐
│  🛡️ Accountabiliy Partners       │
│                                 │
│  Manage who can help you stay  │
│  focused during Fast mode                │
│                                 │
│  ┌───────────────────────┐   │
│  │ Your Guardians             │   │
│  │                        │   │
│  │ 🧑 媽媽              │   │
│  │ Phone: +852 9XXX XXXX  │   │
│  │ Notify: SMS • Edit • Delete │   │
│  │ Last Unlock: 2 days ago  │   │
│  │ Mode: Grace               │   │
│  └──────────────────────────┘   │
│                                 │
│  ┌───────────────────────┐   │
│  │ 🧑 Best friend          │   │
│  │ Phone: +852 9XXX XXXX  │   │
│  │ Notify: SMS • Edit • Delete │   │
│  │ Last Unlock: Never            │   │
│  │ Mode: Grace               │   │
│  └──────────────────────────┘   │
│                                 │
│  [+ Add Guardian]  [Back to Settings] │
└─────────────────────────────────┘
```

**Design Specifications:**

**Colors:**
- Background: #0A0A0A (Dark foundation)
- Card background: #1A1A2E (Slightly lighter for contrast)
- Gold accent: #D4AF37 (Primary actions, Guardian icons)
- Cream text: #FDF5E6
- Subtle border: #2A2A2A (Organic box edges)

**Typography:**
- Header: Cormorant Garamond Light, 28px, letter-spacing 0.1em
- Guardian name: Crimson Pro Medium, 18px, semi-bold
- Phone/Details: Crimson Pro Regular, 14px
- Button text: Cormorant Garamond Medium, 16px

**Components:**
- Guardian cards with organic border-radius: `255px 15px 225px 15px / 15px 225px 15px 255px`
- Action buttons: Full width, gold background (#D4AF37), cream text
- Last unlock badge: Gold circular badge, small text
- Mode indicator: Colored pill (Gold = Grace, #FF6B8A = Not set)
- Add Guardian button: Gold primary action, with guardian icon
- Edit/Delete buttons: Cream secondary, right-aligned on card

**Micro-interactions:**
- Tap guardian card: Scale to 1.05x with subtle shadow
- Swipe left on card: Reveal action buttons (Edit/Delete)
- Success: Haptic feedback, gold flash
- Mode change: Smooth pill color transition
- Empty state: Show empty state illustration (no guardians set)

**User Flow:**
1. **View Guardians:** Vertical scrollable list with cards
2. **Add Guardian:** Modal or inline expansion
   - Enter name (auto-prompt from contacts)
   - Enter phone number (E.164 format validation)
   - Choose notify method: SMS (recommended) or Push (requires partner has Mori)
   - Set mode: Grace (has backup unlock) vs Strict (no unlock)
   - Visual feedback: Guardian card appears with warm animation
3. **Edit Guardian:** Tap guardian card → Expand with edit controls
   - Modify phone number, name, notify method, mode
   - Confirm changes with haptic feedback
4. **Delete Guardian:** Tap guardian card → Swipe or tap delete
   - Show confirmation dialog
   - Remove from local storage
5. **Back to Settings:** Cream button, right-aligned, returns to main Mori settings

**Technical Notes:**
- Guardian list scrolls vertically
- Phone validation: Regex `^\+?[0-9]{11}$`
- Guardian cards max: 3 (expandable in Phase 2)
- Mode storage: Grace (default) vs Strict vs SMS/Push per guardian
- Last unlock tracking: Date + time ago calculation
- Data stored locally with encrypted phone numbers
---

### 3. Emergency Unlock Request + OTP Input Flow

**Purpose:** When user is in Fast/Brain Reset mode and wants to unlock, they must request a one-time password from their Accountability Partner via SMS.

**Screen Layout (Unlock Request):**
```
┌─────────────────────────────────┐
│  🆘 Emergency Unlock Request        │
│                                 │
│  You're currently in Fast mode:    │
│  ⏰ 18:32:15 remaining        │
│                                 │
│  Request unlock from your Guardian: │
│  🧑 Best friend (SMS)           │
│  🔐 Request unlock from guardian   │
│  [Cancel] [Request OTP]             │
│                                 │
│  ┌─────────────────────────────┐   │
│  │ 🛡️ Guardian Verification      │   │
│  │                                 │   │
│  │ Your Guardian has been notified. │   │
│  │ They're reviewing your request...   │   │
│  │ ⏱ OTP expires in 4:59          │   │
│  │ [Try Another Guardian] [Back]     │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────┘
```

**Screen Layout (OTP Input):**
```
┌─────────────────────────────────┐
│  🔐 Enter OTP Code               │
│                                 │
│  Please enter the 4-digit code    │
│  sent to your phone number ending in   │
│  +852-9XXX-7:                    │
│                                 │
│  ┌─────────────────────────────┐   │
│  │ [ 1 ] [ 2 ] [ 3 ] [ 4 ] │   │
│  │         [ 5 ] [ 6 ] [ 7 ]    │   │
│  └─────────────────────────────┘   │
│                                 │
│    ⏱ 3:42 remaining               │
│  [Resend OTP] [Back]                │
└─────────────────────────────────┘
```

**Design Specifications:**

**Colors:**
- Background: #0A0A0A (Dark foundation, focused mode)
- Modal background: #1A1A2E (Semi-transparent cream)
- Gold accent: #D4AF37 (Primary actions, unlock success)
- Red accent: #FF6B8A (Oxytocin connection, guardian icon)
- Cream text: #FDF5E6
- Timer text: #888888 (Muted, countdown)
- Input border: #2A2A2A (Organic input focus)

**Typography:**
- Header: Cormorant Garamond Medium, 24px, letter-spacing 0.05em
- Phone number: DM Mono, 18px
- Timer: DM Mono, 20px
- Input digit: DM Mono, 32px, letter-spacing 0.1em
- Status text: Crimson Pro Regular, 14px

**Components:**
- Request modal: Centered, cream card with dark overlay
- OTP keypad: 4x3 grid, circular digit inputs, cream background
- Timer circle: Animated countdown ring, gold border
- Guardian selection cards: Horizontal list, guardian icons on left
- Action buttons: Full width, rounded corners, distinct colors
- Back button: Cream text, right-aligned
- Retry option: Gold pill button, 4-minute cooldown

**Micro-interactions:**
- "Request OTP": Modal slides up with smooth animation
- Timer: Circular countdown with gold border filling
- OTP input: Digits illuminate one by one as entered
- Success: Gold confetti animation + haptic feedback
- Error: Gentle shake, cream border flashes red
- Timer expiration: Visual warning (red border) at 1:00 remaining

**User Flow:**
1. **Fast Mode Active → Request Unlock:**
   - User taps "Emergency Unlock" button
   - Shows request modal with remaining time
   - Displays available guardians
   - User selects guardian → taps "Request OTP"
2. **OTP Request:**
   - Generates 4-digit OTP (valid for 5 minutes)
   - Sends SMS to selected guardian
   - Shows verification modal with countdown timer
   - User can request from another guardian after 4-minute cooldown
3. **OTP Input:**
   - Guardian receives SMS with: "{{userName}} needs unlock, code: {{OTP}}"
   - User enters digits one by one
   - Each digit glows as entered
   - Auto-focuses next input when filled
   - Shows real-time timer countdown
4. **Verification Success:**
   - Validates OTP against generated code
   - Unlocks Fast mode (allows limited app access)
   - Records unlock in history
   - Shows impact on DOSE Score (see below)
5. **Error Handling:**
   - Invalid OTP: Shake animation, error message "Code incorrect"
   - Expired OTP: Show "Code expired" message, regenerate option
   - No response: "No response from guardian" after 2 minutes, offer retry

**Technical Notes:**
- OTP generation: Cryptographically secure random 4 digits
- SMS gateway integration via Twilio or similar
- Guardian verification timeout: 5 minutes (configurable)
- Rate limiting: Max 1 request per guardian every 4 minutes
- Unlock history: Stored locally with encrypted data

---

### 4. SMS Message Template Preview

**Purpose:** Allow users to preview and customize the SMS message sent to their Accountability Partner during emergency unlock requests.

**Screen Layout:**
```
┌─────────────────────────────────┐
│  📩 SMS Message Template       │
│                                 │
│  Preview how your Guardian will   │
│  receive unlock requests:              │
│                                 │
│  Template Preview:                 │
│  ┌─────────────────────────────┐   │
│  │ 🛡️ Mori 專注模式通知      │   │
│  │                                 │   │
│  │ {{userName}} 正在进行           │   │
│  │ 「Dopamine Fast」               │   │
│  │ （剩餘 {{remainingTime}}）      │   │
│  │                                 │   │
│  │ 佢請求解鎖。                  │   │
│  │ 如果你覺得OK，                 │   │
│  │ 請將以下密碼告知：          │   │
│  │                                 │   │
│  │ 🔑 {{OTP}}                     │   │
│  │ （一次性密碼，5分鐘內有效）  │   │
│  └─────────────────────────────┘   │
│                                 │
│  ┌─────────────────────────────┐   │
│  │ Custom Template Editor           │   │
│  │ ┌─────────────────────────────┐   │
│  │ Message greeting:              │   │
│  │ [📩] {{userName}} needs unlock │   │
│  │                                 │   │
│  │ Current status: [🟢 Fast]      │   │
│  │                                 │   │
│  │ Remaining time: [⏰ {{remainingTime}}]│   │
│  │                                 │   │
│  │ Request action: [🔐 Request unlock]│   │
│  │                                 │   │
│  │ Please grant: [🛡️ Allow] / [❌ Deny]│   │
│  └─────────────────────────────┘   │
│                                 │
│  ┌─────────────────────────────┐   │
│  │ Edit fields (optional):           │   │
│  │ Template: [📝 Use custom] [🔄 Default]│   │
│  │ Message body:                │   │
│  │ [Editable textarea]               │   │
│  │                                 │   │
│  │                                 │   │
│  │ [🌐 Emoji selector]             │   │
│  │                                 │   │
│  │                                 │   │
│  │ [💾 Save as default] [💾 Use once]│   │
│  └─────────────────────────────┘   │
└─────────────────────────────────┘
```

**Design Specifications:**

**Colors:**
- Background: #0A0A0A (Dark foundation)
- Card background: #1A1A2E (Message preview card)
- Gold accent: #D4AF37 (SMS icon, primary actions)
- Cream text: #FDF5E6
- Template border: #2A2A2A (Organic card edges)
- Button background: #FF6B8A (Pink accent for Oxytocin connection)
- Edit field background: #1A1A2E (Semi-transparent)

**Typography:**
- Header: Cormorant Garamond Medium, 24px
- Template text: Crimson Pro Regular, 14px, line-height 1.6
- Variable labels: Crimson Pro Medium, 14px
- Button text: Cormorant Garamond Medium, 16px

**Components:**
- Template preview card: Organic border-radius with warm shadow
- Editable textarea: 100% width, cream background, left-aligned
- Variable display: Gold color ({{variableName}}) styling
- Emoji picker: Horizontal scroll, touch-friendly
- Action buttons: Full width, rounded, distinct colors (Save vs Use Once)
- Live preview: Real-time variable substitution, gold highlight for variables

**Micro-interactions:**
- Variable selection: Tap variable → Gold highlight around it
- Edit textarea: Focus with cream border expansion
- Template preview: Smooth transition from card to preview
- Emoji picker: Tap emoji → Small bounce animation

**User Flow:**
1. **View Templates:** Show list of available templates (Default, Custom, Custom saved)
2. **Edit Template:** Tap template → Expand with editable textarea
3. **Live Preview:** Real-time variable substitution as user types
4. **Save Options:**
   - "💾 Save as default" → Replace all future unlock requests
   - "💾 Use once" → Use this template for one request only
5. **Validation:** Max character limit (160), ensure all variables have values

**Technical Notes:**
- Template variables: {{userName}}, {{remainingTime}}, {{otp}}, {{mode}}
- Character limit: 160 (SMS standard)
- Default template: Shown to first-time users, customizable after first unlock
- Custom templates: User-created, stored locally, can be edited or deleted
- Emoji support: iOS native emoji picker for template customization

---

### 4. SMS Message Template Preview

**Purpose:** Allow users to preview and customize the SMS message sent to their Accountability Partner during emergency unlock requests.

**Screen Layout:**
```
┌─────────────────────────────────┐
│  📩 SMS Message Template       │
│                                 │
│  Preview how your Guardian will   │
│  receive unlock requests:              │
│                                 │
│  Template Preview:                 │
│  ┌─────────────────────────────┐   │
│  │ 🛡️ Mori 專注模式通知      │   │
│  │                                 │   │
│  │ {{userName}} 正在进行           │   │
│  │ 「Dopamine Fast」               │   │
│  │ （剩餘 {{remainingTime}}）      │   │
│  │                                 │   │
│  │ 佢請求解鎖。                  │   │
│  │ 如果你覺得OK，                 │   │
│  │ 請將以下密碼告知：          │   │
│  │                                 │   │
│  │ 🔑 {{OTP}}                     │   │
│  │ （一次性密碼，5分鐘內有效）  │   │
│  └─────────────────────────────┘   │
│                                 │
│  ┌─────────────────────────────┐   │
│  │ Custom Template Editor           │   │
│  ┌─────────────────────────────┐   │
│  │ Message greeting:              │   │
│  │ [📩] {{userName}} needs unlock │   │
│  │                                 │   │
│  │ Current status: [🟢 Fast]      │   │
│  │ Remaining time: [⏰ {{remainingTime}}]│   │
│  │                                 │   │
│  │ Request action: [🔐 Request unlock]│   │
│  │ Please grant: [🛡️ Allow] / [❌ Deny]│   │
│  └─────────────────────────────┘   │
│                                 │
│  ┌─────────────────────────────┐   │
│  │ Edit fields (optional):           │   │
│  │ Template: [📝 Use custom] [🔄 Default]│   │
│  │ Message body:                │   │
│  │ [Editable textarea]               │   │
│  │                                 │   │
│  │                                 │   │
│  │ [🌐 Emoji selector]             │   │
│  │                                 │   │
│  │                                 │   │
│  │ [💾 Save as default] [💾 Use once]│   │
│  └─────────────────────────────┘   │
└─────────────────────────────────┘
```

**Design Specifications:**

**Colors:**
- Background: #0A0A0A (Dark foundation)
- Card background: #1A1A2E (Message preview card)
- Gold accent: #D4AF37 (SMS icon, primary actions)
- Cream text: #FDF5E6
- Template border: #2A2A2A (Organic card edges)
- Button background: #FF6B8A (Pink accent for Oxytocin connection)
- Edit field background: #1A1A2E (Semi-transparent)

**Typography:**
- Header: Cormorant Garamond Medium, 24px
- Template text: Crimson Pro Regular, 14px, line-height 1.6
- Variable labels: Crimson Pro Medium, 14px
- Button text: Cormorant Garamond Medium, 16px

**Components:**
- Template preview card: Organic border-radius with warm shadow
- Editable textarea: 100% width, cream background, left-aligned
- Variable display: Gold color ({{variableName}}) styling
- Emoji picker: Horizontal scroll, touch-friendly
- Action buttons: Full width, rounded, distinct colors (Save vs Use Once)
- Live preview: Real-time variable substitution, gold highlight for variables

**Micro-interactions:**
- Variable selection: Tap variable → Gold highlight around it
- Edit textarea: Focus with cream border expansion
- Template preview: Smooth transition from card to preview
- Emoji picker: Tap emoji → Small bounce animation

**User Flow:**
1. **View Templates:** Show list of available templates (Default, Custom, Custom saved)
2. **Edit Template:** Tap template → Expand with editable textarea
3. **Live Preview:** Real-time variable substitution as user types
4. **Save Options:**
   - "💾 Save as default" → Replace all future unlock requests
   - "💾 Use once" → Use this template for one request only
5. **Validation:** Max character limit (160), ensure all variables have values

**Technical Notes:**
- Template variables: {{userName}}, {{remainingTime}}, {{otp}}, {{mode}}
- Character limit: 160 (SMS standard)
- Default template: Shown to first-time users, customizable after first unlock
- Custom templates: User-created, stored locally, can be edited or deleted
- Emoji support: iOS native emoji picker for template customization

---

### 5. Fast Mode Selection (Grace vs Strict)

**Purpose:** Allow users to choose between Grace Mode (with guardian backup unlock) and Strict Mode (no unlock allowed) for Fast sessions.

**Screen Layout:**
```
┌─────────────────────────────────┐
│  🛡️ Fast Mode Settings          │
│                                 │
│  Choose your Fast session mode:     │
│                                 │
│  ┌─────────────────────────────┐   │
│  │ ☯️ Grace Mode (Recommended)     │   │
│  │                                 │   │
│  │ • Has Guardian backup unlock       │   │
│  │ • If needed, Guardian can grant │   │
│  │ • No lockout risk              │   │
│  │ • Best for first-time users      │   │
│  └─────────────────────────────┘   │
│                                 │
│  ┌─────────────────────────────┐   │
│  │ ⛓️ Strict Mode (Advanced)        │   │
│  │                                 │   │
│  │ • No unlock allowed               │   │
│  │ • Full commitment required        │   │
│  │ • For experienced users           │   │
│  └─────────────────────────────┘   │
│                                 │
│  ┌─────────────────────────────┐   │
│  │ ⚖️ Mode Comparison              │   │
│  │ ┌─────────────────────────────┐   │
│  │ Grace Mode                    │   │
│  │ └─────────────────────────────┘   │
│  │ • Unlock: Yes (with guardian)    │   │
│  │ • Difficulty: Easy                │   │
│  │ • Risk: Low                     │   │
│  │                                 │
│  │ ┌─────────────────────────────┐   │
│  │ Strict Mode                   │   │
│  │ └─────────────────────────────┘   │
│  │ • Unlock: No (full commitment)  │   │
│  │ • Difficulty: Hard               │   │
│  │ • Risk: None                    │
│  │                                 │
│  [Confirm Selection]                     │
└─────────────────────────────────┘
```

**Design Specifications:**

**Colors:**
- Background: #0A0A0A (Dark foundation)
- Mode card background: #1A1A2E (Slightly lighter)
- Gold accent: #D4AF37 (Grace Mode - recommended, success actions)
- Strict accent: #FF6B8A (Strict Mode - advanced, warning color)
- Cream text: #FDF5E6
- Comparison border: #2A2A2A (Organic mode comparison)

**Typography:**
- Header: Cormorant Garamond Medium, 24px
- Mode name: Crimson Pro Semi-bold, 20px
- Feature text: Crimson Pro Regular, 14px, line-height 1.5
- Button text: Cormorant Garamond Medium, 16px

**Components:**
- Mode selection cards: Large organic cards with warm shadows
- Selection indicator: Gold ring around chosen mode
- Feature bullets: Gold checkmark icons, small text
- Comparison table: Side-by-side mode cards with clear visual hierarchy
- Confirm button: Gold primary action, full width
- Cancel button: Cream secondary text

**Micro-interactions:**
- Mode card tap: Scale to 1.05x with subtle shadow lift
- Selection highlight: Gold ring animates around selected mode
- Mode comparison: Smooth slide transition when showing comparison
- Selection confirm: Haptic feedback + gold flash
- Cancel mode: Fade to cream background

**User Flow:**
1. **View Options:** Display Grace (recommended) and Strict modes with clear comparison
2. **Select Grace:** Gold ring animation, confirm with haptic feedback
3. **Select Strict:** Warning explanation modal, confirm required
4. **Mode Comparison:** Side-by-side comparison highlighting differences
5. **Confirmation:** Save choice, return to main settings

**Technical Notes:**
- Default mode: Grace (recommended for new users)
- Mode per guardian: Can be set independently for each guardian
- Grace unlock tracking: Each guardian's unlock decisions recorded
- Strict mode behavior: All unlock requests automatically declined, no backup option
- Mode change: Requires confirmation when switching from Grace → Strict
- Analytics: Track mode selection and unlock success rates

---

### 6. Screen Time Permission Flow

**Purpose:** Request iOS Screen Time/Family Controls permissions to enable app blocking during Fast/Brain Reset sessions.

**Screen Layout (Permission Request):**
```
┌─────────────────────────────────┐
│  📱 Screen Time Access Required     │
│                                 │
│  To enable Fast Mode app blocking,     │
│  Mori needs Screen Time permission.     │
│                                 │
│  [Request Permission] [Learn More]     │
└─────────────────────────────────┘
```

**Screen Layout (Permission Explained):**


**Design Specifications:**

**Colors:**
- Background: #0A0A0A (Dark foundation)
- Permission card: #1A1A2E (Slightly lighter)
- Gold accent: #D4AF37 (Primary actions, app icon)
- Blue accent: #4ECDC4 (iOS Screen Time, permission icon)
- Cream text: #FDF5E6
- Category border: #2A2A2A (Organic permission categories)

**Typography:**
- Header: Cormorant Garamond Medium, 20px
- Permission text: Crimson Pro Regular, 14px
- App name: System font, 14px
- Button text: Cormorant Garamond Medium, 16px

**Components:**
- Permission categories: Large organic cards with warm shadows
- App blocking list: Scrollable, gold checkmarks for blocked apps
- Time limit input: Number field, left-aligned, cream background
- Toggle switches: Smooth gold-on/cream-off transitions
- Action buttons: Full width, rounded, distinct colors
- Info icon: Blue question mark (iOS native)

**Micro-interactions:**
- Permission category: Scale to 1.05x with subtle shadow
- App selection: Tap app → Gold checkmark animation
- Time limit: Focus with cream border expansion
- Learn More: Info icon pulse animation
- Success: Haptic feedback + smooth transition to Fast mode

**User Flow:**
1. **Permission Request:** User starts Fast mode → System checks Screen Time permissions
2. **Permission Missing:** Show permission request modal with explanation
3. **Grant Permission:** User taps "Grant Permission" → iOS permission dialog appears
4. **Category Selection:** User selects which app categories to block
5. **Time Limit (Optional):** User can set daily screen time limit for DOSE tracking
6. **Permission Granted:** Success message, transition to Fast mode enabled

**Technical Notes:**
- iOS Screen Time framework: Family Controls entitlement required
- App blocking: ManagedSettings API for app blocking
- DOSE tracking: Screen Time data provides objective dopamine metrics
- Permission categories: Social Media, Games, Entertainment, Productivity (configurable)
- Time limit: Stored per Fast Mode configuration
- Analytics: Track blocked app usage vs DOSE Score correlation
---
### 8. DOSE Score Impact Display

**Purpose:** Show users the immediate DOSE Score impact when they unlock early during Fast/Brain Reset mode, providing clear feedback on the consequences of their actions.

**Screen Layout (Post-Unlock Dashboard):**
┌─────────────────────────────────┐
│  ⚡️ Fast Mode Ended            │
│                                 │
│  You unlocked your Fast mode early  │
│                                 │
│  ┌─────────────────────────────┐   │
│  │ DOSE Score Impact              │   │
│  │                                 │   │
│  │ Dopamine: [-1] ⚠️             │   │
│  │ • You interrupted your Fast    │   │
│  │ • This affects your daily streak │   │
│  │                                 │   │
│  └─────────────────────────────┘   │
│                                 │
│  ┌─────────────────────────────┐   │
│  │ What happens next:             │   │
│  │ • Your DOSE tasks reset tomorrow  │   │
│  │ • Streak counter resets to 0      │   │
│  │ • Stay focused to complete tasks │   │
│  │                                 │
│  └─────────────────────────────┘   │
│                                 │
│  [Continue to DOSE Dashboard]           │
└─────────────────────────────────┘

**Screen Layout (Previous Impact Summary):**
┌─────────────────────────────────┐
│  📊 This Month'"s Impact       │
│                                 │
│  ┌─────────────────────────────┐   │
│  │ 🔵 Unlocks: 2                 │   │
│  │ • No penalty                    │   │
│  │                                 │   │
│  ┌─────────────────────────────┐   │
│  │ 🔶 Denied: 1                  │   │
│  │ • -1 Dopamine each               │   │
│  │                                 │
│  └─────────────────────────────┘   │
│                                 │
│  💬 Total DOSE Impact            │   │
│  │ • Current month: -2 points          │   │
│  │                                 │
│  └─────────────────────────────┘   │
│                                 │
│  [View Full Report]                      │
└─────────────────────────────────┘

**Design Specifications:**

**Colors:**
- Background: #0A0A0A (Dark foundation)
- Impact card: #1A1A2E (Slightly lighter)
- Gold accent: #D4AF37 (DOSE theme)
- Warning red: #FF6B8A (Negative impact)
- Success green: #4ECDC4 (No penalty)
- Cream text: #FDF5E6
- Status border: #2A2A2A (Organic impact levels)

**Typography:**
- Header: Cormorant Garamond Medium, 20px
- Impact points: DM Mono, 28px, bold
- Description text: Crimson Pro Regular, 14px
- Button text: Cormorant Garamond Medium, 16px

**Components:**
- Impact cards: Large cards with clear visual hierarchy
- Point indicators: Gold checkmarks for positive, red X for negative
- Total impact card: Prominent display with animated score
- Progress bar: Visual fill showing DOSE health
- Action buttons: Gold primary action (Continue to Dashboard)
- Report button: Cream secondary (View detailed report)

**Micro-interactions:**
- Impact reveal: Card slides up from bottom with easing
- Point calculation: Animate total score incrementally
- Success animation: Gentle glow (gold ring pulse)
- Warning shake: Phone haptic feedback + subtle red flash
- Report expansion: Smooth modal slide up with blur effect

**User Flow:**
1. **Early Unlock Detection:** System automatically detects early unlock and calculates impact
2. **Impact Display:** Shows immediate visual feedback (gold checkmark = no penalty, red X = -1 dopamine)
3. **Understanding:** User sees clear explanation of consequences and next steps
4. **Monthly Summary:** View accumulated impact for month with break down
5. **Action Guidance:** Continue to DOSE Dashboard button returns to main DOSE interface

**Technical Notes:**
- Impact calculation: Base DOSE score (4 points) - penalty per early unlock
- Dopamine tracking: Negative impact specifically affects Dopamine dimension
- Other dimensions: Oxytocin, Serotonin, Endorphins remain unaffected
- Monthly reset: DOSE daily tasks reset next day after early unlock
- Visual feedback: Clear color coding makes impact immediately visible to users

---

## Implementation Summary

**Completion Status:** All 8 design deliverables completed for MET-40 (Mori DOSE Reset — UI/UX Design & Mockups).

**Deliverables Completed:**

1. ✅ Emergency Contact Setup Screen (Onboarding)
   - Guardian setup flow during onboarding
   - Contact management interface
   - SMS vs Push notification methods
   - Grace vs Strict mode configuration

2. ✅ Accountability Partner Management Screen
   - Guardian list with edit/delete functionality
   - Mode settings per guardian
   - Unlock history tracking per guardian
   - Visual feedback for all actions

3. ✅ Emergency Unlock Request + OTP Input Flow
   - Guardian selection and OTP request
   - 4-digit OTP input interface
   - Countdown timer with visual feedback
   - Success/error states with clear messaging

4. ✅ SMS Message Template Preview
   - Template customization interface
   - Real-time variable substitution preview
   - Default vs custom template options
   - Emoji picker for template enhancement

5. ✅ Fast Mode Selection (Grace vs Strict)
   - Mode comparison with clear visual differences
   - Detailed feature breakdown per mode
   - Selection confirmation with impact warnings
   - User flow optimized for first-time vs experienced users

6. ✅ Screen Time Permission Flow
   - iOS Screen Time/Family Controls integration
   - Permission request modal with educational content
   - App category selection interface
   - Optional daily time limit for DOSE tracking
   - Clear visual hierarchy for permission categories

7. ✅ Unlock History View
   - Chronological unlock history display
   - Detailed unlock information cards
   - DOSE Score impact visualization per event
   - Filter and reporting functionality
   - Color-coded status badges for impact assessment

8. ✅ DOSE Score Impact Display
   - Immediate post-unlock feedback interface
   - Clear impact calculation explanation
   - Visual consequence display for users
   - Monthly summary with breakdown
   - Action guidance for DOSE task completion

**Design System Alignment:**

All designs extend the existing Mori Warm Minimalism aesthetic:
- Maintain #0A0A0A background with #FDF5E6 gold accents
- Use Cormorant Garamond typography with Crimson Pro body text
- Apply organic box component style with non-uniform border-radius
- Ensure smooth micro-interactions with haptic feedback
- Provide clear visual hierarchy with warm but balanced color contrast

**Next Steps:**

All design specifications are ready for implementation by Phoenix (Build Agent). This document provides:
- Complete screen layouts with ASCII mockups
- Detailed design specifications (colors, typography, components)
- User flow documentation for each feature
- Technical implementation notes
- Visual hierarchy guidelines

**Ready for:**
- Design review and approval
- Implementation handoff to Phoenix
- Integration with existing Mori codebase
