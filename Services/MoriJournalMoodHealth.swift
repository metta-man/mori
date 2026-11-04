import Foundation
import HealthKit

extension MoriJournalMoodHealth {
    static let shared = MoriJournalMoodHealth.configured(arguments: ProcessInfo.processInfo.arguments) {
        MoriJournalHealthKitWriter()
    }
    static var isAvailable: Bool {
        if usesFixture(arguments: ProcessInfo.processInfo.arguments) { return true }
        if #available(iOS 18.0, *) { return HKHealthStore.isHealthDataAvailable() }
        return false
    }
}

@MainActor
private final class MoriJournalHealthKitWriter: MoriJournalMoodHealthWriting {
    private let store = HKHealthStore()
    func authorize() async throws {
        guard #available(iOS 18.0, *), HKHealthStore.isHealthDataAvailable() else {
            throw MoriJournalMoodHealthError.unavailable
        }
        let type = HKObjectType.stateOfMindType()
        // No read access requested. Authorizing alone is not proof of write permission.
        try await store.requestAuthorization(toShare: [type], read: [])
        guard store.authorizationStatus(for: type) == .sharingAuthorized else {
            throw MoriJournalMoodHealthError.denied
        }
    }
    func write(_ mood: MoriJournalMood) async throws {
        guard #available(iOS 18.0, *), HKHealthStore.isHealthDataAvailable() else {
            throw MoriJournalMoodHealthError.unavailable
        }
        // Recheck after any suspension between authorization and save.
        guard store.authorizationStatus(for: HKObjectType.stateOfMindType()) == .sharingAuthorized else {
            throw MoriJournalMoodHealthError.denied
        }
        let payload = mood.healthPayload
        let labels: [HKStateOfMind.Label]
        switch payload.labelID {
        case "calm": labels = [.calm]
        case "hopeful": labels = [.hopeful]
        case "anxious": labels = [.anxious]
        case "frustrated": labels = [.frustrated]
        case "happy": labels = [.happy]
        case "content": labels = [.content]
        case "grateful": labels = [.grateful]
        case "relieved": labels = [.relieved]
        case "sad": labels = [.sad]
        default: labels = []
        }
        let associations: [HKStateOfMind.Association] = payload.associationID == "money" ? [.money] : []
        let sample = HKStateOfMind(date: payload.recordedAt, kind: .momentaryEmotion,
            valence: payload.valence.value, labels: labels, associations: associations,
            metadata: [HKMetadataKeySyncIdentifier: payload.syncIdentifier,
                       HKMetadataKeySyncVersion: payload.version])
        // HealthKit replaces lower versions of the same sync ID; identical-version
        // retries cannot create another logical sample after a interrupted receipt.
        try await store.save(sample)
    }
}
