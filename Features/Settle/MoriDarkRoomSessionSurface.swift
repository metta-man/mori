import SwiftUI

struct MoriDarkRoomCueStatus: Equatable {
    let icon: MoriBitmapIcon
    let text: String

    static func current(soundEnabled: Bool, hapticsEnabled: Bool) -> MoriDarkRoomCueStatus? {
        switch (soundEnabled, hapticsEnabled) {
        case (true, true):
            return MoriDarkRoomCueStatus(icon: .sound, text: "Sound + haptic cues on")
        case (true, false):
            return MoriDarkRoomCueStatus(icon: .sound, text: "Sound cues on")
        case (false, true):
            return MoriDarkRoomCueStatus(icon: .haptics, text: "Haptic cues on")
        case (false, false):
            return nil
        }
    }
}

struct MoriDarkRoomSessionSurface<Controls: View>: View {
    let timeText: String
    let sessionLabel: String
    let cueText: String
    let cueStatus: MoriDarkRoomCueStatus?
    @Binding var dim: Double
    let isFullBlack: Bool
    let controlsVisible: Bool
    let onRevealControls: () -> Void
    let onExitFullBlack: () -> Void
    let controls: Controls

    init(
        timeText: String,
        sessionLabel: String,
        cueText: String,
        cueStatus: MoriDarkRoomCueStatus?,
        dim: Binding<Double>,
        isFullBlack: Bool,
        controlsVisible: Bool,
        onRevealControls: @escaping () -> Void,
        onExitFullBlack: @escaping () -> Void,
        @ViewBuilder controls: () -> Controls
    ) {
        self.timeText = timeText
        self.sessionLabel = sessionLabel
        self.cueText = cueText
        self.cueStatus = cueStatus
        _dim = dim
        self.isFullBlack = isFullBlack
        self.controlsVisible = controlsVisible
        self.onRevealControls = onRevealControls
        self.onExitFullBlack = onExitFullBlack
        self.controls = controls()
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if !isFullBlack {
                VStack(spacing: 0) {
                    Text(timeText)
                        .font(.system(size: 52, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(dimmedOpacity(0.92)))
                        .monospacedDigit()
                        .minimumScaleFactor(0.62)
                        .lineLimit(1)

                    Text(sessionLabel)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white.opacity(dimmedOpacity(0.52)))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.top, 24)

                    Text(cueText)
                        .font(.system(size: 25, weight: .semibold, design: .serif))
                        .foregroundColor(.white.opacity(dimmedOpacity(0.74)))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.top, 18)

                    if let cueStatus {
                        HStack(spacing: 10) {
                            MoriBitmapIconImage(icon: cueStatus.icon, size: 15, opacity: dimmedOpacity(0.58))

                            Text(cueStatus.text)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white.opacity(dimmedOpacity(0.46)))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.top, 32)
                    }

                    Text("Tap to wake")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(dimmedOpacity(0.28)))
                        .padding(.top, 58)
                        .opacity(controlsVisible ? 0 : 1)
                }
                .padding(.horizontal, 24)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(darkRoomAccessibilityLabel)
                .allowsHitTesting(false)

                if controlsVisible {
                    VStack {
                        Spacer()
                        controls
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isFullBlack {
                onExitFullBlack()
            } else {
                onRevealControls()
            }
        }
        .animation(.easeInOut(duration: 0.22), value: controlsVisible)
        .animation(.easeInOut(duration: 0.22), value: isFullBlack)
        .accessibilityLabel(isFullBlack ? MoriL10n.display("Full black mode. Tap to wake.") : darkRoomAccessibilityLabel)
    }

    private var contentOpacityScale: Double {
        min(1, max(0.55, 1.55 - dim))
    }

    private var darkRoomAccessibilityLabel: String {
        if let cueStatus {
            return "\(sessionLabel), \(cueText), \(timeText), \(cueStatus.text)"
        }
        return "\(sessionLabel), \(cueText), \(timeText)"
    }

    private func dimmedOpacity(_ opacity: Double) -> Double {
        opacity * contentOpacityScale
    }
}

struct MoriDarkRoomDimControl: View {
    @Binding var dim: Double

    var body: some View {
        VStack(spacing: 8) {
            Slider(value: $dim, in: 0.65...0.98)
                .tint(.white.opacity(0.72))

            Text("Dim")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.62))
        }
        .padding(.horizontal, 4)
    }
}

struct MoriDarkRoomFullBlackButton: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                MoriBitmapIconImage(icon: .quiet, size: 18, opacity: 0.88)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Text("Black")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.62))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Full black screen")
    }
}
