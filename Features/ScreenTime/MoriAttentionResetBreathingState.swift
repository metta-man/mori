import SwiftUI

enum MoriBeforeFeedPauseStyle: String, Codable, CaseIterable, Identifiable {
    case guidedBreathing = "guided_breathing"
    case quietPause = "quiet_pause"

    var id: String { rawValue }
}

struct MoriBeforeFeedPausePreferences {
    static let minGuidedCycleCount = 1
    static let maxGuidedCycleCount = 10
    static let defaultGuidedCycleCount = 1

    private let defaults: UserDefaults
    private let legacyDefaults: UserDefaults

    init(
        defaults: UserDefaults = MoriAppGroup.defaults,
        legacyDefaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
        self.legacyDefaults = legacyDefaults
    }

    /// Converts the former technique-plus-duration preferences into the v1
    /// pause model. This intentionally runs before the existing duration
    /// migration so a fresh install keeps the one-cycle Long Exhale default
    /// while an existing install can retain its former reset length or saved
    /// cycle count.
    func migrateLegacyPausePreferencesIfNeeded() {
        guard !defaults.bool(forKey: MoriScreenTimeShared.beforeFeedPausePreferencesMigrationKey) else {
            normalizePausePreferences()
            return
        }

        let storedStyle = defaults.string(forKey: MoriScreenTimeShared.beforeFeedPauseStyleKey)
            .flatMap(MoriBeforeFeedPauseStyle.init(rawValue:))
        let legacyTechniqueID = storedTechniqueID()
        let style = storedStyle
            ?? (legacyTechniqueID == MoriScreenTimeShared.beforeFeedBreathingNoneID ? .quietPause : .guidedBreathing)
        let resolvedTechniqueID = normalizedTechniqueID(legacyTechniqueID)

        defaults.set(style.rawValue, forKey: MoriScreenTimeShared.beforeFeedPauseStyleKey)
        defaults.set(resolvedTechniqueID, forKey: MoriScreenTimeShared.beforeFeedBreathingTechniqueIDKey)

        if defaults.object(forKey: MoriScreenTimeShared.beforeFeedGuidedCycleCountKey) == nil {
            let cycleCount: Int
            if style == .guidedBreathing,
               let legacyDuration = storedLegacyDurationSeconds(),
               let pattern = migrationPattern(for: resolvedTechniqueID),
               pattern.totalCycleDuration > 0 {
                cycleCount = normalizedGuidedCycleCount(
                    Int((Double(legacyDuration) / pattern.totalCycleDuration).rounded())
                )
            } else {
                cycleCount = Self.defaultGuidedCycleCount
            }
            defaults.set(cycleCount, forKey: MoriScreenTimeShared.beforeFeedGuidedCycleCountKey)
        }

        defaults.set(true, forKey: MoriScreenTimeShared.beforeFeedPausePreferencesMigrationKey)
        normalizePausePreferences()
    }

    func normalizePersistedSettings() {
        normalizePausePreferences()
        _ = quietDurationSeconds()
    }

    func pauseStyle() -> MoriBeforeFeedPauseStyle {
        guard let rawValue = defaults.string(forKey: MoriScreenTimeShared.beforeFeedPauseStyleKey),
              let style = MoriBeforeFeedPauseStyle(rawValue: rawValue)
        else {
            defaults.set(
                MoriBeforeFeedPauseStyle.guidedBreathing.rawValue,
                forKey: MoriScreenTimeShared.beforeFeedPauseStyleKey
            )
            return .guidedBreathing
        }
        return style
    }

    func savePauseStyle(_ style: MoriBeforeFeedPauseStyle) {
        defaults.set(style.rawValue, forKey: MoriScreenTimeShared.beforeFeedPauseStyleKey)
    }

    func guidedCycleCount() -> Int {
        let stored = defaults.object(forKey: MoriScreenTimeShared.beforeFeedGuidedCycleCountKey) == nil
            ? Self.defaultGuidedCycleCount
            : defaults.integer(forKey: MoriScreenTimeShared.beforeFeedGuidedCycleCountKey)
        let normalized = normalizedGuidedCycleCount(stored)
        if stored != normalized {
            defaults.set(normalized, forKey: MoriScreenTimeShared.beforeFeedGuidedCycleCountKey)
        }
        return normalized
    }

    func saveGuidedCycleCount(_ count: Int) {
        defaults.set(
            normalizedGuidedCycleCount(count),
            forKey: MoriScreenTimeShared.beforeFeedGuidedCycleCountKey
        )
    }

    func techniqueID() -> String {
        let stored = defaults.string(forKey: MoriScreenTimeShared.beforeFeedBreathingTechniqueIDKey)
        let normalized = normalizedTechniqueID(stored)
        if stored != normalized {
            defaults.set(normalized, forKey: MoriScreenTimeShared.beforeFeedBreathingTechniqueIDKey)
        }
        return normalized
    }

    func saveTechniqueID(_ techniqueID: String) {
        defaults.set(
            normalizedTechniqueID(techniqueID),
            forKey: MoriScreenTimeShared.beforeFeedBreathingTechniqueIDKey
        )
    }

    func quietDurationSeconds() -> Int {
        BeforeFeedGateStore(defaults: defaults, legacyDefaults: legacyDefaults).durationSeconds()
    }

    func saveQuietDurationSeconds(_ seconds: Int) {
        BeforeFeedGateStore(defaults: defaults, legacyDefaults: legacyDefaults).saveDurationSeconds(seconds)
    }

    func resolvedTechnique() -> MoriBreathingTechnique? {
        guard pauseStyle() == .guidedBreathing else { return nil }
        return MoriBreathingTechniqueRepository.getTechnique(id: techniqueID())
            ?? MoriBreathingTechniqueRepository.getTechnique(
                id: MoriScreenTimeShared.defaultBeforeFeedBreathingTechniqueID
            )
    }

    func resolvedPattern(
        customInhaleSeconds: Double = 4,
        customHoldSeconds: Double = 0,
        customExhaleSeconds: Double = 6,
        customUsesHold: Bool = false
    ) -> MoriBreathPattern? {
        guard let technique = resolvedTechnique() else { return nil }
        guard technique.id == MoriBreathingTechniqueID.custom.rawValue else {
            return technique.breathPattern
        }

        return MoriBreathPattern(
            inhale: Self.normalizedCustomPhase(customInhaleSeconds, fallback: 4),
            inhaleHold: customUsesHold
                ? Self.normalizedCustomPhase(customHoldSeconds, fallback: 1)
                : nil,
            exhale: Self.normalizedCustomPhase(customExhaleSeconds, fallback: 6),
            exhaleHold: nil
        )
    }

    func resolvedDuration(
        customInhaleSeconds: Double = 4,
        customHoldSeconds: Double = 0,
        customExhaleSeconds: Double = 6,
        customUsesHold: Bool = false
    ) -> TimeInterval {
        guard pauseStyle() == .guidedBreathing else {
            return TimeInterval(quietDurationSeconds())
        }
        guard let pattern = resolvedPattern(
            customInhaleSeconds: customInhaleSeconds,
            customHoldSeconds: customHoldSeconds,
            customExhaleSeconds: customExhaleSeconds,
            customUsesHold: customUsesHold
        ) else {
            return 0
        }
        return pattern.totalCycleDuration * TimeInterval(guidedCycleCount())
    }

    private func normalizePausePreferences() {
        _ = pauseStyle()
        _ = guidedCycleCount()
        _ = techniqueID()
    }

    private func storedTechniqueID() -> String? {
        if let stored = defaults.string(forKey: MoriScreenTimeShared.beforeFeedBreathingTechniqueIDKey) {
            return stored
        }
        return legacyDefaults.string(forKey: MoriScreenTimeShared.beforeFeedBreathingTechniqueIDKey)
    }

    private func storedLegacyDurationSeconds() -> Int? {
        if defaults.object(forKey: MoriScreenTimeShared.beforeFeedDurationSecondsKey) != nil {
            let seconds = defaults.integer(forKey: MoriScreenTimeShared.beforeFeedDurationSecondsKey)
            return seconds > 0 ? normalizedQuietDurationSeconds(seconds) : nil
        }

        let groupMinutes = defaults.integer(forKey: MoriScreenTimeShared.beforeFeedDurationMinutesKey)
        let standardMinutes = legacyDefaults.integer(forKey: MoriScreenTimeShared.beforeFeedDurationMinutesKey)
        let minutes = groupMinutes > 0 ? groupMinutes : standardMinutes
        return minutes > 0 ? normalizedQuietDurationSeconds(minutes * 60) : nil
    }

    private func migrationPattern(for techniqueID: String) -> MoriBreathPattern? {
        guard let technique = MoriBreathingTechniqueRepository.getTechnique(id: techniqueID) else {
            return nil
        }
        guard technique.id == MoriBreathingTechniqueID.custom.rawValue else {
            return technique.breathPattern
        }

        return MoriBreathPattern(
            inhale: storedLegacyCustomPhase(
                forKey: "mori_settle_breathing_custom_inhale",
                fallback: 4
            ),
            inhaleHold: legacyDefaults.bool(forKey: "mori_settle_breathing_custom_uses_hold")
                ? storedLegacyCustomPhase(
                    forKey: "mori_settle_breathing_custom_hold",
                    fallback: 1
                )
                : nil,
            exhale: storedLegacyCustomPhase(
                forKey: "mori_settle_breathing_custom_exhale",
                fallback: 6
            ),
            exhaleHold: nil
        )
    }

    private func storedLegacyCustomPhase(forKey key: String, fallback: Double) -> Double {
        guard legacyDefaults.object(forKey: key) != nil else { return fallback }
        return Self.normalizedCustomPhase(legacyDefaults.double(forKey: key), fallback: fallback)
    }

    private func normalizedTechniqueID(_ techniqueID: String?) -> String {
        guard let techniqueID,
              techniqueID != MoriScreenTimeShared.beforeFeedBreathingNoneID,
              MoriBreathingTechniqueRepository.getTechnique(id: techniqueID) != nil
        else {
            return MoriScreenTimeShared.defaultBeforeFeedBreathingTechniqueID
        }
        return techniqueID
    }

    private func normalizedGuidedCycleCount(_ count: Int) -> Int {
        min(Self.maxGuidedCycleCount, max(Self.minGuidedCycleCount, count))
    }

    private func normalizedQuietDurationSeconds(_ seconds: Int) -> Int {
        min(
            MoriScreenTimeShared.maxBeforeFeedDurationSeconds,
            max(MoriScreenTimeShared.minBeforeFeedDurationSeconds, seconds)
        )
    }

    static func normalizedCustomPhase(_ seconds: Double, fallback: Double) -> Double {
        guard seconds.isFinite else { return fallback }
        return min(20, max(1, seconds))
    }
}

/// An immutable copy of the Before Feed breathing choice used by one presented
/// sheet. Settings and the global custom pattern may change while the sheet is
/// open, but the active pause remains truthful to the choice it began with.
struct MoriBeforeFeedPauseSessionSnapshot: Equatable {
    let style: MoriBeforeFeedPauseStyle
    let guidedCycleCount: Int
    let techniqueID: String
    let pattern: MoriBreathPattern?
    let displayedDurationSeconds: Int
    let targetDuration: TimeInterval

    static let defaultValue = MoriBeforeFeedPauseSessionSnapshot(
        style: .guidedBreathing,
        guidedCycleCount: MoriBeforeFeedPausePreferences.defaultGuidedCycleCount,
        techniqueID: MoriScreenTimeShared.defaultBeforeFeedBreathingTechniqueID,
        pattern: MoriBeforeFeedBreathKey.pattern,
        displayedDurationSeconds: Int(ceil(MoriBeforeFeedBreathKey.duration)),
        targetDuration: MoriBeforeFeedBreathKey.duration
    )

    init(
        preferences: MoriBeforeFeedPausePreferences,
        customInhaleSeconds: Double,
        customHoldSeconds: Double,
        customExhaleSeconds: Double,
        customUsesHold: Bool
    ) {
        let style = preferences.pauseStyle()
        let guidedCycleCount = preferences.guidedCycleCount()
        let techniqueID = preferences.techniqueID()

        self.style = style
        self.guidedCycleCount = guidedCycleCount
        self.techniqueID = techniqueID

        switch style {
        case .guidedBreathing:
            let pattern = preferences.resolvedPattern(
                customInhaleSeconds: customInhaleSeconds,
                customHoldSeconds: customHoldSeconds,
                customExhaleSeconds: customExhaleSeconds,
                customUsesHold: customUsesHold
            ) ?? MoriBeforeFeedBreathKey.pattern
            let targetDuration = max(
                0.1,
                pattern.totalCycleDuration * TimeInterval(guidedCycleCount)
            )
            self.pattern = pattern
            self.targetDuration = targetDuration
            displayedDurationSeconds = max(1, Int(ceil(targetDuration)))

        case .quietPause:
            let duration = preferences.quietDurationSeconds()
            pattern = nil
            targetDuration = TimeInterval(duration)
            displayedDurationSeconds = duration
        }
    }

    init(
        style: MoriBeforeFeedPauseStyle,
        guidedCycleCount: Int,
        techniqueID: String,
        pattern: MoriBreathPattern?,
        displayedDurationSeconds: Int,
        targetDuration: TimeInterval
    ) {
        self.style = style
        self.guidedCycleCount = guidedCycleCount
        self.techniqueID = techniqueID
        self.pattern = pattern
        self.displayedDurationSeconds = displayedDurationSeconds
        self.targetDuration = targetDuration
    }
}

enum MoriBeforeFeedFlowStage: Equatable {
    case breathKey
    case intent
}

enum MoriBeforeFeedBreathKey {
    static let pattern = MoriBreathPattern(
        inhale: 4,
        inhaleHold: nil,
        exhale: 6,
        exhaleHold: nil
    )
    static let duration: TimeInterval = pattern.totalCycleDuration
}

enum MoriBeforeFeedEnoughChoice: String, Codable, CaseIterable, Identifiable {
    case oneReply = "one_reply"
    case twoMinutes = "2_minutes"
    case fiveMinutes = "5_minutes"
    case tenMinutes = "10_minutes"
    case fifteenMinutes = "15_minutes"

    var id: String { rawValue }

    var openWindowSeconds: Int {
        switch self {
        case .oneReply, .fiveMinutes:
            return 5 * 60
        case .twoMinutes:
            return 2 * 60
        case .tenMinutes:
            return 10 * 60
        case .fifteenMinutes:
            return 15 * 60
        }
    }

    func isAvailable(for reason: MoriBeforeFeedIntentReason) -> Bool {
        self != .oneReply || reason == .replyToSomeone
    }

    static func choices(for reason: MoriBeforeFeedIntentReason) -> [Self] {
        allCases.filter { $0.isAvailable(for: reason) }
    }
}

enum MoriBeforeFeedReturnAnchor: String, Codable, CaseIterable, Identifiable {
    case work
    case study
    case someone
    case rest
    case move
    case sleep

    var id: String { rawValue }
}

enum MoriBeforeFeedReturnAnchorPolicy {
    static func shouldShow(for reason: MoriBeforeFeedIntentReason) -> Bool {
        switch reason {
        case .replyToSomeone, .learn, .relax, .habit, .other:
            return true
        }
    }
}

struct MoriBeforeFeedFlowState: Equatable {
    private(set) var stage: MoriBeforeFeedFlowStage = .breathKey
    private(set) var hasCompletedBreath = false
    private(set) var reason: MoriBeforeFeedIntentReason?
    private(set) var enoughChoice: MoriBeforeFeedEnoughChoice?
    private(set) var returnAnchor: MoriBeforeFeedReturnAnchor?

    var canOpenFeed: Bool {
        stage == .intent && hasCompletedBreath && reason != nil && enoughChoice != nil
    }

    var confirmedOpenWindowSeconds: Int? {
        guard canOpenFeed else { return nil }
        return enoughChoice?.openWindowSeconds
    }

    mutating func selectReason(_ reason: MoriBeforeFeedIntentReason) {
        guard stage == .intent, hasCompletedBreath else { return }
        self.reason = reason
        enoughChoice = nil
        returnAnchor = nil
    }

    @discardableResult
    mutating func completeBreath() -> Bool {
        guard stage == .breathKey else { return false }
        hasCompletedBreath = true
        stage = .intent
        return true
    }

    @discardableResult
    mutating func selectEnoughChoice(_ choice: MoriBeforeFeedEnoughChoice) -> Bool {
        guard stage == .intent,
              hasCompletedBreath,
              let reason,
              choice.isAvailable(for: reason)
        else {
            return false
        }
        enoughChoice = choice
        return true
    }

    mutating func selectReturnAnchor(_ anchor: MoriBeforeFeedReturnAnchor?) {
        guard stage == .intent, hasCompletedBreath else { return }
        returnAnchor = anchor
    }

    mutating func reset() {
        self = Self()
    }
}

struct MoriAttentionResetBreathingState {
    let context: MoriAttentionResetContext
    let beforeFeedTechniqueID: String
    let morningGateTechniqueID: String
    let customInhaleSeconds: Double
    let customHoldSeconds: Double
    let customExhaleSeconds: Double
    let customUsesHold: Bool
    let isRunning: Bool
    let isComplete: Bool
    let elapsedTime: TimeInterval

    var selectedTechniqueID: String {
        switch context {
        case .beforeFeed:
            return beforeFeedTechniqueID
        case .morningGate:
            return morningGateTechniqueID
        }
    }

    var selectedTechnique: MoriBreathingTechnique? {
        guard selectedTechniqueID != MoriScreenTimeShared.beforeFeedBreathingNoneID else {
            return nil
        }

        let fallbackID: String
        switch context {
        case .beforeFeed:
            fallbackID = MoriScreenTimeShared.defaultBeforeFeedBreathingTechniqueID
        case .morningGate:
            fallbackID = MoriScreenTimeShared.defaultMorningGateBreathingTechniqueID
        }

        return MoriBreathingTechniqueRepository.getTechnique(id: selectedTechniqueID)
            ?? MoriBreathingTechniqueRepository.getTechnique(id: fallbackID)
    }

    var hasTechnique: Bool {
        selectedTechnique != nil
    }

    var headerSubtitle: String {
        context.subtitle(technique: selectedTechnique)
    }

    var cueText: String {
        if isRunning {
            return context.runningCue(
                hasTechnique: hasTechnique,
                breathingLabel: visualState.label
            )
        }

        return context.idleCue(hasTechnique: hasTechnique, isComplete: isComplete)
    }

    var segments: [MoriBreathingCycleSegment] {
        breathPattern?.segments ?? []
    }

    var visualState: MoriBreathingCycleVisualState {
        guard isRunning, !segments.isEmpty else { return .idle }
        return MoriBreathingCycle.visualState(
            for: segments,
            elapsedTime: elapsedTime
        )
    }

    var phaseRemaining: TimeInterval {
        MoriBreathingCycle.phaseRemaining(
            for: segments,
            elapsedTime: elapsedTime
        )
    }

    var tint: Color {
        guard let technique = selectedTechnique else {
            return MoriColors.botanicalMoss
        }
        return Color(hex: technique.gradientColors.first ?? "#687E5E")
    }

    private var breathPattern: MoriBreathPattern? {
        guard let technique = selectedTechnique else { return nil }

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
}
