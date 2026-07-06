import Combine
import SwiftUI

extension View {
    func moriAttentionResetLifecycle(
        soundEnabled: Bool,
        onPrepare: @escaping () -> Void,
        onCleanup: @escaping () -> Void,
        onTick: @escaping (Date) -> Void,
        onSoundEnabledChange: @escaping (Bool) -> Void
    ) -> some View {
        modifier(
            MoriAttentionResetLifecycleModifier(
                soundEnabled: soundEnabled,
                onPrepare: onPrepare,
                onCleanup: onCleanup,
                onTick: onTick,
                onSoundEnabledChange: onSoundEnabledChange
            )
        )
    }
}

private struct MoriAttentionResetLifecycleModifier: ViewModifier {
    let soundEnabled: Bool
    let onPrepare: () -> Void
    let onCleanup: () -> Void
    let onTick: (Date) -> Void
    let onSoundEnabledChange: (Bool) -> Void

    private let ticker = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    func body(content: Content) -> some View {
        content
            .onAppear {
                DispatchQueue.main.async(execute: onPrepare)
            }
            .onDisappear(perform: onCleanup)
            .onReceive(ticker, perform: onTick)
            .onChange(of: soundEnabled, perform: onSoundEnabledChange)
    }
}
