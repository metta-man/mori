import Foundation

@MainActor
protocol MoriJournalMoodHealthWriting {
    func authorize() async throws
    func write(_ mood: MoriJournalMood) async throws
}

enum MoriJournalMoodHealthError: Error { case unavailable, denied, busy }
enum MoriJournalMoodShareResult: Equatable { case written, previouslyShared }

/// Deliberately has no launch/backfill hooks. Called only by the explicit share action.
@MainActor
final class MoriJournalMoodHealth {
    private let writer: any MoriJournalMoodHealthWriting
    private var isWriting = false
    init(writer: any MoriJournalMoodHealthWriting) { self.writer = writer }

    @discardableResult
    func share(_ mood: MoriJournalMood) async throws -> MoriJournalMoodShareResult {
        guard !isWriting else { throw MoriJournalMoodHealthError.busy }
        isWriting = true
        defer { isWriting = false }
        // Check current permission even for a cached receipt; revocation is not success.
        try await writer.authorize()
        guard mood.needsSharing else { return .previouslyShared }
        try await writer.write(mood)
        return .written
    }
}


/// Production factory never constructs a live Health store for a debug UI fixture.
extension MoriJournalMoodHealth {
    static func usesFixture(arguments: [String]) -> Bool {
        #if DEBUG
        return arguments.contains { $0.contains("ForUITest") }
        #else
        return false
        #endif
    }
    static func configured(arguments: [String], liveWriter: () -> any MoriJournalMoodHealthWriting) -> MoriJournalMoodHealth {
        if usesFixture(arguments: arguments) {
            return MoriJournalMoodHealth(writer: MoriJournalMoodFixtureWriter(
                denies: arguments.contains("-MoriMoodHealthDeniedForUITest"),
                deferred: arguments.contains("-MoriMoodHealthDeferredForUITest")))
        }
        return MoriJournalMoodHealth(writer: liveWriter())
    }
}

@MainActor
private final class MoriJournalMoodFixtureWriter: MoriJournalMoodHealthWriting {
    private let denies: Bool
    private let deferred: Bool
    private var samples: [String: Int] = [:]
    init(denies: Bool, deferred: Bool) { self.denies = denies; self.deferred = deferred }
    func authorize() async throws {
        if deferred { await MoriJournalMoodFixtureGate.shared.wait() }
        if denies { throw MoriJournalMoodHealthError.denied }
    }
    func write(_ mood: MoriJournalMood) async throws {
        samples[mood.syncIdentifier] = max(samples[mood.syncIdentifier] ?? 0, mood.version)
    }
}

/// DEBUG fixture completion is an explicit UI event, not a timing-dependent sleep.
@MainActor
final class MoriJournalMoodFixtureGate {
    static let shared = MoriJournalMoodFixtureGate()
    private var continuation: CheckedContinuation<Void, Never>?
    private var released = false
    func wait() async {
        if released { released = false; return }
        await withCheckedContinuation { continuation = $0 }
    }
    func release() {
        if let continuation {
            self.continuation = nil
            continuation.resume()
        } else { released = true }
    }
}
