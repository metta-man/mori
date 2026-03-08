//
//  MoriTabView.swift
//  Mori
//
//  Tab navigation based on design spec
//

import SwiftUI

// MARK: - Mori Tab Bar
/// Custom tab bar with warm styling
struct MoriTabBar: View {
    @Binding var selectedTab: Int
    
    let tabs = [
        (icon: "square.grid.3x3", label: "Grid"),
        (icon: "minus.circle", label: "Habits"),
        (icon: "clock", label: "Home"),
        (icon: "heart", label: "Journal")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(MoriAnimation.standard) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: MoriSpacing.space1) {
                        Image(systemName: selectedTab == index ? tabs[index].icon : tabs[index].icon)
                            .font(.system(size: MoriIconSize.tabBar, weight: .medium))
                            .foregroundColor(selectedTab == index ? MoriColors.accentAmber : MoriColors.softTaupe)
                            .scaleEffect(selectedTab == index ? 1.1 : 1.0)
                            .animation(MoriAnimation.standard, value: selectedTab)
                        
                        Text(tabs[index].label)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(selectedTab == index ? MoriColors.accentAmber : MoriColors.softTaupe)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MoriSpacing.space2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, MoriSpacing.space4)
        .padding(.bottom, MoriSpacing.space2)
        .background(
            MoriColors.softCream
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: -2)
        )
    }
}

// MARK: - Mori Navigation Bar
/// Top navigation bar
struct MoriNavigationBar: View {
    let title: String
    var leftIcon: String? = nil
    var rightIcon: String? = nil
    var leftAction: (() -> Void)? = nil
    var rightAction: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            if let leftIcon = leftIcon, let leftAction = leftAction {
                Button(action: leftAction) {
                    Image(systemName: leftIcon)
                        .font(.system(size: 22))
                        .foregroundColor(MoriColors.softTaupe)
                        .frame(width: MoriHitTarget.minimum, height: MoriHitTarget.minimum)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
            
            Text(title)
                .font(MoriTypography.title2)
                .foregroundColor(MoriColors.warmCharcoal)
            
            Spacer()
            
            if let rightIcon = rightIcon, let rightAction = rightAction {
                Button(action: rightAction) {
                    Image(systemName: rightIcon)
                        .font(.system(size: 22))
                        .foregroundColor(MoriColors.softTaupe)
                        .frame(width: MoriHitTarget.minimum, height: MoriHitTarget.minimum)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, MoriSpacing.screenHorizontal)
        .padding(.vertical, MoriSpacing.space3)
    }
}

// MARK: - Preview
#if DEBUG
struct MoriTabView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            MoriTabBar(selectedTab: .constant(0))
        }
        .background(MoriColors.creamWhite)
    }
}
#endif
