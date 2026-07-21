import Combine
import SwiftUI

extension View {
    func pomodoroPracticeLifecycle(
        focusMinutes: Int,
        shortBreakMinutes: Int,
        longBreakMinutes: Int,
        cycles: Int,
        focusBreathingRaw: String,
        breakBreathingRaw: String,
        darkRoomEnabled: Bool,
        showLeaveDialog: Binding<Bool>,
        onPrepare: @escaping () -> Void,
        onDurationSettingsChange: @escaping () -> Void,
        onFocusBreathingChange: @escaping () -> Void,
        onBreakBreathingChange: @escaping () -> Void,
        onTick: @escaping () -> Void,
        onBreathingTick: @escaping () -> Void,
        onDarkRoomEnabledChange: @escaping (Bool) -> Void,
        onCleanup: @escaping () -> Void,
        onEndAndLeave: @escaping () -> Void
    ) -> some View {
        modifier(
            PomodoroPracticeLifecycleModifier(
                focusMinutes: focusMinutes,
                shortBreakMinutes: shortBreakMinutes,
                longBreakMinutes: longBreakMinutes,
                cycles: cycles,
                focusBreathingRaw: focusBreathingRaw,
                breakBreathingRaw: breakBreathingRaw,
                darkRoomEnabled: darkRoomEnabled,
                showLeaveDialog: showLeaveDialog,
                onPrepare: onPrepare,
                onDurationSettingsChange: onDurationSettingsChange,
                onFocusBreathingChange: onFocusBreathingChange,
                onBreakBreathingChange: onBreakBreathingChange,
                onTick: onTick,
                onBreathingTick: onBreathingTick,
                onDarkRoomEnabledChange: onDarkRoomEnabledChange,
                onCleanup: onCleanup,
                onEndAndLeave: onEndAndLeave
            )
        )
    }
}

private struct PomodoroPracticeLifecycleModifier: ViewModifier {
    let focusMinutes: Int
    let shortBreakMinutes: Int
    let longBreakMinutes: Int
    let cycles: Int
    let focusBreathingRaw: String
    let breakBreathingRaw: String
    let darkRoomEnabled: Bool
    @Binding var showLeaveDialog: Bool
    let onPrepare: () -> Void
    let onDurationSettingsChange: () -> Void
    let onFocusBreathingChange: () -> Void
    let onBreakBreathingChange: () -> Void
    let onTick: () -> Void
    let onBreathingTick: () -> Void
    let onDarkRoomEnabledChange: (Bool) -> Void
    let onCleanup: () -> Void
    let onEndAndLeave: () -> Void

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let breathingTicker = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    func body(content: Content) -> some View {
        content
            .onAppear(perform: onPrepare)
            .moriOnChange(of: focusMinutes, perform: onDurationSettingsChange)
            .moriOnChange(of: shortBreakMinutes, perform: onDurationSettingsChange)
            .moriOnChange(of: longBreakMinutes, perform: onDurationSettingsChange)
            .moriOnChange(of: cycles, perform: onDurationSettingsChange)
            .moriOnChange(of: focusBreathingRaw, perform: onFocusBreathingChange)
            .moriOnChange(of: breakBreathingRaw, perform: onBreakBreathingChange)
            .onReceive(ticker) { _ in onTick() }
            .onReceive(breathingTicker) { _ in onBreathingTick() }
            .moriOnChange(of: darkRoomEnabled, perform: onDarkRoomEnabledChange)
            .onDisappear(perform: onCleanup)
            .confirmationDialog(
                "End this Deep Session?",
                isPresented: $showLeaveDialog,
                titleVisibility: .visible
            ) {
                Button("Stay here", role: .cancel) {}
                Button("End and leave", role: .destructive, action: onEndAndLeave)
            } message: {
                Text("You can pause or leave. Nothing is lost.")
            }
    }
}
