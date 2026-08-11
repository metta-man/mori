import SwiftUI

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
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(
                        cornerRadius: MoriMainTabBarMetrics.cornerRadius,
                        style: .continuous
                    )
                    .fill(Color.white.opacity(0.28))
                }
                .overlay {
                    RoundedRectangle(
                        cornerRadius: MoriMainTabBarMetrics.cornerRadius,
                        style: .continuous
                    )
                    .stroke(Color.white.opacity(0.52), lineWidth: 0.8)
                }
                .shadow(
                    color: MoriV2Palette.forestInk.opacity(0.08),
                    radius: 30,
                    x: 0,
                    y: 12
                )
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
                MoriBitmapIconImage(
                    icon: tab.bitmapIcon,
                    size: isSelected ? 27 : 25,
                    opacity: isSelected ? 1 : 0.46
                )
                .frame(width: 34, height: 29)

                Text(tab.title)
                    .font(.system(size: 11.5, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(MoriV2Palette.forestInk)
                    .opacity(isSelected ? 1 : 0.46)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(height: 15)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .moriReduceMotionAnimation(MoriAnimation.standard, value: isSelected)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
