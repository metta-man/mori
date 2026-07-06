import SwiftUI
import WatchKit

final class MoriWatchSessionModel: ObservableObject {
    @Published var state: MoriWatchSessionState = .idle
    @Published var secondsRemaining = 60
    @Published var totalSeconds = 60
    @Published var headerTitle = MoriL10n.string("practice.breathe.title", defaultValue: "Breathe")
    @Published var headerSubtitle = MoriL10n.string("time.minute_compact_one", defaultValue: "1 min")
    @Published var phaseText = MoriL10n.string("watch.session.ready", defaultValue: "Ready")
    @Published var cycleText = ""
    @Published var activeTint = MoriWatchPalette.moss

    private var timer: Timer?
    private let runtimeSessionController = MoriWatchRuntimeSessionController()
    private var practice: MoriWatchPractice = .breathe
    private var breathPreset: MoriWatchBreathPreset = .coherent5
    private var breathingMinutes = 1
    private var settleMinutes = 3
    private var pomodoroFocusMinutes = 25
    private var pomodoroCycles = 2
    private var pomodoroBreakPreset: MoriWatchBreathPreset = .longExhale
    private var pomodoroCompletedCycles = 0
    private var pomodoroPhase: MoriWatchPomodoroPhase = .focus
    private var lastBreathPhaseIndex: Int?
    private var lastPomodoroBreakBreathPhaseIndex: Int?
    private var phaseEndDate: Date?

    var progress: CGFloat {
        guard totalSeconds > 0 else { return 0 }
        return CGFloat(totalSeconds - secondsRemaining) / CGFloat(totalSeconds)
    }

    var timeText: String {
        Self.formatTime(secondsRemaining)
    }

    deinit {
        timer?.invalidate()
        runtimeSessionController.end()
    }

    func configure(
        practice: MoriWatchPractice,
        breathPreset: MoriWatchBreathPreset,
        breathingMinutes: Int,
        settleMinutes: Int,
        pomodoroFocusMinutes: Int,
        pomodoroCycles: Int,
        pomodoroBreakPreset: MoriWatchBreathPreset
    ) {
        self.practice = practice
        self.breathPreset = breathPreset
        self.breathingMinutes = breathingMinutes
        self.settleMinutes = settleMinutes
        self.pomodoroFocusMinutes = pomodoroFocusMinutes
        self.pomodoroCycles = pomodoroCycles
        self.pomodoroBreakPreset = pomodoroBreakPreset
        self.pomodoroCompletedCycles = 0
        self.pomodoroPhase = .focus
        self.lastBreathPhaseIndex = nil
        self.lastPomodoroBreakBreathPhaseIndex = nil
        self.phaseEndDate = nil
        runtimeSessionController.end()
        state = .idle

        switch practice {
        case .breathe:
            totalSeconds = max(1, breathingMinutes * 60)
            secondsRemaining = totalSeconds
            headerTitle = breathPreset.title
            headerSubtitle = MoriL10n.string("time.minute_compact_many", defaultValue: "%d min", arguments: [breathingMinutes])
            phaseText = MoriL10n.string("watch.session.ready", defaultValue: "Ready")
            cycleText = ""
            activeTint = practice.tint

        case .settle:
            totalSeconds = max(1, settleMinutes * 60)
            secondsRemaining = totalSeconds
            headerTitle = MoriL10n.string("watch.settle_timer", defaultValue: "Settle Timer")
            headerSubtitle = MoriL10n.string("time.minute_compact_many", defaultValue: "%d min", arguments: [settleMinutes])
            phaseText = MoriL10n.string("watch.session.ready", defaultValue: "Ready")
            cycleText = ""
            activeTint = practice.tint

        case .pomodoro:
            totalSeconds = max(1, pomodoroFocusMinutes * 60)
            secondsRemaining = totalSeconds
            headerTitle = MoriL10n.string("Focus Cycle", defaultValue: "Focus Cycle")
            headerSubtitle = MoriL10n.string("watch.cycles.count", defaultValue: "%d cycles", arguments: [pomodoroCycles])
            phaseText = pomodoroPhase.title
            cycleText = MoriL10n.string("watch.cycle.count", defaultValue: "Cycle %d of %d", arguments: [1, pomodoroCycles])
            activeTint = pomodoroPhase.tint

        case .bell:
            break
        }
    }

    func start() {
        guard state == .idle || state == .completed else { return }

        if state == .completed {
            configure(
                practice: practice,
                breathPreset: breathPreset,
                breathingMinutes: breathingMinutes,
                settleMinutes: settleMinutes,
                pomodoroFocusMinutes: pomodoroFocusMinutes,
                pomodoroCycles: pomodoroCycles,
                pomodoroBreakPreset: pomodoroBreakPreset
            )
        }

        state = .running
        phaseEndDate = Date().addingTimeInterval(TimeInterval(secondsRemaining))
        runtimeSessionController.start()
        playStartHaptic()
        updateDynamicPhase(force: true)
        startTimer()
    }

    func pause() {
        guard state == .running else { return }
        syncRemainingWithClock()
        state = .paused
        phaseEndDate = nil
        timer?.invalidate()
        runtimeSessionController.end()
        WKInterfaceDevice.current().play(.click)
    }

    func resume() {
        guard state == .paused else { return }
        state = .running
        phaseEndDate = Date().addingTimeInterval(TimeInterval(secondsRemaining))
        runtimeSessionController.start()
        WKInterfaceDevice.current().play(.start)
        updateDynamicPhase(force: true)
        startTimer()
    }

    func stop(reset: Bool) {
        guard state == .running || state == .paused || !reset else {
            return
        }

        syncRemainingWithClock()
        timer?.invalidate()
        timer = nil
        phaseEndDate = nil
        runtimeSessionController.end()

        if reset {
            WKInterfaceDevice.current().play(.stop)
            configure(
                practice: practice,
                breathPreset: breathPreset,
                breathingMinutes: breathingMinutes,
                settleMinutes: settleMinutes,
                pomodoroFocusMinutes: pomodoroFocusMinutes,
                pomodoroCycles: pomodoroCycles,
                pomodoroBreakPreset: pomodoroBreakPreset
            )
        }
    }

    func stopForViewDismissal(scenePhase: ScenePhase) {
        guard scenePhase == .active else { return }
        stop(reset: false)
    }

    func handleScenePhaseChange(_ scenePhase: ScenePhase) {
        guard scenePhase == .active, state == .running else { return }

        syncRemainingWithClock()
        if secondsRemaining <= 0 {
            completeCurrentPhase()
        } else {
            runtimeSessionController.start()
            updateDynamicPhase(force: false)
            startTimer()
        }
    }

    private func startTimer() {
        timer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        self.timer = timer
        RunLoop.current.add(timer, forMode: .common)
    }

    private func tick() {
        guard state == .running else { return }

        syncRemainingWithClock()
        if secondsRemaining > 0 {
            updateDynamicPhase(force: false)
        }

        if secondsRemaining <= 0 {
            completeCurrentPhase()
        }
    }

    private func completeCurrentPhase() {
        switch practice {
        case .breathe, .settle:
            completeSession()

        case .pomodoro:
            advancePomodoro()

        case .bell:
            break
        }
    }

    private func completeSession() {
        timer?.invalidate()
        timer = nil
        phaseEndDate = nil
        runtimeSessionController.end()
        state = .completed
        secondsRemaining = 0
        phaseText = MoriL10n.string("Complete", defaultValue: "Complete")
        cycleText = ""
        WKInterfaceDevice.current().play(.success)
    }

    private func advancePomodoro() {
        timer?.invalidate()
        timer = nil

        switch pomodoroPhase {
        case .focus:
            pomodoroCompletedCycles += 1
            if pomodoroCompletedCycles >= pomodoroCycles {
                completeSession()
                return
            }

            pomodoroPhase = pomodoroCompletedCycles.isMultiple(of: 4) ? .longBreak : .shortBreak
            totalSeconds = pomodoroPhase.durationSeconds(focusMinutes: pomodoroFocusMinutes)
            secondsRemaining = totalSeconds
            phaseText = pomodoroPhase.title
            activeTint = pomodoroPhase.tint
            cycleText = MoriL10n.string("watch.cycle.count", defaultValue: "Cycle %d of %d", arguments: [min(pomodoroCompletedCycles + 1, pomodoroCycles), pomodoroCycles])
            lastPomodoroBreakBreathPhaseIndex = nil
            phaseEndDate = Date().addingTimeInterval(TimeInterval(secondsRemaining))
            runtimeSessionController.start()
            WKInterfaceDevice.current().play(.notification)
            startTimer()

        case .shortBreak, .longBreak:
            pomodoroPhase = .focus
            totalSeconds = pomodoroPhase.durationSeconds(focusMinutes: pomodoroFocusMinutes)
            secondsRemaining = totalSeconds
            phaseText = pomodoroPhase.title
            activeTint = pomodoroPhase.tint
            cycleText = MoriL10n.string("watch.cycle.count", defaultValue: "Cycle %d of %d", arguments: [min(pomodoroCompletedCycles + 1, pomodoroCycles), pomodoroCycles])
            lastPomodoroBreakBreathPhaseIndex = nil
            phaseEndDate = Date().addingTimeInterval(TimeInterval(secondsRemaining))
            runtimeSessionController.start()
            WKInterfaceDevice.current().play(.start)
            startTimer()
        }
    }

    private func syncRemainingWithClock(now: Date = Date()) {
        guard let phaseEndDate else { return }
        secondsRemaining = max(0, Int(ceil(phaseEndDate.timeIntervalSince(now))))
    }

    private func updateDynamicPhase(force: Bool) {
        switch practice {
        case .breathe:
            updateBreathingPhase(force: force)
        case .pomodoro:
            if pomodoroPhase == .focus {
                phaseText = pomodoroPhase.title
                cycleText = MoriL10n.string("watch.cycle.count", defaultValue: "Cycle %d of %d", arguments: [min(pomodoroCompletedCycles + 1, pomodoroCycles), pomodoroCycles])
            } else {
                updatePomodoroBreakBreathingPhase(force: force)
            }
        case .settle:
            phaseText = state == .paused ? MoriL10n.string("watch.session.paused", defaultValue: "Paused") : MoriL10n.string("practice.settle.title", defaultValue: "Settle")
        case .bell:
            break
        }
    }

    private func updateBreathingPhase(force: Bool) {
        let elapsed = max(0, totalSeconds - secondsRemaining)
        let segments = breathPreset.segments
        guard !segments.isEmpty else { return }

        let cycleDuration = max(1, breathPreset.cycleDuration)
        let totalCycles = max(1, Int((Double(totalSeconds) / cycleDuration).rounded(.up)))
        let cycleIndex = min(totalCycles, Int(Double(elapsed) / cycleDuration) + 1)
        let offset = Double(elapsed).truncatingRemainder(dividingBy: cycleDuration)

        var cursor: Double = 0
        var activeIndex = 0
        for index in segments.indices {
            cursor += segments[index].duration
            if offset < cursor {
                activeIndex = index
                break
            }
        }

        let segment = segments[activeIndex]
        phaseText = segment.label
        cycleText = MoriL10n.string("watch.cycle.count", defaultValue: "Cycle %d of %d", arguments: [cycleIndex, totalCycles])

        guard force || activeIndex != lastBreathPhaseIndex else { return }
        lastBreathPhaseIndex = activeIndex

        switch segment.kind {
        case .inhale:
            WKInterfaceDevice.current().play(.directionUp)
        case .hold:
            WKInterfaceDevice.current().play(.click)
        case .exhale:
            WKInterfaceDevice.current().play(.directionDown)
        }
    }

    private func updatePomodoroBreakBreathingPhase(force: Bool) {
        let elapsed = max(0, totalSeconds - secondsRemaining)
        let segments = pomodoroBreakPreset.segments
        guard !segments.isEmpty else { return }

        let cycleDuration = max(1, pomodoroBreakPreset.cycleDuration)
        let offset = Double(elapsed).truncatingRemainder(dividingBy: cycleDuration)

        var cursor: Double = 0
        var activeIndex = 0
        for index in segments.indices {
            cursor += segments[index].duration
            if offset < cursor {
                activeIndex = index
                break
            }
        }

        let segment = segments[activeIndex]
        phaseText = segment.label
        cycleText = MoriL10n.string(
            "watch.pomodoro_break_cycle",
            defaultValue: "%@ · Cycle %d of %d",
            arguments: [pomodoroPhase.title, min(pomodoroCompletedCycles + 1, pomodoroCycles), pomodoroCycles]
        )

        guard force || activeIndex != lastPomodoroBreakBreathPhaseIndex else { return }
        lastPomodoroBreakBreathPhaseIndex = activeIndex

        switch segment.kind {
        case .inhale:
            WKInterfaceDevice.current().play(.directionUp)
        case .hold:
            WKInterfaceDevice.current().play(.click)
        case .exhale:
            WKInterfaceDevice.current().play(.directionDown)
        }
    }

    private func playStartHaptic() {
        switch practice {
        case .breathe:
            WKInterfaceDevice.current().play(.directionUp)
        case .settle, .pomodoro:
            WKInterfaceDevice.current().play(.start)
        case .bell:
            WKInterfaceDevice.current().play(.notification)
        }
    }

    private static func formatTime(_ seconds: Int) -> String {
        let safeSeconds = max(0, seconds)
        let minutes = safeSeconds / 60
        let remainder = safeSeconds % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }
}

private final class MoriWatchRuntimeSessionController: NSObject, WKExtendedRuntimeSessionDelegate {
    private var session: WKExtendedRuntimeSession?

    func start() {
        if let session, session.state == .running || session.state == .scheduled {
            return
        }

        let session = WKExtendedRuntimeSession()
        session.delegate = self
        self.session = session
        session.start()
    }

    func end() {
        guard let session else { return }

        if session.state == .running || session.state == .scheduled {
            session.invalidate()
        }

        self.session = nil
    }

    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}

    func extendedRuntimeSession(
        _ extendedRuntimeSession: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: Error?
    ) {
        guard session === extendedRuntimeSession else { return }
        session = nil
    }
}
