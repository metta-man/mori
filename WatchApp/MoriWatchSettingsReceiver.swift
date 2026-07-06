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

        if let archiveStartDate = context["archiveStartDate"] as? Date {
            defaults.set(archiveStartDate, forKey: "archiveStartDate")
        } else if let legacyArchiveStartDate = context["birthDate"] as? Date {
            defaults.set(legacyArchiveStartDate, forKey: "archiveStartDate")
        }

        if let archiveSpanYears = context["archiveSpanYears"] as? Int {
            defaults.set(archiveSpanYears, forKey: "archiveSpanYears")
        }

        if let localePreference = context[MoriLocalePreference.defaultsKey] as? String {
            defaults.set(localePreference, forKey: MoriLocalePreference.defaultsKey)
        }

        if let data = context[MoriWidgetContextSnapshot.watchApplicationContextKey] as? Data,
           let snapshot = MoriWidgetContextSnapshot.decode(data) {
            snapshot.save(defaults: defaults)
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "MoriWatchWidgets")
        WidgetCenter.shared.reloadTimelines(ofKind: "MoriWatchPulseWidget")
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
