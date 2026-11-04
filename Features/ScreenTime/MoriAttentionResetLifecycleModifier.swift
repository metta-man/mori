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

    @Environment(\.scenePhase) private var scenePhase
    private let ticker = Timer.publish(every: 1.0 / 18.0, on: .main, in: .common).autoconnect()

    func body(content: Content) -> some View {
        content
            .onAppear {
                DispatchQueue.main.async(execute: onPrepare)
            }
            .onDisappear(perform: onCleanup)
            .onReceive(ticker) { date in
                guard scenePhase == .active else { return }
                onTick(date)
            }
            .moriOnChange(of: scenePhase) { phase in
                if phase == .active { onTick(Date()) }
            }
            .moriOnChange(of: soundEnabled, perform: onSoundEnabledChange)
    }
}
