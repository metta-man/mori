# Mori Design System v2 - Botanical Watercolor

## Overview

The current app design is a botanical watercolor system: textured watercolor paper, quiet botanical washes, deep leaf ink, sage highlights, and generous quiet space. Brand/logo text, seedling badges, circular emblems, and repeated leaf marks should stay out of primary app surfaces unless the OS or an external flow requires the app name.

## Design Philosophy

### Core Principles
- **Botanical Paper**: Surfaces should feel like watercolor on paper, not flat cream panels
- **Action Over Logo**: UI copy should name the user action, not repeatedly name the app
- **Logo Is Not Texture**: The app icon, wordmark, paper-linework mark, seedling badge, circular emblem, and leaf mark belong to OS, store, or external brand surfaces only. In-app cards use paper, ink, and breathing room, not a repeated brand signature.
- **Material Over Marks**: Cards default to `MoriPlainWatercolorCardBackground`, backed by an opaque watercolor-paper base and the dedicated `moriCardPaperWash` bitmap: quiet watercolor paper grain with no repeated logo, app-icon, wordmark, paper-linework, seed-circle, seedling badge, circular emblem, or leaf-mark watermarks. Botanical painting belongs at the screen/root layer through `MoriPaperBackground`, or as a rare hero/support accent; ordinary repeated cards stay quiet instead of letting screen-level art bleed through them.
- **Botanical Without Billboarding**: Accent boxes may use generated paper-material variants such as `moriCardSageWash`, `moriCardWarmWash`, or `moriCardCoolWash`. These are faint edge/corner watercolor paper washes, not logo, badge, seedling, circular emblem, or wordmark backgrounds.
- **Bitmap Actions**: Primary action surfaces use the dedicated `moriButtonWash` bitmap so buttons still feel like watercolor on paper, not flat synthetic slabs or brand badges.
- **No Card Backdrop API**: `moriSanctuaryCard` and `moriSanctuaryBox` intentionally do not accept `backdrop`, `showsWave`, or `showsTexture` parameters. Screen-level botanical paintings belong in `MoriPaperBackground`; hero wash belongs in `MoriWatercolorHeroWash`; ordinary cards stay plain paper.
- **Minimalist Clarity**: Clean, uncluttered interfaces focus on the next useful action
- **Accessibility First**: All components built with accessibility in mind
- **Consistent Spacing**: 4pt grid system for visual harmony
- **Purposeful Animation**: Gentle, meaningful interactions

### Color System
The palette now follows the supplied watercolor paper references:

- **Watercolor Paper** (`#FBF7EF`) - Main background
- **Seed Paper** (`#FFFDF8`) - Card backgrounds
- **Paper Line** (`#DDD6C8`) - Borders and dividers
- **Muted Leaf Ink** (`#5F6D64`) - Secondary text/icons
- **Deep Leaf Ink** (`#14392F`) - Primary text
- **Deep Canopy** (`#0F2E27`) - High contrast text
- **Leaf Wash** (`#758C6B`) - Focus/active states
- **Soft Sage** (`#8FA883`) - Success/growth states
- **Soft Clay** (`#B9856D`) - Warning/error states
- **Seed Ochre** (`#D8B86F`) - Celebration states

## Component Architecture

### 1. Design Tokens (`MoriDesignTokens.swift`)

#### Colors
```swift
// Active botanical watercolor colors
MoriColors.sanctuaryPaper       // Root watercolor paper
MoriColors.sanctuarySurface     // Quiet card paper
MoriColors.sanctuaryInk         // Primary deep leaf ink
MoriColors.sanctuaryMuted       // Secondary text/icons
MoriColors.sanctuarySage        // Focus and selected controls
MoriColors.sanctuaryFern        // Growth accents
MoriColors.sanctuaryLine        // Hairline borders
MoriColors.sanctuaryShadow      // Paper shadow
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

### 2. Core Components

#### Paper Surfaces
```swift
MoriPaperBackground(variant: .today) {
    Content()
}

Content()
    .moriSanctuaryCard()

BotanicalPanel {
    Content()
}
```

#### Buttons
Primary buttons use `MoriGeneratedArtImage(art: .buttonWash, contentMode: .fill)` for a restrained watercolor-paper material. This is an action material, not logo art, and it should not introduce app icons, wordmarks, seedling badges, circular emblems, or repeated leaf-mark textures.

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
MoriIconButton(icon: .plus) {
    action()
}
```

#### Form Components
```swift
TextField("Enter name", text: $text)
    .padding(MoriSpacing.inputPadding)
    .moriSanctuaryBox(
        cornerRadius: MoriCornerRadius.input,
        padding: 0,
        castsShadow: false
    )

Toggle("Enable notifications", isOn: $isOn)
    .tint(MoriColors.sanctuarySage)

Picker("Mode", selection: $selection) {
    Text("Day").tag("day")
    Text("Week").tag("week")
    Text("Month").tag("month")
}
.pickerStyle(.segmented)
```

#### Progress Components
```swift
MoriBotanicalProgressBar(value: 0.6)

MoriTimerProgressRing(progress: 0.75)

ProgressView("Loading...")
    .tint(MoriColors.sanctuarySage)

MoriSkeleton(width: 180, height: 20)
```

#### App Shell Components
```swift
@State private var selectedTab = AppTab.defaultTab

// App shell tab bar
MoriBottomTabBarOverlay(
    selectedTab: selectedTab,
    onSelectTab: { selectedTab = $0 }
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

// Compact metric tile
MoriMetricTile(title: "quiet minutes", value: "24", detail: "reclaimed before feeds")
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
    @State private var selectedTab = AppTab.defaultTab

    var body: some View {
        ZStack(alignment: .bottom) {
            MoriPaperBackground {
                ScrollView {
                    VStack(spacing: MoriSpacing.space5) {
                        MoriRootHeader(
                            title: "Example",
                            subtitle: "One focused surface."
                        )

                        Content()
                            .moriSanctuaryCard()

                        OrganicCard {
                            Content()
                        }

                        MoriButton(title: "Action") {
                            action()
                        }
                    }
                    .padding(MoriSpacing.space6)
                    .padding(.bottom, MoriMainTabBarMetrics.scrollBottomInset)
                }
            }

            MoriBottomTabBarOverlay(
                selectedTab: selectedTab,
                onSelectTab: { selectedTab = $0 }
            )
        }
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
            TextField("Full name", text: $name)
                .padding(MoriSpacing.inputPadding)
                .moriSanctuaryBox(
                    cornerRadius: MoriCornerRadius.input,
                    padding: 0,
                    castsShadow: false
                )

            TextField("Email address", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .padding(MoriSpacing.inputPadding)
                .moriSanctuaryBox(
                    cornerRadius: MoriCornerRadius.input,
                    padding: 0,
                    castsShadow: false
                )

            Toggle("Subscribe to newsletter", isOn: $newsletter)
                .tint(MoriColors.sanctuarySage)

            Picker("Account type", selection: $accountType) {
                Text("Personal").tag("personal")
                Text("Business").tag("business")
            }
            .pickerStyle(.segmented)
            
            MoriButton(title: "Create Account") {
                submitForm()
            }
        }
        .padding(MoriSpacing.space6)
        .moriSanctuaryCard()
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
- **Color Contrast**: token-level WCAG AA text combinations guarded by `scripts/check_color_contrast_tokens.sh`
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

## Current Status

### v2 Botanical Watercolor
- Active design direction: textured watercolor paper, quiet botanical washes, deep leaf ink, and generated bitmap assets.
- Active app shell: custom root navigation with `MoriPaperBackground`, `MoriRootHeader`, and `MoriBottomTabBarOverlay`. Screen-level watercolor botanical paintings live in `MoriPaperBackground`, not repeated inside every card.
- Active icon rule: use Mori bitmap icons for primary app surfaces; add a generated bitmap asset when a matching icon is missing.
- Active visual rule: cards default to `MoriPlainWatercolorCardBackground` with the dedicated `moriCardPaperWash` bitmap, no repeated logo, app-icon, wordmark, paper-linework, seed-circle, seedling badge, circular emblem, or leaf-mark watermark. The shared card/box API has no `backdrop`, `showsWave`, or `showsTexture` parameters; use `MoriWatercolorHeroWash` only when a specific hero or anchor moment needs hierarchy, and never use brand art as surface decoration.
- Active action rule: primary button materials use `moriButtonWash`, compiled with the app and extensions alongside the screen, card, widget, and icon bitmap assets.
- Completion remains unclaimed until simulator screenshots cover the main surfaces and the active source, docs, and compiled artifact gates pass without exceptions.

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

*The Mori Design System v2 is designed to be flexible, accessible, and maintainable while maintaining the quiet botanical watercolor aesthetic used across the app.*
