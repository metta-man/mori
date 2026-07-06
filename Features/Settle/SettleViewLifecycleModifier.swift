import SwiftUI

extension View {
    func settleLaunchRequestLifecycle(
        launchRequestID: UUID?,
        onHandleLaunchRequest: @escaping () -> Void
    ) -> some View {
        modifier(
            SettleLaunchRequestLifecycleModifier(
                launchRequestID: launchRequestID,
                onHandleLaunchRequest: onHandleLaunchRequest
            )
        )
    }
}

private struct SettleLaunchRequestLifecycleModifier: ViewModifier {
    let launchRequestID: UUID?
    let onHandleLaunchRequest: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear(perform: onHandleLaunchRequest)
            .onChange(of: launchRequestID) { _ in
                onHandleLaunchRequest()
            }
    }
}
