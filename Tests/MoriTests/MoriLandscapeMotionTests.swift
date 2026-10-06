import XCTest
import SwiftUI
import UIKit
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

final class MoriSantiBreathingCircleTests: XCTestCase {
    func testCircleTracksSelectedPhaseEndpointsAndCosineMidpoint() {
        for progress in [0.0, 0.5, 1.0] {
            let inward = MoriSantiBreathingCircleMotion.openness(phase: .inhale, progress: progress)
            let outward = MoriSantiBreathingCircleMotion.openness(phase: .exhale, progress: progress)
            XCTAssertEqual(inward + outward, 1, accuracy: 0.000001)
            XCTAssertEqual(inward, progress, accuracy: 0.000001)
        }
        XCTAssertEqual(MoriSantiBreathingCircleMotion.openness(phase: .holdAfterInhale, progress: 0.3), 1)
        XCTAssertEqual(MoriSantiBreathingCircleMotion.openness(phase: .holdAfterExhale, progress: 0.7), 0)
        XCTAssertEqual(MoriSantiBreathingCircleMotion.openness(phase: .inhale, progress: -1), 0)
        XCTAssertEqual(MoriSantiBreathingCircleMotion.openness(phase: .exhale, progress: 2), 0)
    }

    func testReducedOrInactiveMotionUsesOneStaticSizeForEveryPhase() {
        for openness in [0.0, 0.2, 0.5, 0.8, 1.0] {
            XCTAssertEqual(MoriSantiBreathingCircleMotion.scale(openness: openness, allowsMotion: false), 0.88, accuracy: 0.000001)
        }
        XCTAssertEqual(MoriSantiBreathingCircleMotion.scale(openness: 0, allowsMotion: true), 0.76, accuracy: 0.000001)
        XCTAssertEqual(MoriSantiBreathingCircleMotion.scale(openness: 1, allowsMotion: true), 1, accuracy: 0.000001)
    }
}

final class MoriSantiCircleNativeRenderingTests: XCTestCase {
    @MainActor
    func testNativeCircleRendersNormalExpansionAndReducedStillness() throws {
        func render(progress: Double, reduced: Bool) throws -> UIImage {
            let openness = MoriSantiBreathingCircleMotion.openness(phase: .inhale, progress: progress)
            let renderer = ImageRenderer(content: MoriSantiBreathingCircleDrawing(openness: openness, allowsMotion: !reduced)
                .frame(width: 240, height: 240))
            renderer.scale = 1
            return try XCTUnwrap(renderer.uiImage)
        }
        func geometry(_ image: UIImage) throws -> (width: Int, pixels: Int) {
            let cgImage = try XCTUnwrap(image.cgImage)
            let width = cgImage.width, height = cgImage.height
            var rgba = [UInt8](repeating: 0, count: width * height * 4)
            try rgba.withUnsafeMutableBytes { bytes in
                let context = try XCTUnwrap(CGContext(data: bytes.baseAddress, width: width, height: height,
                    bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
                context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            }
            var minX = width, maxX = -1, filled = 0
            for y in 0..<height {
                for x in 0..<width where rgba[(y * width + x) * 4 + 3] >= 128 {
                    minX = min(minX, x); maxX = max(maxX, x); filled += 1
                }
            }
            XCTAssertGreaterThan(filled, 0)
            return (maxX - minX + 1, filled)
        }
        let contracted = try render(progress: 0, reduced: false)
        let expanded = try render(progress: 1, reduced: false)
        let reducedStart = try render(progress: 0, reduced: true)
        let reducedEnd = try render(progress: 1, reduced: true)
        let small = try geometry(contracted), large = try geometry(expanded)
        let stillA = try geometry(reducedStart), stillB = try geometry(reducedEnd)
        XCTAssertGreaterThan(large.width, small.width)
        XCTAssertGreaterThan(large.pixels, small.pixels)
        XCTAssertNotEqual(contracted.pngData(), expanded.pngData())
        XCTAssertEqual(stillA.width, stillB.width)
        XCTAssertEqual(stillA.pixels, stillB.pixels)
        XCTAssertEqual(reducedStart.pngData(), reducedEnd.pngData())
        XCTAssertGreaterThan(stillA.width, small.width)
        XCTAssertLessThan(stillA.width, large.width)
        for (name, image) in [("Native circle normal contracted", contracted), ("Native circle normal expanded", expanded),
                              ("Native circle reduced start", reducedStart), ("Native circle reduced end", reducedEnd)] {
            let attachment = XCTAttachment(image: image)
            attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
        }
        let proof = XCTAttachment(string: "revision=MoriCircleNativeRender-20261002-v1\nnormalWidths=\(small.width),\(large.width)\nnormalFilledPixels=\(small.pixels),\(large.pixels)\nreducedWidths=\(stillA.width),\(stillB.width)\nreducedFilledPixels=\(stillA.pixels),\(stillB.pixels)\nreducedPixelsIdentical=\(reducedStart.pngData() == reducedEnd.pngData())")
        proof.name = "Mori native circle phase pixel proof"; proof.lifetime = .keepAlways; add(proof)
    }
}
