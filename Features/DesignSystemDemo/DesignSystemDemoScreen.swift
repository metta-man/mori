//
//  DesignSystemDemoScreen.swift
//  Mori
//
//  Demonstration screen for complete Mori Design System v1.0
//  This screen showcases all components in the design system
//

import SwiftUI

struct DesignSystemDemoScreen: View {
    @State private var demoData = DemoData()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Mori Design System")
                        .font(MoriTypography.display)
                        .foregroundColor(MoriColors.warmCharcoal)
                    
                    Text("v1.0 Complete Implementation")
                        .font(MoriTypography.subtitle)
                        .foregroundColor(MoriColors.softTaupe)
                }
                .padding(.horizontal, MoriSpacing.space7)
                .padding(.top, MoriSpacing.space5)
                
                // Component sections
                designTokensSection
                layoutComponentsSection
                buttonComponentsSection
                formComponentsSection
                progressComponentsSection
                navigationComponentsSection
                stateComponentsSection
                
                // Footer
                Text("All components built with warm, accessible design principles")
                    .font(MoriTypography.caption)
                    .foregroundColor(MoriColors.softTaupe)
                    .padding(.horizontal, MoriSpacing.space7)
                    .padding(.bottom, MoriSpacing.space8)
            }
        }
        .background(MoriColors.creamWhite)
    }
    
    // MARK: - Design Tokens Section
    private var designTokensSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Design Tokens")
                .font(MoriTypography.title2)
                .foregroundColor(MoriColors.warmCharcoal)
            
            MoriCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Colors")
                            .font(MoriTypography.subtitle)
                            .foregroundColor(MoriColors.warmCharcoal)
                        Spacer()
                    }
                    
                    // Color palette
                    HStack(spacing: MoriSpacing.space2) {
                        colorSample(name: "Cream", color: MoriColors.creamWhite)
                        colorSample(name: "Soft Cream", color: MoriColors.softCream)
                        colorSample(name: "Charcoal", color: MoriColors.warmCharcoal)
                        colorSample(name: "Amber", color: MoriColors.accentAmber)
                        colorSample(name: "Sage", color: MoriColors.softSage)
                        colorSample(name: "Clay", color: MoriColors.warmClay)
                    }
                    
                    HStack {
                        Text("Typography")
                            .font(MoriTypography.subtitle)
                            .foregroundColor(MoriColors.warmCharcoal)
                        Spacer()
                    }
                    
                    VStack(spacing: 4) {
                        Text("Display: 48pt Light")
                            .font(MoriTypography.display)
                            .foregroundColor(MoriColors.warmCharcoal)
                        
                        Text("Title 1: 28pt Semibold")
                            .font(MoriTypography.title1)
                            .foregroundColor(MoriColors.warmCharcoal)
                        
                        Text("Title 2: 22pt Semibold")
                            .font(MoriTypography.title2)
                            .foregroundColor(MoriColors.warmCharcoal)
                        
                        Text("Body: 17pt Regular")
                            .font(MoriTypography.body)
                            .foregroundColor(MoriColors.warmCharcoal)
                        
                        Text("Caption: 14pt Regular")
                            .font(MoriTypography.caption)
                            .foregroundColor(MoriColors.softTaupe)
                    }
                }
            }
            .padding(MoriSpacing.space4)
        }
        .padding(.horizontal, MoriSpacing.space7)
    }
    
    // MARK: - Layout Components Section
    private var layoutComponentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Layout Components")
                .font(MoriTypography.title2)
                .foregroundColor(MoriColors.warmCharcoal)
            
            MoriCard {
                VStack(spacing: 16) {
                    Text("Grid System")
                        .font(MoriTypography.subtitle)
                        .foregroundColor(MoriColors.warmCharcoal)
                    
                    MoriGrid(columns: 2, spacing: MoriSpacing.space3) {
                        ForEach(0..<4, id: \.self) { index in
                            MoriCard {
                                Text("Item \(index + 1)")
                                    .font(MoriTypography.body)
                                    .foregroundColor(MoriColors.warmCharcoal)
                            }
                        }
                    }
                    
                    Text("Responsive Grid")
                        .font(MoriTypography.subtitle)
                        .foregroundColor(MoriColors.warmCharcoal)
                        .padding(.top, 8)
                    
                    MoriResponsiveGrid {
                        ForEach(0..<6, id: \.self) { index in
                            MoriCard {
                                VStack {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(MoriColors.accentAmber)
                                    Text("Card \(index + 1)")
                                        .font(MoriTypography.body)
                                        .foregroundColor(MoriColors.warmCharcoal)
                                }
                                .padding(MoriSpacing.space3)
                            }
                        }
                    }
                }
            }
            .padding(MoriSpacing.space4)
        }
        .padding(.horizontal, MoriSpacing.space7)
    }
    
    // MARK: - Button Components Section
    private var buttonComponentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Button Components")
                .font(MoriTypography.title2)
                .foregroundColor(MoriColors.warmCharcoal)
            
            MoriCard {
                VStack(spacing: 16) {
                    MoriButton(title: "Primary Action") {
                        showToast("Primary button tapped")
                    }
                    
                    MoriSecondaryButton(title: "Secondary Action") {
                        showToast("Secondary button tapped")
                    }
                    
                    MoriButton(title: "Disabled", isEnabled: false) {
                        // This won't trigger
                    }
                    
                    MoriSecondaryButton(title: "Disabled", isEnabled: false) {
                        // This won't trigger
                    }
                    
                    HStack(spacing: MoriSpacing.space4) {
                        MoriIconButton(systemName: "heart") {
                            showToast("Heart icon tapped")
                        }
                        
                        MoriIconButton(systemName: "star", isActive: true) {
                            showToast("Star icon tapped")
                        }
                        
                        MoriIconButton(systemName: "plus", size: 56, iconSize: 28) {
                            showToast("Large plus icon tapped")
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(MoriSpacing.space4)
        }
        .padding(.horizontal, MoriSpacing.space7)
    }
    
    // MARK: - Form Components Section
    private var formComponentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Form Components")
                .font(MoriTypography.title2)
                .foregroundColor(MoriColors.warmCharcoal)
            
            MoriCard {
                VStack(spacing: 16) {
                    MoriTextField(text: $demoData.name, placeholder: "Enter your name")
                        .padding(.horizontal, MoriSpacing.space2)
                    
                    MoriTextField(text: $demoData.email, placeholder: "Email address")
                        .padding(.horizontal, MoriSpacing.space2)
                    
                    MoriToggle(isOn: $demoData.newsletter, label: "Subscribe to newsletter")
                    
                    MoriCheckbox(isSelected: $demoData.agreeTerms, label: "I agree to terms and conditions")
                    
                    MoriSegmentedControl(
                        selection: $demoData.accountType,
                        options: ["Personal", "Business"],
                        labelForOption: { $0 }
                    )
                    
                    MoriRadioGroup(
                        selection: $demoData.plan,
                        options: ["Free", "Pro", "Enterprise"],
                        labelForOption: { $0 },
                        keyForOption: { $0 }
                    )
                }
                .padding(MoriSpacing.space4)
            }
            .padding(MoriSpacing.space4)
        }
        .padding(.horizontal, MoriSpacing.space7)
    }
    
    // MARK: - Progress Components Section
    private var progressComponentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress Components")
                .font(MoriTypography.title2)
                .foregroundColor(MoriColors.warmCharcoal)
            
            MoriCard {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("Progress Bar")
                            .font(MoriTypography.subtitle)
                            .foregroundColor(MoriColors.warmCharcoal)
                        
                        MoriProgressBar(progress: demoData.progressBarProgress)
                        
                        Slider(value: $demoData.progressBarProgress, in: 0...1) {
                            Text("Progress")
                        }
                    }
                    
                    VStack(spacing: 8) {
                        Text("Circular Progress")
                            .font(MoriTypography.subtitle)
                            .foregroundColor(MoriColors.warmCharcoal)
                        
                        MoriCircularProgress(progress: demoData.circularProgressProgress, size: 80)
                        
                        Slider(value: $demoData.circularProgressProgress, in: 0...1) {
                            Text("Circular Progress")
                        }
                    }
                    
                    VStack(spacing: 8) {
                        Text("Loading States")
                            .font(MoriTypography.subtitle)
                            .foregroundColor(MoriColors.warmCharcoal)
                        
                        MoriActivityIndicator(text: "Loading data...")
                        
                        MoriLoadingSpinner(size: 32)
                    }
                }
                .padding(MoriSpacing.space4)
            }
            .padding(MoriSpacing.space4)
        }
        .padding(.horizontal, MoriSpacing.space7)
    }
    
    // MARK: - Navigation Components Section
    private var navigationComponentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Navigation Components")
                .font(MoriTypography.title2)
                .foregroundColor(MoriColors.warmCharcoal)
            
            MoriCard {
                VStack(spacing: 16) {
                    Text("Tab Bar")
                        .font(MoriTypography.subtitle)
                        .foregroundColor(MoriColors.warmCharcoal)
                    
                    MoriTabBar(selectedTab: $demoData.selectedTab)
                    
                    Text("Navigation Bar")
                        .font(MoriTypography.subtitle)
                        .foregroundColor(MoriColors.warmCharcoal)
                        .padding(.top, 8)
                    
                    MoriNavigationBar(
                        title: "Profile",
                        leftIcon: "chevron.left",
                        rightIcon: "ellipsis"
                    ) {
                        showToast("Back tapped")
                    } rightAction: {
                        showToast("Menu tapped")
                    }
                }
            }
            .padding(MoriSpacing.space4)
        }
        .padding(.horizontal, MoriSpacing.space7)
    }
    
    // MARK: - State Components Section
    private var stateComponentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("State Components")
                .font(MoriTypography.title2)
                .foregroundColor(MoriColors.warmCharcoal)
            
            MoriCard {
                VStack(spacing: 20) {
                    MoriEmptyState(
                        icon: "book.closed",
                        title: "No entries yet",
                        message: "Start your journey by creating your first gratitude entry",
                        buttonTitle: "Get Started"
                    ) {
                        showToast("Create first entry")
                    }
                    
                    MoriErrorState(
                        message: "Unable to load content",
                        retryAction: {
                            showToast("Retry action")
                        }
                    )
                    
                    MoriCountdownDisplay(days: 12847, subtitle: "days remaining")
                    
                    HStack(spacing: MoriSpacing.space4) {
                        MoriHabitButton(isDone: true) {
                            showToast("Habit completed")
                        }
                        
                        MoriHabitButton(isDone: false) {
                            showToast("Habit marked")
                        }
                    }
                }
                .padding(MoriSpacing.space4)
            }
            .padding(MoriSpacing.space4)
        }
        .padding(.horizontal, MoriSpacing.space7)
    }
    
    // MARK: - Helper Methods
    private func colorSample(name: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(color)
                .frame(width: 40, height: 40)
                .cornerRadius(MoriCornerRadius.small)
            
            Text(name)
                .font(MoriTypography.smallCaption)
                .foregroundColor(MoriColors.softTaupe)
        }
    }
    
    private func showToast(_ message: String) {
        demoData.toastMessage = message
        demoData.showToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            demoData.showToast = false
        }
    }
}

// MARK: - Demo Data
private struct DemoData {
    @State var name = ""
    @State var email = ""
    @State var newsletter = false
    @State var agreeTerms = false
    @State var accountType = "Personal"
    @State var plan: String? = "Free"
    @State var progressBarProgress: Double = 0.6
    @State var circularProgressProgress: Double = 0.75
    @State var selectedTab = 0
    @State var toastMessage = ""
    @State var showToast = false
}

// MARK: - Preview
#Preview {
    DesignSystemDemoScreen()
}

// MARK: - Secure Field Extension
extension SecureField where Label == Text {
    init(placeholder: String, @ViewBuilder content: @escaping () -> some View) {
        self.init(
            text: .constant(""),
            onCommit: { }
        ) {
            content()
        }
    }
}
