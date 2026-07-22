import SwiftUI

struct DailySparkCard: View {
    @ObservedObject var store: DailySparkStore
    var onSaved: ((DailySparkEntry) -> Void)?

    @State private var focus = ""
    @State private var smallAction = ""
    @State private var desiredFeeling = ""
    @State private var thingToAvoid = ""
    @State private var ifThenPlan = ""
    @State private var isEditing = false

    private var feelingOptions: [String] {
        ["Clear", "Steady", "Brave", "Light", "Connected", "Useful"].map(MoriL10n.display)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if let entry = store.todayEntry {
                savedSpark(entry)
            } else {
                compactPrompt
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
        .onAppear(perform: loadToday)
        .onMoriDataChange(.dailySpark, perform: loadToday)
        .sheet(isPresented: $isEditing) {
            DailySparkEditorSheet(
                focus: $focus,
                smallAction: $smallAction,
                desiredFeeling: $desiredFeeling,
                thingToAvoid: $thingToAvoid,
                ifThenPlan: $ifThenPlan,
                feelingOptions: feelingOptions,
                canSave: canSave,
                onSave: saveSpark
            )
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            MoriBitmapIconBadge(
                icon: .leaf,
                size: 36,
                iconScale: 0.58,
                fill: MoriColors.sanctuarySurface.opacity(0.76),
                stroke: Color.white.opacity(0.88),
                shadow: MoriColors.sanctuaryShadow.opacity(0.18)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(MoriL10n.display("Daily Spark"))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.botanicalInk)

                Text(MoriL10n.display("Start with one small action."))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)
            }

            Spacer()

            if store.todayEntry != nil || isEditing {
                Button {
                    isEditing = true
                } label: {
                    MoriBitmapIconImage(icon: .journal, size: 17, opacity: 0.88)
                        .frame(width: 32, height: 32)
                        .background(MoriColors.botanicalInk.opacity(0.08))
                        .clipShape(Circle())
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(MoriL10n.display("Edit Daily Spark"))
            }
        }
    }

    private var compactPrompt: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(MoriL10n.display("Optional planner. Open it only when one check-in is not enough."))
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(MoriColors.botanicalMuted)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                isEditing = true
            } label: {
                HStack(spacing: 10) {
                    MoriBitmapIconImage(icon: .plus, size: 15, opacity: 0.88)
                        .frame(width: 30, height: 30)
                        .background(MoriColors.botanicalInk.opacity(0.08))
                        .clipShape(Circle())

                    Text(MoriL10n.display("Open Daily Spark"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalInk)

                    Spacer(minLength: 0)

                    MoriBitmapIconImage(icon: .chevron, size: 13, opacity: 0.58)
                }
                .padding(12)
                .background(MoriColors.botanicalPaperDeep.opacity(0.48))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(MoriL10n.display("Open Daily Spark"))
        }
    }

    private func savedSpark(_ entry: DailySparkEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SparkSummaryRow(icon: .focus, title: "Today's Focus", value: entry.focus)
            SparkSummaryRow(icon: .leaf, title: "Small Action", value: entry.smallAction)
            SparkSummaryRow(icon: .heart, title: "I want to feel", value: entry.desiredFeeling)
            SparkSummaryRow(icon: .lockShield, title: "Avoid", value: entry.thingToAvoid)

            if !entry.ifThenPlan.isEmpty {
                Text(entry.ifThenPlan)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(MoriColors.botanicalPaperDeep.opacity(0.58))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            HStack(spacing: 6) {
                MoriBitmapIconImage(icon: .journal, size: 14, opacity: 0.84)

                Text(MoriL10n.display("Saved to Log"))
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(MoriColors.botanicalMoss)
            .padding(.top, 2)
        }
    }

    private var canSave: Bool {
        !focus.trimmedForUI.isEmpty &&
        !smallAction.trimmedForUI.isEmpty &&
        !desiredFeeling.trimmedForUI.isEmpty &&
        !thingToAvoid.trimmedForUI.isEmpty
    }

    private func loadToday() {
        guard let entry = store.todayEntry else {
            if !isEditing {
                focus = ""
                smallAction = ""
                desiredFeeling = ""
                thingToAvoid = ""
                ifThenPlan = ""
            }
            return
        }

        focus = entry.focus
        smallAction = entry.smallAction
        desiredFeeling = entry.desiredFeeling
        thingToAvoid = entry.thingToAvoid
        ifThenPlan = entry.ifThenPlan
    }

    private func saveSpark() {
        let saved = store.saveToday(
            focus: focus,
            smallAction: smallAction,
            desiredFeeling: desiredFeeling,
            thingToAvoid: thingToAvoid,
            ifThenPlan: ifThenPlan
        )

        guard let saved else { return }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        isEditing = false

        onSaved?(saved)
    }
}

private struct DailySparkEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var focus: String
    @Binding var smallAction: String
    @Binding var desiredFeeling: String
    @Binding var thingToAvoid: String
    @Binding var ifThenPlan: String

    let feelingOptions: [String]
    let canSave: Bool
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            MoriPaperBackground(variant: .journal) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(MoriL10n.display("Start with one small action."))
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(MoriColors.botanicalMuted)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 18) {
                            DailySparkField(
                                title: "Today's Focus",
                                placeholder: "One thing that deserves my best attention",
                                text: $focus,
                                icon: .focus
                            )

                            DailySparkField(
                                title: "One small action",
                                placeholder: "One small action that protects today...",
                                text: $smallAction,
                                icon: .leaf
                            )

                            VStack(alignment: .leading, spacing: 10) {
                                DailySparkField(
                                    title: "Today I want to feel",
                                    placeholder: "Clear, steady, brave...",
                                    text: $desiredFeeling,
                                    icon: .heart
                                )

                                FlowLayout(spacing: 8) {
                                    ForEach(feelingOptions, id: \.self) { feeling in
                                        feelingButton(feeling)
                                    }
                                }
                            }

                            DailySparkField(
                                title: "One thing to avoid",
                                placeholder: "The drift that usually steals the day",
                                text: $thingToAvoid,
                                icon: .lockShield
                            )

                            DailySparkField(
                                title: "If-then plan",
                                placeholder: "If I notice it, I will pause and come back.",
                                text: $ifThenPlan,
                                icon: .refresh
                            )
                        }

                        saveButton
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(MoriL10n.display("Daily Spark"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(MoriL10n.display("Cancel")) {
                        dismiss()
                    }
                    .foregroundColor(MoriColors.botanicalInk)
                }
            }
        }
        .moriKeyboardDoneToolbar()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func feelingButton(_ feeling: String) -> some View {
        let isSelected = desiredFeeling == feeling

        return Button {
            desiredFeeling = feeling
        } label: {
            Text(MoriL10n.display(feeling))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? MoriColors.botanicalSurface : MoriColors.botanicalInk)
                .padding(.horizontal, 13)
                .frame(minHeight: 44)
                .background(isSelected ? MoriColors.botanicalInk : MoriColors.botanicalInk.opacity(0.08))
                .clipShape(Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MoriL10n.display(feeling))
        .accessibilityValue(isSelected ? MoriL10n.display("Selected") : "")
    }

    private var saveButton: some View {
        Button(action: onSave) {
            HStack(spacing: 8) {
                MoriBitmapIconImage(icon: .leaf, size: 16, opacity: canSave ? 0.96 : 0.42)
                    .frame(width: 23, height: 23)
                    .background(canSave ? MoriColors.sanctuarySurface.opacity(0.86) : Color.clear)
                    .clipShape(Circle())

                Text(MoriL10n.display("Save Daily Spark"))
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(canSave ? MoriColors.botanicalSurface : MoriColors.botanicalMuted)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(canSave ? MoriColors.botanicalInk : MoriColors.botanicalInk.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
        .accessibilityLabel(MoriL10n.display("Save Daily Spark"))
    }
}

private struct DailySparkField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: MoriBitmapIcon

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                MoriBitmapIconImage(icon: icon, size: 13, opacity: 0.70)

                Text(MoriL10n.display(title))
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(MoriColors.botanicalMuted)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(MoriL10n.display(placeholder))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MoriColors.botanicalInkSoft.opacity(0.88))
                        .lineLimit(2)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }

                TextField("", text: $text, axis: .vertical)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(MoriColors.botanicalInk)
                    .lineLimit(1...3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .submitLabel(.next)
                    .accessibilityLabel(MoriL10n.display(title))
            }
            .background(MoriColors.sanctuarySurface.opacity(0.94))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(MoriColors.botanicalInk.opacity(0.14), lineWidth: 1)
            )
            .frame(minHeight: 44)
        }
    }
}

private struct SparkSummaryRow: View {
    let icon: MoriBitmapIcon
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            MoriBitmapIconImage(icon: icon, size: 16, opacity: 0.82)
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 3) {
                Text(MoriL10n.display(title))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalMuted)

                Text(value)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(MoriColors.botanicalInk)
                    .lineLimit(2)
            }
        }
    }
}

private extension String {
    var trimmedForUI: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    MoriPaperBackground(variant: .today) {
        DailySparkCard(store: .shared)
            .padding()
    }
}
