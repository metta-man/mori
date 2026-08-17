import Foundation
import UserNotifications

enum MoriDataCategory: String, CaseIterable, Identifiable {
    case logsAndPhotos
    case iCloudBackup
    case lifeGridAndCheckIns
    case recoveryHistory
    case focusAndReminders
    case analytics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .logsAndPhotos: "Logs & Photos"
        case .iCloudBackup: "iCloud Backup"
        case .lifeGridAndCheckIns: "Life Grid & Check-ins"
        case .recoveryHistory: "Recovery History"
        case .focusAndReminders: "App Limits, Focus & Reminders"
        case .analytics: "Analytics Data"
        }
    }
}

enum MoriDataDeletionError: LocalizedError {
    case cloudDeletionFailed
    var errorDescription: String? { "Local data was removed, but the iCloud backup could not be deleted. Check your connection and try again." }
}

@MainActor
final class MoriDataDeletionService {
    static let shared = MoriDataDeletionService()

    func delete(_ category: MoriDataCategory) async throws {
        switch category {
        case .logsAndPhotos:
            GratitudeEntryStore.live.deleteLocalEntries()
            GratitudeDraftStore().clear()
            try GratitudePhotoStore.deleteAllPhotos()
        case .iCloudBackup:
            GratitudeEntryStore.live.deleteICloudMirror()
            do { try await GratitudeCloudBackup.shared.delete() }
            catch { throw MoriDataDeletionError.cloudDeletionFailed }
        case .lifeGridAndCheckIns:
            HabitDataManager.shared.clearAllEntries()
            try WeekArchiveRecordStore.shared.deleteAllRecords()
            clearStandardDefaults(matching: ["daily", "spark", "clarity", "weekArchive"])
        case .recoveryHistory:
            MoriRecoveryHistoryPersistence().clear()
            MoriRecoveryTagOverrideStore().clear()
            clearStandardDefaults(matching: ["mori_recovery", "mori_factor"])
            MoriAppGroup.defaults.removeObject(forKey: MoriWidgetContextSnapshot.defaultsKey)
        case .focusAndReminders:
            AttentionShieldManager.shared.resetAllProtectionData()
            MindfulnessBellScheduler.shared.cancelAll()
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            clearStandardDefaults(matching: ["mindfulness", "settle", "pomodoro", "quiet"])
            clearSharedDefaults(matching: ["screen", "shield", "beforeFeed", "morningGate", "attention"])
        case .analytics:
            try await AnalyticsManager.shared.deleteAnalyticsData()
        }
    }

    func deleteEverything() async throws {
        var firstError: Error?
        for category in MoriDataCategory.allCases {
            do { try await delete(category) }
            catch { firstError = firstError ?? error }
        }
        if let firstError { throw firstError }
    }

    private func clearStandardDefaults(matching fragments: [String]) {
        clear(defaults: .standard, matching: fragments)
    }

    private func clearSharedDefaults(matching fragments: [String]) {
        clear(defaults: MoriAppGroup.defaults, matching: fragments)
    }

    private func clear(defaults: UserDefaults, matching fragments: [String]) {
        for key in defaults.dictionaryRepresentation().keys where fragments.contains(where: { key.localizedCaseInsensitiveContains($0) }) {
            defaults.removeObject(forKey: key)
        }
    }
}
