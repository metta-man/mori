import Foundation

enum MoriFactorTagCategory: String, Codable, CaseIterable {
    case body
    case mind
    case sleep
    case movement
    case practice
    case context
}

enum MoriFactorTagID: String, Codable, CaseIterable, Identifiable, Hashable {
    case lateCaffeine = "late_caffeine"
    case lateMeal = "late_meal"
    case hardWorkout = "hard_workout"
    case poorSleep = "poor_sleep"
    case workConflict = "work_conflict"
    case socialStress = "social_stress"
    case emotionalStrain = "emotional_strain"
    case travel = "travel"
    case bodyLoad = "body_load"
    case breathingPractice = "breathing_practice"
    case meditation = "meditation"
    case walk = "walk"
    case screenTimePressure = "screen_time_pressure"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .lateCaffeine: return MoriL10n.display("Late caffeine")
        case .lateMeal: return MoriL10n.display("Late meal")
        case .hardWorkout: return MoriL10n.display("Hard workout")
        case .poorSleep: return MoriL10n.display("Poor sleep")
        case .workConflict: return MoriL10n.display("Work conflict")
        case .socialStress: return MoriL10n.display("Social stress")
        case .emotionalStrain: return MoriL10n.display("Emotional strain")
        case .travel: return MoriL10n.display("Travel")
        case .bodyLoad: return MoriL10n.display("Body load")
        case .breathingPractice: return MoriL10n.display("Breathing")
        case .meditation: return MoriL10n.display("Meditation")
        case .walk: return MoriL10n.display("Walk")
        case .screenTimePressure: return MoriL10n.display("Screen pressure")
        }
    }

    var icon: MoriBitmapIcon {
        switch self {
        case .lateCaffeine, .lateMeal:
            return .leaf
        case .hardWorkout, .walk:
            return .focus
        case .poorSleep:
            return .quiet
        case .workConflict, .screenTimePressure:
            return .lockShield
        case .socialStress, .emotionalStrain, .bodyLoad:
            return .heart
        case .travel:
            return .refresh
        case .breathingPractice, .meditation:
            return .breathe
        }
    }

    var symbolName: String { icon.legacySystemName }

    var category: MoriFactorTagCategory {
        switch self {
        case .lateCaffeine, .lateMeal, .bodyLoad:
            return .body
        case .poorSleep:
            return .sleep
        case .hardWorkout, .walk:
            return .movement
        case .breathingPractice, .meditation:
            return .practice
        case .workConflict, .socialStress, .emotionalStrain, .screenTimePressure:
            return .mind
        case .travel:
            return .context
        }
    }

    var suggestedPractice: MoriPractice {
        switch self {
        case .lateCaffeine, .lateMeal, .poorSleep, .bodyLoad:
            return .settleThree
        case .hardWorkout:
            return .walkReset
        case .workConflict, .socialStress, .emotionalStrain, .screenTimePressure:
            return .breatheMinute
        case .travel:
            return .quietPause
        case .breathingPractice, .meditation:
            return .settleThree
        case .walk:
            return .walkReset
        }
    }

    var keywords: [String] {
        switch self {
        case .lateCaffeine:
            return ["coffee", "caffeine", "latte", "espresso", "matcha", "tea", "咖啡", "奶茶", "咖啡因"]
        case .lateMeal:
            return ["late dinner", "late meal", "snack", "heavy dinner", "宵夜", "夜晚食", "食太飽", "晚餐太夜"]
        case .hardWorkout:
            return ["interval", "hiit", "long run", "hard run", "heavy lift", "gym", "衝刺", "間歇", "重訓", "跑步"]
        case .poorSleep:
            return ["bad sleep", "poor sleep", "woke up", "insomnia", "瞓得差", "失眠", "醒咗", "睡眠差"]
        case .workConflict:
            return ["boss", "client", "deadline", "meeting", "argument at work", "work stress", "老細", "客戶", "開會", "工作壓力", "deadline"]
        case .socialStress:
            return ["argued", "fight", "relationship", "family", "friend", "嘈", "吵架", "屋企人", "朋友", "伴侶"]
        case .emotionalStrain:
            return ["anxious", "sad", "angry", "overwhelmed", "stressed", "焦慮", "嬲", "傷心", "壓力", "崩潰"]
        case .travel:
            return ["flight", "hotel", "jet lag", "travel", "trip", "飛機", "旅行", "酒店", "時差"]
        case .bodyLoad:
            return ["sick", "tired", "fatigue", "headache", "under the weather", "攰", "頭痛", "唔舒服", "疲勞"]
        case .breathingPractice:
            return ["breath", "breathing", "breathe", "呼吸"]
        case .meditation:
            return ["meditate", "meditation", "settle", "body scan", "冥想", "靜坐", "身體掃描"]
        case .walk:
            return ["walk", "walking", "步行", "散步"]
        case .screenTimePressure:
            return ["scroll", "instagram", "youtube", "tiktok", "phone", "doomscroll", "碌電話", "社交媒體", "短片"]
        }
    }
}

enum MoriFactorTagSourceKind: String, Codable, Equatable {
    case auto
    case user
    case practice
    case health
}

struct MoriFactorTag: Identifiable, Codable, Equatable {
    let id: MoriFactorTagID
    var confidence: Double
    var sourceKind: MoriFactorTagSourceKind
    var sourceID: String?
    var userEdited: Bool

    init(
        id: MoriFactorTagID,
        confidence: Double = 1,
        sourceKind: MoriFactorTagSourceKind,
        sourceID: String? = nil,
        userEdited: Bool = false
    ) {
        self.id = id
        self.confidence = max(0, min(1, confidence))
        self.sourceKind = sourceKind
        self.sourceID = sourceID
        self.userEdited = userEdited
    }
}
