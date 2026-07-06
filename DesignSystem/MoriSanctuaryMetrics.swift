import SwiftUI

struct MoriCompactStatStrip<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(MoriColors.sanctuarySurface.opacity(0.86))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.76), lineWidth: 1)
        )
    }
}

struct MoriCompactStatItem: View {
    let title: String
    let value: String
    var icon: MoriBitmapIcon
    var tint: Color = MoriColors.botanicalMoss

    init(
        title: String,
        value: String,
        icon: MoriBitmapIcon,
        tint: Color = MoriColors.botanicalMoss
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.tint = tint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                MoriBitmapIconImage(icon: icon, size: 13)

                Text(MoriL10n.display(title))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(MoriColors.sanctuaryMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Text(MoriL10n.display(value))
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundColor(MoriColors.sanctuaryInk)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }
}

struct MoriMetricTile: View {
    let title: String
    let value: String
    let detail: String
    var icon: MoriBitmapIcon = .leaf
    var tint: Color = MoriColors.botanicalMoss

    init(
        title: String,
        value: String,
        detail: String,
        icon: MoriBitmapIcon = .leaf,
        tint: Color = MoriColors.botanicalMoss
    ) {
        self.title = title
        self.value = value
        self.detail = detail
        self.icon = icon
        self.tint = tint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MoriBitmapIconBadge(
                icon: icon,
                size: 38,
                fill: MoriColors.sanctuarySurface.opacity(0.70),
                stroke: MoriColors.sanctuaryLine.opacity(0.72)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(MoriL10n.display(value))
                    .font(.system(size: 26, weight: .regular, design: .serif))
                    .foregroundColor(MoriColors.sanctuaryInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(MoriL10n.display(title))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MoriColors.sanctuaryMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(MoriL10n.display(detail))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(MoriColors.sanctuaryMuted.opacity(0.82))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .moriSanctuaryCard(cornerRadius: 18, padding: 15)
    }
}

struct MoriPill: View {
    let title: String
    var icon: MoriBitmapIcon?
    var isSelected: Bool = false
    var tint: Color = MoriColors.botanicalMoss

    init(
        title: String,
        icon: MoriBitmapIcon? = nil,
        isSelected: Bool = false,
        tint: Color = MoriColors.botanicalMoss
    ) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.tint = tint
    }

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                MoriBitmapIconImage(icon: icon, size: 15)
            }

            Text(MoriL10n.display(title))
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundColor(isSelected ? MoriColors.sanctuarySurface : tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? tint : tint.opacity(0.10))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(tint.opacity(isSelected ? 0 : 0.16), lineWidth: 1)
        )
    }
}

struct MoriBotanicalProgressBar: View {
    let value: Double
    var tint: Color = MoriColors.botanicalMoss

    var body: some View {
        GeometryReader { proxy in
            let clamped = max(0, min(1, value))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(MoriColors.botanicalLine.opacity(0.55))

                Capsule()
                    .fill(tint)
                    .frame(width: max(8, proxy.size.width * clamped))
            }
        }
        .frame(height: 9)
    }
}

struct MoriTimerProgressRing: View {
    let progress: CGFloat
    let tint: Color
    let trackTint: Color
    let lineWidth: CGFloat
    let animation: Animation?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        progress: CGFloat,
        tint: Color = MoriColors.botanicalMoss,
        trackTint: Color = MoriColors.botanicalLine.opacity(0.62),
        lineWidth: CGFloat = 13,
        animation: Animation? = .easeInOut(duration: 0.25)
    ) {
        self.progress = progress
        self.tint = tint
        self.trackTint = trackTint
        self.lineWidth = lineWidth
        self.animation = animation
    }

    private var clampedProgress: CGFloat {
        guard progress.isFinite else { return 0 }
        return min(1, max(0, progress))
    }

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)

            ZStack {
                Circle()
                    .stroke(trackTint, lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: clampedProgress)
                    .stroke(
                        tint,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(reduceMotion ? nil : animation, value: clampedProgress)
            }
            .frame(width: side, height: side)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}
