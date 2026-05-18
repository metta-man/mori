import Foundation
import WatchConnectivity

final class MoriWatchSettingsSync: NSObject {
    static let shared = MoriWatchSettingsSync()

    private var pendingContext: [String: Any]?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        session.delegate = self

        if session.activationState == .notActivated {
            session.activate()
        }
    }

    func send(birthDate: Date, lifeExpectancy: Int, timeUnit: String) {
        guard WCSession.isSupported() else { return }

        let context: [String: Any] = [
            "birthDate": birthDate,
            "lifeExpectancy": lifeExpectancy,
            "clockTimeUnit": timeUnit
        ]

        pendingContext = context
        activate()
        flushPendingContext()
    }

    private func flushPendingContext() {
        guard
            let context = pendingContext,
            WCSession.default.activationState == .activated,
            WCSession.default.isWatchAppInstalled
        else { return }

        do {
            try WCSession.default.updateApplicationContext(context)
            pendingContext = nil
        } catch {
            pendingContext = context
        }
    }
}

extension MoriWatchSettingsSync: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        flushPendingContext()
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
