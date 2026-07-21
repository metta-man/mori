import Foundation

enum MoriPracticeRoute: String, Equatable {
    case quickComplete
    case breathing
    case settle
    case quietMode
    case journal
    case dailyCheckIn
    case focusCycle
}

enum MoriPracticeNeed: String, CaseIterable, Identifiable {
    case calmBody
    case focusWork
    case protectAttention
    case reflect
    case stepAway

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calmBody:
            return MoriL10n.string("practice_need.calm_body.title", defaultValue: "Calm my body")
        case .focusWork:
            return MoriL10n.string("practice_need.focus_work.title", defaultValue: "Focus my work")
        case .protectAttention:
            return MoriL10n.string("practice_need.protect_attention.title", defaultValue: "Protect attention")
        case .reflect:
            return MoriL10n.string("practice_need.reflect.title", defaultValue: "Reflect")
        case .stepAway:
            return MoriL10n.string("practice_need.step_away.title", defaultValue: "Step away")
        }
    }

    var subtitle: String {
        switch self {
        case .calmBody:
            return MoriL10n.string("practice_need.calm_body.subtitle", defaultValue: "Use the breath and a quiet timer to settle your nervous system.")
        case .focusWork:
            return MoriL10n.string("practice_need.focus_work.subtitle", defaultValue: "Make one meaningful task easier to begin.")
        case .protectAttention:
            return MoriL10n.string("practice_need.protect_attention.subtitle", defaultValue: "Pause before feeds, reduce noisy loops, and keep selected apps limited.")
        case .reflect:
            return MoriL10n.string("practice_need.reflect.subtitle", defaultValue: "Turn the day into a memory instead of another blur.")
        case .stepAway:
            return MoriL10n.string("practice_need.step_away.subtitle", defaultValue: "Leave the screen for a few minutes and come back clearer.")
        }
    }

    var symbolName: String {
        icon.legacySystemName
    }

    var icon: MoriBitmapIcon {
        switch self {
        case .calmBody:
            return .breathe
        case .focusWork:
            return .timer
        case .protectAttention:
            return .lockShield
        case .reflect:
            return .journal
        case .stepAway:
            return .leaf
        }
    }
}

struct MoriPractice: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let durationText: String
    let minutes: Int
    let seeds: Int
    let icon: MoriBitmapIcon
    let kind: MoriMindfulActionKind
    let note: String
    let domains: [LifeDomain]
    let route: MoriPracticeRoute

    var symbolName: String {
        icon.legacySystemName
    }

    var domainText: String {
        domains.map(\.title).joined(separator: " / ")
    }

    var seedText: String {
        MoriL10n.string(
            seeds == 1 ? "practice.seed.badge_one" : "practice.seed.badge_many",
            defaultValue: seeds == 1 ? "+%d Seed" : "+%d Seeds",
            arguments: [seeds]
        )
    }

    var primaryNeed: MoriPracticeNeed {
        switch id {
        case Self.breatheMinute.id, Self.settleThree.id:
            return .calmBody
        case Self.focusFifteen.id:
            return .focusWork
        case Self.quietPause.id:
            return .protectAttention
        case Self.quietNote.id, Self.dailyCheckIn.id:
            return .reflect
        case Self.walkReset.id:
            return .stepAway
        default:
            return .reflect
        }
    }

    static var breatheMinute: MoriPractice {
        MoriPractice(
            id: "breathe-minute",
            title: MoriL10n.string("practice.breathe.title", defaultValue: "Breathe"),
            description: MoriL10n.string("practice.breathe.description", defaultValue: "1 min nervous system reset"),
            durationText: MoriL10n.string("time.minute_compact_one", defaultValue: "1 min"),
            minutes: 1,
            seeds: 1,
            icon: .breathe,
            kind: .breathingSession,
            note: MoriL10n.string("practice.breathe.note", defaultValue: "Completed a short breath reset"),
            domains: [.body, .rest],
            route: .breathing
        )
    }

    static var settleThree: MoriPractice {
        MoriPractice(
            id: "settle-three",
            title: MoriL10n.string("practice.settle.title", defaultValue: "Settle"),
            description: MoriL10n.string("practice.settle.description", defaultValue: "3 min return to presence"),
            durationText: MoriL10n.string("time.minute_compact_many", defaultValue: "%d min", arguments: [3]),
            minutes: 3,
            seeds: 1,
            icon: .breathe,
            kind: .settleSession,
            note: MoriL10n.string("practice.settle.note", defaultValue: "Completed a short Settle practice"),
            domains: [.rest, .wonder],
            route: .settle
        )
    }

    static var quietNote: MoriPractice {
        MoriPractice(
            id: "quiet-note",
            title: MoriL10n.string("practice.journal.title", defaultValue: "Log"),
            description: MoriL10n.string("practice.journal.description", defaultValue: "private reflection"),
            durationText: MoriL10n.string("time.minute_compact_many", defaultValue: "%d min", arguments: [3]),
            minutes: 3,
            seeds: 1,
            icon: .journal,
            kind: .journal,
            note: MoriL10n.string("practice.journal.note", defaultValue: "Wrote a quiet note"),
            domains: [.craft, .mind],
            route: .journal
        )
    }

    static var dailyCheckIn: MoriPractice {
        MoriPractice(
            id: "daily-check-in",
            title: MoriL10n.string("practice.daily_check_in.title", defaultValue: "Daily Check-In"),
            description: MoriL10n.string("practice.daily_check_in.description", defaultValue: "how today went"),
            durationText: MoriL10n.string("practice.duration.reflect", defaultValue: "Reflect"),
            minutes: 0,
            seeds: 1,
            icon: .journal,
            kind: .dailyCheckIn,
            note: MoriL10n.string("practice.daily_check_in.note", defaultValue: "Reflected on how today went"),
            domains: [.body, .rest, .love],
            route: .dailyCheckIn
        )
    }

    static var focusFifteen: MoriPractice {
        MoriPractice(
            id: "focus-fifteen",
            title: MoriL10n.string("practice.pomodoro.title", defaultValue: "Deep Session"),
            description: MoriL10n.string("practice.pomodoro.description", defaultValue: "15 quiet minutes"),
            durationText: MoriL10n.string("time.minute_compact_many", defaultValue: "%d min", arguments: [15]),
            minutes: 15,
            seeds: 2,
            icon: .timer,
            kind: .pomodoroSession,
            note: MoriL10n.string("practice.pomodoro.note", defaultValue: "Protected a short quiet session"),
            domains: [.craft, .mind],
            route: .focusCycle
        )
    }

    static var quietPause: MoriPractice {
        MoriPractice(
            id: "quiet-pause",
            title: MoriL10n.string("practice.quiet_mode.title", defaultValue: "Quiet Mode"),
            description: MoriL10n.string("practice.quiet_mode.description", defaultValue: "pause before scrolling"),
            durationText: MoriL10n.string("time.minute_compact_many", defaultValue: "%d min", arguments: [2]),
            minutes: 2,
            seeds: 1,
            icon: .quiet,
            kind: .quietTimer,
            note: MoriL10n.string("practice.quiet_mode.note", defaultValue: "Paused before scrolling"),
            domains: [.rest, .body, .mind],
            route: .quietMode
        )
    }

    static var walkReset: MoriPractice {
        MoriPractice(
            id: "walk-reset",
            title: MoriL10n.string("practice.walk_reset.title", defaultValue: "Walk / Offline Reset"),
            description: MoriL10n.string("practice.walk_reset.description", defaultValue: "Leave the screen"),
            durationText: MoriL10n.string("time.minute_compact_many", defaultValue: "%d min", arguments: [8]),
            minutes: 8,
            seeds: 2,
            icon: .leaf,
            kind: .replacementAction,
            note: MoriL10n.string("practice.walk_reset.note", defaultValue: "Took an offline reset"),
            domains: [.body, .rest],
            route: .quickComplete
        )
    }

    static var plantSeedChoices: [MoriPractice] {
        [
            .breatheMinute,
            .settleThree,
            .quietNote,
            .dailyCheckIn,
            .focusFifteen,
            .quietPause,
            .walkReset
        ]
    }

    static var practiceGarden: [MoriPractice] {
        [
            .breatheMinute,
            .settleThree,
            .quietNote,
            .dailyCheckIn,
            .quietPause,
            .focusFifteen,
            .walkReset
        ]
    }

    static func suggested(for domain: LifeDomain) -> MoriPractice {
        switch domain {
        case .body:
            return .walkReset
        case .mind:
            return .quietNote
        case .love:
            return .dailyCheckIn
        case .craft:
            return .focusFifteen
        case .courage:
            return .quietNote
        case .service:
            return .dailyCheckIn
        case .wonder:
            return .settleThree
        case .rest:
            return .quietPause
        }
    }

    static func suggestedSeeds(for domain: LifeDomain, limit: Int = 3) -> [MoriPractice] {
        var seeds = practiceGarden.filter { $0.domains.contains(domain) }
        let fallback = suggested(for: domain)

        if !seeds.contains(fallback) {
            seeds.insert(fallback, at: 0)
        }

        return Array(seeds.prefix(max(1, limit)))
    }

    static func domains(for action: MoriMindfulAction) -> [LifeDomain] {
        let loweredTitle = action.title.lowercased()

        if let practice = plantSeedChoices.first(where: { practice in
            loweredTitle.contains(practice.title.lowercased()) || action.note == practice.note
        }) {
            return practice.domains
        }

        switch action.kind {
        case .pulseRead:
            return [.mind]
        case .resetAction:
            return [.rest, .body]
        case .quietTimer:
            return quietPause.domains
        case .settleSession:
            return settleThree.domains
        case .breathingSession:
            return breatheMinute.domains
        case .pomodoroSession:
            return focusFifteen.domains
        case .urgeCheckIn:
            return [.rest, .mind]
        case .replacementAction:
            if loweredTitle.contains("walk") || loweredTitle.contains("offline") {
                return walkReset.domains
            }
            return [.body, .rest]
        case .dailyFocus, .dailyCheckIn:
            return dailyCheckIn.domains
        case .dailySpark:
            return [.craft, .mind]
        case .weekArchiveProof:
            return [.mind]
        case .journal:
            return quietNote.domains
        case .screenTimeLimitKept:
            return [.craft, .mind]
        case .screenTimeThresholdReached:
            return [.rest, .mind]
        }
    }
}
