import XCTest
@testable import Mori

final class MoriLandscapeMotionTests: XCTestCase {
    func testMotionStopsForEveryIndependentSuppressionReason() {
        XCTAssertTrue(MoriLandscapeMotionPolicy.allowsMotion(
            reduceMotion: false, lowPower: false, active: true, visible: true, enabled: true))
        for reason in 0..<5 {
            XCTAssertFalse(MoriLandscapeMotionPolicy.allowsMotion(
                reduceMotion: reason == 0, lowPower: reason == 1,
                active: reason != 2, visible: reason != 3, enabled: reason != 4))
        }
    }
}
