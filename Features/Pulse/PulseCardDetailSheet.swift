import SwiftUI

struct PulseCardDetailSheet: View {
    @Binding var card: MoriPulseCard
    let isAnswering: Bool
    let errorMessage: String?
    let onAsk: (String) async -> Void
    let onRetry: () async -> Void
    let onOpenPractices: () -> Void

    init(
        card: Binding<MoriPulseCard>,
        isAnswering: Bool,
        errorMessage: String?,
        onAsk: @escaping (String) async -> Void,
        onRetry: @escaping () async -> Void,
        onOpenPractices: @escaping () -> Void
    ) {
        self._card = card
        self.isAnswering = isAnswering
        self.errorMessage = errorMessage
        self.onAsk = onAsk
        self.onRetry = onRetry
        self.onOpenPractices = onOpenPractices
    }

    @Environment(\.dismiss) private var dismiss
    @State private var question = ""

    private var tint: Color {
        switch card.kind {
        case .worthKnowing: return MoriColors.botanicalMoss
        case .worthIgnoring: return MoriColors.botanicalMist
        case .attentionTrap: return MoriColors.botanicalClay
        case .resetAction: return MoriColors.botanicalFern
        case .reclaimedTime: return MoriColors.botanicalSeed
        }
    }

    private var prompts: [String] {
        if !card.followUpPrompts.isEmpty {
            return Array(card.followUpPrompts.prefix(3))
        }

        switch card.kind {
        case .worthKnowing:
            return [
                MoriL10n.string("pulse.prompt.what_matters", defaultValue: "What matters most?"),
                MoriL10n.string("pulse.prompt.next", defaultValue: "What should I do next?")
            ]
        case .worthIgnoring:
            return [
                MoriL10n.string("pulse.prompt.why_wait", defaultValue: "Why can this wait?"),
                MoriL10n.string("pulse.prompt.real_signal", defaultValue: "What is the real signal?")
            ]
        case .attentionTrap:
            return [
                MoriL10n.string("pulse.prompt.sticky", defaultValue: "What makes this sticky?"),
                MoriL10n.string("pulse.prompt.step_away", defaultValue: "How do I step away?")
            ]
        case .resetAction:
            return [
                MoriL10n.string("pulse.prompt.practice", defaultValue: "Which reset fits now?"),
                MoriL10n.string("pulse.prompt.smaller", defaultValue: "Make this smaller")
            ]
        case .reclaimedTime:
            return [
                MoriL10n.string("pulse.prompt.protect_time", defaultValue: "How do I protect it?"),
                MoriL10n.string("pulse.prompt.time_source", defaultValue: "Where did this time come from?")
            ]
        }
    }

    var body: some View {
        NavigationStack {
            MoriPaperBackground(variant: .today) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        detailHeader

                        if !card.sources.isEmpty {
                            sourcesSection
                        }

                        promptsSection

                        threadSection

                        if let errorMessage {
                            PulseFollowUpErrorRow(
                                message: errorMessage,
                                isAnswering: isAnswering,
                                onRetry: onRetry
                            )
                        }

                        questionBar

                        Button(action: onOpenPractices) {
                            HStack(spacing: 8) {
                                MoriBitmapIconImage(icon: .refresh, size: 16, opacity: 0.94)
                                    .frame(width: 24, height: 24)
                                    .background(MoriColors.sanctuarySurface.opacity(0.86))
                                    .clipShape(Circle())

                                Text(MoriL10n.display("Choose reset action"))
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(MoriColors.botanicalSurface)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(MoriColors.botanicalInk)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 34)
                }
            }
            .navigationTitle(MoriL10n.display("Pulse"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(MoriL10n.display("Close")) {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)
                }
            }
            .moriKeyboardDoneToolbar()
        }
    }

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                MoriBitmapIconBadge(
                    icon: card.kind.icon,
                    size: 40,
                    iconScale: 0.58,
                    fill: MoriColors.sanctuarySurface.opacity(0.76),
                    stroke: Color.white.opacity(0.88),
                    shadow: MoriColors.sanctuaryShadow.opacity(0.18)
                )

                VStack(alignment: .leading, spacing: 5) {
                    Text(card.kind.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(tint)

                    Text(card.headline)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.botanicalInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(card.body)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(MoriColors.botanicalMuted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriSectionTitle(title: "Sources", subtitle: nil)

            ForEach(Array(card.sources.prefix(4).enumerated()), id: \.offset) { index, source in
                PulseCardSourceRow(source: source, index: index + 1, tint: tint)
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private var promptsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriSectionTitle(title: "Ask", subtitle: nil)

            FlowLayout(spacing: 8) {
                ForEach(prompts, id: \.self) { prompt in
                    Button {
                        submit(prompt)
                    } label: {
                        MoriPill(title: prompt, icon: .pulse, tint: tint)
                    }
                    .buttonStyle(.plain)
                    .disabled(isAnswering)
                }
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private var threadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriSectionTitle(title: "Thread", subtitle: nil)

            if card.followUpMessages.isEmpty {
                Text(MoriL10n.display("No follow-ups yet."))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)
            } else {
                ForEach(card.followUpMessages) { message in
                    PulseFollowUpMessageBubble(message: message, tint: tint)
                }
            }

            if isAnswering {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(tint)
                    Text(MoriL10n.display("Listening for signal..."))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalMuted)
                }
                .padding(.top, 2)
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private var questionBar: some View {
        HStack(spacing: 10) {
            TextField(MoriL10n.display("Ask a follow-up"), text: $question, axis: .vertical)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(MoriColors.botanicalInk)
                .lineLimit(1...3)
                .padding(12)
                .background(MoriColors.botanicalPaperDeep.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .disabled(isAnswering)

            Button {
                submit(question)
            } label: {
                MoriBitmapIconImage(icon: .pulse, size: 17, opacity: canSubmit ? 0.94 : 0.38)
                    .frame(width: 24, height: 24)
                    .background(canSubmit ? MoriColors.sanctuarySurface.opacity(0.86) : Color.clear)
                    .clipShape(Circle())
                    .frame(width: 46, height: 46)
                    .background(canSubmit ? MoriColors.botanicalInk : MoriColors.botanicalMuted.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
            .accessibilityLabel(MoriL10n.display("Send follow-up"))
        }
    }

    private var canSubmit: Bool {
        !isAnswering && !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submit(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isAnswering else { return }
        question = ""
        Task {
            await onAsk(trimmed)
        }
    }

}
