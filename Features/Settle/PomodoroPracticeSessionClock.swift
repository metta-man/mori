import Foundation

struct PomodoroPracticeDurations: Equatable {
    let focusMinutes: Int
    let shortBreakMinutes: Int
    let longBreakMinutes: Int
    let cycles: Int

    var focusSeconds: Int { focusMinutes * 60 }
    var shortBreakSeconds: Int { shortBreakMinutes * 60 }
    var longBreakSeconds: Int { longBreakMinutes * 60 }
}

enum PomodoroPracticePhaseTransition: Equatable {
    case none
    case completed
    case focusStarted
    case breakStarted(MoriPomodoroPhase)
}

struct PomodoroPracticeSessionClock: Equatable {
    private(set) var timerState: SettleTimerState = .idle
    private(set) var phase: MoriPomodoroPhase = .focus
    private(set) var secondsRemaining: Int
    private(set) var completedCycles = 0
    private(set) var focusSecondsCompleted = 0
    private(set) var breakSecondsCompleted = 0
    private var lastAccountedAt: Date?
    private var fractionalElapsed: TimeInterval = 0

    init(focusMinutes: Int = 25) {
        secondsRemaining = focusMinutes * 60
    }

    var canChangeDuration: Bool {
        timerState.canChangeDuration
    }

    mutating func selectSetupPhase(
        _ selectedPhase: MoriPomodoroPhase,
        durations: PomodoroPracticeDurations
    ) -> Bool {
        guard canChangeDuration else { return false }
        phase = selectedPhase
        secondsRemaining = selectedPhase.durationSeconds(
            focusMinutes: durations.focusMinutes,
            shortBreakMinutes: durations.shortBreakMinutes,
            longBreakMinutes: durations.longBreakMinutes
        )
        return true
    }

    mutating func start(durations: PomodoroPracticeDurations, now: Date = Date()) {
        reset(durations: durations)
        timerState = .running
        lastAccountedAt = now
    }

    mutating func pause() {
        guard timerState == .running else { return }
        timerState = .paused
        lastAccountedAt = nil
    }

    mutating func resume(now: Date = Date()) {
        guard timerState == .paused else { return }
        timerState = .running
        lastAccountedAt = now
    }

    mutating func complete() {
        timerState = .completed
        phase = .completed
        secondsRemaining = 0
        lastAccountedAt = nil
        fractionalElapsed = 0
    }

    mutating func reset(durations: PomodoroPracticeDurations) {
        timerState = .idle
        phase = .focus
        secondsRemaining = durations.focusSeconds
        completedCycles = 0
        focusSecondsCompleted = 0
        breakSecondsCompleted = 0
        lastAccountedAt = nil
        fractionalElapsed = 0
    }

    /// Foreground ticks only refresh the display. A missing tick (lock screen,
    /// background suspension) does not remove elapsed time from the session.
    mutating func update(to now: Date, durations: PomodoroPracticeDurations) -> PomodoroPracticePhaseTransition {
        guard timerState == .running, let anchor = lastAccountedAt, now >= anchor else { return .none }
        let elapsed = now.timeIntervalSince(anchor) + fractionalElapsed
        guard elapsed.isFinite else { return .none }
        // Bound catch-up by the configured session, avoiding Int overflow for a bad date.
        let maximum = Double(max(1, durations.cycles)) * Double(max(1, durations.focusSeconds) + max(1, durations.shortBreakSeconds) + max(1, durations.longBreakSeconds))
        var seconds = Int(min(floor(elapsed), maximum))
        fractionalElapsed = elapsed - floor(elapsed)
        lastAccountedAt = now
        var transition: PomodoroPracticePhaseTransition = .none
        while seconds > 0 && timerState == .running {
            let consumed = min(seconds, max(0, secondsRemaining))
            secondsRemaining -= consumed
            seconds -= consumed
            if phase == .focus { focusSecondsCompleted += consumed }
            else if phase.isBreak { breakSecondsCompleted += consumed }
            if secondsRemaining == 0 {
                transition = advancePhase(durations: durations)
                if transition == .completed { complete() }
            }
        }
        return transition
    }

    mutating func advancePhase(durations: PomodoroPracticeDurations) -> PomodoroPracticePhaseTransition {
        switch phase {
        case .focus:
            completedCycles += 1
            if completedCycles >= durations.cycles {
                phase = .completed
                secondsRemaining = 0
                return .completed
            }

            if completedCycles.isMultiple(of: 4) {
                phase = .longBreak
                secondsRemaining = durations.longBreakSeconds
                return .breakStarted(.longBreak)
            }

            phase = .shortBreak
            secondsRemaining = durations.shortBreakSeconds
            return .breakStarted(.shortBreak)

        case .shortBreak, .longBreak:
            phase = .focus
            secondsRemaining = durations.focusSeconds
            return .focusStarted

        case .completed:
            return .completed
        }
    }
}
