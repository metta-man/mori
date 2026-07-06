import SwiftUI

struct MoriBottomTabBarOverlay: View {
    let selectedTab: AppTab
    let onSelectTab: (AppTab) -> Void

    var body: some View {
        MoriSanctuaryBottomTabBar(
            selectedTab: selectedTab,
            onSelectTab: onSelectTab
        )
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity)
        .frame(height: MoriMainTabBarMetrics.overlayHeight, alignment: .bottom)
        .ignoresSafeArea(edges: .bottom)
    }
}

private struct MoriSanctuaryBottomTabBar: View {
    let selectedTab: AppTab
    let onSelectTab: (AppTab) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                MoriTabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    onSelect: {
                        withAnimation(MoriAnimation.standard) {
                            onSelectTab(tab)
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 6)
        .frame(width: 292, height: MoriMainTabBarMetrics.barHeight)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.36), lineWidth: 1)
                )
                .shadow(color: MoriColors.sanctuaryShadow.opacity(0.12), radius: 16, x: 0, y: 8)
        )
        .padding(.horizontal, 16)
    }
}

private struct MoriTabBarItem: View {
    let tab: AppTab
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 2) {
                MoriBitmapIconImage(
                    icon: tab.bitmapIcon,
                    size: isSelected ? 27 : 25,
                    opacity: isSelected ? 1 : 0.68
                )
                .frame(width: 34, height: 28)

                Text(tab.title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? MoriColors.sanctuaryInk : MoriColors.sanctuaryMuted.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(height: 15)

                Capsule(style: .continuous)
                    .fill(isSelected ? MoriColors.sanctuaryInk : Color.clear)
                    .frame(width: isSelected ? 22 : 6, height: 2)
                    .opacity(isSelected ? 0.88 : 0)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
