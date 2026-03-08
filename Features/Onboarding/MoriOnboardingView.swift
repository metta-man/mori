//
//  MoriOnboardingView.swift
//  Mori
//
//  Enhanced 5-screen onboarding flow based on Flare's design spec
//  Task: j57ft26sj2z3awasgxjwjjw5x182dvaa
//

import SwiftUI

// MARK: - Mori Onboarding View
struct MoriOnboardingView: View {
    @EnvironmentObject var userSettings: UserSettings
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var currentScreen = 0
    @State private var animationProgress: Double = 0
    
    private let totalScreens = 5
    
    var body: some View {
        ZStack {
            // Background
            MoriColors.creamWhite
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Bar
                MoriProgressBar(
                    currentStep: currentScreen,
                    totalSteps: totalScreens
                )
                .padding(.top, 60)
                .padding(.horizontal, 24)
                
                // Content
                TabView(selection: $currentScreen) {
                    // Screen 1: Welcome / Life Grid Intro
                    WelcomeScreen(viewModel: viewModel)
                        .tag(0)
                    
                    // Screen 2: Birth Date Input
                    BirthDateScreen(viewModel: viewModel)
                        .tag(1)
                    
                    // Screen 3: Life Grid Preview
                    LifeGridPreviewScreen(viewModel: viewModel)
                        .tag(2)
                    
                    // Screen 4: First Habit Check-in
                    FirstHabitScreen(viewModel: viewModel)
                        .tag(3)
                    
                    // Screen 5: First Gratitude Entry
                    FirstGratitudeScreen(viewModel: viewModel, onComplete: completeOnboarding)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentScreen)
            }
        }
        .preferredColorScheme(.light)
    }
    
    private func completeOnboarding() {
        userSettings.birthDate = viewModel.birthDate
        userSettings.lifeExpectancy = 80
        userSettings.hasCompletedOnboarding = true
        
        // Save first habit entry if selected
        if !viewModel.firstHabitName.isEmpty {
            HabitDataManager.shared.saveEntry(
                habitName: viewModel.firstHabitName,
                isPositive: true
            )
        }
        
        // Save first gratitude to UserDefaults (as simple string for now)
        if !viewModel.firstGratitude.isEmpty {
            var gratitudes = UserDefaults.standard.stringArray(forKey: "gratitude_entries") ?? []
            let entry: [String: Any] = [
                "text": viewModel.firstGratitude,
                "createdAt": Date().timeIntervalSince1970
            ]
            if let data = try? JSONSerialization.data(withJSONObject: entry),
               let jsonString = String(data: data, encoding: .utf8) {
                gratitudes.append(jsonString)
                UserDefaults.standard.set(gratitudes, forKey: "gratitude_entries")
            }
        }
        
        AnalyticsManager.shared.trackOnboardingCompleted()
    }
}

// MARK: - Screen 1: Welcome / Life Grid Introduction
struct WelcomeScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showContent = false
    @State private var gridOpacity: Double = 0
    @State private var cellDelay: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Mori Logo
            Image(systemName: "leaf.fill")
                .font(.system(size: 48))
                .foregroundColor(MoriColors.accentAmber)
                .scaleEffect(showContent ? 1 : 0.8)
                .opacity(showContent ? 1 : 0)
            
            // Intro Grid Preview
            IntroGridView()
                .opacity(gridOpacity)
                .padding(.vertical, 32)
            
            // Title
            Text("你的生命\n以格子呈现")
                .font(.custom("CormorantGaramond-Light", size: 32))
                .foregroundColor(MoriColors.warmCharcoal)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)
            
            // Subtitle
            Text("每一格 = 一周")
                .font(.custom("DM Mono", size: 14))
                .foregroundColor(MoriColors.accentAmber)
                .tracking(0.5)
                .padding(.top, 8)
                .opacity(showContent ? 1 : 0)
            
            // Philosophy Quote
            Text("\"记住死亡，是为了更好地活着\"")
                .font(.custom("Crimson Pro Italic", size: 16))
                .foregroundColor(MoriColors.softTaupe)
                .padding(.top, 24)
                .opacity(showContent ? 1 : 0)
            
            Spacer()
            
            // Start Button
            Button(action: {}) {
                Text("开始探索")
                    .font(.custom("Crimson Pro SemiBold", size: 18))
                    .foregroundColor(MoriColors.deepEspresso)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(MoriColors.accentAmber)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 30)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                gridOpacity = 1
            }
        }
    }
}

// MARK: - Intro Grid View (9x4 preview)
struct IntroGridView: View {
    private let columns = 9
    private let rows = 4
    private let cellSize: CGFloat = 6
    private let spacing: CGFloat = 2
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: columns),
            spacing: spacing
        ) {
            ForEach(0..<(columns * rows), id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index < 12 ? MoriColors.accentAmber : MoriColors.warmCharcoal.opacity(0.3))
                    .frame(width: cellSize, height: cellSize)
            }
        }
        .padding(24)
        .background(MoriColors.softCream)
        .cornerRadius(12)
    }
}

// MARK: - Screen 2: Birth Date Input
struct BirthDateScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Back Button
            HStack {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(MoriColors.softTaupe)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
            
            // Title
            Text("你出生在何时？")
                .font(.custom("CormorantGaramond-Light", size: 28))
                .foregroundColor(MoriColors.warmCharcoal)
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
            
            // Date Picker Card
            VStack(spacing: 16) {
                Image(systemName: "calendar")
                    .font(.system(size: 32))
                    .foregroundColor(MoriColors.accentAmber)
                
                DatePicker(
                    "选择你的出生日期",
                    selection: $viewModel.birthDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .accentColor(MoriColors.accentAmber)
            }
            .padding(24)
            .background(MoriColors.softCream)
            .cornerRadius(16)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .opacity(showContent ? 1 : 0)
            
            // Info Box
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle")
                    .foregroundColor(MoriColors.softTaupe)
                
                Text("我们会用这个计算你的生命格子，数据完全本地存储")
                    .font(.system(size: 13))
                    .foregroundColor(MoriColors.softTaupe)
            }
            .padding(16)
            .background(MoriColors.softCream.opacity(0.6))
            .cornerRadius(8)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .opacity(showContent ? 1 : 0)
            
            Spacer()
            
            // Continue Button
            Button(action: {}) {
                Text("继续")
                    .font(.custom("Crimson Pro SemiBold", size: 18))
                    .foregroundColor(MoriColors.deepEspresso)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(MoriColors.accentAmber)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

// MARK: - Screen 3: Life Grid Preview (Full 80x52)
struct LifeGridPreviewScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showGrid = false
    @State private var showStats = false
    
    private let gridColumns = 9
    
    var body: some View {
        VStack(spacing: 0) {
            // Back Button
            HStack {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(MoriColors.softTaupe)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
            
            // Title
            Text("这是你的人生")
                .font(.custom("CormorantGaramond-Light", size: 28))
                .foregroundColor(MoriColors.warmCharcoal)
                .multilineTextAlignment(.center)
                .opacity(showStats ? 1 : 0)
            
            // Stats
            HStack(spacing: 40) {
                StatView(
                    value: "\(viewModel.weeksLived)",
                    label: "已度过",
                    delay: 0.1
                )
                .opacity(showStats ? 1 : 0)
                
                StatView(
                    value: "\(viewModel.weeksRemaining)",
                    label: "剩余周数",
                    delay: 0.2
                )
                .opacity(showStats ? 1 : 0)
            }
            .padding(.top, 16)
            
            // Full Life Grid (80x52 = 4160 cells)
            ScrollView(.horizontal, showsIndicators: false) {
                LifeGridVisualization(
                    weeksLived: viewModel.weeksLived,
                    totalWeeks: viewModel.totalWeeks
                )
                .scaleEffect(showGrid ? 1 : 0.9)
                .opacity(showGrid ? 1 : 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            
            Spacer()
            
            // Continue Button
            Button(action: {}) {
                Text("继续")
                    .font(.custom("Crimson Pro SemiBold", size: 18))
                    .foregroundColor(MoriColors.deepEspresso)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(MoriColors.accentAmber)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .opacity(showGrid ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                showStats = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
                showGrid = true
            }
        }
    }
}

// MARK: - Life Grid Visualization
struct LifeGridVisualization: View {
    let weeksLived: Int
    let totalWeeks: Int
    
    private let columns = 9
    
    var body: some View {
        let rows = (totalWeeks + columns - 1) / columns
        
        VStack(spacing: 1) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<columns, id: \.self) { col in
                        let weekIndex = row * columns + col
                        if weekIndex < totalWeeks {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(weekIndex < weeksLived ? MoriColors.accentAmber : MoriColors.warmCharcoal.opacity(0.15))
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Stat View
struct StatView: View {
    let value: String
    let label: String
    var delay: Double = 0
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("DM Mono", size: 24))
                .foregroundColor(MoriColors.accentAmber)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(MoriColors.softTaupe)
        }
    }
}

// MARK: - Screen 4: First Habit Check-in
struct FirstHabitScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showContent = false
    @State private var selectedHabit: String?
    
    private let habitOptions = [
        ("💪", "运动"),
        ("📚", "阅读"),
        ("💤", "睡眠"),
        ("💧", "饮水"),
        ("🧘", "冥想"),
        ("✍️", "写作")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Back Button
            HStack {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(MoriColors.softTaupe)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
            
            // Title
            Text("建立你的第一个习惯")
                .font(.custom("CormorantGaramond-Light", size: 28))
                .foregroundColor(MoriColors.warmCharcoal)
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
            
            Text("选择一个你想培养的习惯")
                .font(.system(size: 14))
                .foregroundColor(MoriColors.softTaupe)
                .padding(.top, 8)
                .opacity(showContent ? 1 : 0)
            
            // Habit Options Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(habitOptions, id: \.1) { emoji, name in
                    HabitOptionCard(
                        emoji: emoji,
                        name: name,
                        isSelected: selectedHabit == name
                    ) {
                        selectedHabit = name
                        viewModel.firstHabitName = name
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .opacity(showContent ? 1 : 0)
            
            Spacer()
            
            // Continue Button
            Button(action: {}) {
                Text("继续")
                    .font(.custom("Crimson Pro SemiBold", size: 18))
                    .foregroundColor(MoriColors.deepEspresso)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(selectedHabit != nil ? MoriColors.accentAmber : MoriColors.warmGray)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .opacity(showContent ? 1 : 0)
            .disabled(selectedHabit == nil)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

// MARK: - Habit Option Card
struct HabitOptionCard: View {
    let emoji: String
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 32))
                
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MoriColors.warmCharcoal)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? MoriColors.accentAmber.opacity(0.2) : MoriColors.softCream)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? MoriColors.accentAmber : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Screen 5: First Gratitude Entry
struct FirstGratitudeScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showContent = false
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Back Button
            HStack {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(MoriColors.softTaupe)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
            
            // Title
            Text("今天你感激什么？")
                .font(.custom("CormorantGaramond-Light", size: 28))
                .foregroundColor(MoriColors.warmCharcoal)
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
            
            Text("写下你感激的事物，让生活更有意义")
                .font(.system(size: 14))
                .foregroundColor(MoriColors.softTaupe)
                .padding(.top, 8)
                .opacity(showContent ? 1 : 0)
            
            // Gratitude Input
            VStack(spacing: 16) {
                TextField("我感激...", text: $viewModel.firstGratitude)
                    .font(.system(size: 16))
                    .padding(16)
                    .background(MoriColors.softCream)
                    .cornerRadius(12)
                    .opacity(showContent ? 1 : 0)
                
                // Quick prompts
                HStack(spacing: 8) {
                    ForEach(["家人", "健康", "朋友", "阳光"], id: \.self) { prompt in
                        Button(action: {
                            viewModel.firstGratitude = prompt
                        }) {
                            Text(prompt)
                                .font(.system(size: 12))
                                .foregroundColor(MoriColors.softTaupe)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(MoriColors.softCream)
                                .cornerRadius(16)
                        }
                    }
                }
                .opacity(showContent ? 1 : 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            
            Spacer()
            
            // Complete Button
            Button(action: onComplete) {
                Text("开始旅程")
                    .font(.custom("Crimson Pro SemiBold", size: 18))
                    .foregroundColor(MoriColors.deepEspresso)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(MoriColors.accentAmber)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

// MARK: - Mori Progress Bar
struct MoriProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index <= currentStep ? MoriColors.accentAmber : MoriColors.warmGray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
}

// MARK: - Onboarding View Model
class OnboardingViewModel: ObservableObject {
    @Published var birthDate: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
    @Published var firstHabitName: String = ""
    @Published var firstGratitude: String = ""
    
    var weeksLived: Int {
        LifeWeekCalculator.weeksLived(from: birthDate)
    }
    
    var weeksRemaining: Int {
        LifeWeekCalculator.weeksRemaining(from: birthDate)
    }
    
    var totalWeeks: Int {
        80 * 52
    }
}

// MARK: - Preview
#Preview {
    MoriOnboardingView()
        .environmentObject(UserSettings())
}
