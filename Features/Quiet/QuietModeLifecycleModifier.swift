import Combine
import SwiftUI

extension View {
    func quietModeLifecycle(
        selectedMinutes: Int,
        customHours: Int,
        customMinutes: Int,
        onPrepare: @escaping () -> Void,
        onTick: @escaping () -> Void,
        onSelectedMinutesChange: @escaping (Int) -> Void,
        onCustomHoursChange: @escaping (Int) -> Void,
        onCustomMinutesChange: @escaping () -> Void
    ) -> some View {
        modifier(
            QuietModeLifecycleModifier(
                selectedMinutes: selectedMinutes,
                customHours: customHours,
                customMinutes: customMinutes,
                onPrepare: onPrepare,
                onTick: onTick,
                onSelectedMinutesChange: onSelectedMinutesChange,
                onCustomHoursChange: onCustomHoursChange,
                onCustomMinutesChange: onCustomMinutesChange
            )
        )
    }
}

private struct QuietModeLifecycleModifier: ViewModifier {
    let selectedMinutes: Int
    let customHours: Int
    let customMinutes: Int
    let onPrepare: () -> Void
    let onTick: () -> Void
    let onSelectedMinutesChange: (Int) -> Void
    let onCustomHoursChange: (Int) -> Void
    let onCustomMinutesChange: () -> Void

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    func body(content: Content) -> some View {
        content
            .onAppear(perform: onPrepare)
            .onReceive(ticker) { _ in onTick() }
            .moriOnChange(of: selectedMinutes, perform: onSelectedMinutesChange)
            .moriOnChange(of: customHours, perform: onCustomHoursChange)
            .moriOnChange(of: customMinutes, perform: onCustomMinutesChange)
    }
}
