import Foundation
import Combine

enum MoriLocalLLMAvailability: String, Equatable {
    case foundationModelsAvailable
    case foundationModelsUnavailable
    case templateOnly

    static var current: MoriLocalLLMAvailability {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return .foundationModelsAvailable
        }
        return .foundationModelsUnavailable
        #else
        return .templateOnly
        #endif
    }

    var displayText: String {
        switch self {
        case .foundationModelsAvailable:
            return MoriL10n.display("On-device rewrite available")
        case .foundationModelsUnavailable:
            return MoriL10n.display("On-device rewrite unavailable")
        case .templateOnly:
            return MoriL10n.display("Template insight mode")
        }
    }
}

@MainActor
final class MoriPatternInsightStore: ObservableObject {
    static let shared = MoriPatternInsightStore()

    @Published private(set) var insights: [RecoveryPatternInsight] = []
    @Published private(set) var localLLMAvailability: MoriLocalLLMAvailability = .current
    @Published private(set) var sampleDays = 0

    private init() {}

    func refresh(windowDays: Int = 60) {
        let logs = MoriDailyFactorLogBuilder.logs(windowDays: windowDays)
        sampleDays = logs.filter { $0.recoveryIndicator != nil }.count
        localLLMAvailability = .current
        insights = MoriRecoveryCorrelationEngine.insights(from: logs, windowDays: windowDays)
    }
}
