import Combine
import SwiftUI

struct MoriPracticeVerificationSheet: View {
    let practice: MoriPractice
    let onComplete: (MoriPractice) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var appLimitManager = AppLimitManager.shared
    @State private var secondsRemaining: Int
    @State private var isRunning = false
    @State private var showCompletionConfirm = false

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(practice: MoriPractice, onComplete: @escaping (MoriPractice) -> Void) {
        self.practice = practice
        self.onComplete = onComplete
        _secondsRemaining = State(initialValue: max(30, practice.minutes * 60))
    }

    private var verificationSeconds: Int {
        max(30, practice.minutes * 60)
    }

    private var canConfirmCompletion: Bool {
        secondsRemaining == 0 && !isRunning
    }

    private var screenTimeFeature: MoriScreenTimeFeature {
        practice.id == MoriPractice.walkReset.id ? .walkOfflineReset : .manualPractice
    }

    private var timerActionIcon: MoriBitmapIcon {
        if isRunning {
            return .pause
        }

        return secondsRemaining == 0 ? .refresh : .play
    }

    var body: some View {
        NavigationStack {
            MoriPaperBackground(variant: .practice) {
                GeometryReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 22) {
                            Spacer(minLength: 12)

                            MoriPageHeader(
                                eyebrow: "Pause",
                                title: practice.title,
                                subtitle: "Take this time at your own pace. Pause whenever you need."
                            )

                            VStack(alignment: .leading, spacing: 18) {
                                HStack(alignment: .top, spacing: 12) {
                                    MoriBitmapIconImage(icon: practice.icon, size: 18, opacity: 0.88)
                                        .frame(width: 40, height: 40)
                                        .background(MoriColors.botanicalMoss.opacity(0.12))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(MoriL10n.display(practice.description))
                                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                                            .foregroundColor(MoriColors.botanicalInk)

                                        Text(MoriL10n.string(
                                            "practice.quiet_time",
                                            defaultValue: "%@ of quiet time.",
                                            arguments: [practice.durationText]
                                        ))
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(MoriColors.botanicalMuted)
                                    }
                                }

                                VStack(spacing: 8) {
                                    Text(timeText)
                                        .font(.system(size: 58, weight: .regular, design: .serif))
                                        .foregroundColor(MoriV2Palette.forestInk)
                                        .monospacedDigit()
                                        .minimumScaleFactor(0.72)

                                    Text(MoriL10n.display(canConfirmCompletion ? "ready to finish" : isRunning ? "quiet time" : "ready when you are"))
                                        .font(MoriV2Type.caption)
                                        .foregroundColor(MoriV2Palette.mutedStone)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 28)
                                .background(MoriV2Palette.paper.opacity(0.72))
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel(MoriL10n.display("Quiet practice timer"))
                                .accessibilityValue(Text("\(timeText), \(timerStatusText)"))

                                MoriV2PrimaryButton(
                                    title: isRunning ? "Pause" : secondsRemaining == 0 ? "Restart" : "Start",
                                    icon: timerActionIcon,
                                    action: toggleTimer
                                )

                                if secondsRemaining < verificationSeconds {
                                    Button(action: resetVerification) {
                                        PracticeBitmapLabel(title: "Reset", icon: .refresh, iconSize: 15)
                                            .font(MoriV2Type.control)
                                            .foregroundColor(MoriV2Palette.stone)
                                            .frame(maxWidth: .infinity, minHeight: MoriV2Layout.minimumHitTarget)
                                    }
                                    .buttonStyle(MoriV2PressButtonStyle())
                                    .accessibilityLabel(MoriL10n.display("Restart quiet timer"))
                                }

                                if canConfirmCompletion {
                                    Button {
                                        showCompletionConfirm = true
                                    } label: {
                                        PracticeBitmapLabel(
                                            title: "Finish quiet practice",
                                            icon: .leaf,
                                            iconSize: 16,
                                            iconOpacity: 0.90
                                        )
                                            .font(MoriV2Type.control)
                                            .foregroundColor(MoriV2Palette.forestInk)
                                            .frame(maxWidth: .infinity, minHeight: MoriV2Layout.minimumHitTarget)
                                    }
                                    .buttonStyle(MoriV2PressButtonStyle())
                                }
                            }
                            .moriSanctuaryCard(cornerRadius: 24, padding: 18)

                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .top)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Quiet practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)
                }
            }
            .onReceive(ticker) { _ in
                tick()
            }
            .confirmationDialog(
                "Finish this quiet practice?",
                isPresented: $showCompletionConfirm,
                titleVisibility: .visible
            ) {
                Button("Finish") {
                    confirmCompletion()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Continue only if this pause feels complete.")
            }
            .onDisappear {
                appLimitManager.perform(.endAppLimit(feature: screenTimeFeature))
            }
        }
    }

    private var timeText: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var timerStatusText: String {
        MoriL10n.display(canConfirmCompletion ? "ready to finish" : isRunning ? "quiet time" : "ready")
    }

    private func tick() {
        guard isRunning else { return }
        guard secondsRemaining > 0 else {
            isRunning = false
            stopAppLimit()
            return
        }

        secondsRemaining -= 1
        if secondsRemaining == 0 {
            isRunning = false
            stopAppLimit()
        }
    }

    private func toggleTimer() {
        if isRunning {
            isRunning = false
            return
        }

        if secondsRemaining == 0 {
            secondsRemaining = verificationSeconds
        }
        startAppLimitIfPossible()
        isRunning = true
    }

    private func resetVerification() {
        secondsRemaining = verificationSeconds
        isRunning = false
        stopAppLimit()
    }

    private func confirmCompletion() {
        stopAppLimit()
        onComplete(practice)
    }

    private func startAppLimitIfPossible() {
        appLimitManager.perform(
            .startTimedAppLimit(
                feature: screenTimeFeature,
                remainingSeconds: secondsRemaining
            )
        )
    }

    private func stopAppLimit() {
        appLimitManager.perform(.endAppLimit(feature: screenTimeFeature))
    }
}
