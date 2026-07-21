import SwiftUI

struct MoriWatchBellScheduleSettings {
    let randomMode: Bool
    let intervalMinutes: Int
    let bellsPerHour: Int
    let startHour: Int
    let endHour: Int
    let randomSeed: UInt64

    init(defaults: UserDefaults) {
        randomMode = defaults.bool(forKey: MoriWatchBellDefaults.randomModeKey)
        intervalMinutes = defaults.integer(forKey: MoriWatchBellDefaults.intervalMinutesKey) == 0
            ? 15
            : defaults.integer(forKey: MoriWatchBellDefaults.intervalMinutesKey)
        bellsPerHour = max(1, defaults.integer(forKey: MoriWatchBellDefaults.bellsPerHourKey))
        startHour = defaults.object(forKey: MoriWatchBellDefaults.startHourKey) == nil
            ? 9
            : defaults.integer(forKey: MoriWatchBellDefaults.startHourKey)
        endHour = defaults.object(forKey: MoriWatchBellDefaults.endHourKey) == nil
            ? 21
            : defaults.integer(forKey: MoriWatchBellDefaults.endHourKey)

        if let storedSeed = defaults.object(forKey: MoriWatchBellDefaults.randomSeedKey) as? NSNumber {
            randomSeed = storedSeed.uint64Value
        } else {
            randomSeed = UInt64(Date().timeIntervalSince1970)
            defaults.set(NSNumber(value: randomSeed), forKey: MoriWatchBellDefaults.randomSeedKey)
        }
    }
}

enum MoriWatchBellDefaults {
    static let categoryIdentifier = "MINDFUL_INTERVAL"
    static let identifierPrefix = "mori-watch-mindfulness-bell-"
    static let isActiveKey = "mori_watch_bell_is_active"
    static let randomModeKey = "mori_watch_bell_random_mode"
    static let intervalMinutesKey = "mori_watch_bell_interval_minutes"
    static let bellsPerHourKey = "mori_watch_bell_bells_per_hour"
    static let startHourKey = "mori_watch_bell_start_hour"
    static let endHourKey = "mori_watch_bell_end_hour"
    static let nextFireKey = "mori_watch_bell_next_fire"
    static let randomSeedKey = "mori_watch_bell_random_seed"
}

enum MoriWatchBellMessage {
    private static let messages = [
        (
            titleKey: "watch.bell.message.mindfulness.title",
            title: "Mindfulness Bell",
            bodyKey: "watch.bell.message.mindfulness.body",
            body: "Pause. Take one full breath before the next thing."
        ),
        (
            titleKey: "watch.bell.message.now.title",
            title: "A bell for now",
            bodyKey: "watch.bell.message.now.body",
            body: "Let the wrist tap be enough. Breathe in, breathe out."
        ),
        (
            titleKey: "watch.bell.message.return.title",
            title: "Return to the day",
            bodyKey: "watch.bell.message.return.body",
            body: "Soften your shoulders and come back to this moment."
        ),
        (
            titleKey: "watch.bell.message.small_pause.title",
            title: "Small pause",
            bodyKey: "watch.bell.message.small_pause.body",
            body: "One breath. One clear next step."
        )
    ]

    static func next(identifier: String) -> (title: String, body: String) {
        let index = abs(identifier.hashValue) % messages.count
        let message = messages[index]
        return (
            MoriL10n.string(message.titleKey, defaultValue: message.title),
            MoriL10n.string(message.bodyKey, defaultValue: message.body)
        )
    }
}

enum MoriWatchPractice: String, CaseIterable, Identifiable {
    case breathe
    case settle
    case pomodoro
    case bell

    var id: String { rawValue }

    static var launchTiles: [MoriWatchPractice] {
        [.breathe, .settle, .pomodoro, .bell]
    }

    var title: String {
        switch self {
        case .breathe: return MoriL10n.string("practice.breathe.title", defaultValue: "Breathe")
        case .settle: return MoriL10n.string("practice.settle.title", defaultValue: "Settle")
        case .pomodoro: return MoriL10n.string("practice.pomodoro.title", defaultValue: "Deep Session")
        case .bell: return MoriL10n.string("watch.practice.bell", defaultValue: "Bell")
        }
    }

    var shortDuration: String {
        switch self {
        case .breathe: return MoriL10n.string("time.minute_compact_one", defaultValue: "1 min")
        case .settle: return MoriL10n.string("time.minute_compact_many", defaultValue: "%d min", arguments: [3])
        case .pomodoro: return MoriL10n.string("time.minute_compact_many", defaultValue: "%d min", arguments: [25])
        case .bell: return MoriL10n.string("Reminders", defaultValue: "Reminders")
        }
    }

    var symbolName: String {
        switch self {
        case .breathe: return "wind"
        case .settle: return "figure.mind.and.body"
        case .pomodoro: return "timer"
        case .bell: return "bell.and.waves.left.and.right"
        }
    }

    var tint: Color {
        switch self {
        case .breathe: return MoriWatchPalette.mist
        case .settle: return MoriWatchPalette.moss
        case .pomodoro: return MoriWatchPalette.clay
        case .bell: return MoriWatchPalette.seed
        }
    }

    var bitmapIcon: MoriBitmapIcon {
        switch self {
        case .breathe: return .breathe
        case .settle: return .leaf
        case .pomodoro: return .focus
        case .bell: return .bell
        }
    }
}

enum MoriWatchSessionState: Equatable {
    case idle
    case running
    case paused
    case completed

    var isIdle: Bool {
        self == .idle || self == .completed
    }

    var label: String {
        switch self {
        case .idle: return MoriL10n.string("watch.session.ready", defaultValue: "Ready")
        case .running: return MoriL10n.string("watch.session.running", defaultValue: "Running")
        case .paused: return MoriL10n.string("watch.session.paused", defaultValue: "Paused")
        case .completed: return MoriL10n.string("Complete", defaultValue: "Complete")
        }
    }
}

enum MoriWatchPomodoroPhase {
    case focus
    case shortBreak
    case longBreak

    var title: String {
        switch self {
        case .focus: return MoriL10n.string("pomodoro.phase.focus", defaultValue: "Focus")
        case .shortBreak: return MoriL10n.string("pomodoro.phase.short_break", defaultValue: "Short Break")
        case .longBreak: return MoriL10n.string("pomodoro.phase.long_break", defaultValue: "Long Break")
        }
    }

    var tint: Color {
        switch self {
        case .focus: return MoriWatchPalette.clay
        case .shortBreak: return MoriWatchPalette.moss
        case .longBreak: return MoriWatchPalette.mist
        }
    }

    func durationSeconds(focusMinutes: Int) -> Int {
        switch self {
        case .focus: return focusMinutes * 60
        case .shortBreak: return 5 * 60
        case .longBreak: return 15 * 60
        }
    }
}

enum MoriWatchBreathPreset: String, CaseIterable, Identifiable {
    case longExhale
    case nadiShodhana
    case coherent5
    case coherent55
    case coherent6
    case coherent4
    case coherent3
    case box4
    case box6
    case box8
    case box10
    case relaxing478

    var id: String { rawValue }

    var title: String {
        switch self {
        case .longExhale: return MoriL10n.string("breath.long_exhale", defaultValue: "Long Exhale")
        case .nadiShodhana: return MoriL10n.string("breath.nadi_shodhana", defaultValue: "Nadi Shodhana")
        case .coherent5: return "Coherent 5-5"
        case .coherent55: return "Coherent 5.5"
        case .coherent6: return "Coherent 6-6"
        case .coherent4: return "Coherent 7.5"
        case .coherent3: return "Coherent 10"
        case .box4: return "Box 4-4-4-4"
        case .box6: return "Box 6-6-6-6"
        case .box8: return "Box 8-8-8-8"
        case .box10: return "Box 10"
        case .relaxing478: return "4-7-8"
        }
    }

    var shortTitle: String {
        switch self {
        case .longExhale: return "4-6"
        case .nadiShodhana: return "Nadi"
        case .coherent5: return "5-5"
        case .coherent55: return "5.5"
        case .coherent6: return "6-6"
        case .coherent4: return "7.5"
        case .coherent3: return "10-10"
        case .box4: return "Box"
        case .box6: return "Box 6"
        case .box8: return "Box 8"
        case .box10: return "Box 10"
        case .relaxing478: return "4-7-8"
        }
    }

    var patternText: String {
        switch self {
        case .longExhale, .nadiShodhana: return "4 in · 6 out"
        case .coherent5: return "5 in · 5 out"
        case .coherent55: return "5.5 · 5.5"
        case .coherent6: return "6 in · 6 out"
        case .coherent4: return "7.5 · 7.5"
        case .coherent3: return "10 in · 10 out"
        case .box4: return "4 each"
        case .box6: return "6 each"
        case .box8: return "8 each"
        case .box10: return "10 each"
        case .relaxing478: return "4 · 7 · 8"
        }
    }

    var inhale: Double {
        switch self {
        case .longExhale, .nadiShodhana, .box4, .relaxing478:
            return 4
        case .coherent5: return 5
        case .coherent55: return 5.5
        case .coherent6: return 6
        case .coherent4: return 7.5
        case .coherent3, .box10: return 10
        case .box6: return 6
        case .box8: return 8
        }
    }

    var holdAfterInhale: Double {
        switch self {
        case .longExhale, .nadiShodhana, .coherent5, .coherent55, .coherent6, .coherent4, .coherent3:
            return 0
        case .box4: return 4
        case .box6: return 6
        case .box8: return 8
        case .box10: return 10
        case .relaxing478: return 7
        }
    }

    var exhale: Double {
        switch self {
        case .longExhale, .nadiShodhana, .coherent6, .box6:
            return 6
        case .coherent5: return 5
        case .coherent55: return 5.5
        case .coherent4: return 7.5
        case .coherent3, .box10: return 10
        case .box4: return 4
        case .box8, .relaxing478: return 8
        }
    }

    var holdAfterExhale: Double {
        switch self {
        case .longExhale, .nadiShodhana, .coherent5, .coherent55, .coherent6, .coherent4, .coherent3, .relaxing478:
            return 0
        case .box4: return 4
        case .box6: return 6
        case .box8: return 8
        case .box10: return 10
        }
    }

    var cycleDuration: Double {
        inhale + holdAfterInhale + exhale + holdAfterExhale
    }

    var segments: [MoriWatchBreathSegment] {
        var result: [MoriWatchBreathSegment] = [
            .init(label: MoriL10n.string("breath.phase.in", defaultValue: "Breathe In"), duration: inhale, kind: .inhale)
        ]

        if holdAfterInhale > 0 {
            result.append(.init(label: MoriL10n.string("breath.phase.hold", defaultValue: "Hold"), duration: holdAfterInhale, kind: .hold))
        }

        result.append(.init(label: MoriL10n.string("breath.phase.out", defaultValue: "Breathe Out"), duration: exhale, kind: .exhale))

        if holdAfterExhale > 0 {
            result.append(.init(label: MoriL10n.string("breath.phase.hold", defaultValue: "Hold"), duration: holdAfterExhale, kind: .hold))
        }

        return result
    }
}

struct MoriWatchBreathSegment {
    let label: String
    let duration: Double
    let kind: MoriWatchBreathKind
}

enum MoriWatchBreathKind {
    case inhale
    case hold
    case exhale
}

struct MoriWatchIconButtonStyle: ButtonStyle {
    var tint: Color = MoriWatchPalette.surface

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(MoriWatchPalette.ink)
            .background(tint.opacity(configuration.isPressed ? 0.58 : 0.92))
            .clipShape(Circle())
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

struct MoriWatchPrimaryButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(MoriWatchPalette.background)
            .padding(.vertical, 10)
            .background(tint.opacity(configuration.isPressed ? 0.58 : 0.84))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct MoriWatchSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(MoriWatchPalette.ink)
            .padding(.vertical, 10)
            .background(MoriWatchPalette.surface.opacity(configuration.isPressed ? 0.58 : 0.86))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct MoriWatchPaperBackground: View {
    var body: some View {
        ZStack {
            MoriWatchPalette.background

            MoriGeneratedArtImage(art: .paperWash, contentMode: .fill)
                .opacity(0.28)
                .blendMode(.multiply)

            MoriGeneratedArtImage(art: .botanicalScreenWash, contentMode: .fill)
                .opacity(0.06)
                .blendMode(.multiply)
                .scaleEffect(1.12)
                .offset(x: 32, y: -24)

            LinearGradient(
                colors: [
                    MoriWatchPalette.background.opacity(0.24),
                    MoriWatchPalette.background.opacity(0.64)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct MoriWatchCardBackground: View {
    var cornerRadius: CGFloat = 16

    var body: some View {
        MoriPlainWatercolorCardBackground(
            cornerRadius: cornerRadius,
            fill: MoriWatchPalette.surface.opacity(0.92),
            paperOpacity: 0.05,
            edgeOpacity: 0.03
        )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(MoriWatchPalette.line.opacity(0.56), lineWidth: 0.8)
            }
    }
}

extension View {
    func moriWatchPaperBackground() -> some View {
        background(MoriWatchPaperBackground())
    }

    func moriWatchCard(cornerRadius: CGFloat = 16) -> some View {
        background(MoriWatchCardBackground(cornerRadius: cornerRadius))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

enum MoriWatchPalette {
    static let background = Color(red: 0.961, green: 0.966, blue: 0.946)
    static let surface = Color(red: 0.988, green: 0.986, blue: 0.966)
    static let line = Color(red: 0.76, green: 0.80, blue: 0.73)
    static let ink = Color(red: 0.078, green: 0.224, blue: 0.184)
    static let muted = Color(red: 0.36, green: 0.42, blue: 0.38)
    static let moss = Color(red: 0.38, green: 0.50, blue: 0.40)
    static let seed = Color(red: 0.58, green: 0.49, blue: 0.30)
    static let mist = Color(red: 0.36, green: 0.51, blue: 0.54)
    static let clay = Color(red: 0.52, green: 0.38, blue: 0.32)
}
