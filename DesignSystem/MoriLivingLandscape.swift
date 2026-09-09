import SwiftUI
import UIKit

/// Presentation-only policy. No animation clock may drive a session or a shield.
enum MoriLandscapeMotionPolicy {
    static func allowsMotion(reduceMotion: Bool, lowPower: Bool, active: Bool,
                             visible: Bool, enabled: Bool) -> Bool {
        enabled && active && visible && !reduceMotion && !lowPower
    }
}

private struct MoriLandscapeMotionAllowedKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var moriLandscapeMotionAllowed: Bool {
        get { self[MoriLandscapeMotionAllowedKey.self] }
        set { self[MoriLandscapeMotionAllowedKey.self] = newValue }
    }
}

/// A fixed viewpoint: only the two leaf clusters, water and grass move.
/// The supplied art layers all share a 3:2 registration canvas.
struct MoriLivingLandscape: View {
    enum Mood { case meadow, waterside, reading }

    var mood: Mood = .meadow
    var motionEnabled = true
    var artworkAlignment: Alignment = .center
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.moriLandscapeMotionAllowed) private var motionAllowed
    @State private var isVisible = false
    @State private var lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled

    var body: some View {
        GeometryReader { proxy in
            let canvas = CGSize(width: max(proxy.size.width, proxy.size.height * 1.5),
                                height: max(proxy.size.width / 1.5, proxy.size.height))
            let onScreen = proxy.frame(in: .global).intersects(UIScreen.main.bounds)
            let moves = MoriLandscapeMotionPolicy.allowsMotion(
                reduceMotion: reduceMotion, lowPower: lowPower,
                active: scenePhase == .active, visible: isVisible && onScreen,
                enabled: motionEnabled && motionAllowed && mood != .reading
            )
            // Keep layout, text and the base painting outside the animation timeline.
            ZStack {
                Image("MoriMeadowTrunk")
                    .resizable()
                    .interpolation(.high)
                TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !moves)) { timeline in
                    let time = moves ? timeline.date.timeIntervalSinceReferenceDate : 0
                    movingLayers(size: canvas, time: time)
                }
            }
            .frame(width: canvas.width, height: canvas.height)
            .saturation(mood == .waterside ? 0.78 : 0.88)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: artworkAlignment)
            .clipped()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            isVisible = true
            lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
        .onDisappear { isVisible = false }
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
            lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }

    private func movingLayers(size: CGSize, time: Double) -> some View {
        ZStack {
            crown(size: size, left: true)
                .rotationEffect(.degrees(sin(time / 5.7) * 0.42), anchor: UnitPoint(x: 0.79, y: 0.58))
            crown(size: size, left: false)
                .rotationEffect(.degrees(sin(time / 7.3) * -0.34), anchor: UnitPoint(x: 0.81, y: 0.57))
            Canvas { context, canvas in
                // Narrow, low-contrast strokes sit only on the painted pond.
                for index in 0..<9 {
                    let n = Double(index)
                    let x = canvas.width * (0.07 + n.truncatingRemainder(dividingBy: 3) * 0.17)
                    let y = canvas.height * (0.755 + floor(n / 3) * 0.019)
                    let drift = sin(time / 6.5 + n * 1.7) * 2
                    var ripple = Path()
                    ripple.move(to: CGPoint(x: x + drift, y: y))
                    ripple.addQuadCurve(to: CGPoint(x: x + canvas.width * 0.095 + drift, y: y),
                                        control: CGPoint(x: x + canvas.width * 0.05, y: y + 0.8))
                    context.stroke(ripple, with: .color(MoriV2Palette.raisedPaper.opacity(0.46)),
                                   style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
                }
                for index in 0..<18 {
                    let n = Double(index)
                    let x = canvas.width * (0.035 + n * 0.052)
                    let y = canvas.height * (0.97 + sin(n * 2.1) * 0.018)
                    let height = canvas.height * (0.022 + (n.truncatingRemainder(dividingBy: 4)) * 0.005)
                    let sway = sin(time / 4.8 + n * 0.45) * 1.8
                    var blade = Path()
                    blade.move(to: CGPoint(x: x, y: y))
                    blade.addQuadCurve(to: CGPoint(x: x + sway + 2, y: y - height),
                                       control: CGPoint(x: x + sway, y: y - height * 0.6))
                    context.stroke(blade, with: .color(MoriV2Palette.sage.opacity(0.35)),
                                   style: StrokeStyle(lineWidth: 0.7, lineCap: .round))
                }
            }
        }
    }

    private func crown(size: CGSize, left: Bool) -> some View {
        Image("MoriMeadowCrown")
            .resizable()
            .interpolation(.high)
            .frame(width: size.width, height: size.height)
            .mask {
                // Complementary masks avoid a hard seam between the leaf clusters.
                LinearGradient(stops: [
                    .init(color: left ? .white : .clear, location: 0.69),
                    .init(color: left ? .clear : .white, location: 0.80)
                ], startPoint: .leading, endPoint: .trailing)
            }
    }
}

/// A paper field with the same meadow appearing at its lower edge.
/// Reading and utility surfaces deliberately use the still version.
struct MoriLivingPageBackground: View {
    var mood: MoriLivingLandscape.Mood = .reading
    var motionEnabled = false
    var landscapeFraction: CGFloat = 0.42
    var showsLandscape = true

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                MoriV2Palette.paper
                MoriGeneratedArtImage(art: .paperWash, contentMode: .fill)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .opacity(0.18)
                    .blendMode(.multiply)
                if showsLandscape {
                    MoriLivingLandscape(mood: mood, motionEnabled: motionEnabled)
                    .frame(height: min(proxy.size.width / 1.5, proxy.size.height * landscapeFraction))
                    .mask(LinearGradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .white.opacity(0.65), location: 0.25),
                        .init(color: .white, location: 0.60)
                    ], startPoint: .top, endPoint: .bottom))
                    .opacity(mood == .reading ? 0.46 : 0.90)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
