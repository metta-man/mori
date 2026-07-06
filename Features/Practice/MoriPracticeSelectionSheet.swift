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
                            eyebrow: "Seeds",
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
        }
    }

    @ViewBuilder
    private func practiceRow(for practice: MoriPractice) -> some View {
        Button {
            onStartPractice(practice)
        } label: {
            MoriPracticeCard(practice: practice)
        }
        .buttonStyle(.plain)
    }
}
