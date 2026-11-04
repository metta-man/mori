import Foundation

/// One live continuous anchor per dated session. New processes start fresh;
/// nothing interprets their UUID as a boot identity or spends a handoff budget.
public final class ProtectionLiveProcessClock {
    private struct Anchor { let wall: Date; let continuous: TimeInterval; let end: Date }
    private let processID: String
    private let lock = NSLock()
    private var anchors: [String: Anchor] = [:]
    public init(processID: String = UUID().uuidString) { self.processID = processID }
    public func sample(wall: Date, continuous: TimeInterval, state: ProtectionState?) -> ProtectionClockSample {
        lock.lock(); defer { lock.unlock() }
        // Stateless capability probes must never prune or replace session anchors.
        guard let state else { return .init(wall: wall, processID: processID, continuousSeconds: continuous) }
        var windows = ProtectionEngine.activeWindows(state, at: wall)
        if let morning = state.activeFirstUseMorning, !windows.contains(where: { $0.id == morning.id }) { windows.append(morning) }
        let retired = state.clockLedger?.retiredWindowIDs ?? []
        windows = windows.filter { !retired.contains($0.id) && $0.start.timeIntervalSince1970.isFinite && $0.end.timeIntervalSince1970.isFinite && $0.end > $0.start }
        let liveIDs = Set(windows.map(\.id))
        anchors = anchors.filter { liveIDs.contains($0.key) }
        var projected: Date?
        for window in windows {
            if let anchor = anchors[window.id], anchor.end == window.end, continuous >= anchor.continuous {
                let candidate = anchor.wall.addingTimeInterval(continuous - anchor.continuous)
                projected = projected.map { max($0, candidate) } ?? candidate
            } else {
                // Only PRE-EXISTING live anchors constitute elapsed evidence.
                // Do not hide a bad handoff date by anchoring it to persisted time.
                anchors[window.id] = .init(wall: wall, continuous: continuous, end: window.end)
            }
        }
        return .init(wall: wall, processID: processID, continuousSeconds: continuous, projectedNow: projected)
    }
}
