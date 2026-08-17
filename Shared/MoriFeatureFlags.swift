import Foundation

enum MoriFeatureFlags {
    static var aiPulseEnabled: Bool {
#if DEBUG
        !ProcessInfo.processInfo.arguments.contains("-MoriDisableAIPulse")
#else
        false
#endif
    }
}
