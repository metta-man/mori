import Foundation

enum MoriRecoveryAuthorizationStatus: Equatable {
    case needsPermission
    case healthUnavailable
    case missingData
    case ready
}

enum MoriRecoveryState: String, CaseIterable, Equatable {
    case unknown
    case openReady
    case balanced
    case strained
    case depleted

    var title: String {
        switch self {
        case .unknown:
            return MoriL10n.display("Recovery unavailable")
        case .openReady:
            return MoriL10n.display("Open / Ready")
        case .balanced:
            return MoriL10n.display("Balanced")
        case .strained:
            return MoriL10n.display("Strained")
        case .depleted:
            return MoriL10n.display("Depleted")
        }
    }

    var compactTitle: String {
        switch self {
        case .unknown:
            return MoriL10n.display("No signal")
        case .openReady:
            return MoriL10n.display("Ready")
        case .balanced:
            return MoriL10n.display("Balanced")
        case .strained:
            return MoriL10n.display("Strained")
        case .depleted:
            return MoriL10n.display("Rest")
        }
    }

    var guidance: String {
        switch self {
        case .unknown:
            return MoriL10n.display("Connect Apple Health to read your morning recovery signals.")
        case .openReady:
            return MoriL10n.display("Your system looks open today. Normal training or deep work can fit.")
        case .balanced:
            return MoriL10n.display("Your system looks steady. Keep the day simple and paced.")
        case .strained:
            return MoriL10n.display("Your system looks slightly activated today. Choose lighter effort first.")
        case .depleted:
            return MoriL10n.display("Your recovery signals look low. Protect energy and keep stimulation low.")
        }
    }

    var icon: MoriBitmapIcon {
        switch self {
        case .unknown:
            return .lockShield
        case .openReady:
            return .leaf
        case .balanced:
            return .leaf
        case .strained:
            return .breathe
        case .depleted:
            return .quiet
        }
    }

    var symbolName: String { icon.legacySystemName }
}

enum MoriRecoverySignalStatus: String, Equatable {
    case supportive
    case steady
    case caution
    case elevated
    case unavailable
}

struct MoriRecoverySignal: Identifiable, Equatable {
    let id: String
    let title: String
    let valueText: String
    let baselineText: String?
    let comparisonText: String
    let impact: Int
    let status: MoriRecoverySignalStatus
    let icon: MoriBitmapIcon

    var symbolName: String { icon.legacySystemName }

    var llmSummary: String {
        "\(title): \(comparisonText)"
    }
}

struct MoriRecoverySleepSummary: Equatable {
    let duration: TimeInterval?
    let deepDuration: TimeInterval?
    let remDuration: TimeInterval?
    let coreDuration: TimeInterval?
    let wakeAfterSleepOnset: TimeInterval?
    let score: Double?

    static let unavailable = MoriRecoverySleepSummary(
        duration: nil,
        deepDuration: nil,
        remDuration: nil,
        coreDuration: nil,
        wakeAfterSleepOnset: nil,
        score: nil
    )

    var durationText: String {
        guard let duration else { return MoriL10n.display("No sleep data") }
        return MoriRecoveryFormatter.duration(duration)
    }

    var stageSummaryText: String {
        guard duration != nil else { return MoriL10n.display("Sleep stages unavailable") }

        let deep = deepDuration.map(MoriRecoveryFormatter.duration) ?? "--"
        let rem = remDuration.map(MoriRecoveryFormatter.duration) ?? "--"
        return MoriL10n.string("recovery.sleep.stage_summary", defaultValue: "Deep %@ / REM %@", arguments: [deep, rem])
    }

    var impactText: String {
        guard let score else { return MoriL10n.display("Recovery impact unavailable") }

        switch score {
        case 82...:
            return MoriL10n.display("Sleep supports recovery")
        case 62..<82:
            return MoriL10n.display("Sleep was fair")
        case 42..<62:
            return MoriL10n.display("Sleep may be limiting recovery")
        default:
            return MoriL10n.display("Sleep is a recovery priority")
        }
    }
}

struct MoriRecoveryWorkoutSample: Equatable {
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let activeEnergyKilocalories: Double
    let distanceMeters: Double
}

struct MoriRecoveryTrainingSummary: Equatable {
    let lastDayMinutes: Double
    let sevenDayDailyAverage: Double?
    let twentyEightDayDailyAverage: Double?
    let highIntensityMinutes: Double?
    let loadPoints: Double
    let isElevated: Bool

    static let unavailable = MoriRecoveryTrainingSummary(
        lastDayMinutes: 0,
        sevenDayDailyAverage: nil,
        twentyEightDayDailyAverage: nil,
        highIntensityMinutes: nil,
        loadPoints: 0,
        isElevated: false
    )

    var title: String {
        if lastDayMinutes <= 0 {
            return MoriL10n.display("Training steady")
        }

        return MoriL10n.string("duration.minutes_short", defaultValue: "%dm", arguments: [Int(lastDayMinutes.rounded())])
    }

    var detail: String {
        if isElevated {
            return MoriL10n.display("Yesterday's training load is elevated versus your baseline.")
        }

        if let highIntensityMinutes, highIntensityMinutes >= 10 {
            return MoriL10n.string(
                "recovery.training.high_intensity_detail",
                defaultValue: "Workout load is steady, with %d min of higher heart-rate effort.",
                arguments: [Int(highIntensityMinutes.rounded())]
            )
        }

        if lastDayMinutes <= 0 {
            return MoriL10n.display("No workout load detected in the last day.")
        }

        return MoriL10n.display("Workout load looks steady versus recent weeks.")
    }
}

struct MoriRecoverySnapshot: Equatable {
    let date: Date
    let score: Int?
    let state: MoriRecoveryState
    let status: MoriRecoveryAuthorizationStatus
    let nervousSystemLabel: String
    let bodyLoadLabel: String
    let sleepSummary: MoriRecoverySleepSummary
    let trainingSummary: MoriRecoveryTrainingSummary
    let suggestedPractice: MoriPractice
    let primaryMessage: String
    let signals: [MoriRecoverySignal]
    let missingSignals: [String]

    static var permissionNeeded: MoriRecoverySnapshot {
        MoriRecoverySnapshot(
            date: Date(),
            score: nil,
            state: .unknown,
            status: .needsPermission,
            nervousSystemLabel: MoriL10n.display("Connect Health"),
            bodyLoadLabel: MoriL10n.display("Unavailable"),
            sleepSummary: .unavailable,
            trainingSummary: .unavailable,
            suggestedPractice: .breatheMinute,
            primaryMessage: MoriL10n.display("Connect Apple Health to read recovery signals."),
            signals: [],
            missingSignals: []
        )
    }

    static var healthUnavailable: MoriRecoverySnapshot {
        MoriRecoverySnapshot(
            date: Date(),
            score: nil,
            state: .unknown,
            status: .healthUnavailable,
            nervousSystemLabel: MoriL10n.display("Unavailable"),
            bodyLoadLabel: MoriL10n.display("Unavailable"),
            sleepSummary: .unavailable,
            trainingSummary: .unavailable,
            suggestedPractice: .quietNote,
            primaryMessage: MoriL10n.display("Health data is unavailable on this device."),
            signals: [],
            missingSignals: []
        )
    }

    static var uiTestReadyFixture: MoriRecoverySnapshot {
        let sleepDuration: TimeInterval = (7 * 60 * 60) + (52 * 60)
        let deepDuration: TimeInterval = (1 * 60 * 60) + (24 * 60)
        let remDuration: TimeInterval = (1 * 60 * 60) + (36 * 60)
        let sleepBaseline: TimeInterval = (7 * 60 * 60) + (34 * 60)

        return MoriRecoverySnapshot(
            date: Date(timeIntervalSince1970: 1_782_432_000),
            score: 86,
            state: .openReady,
            status: .ready,
            nervousSystemLabel: MoriL10n.display("Calm"),
            bodyLoadLabel: MoriL10n.display("Steady"),
            sleepSummary: MoriRecoverySleepSummary(
                duration: sleepDuration,
                deepDuration: deepDuration,
                remDuration: remDuration,
                coreDuration: sleepDuration - deepDuration - remDuration,
                wakeAfterSleepOnset: 11 * 60,
                score: 88
            ),
            trainingSummary: MoriRecoveryTrainingSummary(
                lastDayMinutes: 22,
                sevenDayDailyAverage: 28,
                twentyEightDayDailyAverage: 31,
                highIntensityMinutes: 6,
                loadPoints: 18,
                isElevated: false
            ),
            suggestedPractice: .focusFifteen,
            primaryMessage: MoriL10n.display("Your system looks open today. Normal training or deep work can fit."),
            signals: [
                MoriRecoverySignal(
                    id: "ui-test-hrv",
                    title: "HRV",
                    valueText: "72 ms",
                    baselineText: MoriL10n.string("recovery.baseline.value", defaultValue: "%@ baseline", arguments: ["68 ms"]),
                    comparisonText: MoriL10n.display("above baseline"),
                    impact: 18,
                    status: .supportive,
                    icon: .pulse
                ),
                MoriRecoverySignal(
                    id: "ui-test-resting-heart-rate",
                    title: "Resting HR",
                    valueText: "58 bpm",
                    baselineText: MoriL10n.string("recovery.baseline.value", defaultValue: "%@ baseline", arguments: ["61 bpm"]),
                    comparisonText: MoriL10n.display("near baseline"),
                    impact: 16,
                    status: .supportive,
                    icon: .heart
                ),
                MoriRecoverySignal(
                    id: "ui-test-sleep",
                    title: "Sleep",
                    valueText: MoriRecoveryFormatter.duration(sleepDuration),
                    baselineText: MoriL10n.string(
                        "recovery.baseline.value",
                        defaultValue: "%@ baseline",
                        arguments: [MoriRecoveryFormatter.duration(sleepBaseline)]
                    ),
                    comparisonText: MoriL10n.display("Sleep supports recovery"),
                    impact: 18,
                    status: .supportive,
                    icon: .quiet
                ),
                MoriRecoverySignal(
                    id: "ui-test-respiratory-rate",
                    title: "Respiratory Rate",
                    valueText: "14.8 / min",
                    baselineText: MoriL10n.string("recovery.baseline.value", defaultValue: "%@ baseline", arguments: ["15.1 / min"]),
                    comparisonText: MoriL10n.display("near baseline"),
                    impact: 0,
                    status: .steady,
                    icon: .breathe
                ),
                MoriRecoverySignal(
                    id: "ui-test-temperature",
                    title: "Temperature",
                    valueText: "36.4 C",
                    baselineText: MoriL10n.string("recovery.baseline.value", defaultValue: "%@ baseline", arguments: ["36.5 C"]),
                    comparisonText: MoriL10n.display("near baseline"),
                    impact: 0,
                    status: .steady,
                    icon: .leaf
                )
            ],
            missingSignals: []
        )
    }

    var scoreText: String {
        score.map(String.init) ?? "--"
    }

    var hasUsableData: Bool {
        score != nil || !signals.isEmpty
    }

    var llmInsightLines: [String] {
        guard hasUsableData else { return [] }

        var lines = [
            "Readiness: \(scoreText) / 100",
            "Recovery state: \(state.title)",
            "Nervous system: \(nervousSystemLabel)",
            "Body load: \(bodyLoadLabel)",
            "Sleep: \(sleepSummary.impactText)",
            "Training: \(trainingSummary.isElevated ? "elevated" : "steady")",
            "Suggested practice: \(suggestedPractice.title)"
        ]
        lines.append(contentsOf: signals.map(\.llmSummary))
        return lines
    }
}

enum MoriRecoveryFormatter {
    static func duration(_ seconds: TimeInterval) -> String {
        let minutes = max(0, Int((seconds / 60).rounded()))
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            return MoriL10n.string("duration.hours_minutes_short", defaultValue: "%dh %dm", arguments: [hours, remainingMinutes])
        }

        return MoriL10n.string("duration.minutes_short", defaultValue: "%dm", arguments: [remainingMinutes])
    }
}
