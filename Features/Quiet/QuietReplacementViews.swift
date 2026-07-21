import SwiftUI

struct QuietReplacementActionsCard: View {
    @Binding var selectedReplacement: QuietReplacementAction?

    let onSelect: (QuietReplacementAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Another way",
                subtitle: "Choose a quieter response to the same need."
            )

            ForEach(QuietReplacementAction.allCases) { action in
                Button {
                    selectedReplacement = action
                    onSelect(action)
                } label: {
                    QuietReplacementActionRow(
                        action: action,
                        isSelected: selectedReplacement == action
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

private struct QuietReplacementActionRow: View {
    let action: QuietReplacementAction
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            MoriBitmapIconImage(icon: action.bitmapIcon, size: 17, opacity: 0.88)
                .frame(width: 36, height: 36)
                .background(action.tint.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(action.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)

                Text(action.note)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)
            }

            Spacer()

            Text("\(action.minutes)m")
                .font(MoriV2Type.caption)
                .foregroundColor(MoriV2Palette.mutedStone)
        }
        .padding(12)
        .frame(minHeight: MoriV2Layout.minimumHitTarget)
        .background(isSelected ? action.tint.opacity(0.12) : MoriColors.botanicalPaperDeep.opacity(0.52))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

enum QuietReplacementAction: String, CaseIterable, Identifiable {
    case breathe
    case journal
    case stretch
    case walk
    case reflect

    var id: String { rawValue }

    var title: String {
        switch self {
        case .breathe: return MoriL10n.display("Breathe")
        case .journal: return MoriL10n.display("Log")
        case .stretch: return MoriL10n.display("Stretch")
        case .walk: return MoriL10n.display("Walk")
        case .reflect: return MoriL10n.display("Reflect")
        }
    }

    var bitmapIcon: MoriBitmapIcon {
        switch self {
        case .breathe: return .breathe
        case .journal: return .journal
        case .stretch: return .focus
        case .walk: return .roots
        case .reflect: return .pulse
        }
    }

    var note: String {
        switch self {
        case .breathe: return MoriL10n.display("Two minutes of longer exhales")
        case .journal: return MoriL10n.display("Write the thought instead of feeding it")
        case .stretch: return MoriL10n.display("Move the body out of the loop")
        case .walk: return MoriL10n.display("Let the screen lose its grip")
        case .reflect: return MoriL10n.display("Ask what the urge is protecting")
        }
    }

    var seeds: Int {
        switch self {
        case .breathe, .journal, .stretch: return 2
        case .walk, .reflect: return 3
        }
    }

    var minutes: Int {
        switch self {
        case .breathe: return 2
        case .journal: return 5
        case .stretch: return 4
        case .walk: return 8
        case .reflect: return 6
        }
    }

    var tint: Color {
        switch self {
        case .breathe: return MoriColors.botanicalMist
        case .journal: return MoriColors.botanicalMoss
        case .stretch: return MoriColors.botanicalFern
        case .walk: return MoriColors.botanicalClay
        case .reflect: return MoriColors.botanicalSeed
        }
    }
}
