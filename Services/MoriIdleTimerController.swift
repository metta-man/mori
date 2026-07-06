import Foundation
import UIKit

struct MoriIdleTimerController {
    static let shared = MoriIdleTimerController(
        applicationActiveProvider: {
            UIApplication.shared.applicationState == .active
        },
        idleTimerSetter: { isDisabled in
            UIApplication.shared.isIdleTimerDisabled = isDisabled
        }
    )

    private let applicationActiveProvider: () -> Bool
    private let idleTimerSetter: (Bool) -> Void

    init(
        applicationActiveProvider: @escaping () -> Bool,
        idleTimerSetter: @escaping (Bool) -> Void
    ) {
        self.applicationActiveProvider = applicationActiveProvider
        self.idleTimerSetter = idleTimerSetter
    }

    var isApplicationActive: Bool {
        guard !Thread.isMainThread else {
            return applicationActiveProvider()
        }

        return DispatchQueue.main.sync {
            applicationActiveProvider()
        }
    }

    func setIdleTimerDisabled(_ isDisabled: Bool) {
        guard !Thread.isMainThread else {
            idleTimerSetter(isDisabled)
            return
        }

        DispatchQueue.main.async {
            idleTimerSetter(isDisabled)
        }
    }

    func reset() {
        setIdleTimerDisabled(false)
    }
}
