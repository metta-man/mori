import DeviceActivity

extension DeviceActivityName {
    static let moriDailySelectedApps = Self("mori.daily.selected-apps")
    static let moriBeforeFeedGrace = Self("mori.before-feed.grace")
    static let moriMorningGate = Self("mori.morning.gate")
    static let moriActiveSession = Self("mori.active-session")
}

extension DeviceActivityEvent.Name {
    static let moriSelectedAppsThreshold = Self("mori.selected-apps.threshold")
}
