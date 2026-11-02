import SwiftUI

private struct MoriAvailableWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat = 390
}

extension EnvironmentValues {
    var moriAvailableWidth: CGFloat {
        get { self[MoriAvailableWidthKey.self] }
        set { self[MoriAvailableWidthKey.self] = newValue }
    }
}

enum MoriAdaptiveLayout {
    static func usesColumns(width: CGFloat, accessibility: Bool) -> Bool {
        width >= 760 && !accessibility
    }

    /// Move the interactive surface together; never put a CTA across an active hinge.
    static func interactionRegion(size: CGSize, divisions: [CGRect]) -> CGRect {
        var region = CGRect(origin: .zero, size: size)
        for division in divisions {
            let cut = region.intersection(division)
            guard !cut.isNull, !cut.isEmpty else { continue }
            if cut.height >= region.height * 0.8 {
                let left = CGRect(x: region.minX, y: region.minY, width: max(0, cut.minX - region.minX), height: region.height)
                let right = CGRect(x: cut.maxX, y: region.minY, width: max(0, region.maxX - cut.maxX), height: region.height)
                region = right.width >= 280 || right.width >= left.width ? right : left
            } else if cut.width >= region.width * 0.8 {
                let top = CGRect(x: region.minX, y: region.minY, width: region.width, height: max(0, cut.minY - region.minY))
                let bottom = CGRect(x: region.minX, y: cut.maxY, width: region.width, height: max(0, region.maxY - cut.maxY))
                region = bottom.height >= 220 || bottom.height >= top.height ? bottom : top
            }
        }
        return region
    }
}

/// The view identity stays stable while the window resizes or changes pose.
struct MoriDuoContentRegion<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        GeometryReader { proxy in
            let region = MoriAdaptiveLayout.interactionRegion(size: proxy.size, divisions: divisions(in: proxy))
            content
                .environment(\.moriAvailableWidth, region.width)
                .frame(width: region.width, height: region.height)
                .position(x: region.midX, y: region.midY)
        }
    }

    private func divisions(in proxy: GeometryProxy) -> [CGRect] {
        // Xcode 27.1+ is the supported shipping SDK for Duo. Older toolchains
        // retain the safe-area/available-width layout for existing iPhones.
        #if compiler(>=6.4)
        if #available(iOS 27.1, *) {
            return proxy.reservedRegions(kind: .division).map(\.frame)
        }
        #endif
        return []
    }
}

struct MoriBottomTabBarOverlay: View {
    let selectedTab: AppTab
    let onSelectTab: (AppTab) -> Void

    var body: some View {
        MoriSanctuaryBottomTabBar(
            selectedTab: selectedTab,
            onSelectTab: onSelectTab
        )
        .padding(.bottom, MoriMainTabBarMetrics.floatingBottomSpacing)
        .frame(maxWidth: .infinity)
        .frame(height: MoriMainTabBarMetrics.overlayHeight, alignment: .bottom)
        .background {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: MoriV2Palette.paper.opacity(0.96), location: 0.35),
                    .init(color: MoriV2Palette.paper, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .padding(.top, -MoriMainTabBarMetrics.topClearance)
            .allowsHitTesting(false)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

private struct MoriSanctuaryBottomTabBar: View {
    let selectedTab: AppTab
    let onSelectTab: (AppTab) -> Void

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    MoriTabBarItem(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        onSelect: {
                            onSelectTab(tab)
                        }
                    )
                }
            }
            .padding(.horizontal, 8)
            .frame(
                width: min(
                    MoriMainTabBarMetrics.maximumBarWidth,
                    max(0, proxy.size.width - (MoriMainTabBarMetrics.horizontalMargin * 2))
                ),
                height: MoriMainTabBarMetrics.barHeight
            )
            .background {
                RoundedRectangle(
                    cornerRadius: MoriMainTabBarMetrics.cornerRadius,
                    style: .continuous
                )
                .fill(MoriV2Palette.raisedPaper)
                .shadow(color: MoriV2Palette.forestInk.opacity(0.035), radius: 10, x: 0, y: 3)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: MoriMainTabBarMetrics.barHeight)
    }
}

private struct MoriTabBarItem: View {
    let tab: AppTab
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                MoriInterfaceIcon(
                    icon: tab.bitmapIcon,
                    size: 23,
                    opacity: isSelected ? 1 : 0.72
                )
                .frame(width: 30, height: 25)

                Text(tab.title)
                    .font(.system(size: 11.5, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(MoriV2Palette.forestInk)
                    .opacity(isSelected ? 1 : 0.72)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(height: 15)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .moriReduceMotionAnimation(MoriAnimation.standard, value: isSelected)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
