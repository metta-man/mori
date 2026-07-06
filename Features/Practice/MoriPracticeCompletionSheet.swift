import SwiftUI

struct PracticeBitmapLabel: View {
    let title: String
    let icon: MoriBitmapIcon
    var iconSize: CGFloat = 16
    var iconOpacity: Double = 0.88
    var spacing: CGFloat = 6

    var body: some View {
        HStack(spacing: spacing) {
            MoriBitmapIconImage(icon: icon, size: iconSize, opacity: iconOpacity)

            Text(MoriL10n.display(title))
        }
    }
}

struct MoriPracticeCompletionSheet: View {
    let practice: MoriPractice
    let seeds: Int

    @Environment(\.moriOpenRoute) private var openRoute
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            MoriPaperBackground(variant: .practice) {
                GeometryReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            Spacer(minLength: 18)

                            ZStack {
                                Circle()
                                    .fill(MoriColors.botanicalSeed.opacity(0.22))
                                    .frame(width: 86, height: 86)

                                MoriBitmapIconImage(icon: .leaf, size: 38, opacity: 0.94)
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Seed planted.")
                                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                                    .foregroundColor(MoriColors.botanicalInk)

                                Text(MoriL10n.string("today.seed_completion.nourished", defaultValue: "This nourished %@.", arguments: [practice.domainText]))
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(MoriColors.botanicalMoss)

                                Text("This week gained a Seed.")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(MoriColors.botanicalMuted)
                            }

                            FlowLayout(spacing: 8) {
                                MoriPill(title: "+\(seeds) Seed\(seeds == 1 ? "" : "s")", icon: .roots, tint: MoriColors.botanicalSeed)
                                MoriPill(title: practice.durationText, icon: .timer, tint: MoriColors.botanicalMist)
                                MoriPill(title: practice.domainText, icon: .leaf, tint: MoriColors.botanicalMoss)
                            }

                            Spacer(minLength: 0)

                            VStack(spacing: 10) {
                                Button(action: openWeekArchive) {
                                    PracticeBitmapLabel(title: "View weeks", icon: .roots, iconSize: 16, iconOpacity: 0.94)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(MoriColors.botanicalSurface)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 13)
                                        .background(MoriColors.botanicalInk)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)

                                Button {
                                    dismiss()
                                } label: {
                                    Text("Done")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(MoriColors.botanicalInk)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 13)
                                        .background(MoriColors.botanicalInk.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .top)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
        }
    }

    private func openWeekArchive() {
        if !openRoute(.weekArchiveDetail) {
            dismiss()
        }
    }
}
