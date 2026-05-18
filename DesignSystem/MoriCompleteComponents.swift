//
//  MoriCompleteComponents.swift
//  Mori
//
//  Complete UI components for Mori Design System v1.0
//  Extends base components with layout, form, and progress components
//

import SwiftUI

// MARK: - Mori Layout Components
/// Grid system based on design spec
struct MoriGrid<Content: View>: View {
    let columns: Int
    let spacing: CGFloat
    let content: Content
    
    init(columns: Int, spacing: CGFloat = MoriSpacing.space3, @ViewBuilder content: () -> Content) {
        self.columns = columns
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: columns), spacing: spacing) {
            content
        }
    }
}

/// Responsive grid that adapts to screen size
struct MoriResponsiveGrid<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                .init(.flexible(), spacing: MoriSpacing.space3),
                .init(.flexible(), spacing: MoriSpacing.space3)
            ], spacing: MoriSpacing.space3) {
                content
            }
            .padding(.horizontal, MoriSpacing.screenHorizontal)
        }
    }
}

/// HStack with Mori styling
struct MoriHStack<Content: View>: View {
    let spacing: CGFloat
    let alignment: VerticalAlignment
    let content: Content
    
    init(spacing: CGFloat = MoriSpacing.space3, alignment: VerticalAlignment = .center, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.alignment = alignment
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: spacing, alignment: alignment) {
            content
        }
    }
}

/// VStack with Mori styling
struct MoriVStack<Content: View>: View {
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: Content
    
    init(spacing: CGFloat = MoriSpacing.space3, alignment: HorizontalAlignment = .leading, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.alignment = alignment
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: spacing, alignment: alignment) {
            content
        }
    }
}

// MARK: - Mori Form Components
/// Checkbox component
struct MoriCheckbox: View {
    @Binding var isSelected: Bool
    let label: String
    
    var body: some View {
    Button(action: {
        isSelected.toggle()
    }) {
        HStack(spacing: MoriSpacing.space2) {
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isSelected ? MoriColors.accentAmber : MoriColors.softTaupe)
                .frame(width: 24, height: 24)
            
            Text(label)
                .font(MoriTypography.body)
                .foregroundColor(MoriColors.warmCharcoal)
        }
        .padding(.vertical, MoriSpacing.space1)
    }
    .buttonStyle(PlainButtonStyle())
    }
}

/// Toggle component
struct MoriToggle: View {
    @Binding var isOn: Bool
    let label: String
    
    var body: some View {
        HStack(spacing: MoriSpacing.space3) {
            Text(label)
                .font(MoriTypography.body)
                .foregroundColor(MoriColors.warmCharcoal)
            
            Spacer()
            
            Button(action: {
                isOn.toggle()
            }) {
                HStack(spacing: MoriSpacing.space2) {
                    Circle()
                        .fill(isOn ? MoriColors.accentAmber : Color.clear)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(MoriColors.warmGray, lineWidth: 2)
                        )
                    
                    if isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, MoriSpacing.space1)
    }
}

/// Radio button group
struct MoriRadioGroup<Selection: Hashable>: View {
    @Binding var selection: Selection?
    let options: [Selection]
    let labelForOption: (Selection) -> String
    let keyForOption: (Selection) -> String
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selection = option
                }) {
                    HStack(spacing: MoriSpacing.space2) {
                        Circle()
                            .fill(selection == option ? MoriColors.accentAmber : Color.clear)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(MoriColors.warmGray, lineWidth: 2)
                            )
                        
                        Text(labelForOption(option))
                            .font(MoriTypography.body)
                            .foregroundColor(MoriColors.warmCharcoal)
                    }
                    .padding(.vertical, MoriSpacing.space1)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

/// Segmented control
struct MoriSegmentedControl<Selection: Hashable>: View {
    @Binding var selection: Selection
    let options: [Selection]
    let labelForOption: (Selection) -> String
    
    var body: some View {
    HStack(spacing: 0) {
        ForEach(options, id: \.self) { option in
            Button(action: {
                selection = option
            }) {
                Text(labelForOption(option))
                    .font(MoriTypography.body)
                    .foregroundColor(selection == option ? MoriColors.deepEspresso : MoriColors.softTaupe)
                    .padding(.horizontal, MoriSpacing.buttonHorizontal)
                    .padding(.vertical, MoriSpacing.space2)
                    .background(
                        RoundedRectangle(cornerRadius: MoriCornerRadius.button)
                            .fill(selection == option ? MoriColors.softCream : Color.clear)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .overlay(
                Rectangle()
                    .fill(MoriColors.accentAmber)
                    .frame(height: 3)
                    .offset(y: 10)
                    .opacity(selection == option ? 1 : 0)
            )
        }
    }
    .padding(MoriSpacing.space1)
    .background(
        RoundedRectangle(cornerRadius: MoriCornerRadius.button)
            .fill(MoriColors.softCream)
    )
    }
}

// MARK: - Mori Progress Components
/// Progress bar
struct MoriProgressBar: View {
    let progress: Double
    let color: Color = MoriColors.accentAmber
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(MoriColors.warmGray.opacity(0.3))
                    .frame(width: geometry.size.width, height: 8)
                    .cornerRadius(MoriCornerRadius.small)
                
                // Progress
                Rectangle()
                    .fill(color)
                    .frame(width: max(0, min(geometry.size.width * progress, geometry.size.width)), height: 8)
                    .cornerRadius(MoriCornerRadius.small)
                    .animation(MoriAnimation.standard, value: progress)
            }
        }
        .frame(height: 8)
    }
}

/// Circular progress indicator
struct MoriCircularProgress: View {
    let progress: Double
    let size: CGFloat
    let color: Color = MoriColors.accentAmber
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(MoriColors.warmGray.opacity(0.3), lineWidth: 6)
            
            Circle()
                .stroke(color, lineWidth: 6)
                .trim(from: 0, to: progress)
                .rotationEffect(.degrees(-90))
                .animation(MoriAnimation.standard, value: progress)
                .overlay(
                    GeometryReader { geometry in
                        Circle()
                            .fill(Color.clear)
                            .frame(width: size, height: size)
                    }
                )
        }
        .frame(width: size, height: size)
    }
}

/// Loading spinner
struct MoriLoadingSpinner: View {
    let size: CGFloat
    let color: Color
    
    init(size: CGFloat = 24, color: Color = MoriColors.accentAmber) {
        self.size = size
        self.color = color
    }
    
    var body: some View {
        Circle()
            .stroke(color.opacity(0.3), lineWidth: 3)
            .overlay(
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(color, lineWidth: 3)
                    .rotationEffect(.degrees(-90))
                    .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: UUID())
            )
            .frame(width: size, height: size)
    }
}

/// Activity indicator
struct MoriActivityIndicator: View {
    let text: String?
    
    var body: some View {
        HStack(spacing: MoriSpacing.space3) {
            MoriLoadingSpinner()
            
            if let text = text {
                Text(text)
                    .font(MoriTypography.body)
                    .foregroundColor(MoriColors.softTaupe)
            }
        }
    }
}

// MARK: - Mori Modal Components
/// Bottom sheet
struct MoriBottomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background overlay
                Color.black.opacity(isPresented ? 0.3 : 0)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = false
                    }
                    .animation(MoriAnimation.standard, value: isPresented)
                
                // Sheet content
                VStack(spacing: 0) {
                    // Handle
                    RoundedRectangle(cornerRadius: MoriCornerRadius.small)
                        .fill(MoriColors.warmGray.opacity(0.5))
                        .frame(width: 40, height: 4)
                        .padding(.top, MoriSpacing.space3)
                    
                    content
                        .padding(MoriSpacing.space6)
                }
                .frame(maxWidth: .infinity)
                .background(MoriColors.softCream)
                .cornerRadius(MoriCornerRadius.large, corners: [.topLeft, .topRight])
                .offset(y: isPresented ? 0 : geometry.size.height)
                .animation(MoriAnimation.screenTransition, value: isPresented)
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }
}

/// Alert with customization
struct MoriAlert<Content: View>: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let content: Content
    
    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    // Alert appears
                }
            }
    }
}

extension View {
    func moriAlert(isPresented: Binding<Bool>, title: String, @ViewBuilder content: () -> some View) -> some View {
        modifier(
            MoriAlert(
                isPresented: isPresented,
                title: title,
                content: content
            )
        )
    }
}

// MARK: - Mori Theme System
/// Complete theme configuration
struct MoriTheme {
    static var light: MoriThemeStyle {
        MoriThemeStyle(
            background: MoriColors.creamWhite,
            surface: MoriColors.softCream,
            primary: MoriColors.warmCharcoal,
            secondary: MoriColors.softTaupe,
            accent: MoriColors.accentAmber,
            success: MoriColors.softSage,
            warning: MoriColors.morningGold,
            error: MoriColors.warmClay
        )
    }
    
    static var dark: MoriThemeStyle {
        MoriThemeStyle(
            background: MoriColors.moriDark,
            surface: Color(hex: "#12151C"),
            primary: MoriColors.moriCream,
            secondary: Color(hex: "#9CA3AF"),
            accent: MoriColors.accentAmber,
            success: MoriColors.softSage,
            warning: MoriColors.morningGold,
            error: MoriColors.warmClay
        )
    }
}

/// Theme style definition
struct MoriThemeStyle {
    let background: Color
    let surface: Color
    let primary: Color
    let secondary: Color
    let accent: Color
    let success: Color
    let warning: Color
    let error: Color
}

// MARK: - Mori Typography Extensions
/// Extended typography for different contexts
extension MoriTypography {
    /// Large title - 32pt Semibold
    static let largeTitle = Font.system(size: 32, weight: .semibold)
    
    /// Headline - 24pt Medium
    static let headline = Font.system(size: 24, weight: .medium)
    
    /// Subtitle - 18pt Regular
    static let subtitle = Font.system(size: 18, weight: .regular)
    
    /// Footnote - 13pt Regular
    static let footnote = Font.system(size: 13, weight: .regular)
    
    /// Small caption - 11pt Regular
    static let smallCaption = Font.system(size: 11, weight: .regular)
}

// MARK: - Mori Shadow Extensions
/// Extended shadow system
extension MoriShadow {
    /// Strong card shadow
    static let cardStrong = (
        radius: CGFloat(16),
        opacity: Double(0.12),
        y: CGFloat(4)
    )
    
    /// Light shadow
    static let light = (
        radius: CGFloat(4),
        opacity: Double(0.04),
        y: CGFloat(1)
    )
    
    /// Overlay shadow
    static let overlay = (
        radius: CGFloat(32),
        opacity: Double(0.16),
        y: CGFloat(16)
    )
}

// MARK: - Preview
#if DEBUG
struct MoriCompleteComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Layout Components
                Text("Layout Components")
                    .font(MoriTypography.title2)
                    .foregroundColor(MoriColors.warmCharcoal)
                
                MoriGrid(columns: 2, spacing: MoriSpacing.space3) {
                    ForEach(0..<4, id: \.self) { index in
                        MoriCard {
                            Text("Item \(index + 1)")
                                .font(MoriTypography.body)
                        }
                    }
                }
                
                // Form Components
                Text("Form Components")
                    .font(MoriTypography.title2)
                    .foregroundColor(MoriColors.warmCharcoal)
                    .padding(.top, MoriSpacing.space5)
                
                VStack(spacing: 15) {
                    @State var isSelected = false
                    @State var isOn = false
                    @State var radioSelection: String? = "option1"
                    
                    MoriCheckbox(isSelected: $isSelected, label: "Check me")
                    
                    MoriToggle(isOn: $isOn, label: "Enable feature")
                    
                    MoriRadioGroup(
                        selection: $radioSelection,
                        options: ["option1", "option2", "option3"],
                        labelForOption: { $0 },
                        keyForOption: { $0 }
                    )
                }
                .padding(MoriSpacing.space4)
                .background(MoriColors.softCream)
                .cornerRadius(MoriCornerRadius.card)
                
                // Progress Components
                Text("Progress Components")
                    .font(MoriTypography.title2)
                    .foregroundColor(MoriColors.warmCharcoal)
                    .padding(.top, MoriSpacing.space5)
                
                VStack(spacing: 20) {
                    MoriProgressBar(progress: 0.6)
                    
                    MoriCircularProgress(progress: 0.75, size: 80)
                    
                    MoriActivityIndicator(text: "Loading...")
                }
                .padding(MoriSpacing.space4)
                .background(MoriColors.softCream)
                .cornerRadius(MoriCornerRadius.card)
            }
            .padding()
            .background(MoriColors.creamWhite)
        }
    }
}
#endif
