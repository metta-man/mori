import SwiftUI

final class SettleDarkRoomCoordinator: ObservableObject {
    @Published var controlsVisible = false
    @Published var offScreen = false

    private let idleTimerController: MoriIdleTimerController
    private var controlsHideWorkItem: DispatchWorkItem?

    init(idleTimerController: MoriIdleTimerController = .shared) {
        self.idleTimerController = idleTimerController
    }

    deinit {
        controlsHideWorkItem?.cancel()
        idleTimerController.reset()
    }

    func applyIdleTimerPolicy(keepScreenOn: Bool, isRunning: Bool, offScreenOverride: Bool? = nil) {
        let offScreenActive = offScreenOverride ?? offScreen
        let shouldDisableIdle = (offScreenActive || (keepScreenOn && isRunning)) && idleTimerController.isApplicationActive
        idleTimerController.setIdleTimerDisabled(shouldDisableIdle)
    }

    func revealControls(isDarkRoomEnabled: Bool, isSessionActive: Bool) {
        guard isDarkRoomEnabled, isSessionActive, !offScreen else { return }

        controlsHideWorkItem?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            controlsVisible = true
        }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, isDarkRoomEnabled, isSessionActive, !self.offScreen else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                self.controlsVisible = false
            }
        }
        controlsHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: workItem)
    }

    func hideControls() {
        controlsHideWorkItem?.cancel()
        controlsHideWorkItem = nil
        withAnimation(.easeInOut(duration: 0.2)) {
            controlsVisible = false
        }
    }

    func enterOffScreen(keepScreenOn: Bool, isRunning: Bool) {
        controlsHideWorkItem?.cancel()
        controlsHideWorkItem = nil
        withAnimation(.easeInOut(duration: 0.22)) {
            controlsVisible = false
            offScreen = true
        }
        applyIdleTimerPolicy(keepScreenOn: keepScreenOn, isRunning: isRunning, offScreenOverride: true)
    }

    func exitOffScreen(keepScreenOn: Bool, isRunning: Bool) {
        withAnimation(.easeInOut(duration: 0.22)) {
            offScreen = false
        }
        applyIdleTimerPolicy(keepScreenOn: keepScreenOn, isRunning: isRunning, offScreenOverride: false)
    }

    func clearTransientState(keepScreenOn: Bool, isRunning: Bool) {
        controlsHideWorkItem?.cancel()
        controlsHideWorkItem = nil
        controlsVisible = false
        offScreen = false
        applyIdleTimerPolicy(keepScreenOn: keepScreenOn, isRunning: isRunning, offScreenOverride: false)
    }

    func resetIdleTimer() {
        idleTimerController.reset()
    }
}
