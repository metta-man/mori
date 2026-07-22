import SwiftUI

enum MoriRootHeaderStyle {
    case sanctuary
    case editorial
}

struct MoriPageHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var showsEyebrow = true

    var body: some View {
        VStack(alignment: .leading, spacing: MoriTheme.Spacing.xSmall) {
            if showsEyebrow {
                Text(MoriL10n.display(eyebrow).uppercased())
                    .font(MoriTheme.Typography.micro)
                    .tracking(1.4)
                    .foregroundColor(MoriColors.sanctuarySage)
            }

            Text(MoriL10n.display(title))
                .font(MoriTheme.Typography.pageTitle)
                .foregroundColor(MoriColors.sanctuaryInk)
                .fixedSize(horizontal: false, vertical: true)

            Text(MoriL10n.display(subtitle))
                .font(MoriTypography.callout.weight(.medium))
                .foregroundColor(MoriColors.sanctuaryInkSoft.opacity(0.92))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MoriRootHeader<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let style: MoriRootHeaderStyle
    private let trailing: Trailing

    init(
        title: String,
        subtitle: String? = nil,
        style: MoriRootHeaderStyle = .sanctuary,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: style == .editorial ? 10 : 7) {
                Text(MoriL10n.display(title))
                    .font(
                        style == .editorial
                            ? MoriTheme.Typography.pageTitle
                            : MoriTypography.sanctuaryRootTitle
                    )
                    .foregroundColor(MoriColors.sanctuaryInk)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle {
                    Text(MoriL10n.display(subtitle))
                        .font(
                            style == .editorial
                                ? MoriTheme.Typography.supporting
                                : MoriTypography.callout.weight(.medium)
                        )
                        .foregroundColor(MoriColors.sanctuaryInkSoft.opacity(0.92))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            trailing
                .padding(.top, 2)
        }
    }
}

extension MoriRootHeader where Trailing == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        style: MoriRootHeaderStyle = .sanctuary
    ) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
        self.trailing = EmptyView()
    }
}

struct MoriRootHeaderBlock<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let safeAreaTopInset: CGFloat
    let minimumTopInset: CGFloat?
    let style: MoriRootHeaderStyle
    let topAnchorID: String?
    private let trailing: Trailing

    init(
        title: String,
        subtitle: String? = nil,
        safeAreaTopInset: CGFloat,
        minimumTopInset: CGFloat? = nil,
        style: MoriRootHeaderStyle = .sanctuary,
        topAnchorID: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.safeAreaTopInset = safeAreaTopInset
        self.minimumTopInset = minimumTopInset
        self.style = style
        self.topAnchorID = topAnchorID
        self.trailing = trailing()
    }

    var body: some View {
        rootHeader
            .padding(
                .top,
                max(
                    minimumTopInset ?? 0,
                    MoriRootScreenMetrics.topInset(for: safeAreaTopInset)
                )
            )
            .padding(.bottom, MoriRootScreenMetrics.headerContentGap)
            .applyOptionalID(topAnchorID)
    }

    private var rootHeader: some View {
        MoriRootHeader(
            title: title,
            subtitle: subtitle,
            style: style,
            trailing: { trailing }
        )
    }
}

extension MoriRootHeaderBlock where Trailing == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        safeAreaTopInset: CGFloat,
        minimumTopInset: CGFloat? = nil,
        style: MoriRootHeaderStyle = .sanctuary,
        topAnchorID: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.safeAreaTopInset = safeAreaTopInset
        self.minimumTopInset = minimumTopInset
        self.style = style
        self.topAnchorID = topAnchorID
        self.trailing = EmptyView()
    }
}

private extension View {
    @ViewBuilder
    func applyOptionalID(_ id: String?) -> some View {
        if let id {
            self.id(id)
        } else {
            self
        }
    }
}

struct MoriRootScrollScreen<HeaderTrailing: View, Content: View>: View {
    let title: String
    let subtitle: String?
    var spacing: CGFloat = 18
    var horizontalPadding: CGFloat = 20
    var bottomPadding: CGFloat = MoriMainTabBarMetrics.scrollBottomInset
    var backgroundVariant: MoriBotanicalScreenBackdrop.Variant = .settings
    var showsBackground: Bool = true
    var minimumTopInset: CGFloat?
    var headerStyle: MoriRootHeaderStyle = .sanctuary
    var topAnchorID: String?
    private let onScrollAppear: ((ScrollViewProxy) -> Void)?
    private let headerTrailing: HeaderTrailing
    private let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        spacing: CGFloat = 18,
        horizontalPadding: CGFloat = 20,
        bottomPadding: CGFloat = MoriMainTabBarMetrics.scrollBottomInset,
        backgroundVariant: MoriBotanicalScreenBackdrop.Variant = .settings,
        showsBackground: Bool = true,
        minimumTopInset: CGFloat? = nil,
        headerStyle: MoriRootHeaderStyle = .sanctuary,
        topAnchorID: String? = nil,
        onScrollAppear: ((ScrollViewProxy) -> Void)? = nil,
        @ViewBuilder headerTrailing: () -> HeaderTrailing,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.bottomPadding = bottomPadding
        self.backgroundVariant = backgroundVariant
        self.showsBackground = showsBackground
        self.minimumTopInset = minimumTopInset
        self.headerStyle = headerStyle
        self.topAnchorID = topAnchorID
        self.onScrollAppear = onScrollAppear
        self.headerTrailing = headerTrailing()
        self.content = content()
    }

    var body: some View {
        ZStack {
            if showsBackground {
                MoriPaperBackground(variant: backgroundVariant) {
                    Color.clear
                }
            }

            GeometryReader { proxy in
                ScrollViewReader { scrollProxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: spacing) {
                            MoriRootHeaderBlock(
                                title: title,
                                subtitle: subtitle,
                                safeAreaTopInset: proxy.safeAreaInsets.top,
                                minimumTopInset: minimumTopInset,
                                style: headerStyle,
                                topAnchorID: topAnchorID,
                                trailing: { headerTrailing }
                            )

                            content
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, bottomPadding)
                    }
                    .padding(.top, MoriRootScreenMetrics.visibleScrollTopOffset)
                    .onAppear {
                        onScrollAppear?(scrollProxy)
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

extension MoriRootScrollScreen where HeaderTrailing == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        spacing: CGFloat = 18,
        horizontalPadding: CGFloat = 20,
        bottomPadding: CGFloat = MoriMainTabBarMetrics.scrollBottomInset,
        backgroundVariant: MoriBotanicalScreenBackdrop.Variant = .settings,
        showsBackground: Bool = true,
        minimumTopInset: CGFloat? = nil,
        headerStyle: MoriRootHeaderStyle = .sanctuary,
        topAnchorID: String? = nil,
        onScrollAppear: ((ScrollViewProxy) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.bottomPadding = bottomPadding
        self.backgroundVariant = backgroundVariant
        self.showsBackground = showsBackground
        self.minimumTopInset = minimumTopInset
        self.headerStyle = headerStyle
        self.topAnchorID = topAnchorID
        self.onScrollAppear = onScrollAppear
        self.headerTrailing = EmptyView()
        self.content = content()
    }
}

struct MoriSectionTitle: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(MoriL10n.display(title))
                .font(MoriTypography.sanctuarySection)
                .foregroundColor(MoriColors.sanctuaryInk)

            if let subtitle {
                Text(MoriL10n.display(subtitle))
                    .font(MoriTypography.micro.weight(.medium))
                    .foregroundColor(MoriColors.sanctuaryInkSoft.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
