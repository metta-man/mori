//
//  MoriOnboardingView.swift
//  Mori
//
//  Updated 3-screen onboarding flow based on market research: Life Grid → Clock → First Weekly Intention
//  Task: j57e6a9p2359eesrr4darj4ah1820nn4
//

import SwiftUI

// MARK: - Mori Onboarding View (3-Step Flow)
struct MoriOnboardingView: View {
    @EnvironmentObject var userSettings: UserSettings
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var currentScreen = 0
    
    private let totalScreens = 3
    
    var body: some View {
        ZStack {
            // Background
            MoriColors.creamWhite
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                OnboardingHeader(
                    currentStep: currentScreen,
                    totalSteps: totalScreens,
                    onBack: goBack,
                    onSkip: currentScreen == 0 ? skipOnboarding : nil
                )
                .padding(.top, 52)
                .padding(.horizontal, 20)
                
                // Content
                TabView(selection: $currentScreen) {
                    // Screen 1: Life Grid Introduction
                    LifeGridIntroductionScreen {
                        advance(to: 1)
                    }
                        .tag(0)
                    
                    // Screen 2: The Clock (Life Countdown)
                    LifeCountdownScreen(viewModel: viewModel) {
                        advance(to: 2)
                    }
                        .tag(1)
                    
                    // Screen 3: First Weekly Intention
                    FirstGratitudeScreen(viewModel: viewModel, onComplete: completeOnboarding)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentScreen)
                .onChange(of: currentScreen) { newValue in
                    viewModel.currentStep = newValue
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            AnalyticsManager.shared.trackOnboardingStarted()
        }
    }
    
    private func completeOnboarding() {
        userSettings.birthDate = viewModel.birthDate
        userSettings.gender = viewModel.gender
        userSettings.locationCountryCode = viewModel.countryCode
        userSettings.locationCountryName = viewModel.countryName
        userSettings.lifeExpectancy = viewModel.lifeExpectancy
        userSettings.hasCompletedOnboarding = true
        userSettings.setWeeklyIntention(
            domain: viewModel.firstIntentionDomain,
            action: viewModel.firstIntentionAction
        )
        
        // Save first gratitude entry
        if !viewModel.firstGratitude.isEmpty {
            GratitudeManager.shared.saveFirstGratitude(viewModel.firstGratitude)
            AnalyticsManager.shared.trackFirstGratitudeEntry()
        }
        
        // Track onboarding completion
        AnalyticsManager.shared.trackOnboardingCompleted()
        
        // Track loop analytics
        AnalyticsManager.shared.trackLoopEvent("onboarding_completed", properties: [
            "steps_completed": 3,
            "time_spent": Date().timeIntervalSince(viewModel.onboardingStartTime)
        ])
    }
    
    private func skipOnboarding() {
        userSettings.hasCompletedOnboarding = true
        AnalyticsManager.shared.trackOnboardingSkipped()
    }

    private func advance(to screen: Int) {
        withAnimation(.easeInOut(duration: 0.35)) {
            currentScreen = screen
            viewModel.currentStep = screen
        }
    }

    private func goBack() {
        guard currentScreen > 0 else { return }
        advance(to: currentScreen - 1)
    }
}

// MARK: - Screen 1: Life Grid Introduction
struct LifeGridIntroductionScreen: View {
    let onContinue: () -> Void
    @State private var showAnimation = false
    @State private var gridOpacity: Double = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                MoriWordmark()
                    .opacity(showAnimation ? 1 : 0)
                    .scaleEffect(showAnimation ? 1 : 0.92)

                VStack(spacing: 12) {
                    Text("Make your weeks visible")
                        .font(MoriTypography.headline1)
                        .foregroundColor(MoriColors.charcoal)
                        .multilineTextAlignment(.center)

                    Text("Mori turns time into a quiet weekly ritual: see the grid, notice the week, choose one thing that matters.")
                        .font(MoriTypography.body)
                        .foregroundColor(MoriColors.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                LifeGridHeroCard(showAnimation: showAnimation, gridOpacity: gridOpacity)

                VStack(spacing: 14) {
                    OnboardingValueRow(
                        iconName: "square.grid.3x3.fill",
                        title: "See the life grid",
                        subtitle: "Each dot is one week, with today held in view."
                    )

                    OnboardingValueRow(
                        iconName: "clock.fill",
                        title: "Personalize the estimate",
                        subtitle: "Use Health and region data when available, or enter it yourself."
                    )

                    OnboardingValueRow(
                        iconName: "heart.text.square.fill",
                        title: "Begin with one intention",
                        subtitle: "Leave onboarding with one small promise for this week."
                    )
                }
                .padding(.top, 2)

                Button {
                    onContinue()
                } label: {
                    Label("Begin", systemImage: "arrow.right")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(MoriPrimaryButtonStyle())
                .padding(.top, 6)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 44)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).delay(0.1)) {
                showAnimation = true
                gridOpacity = 1
            }
        }
    }
}

private struct LifeGridHeroCard: View {
    let showAnimation: Bool
    let gridOpacity: Double

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(MoriColors.charcoal)
                .shadow(color: MoriColors.shadowMedium, radius: 18, x: 0, y: 10)

            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("One life")
                            .font(MoriTypography.caption)
                            .foregroundColor(MoriColors.moriGold)
                            .textCase(.uppercase)

                        Text("in weeks")
                            .font(MoriTypography.title1)
                            .foregroundColor(MoriColors.zenCream)
                    }

                    Spacer()

                    Image(systemName: "hourglass")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(MoriColors.moriGold)
                        .frame(width: 48, height: 48)
                        .background(MoriColors.moriGold.opacity(0.14))
                        .clipShape(Circle())
                }

                HStack {
                    Spacer()

                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(MoriColors.moriCream.opacity(0.08))

                        LifeGridVisualization(
                            rows: 6,
                            columns: 14,
                            filledRatio: 0.25,
                            animate: showAnimation,
                            showLabels: false,
                            filledColor: MoriColors.moriGold,
                            emptyColor: MoriColors.moriCream.opacity(0.18)
                        )
                        .opacity(gridOpacity)
                        .scaleEffect(showAnimation ? 1 : 0.8)
                    }
                    .frame(width: 210, height: 132)

                    Spacer()
                }

                HStack(spacing: 8) {
                    Circle()
                        .fill(MoriColors.moriGold)
                        .frame(width: 7, height: 7)

                    Text("Every dot is a week. This one is yours.")
                        .font(MoriTypography.caption)
                        .foregroundColor(MoriColors.moriCreamMuted)
                }
            }
            .padding(22)
        }
        .frame(height: 304)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Life grid preview. Every dot is a week.")
    }
}

private struct OnboardingValueRow: View {
    let iconName: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: iconName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(MoriColors.moriGold)
                .frame(width: 34, height: 34)
                .background(MoriColors.moriGold.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(MoriTypography.subhead)
                    .foregroundColor(MoriColors.charcoal)

                Text(subtitle)
                    .font(MoriTypography.caption)
                    .foregroundColor(MoriColors.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Screen 2: Life Countdown
struct LifeCountdownScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onContinue: () -> Void
    @State private var revealMetrics = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 16) {
                    Text("Your Life, Visualized")
                        .font(MoriTypography.headline1)
                        .foregroundColor(MoriColors.charcoal)
                        .multilineTextAlignment(.center)
                    
                    Text("Time is the one thing you can't get back")
                        .font(MoriTypography.body)
                        .foregroundColor(MoriColors.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Countdown Display
                TimeRemainingSummary(
                    weeksRemaining: viewModel.timeRemaining,
                    progress: viewModel.lifeProgress,
                    isRevealed: revealMetrics,
                    reduceMotion: reduceMotion
                )

                birthDateSection
                demographicsSection

                // Reflection prompt
                VStack(spacing: 12) {
                    Text("What matters most to you with this time?")
                        .font(MoriTypography.subhead)
                        .foregroundColor(MoriColors.charcoal)
                        .multilineTextAlignment(.center)
                }
                
                // Continue button
                Button("Start My Journey") {
                    onContinue()
                }
                .buttonStyle(MoriPrimaryButtonStyle())
                .padding(.top, 20)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).delay(0.3)) {
                revealMetrics = true
            }
        }
        .task {
            await viewModel.loadProfileIfNeeded()
        }
    }

    @ViewBuilder
    private var birthDateSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: viewModel.birthDateSourceIcon)
                    .font(.body)
                    .foregroundColor(MoriColors.gold)

                Text(viewModel.birthDateStatusText)
                    .font(MoriTypography.caption)
                    .foregroundColor(MoriColors.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if viewModel.isLoadingHealthBirthDate {
                ProgressView()
                    .tint(MoriColors.gold)
            }

            if viewModel.shouldShowManualBirthDatePicker {
                DatePicker(
                    "Birth Date",
                    selection: $viewModel.birthDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .onChange(of: viewModel.birthDate) { _ in
                    viewModel.markBirthDateEditedManually()
                }
            } else if !viewModel.isLoadingHealthBirthDate {
                Button("Enter manually instead") {
                    viewModel.showManualBirthDateOverride()
                }
                .font(MoriTypography.caption)
                .foregroundColor(MoriColors.softTaupe)
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(MoriColors.gray.opacity(0.18), lineWidth: 1)
        )
    }

    private var demographicsSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "person.text.rectangle")
                    .font(.body)
                    .foregroundColor(MoriColors.gold)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Estimate details")
                        .font(MoriTypography.subhead)
                        .foregroundColor(MoriColors.charcoal)

                    Text(viewModel.lifeExpectancyStatusText)
                        .font(MoriTypography.caption)
                        .foregroundColor(MoriColors.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Picker("Gender", selection: $viewModel.gender) {
                ForEach(UserGender.allCases) { gender in
                    Text(gender.title).tag(gender)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.gender) { _ in
                Task {
                    await viewModel.refreshLifeExpectancy()
                }
            }

            Picker("Location", selection: $viewModel.countryCode) {
                ForEach(LifeExpectancyService.countries) { country in
                    Text(country.name).tag(country.code)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: viewModel.countryCode) { _ in
                viewModel.countryName = LifeExpectancyService.countryName(for: viewModel.countryCode)
                Task {
                    await viewModel.refreshLifeExpectancy()
                }
            }

            HStack {
                Label("\(viewModel.age) years old", systemImage: "calendar")
                Spacer()
                Label("\(viewModel.lifeExpectancy) year estimate", systemImage: "heart")
            }
            .font(MoriTypography.caption)
            .foregroundColor(MoriColors.softTaupe)

            if viewModel.isLoadingLocation || viewModel.isLoadingLifeExpectancy {
                ProgressView()
                    .tint(MoriColors.gold)
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(MoriColors.gray.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Screen 3: First Weekly Intention
struct FirstGratitudeScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onComplete: () -> Void
    @FocusState private var isFocused: Bool

    private var trimmedAction: String {
        viewModel.firstIntentionAction.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canContinue: Bool {
        !trimmedAction.isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 16) {
                    Text("Make This Week Real")
                        .font(MoriTypography.headline1)
                        .foregroundColor(MoriColors.charcoal)
                        .multilineTextAlignment(.center)
                    
                    Text("One square is being written now. Choose one small proof that you lived it on purpose.")
                        .font(MoriTypography.body)
                        .foregroundColor(MoriColors.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                VStack(alignment: .leading, spacing: 14) {
                    Text("What part of life deserves attention?")
                        .font(MoriTypography.subhead)
                        .foregroundColor(MoriColors.charcoal)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(LifeDomain.allCases) { domain in
                            Button {
                                viewModel.firstIntentionDomain = domain
                                viewModel.firstIntentionAction = domain.suggestedActions[0]
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: domain.symbolName)
                                    Text(domain.title)
                                        .lineLimit(1)
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(viewModel.firstIntentionDomain == domain ? .white : MoriColors.charcoal)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(viewModel.firstIntentionDomain == domain ? MoriColors.charcoal : Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(MoriColors.gray.opacity(0.18), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Intention input
                VStack(spacing: 16) {
                    Text("This week, I will...")
                        .font(MoriTypography.subhead)
                        .foregroundColor(MoriColors.charcoal)
                    
                    ZStack(alignment: .topLeading) {
                        if viewModel.firstIntentionAction.isEmpty {
                            Text("Choose or write one tiny action...")
                                .foregroundColor(MoriColors.gray)
                                .font(MoriTypography.body)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                        }

                        TextEditor(text: $viewModel.firstIntentionAction)
                            .frame(height: 120)
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(MoriColors.gray.opacity(0.2), lineWidth: 1)
                            )
                            .font(MoriTypography.body)
                            .foregroundColor(MoriColors.charcoal)
                            .focused($isFocused)
                            .onChange(of: viewModel.firstIntentionAction) { newValue in
                                if newValue.count > 500 {
                                    viewModel.firstIntentionAction = String(newValue.prefix(500))
                                }
                            }
                    }
                    
                    // Character count
                    Text("\(viewModel.firstIntentionAction.count) / 500")
                        .font(MoriTypography.caption)
                        .foregroundColor(MoriColors.gray)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                // Prompt chips
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tiny actions")
                        .font(MoriTypography.subhead)
                        .foregroundColor(MoriColors.charcoal)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(viewModel.firstIntentionDomain.suggestedActions, id: \.self) { action in
                            Button(action) {
                                viewModel.firstIntentionAction = action
                            }
                            .buttonStyle(MoriChipButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
            .padding(.bottom, 96)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            isFocused = true
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button {
                    complete()
                } label: {
                    Text("Continue")
                }
                .buttonStyle(MoriPrimaryButtonStyle())
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.45)

                Button("Skip for now") {
                    viewModel.firstIntentionAction = LifeDomain.love.suggestedActions[0]
                    onComplete()
                }
                .font(MoriTypography.caption)
                .foregroundColor(MoriColors.softTaupe)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(.ultraThinMaterial)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("Done") {
                    isFocused = false
                }
            }
        }
    }

    private func complete() {
        guard canContinue else { return }
        isFocused = false
        viewModel.firstIntentionAction = trimmedAction
        onComplete()
    }
}

// MARK: - Supporting Views
struct OnboardingHeader: View {
    let currentStep: Int
    let totalSteps: Int
    let onBack: () -> Void
    let onSkip: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MoriColors.charcoal)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(currentStep == 0 ? 0 : 0.7))
                    .clipShape(Circle())
            }
            .opacity(currentStep == 0 ? 0 : 1)
            .disabled(currentStep == 0)
            .accessibilityLabel("Back")

            Spacer()

            MoriProgressBar(
                currentStep: currentStep,
                totalSteps: totalSteps
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step \(currentStep + 1) of \(totalSteps)")

            Spacer()

            if let onSkip {
                Button("Skip") {
                    onSkip()
                }
                .font(MoriTypography.caption)
                .foregroundColor(MoriColors.softTaupe)
                .frame(width: 40, height: 40)
                .accessibilityHint("Closes onboarding")
            } else {
                Color.clear
                    .frame(width: 40, height: 40)
                    .accessibilityHidden(true)
            }
        }
    }
}

private struct MoriWordmark: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "hourglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(MoriColors.moriDark)
                .frame(width: 38, height: 38)
                .background(MoriColors.moriGold)
                .clipShape(Circle())

            Text("MORI")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(MoriColors.charcoal)
                .tracking(2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Mori")
    }
}

struct MoriProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? MoriColors.gold : MoriColors.gray.opacity(0.3))
                    .frame(width: step <= currentStep ? 8 : 6)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
}

final class OnboardingViewModel: ObservableObject {
    @Published var currentStep = 0
    @Published var birthDate: Date
    @Published var gender: UserGender
    @Published var countryCode: String
    @Published var countryName: String
    @Published var lifeExpectancy = 80
    @Published var firstGratitude = ""
    @Published var firstIntentionDomain: LifeDomain = .love
    @Published var firstIntentionAction = LifeDomain.love.suggestedActions[0]
    @Published var timeRemaining = "--"
    @Published var lifeProgress = 0.0
    @Published var isLoadingHealthBirthDate = false
    @Published var isLoadingLocation = false
    @Published var isLoadingLifeExpectancy = false
    @Published var shouldShowManualBirthDatePicker = false
    @Published var birthDateStatusText = "Checking Apple Health for your birth date..."
    @Published var lifeExpectancyStatusText = "Using your region to estimate life expectancy."

    let onboardingStartTime = Date()
    private let healthProfileProvider = HealthProfileProvider()
    private let locationProvider = OnboardingLocationProvider()
    private let lifeExpectancyService = LifeExpectancyService.shared
    private var hasLoadedProfile = false

    init() {
        birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
        gender = .unspecified
        let initialCountryCode = Locale.current.region?.identifier ?? "US"
        countryCode = initialCountryCode
        countryName = LifeExpectancyService.countryName(for: initialCountryCode)
        calculateLifeCountdown()
    }

    var age: Int {
        max(0, Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0)
    }

    var birthDateSourceIcon: String {
        if isLoadingHealthBirthDate {
            return "heart.text.square"
        }

        return shouldShowManualBirthDatePicker ? "calendar" : "heart.fill"
    }

    @MainActor
    func loadBirthDateFromHealthIfNeeded() async {
        await loadProfileIfNeeded()
    }

    @MainActor
    func loadProfileIfNeeded() async {
        guard !hasLoadedProfile else { return }
        hasLoadedProfile = true

        await loadHealthProfile()
        await loadLocationCountry()
        await refreshLifeExpectancy()
    }

    @MainActor
    private func loadHealthProfile() async {
        isLoadingHealthBirthDate = true
        shouldShowManualBirthDatePicker = false
        birthDateStatusText = "Checking Apple Health for your birth date and sex..."

        do {
            let profile = try await healthProfileProvider.requestProfile()
            if let healthBirthDate = profile.birthDate {
                birthDate = healthBirthDate
            } else {
                shouldShowManualBirthDatePicker = true
            }

            if profile.gender != .unspecified {
                gender = profile.gender
            }

            birthDateStatusText = profile.gender == .unspecified
                ? "Birth date loaded from Apple Health. Please confirm gender below."
                : "Birth date and sex loaded from Apple Health."
            calculateLifeCountdown()
        } catch {
            shouldShowManualBirthDatePicker = true
            birthDateStatusText = "Apple Health was unavailable or not approved. Please enter your birth date."
        }

        isLoadingHealthBirthDate = false
    }

    @MainActor
    private func loadLocationCountry() async {
        isLoadingLocation = true
        lifeExpectancyStatusText = "Checking your location to estimate life expectancy..."

        do {
            let country = try await locationProvider.requestCountry()
            countryCode = country.code
            countryName = country.name
            lifeExpectancyStatusText = "Location detected as \(country.name)."
        } catch {
            lifeExpectancyStatusText = "Location was unavailable or not approved. Using \(countryName)."
        }

        isLoadingLocation = false
    }

    func markBirthDateEditedManually() {
        shouldShowManualBirthDatePicker = true
        birthDateStatusText = "Birth date entered manually."
        calculateLifeCountdown()
    }

    func showManualBirthDateOverride() {
        shouldShowManualBirthDatePicker = true
        birthDateStatusText = "You can adjust your birth date before continuing."
    }

    @MainActor
    func refreshLifeExpectancy() async {
        isLoadingLifeExpectancy = true
        lifeExpectancyStatusText = "Looking up life expectancy for \(countryName)..."

        let estimate = await lifeExpectancyService.estimate(countryCode: countryCode, gender: gender)
        lifeExpectancy = estimate.years
        lifeExpectancyStatusText = estimate.sourceDescription
        calculateLifeCountdown()
        isLoadingLifeExpectancy = false
    }

    func calculateLifeCountdown() {
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .year, value: lifeExpectancy, to: birthDate) ?? Date()
        let weeksRemaining = max(0, calendar.dateComponents([.weekOfYear], from: Date(), to: endDate).weekOfYear ?? 0)
        let weeksLived = max(0, calendar.dateComponents([.weekOfYear], from: birthDate, to: Date()).weekOfYear ?? 0)
        let totalWeeks = max(1, weeksLived + weeksRemaining)

        timeRemaining = NumberFormatter.localizedString(from: NSNumber(value: weeksRemaining), number: .decimal)
        lifeProgress = min(1, max(0, Double(weeksLived) / Double(totalWeeks)))
    }
}

struct TimeRemainingSummary: View {
    let weeksRemaining: String
    let progress: Double
    let isRevealed: Bool
    let reduceMotion: Bool

    var body: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Time remaining")
                        .font(MoriTypography.caption)
                        .foregroundColor(MoriColors.softTaupe)
                        .textCase(.uppercase)

                    Spacer()

                    Text("\(Int(progress * 100))% lived")
                        .font(MoriTypography.caption)
                        .foregroundColor(MoriColors.softTaupe)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(weeksRemaining)
                        .font(.system(size: 56, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.warmCharcoal)
                        .monospacedDigit()
                        .minimumScaleFactor(0.72)
                        .lineLimit(1)
                        .opacity(isRevealed ? 1 : 0)
                        .offset(y: isRevealed || reduceMotion ? 0 : 10)
                        .animation(reduceMotion ? .none : .easeOut(duration: 0.45), value: isRevealed)

                    Text("weeks of life")
                        .font(MoriTypography.body)
                        .foregroundColor(MoriColors.gray)
                }

                LifeProgressRail(progress: progress, isRevealed: isRevealed, reduceMotion: reduceMotion)
                    .padding(.top, 8)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(MoriColors.warmGray.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: MoriColors.shadowSoft, radius: 16, x: 0, y: 8)

            HStack(spacing: 10) {
                TimeMarker(label: "Born", isActive: true)
                Rectangle()
                    .fill(MoriColors.warmGray.opacity(0.35))
                    .frame(height: 1)
                TimeMarker(label: "Today", isActive: true)
                Rectangle()
                    .fill(MoriColors.warmGray.opacity(0.35))
                    .frame(height: 1)
                TimeMarker(label: "Estimated", isActive: false)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(weeksRemaining) weeks of life remaining. \(Int(progress * 100)) percent lived.")
    }
}

struct LifeProgressRail: View {
    let progress: Double
    let isRevealed: Bool
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(MoriColors.warmGray.opacity(0.22))
                    .frame(height: 10)

                Capsule()
                    .fill(MoriColors.accentAmber)
                    .frame(width: max(10, width * (isRevealed ? progress : 0)), height: 10)
                    .animation(reduceMotion ? .none : .easeOut(duration: 0.7), value: isRevealed)

                Circle()
                    .fill(Color.white)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle()
                            .stroke(MoriColors.accentAmber, lineWidth: 4)
                    )
                    .offset(x: min(max(0, width * progress - 11), max(0, width - 22)))
                    .opacity(isRevealed ? 1 : 0)
                    .animation(reduceMotion ? .none : .easeOut(duration: 0.7), value: isRevealed)
            }
            .frame(height: 24)
        }
        .frame(height: 24)
    }
}

struct TimeMarker: View {
    let label: String
    let isActive: Bool

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(isActive ? MoriColors.accentAmber : MoriColors.warmGray.opacity(0.4))
                .frame(width: 8, height: 8)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isActive ? MoriColors.warmCharcoal : MoriColors.softTaupe)
        }
        .frame(width: 68)
    }
}

struct LifeGridVisualization: View {
    let rows: Int
    let columns: Int
    let filledRatio: Double
    let animate: Bool
    let showLabels: Bool
    var filledColor: Color = MoriColors.warmCharcoal
    var emptyColor: Color = MoriColors.warmGray.opacity(0.35)

    var body: some View {
        VStack(spacing: 5) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 5) {
                    ForEach(0..<columns, id: \.self) { column in
                        let index = row * columns + column
                        Circle()
                            .fill(Double(index) / Double(rows * columns) < filledRatio ? filledColor : emptyColor)
                            .frame(width: 7, height: 7)
                            .scaleEffect(animate ? 1 : 0.4)
                            .animation(.easeOut(duration: 0.35).delay(Double(index) * 0.01), value: animate)
                    }
                }
            }
        }
        .padding(28)
        .accessibilityLabel("Life weeks preview")
    }
}

struct LifeProgressArc: View {
    let progress: Double
    let animate: Bool

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.12, to: 0.88)
                .stroke(MoriColors.warmGray.opacity(0.25), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(90))

            Circle()
                .trim(from: 0.12, to: 0.12 + (0.76 * progress))
                .stroke(MoriColors.accentAmber, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(90))
                .animation(animate ? .easeOut(duration: 0.8) : .none, value: progress)

            VStack(spacing: 4) {
                Text("\(Int(progress * 100))%")
                    .font(MoriTypography.title1)
                    .foregroundColor(MoriColors.warmCharcoal)
                Text("lived")
                    .font(MoriTypography.caption)
                    .foregroundColor(MoriColors.softTaupe)
            }
        }
    }
}

struct MoriPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(MoriColors.deepEspresso)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(MoriColors.accentAmber)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct MoriChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(MoriTypography.caption)
            .foregroundColor(MoriColors.warmCharcoal)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(MoriColors.softCream)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(MoriColors.warmGray.opacity(0.7), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}

final class GratitudeManager {
    static let shared = GratitudeManager()

    private init() {}

    func saveFirstGratitude(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        UserDefaults.standard.set(trimmed, forKey: "firstGratitude")
    }
}

// MARK: - Sample Data
private let gratitudePrompts = [
    "My health",
    "My family", 
    "This moment",
    "Nature outside",
    "Food on my table",
    "My home",
    "Learning something new",
    "Kindness I received",
    "Simple pleasures",
    "Another day lived"
]

// MARK: - Preview
#Preview {
    MoriOnboardingView()
        .environmentObject(UserSettings())
}
