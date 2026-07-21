import SwiftUI

struct MoriBreathingSessionSettingsSheet: View {
    @Binding var durationMinutes: Int
    @Binding var soundEnabled: Bool
    @Binding var hapticsEnabled: Bool
    @Binding var animationEnabled: Bool
    @Binding var darkRoomEnabled: Bool
    @Binding var keepScreenOn: Bool
    @Binding var hapticStyleRaw: String
    @Binding var customInhaleSeconds: Double
    @Binding var customHoldSeconds: Double
    @Binding var customExhaleSeconds: Double
    @Binding var customUsesHold: Bool
    let isRunning: Bool

    var body: some View {
        MoriPaperBackground(variant: .breath) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Breathing Settings")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(MoriColors.botanicalInk)
                        Text(MoriL10n.display(isRunning ? "Timing is locked while the session is active." : "Tune duration, cues, haptics, and the custom rhythm."))
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(MoriColors.botanicalMuted)
                    }

                    settingsSection(title: "Duration") {
                        Stepper(MoriL10n.string(
                            "breathing.settings.session_minutes",
                            defaultValue: "Session %dm",
                            arguments: [durationMinutes]
                        ), value: $durationMinutes, in: 1...180, step: 5)
                            .disabled(isRunning)
                    }

                    settingsSection(title: "Guidance") {
                        Toggle("Sound cues", isOn: $soundEnabled)
                            .tint(MoriColors.botanicalMoss)
                        Toggle("Haptic cues", isOn: $hapticsEnabled)
                            .tint(MoriColors.botanicalMoss)
                        Toggle(MoriL10n.string(
                            "breathing.settings.watercolor_motion",
                            defaultValue: "Watercolor motion"
                        ), isOn: $animationEnabled)
                            .tint(MoriColors.botanicalMoss)
                        Toggle(MoriL10n.string(
                            "breathing.settings.dark_room",
                            defaultValue: "Dark room"
                        ), isOn: $darkRoomEnabled)
                            .tint(MoriColors.botanicalMoss)
                        Toggle("Keep screen awake", isOn: $keepScreenOn)
                            .tint(MoriColors.botanicalMoss)

                        if hapticsEnabled {
                            Picker("Haptic style", selection: $hapticStyleRaw) {
                                ForEach(MoriBreathingHapticStyle.allCases) { style in
                                    Text(style.rawValue).tag(style.rawValue)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    settingsSection(title: "Custom Breathing") {
                        CustomBreathingStepper(title: "Inhale", value: $customInhaleSeconds, range: 1...20)
                        Toggle("Hold after inhale", isOn: $customUsesHold)
                            .tint(MoriColors.botanicalMoss)
                            .moriOnChange(of: customUsesHold) { enabled in
                                if enabled && customHoldSeconds < 1 {
                                    customHoldSeconds = 1
                                }
                            }
                        if customUsesHold {
                            CustomBreathingStepper(title: "Hold", value: $customHoldSeconds, range: 1...20)
                        }
                        CustomBreathingStepper(title: "Exhale", value: $customExhaleSeconds, range: 1...20)
                    }
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(MoriColors.botanicalInk)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(MoriL10n.display(title))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MoriColors.botanicalMuted)
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(14)
            .background(MoriColors.botanicalSurface.opacity(0.78))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

private struct CustomBreathingStepper: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        Stepper(value: $value, in: range, step: 0.5) {
            HStack {
                Text(MoriL10n.display(title))
                Spacer()
                Text(MoriBreathingTechnique.formatSeconds(value))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.botanicalMuted)
                    .monospacedDigit()
            }
        }
    }
}
