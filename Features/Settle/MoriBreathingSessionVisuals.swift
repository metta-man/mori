import SwiftUI

/// A quiet watercolor bloom that follows the breathing phase without introducing
/// geometric progress rings or continuously redrawing procedural shapes.
struct MoriBreathingInkBloomView: View {
    let visualState: MoriBreathingCycleVisualState
    let isSessionActive: Bool
    let animationEnabled: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private var usesPhaseMotion: Bool {
        isSessionActive && animationEnabled && !reduceMotion && scenePhase == .active
    }

    private var phaseScale: CGFloat {
        guard usesPhaseMotion else { return 1 }
        return visualState.scale
    }

    private var phaseOpacity: Double {
        guard usesPhaseMotion else { return 0.94 }
        return 0.94 + ((visualState.opacity - 0.78) * 0.18)
    }

    private var phaseDrift: CGFloat {
        guard usesPhaseMotion else { return 0 }
        return (visualState.scale - 1) * 24
    }

    private var phaseBlur: CGFloat {
        guard usesPhaseMotion else { return 0 }
        return min(1.2, visualState.blur * 0.42)
    }

    var body: some View {
        ZStack {
            inkLayer
                .scaleEffect(
                    x: phaseScale * 1.02,
                    y: phaseScale * 1.06,
                    anchor: .center
                )
                .offset(x: phaseDrift, y: -phaseDrift * 0.52)
                .opacity(phaseOpacity * 0.88)

            inkLayer
                .rotationEffect(.degrees(-8))
                .scaleEffect(
                    x: 1.06 - ((phaseScale - 1) * 0.32),
                    y: 1.01 + ((phaseScale - 1) * 0.24),
                    anchor: .center
                )
                .offset(x: -phaseDrift * 0.64, y: phaseDrift * 0.72)
                .opacity(phaseOpacity * 0.18)
        }
        .blur(radius: phaseBlur)
        // The phase already uses cosine easing, as in Santi. Applying a second
        // animation here delays the visual behind the phase label at every tick.
        .transaction { $0.animation = nil }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var inkLayer: some View {
        MoriGeneratedArtImage(art: .breathInkBloom, contentMode: .fit)
            .blendMode(.multiply)
    }
}

struct MoriBreathingOrbView: View {
    let visualState: MoriBreathingCycleVisualState
    let isActive: Bool
    let isPaused: Bool
    let tint: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var gradientRotation: Angle = .zero

    private var shouldAnimate: Bool {
        isActive && !isPaused && !reduceMotion
    }

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(tint.opacity(0.18 - Double(index) * 0.035), lineWidth: 1.2)
                    .scaleEffect(1 + CGFloat(index) * 0.16)
            }

            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            MoriColors.botanicalMistSoft,
                            MoriColors.botanicalPaperDeep,
                            MoriColors.botanicalSeed.opacity(0.78),
                            MoriColors.botanicalMistSoft
                        ],
                        center: .center,
                        angle: gradientRotation
                    )
                )
                .overlay {
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.72),
                            Color.white.opacity(0.18),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 8,
                        endRadius: 150
                    )
                    .clipShape(Circle())
                }
                .shadow(color: tint.opacity(0.22), radius: 28, x: 0, y: 18)
        }
        .frame(width: 190, height: 190)
        .scaleEffect(shouldAnimate ? visualState.scale : (isActive ? 1.0 : 0.92))
        .opacity(shouldAnimate ? visualState.opacity : 0.86)
        .blur(radius: shouldAnimate ? visualState.blur : 0)
        .moriReduceMotionAnimation(.easeInOut(duration: 0.3), value: visualState.scale)
        .onAppear {
            guard !reduceMotion else {
                gradientRotation = .zero
                return
            }
            withAnimation(.linear(duration: 28).repeatForever(autoreverses: false)) {
                gradientRotation = .degrees(360)
            }
        }
        .moriOnChange(of: reduceMotion) { shouldReduceMotion in
            if shouldReduceMotion {
                gradientRotation = .zero
            } else {
                withAnimation(.linear(duration: 28).repeatForever(autoreverses: false)) {
                    gradientRotation = .degrees(360)
                }
            }
        }
    }
}

struct MoriBreathingProgressRing: View {
    let progress: CGFloat
    let tint: Color

    var body: some View {
        MoriTimerProgressRing(progress: progress, tint: tint)
    }
}

/// Adapted from Santi's current AnaBreathingLight and BreathBackgroundGuidance.
/// Visual mapping only: Mori owns the selected cadence, clock and phase labels.
enum MoriSantiBreathingCircleMotion {
    static func openness(phase: MoriBreathingCyclePhase, progress: Double) -> Double {
        let eased = 0.5 - 0.5 * cos(.pi * min(max(progress, 0), 1))
        switch phase {
        case .inhale: return eased
        case .holdAfterInhale: return 1
        case .exhale: return 1 - eased
        case .holdAfterExhale, .idle: return 0
        }
    }

    static func scale(openness: Double, allowsMotion: Bool) -> CGFloat {
        let expansion = allowsMotion ? min(1, max(0, openness)) : 0.5
        return CGFloat(0.76 + expansion * 0.24)
    }
}

struct MoriSantiBreathingCircleView: View {
    let visualState: MoriBreathingCycleVisualState
    let isRunning: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var frozenOpenness = 0.5

    private var openness: Double {
        MoriSantiBreathingCircleMotion.openness(phase: visualState.phase, progress: visualState.progress)
    }

    var body: some View {
        MoriSantiBreathingCircleDrawing(
            openness: isRunning ? openness : frozenOpenness,
            allowsMotion: !reduceMotion && scenePhase == .active
        )
        .transaction { $0.animation = nil }
        .onAppear { if isRunning { frozenOpenness = openness } }
        .moriOnChange(of: visualState) { _ in
            if isRunning { frozenOpenness = openness }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// The same circle drawing used by the live view, independently renderable for
/// phase snapshots without overriding system accessibility settings.
struct MoriSantiBreathingCircleDrawing: View {
    let openness: Double
    let allowsMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width, proxy.size.height)
            ZStack {
                Circle().fill(MoriColors.sanctuarySurface)
                Circle().fill(MoriColors.sanctuarySage.opacity(0.055))
            }
            .frame(width: diameter, height: diameter)
            .scaleEffect(MoriSantiBreathingCircleMotion.scale(
                openness: openness,
                allowsMotion: allowsMotion
            ))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(10)
    }
}
