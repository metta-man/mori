import SwiftUI
import WidgetKit

struct MoriWidgetBloomDial: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let context: MoriWidgetContextSnapshot

    var body: some View {
        ZStack {
            Circle()
                .stroke(MoriWidgetPalette.track(for: renderingMode), lineWidth: 7)

            Circle()
                .trim(from: 0, to: context.bloomProgress)
                .stroke(
                    MoriWidgetPalette.accent(for: renderingMode),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .widgetAccentable()

            VStack(spacing: 1) {
                Text(context.bloomPercentText)
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                    .foregroundStyle(MoriWidgetPalette.ink(for: renderingMode))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(MoriL10n.display("Bloom"))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(MoriWidgetPalette.mutedInk(for: renderingMode))
                    .lineLimit(1)
            }
        }
        .frame(width: 72, height: 72)
    }
}

struct MoriWidgetRecoveryDial: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let context: MoriWidgetContextSnapshot

    var body: some View {
        ZStack {
            Circle()
                .stroke(MoriWidgetPalette.track(for: renderingMode), lineWidth: 7)

            Circle()
                .trim(from: 0, to: context.recoveryProgress)
                .stroke(
                    MoriWidgetPalette.accent(for: renderingMode),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .widgetAccentable()

            VStack(spacing: 1) {
                Text(context.recoveryScoreText)
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                    .foregroundStyle(MoriWidgetPalette.ink(for: renderingMode))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(MoriL10n.display("Recovery"))
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(MoriWidgetPalette.mutedInk(for: renderingMode))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .frame(width: 72, height: 72)
    }
}

struct MoriWidgetMiniMetric: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let title: String
    let value: String
    let icon: MoriBitmapIcon

    var body: some View {
        HStack(spacing: 4) {
            MoriWidgetIconImage(icon: icon, size: 13)

            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(MoriWidgetPalette.accent(for: renderingMode))
        .widgetAccentable()
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(
            MoriWidgetAdaptiveFill(
                fullColor: MoriWidgetColors.leafAccent.opacity(0.11),
                adaptedOpacity: 0.10
            )
        )
        .clipShape(Capsule())
        .accessibilityLabel("\(MoriL10n.display(title)) \(value)")
    }
}

struct MoriWidgetCompactStat: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(MoriWidgetPalette.ink(for: renderingMode))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(MoriL10n.display(title))
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(MoriWidgetPalette.mutedInk(for: renderingMode))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MoriWidgetCardWash(cornerRadius: 10))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct MoriWidgetActionLinks: View {
    enum Style {
        case compact
        case full
    }

    let style: Style

    var body: some View {
        HStack(spacing: 7) {
            MoriWidgetActionLink(title: "Shield", icon: .appLimit, deepLink: "mori://app-limits")
            MoriWidgetActionLink(title: style == .compact ? "Recovery" : "Open Recovery", icon: .heart, deepLink: "mori://recovery")
            MoriWidgetActionLink(title: "Settle", icon: .breathe, deepLink: "mori://settle")
            if style == .full {
                MoriWidgetActionLink(title: "Log", icon: .journal, deepLink: "mori://log")
            }
        }
    }
}

struct MoriWidgetActionLink: View {
    let title: String
    let icon: MoriBitmapIcon
    let deepLink: String

    var body: some View {
        if let url = URL(string: deepLink) {
            Link(destination: url) {
                MoriWidgetIconImage(icon: icon, size: 18)
                    .frame(width: 30, height: 30)
                    .background(
                        MoriWidgetAdaptiveFill(
                            fullColor: MoriWidgetColors.surfaceRaised,
                            adaptedOpacity: 0.10
                        )
                    )
                    .clipShape(Circle())
            }
            .accessibilityLabel(MoriL10n.display(title))
        }
    }
}

struct MoriWidgetShell<Content: View>: View {
    let contentPadding: CGFloat
    let content: Content

    init(contentPadding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.contentPadding = contentPadding
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            content
                .padding(contentPadding)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
    }
}

struct MoriWidgetIconImage: View {
    let icon: MoriBitmapIcon
    var size: CGFloat = 24
    var opacity: Double = 1

    var body: some View {
        Group {
            if #available(iOSApplicationExtension 18.0, *) {
                Image(icon.rawValue)
                    .resizable()
                    .renderingMode(.original)
                    .widgetAccentedRenderingMode(.accentedDesaturated)
            } else {
                Image(icon.rawValue)
                    .resizable()
                    .renderingMode(.original)
            }
        }
        .scaledToFit()
        .frame(width: size, height: size)
        .opacity(opacity)
        .accessibilityHidden(true)
    }
}

struct MoriWidgetHeader: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let title: String
    let icon: MoriBitmapIcon

    var body: some View {
        HStack(spacing: 6) {
            MoriWidgetIconImage(icon: icon, size: 16)

            Text(MoriL10n.display(title))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(MoriWidgetPalette.mutedInk(for: renderingMode))
                .lineLimit(1)
        }
    }
}

struct MiniWeekArchiveGrid: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let snapshot: MoriWidgetSnapshot
    let columns: Int
    let rows: Int
    let dotSize: CGFloat
    let spacing: CGFloat

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<columns, id: \.self) { column in
                        let index = row * columns + column
                        Circle()
                            .fill(color(for: index, visibleCount: rows * columns))
                            .frame(width: dotSize, height: dotSize)
                            .widgetAccentable(isCurrentWeek(index: index, visibleCount: rows * columns))
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func color(for index: Int, visibleCount: Int) -> Color {
        let mappedIndex = mappedWeekIndex(for: index, visibleCount: visibleCount)

        if mappedIndex == snapshot.currentWeekIndex {
            return MoriWidgetPalette.accent(for: renderingMode)
        } else if mappedIndex < snapshot.archiveWeeksElapsed {
            return MoriWidgetPalette.ink(for: renderingMode).opacity(0.72)
        } else {
            return MoriWidgetPalette.ink(for: renderingMode).opacity(0.14)
        }
    }

    private func isCurrentWeek(index: Int, visibleCount: Int) -> Bool {
        mappedWeekIndex(for: index, visibleCount: visibleCount) == snapshot.currentWeekIndex
    }

    private func mappedWeekIndex(for index: Int, visibleCount: Int) -> Int {
        Int((Double(index) / Double(max(visibleCount - 1, 1))) * Double(max(snapshot.totalWeeks - 1, 1)))
    }
}

struct WeekArchivePreview: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let snapshot: MoriWidgetSnapshot

    private let columns = 26

    var body: some View {
        GeometryReader { proxy in
            let rows = min(max(snapshot.archiveSpanYears, 1), 90)
            let horizontalStep = proxy.size.width / CGFloat(columns)
            let verticalStep = proxy.size.height / CGFloat(rows)
            let spacing = max(0.35, min(2, min(horizontalStep, verticalStep) * 0.28))
            let availableWidth = proxy.size.width - CGFloat(columns - 1) * spacing
            let availableHeight = proxy.size.height - CGFloat(rows - 1) * spacing
            let dotSize = max(0, min(4.4, availableWidth / CGFloat(columns), availableHeight / CGFloat(rows)))

            VStack(spacing: spacing) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<columns, id: \.self) { column in
                            let firstWeek = row * 52 + column * 2
                            Capsule()
                                .fill(color(for: firstWeek))
                                .frame(width: dotSize, height: dotSize)
                                .widgetAccentable(firstWeek <= snapshot.currentWeekIndex && snapshot.currentWeekIndex < firstWeek + 2)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .layoutPriority(1)
        .padding(10)
        .background(MoriWidgetCardWash(cornerRadius: 14))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MoriWidgetPalette.outline(for: renderingMode), lineWidth: 1)
        )
        .accessibilityLabel(MoriL10n.string(
            "widget.week_archive.accessibility",
            defaultValue: "Life Grid, current week %d",
            arguments: [snapshot.archiveWeekNumber]
        ))
    }

    private func color(for weekIndex: Int) -> Color {
        if weekIndex <= snapshot.currentWeekIndex && snapshot.currentWeekIndex < weekIndex + 2 {
            return MoriWidgetPalette.accent(for: renderingMode)
        } else if weekIndex < snapshot.archiveWeeksElapsed {
            return MoriWidgetPalette.ink(for: renderingMode).opacity(0.72)
        } else {
            return MoriWidgetPalette.ink(for: renderingMode).opacity(0.13)
        }
    }
}

enum MoriWidgetColors {
    static let paper = Color(hex: "#FBF7EF")
    static let backgroundPaper = paper
    static let surface = Color(hex: "#FFFDF8").opacity(0.74)
    static let surfaceRaised = Color(hex: "#F4EDE1").opacity(0.82)
    static let leafAccent = Color(hex: "#758C6B")
    static let moss = Color(hex: "#6E9298")
    static let ink = Color(hex: "#14392F")
    static let mutedInk = Color(hex: "#5F6D64")
}

enum MoriWidgetPalette {
    static func ink(for renderingMode: WidgetRenderingMode) -> Color {
        renderingMode == .fullColor ? MoriWidgetColors.ink : .primary
    }

    static func mutedInk(for renderingMode: WidgetRenderingMode) -> Color {
        renderingMode == .fullColor ? MoriWidgetColors.mutedInk : Color.primary.opacity(0.82)
    }

    static func accent(for renderingMode: WidgetRenderingMode) -> Color {
        renderingMode == .fullColor ? MoriWidgetColors.leafAccent : .primary
    }

    static func moss(for renderingMode: WidgetRenderingMode) -> Color {
        renderingMode == .fullColor ? MoriWidgetColors.moss : Color.primary.opacity(0.82)
    }

    static func track(for renderingMode: WidgetRenderingMode) -> Color {
        renderingMode == .fullColor ? MoriWidgetColors.ink.opacity(0.12) : Color.primary.opacity(0.14)
    }

    static func outline(for renderingMode: WidgetRenderingMode) -> Color {
        renderingMode == .fullColor ? MoriWidgetColors.leafAccent.opacity(0.18) : Color.primary.opacity(0.18)
    }
}

extension View {
    @ViewBuilder
    func moriWidgetContainerBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) {
                MoriWidgetContainerBackground()
            }
        } else {
            background(MoriWidgetContainerBackground())
        }
    }
}

struct MoriWidgetCardWash: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let cornerRadius: CGFloat

    init(cornerRadius: CGFloat = 14) {
        self.cornerRadius = cornerRadius
    }

    @ViewBuilder
    var body: some View {
        if renderingMode == .fullColor {
            MoriPlainWatercolorCardBackground(
                cornerRadius: cornerRadius,
                fill: MoriWidgetColors.surface,
                paperOpacity: 0.05,
                edgeOpacity: 0.03
            )
        } else {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.primary.opacity(0.10))
        }
    }
}

private struct MoriWidgetContainerBackground: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    @ViewBuilder
    var body: some View {
        if renderingMode == .fullColor {
            GeometryReader { proxy in
                ZStack {
                    MoriGeneratedArtImage(art: .widgetPaperWash, contentMode: .fill)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()

                    MoriGeneratedArtImage(art: .widgetBotanicalWash, contentMode: .fill)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .opacity(0.14)
                        .blendMode(.multiply)
                        .scaleEffect(1.12)
                        .offset(x: 30, y: -24)

                    LinearGradient(
                        colors: [
                            MoriWidgetColors.paper.opacity(0.12),
                            MoriWidgetColors.paper.opacity(0.54)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        } else {
            Color.clear
        }
    }
}

private struct MoriWidgetAdaptiveFill: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let fullColor: Color
    let adaptedOpacity: Double

    @ViewBuilder
    var body: some View {
        if renderingMode == .fullColor {
            fullColor
        } else {
            Color.primary.opacity(adaptedOpacity)
        }
    }
}

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64

        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
