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
            .onChange(of: focusMinutes) { _ in onDurationSettingsChange() }
            .onChange(of: shortBreakMinutes) { _ in onDurationSettingsChange() }
            .onChange(of: longBreakMinutes) { _ in onDurationSettingsChange() }
            .onChange(of: cycles) { _ in onDurationSettingsChange() }
            .onChange(of: focusBreathingRaw) { _ in onFocusBreathingChange() }
            .onChange(of: breakBreathingRaw) { _ in onBreakBreathingChange() }
            .onReceive(ticker) { _ in onTick() }
            .onReceive(breathingTicker) { _ in onBreathingTick() }
            .onChange(of: darkRoomEnabled, perform: onDarkRoomEnabledChange)
            .onDisappear(perform: onCleanup)
            .confirmationDialog(
                "End this Pomodoro?",
                isPresented: $showLeaveDialog,
                titleVisibility: .visible
            ) {
                Button("Keep focusing", role: .cancel) {}
                Button("End and leave", role: .destructive, action: onEndAndLeave)
            } message: {
                Text("Pomodoro sessions only record when the full cycle completes.")
            }
    }
}
