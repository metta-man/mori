import SwiftUI

struct MoriEmptyState: View {
    let icon: MoriBitmapIcon
    let title: String
    let message: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?

    init(
        icon: MoriBitmapIcon,
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
            MoriBitmapIconImage(icon: icon, size: 48, opacity: 0.72)

            Text(MoriL10n.display(title))
                .font(MoriTypography.title2)
                .foregroundColor(MoriColors.botanicalInk)

            Text(MoriL10n.display(message))
                .font(MoriTypography.body)
                .foregroundColor(MoriColors.botanicalMuted)
                .multilineTextAlignment(.center)

            if let buttonTitle, let buttonAction {
                MoriButton(title: buttonTitle, action: buttonAction)
                    .padding(.horizontal, MoriSpacing.space7)
                    .padding(.top, MoriSpacing.space3)
            }
        }
        .padding(MoriSpacing.space6)
    }
}

struct MoriSkeleton: View {
    var width: CGFloat? = nil
    var height: CGFloat = 20

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: MoriCornerRadius.small)
            .fill(MoriColors.botanicalLine.opacity(0.44))
            .frame(width: width, height: height)
            .opacity(reduceMotion ? 1.0 : (isAnimating ? 0.6 : 1.0))
            .moriReduceMotionAnimation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                guard !reduceMotion else {
                    isAnimating = false
                    return
                }
                isAnimating = true
            }
            .onChange(of: reduceMotion) { shouldReduceMotion in
                isAnimating = !shouldReduceMotion
            }
    }
}

struct MoriErrorState: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: MoriSpacing.space4) {
            MoriBitmapIconImage(icon: .refresh, size: 48, opacity: 0.72)

            Text("The connection is unstable")
                .font(MoriTypography.title2)
                .foregroundColor(MoriColors.botanicalInk)

            Text(MoriL10n.display(message))
                .font(MoriTypography.body)
                .foregroundColor(MoriColors.botanicalMuted)
                .multilineTextAlignment(.center)

            MoriSecondaryButton(title: "Retry", action: retryAction)
                .padding(.horizontal, MoriSpacing.space7)
                .padding(.top, MoriSpacing.space3)
        }
        .padding(MoriSpacing.space6)
    }
}
