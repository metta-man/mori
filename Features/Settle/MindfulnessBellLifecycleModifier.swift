import SwiftUI

extension View {
    func mindfulnessBellLifecycle(
        scenePhase: ScenePhase,
        isActive: Bool,
        randomMode: Bool,
        intervalMinutes: Int,
        bellsPerHour: Int,
        startHour: Int,
        endHour: Int,
        onPrepare: @escaping () -> Void,
        onActiveChange: @escaping (Bool) -> Void,
        onScheduleSettingsChange: @escaping () -> Void,
        onSceneActive: @escaping () -> Void
    ) -> some View {
        modifier(
            MindfulnessBellLifecycleModifier(
                scenePhase: scenePhase,
                isActive: isActive,
                randomMode: randomMode,
                intervalMinutes: intervalMinutes,
                bellsPerHour: bellsPerHour,
                startHour: startHour,
                endHour: endHour,
                onPrepare: onPrepare,
                onActiveChange: onActiveChange,
                onScheduleSettingsChange: onScheduleSettingsChange,
                onSceneActive: onSceneActive
            )
        )
    }
}

private struct MindfulnessBellLifecycleModifier: ViewModifier {
    let scenePhase: ScenePhase
    let isActive: Bool
    let randomMode: Bool
    let intervalMinutes: Int
    let bellsPerHour: Int
    let startHour: Int
    let endHour: Int
    let onPrepare: () -> Void
    let onActiveChange: (Bool) -> Void
    let onScheduleSettingsChange: () -> Void
    let onSceneActive: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear(perform: onPrepare)
            .moriOnChange(of: isActive, perform: onActiveChange)
            .moriOnChange(of: randomMode, perform: onScheduleSettingsChange)
            .moriOnChange(of: intervalMinutes, perform: onScheduleSettingsChange)
            .moriOnChange(of: bellsPerHour, perform: onScheduleSettingsChange)
            .moriOnChange(of: startHour, perform: onScheduleSettingsChange)
            .moriOnChange(of: endHour, perform: onScheduleSettingsChange)
            .moriOnChange(of: scenePhase) { phase in
                guard phase == .active else { return }
                onSceneActive()
            }
    }
}
