import Foundation

enum MoriLocalePreference: String, CaseIterable, Identifiable, Codable {
    case system
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"

    static let defaultsKey = "mori_locale_preference"

    var id: String { rawValue }

    var localeIdentifier: String? {
        switch self {
        case .system:
            return nil
        case .english:
            return "en"
        case .simplifiedChinese:
            return "zh-Hans"
        case .traditionalChinese:
            return "zh-Hant"
        }
    }

    var resolvedLocaleIdentifier: String {
        localeIdentifier ?? Self.resolvedSystemLocaleIdentifier()
    }

    var locale: Locale {
        guard let localeIdentifier else {
            return .autoupdatingCurrent
        }
        return Locale(identifier: localeIdentifier)
    }

    var displayName: String {
        switch self {
        case .system:
            return MoriL10n.string("language.system", defaultValue: "System")
        case .english:
            return MoriL10n.string("language.english", defaultValue: "English")
        case .simplifiedChinese:
            return MoriL10n.string("language.zh_hans", defaultValue: "Simplified Chinese")
        case .traditionalChinese:
            return MoriL10n.string("language.zh_hant", defaultValue: "Traditional Chinese")
        }
    }

    var defaultPulseTopics: [String] {
        switch resolvedLocaleIdentifier {
        case MoriLocalePreference.simplifiedChinese.rawValue:
            return ["心智", "健康", "学习"]
        case MoriLocalePreference.traditionalChinese.rawValue:
            return ["心智", "健康", "學習"]
        default:
            return ["Mind", "Wellness", "Learning"]
        }
    }

    static func load(defaults: UserDefaults = MoriSharedDefaults.shared) -> MoriLocalePreference {
        if let rawValue = defaults.string(forKey: defaultsKey),
           let preference = MoriLocalePreference(rawValue: rawValue) {
            return preference
        }

        return .system
    }

    static func save(_ preference: MoriLocalePreference, defaults: UserDefaults = MoriSharedDefaults.shared) {
        defaults.set(preference.rawValue, forKey: defaultsKey)
    }

    static func resolvedSystemLocaleIdentifier(preferredLanguages: [String] = Locale.preferredLanguages) -> String {
        for language in preferredLanguages {
            let normalized = language.replacingOccurrences(of: "_", with: "-").lowercased()
            if normalized.hasPrefix("zh-hant") ||
                normalized.contains("-hk") ||
                normalized.contains("-mo") ||
                normalized.contains("-tw") {
                return MoriLocalePreference.traditionalChinese.rawValue
            }

            if normalized.hasPrefix("zh") {
                return MoriLocalePreference.simplifiedChinese.rawValue
            }

            if normalized.hasPrefix("en") {
                return MoriLocalePreference.english.rawValue
            }
        }

        return MoriLocalePreference.english.rawValue
    }
}

enum MoriL10n {
    static func display(_ value: String) -> String {
        if let localizedValue = localizedDynamicDisplay(value) {
            return localizedValue
        }

        return string(value, defaultValue: value)
    }

    static func display(_ value: String?) -> String? {
        guard let value else { return nil }
        return display(value)
    }

    static func string(
        _ key: String,
        defaultValue: String? = nil,
        arguments: [CVarArg] = []
    ) -> String {
        let preference = MoriLocalePreference.load()
        let localeIdentifier = preference.resolvedLocaleIdentifier
        let bundle = localizationBundle(for: localeIdentifier)
        let format = NSLocalizedString(
            key,
            tableName: nil,
            bundle: bundle,
            value: defaultValue ?? key,
            comment: ""
        )

        guard !arguments.isEmpty else {
            return format
        }

        return String(format: format, locale: Locale(identifier: localeIdentifier), arguments: arguments)
    }

    static func localizationBundle(for localeIdentifier: String) -> Bundle {
        if let path = Bundle.main.path(forResource: localeIdentifier, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }

        if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }

        return .main
    }

    private static func localizedDynamicDisplay(_ value: String) -> String? {
        guard value.hasSuffix("m") else { return nil }

        let numberText = String(value.dropLast()).replacingOccurrences(of: ",", with: "")
        guard let minutes = Int(numberText) else { return nil }

        return string("duration.minutes_short", defaultValue: "%dm", arguments: [minutes])
    }
}
