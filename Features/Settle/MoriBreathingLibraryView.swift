import SwiftUI
import UIKit

struct MoriBreathingLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedMood: MoriBreathMood = .all
    @State private var selectedDuration = 10
    @State private var techniqueForDurationSelection: MoriBreathingTechnique?
    @State private var practiceRoute: MoriBreathingPracticeRoute?

    private var filteredTechniques: [MoriBreathingTechnique] {
        MoriBreathingTechniqueRepository.search(query: searchText, mood: selectedMood)
    }

    var body: some View {
        MoriForestBackground {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    MoriPageHeader(
                        eyebrow: "Breathing",
                        title: "Breathing Library",
                        subtitle: "Choose a full guided pattern from the mindfulness-timer library, then practice it inside Mori."
                    )

                    searchField
                    moodFilterRow

                    LazyVStack(spacing: 14) {
                        ForEach(filteredTechniques) { technique in
                            MoriBreathingTechniqueCard(
                                technique: technique,
                                onStart: { selectDuration(for: technique) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Breathing")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MoriColors.forestCanopy)
                }
                .accessibilityLabel("Back")
            }
        }
        .toolbarBackground(MoriColors.forestPaper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .sheet(item: $techniqueForDurationSelection) { technique in
            MoriBreathingDurationPickerSheet(
                techniqueName: technique.name,
                selectedDuration: $selectedDuration,
                onStart: {
                    practiceRoute = MoriBreathingPracticeRoute(techniqueID: technique.id, durationMinutes: selectedDuration)
                    techniqueForDurationSelection = nil
                }
            )
            .presentationDetents([.height(560), .large])
            .presentationDragIndicator(.visible)
        }
        .navigationDestination(isPresented: practiceRouteIsPresented) {
            if let route = practiceRoute {
                MoriBreathingSessionView(
                    techniqueID: route.techniqueID,
                    durationMinutes: route.durationMinutes,
                    autoStart: true
                )
            } else {
                EmptyView()
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(MoriColors.forestMuted)

            TextField("Search techniques, benefits, or categories", text: $searchText)
                .font(.system(size: 15, weight: .regular))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(MoriColors.forestMuted.opacity(0.75))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(MoriColors.forestCard.opacity(0.82))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MoriColors.forestLine.opacity(0.62), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var moodFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MoriBreathMood.allCases) { mood in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMood = mood
                        }
                    } label: {
                        MoriPill(
                            title: mood.rawValue,
                            symbolName: mood.iconName,
                            isSelected: selectedMood == mood,
                            tint: mood == .sleep ? MoriColors.forestMist : MoriColors.forestMoss
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var practiceRouteIsPresented: Binding<Bool> {
        Binding(
            get: { practiceRoute != nil },
            set: { isPresented in
                if !isPresented {
                    practiceRoute = nil
                }
            }
        )
    }

    private func selectDuration(for technique: MoriBreathingTechnique) {
        selectedDuration = 10
        techniqueForDurationSelection = technique
    }
}

private struct MoriBreathingTechniqueCard: View {
    let technique: MoriBreathingTechnique
    let onStart: () -> Void

    private var accent: Color {
        Color(hex: technique.gradientColors.first ?? "#687E5E")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: technique.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(accent)
                    .frame(width: 42, height: 42)
                    .background(accent.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(technique.name)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(MoriColors.forestCanopy)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 4)
                    }

                    Text(technique.shortDescription)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(MoriColors.forestMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                MoriMiniBadge(title: technique.category, symbolName: "folder", tint: accent)
                MoriMiniBadge(title: technique.patternDisplay, symbolName: "metronome", tint: MoriColors.forestMist)
            }

            HStack(spacing: 10) {
                Button(action: onStart) {
                    Label("Start", systemImage: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MoriColors.forestCard)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(MoriColors.forestCanopy)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                NavigationLink {
                    MoriBreathingTechniqueDetailView(technique: technique)
                } label: {
                    Label("Details", systemImage: "book.pages")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MoriColors.forestCanopy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(MoriColors.forestCanopy.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .moriSanctuaryCard(cornerRadius: 20, padding: 16)
    }
}

private struct MoriMiniBadge: View {
    let title: String
    let symbolName: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: symbolName)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.11))
            .clipShape(Capsule())
    }
}

private struct MoriBreathingTechniqueDetailView: View {
    let technique: MoriBreathingTechnique

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDuration = 10
    @State private var showDurationPicker = false
    @State private var practiceRoute: MoriBreathingPracticeRoute?
    @AppStorage("mori_settle_breathing_custom_inhale") private var customInhaleSeconds: Double = 4
    @AppStorage("mori_settle_breathing_custom_hold") private var customHoldSeconds: Double = 0
    @AppStorage("mori_settle_breathing_custom_exhale") private var customExhaleSeconds: Double = 6
    @AppStorage("mori_settle_breathing_custom_uses_hold") private var customUsesHold: Bool = false

    private var displayedPattern: MoriBreathPattern {
        technique.id == MoriBreathingTechniqueID.custom.rawValue
            ? MoriBreathPattern(
                inhale: max(1, customInhaleSeconds),
                inhaleHold: customUsesHold ? max(1, customHoldSeconds) : nil,
                exhale: max(1, customExhaleSeconds),
                exhaleHold: nil
            )
            : technique.breathPattern
    }

    var body: some View {
        MoriForestBackground {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    detailHero
                    patternMetrics
                    detailSection(title: "What It Is", symbolName: "lightbulb.fill", body: technique.longDescription, tint: MoriColors.forestMoss)
                    benefitsSection
                    detailSection(title: "The Science", symbolName: "brain.head.profile", body: technique.scienceExplanation, tint: MoriColors.forestMist)
                    stepsSection
                    bestForSection
                    startButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Technique")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MoriColors.forestCanopy)
                }
                .accessibilityLabel("Back")
            }
        }
        .toolbarBackground(MoriColors.forestPaper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .sheet(isPresented: $showDurationPicker) {
            MoriBreathingDurationPickerSheet(
                techniqueName: technique.name,
                selectedDuration: $selectedDuration,
                onStart: {
                    practiceRoute = MoriBreathingPracticeRoute(techniqueID: technique.id, durationMinutes: selectedDuration)
                    showDurationPicker = false
                }
            )
            .presentationDetents([.height(560), .large])
            .presentationDragIndicator(.visible)
        }
        .navigationDestination(isPresented: practiceRouteIsPresented) {
            if let route = practiceRoute {
                MoriBreathingSessionView(
                    techniqueID: route.techniqueID,
                    durationMinutes: route.durationMinutes,
                    autoStart: true
                )
            } else {
                EmptyView()
            }
        }
    }

    private var practiceRouteIsPresented: Binding<Bool> {
        Binding(
            get: { practiceRoute != nil },
            set: { isPresented in
                if !isPresented {
                    practiceRoute = nil
                }
            }
        )
    }

    private var detailHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: technique.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(MoriColors.forestCard)
                    .frame(width: 52, height: 52)
                    .background(Color(hex: technique.gradientColors.first ?? "#687E5E"))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("BREATHING TECHNIQUE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(MoriColors.forestMoss)

                    Text(technique.name)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestCanopy)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(technique.shortDescription)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(MoriColors.forestMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private var patternMetrics: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MoriMetricTile(
                title: "Pattern",
                value: MoriBreathingTechnique.patternDisplay(for: displayedPattern),
                detail: "breath rhythm",
                symbolName: "metronome",
                tint: MoriColors.forestMoss
            )

            MoriMetricTile(
                title: "Frequency",
                value: String(format: "%.1f", displayedPattern.breathsPerMinute),
                detail: "breaths/min",
                symbolName: "waveform.path.ecg",
                tint: MoriColors.forestMist
            )
        }
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriSectionTitle(title: "Benefits", subtitle: "What this rhythm is commonly used for.")
            ForEach(technique.benefits, id: \.self) { benefit in
                Label(benefit, systemImage: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(MoriColors.forestCanopy)
            }
        }
        .moriSanctuaryCard(cornerRadius: 20, padding: 16)
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriSectionTitle(title: "How To Practice", subtitle: "Follow the reference sequence without forcing the breath.")
            ForEach(Array(technique.howToSteps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestCard)
                        .frame(width: 24, height: 24)
                        .background(MoriColors.forestCanopy)
                        .clipShape(Circle())

                    Text(step)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(MoriColors.forestCanopy)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .moriSanctuaryCard(cornerRadius: 20, padding: 16)
    }

    private var bestForSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriSectionTitle(title: "Best For", subtitle: "A quick match guide from the breathing library.")
            FlowLayout(spacing: 8) {
                ForEach(technique.bestFor, id: \.self) { item in
                    MoriPill(title: item, isSelected: false, tint: MoriColors.forestMist)
                }
            }
        }
        .moriSanctuaryCard(cornerRadius: 20, padding: 16)
    }

    private var startButton: some View {
        Button {
            showDurationPicker = true
        } label: {
            Label("Choose Duration", systemImage: "play.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(MoriColors.forestCard)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(MoriColors.forestCanopy)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func detailSection(title: String, symbolName: String, body: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbolName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(tint)

            Text(body)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(MoriColors.forestMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .moriSanctuaryCard(cornerRadius: 20, padding: 16)
    }
}

private struct MoriBreathingDurationPickerSheet: View {
    let techniqueName: String
    @Binding var selectedDuration: Int
    let onStart: () -> Void
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        MoriForestBackground {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    VStack(spacing: 8) {
                        Text("Choose Duration")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(MoriColors.forestCanopy)

                        Text(techniqueName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(MoriColors.forestMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Text("The reference library supports short resets through long practice blocks.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(MoriColors.forestMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 22)

                    Picker("Duration", selection: $selectedDuration) {
                        ForEach(MoriBreathingSessionDurationOptions.pickerOptions, id: \.self) { minutes in
                            Text("\(minutes)m").tag(minutes)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(MoriBreathingSessionDurationOptions.presets, id: \.self) { minutes in
                            Button {
                                selectedDuration = minutes
                            } label: {
                                Text("\(minutes)m")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(selectedDuration == minutes ? MoriColors.forestCard : MoriColors.forestCanopy)
                                    .frame(maxWidth: .infinity, minHeight: 42)
                                    .background(selectedDuration == minutes ? MoriColors.forestCanopy : MoriColors.forestCanopy.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Custom length")
                            Spacer()
                            Text("\(selectedDuration)m")
                                .monospacedDigit()
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MoriColors.forestCanopy)

                        Slider(value: Binding(
                            get: { Double(selectedDuration) },
                            set: { selectedDuration = Int($0.rounded()) }
                        ), in: 1...180, step: 1)
                        .tint(MoriColors.forestMoss)
                    }

                    HStack(spacing: 10) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(MoriColors.forestCanopy)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(MoriColors.forestCanopy.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Button(action: onStart) {
                            Label("Start Session", systemImage: "play.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(MoriColors.forestCard)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(MoriColors.forestCanopy)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 22)
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

private struct MoriBreathingPracticeRoute: Identifiable, Hashable {
    let id = UUID()
    let techniqueID: String
    let durationMinutes: Int
}

private struct MoriBreathingCompletionSummary {
    let title: String
    let seeds: Int
    let minutes: Int
    let symbolName: String
    let tint: Color
}

private func moriBreathingCompletionBanner(_ summary: MoriBreathingCompletionSummary) -> some View {
    HStack(alignment: .center, spacing: 12) {
        Image(systemName: summary.symbolName)
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(summary.tint)

        VStack(alignment: .leading, spacing: 3) {
            Text(summary.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(MoriColors.forestCanopy)

            Text("\(summary.minutes)m completed · \(summary.seeds) Seeds")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(MoriColors.forestMuted)
        }

        Spacer()
    }
    .padding(14)
    .background(summary.tint.opacity(0.10))
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
}

private enum MoriBreathingRunState {
    case idle
    case running
    case paused
    case completed

    var isActive: Bool {
        self == .running || self == .paused
    }
}

private struct MoriBreathingSessionView: View {
    let techniqueID: String
    let autoStart: Bool

    @Environment(\.dismiss) private var dismiss
    @StateObject private var clarityStore = MoriClarityStore.shared

    @AppStorage("mori_settle_breathing_sound_enabled") private var soundEnabled: Bool = true
    @AppStorage("mori_settle_breathing_haptics_enabled") private var hapticsEnabled: Bool = true
    @AppStorage("mori_settle_breathing_keep_screen_on") private var keepScreenOn: Bool = true
    @AppStorage("mori_settle_breathing_haptic_style") private var hapticStyleRaw: String = MoriBreathingHapticStyle.minimalist.rawValue
    @AppStorage("mori_settle_breathing_custom_inhale") private var customInhaleSeconds: Double = 4
    @AppStorage("mori_settle_breathing_custom_hold") private var customHoldSeconds: Double = 0
    @AppStorage("mori_settle_breathing_custom_exhale") private var customExhaleSeconds: Double = 6
    @AppStorage("mori_settle_breathing_custom_uses_hold") private var customUsesHold: Bool = false

    @State private var durationMinutes: Int
    @State private var runState: MoriBreathingRunState = .idle
    @State private var activeElapsed: TimeInterval = 0
    @State private var sessionStartDate: Date?
    @State private var pausedAt: Date?
    @State private var totalPausedDuration: TimeInterval = 0
    @State private var currentPhaseIndex = 0
    @State private var completedBreathCount = 0
    @State private var completedSummary: MoriBreathingCompletionSummary?
    @State private var scheduledHapticTimers: [Timer] = []
    @State private var scheduledSoundTimer: Timer?
    @State private var scheduledFadeTimer: Timer?
    @State private var showLeaveDialog = false
    @State private var showSettings = false
    @State private var hasAutoStarted = false

    private let ticker = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    init(techniqueID: String, durationMinutes: Int, autoStart: Bool = false) {
        self.techniqueID = techniqueID
        self.autoStart = autoStart
        _durationMinutes = State(initialValue: durationMinutes)
    }

    private var technique: MoriBreathingTechnique {
        MoriBreathingTechniqueRepository.getTechnique(id: techniqueID)
            ?? MoriBreathingTechniqueRepository.getTechnique(id: MoriBreathingTechniqueID.custom.rawValue)
            ?? MoriBreathingTechniqueRepository.techniques[0]
    }

    private var hapticStyle: MoriBreathingHapticStyle {
        MoriBreathingHapticStyle(rawValue: hapticStyleRaw) ?? .minimalist
    }

    private var sessionDuration: TimeInterval {
        TimeInterval(max(1, durationMinutes) * 60)
    }

    private var currentPattern: MoriBreathPattern {
        if technique.id == MoriBreathingTechniqueID.custom.rawValue {
            return MoriBreathPattern(
                inhale: max(1, customInhaleSeconds),
                inhaleHold: customUsesHold && customHoldSeconds > 0 ? max(1, customHoldSeconds) : nil,
                exhale: max(1, customExhaleSeconds),
                exhaleHold: nil
            )
        }

        return technique.breathPattern
    }

    private var segments: [MoriBreathingCycleSegment] {
        currentPattern.segments
    }

    private var visualState: MoriBreathingCycleVisualState {
        MoriBreathingCycle.visualState(for: segments, elapsedTime: activeElapsed)
    }

    private var secondsRemaining: Int {
        max(0, Int(ceil(sessionDuration - activeElapsed)))
    }

    private var phaseRemaining: TimeInterval {
        MoriBreathingCycle.phaseRemaining(for: segments, elapsedTime: activeElapsed)
    }

    private var progress: CGFloat {
        CGFloat(min(1, max(0, activeElapsed / max(1, sessionDuration))))
    }

    var body: some View {
        MoriForestBackground {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    MoriPageHeader(
                        eyebrow: "Breathing",
                        title: technique.name,
                        subtitle: technique.shortDescription
                    )

                    techniqueInfoCard
                    phaseSummaryGrid
                    timerCard
                    guidanceSettingsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    requestClose()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MoriColors.forestCanopy)
                }
                .accessibilityLabel("Back")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MoriColors.forestCanopy)
                }
                .accessibilityLabel("Breathing settings")
            }
        }
        .toolbarBackground(MoriColors.forestPaper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .onAppear {
            applyIdleTimerPolicy()
            if autoStart, !hasAutoStarted {
                hasAutoStarted = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    startBreathing()
                }
            }
        }
        .onDisappear {
            cleanupSessionSideEffects(stopAudio: true)
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onReceive(ticker) { date in
            syncBreathingState(now: date)
        }
        .onChange(of: soundEnabled) { enabled in
            if enabled, runState == .running {
                playSoundFeedback()
                scheduleSoundForNextPhase()
            } else {
                cancelScheduledSound()
                SettleBellService.shared.stopBreathingCues()
            }
        }
        .onChange(of: hapticsEnabled) { enabled in
            cancelScheduledHaptics()
            if enabled, runState == .running {
                scheduleHapticsForCurrentPhase()
            }
        }
        .onChange(of: keepScreenOn) { _ in
            applyIdleTimerPolicy()
        }
        .sheet(isPresented: $showSettings) {
            MoriBreathingSessionSettingsSheet(
                durationMinutes: $durationMinutes,
                soundEnabled: $soundEnabled,
                hapticsEnabled: $hapticsEnabled,
                keepScreenOn: $keepScreenOn,
                hapticStyleRaw: $hapticStyleRaw,
                customInhaleSeconds: $customInhaleSeconds,
                customHoldSeconds: $customHoldSeconds,
                customExhaleSeconds: $customExhaleSeconds,
                customUsesHold: $customUsesHold,
                isRunning: runState.isActive
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "End this breathing session?",
            isPresented: $showLeaveDialog,
            titleVisibility: .visible
        ) {
            Button("Keep breathing", role: .cancel) {}
            Button("End and leave", role: .destructive) {
                endWithoutRecording()
                dismiss()
            }
        } message: {
            Text("Breathing sessions only record when the timer completes.")
        }
    }

    private var techniqueInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                MoriMiniBadge(title: technique.category, symbolName: "folder", tint: MoriColors.forestMoss)
                MoriMiniBadge(title: technique.difficulty.rawValue, symbolName: "star.fill", tint: technique.difficulty.tint)
                MoriMiniBadge(title: MoriBreathingTechnique.patternDisplay(for: currentPattern), symbolName: "metronome", tint: MoriColors.forestMist)
            }

            Text(technique.bestFor.prefix(3).joined(separator: " · "))
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(MoriColors.forestMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .moriSanctuaryCard(cornerRadius: 20, padding: 16)
    }

    private var phaseSummaryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: min(max(segments.count, 2), 4)), spacing: 8) {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                VStack(spacing: 5) {
                    Image(systemName: phaseIcon(for: segment.phase))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(index == currentPhaseIndex && runState == .running ? MoriColors.forestCard : MoriColors.forestMoss)
                    Text(segment.label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(index == currentPhaseIndex && runState == .running ? MoriColors.forestCard : MoriColors.forestCanopy)
                    Text(MoriBreathingTechnique.formatSeconds(segment.duration))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(index == currentPhaseIndex && runState == .running ? MoriColors.forestCard : MoriColors.forestCanopy)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, minHeight: 78)
                .background(index == currentPhaseIndex && runState == .running ? MoriColors.forestCanopy : MoriColors.forestPaperDeep.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private var timerCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                MoriSectionTitle(
                    title: visualState.label,
                    subtitle: runState == .running ? "Follow the cue. No forcing." : "Ready for \(durationMinutes)m of guided breathing."
                )

                Spacer()

                HStack(spacing: 8) {
                    cueToggleButton(
                        isOn: soundEnabled,
                        onSymbol: "speaker.wave.2.fill",
                        offSymbol: "speaker.slash.fill",
                        label: soundEnabled ? "Sound cues on" : "Sound cues off"
                    ) {
                        soundEnabled.toggle()
                    }
                    cueToggleButton(
                        isOn: hapticsEnabled,
                        onSymbol: "hand.tap.fill",
                        offSymbol: "hand.raised.slash",
                        label: hapticsEnabled ? "Haptics on" : "Haptics off"
                    ) {
                        hapticsEnabled.toggle()
                    }
                }
            }

            ZStack {
                MoriBreathingProgressRing(progress: progress, tint: Color(hex: technique.gradientColors.first ?? "#687E5E"))
                MoriBreathingOrbView(
                    visualState: visualState,
                    isActive: runState == .running,
                    isPaused: runState == .paused,
                    tint: Color(hex: technique.gradientColors.first ?? "#687E5E")
                )

                VStack {
                    Spacer()
                    Text("\(completedBreathCount) breaths")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestMuted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(MoriColors.forestCanopy.opacity(0.07))
                        .clipShape(Capsule())
                }
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 270)
            .overlay(alignment: .center) {
                VStack(spacing: 7) {
                    Text(formatTime(secondsRemaining))
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestCanopy)
                        .monospacedDigit()

                    Text(runState == .paused ? "Paused" : visualState.label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MoriColors.forestMuted)
                }
            }

            if let completedSummary {
                moriBreathingCompletionBanner(completedSummary)
            }

            controlRow
        }
        .moriSanctuaryCard(cornerRadius: 24, padding: 18)
    }

    private var guidanceSettingsCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            MoriSectionTitle(title: "Guidance", subtitle: "Reference-style phase sound and haptic cues.")

            HStack(spacing: 10) {
                MoriMiniBadge(title: soundEnabled ? "Sound on" : "Sound off", symbolName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill", tint: MoriColors.forestMoss)
                MoriMiniBadge(title: hapticStyle.rawValue, symbolName: "hand.tap", tint: MoriColors.forestMist)
                MoriMiniBadge(title: keepScreenOn ? "Screen awake" : "Screen normal", symbolName: "display", tint: MoriColors.forestClay)
            }

            if technique.id == MoriBreathingTechniqueID.custom.rawValue {
                Text("Custom pattern: \(MoriBreathingTechnique.patternDisplay(for: currentPattern))")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(MoriColors.forestMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .moriSanctuaryCard(cornerRadius: 20, padding: 16)
    }

    private var controlRow: some View {
        HStack(spacing: 12) {
            switch runState {
            case .idle, .completed:
                Button {
                    startBreathing()
                } label: {
                    Label(runState == .completed ? "Breathe again" : "Start", systemImage: "play.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MoriColors.forestCard)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(MoriColors.forestCanopy)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

            case .running:
                Button {
                    pauseBreathing()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MoriColors.forestCard)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(MoriColors.forestCanopy)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                endButton

            case .paused:
                Button {
                    resumeBreathing()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MoriColors.forestCard)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(MoriColors.forestCanopy)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                endButton
            }
        }
    }

    private var endButton: some View {
        Button {
            endWithoutRecording()
        } label: {
            Label("End", systemImage: "stop.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(MoriColors.forestCanopy)
                .frame(width: 100)
                .padding(.vertical, 14)
                .background(MoriColors.forestCanopy.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func cueToggleButton(isOn: Bool, onSymbol: String, offSymbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: isOn ? onSymbol : offSymbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(MoriColors.forestCanopy)
                .frame(width: 36, height: 36)
                .background(MoriColors.forestCanopy.opacity(0.08))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func startBreathing() {
        runState = .running
        activeElapsed = 0
        currentPhaseIndex = 0
        sessionStartDate = Date()
        pausedAt = nil
        totalPausedDuration = 0
        completedBreathCount = 0
        completedSummary = nil
        applyIdleTimerPolicy()
        scheduleHapticsForCurrentPhase()
        if soundEnabled {
            playSoundFeedback()
            scheduleSoundForNextPhase()
        }
    }

    private func pauseBreathing() {
        guard runState == .running else { return }
        syncBreathingState()
        runState = .paused
        pausedAt = Date()
        cleanupSessionSideEffects(stopAudio: true)
        applyIdleTimerPolicy()
    }

    private func resumeBreathing() {
        guard runState == .paused else { return }
        if let pausedAt {
            totalPausedDuration += Date().timeIntervalSince(pausedAt)
        }
        pausedAt = nil
        runState = .running
        applyIdleTimerPolicy()
        scheduleHapticsForCurrentPhase()
        if soundEnabled {
            playSoundFeedback()
            scheduleSoundForNextPhase()
        }
    }

    private func syncBreathingState(now: Date = Date()) {
        guard runState == .running, let sessionStartDate else { return }

        let elapsed = max(0, now.timeIntervalSince(sessionStartDate) - totalPausedDuration)
        let previousPhaseIndex = currentPhaseIndex
        activeElapsed = min(sessionDuration, elapsed)

        if activeElapsed >= sessionDuration {
            completeBreathing()
            return
        }

        currentPhaseIndex = MoriBreathingCycle.phaseIndex(for: segments, elapsedTime: activeElapsed)

        if currentPhaseIndex != previousPhaseIndex {
            if currentPhaseIndex == 0 {
                completedBreathCount += 1
            }
            cancelScheduledHaptics()
            scheduleHapticsForCurrentPhase()
            if soundEnabled {
                scheduleSoundForNextPhase()
            }
        }
    }

    private func completeBreathing() {
        guard runState == .running else { return }
        runState = .completed
        activeElapsed = sessionDuration
        cleanupSessionSideEffects(stopAudio: true)
        UIApplication.shared.isIdleTimerDisabled = false

        let seeds = max(1, durationMinutes / 2)
        clarityStore.record(
            kind: .breathingSession,
            title: technique.name,
            seeds: seeds,
            minutes: durationMinutes,
            note: "Completed \(technique.name)"
        )

        completedSummary = MoriBreathingCompletionSummary(
            title: "Breath settled",
            seeds: seeds,
            minutes: durationMinutes,
            symbolName: "wind.circle.fill",
            tint: MoriColors.forestMist
        )

        if soundEnabled {
            SettleBellService.shared.playEndingBell()
        }
        if hapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func endWithoutRecording() {
        runState = .idle
        activeElapsed = 0
        currentPhaseIndex = 0
        sessionStartDate = nil
        pausedAt = nil
        totalPausedDuration = 0
        completedBreathCount = 0
        completedSummary = nil
        cleanupSessionSideEffects(stopAudio: true)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func requestClose() {
        if runState.isActive {
            showLeaveDialog = true
        } else {
            dismiss()
        }
    }

    private func scheduleHapticsForCurrentPhase() {
        guard hapticsEnabled, runState == .running, segments.indices.contains(currentPhaseIndex) else { return }
        let segment = segments[currentPhaseIndex]

        switch hapticStyle {
        case .symmetry:
            scheduleSymmetryHaptics(for: segment)
        case .minimalist:
            scheduleMinimalistHaptics(for: segment)
        }
    }

    private func scheduleMinimalistHaptics(for segment: MoriBreathingCycleSegment) {
        switch segment.phase {
        case .inhale:
            scheduleHapticTap(after: 0, style: .medium)
        case .exhale:
            scheduleHapticTap(after: 0, style: .light)
        case .holdAfterInhale, .holdAfterExhale:
            scheduleHapticTap(after: 0, style: .medium)
            scheduleHapticTap(after: 0.2, style: .medium)
        case .idle:
            break
        }
    }

    private func scheduleSymmetryHaptics(for segment: MoriBreathingCycleSegment) {
        switch segment.phase {
        case .inhale:
            scheduleSymmetryInhale(duration: segment.duration)
            scheduleHapticTap(after: max(0, segment.duration - 0.01), style: .medium)
        case .holdAfterInhale, .holdAfterExhale:
            scheduleHapticTap(after: 0, style: .medium)
            scheduleHapticTap(after: 0.15, style: .medium)
            scheduleHoldPreCueTapTap(duration: segment.duration)
        case .exhale, .idle:
            break
        }
    }

    private func scheduleSymmetryInhale(duration: Double) {
        guard duration > 0 else { return }
        let startInterval = 0.8
        let endInterval = 0.15
        var currentTime = 0.0

        while currentTime < duration {
            scheduleHapticTap(after: currentTime, style: .light)
            let progress = currentTime / duration
            let ratio = endInterval / startInterval
            currentTime += startInterval * pow(ratio, progress)
        }
    }

    private func scheduleHoldPreCueTapTap(duration: Double) {
        guard duration > 0 else { return }
        let firstLead = min(0.35, max(0, duration / 3))
        let secondLead = min(0.15, max(0, duration / 6))
        let times = Array(Set([max(0, duration - firstLead), max(0, duration - secondLead)])).sorted()
        for time in times where time > 0 {
            scheduleHapticTap(after: time, style: .light)
        }
    }

    private enum TapStyle {
        case light
        case medium
    }

    private func scheduleHapticTap(after delay: Double, style: TapStyle) {
        guard hapticsEnabled, runState == .running else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: max(0, delay), repeats: false) { _ in
            guard hapticsEnabled, runState == .running else { return }
            let generator: UIImpactFeedbackGenerator
            switch style {
            case .light:
                generator = UIImpactFeedbackGenerator(style: .light)
            case .medium:
                generator = UIImpactFeedbackGenerator(style: .medium)
            }
            generator.impactOccurred()
        }
        scheduledHapticTimers.append(timer)
        RunLoop.current.add(timer, forMode: .common)
    }

    private func cancelScheduledHaptics() {
        scheduledHapticTimers.forEach { $0.invalidate() }
        scheduledHapticTimers.removeAll()
    }

    private func playSoundFeedback() {
        guard soundEnabled, segments.indices.contains(currentPhaseIndex), let cue = segments[currentPhaseIndex].phase.cue else { return }
        SettleBellService.shared.playBreathingCue(cue)
    }

    private func scheduleSoundForNextPhase() {
        guard soundEnabled, runState == .running, !segments.isEmpty, segments.indices.contains(currentPhaseIndex) else { return }
        cancelScheduledSound()

        let nextPhaseIndex = (currentPhaseIndex + 1) % segments.count
        guard segments.indices.contains(nextPhaseIndex), let nextCue = segments[nextPhaseIndex].phase.cue else { return }

        let currentCue = segments[currentPhaseIndex].phase.cue
        let leadTime: Double
        switch nextCue {
        case .inhale, .hold:
            leadTime = 0.2
        case .exhale:
            leadTime = 0.8
        }

        let fadeDuration = 1.5
        let fadeDelay = max(0, phaseRemaining - leadTime - fadeDuration)
        let soundDelay = max(0, phaseRemaining - leadTime)

        if let currentCue, currentCue == .inhale || currentCue == .exhale {
            scheduledFadeTimer = Timer.scheduledTimer(withTimeInterval: fadeDelay, repeats: false) { _ in
                guard soundEnabled, runState == .running else { return }
                SettleBellService.shared.fadeOutBreathingCue(currentCue)
            }
            if let scheduledFadeTimer {
                RunLoop.current.add(scheduledFadeTimer, forMode: .common)
            }
        }

        scheduledSoundTimer = Timer.scheduledTimer(withTimeInterval: soundDelay, repeats: false) { _ in
            guard soundEnabled, runState == .running else { return }
            SettleBellService.shared.playBreathingCue(nextCue)
        }
        if let scheduledSoundTimer {
            RunLoop.current.add(scheduledSoundTimer, forMode: .common)
        }
    }

    private func cancelScheduledSound() {
        scheduledSoundTimer?.invalidate()
        scheduledFadeTimer?.invalidate()
        scheduledSoundTimer = nil
        scheduledFadeTimer = nil
    }

    private func cleanupSessionSideEffects(stopAudio: Bool) {
        cancelScheduledHaptics()
        cancelScheduledSound()
        if stopAudio {
            SettleBellService.shared.stopBreathingCues()
        }
    }

    private func applyIdleTimerPolicy() {
        let shouldDisableIdle = keepScreenOn && runState == .running && UIApplication.shared.applicationState == .active
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = shouldDisableIdle
        }
    }

    private func phaseIcon(for phase: MoriBreathingCyclePhase) -> String {
        switch phase {
        case .inhale: return "arrow.up.circle"
        case .exhale: return "arrow.down.circle"
        case .holdAfterInhale, .holdAfterExhale: return "pause.circle"
        case .idle: return "circle"
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = max(0, seconds) / 60
        let seconds = max(0, seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private struct MoriBreathingOrbView: View {
    let visualState: MoriBreathingCycleVisualState
    let isActive: Bool
    let isPaused: Bool
    let tint: Color
    @State private var gradientRotation: Angle = .zero

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(tint.opacity(0.18 - Double(index) * 0.035), lineWidth: 1.2)
                    .scaleEffect(1 + CGFloat(index) * 0.16)
            }

            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            MoriColors.forestMistSoft,
                            MoriColors.forestPaperDeep,
                            MoriColors.forestSeed.opacity(0.78),
                            MoriColors.forestMistSoft
                        ],
                        center: .center,
                        angle: gradientRotation
                    )
                )
                .overlay {
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.72),
                            Color.white.opacity(0.18),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 8,
                        endRadius: 150
                    )
                    .clipShape(Circle())
                }
                .shadow(color: tint.opacity(0.22), radius: 28, x: 0, y: 18)
        }
        .frame(width: 190, height: 190)
        .scaleEffect(isActive && !isPaused ? visualState.scale : 0.92)
        .opacity(isActive && !isPaused ? visualState.opacity : 0.82)
        .blur(radius: isActive && !isPaused ? visualState.blur : 0)
        .animation(.easeInOut(duration: 0.3), value: visualState.scale)
        .onAppear {
            withAnimation(.linear(duration: 28).repeatForever(autoreverses: false)) {
                gradientRotation = .degrees(360)
            }
        }
    }
}

private struct MoriBreathingProgressRing: View {
    let progress: CGFloat
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(MoriColors.forestLine.opacity(0.62), lineWidth: 13)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: 13, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: progress)
        }
    }
}

private struct MoriBreathingSessionSettingsSheet: View {
    @Binding var durationMinutes: Int
    @Binding var soundEnabled: Bool
    @Binding var hapticsEnabled: Bool
    @Binding var keepScreenOn: Bool
    @Binding var hapticStyleRaw: String
    @Binding var customInhaleSeconds: Double
    @Binding var customHoldSeconds: Double
    @Binding var customExhaleSeconds: Double
    @Binding var customUsesHold: Bool
    let isRunning: Bool

    var body: some View {
        MoriForestBackground {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Breathing Settings")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(MoriColors.forestCanopy)
                        Text(isRunning ? "Timing is locked while the session is active." : "Tune duration, cues, haptics, and the custom rhythm.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(MoriColors.forestMuted)
                    }

                    settingsSection(title: "Duration") {
                        Stepper("Session \(durationMinutes)m", value: $durationMinutes, in: 1...180, step: 5)
                            .disabled(isRunning)
                    }

                    settingsSection(title: "Guidance") {
                        Toggle("Sound cues", isOn: $soundEnabled)
                            .tint(MoriColors.forestMoss)
                        Toggle("Haptic cues", isOn: $hapticsEnabled)
                            .tint(MoriColors.forestMoss)
                        Toggle("Keep screen awake", isOn: $keepScreenOn)
                            .tint(MoriColors.forestMoss)

                        if hapticsEnabled {
                            Picker("Haptic style", selection: $hapticStyleRaw) {
                                ForEach(MoriBreathingHapticStyle.allCases) { style in
                                    Text(style.rawValue).tag(style.rawValue)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    settingsSection(title: "Custom Breathing") {
                        CustomBreathingStepper(title: "Inhale", value: $customInhaleSeconds, range: 1...20)
                        Toggle("Hold after inhale", isOn: $customUsesHold)
                            .tint(MoriColors.forestMoss)
                            .onChange(of: customUsesHold) { enabled in
                                if enabled && customHoldSeconds < 1 {
                                    customHoldSeconds = 1
                                }
                            }
                        if customUsesHold {
                            CustomBreathingStepper(title: "Hold", value: $customHoldSeconds, range: 1...20)
                        }
                        CustomBreathingStepper(title: "Exhale", value: $customExhaleSeconds, range: 1...20)
                    }
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(MoriColors.forestCanopy)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MoriColors.forestMuted)
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(14)
            .background(MoriColors.forestCard.opacity(0.78))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

private struct CustomBreathingStepper: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        Stepper(value: $value, in: range, step: 0.5) {
            HStack {
                Text(title)
                Spacer()
                Text(MoriBreathingTechnique.formatSeconds(value))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.forestMuted)
                    .monospacedDigit()
            }
        }
    }
}
