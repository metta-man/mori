import SwiftUI
import UIKit

struct MoriMainTabBarHiddenPreferenceKey: PreferenceKey {
    static let defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

enum MoriMainTabBarMetrics {
    static let barHeight: CGFloat = 58
    static let reservedBottomInset: CGFloat = 70
    static let overlayHeight: CGFloat = reservedBottomInset
    static let scrollBottomInset: CGFloat = reservedBottomInset + 8
}

enum MoriRootScreenMetrics {
    static let minimumTopInset: CGFloat = 112
    static let safeAreaBreathingRoom: CGFloat = 24
    static let visibleScrollTopOffset: CGFloat = 18
    static let headerContentGap: CGFloat = 18

    static func topInset(for safeAreaTop: CGFloat) -> CGFloat {
        max(minimumTopInset, safeAreaTop + safeAreaBreathingRoom)
    }
}

struct MoriKeyboardDismissAction {
    static let system = MoriKeyboardDismissAction {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private let handler: () -> Void

    init(_ handler: @escaping () -> Void) {
        self.handler = handler
    }

    func callAsFunction() {
        handler()
    }
}

// MARK: - Mori Text Styles
extension View {
    func moriTitle() -> some View {
        self.font(MoriTypography.title1)
            .foregroundColor(MoriColors.botanicalInk)
    }
    
    func moriBody() -> some View {
        self.font(MoriTypography.body)
            .foregroundColor(MoriColors.botanicalInk)
    }
    
    func moriCaption() -> some View {
        self.font(MoriTypography.caption)
            .foregroundColor(MoriColors.botanicalMuted)
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
    func body(content: Content) -> some View {
        content
    }
}

// MARK: - Mori Color Modifiers
extension View {
    /// Apply Mori's primary light sanctuary theme across the app.
    func moriAppTheme() -> some View {
        self
            .tint(MoriColors.botanicalInk)
            .preferredColorScheme(.light)
    }

    /// Add a consistent keyboard accessory so text input can always be dismissed.
    func moriKeyboardDoneToolbar(doneTitle: String = "Done") -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button {
                    MoriKeyboardDismissAction.system()
                } label: {
                    HStack(spacing: 5) {
                        MoriBitmapIconImage(icon: .chevron, size: 13, opacity: 0.78)
                            .rotationEffect(.degrees(90))

                        Text(MoriL10n.display(doneTitle))
                    }
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(MoriColors.botanicalInk)
                .accessibilityLabel("Dismiss keyboard")
            }
        }
    }

    /// Hide the root app tab bar for immersive pushed practice flows.
    func moriHidesMainTabBar() -> some View {
        self
            .toolbar(.hidden, for: .tabBar)
            .preference(key: MoriMainTabBarHiddenPreferenceKey.self, value: true)
    }

    /// Keep SwiftUI forms aligned with Mori's light paper UI, independent of the device appearance.
    func moriSettingsForm() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background {
                MoriPaperBackground(variant: .settings) {
                    Color.clear
                }
            }
            .tint(MoriColors.botanicalInk)
            .listRowSeparatorTint(MoriColors.botanicalLine.opacity(0.7))
            .environment(\.colorScheme, .light)
    }

    /// Apply primary text color
    func moriTextPrimary() -> some View {
        self.foregroundColor(MoriColors.botanicalInk)
    }
    
    /// Apply secondary text color
    func moriTextSecondary() -> some View {
        self.foregroundColor(MoriColors.botanicalMuted)
    }
    
    /// Apply accent text color
    func moriTextAccent() -> some View {
        self.foregroundColor(MoriColors.botanicalMoss)
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

    /// Apply an animation that reacts to the current SwiftUI Reduce Motion environment.
    func moriReduceMotionAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        modifier(MoriReduceMotionAnimationModifier(animation: animation, value: value))
    }
}

private struct MoriReduceMotionAnimationModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let animation: Animation?
    let value: Value

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

extension EnvironmentValues {
    var moriAllowsMotion: Bool {
        !accessibilityReduceMotion
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
            
            MoriButton(title: "Primary Button") {}

            MoriSecondaryButton(title: "Secondary Button") {}

            Text("Card Content")
                .moriSanctuaryCard()
        }
        .padding()
    }
}
#endif
