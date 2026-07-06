import Foundation

enum MoriScreenTimeSignalStore {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func allSignals() -> [MoriScreenTimeSignal] {
        guard let data = MoriAppGroup.defaults.data(forKey: MoriScreenTimeShared.signalsKey),
              let signals = try? decoder.decode([MoriScreenTimeSignal].self, from: data)
        else {
            return []
        }
        return signals
    }

    static func signals(for date: Date = Date()) -> [MoriScreenTimeSignal] {
        let key = MoriScreenTimeShared.dateKey(for: date)
        return allSignals().filter { $0.dateKey == key }
    }

    static func append(_ signal: MoriScreenTimeSignal) {
        var signals = allSignals()
        guard !signals.contains(where: { $0.thresholdID == signal.thresholdID && $0.dateKey == signal.dateKey }) else {
            return
        }

        signals.insert(signal, at: 0)
        if let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) {
            signals.removeAll { $0.reachedAt < cutoff }
        }
        persist(signals)
    }

    private static func persist(_ signals: [MoriScreenTimeSignal]) {
        guard let data = try? encoder.encode(signals) else { return }
        MoriAppGroup.defaults.set(data, forKey: MoriScreenTimeShared.signalsKey)
    }
}

enum MoriScreenTimeSavedTimeEstimator {
    static func estimate(
        feature: MoriScreenTimeFeature?,
        targetKind: MoriScreenTimeAttemptTargetKind,
        displayNames: [String] = []
    ) -> MoriScreenTimeSavedTimeEstimate {
        MoriScreenTimeSavedTimeEstimate(
            category: inferredCategory(
                feature: feature,
                targetKind: targetKind,
                displayNames: displayNames
            )
        )
    }

    static func persistCurrentEstimate(
        feature: MoriScreenTimeFeature?,
        displayNames: [String] = [],
        defaults: UserDefaults = MoriAppGroup.defaults
    ) {
        let estimate = estimate(
            feature: feature,
            targetKind: .application,
            displayNames: displayNames
        )
        defaults.set(estimate.seconds, forKey: MoriScreenTimeShared.currentShieldSavedTimeSecondsKey)
        defaults.set(estimate.category.rawValue, forKey: MoriScreenTimeShared.currentShieldSavedTimeCategoryKey)
    }

    static func currentEstimate(
        feature: MoriScreenTimeFeature?,
        targetKind: MoriScreenTimeAttemptTargetKind,
        defaults: UserDefaults = MoriAppGroup.defaults
    ) -> MoriScreenTimeSavedTimeEstimate {
        if defaults.object(forKey: MoriScreenTimeShared.currentShieldSavedTimeSecondsKey) != nil,
           let rawCategory = defaults.string(forKey: MoriScreenTimeShared.currentShieldSavedTimeCategoryKey),
           let category = MoriScreenTimeSavedTimeCategory(rawValue: rawCategory) {
            if category == .unknown, targetKind != .application {
                return estimate(feature: feature, targetKind: targetKind)
            }

            return MoriScreenTimeSavedTimeEstimate(
                category: category,
                seconds: defaults.integer(forKey: MoriScreenTimeShared.currentShieldSavedTimeSecondsKey)
            )
        }

        return estimate(feature: feature, targetKind: targetKind)
    }

    static func clearCurrentEstimate(defaults: UserDefaults = MoriAppGroup.defaults) {
        defaults.removeObject(forKey: MoriScreenTimeShared.currentShieldSavedTimeSecondsKey)
        defaults.removeObject(forKey: MoriScreenTimeShared.currentShieldSavedTimeCategoryKey)
    }

    private static func inferredCategory(
        feature: MoriScreenTimeFeature?,
        targetKind: MoriScreenTimeAttemptTargetKind,
        displayNames: [String]
    ) -> MoriScreenTimeSavedTimeCategory {
        let normalizedNames = displayNames.map(normalized)
        if containsAny(normalizedNames, from: streamingTerms) {
            return .streamingMedia
        }

        if containsAny(normalizedNames, from: gameTerms) {
            return .games
        }

        if containsAny(normalizedNames, from: shoppingTerms) {
            return .shopping
        }

        if containsAny(normalizedNames, from: newsTerms) {
            return .newsReading
        }

        if normalizedNames.contains("x") {
            return .socialMessaging
        }

        if containsAny(normalizedNames, from: socialTerms) {
            return .socialMessaging
        }

        if feature == .beforeFeed || feature == .morningGate {
            return .socialMessaging
        }

        if targetKind == .webDomain {
            return .newsReading
        }

        return .unknown
    }

    private static func normalized(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    private static func containsAny(_ names: [String], from terms: [String]) -> Bool {
        names.contains { name in
            terms.contains { name.contains($0) }
        }
    }

    private static let socialTerms = [
        "instagram", "tiktok", "facebook", "messenger", "snapchat", "twitter", "x.com",
        "threads", "reddit", "discord", "telegram", "whatsapp", "wechat", "weibo",
        "pinterest", "linkedin", "mastodon", "bluesky"
    ]

    private static let newsTerms = [
        "news", "nyt", "new york times", "washington post", "guardian", "cnn",
        "bbc", "bloomberg", "financial times", "wsj", "wall street journal",
        "medium", "substack"
    ]

    private static let streamingTerms = [
        "youtube", "netflix", "twitch", "hulu", "disney", "prime video",
        "spotify", "apple music", "podcast", "bilibili", "vimeo"
    ]

    private static let gameTerms = [
        "game", "gaming", "roblox", "minecraft", "steam", "playstation",
        "xbox", "nintendo", "genshin", "fortnite", "pubg"
    ]

    private static let shoppingTerms = [
        "amazon", "shop", "shopping", "shein", "temu", "taobao", "etsy",
        "ebay", "aliexpress", "target", "walmart"
    ]
}

enum MoriScreenTimeAttemptStore {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func allAttempts() -> [MoriScreenTimeAttempt] {
        guard let data = MoriAppGroup.defaults.data(forKey: MoriScreenTimeShared.attemptsKey),
              let attempts = try? decoder.decode([MoriScreenTimeAttempt].self, from: data)
        else {
            return []
        }
        return attempts
    }

    static func attempts(for date: Date = Date()) -> [MoriScreenTimeAttempt] {
        let key = MoriScreenTimeShared.dateKey(for: date)
        return allAttempts().filter { $0.dateKey == key }
    }

    static func append(_ attempt: MoriScreenTimeAttempt) {
        var attempts = allAttempts()
        attempts.insert(attempt, at: 0)
        if let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) {
            attempts.removeAll { $0.attemptedAt < cutoff }
        }
        persist(attempts)
    }

    static func savedSeconds(for date: Date = Date()) -> Int {
        attempts(for: date).reduce(0) { $0 + $1.estimatedSavedSeconds }
    }

    static func savedMinutes(for date: Date = Date()) -> Int {
        let seconds = savedSeconds(for: date)
        guard seconds > 0 else { return 0 }
        return Int(ceil(Double(seconds) / 60.0))
    }

    static func featureBreakdown(for date: Date = Date()) -> [String: Int] {
        attempts(for: date).reduce(into: [:]) { result, attempt in
            let key = attempt.feature?.rawValue ?? "unknown"
            result[key, default: 0] += 1
        }
    }

    static func categoryBreakdown(for date: Date = Date()) -> [String: Int] {
        attempts(for: date).reduce(into: [:]) { result, attempt in
            result[attempt.savedTimeCategory.rawValue, default: 0] += 1
        }
    }

    private static func persist(_ attempts: [MoriScreenTimeAttempt]) {
        guard let data = try? encoder.encode(attempts) else { return }
        MoriAppGroup.defaults.set(data, forKey: MoriScreenTimeShared.attemptsKey)
    }
}
