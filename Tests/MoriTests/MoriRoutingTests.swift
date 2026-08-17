import XCTest
@testable import Mori

final class MoriRoutingTests: XCTestCase {
    func testRecoveryDeepLinkOpensRecovery() {
        let request = MoriAppRouteRequest(url: URL(string: "mori://recovery")!)
        guard case .todayLaunch(.recovery) = request.route else {
            return XCTFail("Recovery link did not open Recovery")
        }
    }

    func testReleasePulseBoundary() {
        #if !DEBUG
        guard case .todayLaunch(.recovery) = MoriAppRoute.pulseSheet else {
            return XCTFail("Pulse must be hidden in release builds")
        }
        #endif
    }
}
