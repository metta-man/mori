import SwiftUI

extension View {
    func screenTimeGateRefreshes(
        beforeFeedNativeGateEnabled: Bool,
        beforeFeedGraceWindowSeconds: Int,
        morningGateEnabled: Bool,
        morningGateStartHour: Int,
        morningGateStartMinute: Int,
        morningGateDurationSeconds: Int,
        onGateSettingsChange: @escaping (MoriScreenTimeFeature) -> Void
    ) -> some View {
        modifier(
            ScreenTimeGateRefreshModifier(
                beforeFeedNativeGateEnabled: beforeFeedNativeGateEnabled,
                beforeFeedGraceWindowSeconds: beforeFeedGraceWindowSeconds,
                morningGateEnabled: morningGateEnabled,
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
    let beforeFeedGraceWindowSeconds: Int
    let morningGateEnabled: Bool
    let morningGateStartHour: Int
    let morningGateStartMinute: Int
    let morningGateDurationSeconds: Int
    let onGateSettingsChange: (MoriScreenTimeFeature) -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: beforeFeedNativeGateEnabled) { _ in
                onGateSettingsChange(.beforeFeed)
            }
            .onChange(of: beforeFeedGraceWindowSeconds) { _ in
                onGateSettingsChange(.beforeFeed)
            }
            .onChange(of: morningGateEnabled) { _ in
                onGateSettingsChange(.morningGate)
            }
            .onChange(of: morningGateStartHour) { _ in
                onGateSettingsChange(.morningGate)
            }
            .onChange(of: morningGateStartMinute) { _ in
                onGateSettingsChange(.morningGate)
            }
            .onChange(of: morningGateDurationSeconds) { _ in
                onGateSettingsChange(.morningGate)
            }
    }
}
