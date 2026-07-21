import Combine
import SwiftUI

extension View {
    func settleTimerLifecycle(
        selectedMinutes: Int,
        darkRoomEnabled: Bool,
        showLeaveDialog: Binding<Bool>,
        onPrepare: @escaping () -> Void,
        onSelectedMinutesChange: @escaping (Int) -> Void,
        onTick: @escaping () -> Void,
        onDarkRoomEnabledChange: @escaping (Bool) -> Void,
        onCleanup: @escaping () -> Void,
        onEndAndLeave: @escaping () -> Void
    ) -> some View {
        modifier(
            SettleTimerLifecycleModifier(
                selectedMinutes: selectedMinutes,
                darkRoomEnabled: darkRoomEnabled,
                showLeaveDialog: showLeaveDialog,
                onPrepare: onPrepare,
                onSelectedMinutesChange: onSelectedMinutesChange,
                onTick: onTick,
                onDarkRoomEnabledChange: onDarkRoomEnabledChange,
                onCleanup: onCleanup,
                onEndAndLeave: onEndAndLeave
            )
        )
    }
}

private struct SettleTimerLifecycleModifier: ViewModifier {
    let selectedMinutes: Int
    let darkRoomEnabled: Bool
    @Binding var showLeaveDialog: Bool
    let onPrepare: () -> Void
    let onSelectedMinutesChange: (Int) -> Void
    let onTick: () -> Void
    let onDarkRoomEnabledChange: (Bool) -> Void
    let onCleanup: () -> Void
    let onEndAndLeave: () -> Void

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    func body(content: Content) -> some View {
        content
            .onAppear(perform: onPrepare)
            .moriOnChange(of: selectedMinutes, perform: onSelectedMinutesChange)
            .onReceive(ticker) { _ in onTick() }
            .moriOnChange(of: darkRoomEnabled, perform: onDarkRoomEnabledChange)
            .onDisappear(perform: onCleanup)
            .confirmationDialog(
                "End this Settle session?",
                isPresented: $showLeaveDialog,
                titleVisibility: .visible
            ) {
                Button("Keep practicing", role: .cancel) {}
                Button("End and leave", role: .destructive, action: onEndAndLeave)
            } message: {
                Text("The partial Settle session will be saved as ended early.")
            }
    }
}
