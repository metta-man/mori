import Foundation

enum MoriSharedDefaults {
    static let appGroupIdentifier = "group.com.mettalabs.mori"

    static var shared: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
}

struct MoriWidgetSnapshot {
    let archiveStartDate: Date
    let archiveSpanYears: Int
    let now: Date

    init(
        archiveStartDate: Date,
        archiveSpanYears: Int,
        now: Date = Date()
    ) {
        self.archiveStartDate = archiveStartDate
        self.archiveSpanYears = max(archiveSpanYears, 1)
        self.now = now
    }

    init(defaults: UserDefaults = MoriSharedDefaults.shared, now: Date = Date()) {
        let fallbackArchiveStartDate = Calendar.current.date(byAdding: .year, value: -30, to: now) ?? now
        let savedArchiveStartDate = defaults.object(forKey: "archiveStartDate") as? Date
        let savedLegacyArchiveStartDate = defaults.object(forKey: "birthDate") as? Date
        let savedArchiveSpanYears = defaults.integer(forKey: "archiveSpanYears")
        let legacyLifeExpectancy = defaults.integer(forKey: "lifeExpectancy")

        self.init(
            archiveStartDate: savedArchiveStartDate ?? savedLegacyArchiveStartDate ?? fallbackArchiveStartDate,
            archiveSpanYears: savedArchiveSpanYears > 0 ? savedArchiveSpanYears : legacyLifeExpectancy > 0 ? legacyLifeExpectancy : 80,
            now: now
        )
    }

    var totalWeeks: Int {
        archiveSpanYears * 52
    }

    var archiveWeeksElapsed: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: archiveStartDate, to: now).day ?? 0
        return min(max(0, days / 7), totalWeeks)
    }

    var currentWeekIndex: Int {
        min(archiveWeeksElapsed, max(totalWeeks - 1, 0))
    }

    var progress: Double {
        guard totalWeeks > 0 else { return 0 }
        return Double(archiveWeeksElapsed) / Double(totalWeeks)
    }

    var archiveWeekNumber: Int {
        currentWeekIndex + 1
    }

    var archiveWeekText: String {
        MoriL10n.string(
            "widget.archive.week",
            defaultValue: "Week %@",
            arguments: [archiveWeekNumber.formatted()]
        )
    }

    var archiveWeekCompactText: String {
        "W\(archiveWeekNumber.formatted())"
    }

    var archiveProgressPercentText: String {
        "\(Int((progress * 100).rounded()))%"
    }
}

struct MoriWidgetContextSnapshot: Codable, Equatable {
    static let defaultsKey = "mori_widget_context_snapshot"
    static let watchApplicationContextKey = "moriWidgetContextSnapshot"

    let pulseHeadline: String?
    let pulseTopic: String?
    let pulseGeneratedAt: Date?
    let isPulseFreshToday: Bool
    let clarityScore: Int
    let seedsToday: Int
    let bloomProgress: Double
    let reclaimedMinutesToday: Int
    let suggestedPracticeTitle: String
    let suggestedPracticeIcon: MoriBitmapIcon
    let recoveryScore: Int?
    let recoveryStateTitle: String?
    let recoveryStateDetail: String?
    let recoverySuggestedPracticeTitle: String?
    let recoverySuggestedPracticeIcon: MoriBitmapIcon?
    let recoveryUpdatedAt: Date?
    let updatedAt: Date

    init(
        pulseHeadline: String? = nil,
        pulseTopic: String? = nil,
        pulseGeneratedAt: Date? = nil,
        isPulseFreshToday: Bool = false,
        clarityScore: Int = 46,
        seedsToday: Int = 0,
        bloomProgress: Double = 0,
        reclaimedMinutesToday: Int = 0,
        suggestedPracticeTitle: String = MoriL10n.string("practice.quiet_pause", defaultValue: "Quiet Pause"),
        suggestedPracticeIcon: MoriBitmapIcon = .leaf,
        recoveryScore: Int? = nil,
        recoveryStateTitle: String? = nil,
        recoveryStateDetail: String? = nil,
        recoverySuggestedPracticeTitle: String? = nil,
        recoverySuggestedPracticeIcon: MoriBitmapIcon? = nil,
        recoveryUpdatedAt: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.pulseHeadline = Self.clean(pulseHeadline)
        self.pulseTopic = Self.clean(pulseTopic)
        self.pulseGeneratedAt = pulseGeneratedAt
        self.isPulseFreshToday = isPulseFreshToday
        self.clarityScore = max(0, min(100, clarityScore))
        self.seedsToday = max(0, seedsToday)
        self.bloomProgress = max(0, min(1, bloomProgress))
        self.reclaimedMinutesToday = max(0, reclaimedMinutesToday)
        self.suggestedPracticeTitle = Self.clean(suggestedPracticeTitle) ?? MoriL10n.string("practice.quiet_pause", defaultValue: "Quiet Pause")
        self.suggestedPracticeIcon = suggestedPracticeIcon
        self.recoveryScore = recoveryScore.map { max(0, min(100, $0)) }
        self.recoveryStateTitle = Self.clean(recoveryStateTitle)
        self.recoveryStateDetail = Self.clean(recoveryStateDetail)
        self.recoverySuggestedPracticeTitle = Self.clean(recoverySuggestedPracticeTitle)
        self.recoverySuggestedPracticeIcon = recoverySuggestedPracticeIcon
        self.recoveryUpdatedAt = recoveryUpdatedAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case pulseHeadline
        case pulseTopic
        case pulseGeneratedAt
        case isPulseFreshToday
        case clarityScore
        case seedsToday
        case bloomProgress
        case reclaimedMinutesToday
        case suggestedPracticeTitle
        case suggestedPracticeIcon
        case recoveryScore
        case recoveryStateTitle
        case recoveryStateDetail
        case recoverySuggestedPracticeTitle
        case recoverySuggestedPracticeIcon
        case recoveryUpdatedAt
        case updatedAt
        case legacySuggestedPracticeSymbol = "suggestedPracticeSymbol"
        case legacyRecoverySuggestedPracticeSymbol = "recoverySuggestedPracticeSymbol"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacySuggestedSymbol = try container.decodeIfPresent(String.self, forKey: .legacySuggestedPracticeSymbol)
        let legacyRecoverySymbol = try container.decodeIfPresent(String.self, forKey: .legacyRecoverySuggestedPracticeSymbol)

        self.init(
            pulseHeadline: try container.decodeIfPresent(String.self, forKey: .pulseHeadline),
            pulseTopic: try container.decodeIfPresent(String.self, forKey: .pulseTopic),
            pulseGeneratedAt: try container.decodeIfPresent(Date.self, forKey: .pulseGeneratedAt),
            isPulseFreshToday: try container.decodeIfPresent(Bool.self, forKey: .isPulseFreshToday) ?? false,
            clarityScore: try container.decodeIfPresent(Int.self, forKey: .clarityScore) ?? 46,
            seedsToday: try container.decodeIfPresent(Int.self, forKey: .seedsToday) ?? 0,
            bloomProgress: try container.decodeIfPresent(Double.self, forKey: .bloomProgress) ?? 0,
            reclaimedMinutesToday: try container.decodeIfPresent(Int.self, forKey: .reclaimedMinutesToday) ?? 0,
            suggestedPracticeTitle: try container.decodeIfPresent(String.self, forKey: .suggestedPracticeTitle)
                ?? MoriL10n.string("practice.quiet_pause", defaultValue: "Quiet Pause"),
            suggestedPracticeIcon: try container.decodeIfPresent(MoriBitmapIcon.self, forKey: .suggestedPracticeIcon)
                ?? Self.migratedLegacyIcon(from: legacySuggestedSymbol)
                ?? .leaf,
            recoveryScore: try container.decodeIfPresent(Int.self, forKey: .recoveryScore),
            recoveryStateTitle: try container.decodeIfPresent(String.self, forKey: .recoveryStateTitle),
            recoveryStateDetail: try container.decodeIfPresent(String.self, forKey: .recoveryStateDetail),
            recoverySuggestedPracticeTitle: try container.decodeIfPresent(String.self, forKey: .recoverySuggestedPracticeTitle),
            recoverySuggestedPracticeIcon: try container.decodeIfPresent(MoriBitmapIcon.self, forKey: .recoverySuggestedPracticeIcon)
                ?? Self.migratedLegacyIcon(from: legacyRecoverySymbol),
            recoveryUpdatedAt: try container.decodeIfPresent(Date.self, forKey: .recoveryUpdatedAt),
            updatedAt: try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(pulseHeadline, forKey: .pulseHeadline)
        try container.encodeIfPresent(pulseTopic, forKey: .pulseTopic)
        try container.encodeIfPresent(pulseGeneratedAt, forKey: .pulseGeneratedAt)
        try container.encode(isPulseFreshToday, forKey: .isPulseFreshToday)
        try container.encode(clarityScore, forKey: .clarityScore)
        try container.encode(seedsToday, forKey: .seedsToday)
        try container.encode(bloomProgress, forKey: .bloomProgress)
        try container.encode(reclaimedMinutesToday, forKey: .reclaimedMinutesToday)
        try container.encode(suggestedPracticeTitle, forKey: .suggestedPracticeTitle)
        try container.encode(suggestedPracticeIcon, forKey: .suggestedPracticeIcon)
        try container.encodeIfPresent(recoveryScore, forKey: .recoveryScore)
        try container.encodeIfPresent(recoveryStateTitle, forKey: .recoveryStateTitle)
        try container.encodeIfPresent(recoveryStateDetail, forKey: .recoveryStateDetail)
        try container.encodeIfPresent(recoverySuggestedPracticeTitle, forKey: .recoverySuggestedPracticeTitle)
        try container.encodeIfPresent(recoverySuggestedPracticeIcon, forKey: .recoverySuggestedPracticeIcon)
        try container.encodeIfPresent(recoveryUpdatedAt, forKey: .recoveryUpdatedAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }

    static func load(defaults: UserDefaults = MoriSharedDefaults.shared) -> MoriWidgetContextSnapshot {
        guard let data = defaults.data(forKey: defaultsKey),
              let snapshot = decode(data) else {
            return MoriWidgetContextSnapshot()
        }

        return snapshot
    }

    func save(defaults: UserDefaults = MoriSharedDefaults.shared) {
        guard let data = encodedData else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }

    var encodedData: Data? {
        try? JSONEncoder().encode(self)
    }

    static func decode(_ data: Data) -> MoriWidgetContextSnapshot? {
        try? JSONDecoder().decode(MoriWidgetContextSnapshot.self, from: data)
    }

    var displayPulseHeadline: String {
        guard isPulseFreshToday, let pulseHeadline else {
            return MoriL10n.string("widget.open_pulse_signal", defaultValue: "Open Pulse for today's signal")
        }

        return pulseHeadline
    }

    var displayPulseTopic: String {
        guard isPulseFreshToday, let pulseTopic else {
            return MoriL10n.string("Pulse", defaultValue: "Pulse")
        }

        return pulseTopic
    }

    var bloomPercentText: String {
        "\(Int((bloomProgress * 100).rounded()))%"
    }

    var reclaimedMinutesText: String {
        reclaimedMinutesToday == 1
            ? MoriL10n.string("time.minute_compact_one", defaultValue: "1 min")
            : MoriL10n.string("time.minute_compact_many", defaultValue: "%d min", arguments: [reclaimedMinutesToday])
    }

    var hasRecoverySnapshot: Bool {
        recoveryScore != nil
    }

    var recoveryProgress: Double {
        Double(recoveryScore ?? 0) / 100.0
    }

    var recoveryScoreText: String {
        recoveryScore.map(String.init) ?? "--"
    }

    var displayRecoveryState: String {
        recoveryStateTitle ?? MoriL10n.string("recovery.widget.no_signal", defaultValue: "No signal")
    }

    var displayRecoveryDetail: String {
        recoveryStateDetail ?? MoriL10n.string("recovery.widget.open_health", defaultValue: "Open recovery")
    }

    var displayRecoveryPracticeTitle: String {
        recoverySuggestedPracticeTitle ?? suggestedPracticeTitle
    }

    var displayRecoveryPracticeIcon: MoriBitmapIcon {
        recoverySuggestedPracticeIcon ?? suggestedPracticeIcon
    }

    func updatingRecovery(
        score: Int?,
        stateTitle: String?,
        stateDetail: String?,
        recoverySuggestedPracticeTitle: String?,
        recoverySuggestedPracticeIcon: MoriBitmapIcon?,
        updatedAt recoveryUpdatedAt: Date?
    ) -> MoriWidgetContextSnapshot {
        MoriWidgetContextSnapshot(
            pulseHeadline: pulseHeadline,
            pulseTopic: pulseTopic,
            pulseGeneratedAt: pulseGeneratedAt,
            isPulseFreshToday: isPulseFreshToday,
            clarityScore: clarityScore,
            seedsToday: seedsToday,
            bloomProgress: bloomProgress,
            reclaimedMinutesToday: reclaimedMinutesToday,
            suggestedPracticeTitle: suggestedPracticeTitle,
            suggestedPracticeIcon: suggestedPracticeIcon,
            recoveryScore: score,
            recoveryStateTitle: stateTitle,
            recoveryStateDetail: stateDetail,
            recoverySuggestedPracticeTitle: recoverySuggestedPracticeTitle,
            recoverySuggestedPracticeIcon: recoverySuggestedPracticeIcon,
            recoveryUpdatedAt: recoveryUpdatedAt,
            updatedAt: Date()
        )
    }

    private static func clean(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }

    private static func migratedLegacyIcon(from value: String?) -> MoriBitmapIcon? {
        guard let cleaned = clean(value) else { return nil }
        return MoriBitmapIcon(rawValue: cleaned) ?? MoriBitmapIcon.fromLegacySymbolName(cleaned)
    }
}

extension MoriWidgetContextSnapshot {
    static var widgetPreview: MoriWidgetContextSnapshot {
        MoriWidgetContextSnapshot(
            pulseHeadline: "One useful signal is enough. Skip the loops and start with the next grounded action.",
            pulseTopic: "Mind",
            pulseGeneratedAt: Date(),
            isPulseFreshToday: true,
            clarityScore: 74,
            seedsToday: 6,
            bloomProgress: 0.42,
            reclaimedMinutesToday: 18,
            suggestedPracticeTitle: "Settle",
            suggestedPracticeIcon: .leaf,
            recoveryScore: 72,
            recoveryStateTitle: "Balanced",
            recoveryStateDetail: "Your system looks steady. Keep the day simple and paced.",
            recoverySuggestedPracticeTitle: "Breathe",
            recoverySuggestedPracticeIcon: .breathe,
            recoveryUpdatedAt: Date(),
            updatedAt: Date()
        )
    }

    static var widgetStalePreview: MoriWidgetContextSnapshot {
        MoriWidgetContextSnapshot(
            isPulseFreshToday: false,
            clarityScore: 58,
            seedsToday: 3,
            bloomProgress: 0.24,
            reclaimedMinutesToday: 8,
            suggestedPracticeTitle: "Log",
            suggestedPracticeIcon: .journal,
            updatedAt: Date()
        )
    }

    static var widgetEmptyPreview: MoriWidgetContextSnapshot {
        MoriWidgetContextSnapshot(updatedAt: Date())
    }
}
