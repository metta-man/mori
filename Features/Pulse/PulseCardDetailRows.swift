import SwiftUI

struct PulseCardSourceRow: View {
    let source: MoriPulseSource
    let index: Int
    let tint: Color

    var body: some View {
        Group {
            if let url = URL(string: source.url) {
                Link(destination: url) {
                    content
                }
            } else {
                content
            }
        }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(index)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(MoriColors.botanicalSurface)
                .frame(width: 24, height: 24)
                .background(tint)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(source.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)
                    .fixedSize(horizontal: false, vertical: true)

                Text(sourceMeta)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(MoriColors.botanicalPaperDeep.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var sourceMeta: String {
        [source.site, source.publishedAt, source.snippet]
            .compactMap { value in
                let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return trimmed.isEmpty ? nil : trimmed
            }
            .joined(separator: " · ")
    }
}

struct PulseFollowUpMessageBubble: View {
    let message: MoriPulseFollowUpMessage
    let tint: Color

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
            Text(message.content)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(isUser ? MoriColors.botanicalSurface : MoriColors.botanicalInk)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .background(isUser ? MoriColors.botanicalInk : MoriColors.botanicalPaperDeep.opacity(0.68))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if !message.sources.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(Array(message.sources.prefix(3).enumerated()), id: \.offset) { index, source in
                        MoriPill(
                            title: source.site ?? MoriL10n.string("pulse.source.fallback", defaultValue: "Source %d", arguments: [index + 1]),
                            icon: .journal,
                            tint: tint
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
}

struct PulseFollowUpErrorRow: View {
    let message: String
    let isAnswering: Bool
    let onRetry: () async -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            MoriBitmapIconImage(icon: .lockShield, size: 18, opacity: 0.82)

            Text(message)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(MoriColors.botanicalMuted)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Button {
                Task { await onRetry() }
            } label: {
                Text(MoriL10n.display("Retry"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(MoriColors.botanicalInk.opacity(0.08))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isAnswering)
        }
        .moriSanctuaryCard(cornerRadius: 18, padding: 14)
    }
}
