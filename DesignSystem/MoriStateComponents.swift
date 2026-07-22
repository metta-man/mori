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
        MoriFeedbackState(
            icon: icon,
            title: title,
            message: message,
            actionTitle: buttonTitle,
            action: buttonAction
        )
        .padding(MoriSpacing.space4)
    }
}

struct MoriPermissionState: View {
    let icon: MoriBitmapIcon
    let title: String
    let message: String
    let buttonTitle: String
    let buttonAction: () -> Void

    init(
        icon: MoriBitmapIcon = .lockShield,
        title: String,
        message: String,
        buttonTitle: String,
        buttonAction: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }

    var body: some View {
        MoriFeedbackState(
            icon: icon,
            title: title,
            message: message,
            actionTitle: buttonTitle,
            action: buttonAction
        )
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
            .moriOnChange(of: reduceMotion) { shouldReduceMotion in
                isAnimating = !shouldReduceMotion
            }
    }
}

struct MoriErrorState: View {
    let title: String
    let message: String
    let retryTitle: String
    let retryAction: () -> Void

    init(
        title: String = "The connection is unstable",
        message: String,
        retryTitle: String = "Retry",
        retryAction: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.retryTitle = retryTitle
        self.retryAction = retryAction
    }

    var body: some View {
        MoriFeedbackState(
            icon: .refresh,
            title: title,
            message: message,
            actionTitle: retryTitle,
            action: retryAction
        )
        .padding(MoriSpacing.space4)
    }
}

private struct MoriFeedbackState: View {
    let icon: MoriBitmapIcon
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: MoriSpacing.space4) {
            HStack(alignment: .top, spacing: MoriSpacing.space3) {
                MoriBitmapIconImage(icon: icon, size: 20, opacity: 0.90)
                    .frame(width: 36, height: 36)
                    .background(MoriColors.botanicalInk.opacity(0.08))
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: MoriSpacing.space1) {
                    Text(MoriL10n.display(title))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalInk)

                    Text(MoriL10n.display(message))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(MoriL10n.display(actionTitle))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MoriColors.sanctuarySurface)
                        .frame(maxWidth: .infinity, minHeight: MoriV2Layout.minimumHitTarget)
                        .background(MoriColors.botanicalInk)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
