//
//  MoriComponents.swift
//  Mori
//
//  Core UI components based on Flare's design system
//

import SwiftUI

// MARK: - Mori Card
/// Base card component with warm cream styling
struct MoriCard<Content: View>: View {
    let content: Content
    var isHighlighted: Bool = false
    var isInteractive: Bool = false
    
    @State private var isPressed = false
    
    init(
        isHighlighted: Bool = false,
        isInteractive: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.isHighlighted = isHighlighted
        self.isInteractive = isInteractive
    }
    
    var body: some View {
        content
            .padding(MoriSpacing.cardPadding)
            .background(MoriColors.surface(for: .light))
            .cornerRadius(MoriCornerRadius.card)
            .shadow(
                color: Color.black.opacity(MoriShadow.cardOpacity),
                radius: MoriShadow.cardRadius,
                y: MoriShadow.cardY
            )
            .overlay(
                RoundedRectangle(cornerRadius: MoriCornerRadius.card)
                    .stroke(
                        isHighlighted ? MoriColors.accentAmber : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(MoriAnimation.standard, value: isPressed)
            .onTapGesture {
                if isInteractive {
                    withAnimation(MoriAnimation.standard) {
                        isPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(MoriAnimation.standard) {
                            isPressed = false
                        }
                    }
                }
            }
    }
}

// MARK: - Mori Primary Button
/// Primary action button with amber accent
struct MoriButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(MoriColors.deepEspresso)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MoriSpacing.buttonVertical)
                .background(
                    isEnabled ? MoriColors.accentAmber : MoriColors.warmGray
                )
                .cornerRadius(MoriCornerRadius.button)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? MoriAnimation.buttonTapScale : 1.0)
        .animation(MoriAnimation.fast, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if isEnabled {
                        withAnimation(MoriAnimation.fast) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(MoriAnimation.fast) {
                        isPressed = false
                    }
                }
        )
        .disabled(!isEnabled)
    }
}

// MARK: - Mori Secondary Button
/// Secondary action button with outline style
struct MoriSecondaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(isEnabled ? MoriColors.softTaupe : MoriColors.warmGray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MoriSpacing.buttonVertical)
                .background(MoriColors.softCream)
                .overlay(
                    RoundedRectangle(cornerRadius: MoriCornerRadius.button)
                        .stroke(
                            isEnabled ? MoriColors.warmGray : MoriColors.warmGray.opacity(0.5),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? MoriAnimation.buttonTapScale : 1.0)
        .animation(MoriAnimation.fast, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if isEnabled {
                        withAnimation(MoriAnimation.fast) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(MoriAnimation.fast) {
                        isPressed = false
                    }
                }
        )
        .disabled(!isEnabled)
    }
}

// MARK: - Mori Text Field
/// Text input field with warm styling
struct MoriTextField: View {
    @Binding var text: String
    let placeholder: String
    var isSecure: Bool = false
    
    @FocusState private var isFocused: Bool
    
    @ViewBuilder
    var body: some View {
        if isSecure {
            SecureField(placeholder, text: $text)
                .font(.system(size: 17))
                .foregroundColor(MoriColors.warmCharcoal)
                .padding(MoriSpacing.inputPadding)
                .background(Color.white)
                .cornerRadius(MoriCornerRadius.input)
                .overlay(
                    RoundedRectangle(cornerRadius: MoriCornerRadius.input)
                        .stroke(
                            isFocused ? MoriColors.accentAmber : MoriColors.warmGray,
                            lineWidth: 1
                        )
                )
                .focused($isFocused)
        } else {
            TextField(placeholder, text: $text)
                .font(.system(size: 17))
                .foregroundColor(MoriColors.warmCharcoal)
                .padding(MoriSpacing.inputPadding)
                .background(Color.white)
                .cornerRadius(MoriCornerRadius.input)
                .overlay(
                    RoundedRectangle(cornerRadius: MoriCornerRadius.input)
                        .stroke(
                            isFocused ? MoriColors.accentAmber : MoriColors.warmGray,
                            lineWidth: 1
                        )
                )
                .focused($isFocused)
        }
    }
}

// MARK: - Mori Icon Button
/// Circular icon button for actions
struct MoriIconButton: View {
    let systemName: String
    let action: () -> Void
    var size: CGFloat = 44
    var iconSize: CGFloat = 24
    var isActive: Bool = false
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(isActive ? MoriColors.accentAmber : MoriColors.softTaupe)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(isActive ? MoriColors.accentAmber.opacity(0.1) : Color.clear)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(MoriAnimation.fast, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(MoriAnimation.fast) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(MoriAnimation.fast) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Mori Tab Bar Item
/// Tab bar item with icon and optional label
struct MoriTabItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: MoriSpacing.space1) {
                Image(systemName: icon)
                    .font(.system(size: MoriIconSize.tabBar, weight: .medium))
                    .foregroundColor(isSelected ? MoriColors.accentAmber : MoriColors.softTaupe)
                
                Text(label)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(isSelected ? MoriColors.accentAmber : MoriColors.softTaupe)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MoriSpacing.space2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Mori Empty State
/// Empty state view with icon, title, and action
struct MoriEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        buttonTitle: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }
    
    var body: some View {
        VStack(spacing: MoriSpacing.space4) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(MoriColors.softTaupe.opacity(0.6))
            
            Text(title)
                .font(MoriTypography.title2)
                .foregroundColor(MoriColors.warmCharcoal)
            
            Text(message)
                .font(MoriTypography.body)
                .foregroundColor(MoriColors.softTaupe)
                .multilineTextAlignment(.center)
            
            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                MoriButton(title: buttonTitle, action: buttonAction)
                    .padding(.horizontal, MoriSpacing.space7)
                    .padding(.top, MoriSpacing.space3)
            }
        }
        .padding(MoriSpacing.space6)
    }
}

// MARK: - Mori Loading State
/// Skeleton loading placeholder
struct MoriSkeleton: View {
    var width: CGFloat? = nil
    var height: CGFloat = 20
    
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: MoriCornerRadius.small)
            .fill(MoriColors.warmGray.opacity(0.3))
            .frame(width: width, height: height)
            .opacity(isAnimating ? 0.6 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Mori Error State
/// Error state with retry option
struct MoriErrorState: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: MoriSpacing.space4) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundColor(MoriColors.softTaupe.opacity(0.6))
            
            Text("網絡有點不穩定")
                .font(MoriTypography.title2)
                .foregroundColor(MoriColors.warmCharcoal)
            
            Text(message)
                .font(MoriTypography.body)
                .foregroundColor(MoriColors.softTaupe)
                .multilineTextAlignment(.center)
            
            MoriSecondaryButton(title: "重試", action: retryAction)
                .padding(.horizontal, MoriSpacing.space7)
                .padding(.top, MoriSpacing.space3)
        }
        .padding(MoriSpacing.space6)
    }
}

// MARK: - Mori Countdown Display
/// Large countdown number display
struct MoriCountdownDisplay: View {
    let days: Int
    var subtitle: String? = nil
    
    var body: some View {
        VStack(spacing: MoriSpacing.space2) {
            Text("\(days)")
                .font(MoriTypography.largeNumber)
                .foregroundColor(MoriColors.warmCharcoal)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(MoriTypography.caption)
                    .foregroundColor(MoriColors.softTaupe)
            }
        }
    }
}

// MARK: - Mori Habit Button
/// Habit done/missed toggle button
struct MoriHabitButton: View {
    let isDone: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isDone ? "checkmark.circle.fill" : "minus.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(isDone ? MoriColors.softSage : MoriColors.warmClay)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(MoriAnimation.fast, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(MoriAnimation.fast) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(MoriAnimation.fast) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Preview Providers
#if DEBUG
struct MoriComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            MoriCard {
                Text("Card Content")
                    .font(MoriTypography.body)
            }
            
            MoriButton(title: "Primary Button") {
                print("Tapped")
            }
            
            MoriSecondaryButton(title: "Secondary Button") {
                print("Tapped")
            }
            
            MoriTextField(text: .constant(""), placeholder: "Enter text")
            
            MoriEmptyState(
                icon: "book.closed",
                title: "開始你的第一篇日記",
                message: "記錄你的想法和感受",
                buttonTitle: "寫日記"
            ) {
                print("Tapped")
            }
            
            MoriCountdownDisplay(days: 12847, subtitle: "days remaining")
            
            HStack(spacing: 20) {
                MoriHabitButton(isDone: true) { }
                MoriHabitButton(isDone: false) { }
            }
        }
        .padding()
        .background(MoriColors.creamWhite)
    }
}
#endif
