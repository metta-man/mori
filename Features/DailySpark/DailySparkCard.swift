import SwiftUI

struct DailySparkCard: View {
    @ObservedObject var store: DailySparkStore
    var onSaved: ((DailySparkEntry) -> Void)?

    @State private var focus = ""
    @State private var desiredFeeling = ""
    @State private var thingToAvoid = ""
    @State private var ifThenPlan = ""
    @State private var isEditing = false

    private let feelingOptions = ["Clear", "Steady", "Brave", "Light", "Connected", "Useful"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if let entry = store.todayEntry, !isEditing {
                savedSpark(entry)
            } else {
                editor
            }
        }
        .padding(16)
        .background(MoriColors.moriDark.opacity(0.52))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(MoriColors.moriGold.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear(perform: loadToday)
        .onReceive(NotificationCenter.default.publisher(for: .dailySparkDataDidChange)) { _ in
            loadToday()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkle.magnifyingglass")
                .foregroundColor(MoriColors.moriGold)

            VStack(alignment: .leading, spacing: 2) {
                Text("Daily Spark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.moriCream)

                Text("Set the lens for today.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.moriCreamMuted)
            }

            Spacer()

            if store.todayEntry != nil {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        isEditing.toggle()
                    }
                } label: {
                    Image(systemName: isEditing ? "xmark" : "pencil")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MoriColors.moriGold)
                        .frame(width: 32, height: 32)
                        .background(MoriColors.moriDarkElevated)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isEditing ? "Cancel editing Daily Spark" : "Edit Daily Spark")
            }
        }
    }

    private func savedSpark(_ entry: DailySparkEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SparkSummaryRow(symbol: "target", title: "Today's Focus", value: entry.focus)
            SparkSummaryRow(symbol: "heart", title: "I want to feel", value: entry.desiredFeeling)
            SparkSummaryRow(symbol: "hand.raised", title: "Avoid", value: entry.thingToAvoid)

            if !entry.ifThenPlan.isEmpty {
                Text(entry.ifThenPlan)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(MoriColors.moriCream.opacity(0.78))
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(MoriColors.moriDarkElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Label("Saved to Journal", systemImage: "book.closed")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(MoriColors.moriGold)
                .padding(.top, 2)
        }
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 14) {
            DailySparkField(
                title: "Today's Focus",
                placeholder: "One thing that deserves my best attention",
                text: $focus,
                symbolName: "target"
            )

            VStack(alignment: .leading, spacing: 10) {
                DailySparkField(
                    title: "Today I want to feel",
                    placeholder: "Clear, steady, brave...",
                    text: $desiredFeeling,
                    symbolName: "heart"
                )

                FlowLayout(spacing: 8) {
                    ForEach(feelingOptions, id: \.self) { feeling in
                        Button {
                            desiredFeeling = feeling
                        } label: {
                            Text(feeling)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(desiredFeeling == feeling ? MoriColors.moriDark : MoriColors.moriCreamMuted)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(desiredFeeling == feeling ? MoriColors.moriGold : MoriColors.moriDarkElevated)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            DailySparkField(
                title: "One thing to avoid",
                placeholder: "The drift that usually steals the day",
                text: $thingToAvoid,
                symbolName: "hand.raised"
            )

            DailySparkField(
                title: "If-then plan",
                placeholder: "If I notice it, I will pause and come back.",
                text: $ifThenPlan,
                symbolName: "arrow.triangle.turn.up.right.diamond"
            )

            Button {
                saveSpark()
            } label: {
                Label("Save Daily Spark", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(canSave ? MoriColors.moriDark : MoriColors.moriCreamMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(canSave ? MoriColors.moriGold : MoriColors.moriDarkElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
            .accessibilityLabel("Save Daily Spark")
        }
    }

    private var canSave: Bool {
        !focus.trimmedForUI.isEmpty &&
        !desiredFeeling.trimmedForUI.isEmpty &&
        !thingToAvoid.trimmedForUI.isEmpty
    }

    private func loadToday() {
        guard let entry = store.todayEntry else {
            if !isEditing {
                focus = ""
                desiredFeeling = ""
                thingToAvoid = ""
                ifThenPlan = ""
            }
            return
        }

        focus = entry.focus
        desiredFeeling = entry.desiredFeeling
        thingToAvoid = entry.thingToAvoid
        ifThenPlan = entry.ifThenPlan
    }

    private func saveSpark() {
        let saved = store.saveToday(
            focus: focus,
            desiredFeeling: desiredFeeling,
            thingToAvoid: thingToAvoid,
            ifThenPlan: ifThenPlan
        )

        guard let saved else { return }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            isEditing = false
        }

        onSaved?(saved)
    }
}

private struct DailySparkField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let symbolName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: symbolName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(MoriColors.moriCreamMuted)

            TextField(placeholder, text: $text, axis: .vertical)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(MoriColors.moriCream)
                .lineLimit(1...3)
                .padding(11)
                .background(MoriColors.moriDarkElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .submitLabel(.next)
        }
    }
}

private struct SparkSummaryRow: View {
    let symbol: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MoriColors.moriGold)
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(MoriColors.moriCreamMuted)

                Text(value)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(MoriColors.moriCream)
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
    ZStack {
        MoriColors.moriDark.ignoresSafeArea()
        DailySparkCard(store: .shared)
            .padding()
    }
}
