import SwiftUI

extension View {
    func screenTimeGateRefreshes(
        beforeFeedNativeGateEnabled: Bool,
        beforeFeedHiddenAppLockEnabled: Bool,
        beforeFeedGraceWindowSeconds: Int,
        morningGateEnabled: Bool,
        morningGateHiddenAppLockEnabled: Bool,
        morningGateStartHour: Int,
        morningGateStartMinute: Int,
        morningGateDurationSeconds: Int,
        onGateSettingsChange: @escaping (MoriScreenTimeFeature) -> Void
    ) -> some View {
        modifier(
            ScreenTimeGateRefreshModifier(
                beforeFeedNativeGateEnabled: beforeFeedNativeGateEnabled,
                beforeFeedHiddenAppLockEnabled: beforeFeedHiddenAppLockEnabled,
                beforeFeedGraceWindowSeconds: beforeFeedGraceWindowSeconds,
                morningGateEnabled: morningGateEnabled,
                morningGateHiddenAppLockEnabled: morningGateHiddenAppLockEnabled,
                morningGateStartHour: morningGateStartHour,
                morningGateStartMinute: morningGateStartMinute,
                morningGateDurationSeconds: morningGateDurationSeconds,
                onGateSettingsChange: onGateSettingsChange
            )
        )
    }
}

private struct ScreenTimeGateRefreshModifier: ViewModifier {
    let beforeFeedNativeGateEnabled: Bool
    let beforeFeedHiddenAppLockEnabled: Bool
    let beforeFeedGraceWindowSeconds: Int
    let morningGateEnabled: Bool
    let morningGateHiddenAppLockEnabled: Bool
    let morningGateStartHour: Int
    let morningGateStartMinute: Int
    let morningGateDurationSeconds: Int
    let onGateSettingsChange: (MoriScreenTimeFeature) -> Void

    func body(content: Content) -> some View {
        content
            .moriOnChange(of: beforeFeedNativeGateEnabled) {
                onGateSettingsChange(.beforeFeed)
            }
            .moriOnChange(of: beforeFeedHiddenAppLockEnabled) {
                onGateSettingsChange(.beforeFeed)
            }
            .moriOnChange(of: beforeFeedGraceWindowSeconds) {
                onGateSettingsChange(.beforeFeed)
            }
            .moriOnChange(of: morningGateEnabled) {
                onGateSettingsChange(.morningGate)
            }
            .moriOnChange(of: morningGateHiddenAppLockEnabled) {
                onGateSettingsChange(.morningGate)
            }
            .moriOnChange(of: morningGateStartHour) {
                onGateSettingsChange(.morningGate)
            }
            .moriOnChange(of: morningGateStartMinute) {
                onGateSettingsChange(.morningGate)
            }
            .moriOnChange(of: morningGateDurationSeconds) {
                onGateSettingsChange(.morningGate)
            }
    }
}
