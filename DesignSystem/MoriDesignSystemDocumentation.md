# Mori Design System v1.0 - Complete Implementation

## Overview

The Mori Design System v1.0 is a comprehensive, warm-toned design system built for mortality awareness applications. It follows the core principle of "Warm Mortality Awareness" and provides a complete set of UI components, design tokens, and guidelines for creating consistent and beautiful user interfaces.

## Design Philosophy

### Core Principles
- **Warm & Inviting**: Soft, warm colors create a comfortable environment
- **Minimalist Clarity**: Clean, uncluttered interfaces focus on content
- **Accessibility First**: All components built with accessibility in mind
- **Consistent Spacing**: 4pt grid system for visual harmony
- **Purposeful Animation**: Gentle, meaningful interactions

### Color System
The color palette is inspired by warm, natural tones:

- **Cream White** (`#FFF8E7`) - Main background
- **Soft Cream** (`#F5EFE0`) - Card backgrounds
- **Warm Gray** (`#D4CFC4`) - Borders and dividers
- **Soft Taupe** (`#8B7355`) - Secondary text/icons
- **Warm Charcoal** (`#4A4A4A`) - Primary text
- **Deep Espresso** (`#2B2520`) - High contrast text
- **Accent Amber** (`#D4A574`) - Focus/active states
- **Soft Sage** (`#A8B5A0`) - Success/growth states
- **Warm Clay** (`#C4846C`) - Missed/negative states
- **Morning Gold** (`#E8C78A`) - Celebration states

## Component Architecture

### 1. Design Tokens (`MoriDesignTokens.swift`)

#### Colors
```swift
// Core colors
MoriColors.creamWhite      // Main background
MoriColors.softCream       // Card backgrounds  
MoriColors.warmCharcoal     // Primary text
MoriColors.accentAmber     // Accent color

// Semantic colors
MoriColors.success         // Green for positive actions
MoriColors.warning         // Gold for warnings
MoriColors.neutral         // Neutral gray

// Adaptive colors
MoriColors.background(for: .light/dark)  // Theme-aware background
```

#### Typography
```swift
MoriTypography.display     // 48pt Light (big numbers)
MoriTypography.title1      // 28pt Semibold (screen titles)
MoriTypography.title2      // 22pt Semibold (section headers)
MoriTypography.body         // 17pt Regular (main content)
MoriTypography.callout      // 16pt Regular (secondary info)
MoriTypography.caption      // 14pt Regular (labels)
MoriTypography.micro       // 12pt Medium (timestamps)
```

#### Spacing
```swift
MoriSpacing.space1  // 4pt   - Micro gaps
MoriSpacing.space2  // 8pt   - Tight spacing
MoriSpacing.space3  // 12pt  - Default spacing
MoriSpacing.space4  // 16pt  - Comfortable
MoriSpacing.space5  // 24pt  - Section gaps
MoriSpacing.space6  // 32pt  - Large gaps
MoriSpacing.space7  // 48pt  - Screen margins
MoriSpacing.space8  // 64pt  - Major sections
```

### 2. Layout Components (`MoriCompleteComponents.swift`)

#### Grid System
```swift
// Basic grid
MoriGrid(columns: 2, spacing: MoriSpacing.space3) {
    // Grid items
}

// Responsive grid
MoriResponsiveGrid {
    // Responsive items
}
```

#### Stack Components
```swift
// Horizontal stack
MoriHStack(spacing: MoriSpacing.space3) {
    // Horizontal content
}

// Vertical stack
MoriVStack(spacing: MoriSpacing.space3) {
    // Vertical content
}
```

### 3. Core Components

#### Cards
```swift
MoriCard {
    Content()
}

// With highlighting
MoriCard(isHighlighted: true) {
    Content()
}

// Interactive with tap animation
MoriCard(isInteractive: true) {
    Content()
}
```

#### Buttons
```swift
// Primary button
MoriButton(title: "Save") {
    action()
}

// Secondary button
MoriSecondaryButton(title: "Cancel") {
    action()
}

// Icon button
MoriIconButton(systemName: "plus") {
    action()
}
```

#### Form Components
```swift
// Text field
MoriTextField(text: $text, placeholder: "Enter name")

// Checkbox
MoriCheckbox(isSelected: $isSelected, label: "Remember me")

// Toggle
MoriToggle(isOn: $isOn, label: "Enable notifications")

// Radio group
MoriRadioGroup(
    selection: $selection,
    options: ["Option 1", "Option 2", "Option 3"],
    labelForOption: { $0 }
)

// Segmented control
MoriSegmentedControl(
    selection: $selection,
    options: ["Day", "Week", "Month"],
    labelForOption: { $0 }
)
```

#### Progress Components
```swift
// Progress bar
MoriProgressBar(progress: 0.6)

// Circular progress
MoriCircularProgress(progress: 0.75, size: 80)

// Loading spinner
MoriActivityIndicator(text: "Loading...")

// Simple spinner
MoriLoadingSpinner(size: 24)
```

#### Navigation Components
```swift
// Tab bar
MoriTabBar(selectedTab: $selectedTab)

// Navigation bar
MoriNavigationBar(
    title: "Profile",
    leftIcon: "chevron.left",
    rightIcon: "ellipsis"
)
```

#### State Components
```swift
// Empty state
MoriEmptyState(
    icon: "book.closed",
    title: "No content",
    message: "Get started by adding something",
    buttonTitle: "Add",
    buttonAction: { action() }
)

// Error state
MoriErrorState(
    message: "Connection failed",
    retryAction: { action() }
)

// Countdown display
MoriCountdownDisplay(days: 12847, subtitle: "days remaining")
```

### 4. View Modifiers (`MoriViewModifiers.swift`)

#### Styling Modifiers
```swift
// Text styles
Text("Title").moriTitle()
Text("Body").moriBody()
Text("Caption").moriCaption()

// Card styling
Content().moriCard()
Content().moriCardPadding()

// Color modifiers
Text("Primary").moriTextPrimary()
Text("Secondary").moriTextSecondary()
Text("Accent").moriTextAccent()
```

#### Animation Modifiers
```swift
// Fade in animation
Content().moriFadeIn()

// Tap animation
Button("Tap me").moriTapAnimation()

// Conditional animation
Content().moriAnimation(MoriAnimation.standard, value: isTapped)
```

### 5. Theme System

#### Theme Configuration
```swift
// Light theme
let lightTheme = MoriTheme.light

// Dark theme
let darkTheme = MoriTheme.dark

// Apply theme
content.background(theme.background)
      .foregroundColor(theme.primary)
```

## Usage Patterns

### 1. Screen Layout Pattern
```swift
struct ExampleScreen: View {
    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar
            MoriNavigationBar(title: "Example") {
                // Navigation actions
            }
            
            // Content
            ScrollView {
                VStack(spacing: MoriSpacing.space5) {
                    // Cards, buttons, etc.
                    MoriCard {
                        Content()
                    }
                    
                    MoriButton(title: "Action") {
                        action()
                    }
                }
                .padding(MoriSpacing.space6)
            }
            
            // Tab bar
            MoriTabBar(selectedTab: $selectedTab)
        }
        .background(MoriColors.creamWhite)
    }
}
```

### 2. Form Pattern
```swift
struct FormExample: View {
    @State var name = ""
    @State var email = ""
    @State var newsletter = false
    @State var accountType = "personal"
    
    var body: some View {
        VStack(spacing: MoriSpacing.space5) {
            MoriTextField(text: $name, placeholder: "Full name")
            
            MoriTextField(text: $email, placeholder: "Email address")
            
            MoriToggle(isOn: $newsletter, label: "Subscribe to newsletter")
            
            MoriSegmentedControl(
                selection: $accountType,
                options: ["Personal", "Business"],
                labelForOption: { $0 }
            )
            
            MoriButton(title: "Create Account") {
                submitForm()
            }
        }
        .padding(MoriSpacing.space6)
        .background(MoriColors.softCream)
        .cornerRadius(MoriCornerRadius.card)
    }
}
```

## Animation Guidelines

### Default Animation Values
- **Standard**: 0.3s ease-out (comfortable)
- **Fast**: 0.2s ease-out (quick interactions)
- **Slow**: 0.5s ease-out (transitions)
- **Spring**: Spring response 0.3s, damping 0.7 (playful)
- **Gentle**: 2.0s ease-in-out infinite (celebrations)

### Usage Rules
- Use standard animations for most interactions
- Use fast animations for button taps
- Use spring animations sparingly for playful elements
- Use gentle animations only for special states
- Always respect reduce motion accessibility settings

## Accessibility Features

### Built-in Support
- **Minimum Hit Targets**: 44pt minimum tap size
- **Reduce Motion**: Respects system accessibility settings
- **Color Contrast**: WCAG AA compliant color combinations
- **Semantic Labels**: Proper accessibility labels on components
- **Focus Management**: Clear focus indicators

### Customization
```swift
// Apply minimum hit target
Button("Action")
    .moriHitTarget(minimum: 48)

// Conditional animation
Content()
    .moriAnimation(MoriAnimation.standard, value: value)
```

## Performance Considerations

### Optimization Tips
- Use LazyVGrid/LazyHGrid for large lists
- Minimize animation complexity
- Use appropriate shadow values
- Leverage SwiftUI's view builder efficiency
- Consider view modifiers for reusability

### Memory Management
- Avoid creating unnecessary views in loops
- Use @State for mutable data
- Minimize @Binding usage when possible
- Use efficient layouts to prevent over-composition

## Version History

### v1.0 (Current)
- Complete design token system
- Full component library
- Layout system implementation
- Form components
- Progress indicators
- Modal system
- Theme system
- Comprehensive documentation

## Future Considerations

### v1.1 Planned Features
- Dark mode improvements
- Additional animation types
- Icon system integration
- Testing utilities
- Design system playground

### v2.0 Roadmap
- Multi-platform support
- Advanced animation system
- Voice-over improvements
- Internationalization support
- Advanced theming

## Contributing

### Guidelines
- Follow existing code patterns
- Use proper documentation
- Test on multiple devices
- Respect accessibility standards
- Maintain consistency

### Code Style
- Use SwiftLint when available
- Follow Swift naming conventions
- Document public APIs
- Use view builders for composability
- Maintain consistency with existing components

## Support

For issues, questions, or contributions, please refer to the project documentation or contact the design team.

---

*The Mori Design System v1.0 is designed to be flexible, accessible, and maintainable while maintaining the warm, thoughtful aesthetic appropriate for a mortality awareness application.*
