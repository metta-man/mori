import SwiftUI

// MARK: - Mori v2 calm root-layer primitives

enum MoriV2Palette {
    static let paper = MoriTheme.Colors.paper
    static let raisedPaper = MoriTheme.Colors.raisedPaper
    static let forestInk = MoriTheme.Colors.ink
    static let primaryForest = MoriTheme.Colors.primaryAction
    static let sage = MoriTheme.Colors.sage
    static let stone = MoriTheme.Colors.secondaryText
    static let mutedStone = MoriTheme.Colors.mutedText
    static let hairline = MoriTheme.Colors.hairline
    static let shadow = MoriTheme.Colors.shadow
}

enum MoriV2Layout {
    static let screenEdge = MoriTheme.Spacing.screenEdge
    static let cardRadius = MoriTheme.CornerRadius.card
    static let controlRadius = MoriTheme.CornerRadius.control
    static let cardPadding = MoriTheme.Spacing.cardPadding
    static let sectionGap = MoriTheme.Spacing.section
    static let minimumHitTarget = MoriTheme.Spacing.minimumHitTarget
}

enum MoriV2Type {
    static let rootTitle = MoriTheme.Typography.pageTitle
    static let cardTitle = MoriTheme.Typography.cardTitle
    static let sectionTitle = MoriTheme.Typography.sectionTitle
    static let body = MoriTheme.Typography.body
    static let control = MoriTheme.Typography.control
    static let supporting = MoriTheme.Typography.supporting
    static let caption = MoriTheme.Typography.caption
}

enum MoriV2Motion {
    static let screen = MoriTheme.Animation.screen
    static let control = MoriTheme.Animation.control
    static let disclosure = MoriTheme.Animation.disclosure
    static let ambient = MoriTheme.Animation.ambient
}

struct MoriV2PaperScene<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDrifting = false

    let variant: MoriBotanicalScreenBackdrop.Variant
    var artOpacity: Double = 0.62
    private let content: Content

    init(
        variant: MoriBotanicalScreenBackdrop.Variant,
        artOpacity: Double = 0.62,
        @ViewBuilder content: () -> Content
    ) {
        self.variant = variant
        self.artOpacity = artOpacity
        self.content = content()
    }

    var body: some View {
        ZStack {
            MoriV2Palette.paper
                .ignoresSafeArea()

            MoriBotanicalScreenBackdrop(variant: variant)
                .opacity(artOpacity)
                .scaleEffect(reduceMotion ? 1 : (isDrifting ? 1.012 : 1))
                .offset(y: reduceMotion ? 0 : (isDrifting ? -3 : 1))
                .animation(reduceMotion ? nil : MoriV2Motion.ambient, value: isDrifting)
                .ignoresSafeArea()

            content
        }
        .onAppear {
            guard !reduceMotion else { return }
            isDrifting = true
        }
        .moriOnChange(of: reduceMotion) { shouldReduceMotion in
            isDrifting = !shouldReduceMotion
        }
    }
}

struct MoriV2RootScrollScreen<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    let title: String
    let subtitle: String
    let backgroundVariant: MoriBotanicalScreenBackdrop.Variant
    var minimumTopInset: CGFloat?
    var headerTextSpacing: CGFloat
    var headerTextLeadingInset: CGFloat
    var settingsButtonStyle: MoriV2SettingsButton.Style
    let onOpenSettings: () -> Void
    private let content: Content

    init(
        title: String,
        subtitle: String,
        backgroundVariant: MoriBotanicalScreenBackdrop.Variant,
        minimumTopInset: CGFloat? = nil,
        headerTextSpacing: CGFloat = 8,
        headerTextLeadingInset: CGFloat = 0,
        settingsButtonStyle: MoriV2SettingsButton.Style = .floating,
        onOpenSettings: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.backgroundVariant = backgroundVariant
        self.minimumTopInset = minimumTopInset
        self.headerTextSpacing = headerTextSpacing
        self.headerTextLeadingInset = headerTextLeadingInset
        self.settingsButtonStyle = settingsButtonStyle
        self.onOpenSettings = onOpenSettings
        self.content = content()
    }

    var body: some View {
        ZStack {
            MoriV2PaperScene(variant: backgroundVariant) {
                Color.clear
            }

            GeometryReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: MoriV2Layout.sectionGap) {
                        header
                            .padding(.top, topInset(for: proxy.safeAreaInsets.top))

                        content
                    }
                    .padding(.horizontal, MoriV2Layout.screenEdge)
                    .padding(.bottom, MoriMainTabBarMetrics.scrollBottomInset + 12)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: reduceMotion || isVisible ? 0 : 8)
                    .animation(
                        reduceMotion ? .easeOut(duration: 0.12) : MoriV2Motion.screen,
                        value: isVisible
                    )
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            isVisible = true
        }
    }

    private func topInset(for safeAreaTop: CGFloat) -> CGFloat {
        max(
            minimumTopInset ?? 0,
            MoriRootScreenMetrics.topInset(for: safeAreaTop)
        )
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: headerTextSpacing) {
                Text(MoriL10n.display(title))
                    .font(MoriV2Type.rootTitle)
                    .foregroundColor(MoriV2Palette.forestInk)
                    .fixedSize(horizontal: false, vertical: true)

                Text(MoriL10n.display(subtitle))
                    .font(MoriV2Type.supporting)
                    .foregroundColor(MoriV2Palette.stone)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, headerTextLeadingInset)
            .frame(maxWidth: .infinity, alignment: .leading)

            MoriV2SettingsButton(style: settingsButtonStyle, action: onOpenSettings)
        }
    }
}

struct MoriV2PaperCard<Content: View>: View {
    var padding: CGFloat = MoriV2Layout.cardPadding
    var cornerRadius: CGFloat = MoriV2Layout.cardRadius
    private let content: Content

    init(
        padding: CGFloat = MoriV2Layout.cardPadding,
        cornerRadius: CGFloat = MoriV2Layout.cardRadius,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(MoriV2Palette.raisedPaper)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(MoriV2Palette.hairline, lineWidth: 1)
            )
            .shadow(color: MoriV2Palette.shadow, radius: 18, x: 0, y: 10)
    }
}

struct MoriV2PrimaryButton: View {
    let title: String
    var icon: MoriBitmapIcon? = nil
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        MoriPrimaryButton(
            title: title,
            icon: icon,
            isEnabled: isEnabled,
            style: .v2Compatibility,
            action: action
        )
    }
}

struct MoriV2QuietDisclosureRow: View {
    let title: String
    let subtitle: String
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                MoriBitmapIconImage(icon: isExpanded ? .minus : .plus, size: 17, opacity: 0.78)
                    .frame(width: 34, height: 34)
                    .background(MoriV2Palette.forestInk.opacity(0.06))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(MoriL10n.display(title))
                        .font(MoriV2Type.control)
                        .foregroundColor(MoriV2Palette.forestInk)

                    Text(MoriL10n.display(subtitle))
                        .font(MoriV2Type.caption)
                        .foregroundColor(MoriV2Palette.mutedStone)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                MoriBitmapIconImage(icon: .chevron, size: 13, opacity: 0.52)
                    .rotationEffect(.degrees(isExpanded ? -90 : 90))
            }
            .padding(.horizontal, 15)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .background(MoriV2Palette.raisedPaper)
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(MoriV2Palette.hairline, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        }
        .buttonStyle(MoriV2PressButtonStyle())
        .accessibilityValue(Text(MoriL10n.display(isExpanded ? "Expanded" : "Collapsed")))
    }
}

struct MoriV2QuietActionRow: View {
    let title: String
    let subtitle: String
    let icon: MoriBitmapIcon
    var showsChevron = true

    var body: some View {
        HStack(spacing: 13) {
            MoriBitmapIconImage(icon: icon, size: 19, opacity: 0.80)
                .frame(width: 38, height: 38)
                .background(MoriV2Palette.forestInk.opacity(0.06))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(MoriL10n.display(title))
                    .font(MoriV2Type.control)
                    .foregroundColor(MoriV2Palette.forestInk)

                Text(MoriL10n.display(subtitle))
                    .font(MoriV2Type.caption)
                    .foregroundColor(MoriV2Palette.mutedStone)
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsChevron {
                MoriBitmapIconImage(icon: .chevron, size: 13, opacity: 0.50)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(MoriV2Palette.raisedPaper)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(MoriV2Palette.hairline, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct MoriV2SettingsButton: View {
    enum Style {
        case floating
        case plain
    }

    var style: Style = .floating
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            settingsIcon
                .frame(width: 46, height: 46)
                .background(settingsBackground)
                .contentShape(Circle())
        }
        .buttonStyle(MoriV2PressButtonStyle())
        .accessibilityLabel(MoriL10n.display("Settings"))
        .accessibilityHint(MoriL10n.display("Opens settings"))
    }

    @ViewBuilder
    private var settingsIcon: some View {
        switch style {
        case .floating:
            MoriBitmapIconImage(icon: .settings, size: 24, opacity: 0.78)
        case .plain:
            Image(systemName: "gearshape")
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(MoriV2Palette.forestInk.opacity(0.90))
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var settingsBackground: some View {
        switch style {
        case .floating:
            Circle()
                .fill(MoriV2Palette.raisedPaper)
                .overlay(
                    Circle()
                        .stroke(MoriV2Palette.hairline, lineWidth: 1)
                )
                .shadow(color: MoriV2Palette.shadow, radius: 12, x: 0, y: 6)
        case .plain:
            Color.clear
        }
    }
}

struct MoriV2PressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 1.018 : 1))
            .opacity(configuration.isPressed ? 0.90 : 1)
            .animation(reduceMotion ? nil : MoriV2Motion.control, value: configuration.isPressed)
    }
}

struct MoriPracticeCard: View {
    let practice: MoriPractice
    var eyebrow: String?
    var reason: String?
    var showsChevron = true

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            MoriBitmapIconBadge(
                icon: practice.icon,
                size: 42,
                fill: MoriColors.sanctuarySurface.opacity(0.72),
                stroke: Color.white.opacity(0.9)
            )

            VStack(alignment: .leading, spacing: 8) {
                if let eyebrow {
                    Text(MoriL10n.display(eyebrow))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MoriColors.sanctuarySage)
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(MoriL10n.display(practice.title))
                        .font(.system(size: 18, weight: .regular, design: .serif))
                        .foregroundColor(MoriColors.sanctuaryInk)

                    Text(MoriL10n.display(practice.durationText))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(MoriColors.sanctuaryMuted)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(MoriColors.sanctuaryInk.opacity(0.07))
                        .clipShape(Capsule())
                }

                Text(MoriL10n.display(reason ?? practice.description))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(MoriColors.sanctuaryMuted)
                    .fixedSize(horizontal: false, vertical: true)

                MoriPracticeInlineSummary(practice: practice)
            }

            Spacer(minLength: 0)

            if showsChevron {
                MoriBitmapIconImage(icon: .chevron, size: 15, opacity: 0.58)
                    .padding(.top, 12)
            }
        }
        .moriSanctuaryBox(cornerRadius: 16, padding: 12, tone: .paper, castsShadow: false)
    }
}

struct MoriPracticeInlineSummary: View {
    let practice: MoriPractice

    var body: some View {
        Text(summaryText)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(MoriColors.botanicalMuted)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(MoriColors.botanicalInk.opacity(0.055))
            .clipShape(Capsule())
            .accessibilityLabel(accessibilityText)
    }

    private var summaryText: String {
        "\(practice.seedText) / \(practice.domainText)"
    }

    private var accessibilityText: String {
        MoriL10n.string(
            "practice.inline_summary.accessibility",
            defaultValue: "%@. %@.",
            arguments: [practice.seedText, practice.domainText]
        )
    }
}

struct MoriFeatureBox: View {
    let title: String
    let subtitle: String
    let icon: MoriBitmapIcon
    var detail: String?
    var tone: MoriSanctuaryBoxTone = .paper
    var iconSize: CGFloat = 58
    var minHeight: CGFloat = 132
    var showsChevron = true

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            HStack(alignment: .top, spacing: isCompact ? 10 : 14) {
                iconBadge
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: isCompact ? 5 : 7) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(MoriL10n.display(title))
                            .font(.system(size: isCompact ? 17 : 22, weight: .regular, design: .serif))
                            .foregroundColor(MoriColors.sanctuaryInk)
                            .lineLimit(isCompact ? 1 : 2)
                            .minimumScaleFactor(isCompact ? 0.72 : 0.82)
                            .layoutPriority(2)

                        if let detail {
                            Text(MoriL10n.display(detail))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(tone.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(tone.accent.opacity(0.11))
                                .clipShape(Capsule())
                        }
                    }

                    Text(MoriL10n.display(subtitle))
                        .font(.system(size: isCompact ? 11 : 15, weight: .regular))
                        .foregroundColor(MoriColors.sanctuaryMuted)
                        .lineLimit(isCompact ? 3 : nil)
                        .minimumScaleFactor(isCompact ? 0.78 : 0.88)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, showsChevron ? (isCompact ? 22 : 16) : 0)

                Spacer(minLength: 0)
            }

            if showsChevron {
                MoriBitmapIconImage(icon: .chevron, size: 16, opacity: 0.68)
                    .frame(width: 26, height: 26)
                    .background(MoriColors.sanctuarySurface.opacity(0.52))
                    .clipShape(Circle())
                    .padding(.bottom, 2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
        .moriSanctuaryBox(
            cornerRadius: 22,
            padding: isCompact ? 10 : 14,
            tone: tone,
            castsShadow: !isCompact
        )
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var isCompact: Bool {
        iconSize <= 52
    }

    @ViewBuilder
    private var iconBadge: some View {
        MoriBitmapIconBadge(
            icon: icon,
            size: iconSize,
            iconScale: isCompact ? 0.50 : 0.54,
            fill: tone.iconFill,
            stroke: Color.white.opacity(0.88),
            shadow: MoriColors.sanctuaryShadow.opacity(0.34)
        )
        .accessibilityHidden(true)
    }
}

extension LifeDomain {
    var moriTint: Color {
        switch self {
        case .body:
            return MoriColors.botanicalFern
        case .mind:
            return MoriColors.botanicalMist
        case .love:
            return MoriColors.botanicalClay
        case .craft:
            return MoriColors.botanicalSeed
        case .courage:
            return MoriColors.botanicalRoot
        case .service:
            return MoriColors.botanicalSage
        case .wonder:
            return MoriColors.botanicalSeed
        case .rest:
            return MoriColors.botanicalMuted
        }
    }

    var moriIcon: MoriBitmapIcon {
        switch self {
        case .body:
            return .focus
        case .mind:
            return .pulse
        case .love:
            return .heart
        case .craft:
            return .journal
        case .courage:
            return .leaf
        case .service:
            return .breathe
        case .wonder:
            return .pulse
        case .rest:
            return .quiet
        }
    }
}
