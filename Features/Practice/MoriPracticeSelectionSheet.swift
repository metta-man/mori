import SwiftUI

struct MoriPracticeSelectionSheet: View {
    let title: String
    let subtitle: String
    let practices: [MoriPractice]
    let onStartPractice: (MoriPractice) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            MoriPaperBackground(variant: .practice) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        MoriPageHeader(
                            eyebrow: "Quiet practice",
                            title: title,
                            subtitle: subtitle
                        )

                        ForEach(practices) { practice in
                            practiceRow(for: practice)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 34)
                }
            }
            .navigationTitle("Choose a pause")
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
        }
    }

    @ViewBuilder
    private func practiceRow(for practice: MoriPractice) -> some View {
        Button {
            onStartPractice(practice)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                MoriBitmapIconImage(icon: practice.icon, size: 20, opacity: 0.82)
                    .frame(width: 42, height: 42)
                    .background(MoriColors.sanctuarySurface.opacity(0.74))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(MoriL10n.display(practice.title))
                        .font(.system(.title3, design: .serif, weight: .regular))
                        .foregroundColor(MoriColors.sanctuaryInk)

                    Text(MoriL10n.display(practice.description))
                        .font(.system(.subheadline, design: .default, weight: .regular))
                        .foregroundColor(MoriColors.sanctuaryMuted)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(MoriL10n.display(practice.durationText))
                        .font(.system(.caption, design: .default, weight: .semibold))
                        .foregroundColor(MoriColors.sanctuarySage)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                MoriBitmapIconImage(icon: .chevron, size: 14, opacity: 0.50)
                    .padding(.top, 14)
            }
            .moriSanctuaryBox(cornerRadius: 16, padding: 14, tone: .paper, castsShadow: false)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(MoriL10n.string(
            "practice.selection.row.accessibility",
            defaultValue: "%@, %@, %@",
            arguments: [practice.title, practice.durationText, practice.description]
        ))
    }
}
