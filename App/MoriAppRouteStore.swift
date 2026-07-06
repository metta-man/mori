import Foundation

@MainActor
final class MoriAppRouteStore: ObservableObject {
    static let shared = MoriAppRouteStore()

    @Published private(set) var requestID = UUID()
    private var queuedRequests: [MoriAppRouteRequest] = []

    private init() {}

    func request(_ route: MoriAppRoute, source: MoriAppRouteSource = .queued) {
        queuedRequests.append(MoriAppRouteRequest(route, source: source))
        requestPendingRouteDrain()
    }

    func requestPendingRouteDrain() {
        requestID = UUID()
    }

    func consumeQueuedRouteRequests() -> [MoriAppRouteRequest] {
        let requests = queuedRequests
        queuedRequests.removeAll()
        return requests
    }

    func consumePendingResetRouteRequests() -> [MoriAppRouteRequest] {
        var requests: [MoriAppRouteRequest] = []

        if let source = BeforeFeedGate.consumePendingResetLaunch() {
            requests.append(MoriAppRouteRequest(.beforeFeedReset, source: MoriAppRouteSource(source)))
        }

        if let source = MorningGate.consumePendingResetLaunch() {
            requests.append(MoriAppRouteRequest(.morningGateReset, source: MoriAppRouteSource(source)))
        }

        return requests
    }
}

private extension MoriAppRouteSource {
    init(_ pendingSource: MoriPendingResetLaunchSource) {
        self = MoriAppRouteSource(rawValue: pendingSource.rawValue) ?? .screenTimeGate
    }
}
