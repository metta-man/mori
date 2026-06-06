import Foundation
import Combine
import DeviceActivity
import FamilyControls
import ManagedSettings

@MainActor
final class FocusShieldManager: ObservableObject {
    static let shared = FocusShieldManager()

    @Published private(set) var authorizationStatus: AuthorizationStatus
    @Published private(set) var selectedCount: Int = 0
    @Published private(set) var activeSession: MoriScreenTimeActiveSession?
    @Published private(set) var lastErrorMessage: String?
    @Published var dailyThresholdMinutes: Int {
        didSet {
            let sanitized = min(240, max(5, dailyThresholdMinutes))
            if sanitized != dailyThresholdMinutes {
                dailyThresholdMinutes = sanitized
                return
            }
            defaults.set(sanitized, forKey: MoriScreenTimeShared.dailyThresholdMinutesKey)
            scheduleDailyThresholdMonitoring()
        }
    }

    private let authorizationCenter = AuthorizationCenter.shared
    private let managedStore = ManagedSettingsStore()
    private let activityCenter = DeviceActivityCenter()
    private let selectionStore = ScreenTimeSelectionStore()
    private let defaults = MoriAppGroup.defaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cancellable: AnyCancellable?

    private init() {
        authorizationStatus = authorizationCenter.authorizationStatus
        let savedThreshold = defaults.integer(forKey: MoriScreenTimeShared.dailyThresholdMinutesKey)
        dailyThresholdMinutes = savedThreshold > 0 ? savedThreshold : MoriScreenTimeShared.defaultDailyThresholdMinutes
        selectedCount = selectionStore.selectedCount
        activeSession = loadActiveSession()
        cancellable = authorizationCenter.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.authorizationStatus = status
            }
        restoreActiveShieldIfNeeded()
    }

    var isAuthorized: Bool {
        authorizationStatus == .approved
    }

    var hasSelection: Bool {
        selectionStore.hasSelection
    }

    func requestAuthorization() async {
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
            authorizationStatus = authorizationCenter.authorizationStatus
            lastErrorMessage = nil
            scheduleDailyThresholdMonitoring()
        } catch {
            lastErrorMessage = "Screen Time permission was not granted."
        }
    }

    func currentSelection() -> FamilyActivitySelection {
        selectionStore.loadSelection()
    }

    func saveSelection(_ selection: FamilyActivitySelection) {
        selectionStore.saveSelection(selection)
        selectedCount = selectionStore.selectedCount
        scheduleDailyThresholdMonitoring()

        if let session = activeSession, !session.isExpired {
            applyShield(for: session)
        }
    }

    func startShield(mode: MoriScreenTimeMode, endDate: Date) {
        guard isAuthorized, selectionStore.hasSelection else { return }
        let session = MoriScreenTimeActiveSession(mode: mode, startedAt: Date(), endDate: endDate)
        activeSession = session
        persistActiveSession(session)
        applyShield(for: session)
    }

    func endShield(mode: MoriScreenTimeMode? = nil) {
        guard mode == nil || activeSession?.mode == mode else { return }
        clearShield()
        activeSession = nil
        defaults.removeObject(forKey: MoriScreenTimeShared.activeSessionKey)
    }

    func restoreActiveShieldIfNeeded() {
        guard let session = loadActiveSession() else {
            clearShield()
            return
        }

        guard !session.isExpired else {
            endShield(mode: session.mode)
            return
        }

        activeSession = session
        if isAuthorized, selectionStore.hasSelection {
            applyShield(for: session)
        }
    }

    func scheduleDailyThresholdMonitoring() {
        guard isAuthorized, selectionStore.hasSelection else {
            activityCenter.stopMonitoring([.moriDailySelectedApps])
            return
        }

        let selection = selectionStore.loadSelection()
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: dailyThresholdMinutes)
        )

        do {
            try activityCenter.startMonitoring(
                .moriDailySelectedApps,
                during: schedule,
                events: [.moriSelectedAppsThreshold: event]
            )
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "Could not start Screen Time monitoring."
        }
    }

    private func applyShield(for session: MoriScreenTimeActiveSession) {
        let selection = selectionStore.loadSelection()
        managedStore.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        managedStore.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens, except: Set())
        managedStore.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    private func clearShield() {
        managedStore.shield.applications = nil
        managedStore.shield.applicationCategories = nil
        managedStore.shield.webDomains = nil
    }

    private func persistActiveSession(_ session: MoriScreenTimeActiveSession) {
        guard let data = try? encoder.encode(session) else { return }
        defaults.set(data, forKey: MoriScreenTimeShared.activeSessionKey)
    }

    private func loadActiveSession() -> MoriScreenTimeActiveSession? {
        guard let data = defaults.data(forKey: MoriScreenTimeShared.activeSessionKey) else { return nil }
        return try? decoder.decode(MoriScreenTimeActiveSession.self, from: data)
    }
}

extension DeviceActivityName {
    static let moriDailySelectedApps = Self("mori.daily.selected-apps")
}

extension DeviceActivityEvent.Name {
    static let moriSelectedAppsThreshold = Self("mori.selected-apps.threshold")
}
