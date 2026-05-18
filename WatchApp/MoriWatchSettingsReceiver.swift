import Foundation
import WatchConnectivity
import WidgetKit

final class MoriWatchSettingsReceiver: NSObject {
    static let shared = MoriWatchSettingsReceiver()

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        session.delegate = self

        if session.activationState == .notActivated {
            session.activate()
        } else {
            apply(session.receivedApplicationContext)
        }
    }

    private func apply(_ context: [String: Any]) {
        guard !context.isEmpty else { return }

        let defaults = MoriSharedDefaults.shared

        if let birthDate = context["birthDate"] as? Date {
            defaults.set(birthDate, forKey: "birthDate")
        }

        if let lifeExpectancy = context["lifeExpectancy"] as? Int {
            defaults.set(lifeExpectancy, forKey: "lifeExpectancy")
        }

        if let timeUnit = context["clockTimeUnit"] as? String {
            defaults.set(timeUnit, forKey: "clockTimeUnit")
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "MoriWatchWidgets")
    }
}

extension MoriWatchSettingsReceiver: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        apply(session.receivedApplicationContext)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(applicationContext)
    }
}
