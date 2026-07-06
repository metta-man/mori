import SwiftUI

struct PatternLogSheet: View {
    let existingEntry: HabitEntry?
    let onSave: (HabitDayTone, String, String, String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTone: HabitDayTone
    @State private var trigger: String
    @State private var thought: String
    @State private var feeling: String
    @State private var responsePlan: String

    init(
        existingEntry: HabitEntry?,
        initialTone: HabitDayTone,
        onSave: @escaping (HabitDayTone, String, String, String, String) -> Void
    ) {
        self.existingEntry = existingEntry
        self.onSave = onSave
        _selectedTone = State(initialValue: initialTone)
        _trigger = State(initialValue: existingEntry?.trigger ?? "")
        _thought = State(initialValue: existingEntry?.thought ?? "")
        _feeling = State(initialValue: existingEntry?.feeling ?? "")
        _responsePlan = State(initialValue: existingEntry?.responsePlan ?? "")
    }

    var body: some View {
        NavigationStack {
            MoriPaperBackground(variant: .journal) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(MoriL10n.display("Pattern Log"))
                                .font(.system(size: 28, weight: .semibold, design: .rounded))
                                .foregroundColor(MoriColors.botanicalInk)

                            Text(MoriL10n.display("Notice the loop, then choose the next small move."))
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(MoriColors.botanicalMuted)
                        }

                        Picker(MoriL10n.display("Day tone"), selection: $selectedTone) {
                            ForEach(HabitDayTone.allCases) { tone in
                                Text(tone.title).tag(tone)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(MoriColors.botanicalMoss)

                        PatternLogField(
                            title: "Trigger",
                            placeholder: "What set it off?",
                            text: $trigger
                        )

                        PatternLogField(
                            title: "Thought",
                            placeholder: "What did your mind say?",
                            text: $thought
                        )

                        PatternLogField(
                            title: "Feeling",
                            placeholder: "Name the feeling or body signal.",
                            text: $feeling
                        )

                        PatternLogField(
                            title: "Next response",
                            placeholder: "If this shows up again, I will...",
                            text: $responsePlan
                        )

                        Button(action: save) {
                            HabitTrackerBitmapLabel(title: "Save pattern log", icon: .leaf, iconSize: 16, iconOpacity: 0.94)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(MoriColors.botanicalSurface)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(MoriColors.botanicalInk)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(MoriL10n.display("Done"), action: save)
                        .foregroundColor(MoriColors.botanicalInk)
                }
            }
        }
        .moriKeyboardDoneToolbar()
        .presentationDetents([.large])
    }

    private func save() {
        onSave(selectedTone, trigger, thought, feeling, responsePlan)
        dismiss()
    }

    static func summary(
        trigger: String,
        thought: String,
        feeling: String,
        responsePlan: String
    ) -> String? {
        let rows = [
            (MoriL10n.display("Trigger"), trigger),
            (MoriL10n.display("Thought"), thought),
            (MoriL10n.display("Feeling"), feeling),
            (MoriL10n.display("Next response"), responsePlan)
        ]
            .map { label, value in (label, value.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !$0.1.isEmpty }

        guard !rows.isEmpty else { return nil }
        return rows.map { "\($0.0): \($0.1)" }.joined(separator: "\n")
    }
}

private struct PatternLogField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(MoriL10n.display(title))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MoriColors.botanicalMuted)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(MoriL10n.display(placeholder))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted.opacity(0.86))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                }

                TextEditor(text: $text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(MoriColors.botanicalInk)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 74)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }
            .background(MoriColors.sanctuarySurface.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(MoriColors.botanicalLine.opacity(0.82), lineWidth: 1)
            )
        }
    }
}
