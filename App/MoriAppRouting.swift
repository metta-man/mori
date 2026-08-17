import SwiftUI

struct MoriPracticeLaunchRequest: Equatable {
    enum Kind: Equatable {
        case mindfulnessBellBreathing
        case deepSession
        case quietMode
        case essentialMode
    }

    let id = UUID()
    let kind: Kind
}

enum MoriAppRouteSource: String {
    case userInteraction = "user_interaction"
    case deepLink = "deep_link"
    case notification = "notification"
    case screenTimeGate = "screen_time_gate"
    case shortcut = "shortcut"
    case queued = "queued"

    var analyticsName: String {
        rawValue
    }
}

struct MoriAppRouteRequest {
    let route: MoriAppRoute
    let source: MoriAppRouteSource

    init(_ route: MoriAppRoute, source: MoriAppRouteSource) {
        self.route = route
        self.source = source
    }

    init(url: URL, fallbackSource: MoriAppRouteSource = .deepLink) {
        self.route = MoriAppRoute(url: url)
        self.source = MoriAppRouteSource(url: url) ?? fallbackSource
    }
}

struct MoriTodayLaunchRequest: Equatable {
    enum Kind: Equatable {
        case weekArchiveDetail
        case recovery
    }

    let id = UUID()
    let kind: Kind
}

struct MoriAppPresentationState {
    var selectedTab: AppTab = AppTab.defaultTab
    var activeSheet: MoriAppSheet?
    var activeSheetSource: MoriAppRouteSource?
    var todayLaunchRequest: MoriTodayLaunchRequest?
    var practiceLaunchRequest: MoriPracticeLaunchRequest?

    mutating func open(_ route: MoriAppRoute, source: MoriAppRouteSource) {
        switch route {
        case .tab(let tab):
            selectedTab = tab
            activeSheet = nil
            activeSheetSource = nil
            todayLaunchRequest = nil
            practiceLaunchRequest = nil
        case .sheet(let sheet, let tab):
            selectedTab = tab
            activeSheet = .practice(sheet)
            activeSheetSource = source
            todayLaunchRequest = nil
            practiceLaunchRequest = nil
        case .practiceSheet(let sheet):
            activeSheet = .practice(sheet)
            activeSheetSource = source
            todayLaunchRequest = nil
            practiceLaunchRequest = nil
        case .settings:
            activeSheet = .settings
            activeSheetSource = source
            todayLaunchRequest = nil
            practiceLaunchRequest = nil
        case .appLimits:
            activeSheet = .appLimits
            activeSheetSource = source
            todayLaunchRequest = nil
            practiceLaunchRequest = nil
        case .appLimitSetup:
            activeSheet = .appLimitSetup
            activeSheetSource = source
            todayLaunchRequest = nil
            practiceLaunchRequest = nil
        case .todayLaunch(let kind):
            selectedTab = .today
            activeSheet = nil
            activeSheetSource = nil
            todayLaunchRequest = MoriTodayLaunchRequest(kind: kind)
            practiceLaunchRequest = nil
        case .practiceLaunch(let kind):
            selectedTab = .practice
            activeSheet = nil
            activeSheetSource = nil
            todayLaunchRequest = nil
            practiceLaunchRequest = MoriPracticeLaunchRequest(kind: kind)
        }
    }
}

enum MoriAppSheet: Identifiable {
    case practice(MoriPracticeSheet)
    case settings
    case appLimits
    case appLimitSetup

    var id: String {
        switch self {
        case .practice(let sheet):
            return "practice-\(sheet.id)"
        case .settings:
            return "settings"
        case .appLimits:
            return "app-limits"
        case .appLimitSetup:
            return "app-limit-setup"
        }
    }
}

enum AppTab: Hashable, CaseIterable {
    case today
    case practice
    case journal

    static let defaultTab: AppTab = .today

    var title: String {
        switch self {
        case .today:
            return MoriL10n.display("Today")
        case .practice:
            return MoriL10n.display("Focus")
        case .journal:
            return MoriL10n.display("Log")
        }
    }

    var bitmapIcon: MoriBitmapIcon {
        switch self {
        case .today:
            return .home
        case .practice:
            return .focus
        case .journal:
            return .journal
        }
    }

    var backgroundVariant: MoriBotanicalScreenBackdrop.Variant {
        switch self {
        case .today:
            return .today
        case .practice:
            return .practice
        case .journal:
            return .journal
        }
    }

    var analyticsName: String {
        switch self {
        case .today:
            return "today"
        case .practice:
            return "practice"
        case .journal:
            return "journal"
        }
    }
}

enum MoriAppRoute {
    case tab(AppTab)
    case sheet(MoriPracticeSheet, tab: AppTab)
    case practiceSheet(MoriPracticeSheet)
    case settings
    case appLimits
    case appLimitSetup
    case todayLaunch(MoriTodayLaunchRequest.Kind)
    case practiceLaunch(MoriPracticeLaunchRequest.Kind)

    static let todayTab: MoriAppRoute = .tab(.today)
    static let lifeTab: MoriAppRoute = .todayTab
    static let practiceTab: MoriAppRoute = .tab(.practice)
    static let journalTab: MoriAppRoute = .tab(.journal)
    static let weekArchiveDetail: MoriAppRoute = .todayLaunch(.weekArchiveDetail)
    static let beforeFeedReset: MoriAppRoute = .sheet(.beforeFeed, tab: .today)
    static let morningGateReset: MoriAppRoute = .sheet(.morningGate, tab: .today)
    static let recoveryDetail: MoriAppRoute = .todayLaunch(.recovery)
    static var pulseSheet: MoriAppRoute {
        MoriFeatureFlags.aiPulseEnabled ? .sheet(.pulse, tab: .today) : .recoveryDetail
    }

    init(url: URL) {
        let target = "\(url.host ?? "") \(url.path)".lowercased()

        if Self.matches(target, anyOf: ["app-limit-settings", "app-limits-settings", "screen-time-settings", "advanced-app-limits", "app-limits-advanced", "pin-lock"]) {
            self = .appLimits
        } else if Self.matches(target, anyOf: ["settings", "preferences"]) {
            self = .settings
        } else if Self.matches(target, anyOf: ["app-limits", "app-limit", "screen-time", "shield", "attention-shield", "first-shield"]) {
            self = .appLimitSetup
        } else if Self.matches(target, anyOf: ["before-feed", "beforefeed", "feed-reset"]) {
            self = .beforeFeedReset
        } else if target.contains("morning") {
            self = .morningGateReset
        } else if Self.matches(target, anyOf: ["recovery", "readiness"]) {
            self = .recoveryDetail
        } else if target.contains("pulse") {
            self = .pulseSheet
        } else if Self.matches(target, anyOf: ["journal", "log", "record", "spark"]) {
            self = .journalTab
        } else if Self.matches(target, anyOf: ["grid", "week", "archive"]) {
            self = .weekArchiveDetail
        } else if Self.matches(target, anyOf: ["life", "home", "today", "countdown"]) {
            self = .todayTab
        } else if Self.matches(target, anyOf: ["clock", "roots", "growth"]) {
            self = .todayTab
        } else if Self.matches(target, anyOf: ["settle", "quiet", "breathing", "breathe", "pomodoro"]) {
            self = .practiceTab
        } else {
            self = .tab(AppTab.defaultTab)
        }
    }

    private static func matches(_ target: String, anyOf tokens: [String]) -> Bool {
        tokens.contains { target.contains($0) }
    }
}

private extension MoriAppRouteSource {
    init?(url: URL) {
        guard let value = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "source" })?
            .value
        else {
            return nil
        }

        self.init(rawValue: value)
    }
}

extension MoriAppSheet {
    var analyticsName: String {
        switch self {
        case .practice(let sheet):
            return "practice_\(sheet.analyticsName)"
        case .settings:
            return "settings"
        case .appLimits:
            return "app_limits_locked"
        case .appLimitSetup:
            return "app_limit_setup"
        }
    }
}

extension MoriPracticeSheet {
    var analyticsName: String {
        switch self {
        case .selection:
            return "selection"
        case .pulse:
            return "pulse"
        case .verification:
            return "verification"
        case .completion:
            return "completion"
        case .beforeFeed:
            return "before_feed"
        case .morningGate:
            return "morning_gate"
        case .breathingLibrary:
            return "breathing_library"
        case .settleTimer:
            return "settle_timer"
        case .focusCycle:
            return "focus_cycle"
        case .quietMode:
            return "quiet_mode"
        case .essentialMode:
            return "essential_mode"
        case .journal:
            return "journal"
        case .dailyCheckIn:
            return "daily_check_in"
        }
    }
}

extension MoriAppRoute {
    var analyticsName: String {
        switch self {
        case .tab:
            return "tab"
        case .sheet:
            return "sheet"
        case .practiceSheet:
            return "practice_sheet"
        case .settings:
            return "settings"
        case .appLimits:
            return "app_limits_locked"
        case .appLimitSetup:
            return "app_limit_setup"
        case .todayLaunch:
            return "today_launch"
        case .practiceLaunch:
            return "practice_launch"
        }
    }

    var analyticsProperties: [String: Any] {
        switch self {
        case .tab(let tab):
            return [
                AnalyticsProperties.destinationTab: tab.analyticsName
            ]
        case .sheet(let sheet, let tab):
            return [
                AnalyticsProperties.destinationTab: tab.analyticsName,
                AnalyticsProperties.sheetName: sheet.analyticsName
            ]
        case .practiceSheet(let sheet):
            return [
                AnalyticsProperties.sheetName: sheet.analyticsName
            ]
        case .settings:
            return [
                AnalyticsProperties.sheetName: MoriAppSheet.settings.analyticsName
            ]
        case .appLimits:
            return [
                AnalyticsProperties.sheetName: MoriAppSheet.appLimits.analyticsName
            ]
        case .appLimitSetup:
            return [
                AnalyticsProperties.sheetName: MoriAppSheet.appLimitSetup.analyticsName
            ]
        case .todayLaunch(let kind):
            return [
                AnalyticsProperties.destinationTab: AppTab.today.analyticsName,
                AnalyticsProperties.launchKind: kind.analyticsName
            ]
        case .practiceLaunch(let kind):
            return [
                AnalyticsProperties.destinationTab: AppTab.practice.analyticsName,
                AnalyticsProperties.launchKind: kind.analyticsName
            ]
        }
    }
}

private extension MoriTodayLaunchRequest.Kind {
    var analyticsName: String {
        switch self {
        case .weekArchiveDetail:
            return "week_archive_detail"
        case .recovery:
            return "recovery"
        }
    }
}

private extension MoriPracticeLaunchRequest.Kind {
    var analyticsName: String {
        switch self {
        case .mindfulnessBellBreathing:
            return "mindfulness_bell_breathing"
        case .deepSession:
            return "deep_session"
        case .quietMode:
            return "quiet_mode"
        case .essentialMode:
            return "essential_mode"
        }
    }
}

struct MoriAppRouteAction {
    private let handler: ((MoriAppRoute, MoriAppRouteSource) -> Void)?

    init(_ handler: ((MoriAppRoute, MoriAppRouteSource) -> Void)? = nil) {
        self.handler = handler
    }

    @discardableResult
    func callAsFunction(
        _ route: MoriAppRoute,
        source: MoriAppRouteSource = .userInteraction
    ) -> Bool {
        guard let handler else { return false }
        handler(route, source)
        return true
    }
}

private struct MoriAppRouteActionKey: EnvironmentKey {
    static let defaultValue = MoriAppRouteAction()
}

extension EnvironmentValues {
    var moriOpenRoute: MoriAppRouteAction {
        get { self[MoriAppRouteActionKey.self] }
        set { self[MoriAppRouteActionKey.self] = newValue }
    }
}
