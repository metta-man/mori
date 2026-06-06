import DeviceActivity
import Foundation

extension DeviceActivityName {
    static let moriDailySelectedApps = Self("mori.daily.selected-apps")
}

extension DeviceActivityEvent.Name {
    static let moriSelectedAppsThreshold = Self("mori.selected-apps.threshold")
}

final class MoriScreenTimeMonitorExtension: DeviceActivityMonitor {
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        guard activity == .moriDailySelectedApps,
              event == .moriSelectedAppsThreshold
        else {
            return
        }

        MoriScreenTimeSignalStore.append(
            MoriScreenTimeSignal(
                thresholdID: "mori.daily.selected-apps.mori.selected-apps.threshold",
                mode: .dailyThreshold
            )
        )
    }
}
