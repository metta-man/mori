import SwiftUI
import UIKit

// MARK: - Page composition

/// A warm-paper page shell for new Mori surfaces.
///
/// `MoriPage` deliberately does not include navigation or a header. This keeps
/// presentation reusable without taking ownership of an existing screen's
/// routing or information hierarchy.
struct MoriPage<Content: View>: View {
    let scene: MoriLandscapeBackground.Scene
    let landscapePlacement: MoriLandscapeBackground.Placement
    let scrolls: Bool
    let showsScrollIndicators: Bool
    let horizontalPadding: CGFloat
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let contentSpacing: CGFloat
    private let content: Content

    init(
        scene: MoriLandscapeBackground.Scene = .none,
        landscapePlacement: MoriLandscapeBackground.Placement = .lowerThird,
        scrolls: Bool = true,
        showsScrollIndicators: Bool = false,
        horizontalPadding: CGFloat = MoriTheme.Spacing.screenEdge,
        topPadding: CGFloat = MoriTheme.Spacing.small,
        bottomPadding: CGFloat = MoriTheme.Spacing.xLarge,
        contentSpacing: CGFloat = MoriTheme.Spacing.section,
        @ViewBuilder content: () -> Content
    ) {
        self.scene = scene
        self.landscapePlacement = landscapePlacement
        self.scrolls = scrolls
        self.showsScrollIndicators = showsScrollIndicators
        self.horizontalPadding = horizontalPadding
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
        self.contentSpacing = contentSpacing
        self.content = content()
    }

    var body: some View {
        ZStack {
            MoriLandscapeBackground(
                scene: scene,
                placement: landscapePlacement
            )
            .ignoresSafeArea()

            if scrolls {
                ScrollView(.vertical, showsIndicators: showsScrollIndicators) {
                    pageContent
                }
            } else {
                pageContent
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private var pageContent: some View {
        VStack(alignment: .leading, spacing: contentSpacing) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, horizontalPadding)
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
    }
}

/// A compositional watercolor landscape that grows from an edge instead of
/// behaving like a rectangular wallpaper.
struct MoriLandscapeBackground: View {
    enum Scene: Equatable {
        case today
        case focus
        case log
        case lifeGrid
        case deepSession
        case quietMode
        case offlineReset
        case settings
        case custom(MoriBotanicalScreenBackdrop.Variant)
        case none

        fileprivate var backdropVariant: MoriBotanicalScreenBackdrop.Variant {
            switch self {
            case .today:
                return .today
            case .focus, .deepSession:
                return .focus
            case .log:
                return .journal
            case .lifeGrid:
                return .roots
            case .quietMode:
                return .breath
            case .offlineReset:
                return .homeHero
            case .settings:
                return .settings
            case .custom(let variant):
                return variant
            case .none:
                return .none
            }
        }
    }

    enum Placement: Equatable {
        case fullPage
        case lowerHalf
        case lowerThird
        case card
    }

    let scene: Scene
    var placement: Placement = .lowerThird
    var intensity: Double = 0.72

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                MoriTheme.Colors.paper

                MoriGeneratedArtImage(art: .paperWash, contentMode: .fill)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .opacity(0.34)
                    .blendMode(.multiply)

                if scene != .none {
                    landscapeLayer(in: proxy.size)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func landscapeLayer(in size: CGSize) -> some View {
        MoriPaperBackground(variant: scene.backdropVariant) {
            Color.clear
        }
        .frame(
            width: size.width + MoriTheme.IllustrationSpacing.edgeBleed,
            height: landscapeHeight(in: size) + bottomBleed
        )
        .opacity(min(1, max(0, intensity)))
        .mask(landscapeMask)
        .offset(y: bottomBleed / 2)
        .clipped()
    }

    private func landscapeHeight(in size: CGSize) -> CGFloat {
        switch placement {
        case .fullPage, .card:
            return size.height
        case .lowerHalf:
            return max(
                MoriTheme.IllustrationSpacing.gridLandscapeHeight,
                size.height * 0.58
            )
        case .lowerThird:
            return max(
                MoriTheme.IllustrationSpacing.gridLandscapeHeight,
                size.height * MoriTheme.IllustrationSpacing.pageLandscapeHeightRatio
            )
        }
    }

    private var bottomBleed: CGFloat {
        placement == .card ? 0 : MoriTheme.IllustrationSpacing.bottomBleed
    }

    @ViewBuilder
    private var landscapeMask: some View {
        switch placement {
        case .card:
            Color.white
        case .fullPage:
            LinearGradient(
                colors: [.white.opacity(0.34), .white, .white],
                startPoint: .top,
                endPoint: .bottom
            )
        case .lowerHalf, .lowerThird:
            LinearGradient(
                colors: [.clear, .white.opacity(0.72), .white],
                startPoint: .top,
                endPoint: .center
            )
        }
    }
}

// MARK: - Editorial hierarchy

struct MoriSectionHeader<Trailing: View>: View {
    let title: String
    let subtitle: String?
    private let trailing: Trailing

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .top, spacing: MoriTheme.Spacing.small) {
            VStack(alignment: .leading, spacing: MoriTheme.Spacing.xxSmall) {
                Text(MoriL10n.display(title))
                    .font(MoriTheme.Typography.sectionTitle)
                    .foregroundColor(MoriTheme.Colors.ink)

                if let subtitle {
                    Text(MoriL10n.display(subtitle))
                        .font(MoriTheme.Typography.caption)
                        .foregroundColor(MoriTheme.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            trailing
        }
    }
}

extension MoriSectionHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = EmptyView()
    }
}

// MARK: - Surfaces

struct MoriCard<Content: View>: View {
    enum Tone {
        case paper
        case warm
        case sage
        case clear

        fileprivate var fill: Color {
            switch self {
            case .paper:
                return MoriTheme.Colors.raisedPaper
            case .warm:
                return MoriTheme.Colors.paper
            case .sage:
                return MoriTheme.Colors.sage.opacity(0.12)
            case .clear:
                return .clear
            }
        }
    }

    let tone: Tone
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadow: MoriTheme.Shadow?
    private let content: Content

    init(
        tone: Tone = .paper,
        padding: CGFloat = MoriTheme.Spacing.cardPadding,
        cornerRadius: CGFloat = MoriTheme.CornerRadius.card,
        shadow: MoriTheme.Shadow? = MoriTheme.Shadows.card,
        @ViewBuilder content: () -> Content
    ) {
        self.tone = tone
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(MoriTheme.Colors.hairline, lineWidth: 1)
            )
            .moriThemeShadow(shadow)
    }

    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(tone.fill)

            if toneIsTextured {
                MoriGeneratedArtImage(art: .cardPaperWash, contentMode: .fill)
                    .opacity(0.055)
                    .blendMode(.multiply)
                    .clipShape(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    )
            }
        }
    }

    private var toneIsTextured: Bool {
        switch tone {
        case .clear:
            return false
        case .paper, .warm, .sage:
            return true
        }
    }
}

struct MoriFloatingPanel<Content: View>: View {
    let padding: CGFloat
    private let content: Content

    init(
        padding: CGFloat = MoriTheme.Spacing.medium,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        MoriCard(
            tone: .paper,
            padding: padding,
            cornerRadius: MoriTheme.CornerRadius.floatingPanel,
            shadow: MoriTheme.Shadows.floatingPanel
        ) {
            content
        }
    }
}

struct MoriBottomSheet<Content: View>: View {
    let title: String?
    let subtitle: String?
    let showsDragIndicator: Bool
    let horizontalPadding: CGFloat
    private let content: Content

    init(
        title: String? = nil,
        subtitle: String? = nil,
        showsDragIndicator: Bool = true,
        horizontalPadding: CGFloat = MoriTheme.Spacing.large,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showsDragIndicator = showsDragIndicator
        self.horizontalPadding = horizontalPadding
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MoriTheme.Spacing.large) {
            if title != nil || subtitle != nil {
                VStack(alignment: .leading, spacing: MoriTheme.Spacing.xSmall) {
                    if let title {
                        Text(MoriL10n.display(title))
                            .font(MoriTheme.Typography.detailTitle)
                            .foregroundColor(MoriTheme.Colors.ink)
                    }

                    if let subtitle {
                        Text(MoriL10n.display(subtitle))
                            .font(MoriTheme.Typography.supporting)
                            .foregroundColor(MoriTheme.Colors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            content
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, MoriTheme.Spacing.large)
        .padding(.bottom, MoriTheme.Spacing.xLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MoriTheme.Colors.raisedPaper.ignoresSafeArea())
        .presentationDragIndicator(showsDragIndicator ? .visible : .hidden)
        .modifier(MoriBottomSheetPresentationModifier())
    }
}

private struct MoriBottomSheetPresentationModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                .presentationBackground(MoriTheme.Colors.raisedPaper)
                .presentationCornerRadius(MoriTheme.CornerRadius.bottomSheet)
        } else {
            content.background(
                MoriSheetCornerRadiusBridge(
                    cornerRadius: MoriTheme.CornerRadius.bottomSheet
                )
            )
        }
    }
}

/// SwiftUI exposed `presentationCornerRadius` in iOS 16.4. This bridge keeps
/// the same sheet geometry on Mori's iOS 16.0–16.3 deployment range.
private struct MoriSheetCornerRadiusBridge: UIViewControllerRepresentable {
    let cornerRadius: CGFloat

    func makeUIViewController(context: Context) -> MoriSheetCornerRadiusController {
        let controller = MoriSheetCornerRadiusController()
        controller.view.backgroundColor = .clear
        controller.cornerRadius = cornerRadius
        return controller
    }

    func updateUIViewController(
        _ controller: MoriSheetCornerRadiusController,
        context: Context
    ) {
        controller.cornerRadius = cornerRadius
    }
}

private final class MoriSheetCornerRadiusController: UIViewController {
    var cornerRadius: CGFloat = 0 {
        didSet { applyCornerRadius() }
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        applyCornerRadius()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyCornerRadius()
    }

    private func applyCornerRadius() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            var candidate: UIViewController? = self

            while let current = candidate {
                if let sheet = current.presentationController as? UISheetPresentationController {
                    sheet.preferredCornerRadius = self.cornerRadius
                    return
                }

                candidate = current.parent
            }
        }
    }
}

// MARK: - Focus modes

struct MoriModeCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title2) private var titlePointSize: CGFloat = 24

    enum Artwork {
        case asset(String)
        case generated(MoriGeneratedArt)
    }

    enum Emphasis {
        case primary
        case standard

        fileprivate var artIntensity: Double {
            switch self {
            case .primary:
                return 0.82
            case .standard:
                return 0.68
            }
        }

        fileprivate var leafOpacity: Double {
            switch self {
            case .primary:
                return 0.82
            case .standard:
                return 0.14
            }
        }
    }

    let title: String
    let description: String
    let duration: String
    let scene: MoriLandscapeBackground.Scene
    var artwork: Artwork? = nil
    var emphasis: Emphasis = .standard
    var height: CGFloat = MoriTheme.IllustrationSpacing.modeCardHeight
    var cornerRadius: CGFloat = MoriTheme.CornerRadius.card
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                cardArtwork

                LinearGradient(
                    colors: leadingReadabilityWash,
                    startPoint: .leading,
                    endPoint: .trailing
                )

                VStack(alignment: .leading, spacing: MoriTheme.Spacing.xSmall) {
                    Image(systemName: "leaf")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(
                            MoriTheme.Colors.sage.opacity(emphasis.leafOpacity)
                        )
                        .frame(height: 15)
                        .accessibilityHidden(true)

                    Text(MoriL10n.display(title))
                        .font(.system(size: titlePointSize, weight: .regular, design: .serif))
                        .foregroundColor(MoriTheme.Colors.ink)

                    Text(MoriL10n.display(description))
                        .font(MoriTheme.Typography.supporting)
                        .foregroundColor(MoriTheme.Colors.secondaryText)
                        .lineSpacing(2)
                        .frame(
                            maxWidth: dynamicTypeSize.isAccessibilitySize
                                ? .infinity
                                : MoriTheme.IllustrationSpacing.textClearance * 1.75,
                            alignment: .leading
                        )
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: MoriTheme.Spacing.xSmall)

                    HStack(alignment: .center) {
                        Text(MoriL10n.display(duration))
                            .font(MoriTheme.Typography.caption)
                            .foregroundColor(MoriTheme.Colors.ink)
                            .padding(.horizontal, MoriTheme.Spacing.small)
                            .padding(.vertical, MoriTheme.Spacing.xxSmall + 2)
                            .background(MoriTheme.Colors.paper.opacity(0.90))
                            .clipShape(Capsule())
                            .shadow(
                                color: MoriTheme.Colors.ink.opacity(0.025),
                                radius: 4,
                                x: 0,
                                y: 2
                            )

                        Spacer(
                            minLength: dynamicTypeSize.isAccessibilitySize
                                ? MoriTheme.Spacing.xSmall
                                : MoriTheme.IllustrationSpacing.textClearance
                        )

                        MoriPlayTriangle()
                            .fill(
                                isEnabled
                                    ? MoriTheme.Colors.onPrimary
                                    : MoriTheme.Colors.mutedText
                            )
                            .frame(width: 15, height: 18)
                            .offset(x: 1)
                            .frame(width: 48, height: 48)
                            .background(
                                isEnabled
                                    ? MoriTheme.Colors.primaryAction
                                    : MoriTheme.Colors.hairline
                            )
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 20)
            }
            .frame(maxWidth: .infinity)
            .modifier(MoriModeCardHeightModifier(height: height))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
                .stroke(MoriTheme.Colors.ink.opacity(0.055), lineWidth: 0.7)
            )
            .contentShape(
                RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
            )
            .shadow(
                color: MoriTheme.Colors.ink.opacity(0.035),
                radius: 11,
                x: 0,
                y: 5
            )
        }
        .buttonStyle(MoriComponentPressButtonStyle())
        .disabled(!isEnabled)
        .accessibilityLabel(MoriL10n.display(title))
        .accessibilityValue(MoriL10n.display(duration))
        .accessibilityHint(MoriL10n.display(description))
    }

    @ViewBuilder
    private var cardArtwork: some View {
        GeometryReader { proxy in
            ZStack {
                MoriTheme.Colors.raisedPaper

                switch artwork {
                case .asset(let name):
                    Image(name)
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFill()
                        .scaleEffect(
                            name == "MoriDeepSessionForest"
                                ? (scene == .offlineReset ? 1.48 : 1.40)
                                : 1.02
                        )
                        .offset(
                            x: name == "MoriDeepSessionForest"
                                ? (scene == .offlineReset ? -44 : -32)
                                : 0,
                            y: name == "MoriDeepSessionForest"
                                ? (scene == .offlineReset ? -70 : -138)
                                : -22
                        )
                        .saturation(
                            name == "MoriDeepSessionForest"
                                ? (scene == .offlineReset ? 0.76 : 0.86)
                                : 1.18
                        )
                        .contrast(
                            name == "MoriDeepSessionForest" && scene == .offlineReset
                                ? 1.28
                                : 1.16
                        )
                        .brightness(
                            name == "MoriDeepSessionForest"
                                ? (scene == .offlineReset ? -0.04 : -0.03)
                                : -0.025
                        )

                    if name == "MoriDeepSessionForest" && scene == .quietMode {
                        MoriTheme.Colors.mist
                            .opacity(0.08)
                            .blendMode(.multiply)
                    }

                    if name == "MoriDeepSessionForest" && scene == .offlineReset {
                        MoriTheme.Colors.ochre
                            .opacity(0.05)
                            .blendMode(.multiply)
                    }
                case .generated(let art):
                    Image(art.rawValue)
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFill()
                case nil:
                    MoriLandscapeBackground(
                        scene: scene,
                        placement: .card,
                        intensity: emphasis.artIntensity
                    )
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var leadingReadabilityWash: [Color] {
        switch scene {
        case .deepSession:
            return [
                MoriTheme.Colors.raisedPaper.opacity(0.68),
                MoriTheme.Colors.raisedPaper.opacity(0.17),
                .clear
            ]
        case .quietMode:
            return [
                MoriTheme.Colors.raisedPaper.opacity(0.70),
                MoriTheme.Colors.raisedPaper.opacity(0.18),
                .clear
            ]
        case .offlineReset:
            return [
                MoriTheme.Colors.raisedPaper.opacity(0.70),
                MoriTheme.Colors.raisedPaper.opacity(0.18),
                .clear
            ]
        default:
            return [
                MoriTheme.Colors.raisedPaper.opacity(0.90),
                MoriTheme.Colors.raisedPaper.opacity(0.44),
                .clear
            ]
        }
    }
}

private struct MoriModeCardHeightModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let height: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            content.frame(minHeight: height)
        } else {
            content.frame(height: height)
        }
    }
}

// MARK: - Mood and Life Grid

enum MoriMoodTone: String, CaseIterable, Identifiable, Hashable {
    case good
    case neutral
    case difficult

    var id: String { rawValue }

    var title: String {
        switch self {
        case .good:
            return MoriL10n.display("Good")
        case .neutral:
            return MoriL10n.display("Neutral")
        case .difficult:
            return MoriL10n.display("Difficult")
        }
    }

    var color: Color {
        switch self {
        case .good:
            return MoriTheme.Colors.good
        case .neutral:
            return MoriTheme.Colors.neutral
        case .difficult:
            return MoriTheme.Colors.difficult
        }
    }
}

struct MoriMoodOption<Value: Hashable>: Identifiable {
    let id: Value
    let title: String
    let tone: MoriMoodTone
    let accessibilityLabel: String?

    init(
        id: Value,
        title: String,
        tone: MoriMoodTone,
        accessibilityLabel: String? = nil
    ) {
        self.id = id
        self.title = title
        self.tone = tone
        self.accessibilityLabel = accessibilityLabel
    }
}

struct MoriMoodSelector<Value: Hashable>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let options: [MoriMoodOption<Value>]
    @Binding private var selection: Value?
    let onSelectionChange: ((Value) -> Void)?

    init(
        options: [MoriMoodOption<Value>],
        selection: Binding<Value?>,
        onSelectionChange: ((Value) -> Void)? = nil
    ) {
        self.options = options
        self._selection = selection
        self.onSelectionChange = onSelectionChange
    }

    @ViewBuilder
    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: MoriTheme.Spacing.xSmall) {
                ForEach(options) { option in
                    moodButton(option)
                }
            }
        } else {
            HStack(alignment: .top, spacing: MoriTheme.Spacing.xSmall) {
                ForEach(options) { option in
                    moodButton(option)
                }
            }
        }
    }

    private func moodButton(_ option: MoriMoodOption<Value>) -> some View {
        let isSelected = selection == option.id

        return Button {
            selection = option.id
            onSelectionChange?(option.id)
        } label: {
            VStack(spacing: MoriTheme.Spacing.xSmall) {
                MoriMoodFace(tone: option.tone)
                    .frame(width: 40, height: 40)

                Text(MoriL10n.display(option.title))
                    .font(MoriTheme.Typography.caption)
                    .foregroundColor(MoriTheme.Colors.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 88)
            .padding(.horizontal, MoriTheme.Spacing.xxSmall)
            .background(
                isSelected
                    ? option.tone.color.opacity(0.15)
                    : MoriTheme.Colors.raisedPaper.opacity(0.72)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: MoriTheme.CornerRadius.control,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: MoriTheme.CornerRadius.control,
                    style: .continuous
                )
                .stroke(
                    isSelected
                        ? option.tone.color.opacity(0.58)
                        : MoriTheme.Colors.hairline,
                    lineWidth: 1
                )
            )
            .contentShape(
                RoundedRectangle(
                    cornerRadius: MoriTheme.CornerRadius.control,
                    style: .continuous
                )
            )
        }
        .buttonStyle(MoriComponentPressButtonStyle())
        .accessibilityLabel(
            MoriL10n.display(option.accessibilityLabel ?? option.title)
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension MoriMoodSelector where Value == MoriMoodTone {
    init(
        selection: Binding<MoriMoodTone?>,
        onSelectionChange: ((MoriMoodTone) -> Void)? = nil
    ) {
        self.init(
            options: MoriMoodTone.allCases.map {
                MoriMoodOption(id: $0, title: $0.title, tone: $0)
            },
            selection: selection,
            onSelectionChange: onSelectionChange
        )
    }
}

enum MoriCalendarIndicator: Hashable {
    case note
    case photo
    case quiet

    fileprivate var color: Color {
        switch self {
        case .note:
            return MoriTheme.Colors.ink
        case .photo:
            return MoriTheme.Colors.ochre
        case .quiet:
            return MoriTheme.Colors.moss
        }
    }
}

struct MoriCalendarCell: View {
    let day: Int
    var tone: MoriMoodTone?
    var indicators: [MoriCalendarIndicator] = []
    var isToday = false
    var isSelected = false
    var isFuture = false
    var toneStrength: Double = 0.42
    var accessibilityText: String?

    var body: some View {
        VStack(spacing: MoriTheme.Spacing.xxSmall + 1) {
            Text("\(day)")
                .font(MoriTheme.Typography.caption)
                .foregroundColor(MoriTheme.Colors.ink)
                .monospacedDigit()

            HStack(spacing: 3) {
                ForEach(Array(indicators.prefix(2).enumerated()), id: \.offset) { _, indicator in
                    Circle()
                        .fill(indicatorColor(indicator))
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 5)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 46)
        .background(fillColor)
        .clipShape(
            RoundedRectangle(
                cornerRadius: MoriTheme.CornerRadius.calendarCell,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: MoriTheme.CornerRadius.calendarCell,
                style: .continuous
            )
            .stroke(outlineColor, lineWidth: isSelected ? 1.5 : 1)
        )
        .opacity(isFuture ? 0.38 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            accessibilityText
                ?? MoriL10n.display("Day \(day), \(tone?.title ?? "No entry")")
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var fillColor: Color {
        guard !isFuture, let tone else {
            return MoriTheme.Colors.noEntry.opacity(0.48)
        }

        return tone.color.opacity(min(0.82, max(0.16, toneStrength)))
    }

    private var outlineColor: Color {
        if isSelected || isToday {
            return MoriTheme.Colors.ink
        }

        return MoriTheme.Colors.hairline
    }

    private func indicatorColor(_ indicator: MoriCalendarIndicator) -> Color {
        tone == nil
            ? indicator.color
            : MoriTheme.Colors.ink.opacity(0.66)
    }
}

struct MoriLifeGridPreviewDay: Identifiable, Hashable {
    let id: Int
    let tone: MoriMoodTone?
    let isFuture: Bool

    init(id: Int, tone: MoriMoodTone?, isFuture: Bool = false) {
        self.id = id
        self.tone = tone
        self.isFuture = isFuture
    }
}

struct MoriLifeGridPreview: View {
    let title: String
    let summary: String
    let days: [MoriLifeGridPreviewDay]
    let columnCount: Int
    let action: () -> Void

    init(
        title: String = "Life Grid",
        summary: String,
        days: [MoriLifeGridPreviewDay],
        columnCount: Int = 14,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.summary = summary
        self.days = days
        self.columnCount = max(1, columnCount)
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            MoriCard(
                tone: .paper,
                padding: MoriTheme.Spacing.medium,
                cornerRadius: MoriTheme.CornerRadius.card,
                shadow: MoriTheme.Shadows.card
            ) {
                VStack(alignment: .leading, spacing: MoriTheme.Spacing.medium) {
                    HStack(alignment: .firstTextBaseline, spacing: MoriTheme.Spacing.xSmall) {
                        VStack(alignment: .leading, spacing: MoriTheme.Spacing.xxSmall) {
                            Text(MoriL10n.display(title))
                                .font(MoriTheme.Typography.sectionTitle)
                                .foregroundColor(MoriTheme.Colors.ink)

                            Text(MoriL10n.display(summary))
                                .font(MoriTheme.Typography.caption)
                                .foregroundColor(MoriTheme.Colors.secondaryText)
                        }

                        Spacer(minLength: MoriTheme.Spacing.xSmall)

                        MoriBitmapIconImage(icon: .chevron, size: 14, opacity: 0.58)
                    }

                    LazyVGrid(columns: columns, spacing: 7) {
                        ForEach(days) { day in
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(previewFill(for: day))
                                .aspectRatio(1, contentMode: .fit)
                                .opacity(day.isFuture ? 0.34 : 1)
                        }
                    }
                }
            }
        }
        .buttonStyle(MoriComponentPressButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(MoriL10n.display(title))
        .accessibilityValue(MoriL10n.display(summary))
    }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(minimum: 5), spacing: 7),
            count: columnCount
        )
    }

    private func previewFill(for day: MoriLifeGridPreviewDay) -> Color {
        guard let tone = day.tone else {
            return MoriTheme.Colors.noEntry.opacity(0.56)
        }

        return tone.color.opacity(0.66)
    }
}

// MARK: - Private component support

private struct MoriMoodFace: View {
    let tone: MoriMoodTone

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)

            ZStack {
                Circle()
                    .fill(tone.color.opacity(0.12))
                    .overlay(
                        Circle()
                            .stroke(tone.color.opacity(0.72), lineWidth: 1.25)
                    )

                HStack(spacing: size * 0.22) {
                    Circle()
                        .fill(tone.color)
                        .frame(width: size * 0.07, height: size * 0.07)
                    Circle()
                        .fill(tone.color)
                        .frame(width: size * 0.07, height: size * 0.07)
                }
                .offset(y: -size * 0.10)

                moodMouth(size: size)
                    .stroke(
                        tone.color,
                        style: StrokeStyle(lineWidth: 1.35, lineCap: .round)
                    )
            }
            .frame(width: size, height: size)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityHidden(true)
    }

    private func moodMouth(size: CGFloat) -> Path {
        Path { path in
            let start = CGPoint(x: size * 0.31, y: size * 0.59)
            let end = CGPoint(x: size * 0.69, y: size * 0.59)
            let controlY: CGFloat

            switch tone {
            case .good:
                controlY = size * 0.75
            case .neutral:
                controlY = size * 0.59
            case .difficult:
                controlY = size * 0.45
            }

            path.move(to: start)
            path.addQuadCurve(
                to: end,
                control: CGPoint(x: size * 0.50, y: controlY)
            )
        }
    }
}

private struct MoriPlayTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

private struct MoriComponentPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(
                reduceMotion || !configuration.isPressed
                    ? 1
                    : MoriTheme.Animation.pressScale
            )
            .opacity(configuration.isPressed ? 0.91 : 1)
            .animation(
                reduceMotion ? nil : MoriTheme.Animation.control,
                value: configuration.isPressed
            )
    }
}

private extension View {
    func moriThemeShadow(_ shadow: MoriTheme.Shadow?) -> some View {
        self.shadow(
            color: shadow?.color ?? .clear,
            radius: shadow?.radius ?? 0,
            x: shadow?.x ?? 0,
            y: shadow?.y ?? 0
        )
    }
}

#Preview("Mori design system") {
    MoriDesignSystemPreview()
}

#Preview("Mori bottom sheet") {
    MoriBottomSheet(
        title: "July 17, 2026",
        subtitle: "Calm"
    ) {
        MoriCard(tone: .warm, shadow: nil) {
            Text("Worked slowly and felt clear.")
                .font(MoriTheme.Typography.body)
                .foregroundColor(MoriTheme.Colors.ink)
        }

        MoriPrimaryButton(title: "View full entry", action: {})
    }
}

private struct MoriDesignSystemPreview: View {
    @State private var mood: MoriMoodTone? = .good

    private let previewDays: [MoriLifeGridPreviewDay] = (1...28).map { day in
        let tone: MoriMoodTone? = day.isMultiple(of: 5)
            ? .difficult
            : (day.isMultiple(of: 3) ? .neutral : (day.isMultiple(of: 2) ? .good : nil))
        return MoriLifeGridPreviewDay(id: day, tone: tone)
    }

    var body: some View {
        MoriPage(scene: .lifeGrid, landscapePlacement: .lowerThird) {
            MoriPageHeader(
                eyebrow: "",
                title: "Mori",
                subtitle: "See the shape of your days.",
                showsEyebrow: false
            )

            MoriSectionHeader(title: "Mood", subtitle: "Notice how today feels.")
            MoriMoodSelector(selection: $mood)

            MoriModeCard(
                title: "Deep Session",
                description: "Work, study, or create with apps blocked.",
                duration: "25 min",
                scene: .deepSession,
                emphasis: .primary,
                action: {}
            )

            MoriLifeGridPreview(
                summary: "July · 11 days remembered",
                days: previewDays,
                action: {}
            )

            HStack(spacing: MoriTheme.Spacing.xSmall) {
                MoriCalendarCell(
                    day: 16,
                    tone: .good,
                    indicators: [.note, .quiet]
                )
                MoriCalendarCell(
                    day: 17,
                    tone: .good,
                    indicators: [.photo],
                    isToday: true,
                    isSelected: true
                )
                MoriCalendarCell(day: 18, isFuture: true)
            }

            MoriFloatingPanel {
                Text("42 quiet minutes")
                    .font(MoriTheme.Typography.body)
                    .foregroundColor(MoriTheme.Colors.ink)
            }

            MoriPrimaryButton(title: "Start Deep Session", action: {})
            MoriSecondaryButton(title: "Not now", action: {})
        }
    }
}
