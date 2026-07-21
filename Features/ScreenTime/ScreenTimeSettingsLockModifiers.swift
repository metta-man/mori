import Combine
import SwiftUI

extension View {
    func screenTimePINInput(_ value: Binding<String>) -> some View {
        modifier(ScreenTimePINInputModifier(value: value))
    }

    func screenTimeSettingsUnlockLifecycle(
        onRefreshCooldown: @escaping () -> Void
    ) -> some View {
        modifier(
            ScreenTimeSettingsUnlockLifecycleModifier(
                onRefreshCooldown: onRefreshCooldown
            )
        )
    }

    func screenTimeSettingsLockLifecycle(
        onRefresh: @escaping () -> Void
    ) -> some View {
        modifier(ScreenTimeSettingsLockLifecycleModifier(onRefresh: onRefresh))
    }
}

private struct ScreenTimePINInputModifier: ViewModifier {
    @Binding var value: String

    func body(content: Content) -> some View {
        content
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .moriOnChange(of: value) { newValue in
                value = ScreenTimePINSanitizer.sanitized(newValue)
            }
    }
}

private struct ScreenTimeSettingsUnlockLifecycleModifier: ViewModifier {
    let onRefreshCooldown: () -> Void

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    func body(content: Content) -> some View {
        content
            .onAppear(perform: onRefreshCooldown)
            .onReceive(ticker) { _ in onRefreshCooldown() }
    }
}

private struct ScreenTimeSettingsLockLifecycleModifier: ViewModifier {
    let onRefresh: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear(perform: onRefresh)
    }
}

private enum ScreenTimePINSanitizer {
    static func sanitized(_ value: String) -> String {
        String(value.filter(\.isNumber).prefix(ScreenTimeSettingsLockStore.pinLength))
    }
}
