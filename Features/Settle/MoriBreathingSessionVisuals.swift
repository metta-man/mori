import SwiftUI

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
        .onChange(of: reduceMotion) { shouldReduceMotion in
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
