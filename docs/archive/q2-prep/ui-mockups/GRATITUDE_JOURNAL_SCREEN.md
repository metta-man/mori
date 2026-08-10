# Mori - Gratitude Journal UI Mockup

**Feature**: Gratitude Journal - Daily Appreciation Practice  
**Screen**: Main Gratitude Journal View  
**Designer**: Flare  
**Date**: 2026-03-05

---

## 🎨 Visual Layout

### Screen Overview

```
┌─────────────────────────────────────────┐
│  ← Mori                     📖  ⚙️     │ ← Top Nav (56px)
├─────────────────────────────────────────┤
│                                         │
│    What are you grateful for today?     │ ← Title (32px, Cormorant)
│                                         │
│  ┌────────────────────────────────────┐ │
│  │  💡 Choose a prompt                │ │ ← Prompt Section
│  │  ┌──────┐ ┌──────┐ ┌──────┐       │ │
│  │  │Today │ │ Joy  │ │Moment│ ...   │ │ ← Prompt Chips
│  │  └──────┘ └──────┘ └──────┘       │ │
│  └────────────────────────────────────┘ │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │                                    │ │
│  │  Today I'm grateful for...         │ │ ← Text Input (120px min)
│  │                                    │ │
│  │  [Cursor blinking]                 │ │
│  │                                    │ │
│  │  ────────────────────────          │ │
│  │  Characters: 45/500      [Save]   │ │ ← Character count + Save button
│  └────────────────────────────────────┘ │
│                                         │
│         ───── OR ─────                  │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │  🎲 Random Memory                  │ │ ← Random Recall Button
│  │  Rediscover a past moment          │ │
│  └────────────────────────────────────┘ │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │  📅 Recent Gratitude               │ │ ← Recent Entries Section
│  │  ────────────────────────          │ │
│  │  Mar 4 · "Today I'm grateful..."   │ │ ← Entry Preview (3 lines)
│  │  Mar 3 · "A small joy I..."        │ │
│  │  Mar 2 · "I want to remember..."   │ │
│  │                                    │ │
│  │         [View All →]               │ │
│  └────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

---

## 📐 Component Specifications

### Page Title

```swift
TitleSection {
    padding: 32px 24px 16px 24px
    textAlign: center
}

titleText {
    text: "What are you grateful for today?"
    font: "Cormorant Garamond", 32px, Regular
    color: #333333
    letterSpacing: 0.5px
}
```

### Prompt Selection Section

```swift
PromptSection {
    backgroundColor: white
    borderRadius: 16px
    padding: 20px
    margin: 0 24px 24px 24px
    boxShadow: 0 2px 8px rgba(0, 0, 0, 0.05)
    border: 1px solid #E8E8E8
}

promptHeader {
    display: flex
    alignItems: center
    marginBottom: 16px
}

promptIcon {
    fontSize: 18px
    marginRight: 8px
}

promptTitle {
    font: "Poppins", 14px, Medium
    color: #666666
}

promptChips {
    display: flex
    flexWrap: wrap
    gap: 8px
}

PromptChip {
    padding: 8px 16px
    borderRadius: 20px
    backgroundColor: #F5F5F5
    border: 1px solid #E0E0E0
    font: "Poppins", 13px, Regular
    color: #666666
    cursor: pointer
    transition: all 0.2s ease
}

PromptChip:hover {
    backgroundColor: #F0F5EB
    borderColor: #788c5d
    color: #788c5d
}

PromptChip.selected {
    backgroundColor: #788c5d
    color: white
    borderColor: #788c5d
}

/* Prompt Options */
PromptChip.today { /* Default style */ }
PromptChip.smallJoy { /* Default style */ }
PromptChip.moment { /* Default style */ }
PromptChip.person { /* Default style */ }
PromptChip.growth { /* Default style */ }
```

### Text Input Area

```swift
GratitudeEditorView {
    backgroundColor: white
    borderRadius: 16px
    padding: 20px
    margin: 0 24px 24px 24px
    boxShadow: 0 2px 8px rgba(0, 0, 0, 0.05)
    border: 1px solid #E8E8E8
    minHeight: 120px
}

textArea {
    width: 100%
    minHeight: 80px
    border: none
    resize: none
    font: "Poppins", 15px, Regular
    color: #333333
    lineHeight: 1.6
    backgroundColor: transparent
}

textArea::placeholder {
    color: #AAAAAA
    font-style: italic
}

textArea:focus {
    outline: none
}

editorFooter {
    display: flex
    justifyContent: space-between
    alignItems: center
    marginTop: 16px
    paddingTop: 16px
    borderTop: 1px solid #E8E8E8
}

charCount {
    font: "Poppins", 12px, Regular
    color: #888888
}

charCount.warning {
    color: #FF6B35 /* When > 450 chars */
}

charCount.error {
    color: #DC3545 /* When > 500 chars */
}

SaveButton {
    padding: 8px 24px
    borderRadius: 8px
    backgroundColor: #788c5d
    color: white
    font: "Poppins", 14px, SemiBold
    border: none
    cursor: pointer
    transition: all 0.2s ease
}

SaveButton:hover {
    backgroundColor: #6A7E51
    transform: translateY(-1px)
    boxShadow: 0 4px 12px rgba(120, 140, 93, 0.3)
}

SaveButton:disabled {
    backgroundColor: #CCCCCC
    cursor: not-allowed
    transform: none
    boxShadow: none
}
```

### Random Memory Button

```swift
RandomMemoryButton {
    backgroundColor: #FDF5E6
    border: 2px dashed #D4AF37
    borderRadius: 16px
    padding: 24px
    margin: 0 24px 24px 24px
    textAlign: center
    cursor: pointer
    transition: all 0.3s ease
}

RandomMemoryButton:hover {
    backgroundColor: #FFF9ED
    borderColor: #D4AF37
    transform: translateY(-2px)
    boxShadow: 0 4px 16px rgba(212, 175, 55, 0.2)
}

randomIcon {
    fontSize: 28px
    marginBottom: 8px
    animation: diceRoll 0.6s ease on hover
}

randomTitle {
    font: "Poppins", 16px, SemiBold
    color: #D4AF37
    marginBottom: 4px
}

randomSubtitle {
    font: "Poppins", 12px, Regular
    color: #888888
}

/* Dice Roll Animation */
@keyframes diceRoll {
    0%, 100% { transform: rotate(0deg); }
    25% { transform: rotate(-15deg); }
    75% { transform: rotate(15deg); }
}
```

### Recent Entries Section

```swift
RecentEntriesSection {
    backgroundColor: white
    borderRadius: 16px
    padding: 20px
    margin: 0 24px 48px 24px
    boxShadow: 0 2px 8px rgba(0, 0, 0, 0.05)
    border: 1px solid #E8E8E8
}

sectionHeader {
    display: flex
    alignItems: center
    marginBottom: 16px
}

sectionIcon {
    fontSize: 18px
    marginRight: 8px
}

sectionTitle {
    font: "Poppins", 14px, SemiBold
    color: #333333
}

divider {
    height: 1px
    backgroundColor: #E8E8E8
    marginBottom: 16px
}

EntryPreview {
    padding: 12px 0
    borderBottom: 1px solid #F5F5F5
    cursor: pointer
    transition: all 0.2s ease
}

EntryPreview:hover {
    backgroundColor: #FAFAFA
    padding-left: 8px
}

EntryPreview:last-child {
    borderBottom: none
}

entryDate {
    font: "Poppins", 12px, Medium
    color: #788c5d
    marginBottom: 4px
}

entryContent {
    font: "Poppins", 14px, Regular
    color: #666666
    lineClamp: 3
    display: -webkit-box
    -webkit-line-clamp: 3
    -webkit-box-orient: vertical
    overflow: hidden
}

viewAllButton {
    display: flex
    justifyContent: center
    marginTop: 16px
    paddingTop: 16px
    borderTop: 1px solid #E8E8E8
}

viewAllText {
    font: "Poppins", 14px, Medium
    color: #788c5d
    cursor: pointer
    transition: all 0.2s ease
}

viewAllText:hover {
    color: #6A7E51
}
```

---

## 🎭 Interaction States

### Initial Load

```
1. Check if today's entry exists
2. If yes: Pre-fill text area with saved content
3. If no: Show empty text area with placeholder
4. Load 3 most recent entries
5. Default prompt: "Today I'm grateful for..."
```

### Selecting a Prompt

```
1. User taps a prompt chip
2. Previous chip deselects
3. Selected chip fills with Sage Green
4. Placeholder updates to prompt text
5. Text area focuses automatically
6. Cursor positioned after prompt
```

### Writing Entry

```
1. User types in text area
2. Character count updates in real-time
3. At 450 chars: Count turns orange (warning)
4. At 500 chars: Input disabled, count red
5. Auto-save draft every 30 seconds
6. Save button enables when valid (≥10 chars)
```

### Saving Entry

```
1. User taps Save button
2. Validate content (10-500 chars)
3. If invalid: Show error toast
4. If valid:
   - Save to database with timestamp
   - Show success toast
   - Update recent entries list
   - Clear text area (or keep if user prefers)
   - Update prompt chip to default
```

### Random Memory

```
1. User taps Random Memory button
2. Button animates (dice roll)
3. Modal slides up from bottom
4. Display random past entry with:
   - Original date
   - Prompt (if used)
   - Full content
5. Show "Another Memory" button
6. User can close modal
```

### Viewing Entry History

```
1. User taps "View All →"
2. Navigate to full history screen
3. Entries sorted by date (newest first)
4. Infinite scroll or pagination
5. Tap entry to view details
```

---

## 🎨 Visual Effects

### Prompt Chip Selection Animation

```css
@keyframes chipSelect {
    0% {
        transform: scale(1);
    }
    50% {
        transform: scale(1.05);
    }
    100% {
        transform: scale(1);
    }
}

.prompt-chip.selected {
    animation: chipSelect 0.2s ease;
}
```

### Save Button Success Animation

```css
@keyframes saveSuccess {
    0% {
        transform: scale(1);
    }
    50% {
        transform: scale(0.95);
    }
    100% {
        transform: scale(1);
        opacity: 0;
    }
}
```

### Text Area Focus Effect

```css
.gratitude-editor:focus-within {
    border-color: #788c5d;
    box-shadow: 0 0 0 3px rgba(120, 140, 93, 0.1);
}
```

### Entry Preview Hover Effect

```css
.entry-preview:hover {
    padding-left: 8px;
    background-color: #FAFAFA;
    transition: all 0.2s ease;
}
```

### Random Memory Dice Roll

```css
@keyframes diceRoll {
    0%, 100% { transform: rotate(0deg); }
    25% { transform: rotate(-15deg); }
    75% { transform: rotate(15deg); }
}

.random-memory:hover .random-icon {
    animation: diceRoll 0.6s ease;
}
```

---

## 📱 Responsive Behavior

### Mobile (< 768px)

```
- Title: 28px (smaller)
- Prompt chips: Full width, wrap to new lines
- Text area: Full width
- Cards: Full width, 16px side padding
- Entry previews: 2 lines max (instead of 3)
- Random memory button: Full width
```

### Tablet (768px - 1024px)

```
- Title: 32px
- Prompt chips: 3 per row
- Text area: Min height 140px
- Cards: 90% width, centered
- Entry previews: 3 lines
- Side padding: 32px
```

### Desktop (> 1024px)

```
- Title: 36px
- Prompt chips: All in one row
- Text area: Min height 160px, max width 600px
- Cards: Max width 600px, centered
- Hover effects enabled
- Keyboard shortcuts (Cmd+S to save)
```

---

## 🎨 Color Tokens Used

```css
/* Prompt Chips */
--chip-bg: #F5F5F5
--chip-border: #E0E0E0
--chip-hover-bg: #F0F5EB
--chip-hover-border: #788c5d
--chip-selected-bg: #788c5d
--chip-selected-text: white

/* Text Area */
--editor-bg: white
--editor-border: #E8E8E8
--editor-focus-border: #788c5d
--editor-focus-shadow: rgba(120, 140, 93, 0.1)

/* Character Count */
--char-count: #888888
--char-count-warning: #FF6B35
--char-count-error: #DC3545

/* Save Button */
--btn-save: #788c5d
--btn-save-hover: #6A7E51
--btn-disabled: #CCCCCC

/* Random Memory */
--random-bg: #FDF5E6
--random-border: #D4AF37
--random-hover-bg: #FFF9ED

/* Entry Previews */
--entry-date: #788c5d
--entry-content: #666666
--entry-hover-bg: #FAFAFA

/* Text */
--text-primary: #333333
--text-secondary: #666666
--text-tertiary: #888888
--text-placeholder: #AAAAAA

/* Backgrounds */
--bg-card: white
--bg-primary: #FDF5E6
--bg-divider: #E8E8E8
```

---

## ✅ Accessibility

### VoiceOver Labels

```
- Prompt chips: "Prompt: Today I'm grateful for"
- Text area: "Gratitude entry text field, 45 of 500 characters"
- Save button: "Save gratitude entry"
- Random memory: "Show a random past gratitude entry"
- Entry preview: "March 4th entry: Today I'm grateful for..."
- View all: "View all gratitude entries"
```

### Color Independence

```
- Use emoji icons in addition to color
- Clear text labels for all actions
- Error messages don't rely solely on color
- Focus states use both color and outline
```

### Tap Targets

```
- Prompt chips: 44×44px minimum tap area
- Save button: 44×44px minimum
- Entry previews: 60px minimum height
- Random memory button: 80px minimum height
```

### Keyboard Navigation

```
- Tab: Navigate between chips, text area, buttons
- Enter/Space: Select prompt chip, save entry
- Escape: Close modals
- Cmd+S: Quick save (desktop)
```

---

## 📊 Data Requirements

```swift
struct GratitudeEntry {
    let id: UUID
    let date: Date
    let content: String
    var promptType: String?
    let createdAt: Date
    var updatedAt: Date
}

enum GratitudePrompt: String, CaseIterable {
    case today = "Today I'm grateful for..."
    case smallJoy = "A small joy I noticed..."
    case moment = "I want to remember this moment..."
    case person = "Someone I appreciate today..."
    case growth = "Something I learned..."
}

struct GratitudeDraft {
    var content: String
    var promptType: GratitudePrompt?
    var lastSaved: Date
}
```

### Validation Rules

```swift
func validateEntry(_ content: String) -> ValidationResult {
    let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
    
    guard trimmed.count >= 10 else {
        return .invalid("Entry must be at least 10 characters")
    }
    
    guard trimmed.count <= 500 else {
        return .invalid("Entry cannot exceed 500 characters")
    }
    
    return .valid
}

func checkExistingEntry(for date: Date) -> Bool {
    // Query database for existing entry on this date
    // Return true if exists
}
```

### Auto-Save Logic

```swift
class GratitudeEditorViewModel: ObservableObject {
    @Published var content: String = ""
    @Published var selectedPrompt: GratitudePrompt?
    
    private var autoSaveTimer: Timer?
    
    init() {
        setupAutoSave()
    }
    
    func setupAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.saveDraft()
        }
    }
    
    func saveDraft() {
        // Save to UserDefaults or temporary storage
        // Don't save to main database until user taps "Save"
    }
}
```

---

## 🚀 Implementation Notes

### SwiftUI Components

```swift
struct GratitudeJournalScreen: View {
    @State private var content: String = ""
    @State private var selectedPrompt: GratitudePrompt?
    @State private var recentEntries: [GratitudeEntry] = []
    @State private var showRandomMemory: Bool = false
    @State private var randomEntry: GratitudeEntry?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TitleSection()
                PromptSelection(selected: $selectedPrompt)
                GratitudeEditor(
                    content: $content,
                    prompt: selectedPrompt,
                    onSave: saveEntry
                )
                RandomMemoryButton {
                    loadRandomEntry()
                }
                RecentEntries(entries: recentEntries)
            }
        }
        .background(Color("ZenCream"))
        .sheet(isPresented: $showRandomMemory) {
            RandomMemoryModal(entry: randomEntry)
        }
        .onAppear {
            loadRecentEntries()
            loadTodaysDraft()
        }
    }
    
    func saveEntry() {
        // Validate content
        // Save to database
        // Show success toast
        // Update recent entries
    }
    
    func loadRandomEntry() {
        // Query database for random entry
        // Show modal
    }
}

struct PromptSelection: View {
    @Binding var selected: GratitudePrompt?
    
    let prompts: [GratitudePrompt] = [.today, .smallJoy, .moment, .person, .growth]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("💡")
                    .font(.system(size: 18))
                Text("Choose a prompt")
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(.gray)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(prompts, id: \.self) { prompt in
                    PromptChip(
                        prompt: prompt,
                        isSelected: selected == prompt
                    ) {
                        selected = prompt
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
}

struct GratitudeEditor: View {
    @Binding var content: String
    let prompt: GratitudePrompt?
    let onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextEditor(text: $content)
                .font(.custom("Poppins-Regular", size: 15))
                .frame(minHeight: 80)
                .padding(20)
            
            Divider()
                .background(Color("DividerGray"))
            
            HStack {
                Text("\(content.count)/500")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(charCountColor)
                
                Spacer()
                
                Button(action: onSave) {
                    Text("Save")
                        .font(.custom("Poppins-SemiBold", size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(isValid ? Color("SageGreen") : Color.gray)
                        .cornerRadius(8)
                }
                .disabled(!isValid)
            }
            .padding(20)
        }
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
    
    var isValid: Bool {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 10 && trimmed.count <= 500
    }
    
    var charCountColor: Color {
        if content.count > 500 { return Color("ErrorRed") }
        if content.count > 450 { return Color("EmberOrange") }
        return Color.gray
    }
}
```

### Toast Notifications

```swift
struct ToastView: View {
    let message: String
    let type: ToastType
    
    var body: some View {
        Text(message)
            .font(.custom("Poppins-Regular", size: 14))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .cornerRadius(8)
    }
    
    var backgroundColor: Color {
        switch type {
        case .success: return Color("SageGreen")
        case .error: return Color("ErrorRed")
        case .info: return Color.gray
        }
    }
}

enum ToastType {
    case success, error, info
}
```

---

## 🖼️ Visual Preview

### Initial State (New Day)

```
Title centered at top
Prompt section with 5 chips
Empty text area with placeholder
Random memory button (dashed border)
Recent entries showing last 3 days
Cream background throughout
```

### After Selecting Prompt

```
"Today I'm grateful for..." chip filled with Sage Green
Other chips unselected (light gray)
Placeholder updates in text area
Cursor focuses automatically
```

### While Writing

```
Text fills the text area
Character count updates (e.g., "45/500")
At 450 chars: count turns orange
Save button enables at 10 chars
Auto-save indicator appears (optional)
```

### After Saving

```
Success toast slides up: "Entry saved! ✨"
Text area clears (or keeps based on preference)
Recent entries updates with new entry at top
Selected prompt resets to default
```

### Random Memory Modal

```
Modal slides up from bottom
Shows past entry:
  - "March 1, 2026" (date)
  - "Today I'm grateful for..." (prompt)
  - Full content text
"Another Memory" button at bottom
Close button (X) in top corner
```

---

## 💡 Microcopy Examples

### Empty State

```
"Start your gratitude journey
Choose a prompt or write freely
Even a small note makes a difference"
```

### Placeholder Text (By Prompt)

```
Today: "Today I'm grateful for..."
Small Joy: "A small joy I noticed..."
Moment: "I want to remember this moment..."
Person: "Someone I appreciate today..."
Growth: "Something I learned..."
```

### Validation Messages

```
< 10 chars: "Write a bit more (at least 10 characters)"
> 500 chars: "Keep it concise (max 500 characters)"
Empty: "What are you grateful for today?"
```

### Success Messages

```
Saved: "Entry saved! ✨"
Updated: "Entry updated! 📝"
Auto-saved: "Draft saved" (subtle indicator)
```

### Random Memory Messages

```
Button: "🎲 Random Memory - Rediscover a past moment"
Empty History: "No memories yet. Start writing to build your collection!"
Modal Title: "From March 1, 2026"
Another Memory: "Show Another Memory →"
```

### Entry Preview Truncation

```
Full: "Today I'm grateful for the warm sunshine that greeted me this morning."
Preview: "Today I'm grateful for the warm sunshine..."
```

---

## 📋 Additional Screens

### Full History Screen

```
┌─────────────────────────────────────────┐
│  ← Gratitude History                    │
├─────────────────────────────────────────┤
│                                         │
│  📅 March 2026                          │
│  ─────────────────────────────────────  │
│  Mar 5                                 │
│  "Today I'm grateful for..."            │
│                                         │
│  Mar 4                                  │
│  "A small joy I noticed..."             │
│                                         │
│  Mar 3                                  │
│  "I want to remember this moment..."    │
│                                         │
│  [Infinite scroll...]                   │
│                                         │
└─────────────────────────────────────────┘
```

### Entry Detail View

```
┌─────────────────────────────────────────┐
│  ← Back                        🗑️  ✏️  │
├─────────────────────────────────────────┤
│                                         │
│  March 4, 2026                          │
│  10:45 AM                               │
│                                         │
│  💡 Today I'm grateful for...           │
│                                         │
│  the warm sunshine that greeted me      │
│  this morning. It reminded me that      │
│  every day is a new beginning. I        │
│  felt peaceful drinking my coffee       │
│  by the window.                         │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  Created: Mar 4, 10:45 AM               │
│  Updated: Mar 4, 11:20 AM               │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🎯 User Flow Diagrams

### New Entry Flow

```
1. Open Gratitude screen
2. See empty text area
3. (Optional) Select prompt chip
4. Type gratitude content
5. See character count update
6. Tap Save button
7. Success toast appears
8. Entry added to recent list
```

### Random Memory Flow

```
1. Tap Random Memory button
2. Modal slides up
3. See past entry with date
4. (Optional) Tap "Another Memory"
5. New random entry appears
6. Tap Close (X) to dismiss
```

### View History Flow

```
1. Tap "View All →" button
2. Navigate to history screen
3. Scroll through past entries
4. Tap entry to view details
5. (Optional) Edit or delete
6. Tap Back to return
```

---

**Mockup Status**: ✅ COMPLETE  
**Ready for**: Phoenix Implementation  
**Design File**: SVG exports to be created separately

---

_Created by Flare — Mori Gratitude Journal Screen v1.0_
