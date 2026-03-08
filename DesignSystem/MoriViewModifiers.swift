import SwiftUI

// MARK: - Mori Card Style
struct MoriCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(MoriColors.cardBackground)
            .cornerRadius(MoriCornerRadius.card)
            .shadow(color: Color.black.opacity(MoriShadow.cardOpacity), radius: MoriShadow.cardRadius, x: 0, y: MoriShadow.cardY)
    }
}

extension View {
    func moriCard() -> some View {
        modifier(MoriCardStyle())
    }
}

// MARK: - Mori Button Style
struct MoriButtonStyle: ButtonStyle {
    var isPrimary: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(MoriTypography.body)
            .foregroundColor(isPrimary ? .white : MoriColors.warmCharcoal)
            .padding(.vertical, MoriSpacing.buttonVertical)
            .padding(.horizontal, MoriSpacing.buttonHorizontal)
            .background(isPrimary ? MoriColors.accentAmber : Color.clear)
            .cornerRadius(MoriCornerRadius.button)
            .scaleEffect(configuration.isPressed ? MoriAnimation.buttonTapScale : 1.0)
            .animation(MoriAnimation.standard, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == MoriButtonStyle {
    static var mori: MoriButtonStyle {
        MoriButtonStyle()
    }
    
    static func mori(isPrimary: Bool) -> MoriButtonStyle {
        MoriButtonStyle(isPrimary: isPrimary)
    }
}

// MARK: - Mori Text Styles
extension View {
    func moriTitle() -> some View {
        self.font(MoriTypography.title1)
            .foregroundColor(MoriColors.warmCharcoal)
    }
    
    func moriBody() -> some View {
        self.font(MoriTypography.body)
            .foregroundColor(MoriColors.warmCharcoal)
    }
    
    func moriCaption() -> some View {
        self.font(MoriTypography.caption)
            .foregroundColor(MoriColors.softTaupe)
    }
}

// MARK: - Mori Animation Modifiers
extension View {
    /// Apply standard Mori fade-in animation
    func moriFadeIn(delay: Double = 0) -> some View {
        self
            .opacity(0)
            .offset(y: 8)
            .animation(MoriAnimation.standard, value: delay)
    }
    
    /// Apply tap press animation
    func moriTapAnimation() -> some View {
        self.modifier(MoriTapAnimationModifier())
    }
}

struct MoriTapAnimationModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? MoriAnimation.buttonTapScale : 1.0)
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

// MARK: - Mori Color Modifiers
extension View {
    /// Apply primary text color
    func moriTextPrimary() -> some View {
        self.foregroundColor(MoriColors.warmCharcoal)
    }
    
    /// Apply secondary text color
    func moriTextSecondary() -> some View {
        self.foregroundColor(MoriColors.softTaupe)
    }
    
    /// Apply accent text color
    func moriTextAccent() -> some View {
        self.foregroundColor(MoriColors.accentAmber)
    }
}

// MARK: - Mori Spacing Modifiers
extension View {
    /// Apply standard card padding
    func moriCardPadding() -> some View {
        self.padding(MoriSpacing.cardPadding)
    }
    
    /// Apply screen horizontal margins
    func moriScreenPadding() -> some View {
        self.padding(.horizontal, MoriSpacing.screenHorizontal)
    }
}

// MARK: - Accessibility Modifiers
extension View {
    /// Apply minimum tap target
    func moriHitTarget(minimum: CGFloat = MoriHitTarget.minimum) -> some View {
        self.frame(minWidth: minimum, minHeight: minimum)
    }
}

// MARK: - Reduce Motion Support
extension View {
    /// Conditionally apply animation based on accessibility settings
    @ViewBuilder
    func moriAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            self.animation(nil, value: value)
        } else {
            self.animation(animation, value: value)
        }
    }
}

// MARK: - Preview
#if DEBUG
struct MoriViewModifiers_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Mori Design System")
                .moriTitle()
            
            Text("Body text example")
                .moriBody()
            
            Text("Caption text")
                .moriCaption()
            
            Button("Primary Button") {}
                .buttonStyle(.mori)
            
            Button("Secondary Button") {}
                .buttonStyle(.mori(isPrimary: false))
            
            Text("Card Content")
                .moriCard()
                .moriCardPadding()
        }
        .padding()
    }
}
#endif
