import Combine
import CoreGraphics
import Foundation

enum MoriBreathingRunState {
    case idle
    case running
    case paused
    case completed

    var isActive: Bool {
        self == .running || self == .paused
    }
}

final class MoriBreathingSessionClock: ObservableObject {
    enum SyncResult {
        case inactive
        case unchanged
        case phaseChanged
        case completed
    }

    @Published var durationMinutes: Int
    @Published private(set) var runState: MoriBreathingRunState = .idle
    @Published private(set) var activeElapsed: TimeInterval = 0
    @Published private(set) var currentPhaseIndex = 0
    @Published private(set) var completedBreathCount = 0

    private var sessionStartDate: Date?
    private var pausedAt: Date?
    private var totalPausedDuration: TimeInterval = 0

    init(durationMinutes: Int) {
        self.durationMinutes = durationMinutes
    }

    var sessionDuration: TimeInterval {
        TimeInterval(max(1, durationMinutes) * 60)
    }

    var secondsRemaining: Int {
        max(0, Int(ceil(sessionDuration - activeElapsed)))
    }

    var progress: CGFloat {
        CGFloat(min(1, max(0, activeElapsed / max(1, sessionDuration))))
    }

    func phaseRemaining(for segments: [MoriBreathingCycleSegment]) -> TimeInterval {
        MoriBreathingCycle.phaseRemaining(for: segments, elapsedTime: activeElapsed)
    }

    func start(now: Date = Date()) {
        runState = .running
        activeElapsed = 0
        currentPhaseIndex = 0
        sessionStartDate = now
        pausedAt = nil
        totalPausedDuration = 0
        completedBreathCount = 0
    }

    func pause(now: Date = Date()) -> Bool {
        guard runState == .running else { return false }
        runState = .paused
        pausedAt = now
        return true
    }

    func resume(now: Date = Date()) -> Bool {
        guard runState == .paused else { return false }
        if let pausedAt {
            totalPausedDuration += now.timeIntervalSince(pausedAt)
        }
        pausedAt = nil
        runState = .running
        return true
    }

    func sync(now: Date = Date(), segments: [MoriBreathingCycleSegment]) -> SyncResult {
        guard runState == .running, let sessionStartDate else { return .inactive }

        let elapsed = max(0, now.timeIntervalSince(sessionStartDate) - totalPausedDuration)
        let previousPhaseIndex = currentPhaseIndex
        activeElapsed = min(sessionDuration, elapsed)

        if activeElapsed >= sessionDuration {
            return .completed
        }

        currentPhaseIndex = MoriBreathingCycle.phaseIndex(for: segments, elapsedTime: activeElapsed)

        guard currentPhaseIndex != previousPhaseIndex else { return .unchanged }
        if currentPhaseIndex == 0 {
            completedBreathCount += 1
        }
        return .phaseChanged
    }

    func complete() {
        guard runState == .running else { return }
        runState = .completed
        activeElapsed = sessionDuration
    }

    func reset() {
        runState = .idle
        activeElapsed = 0
        currentPhaseIndex = 0
        sessionStartDate = nil
        pausedAt = nil
        totalPausedDuration = 0
        completedBreathCount = 0
    }
}
