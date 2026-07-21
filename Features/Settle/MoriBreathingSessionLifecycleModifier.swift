import Combine
import SwiftUI

extension View {
    func moriBreathingSessionLifecycle(
        autoStart: Bool,
        hasAutoStarted: Binding<Bool>,
        soundEnabled: Bool,
        hapticsEnabled: Bool,
        keepScreenOn: Bool,
        darkRoomEnabled: Bool,
        showLeaveDialog: Binding<Bool>,
        onPrepare: @escaping () -> Void,
        onAutoStart: @escaping () -> Void,
        onCleanup: @escaping () -> Void,
        onTick: @escaping (Date) -> Void,
        onSoundEnabledChange: @escaping (Bool) -> Void,
        onHapticsEnabledChange: @escaping (Bool) -> Void,
        onKeepScreenOnChange: @escaping () -> Void,
        onDarkRoomEnabledChange: @escaping (Bool) -> Void,
        onEndAndLeave: @escaping () -> Void
    ) -> some View {
        modifier(
            MoriBreathingSessionLifecycleModifier(
                autoStart: autoStart,
                hasAutoStarted: hasAutoStarted,
                soundEnabled: soundEnabled,
                hapticsEnabled: hapticsEnabled,
                keepScreenOn: keepScreenOn,
                darkRoomEnabled: darkRoomEnabled,
                showLeaveDialog: showLeaveDialog,
                onPrepare: onPrepare,
                onAutoStart: onAutoStart,
                onCleanup: onCleanup,
                onTick: onTick,
                onSoundEnabledChange: onSoundEnabledChange,
                onHapticsEnabledChange: onHapticsEnabledChange,
                onKeepScreenOnChange: onKeepScreenOnChange,
                onDarkRoomEnabledChange: onDarkRoomEnabledChange,
                onEndAndLeave: onEndAndLeave
            )
        )
    }
}

private struct MoriBreathingSessionLifecycleModifier: ViewModifier {
    let autoStart: Bool
    @Binding var hasAutoStarted: Bool
    let soundEnabled: Bool
    let hapticsEnabled: Bool
    let keepScreenOn: Bool
    let darkRoomEnabled: Bool
    @Binding var showLeaveDialog: Bool
    let onPrepare: () -> Void
    let onAutoStart: () -> Void
    let onCleanup: () -> Void
    let onTick: (Date) -> Void
    let onSoundEnabledChange: (Bool) -> Void
    let onHapticsEnabledChange: (Bool) -> Void
    let onKeepScreenOnChange: () -> Void
    let onDarkRoomEnabledChange: (Bool) -> Void
    let onEndAndLeave: () -> Void

    private let ticker = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    func body(content: Content) -> some View {
        content
            .onAppear(perform: handleAppear)
            .onDisappear(perform: onCleanup)
            .onReceive(ticker, perform: onTick)
            .moriOnChange(of: soundEnabled, perform: onSoundEnabledChange)
            .moriOnChange(of: hapticsEnabled, perform: onHapticsEnabledChange)
            .moriOnChange(of: keepScreenOn, perform: onKeepScreenOnChange)
            .moriOnChange(of: darkRoomEnabled, perform: onDarkRoomEnabledChange)
            .confirmationDialog(
                "End this breathing session?",
                isPresented: $showLeaveDialog,
                titleVisibility: .visible
            ) {
                Button("Keep breathing", role: .cancel) {}
                Button("End and leave", role: .destructive, action: onEndAndLeave)
            } message: {
                Text("Breathing sessions only record when the timer completes.")
            }
    }

    private func handleAppear() {
        onPrepare()

        guard autoStart, !hasAutoStarted else { return }
        hasAutoStarted = true
        DispatchQueue.main.async(execute: onAutoStart)
    }
}
