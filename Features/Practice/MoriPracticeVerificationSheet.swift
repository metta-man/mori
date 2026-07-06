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

    private var progress: Double {
        guard verificationSeconds > 0 else { return 1 }
        let elapsedSeconds = max(0, min(verificationSeconds, verificationSeconds - secondsRemaining))
        return Double(elapsedSeconds) / Double(verificationSeconds)
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
                                eyebrow: "Verify",
                                title: practice.title,
                                subtitle: "Finish the reset first. The Seed is planted only after the timer and your confirmation."
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
                                            "practice.expected_time",
                                            defaultValue: "Expected time %@.",
                                            arguments: [practice.durationText]
                                        ))
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(MoriColors.botanicalMuted)
                                    }
                                }

                                ZStack {
                                    MoriTimerProgressRing(
                                        progress: CGFloat(progress),
                                        tint: MoriColors.botanicalMoss,
                                        lineWidth: 12
                                    )

                                    VStack(spacing: 6) {
                                        Text(timeText)
                                            .font(.system(size: 46, weight: .semibold, design: .rounded))
                                            .foregroundColor(MoriColors.botanicalInk)
                                            .monospacedDigit()

                                        Text(MoriL10n.display(canConfirmCompletion ? "ready to confirm" : isRunning ? "reset in progress" : "ready"))
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(MoriColors.botanicalMuted)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 230)

                                FlowLayout(spacing: 8) {
                                    MoriPill(title: practice.seedText, icon: .roots, tint: MoriColors.botanicalSeed)
                                    MoriPill(title: practice.domainText, icon: .leaf, tint: MoriColors.botanicalMoss)
                                }

                                HStack(spacing: 12) {
                                    Button(action: toggleTimer) {
                                        PracticeBitmapLabel(
                                            title: isRunning ? "Pause" : secondsRemaining == 0 ? "Restart" : "Start",
                                            icon: timerActionIcon,
                                            iconSize: 16,
                                            iconOpacity: 0.94
                                        )
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(MoriColors.botanicalSurface)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(MoriColors.botanicalInk)
                                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    }
                                    .buttonStyle(.plain)

                                    Button(action: resetVerification) {
                                        MoriBitmapIconImage(icon: .refresh, size: 17, opacity: 0.86)
                                            .frame(width: 50, height: 50)
                                            .background(MoriColors.botanicalInk.opacity(0.08))
                                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(MoriL10n.display("Reset verification timer"))
                                }

                                Button {
                                    showCompletionConfirm = true
                                } label: {
                                    PracticeBitmapLabel(
                                        title: "Confirm completion",
                                        icon: .leaf,
                                        iconSize: 16,
                                        iconOpacity: canConfirmCompletion ? 0.94 : 0.42
                                    )
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(canConfirmCompletion ? MoriColors.botanicalSurface : MoriColors.botanicalMuted)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(canConfirmCompletion ? MoriColors.botanicalMoss : MoriColors.botanicalInk.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .disabled(!canConfirmCompletion)
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
            .navigationTitle("Choose Reset")
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
                "Plant this Seed?",
                isPresented: $showCompletionConfirm,
                titleVisibility: .visible
            ) {
                Button("Yes, plant Seed") {
                    confirmCompletion()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Only confirm if you completed the reset.")
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
