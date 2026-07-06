import Combine
import Foundation

@MainActor
final class MoriRecoveryStore: ObservableObject {
    static let shared = MoriRecoveryStore()
    static let authorizationRequestedKey = MoriRecoveryPreferencesStore.authorizationRequestedKey
    static let llmInsightOptInKey = "mori_recovery_llm_insight_opt_in"
    static let uiTestReadyFixtureArgument = "-MoriUseMockRecoveryReadyForUITest"

    @Published private(set) var snapshot: MoriRecoverySnapshot = .permissionNeeded
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let service: MoriRecoveryHealthService
    private let preferences: MoriRecoveryPreferencesStore
    private let snapshotPublisher: MoriRecoverySnapshotPublisher

    private init(
        service: MoriRecoveryHealthService = MoriRecoveryHealthService(),
        preferences: MoriRecoveryPreferencesStore = MoriRecoveryPreferencesStore(),
        snapshotPublisher: MoriRecoverySnapshotPublisher = MoriRecoverySnapshotPublisher()
    ) {
        self.service = service
        self.preferences = preferences
        self.snapshotPublisher = snapshotPublisher
    }

    func refresh() async {
        guard !applyUITestReadyFixtureIfNeeded() else { return }

        guard preferences.hasRequestedAuthorization() else {
            snapshot = .permissionNeeded
            errorMessage = nil
            return
        }

        await load(requestAuthorization: false)
    }

    func requestAuthorizationAndRefresh() async {
        guard !applyUITestReadyFixtureIfNeeded() else { return }

        await load(requestAuthorization: true)
    }

    @discardableResult
    private func applyUITestReadyFixtureIfNeeded() -> Bool {
        guard ProcessInfo.processInfo.arguments.contains(Self.uiTestReadyFixtureArgument) else {
            return false
        }

        snapshot = .uiTestReadyFixture
        errorMessage = nil
        return true
    }

    private func load(requestAuthorization: Bool) async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let latest = try await service.snapshot(requestAuthorization: requestAuthorization)
            preferences.markAuthorizationRequested()
            snapshot = latest
            snapshotPublisher.publish(latest)
        } catch MoriRecoveryHealthServiceError.healthDataUnavailable {
            snapshot = .healthUnavailable
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
