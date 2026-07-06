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

struct PomodoroPracticeClockTick: Equatable {
    let advancedElapsed: Bool
    let finishedPhase: Bool
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

    mutating func start(durations: PomodoroPracticeDurations) {
        reset(durations: durations)
        timerState = .running
    }

    mutating func pause() {
        timerState = .paused
    }

    mutating func resume() {
        timerState = .running
    }

    mutating func complete() {
        timerState = .completed
        phase = .completed
        secondsRemaining = 0
    }

    mutating func reset(durations: PomodoroPracticeDurations) {
        timerState = .idle
        phase = .focus
        secondsRemaining = durations.focusSeconds
        completedCycles = 0
        focusSecondsCompleted = 0
        breakSecondsCompleted = 0
    }

    mutating func tick() -> PomodoroPracticeClockTick {
        guard timerState == .running else {
            return PomodoroPracticeClockTick(advancedElapsed: false, finishedPhase: false)
        }

        var advancedElapsed = false
        if secondsRemaining > 0 {
            secondsRemaining -= 1
            advancedElapsed = phase == .focus || phase.isBreak
            if phase == .focus {
                focusSecondsCompleted += 1
            } else if phase.isBreak {
                breakSecondsCompleted += 1
            }
        }

        return PomodoroPracticeClockTick(
            advancedElapsed: advancedElapsed,
            finishedPhase: secondsRemaining == 0
        )
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
