import SwiftUI
import FamilyControls

struct MoriBlockListsView: View {
    @State private var lists: [MoriBlockList] = []
    @State private var draft: MoriBlockList?
    @State private var errorMessage: String?
    private let store = MoriBlockListStore()

    var body: some View {
        MoriRootScrollScreen(
            title: "Block Lists",
            subtitle: "Keep a different app list for work, study, or time for yourself.",
            spacing: 22,
            backgroundVariant: .settings,
            headerStyle: .editorial
        ) {
            if lists.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(MoriL10n.display("A little space for each part of your day."))
                        .font(.system(.title3, design: .serif, weight: .medium))
                    Text(MoriL10n.display("Name a list, then choose the apps and websites you want to set aside."))
                        .font(.body)
                        .foregroundColor(MoriColors.botanicalMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 0) {
                    ForEach(lists) { list in
                        Button { draft = list } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(list.name).font(.headline)
                                    Text(blockListCountText(list.selectedCount))
                                        .font(.subheadline)
                                        .foregroundColor(MoriColors.botanicalMuted)
                                }
                                Spacer(minLength: 8)
                                Image(systemName: "chevron.right").font(.footnote)
                                    .accessibilityHidden(true)
                            }
                            .padding(16)
                            .frame(minHeight: 60)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("block-list-\(list.name)")
                        if list.id != lists.last?.id { Divider().padding(.horizontal, 16) }
                    }
                }
                .moriSanctuaryBox(cornerRadius: 20, padding: 0, tone: .paper, castsShadow: false)
            }

            Button { draft = MoriBlockList(name: "") } label: {
                Label(MoriL10n.display("Add Block List"), systemImage: "plus")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(MoriColors.botanicalInk.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("block-lists-add")
            .disabled(errorMessage != nil)

            Text(MoriL10n.display("Load a saved list when choosing apps for App Limits or a focus session. Changes here do not change lists already in use."))
                .font(.subheadline)
                .foregroundColor(MoriColors.botanicalMuted)
                .fixedSize(horizontal: false, vertical: true)

            if let errorMessage {
                Text(MoriL10n.display(errorMessage)).foregroundColor(MoriColors.botanicalClay)
                Button(MoriL10n.display("Try again"), action: reload)
            }
        }
        .foregroundColor(MoriColors.botanicalInk)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear(perform: reload)
        .navigationDestination(isPresented: Binding(
            get: { draft != nil },
            set: { if !$0 { draft = nil } }
        )) {
            if let draft {
                MoriBlockListEditor(list: draft, isNew: !lists.contains { $0.id == draft.id })
            }
        }
    }

    private func reload() {
        do {
            lists = try store.load()
            errorMessage = nil
        } catch {
            errorMessage = "Could not read your block lists. Your saved data has been kept."
        }
    }
}

private struct MoriBlockListEditor: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = AppLimitManager.shared
    @State var list: MoriBlockList
    let isNew: Bool
    @State private var pickerSelection = FamilyActivitySelection()
    @State private var showsPicker = false
    @State private var confirmsDelete = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            Form {
                Section {
                    TextField(MoriL10n.display("For example, Work or Study"), text: $list.name)
                        .accessibilityLabel(MoriL10n.display("List name"))
                        .accessibilityIdentifier("block-list-name")
                } header: { Text(MoriL10n.display("List name")) }
                .listRowBackground(MoriColors.sanctuaryPaper)

                Section {
                    Button {
                        pickerSelection = list.selection
                        showsPicker = true
                    } label: {
                        ViewThatFits(in: .horizontal) {
                            HStack {
                                Text(MoriL10n.display("Choose Apps")).fixedSize()
                                Spacer()
                                Text(blockListCountText(list.selectedCount)).fixedSize()
                                    .foregroundColor(MoriColors.botanicalMuted)
                            }
                            VStack(alignment: .leading, spacing: 5) {
                                Text(MoriL10n.display("Choose Apps"))
                                Text(blockListCountText(list.selectedCount))
                                    .foregroundColor(MoriColors.botanicalMuted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(minHeight: 44)
                    }
                    .disabled(!manager.settingsSnapshot.isAuthorized)
                    if !manager.settingsSnapshot.isAuthorized {
                        Button(MoriL10n.display("Allow Screen Time")) {
                            manager.perform(.requestAuthorization)
                        }
                    }
                } footer: {
                    Text(MoriL10n.display("Choose individual apps and websites inside categories. You can also save an empty list and add apps later."))
                    Text(MoriL10n.display("Load a saved list when choosing apps for App Limits or a focus session. Changes here do not change lists already in use."))
                }
                .listRowBackground(MoriColors.sanctuaryPaper)

                if let errorMessage {
                    Section { Text(MoriL10n.display(errorMessage)).foregroundColor(MoriColors.botanicalClay) }
                }
                if let message = manager.settingsSnapshot.lastErrorMessage {
                    Section { Text(MoriL10n.display(message)).foregroundColor(MoriColors.botanicalClay) }
                }

                if !isNew {
                    Section {
                        Button(MoriL10n.display("Delete Block List"), role: .destructive) { confirmsDelete = true }
                    }
                    .listRowBackground(MoriColors.sanctuaryPaper)
                }
            }
            .moriSettingsForm()
            .navigationTitle(MoriL10n.display(isNew ? "New Block List" : "Edit Block List"))
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(MoriL10n.display("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(MoriL10n.display("Save"), action: save)
                        .disabled(list.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("block-list-save")
                }
            }
            .navigationDestination(isPresented: $showsPicker) {
                VStack(spacing: 0) {
                    Text(MoriL10n.display("Choose individual apps and websites inside categories."))
                        .font(.subheadline)
                        .padding()
                    FamilyActivityPicker(selection: $pickerSelection)
                }
                .background(MoriColors.sanctuaryPaper)
                .navigationTitle(MoriL10n.display("Choose Apps"))
                .navigationBarBackButtonHidden(false)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(MoriL10n.display("Done")) {
                            list.selection = pickerSelection
                            list.selection.categoryTokens = []
                            showsPicker = false
                        }
                    }
                }
            }
            .alert(MoriL10n.display("Delete this block list?"), isPresented: $confirmsDelete) {
                Button(MoriL10n.display("Cancel"), role: .cancel) {}
                Button(MoriL10n.display("Delete"), role: .destructive) {
                    do {
                        try MoriBlockListStore().delete(id: list.id)
                        dismiss()
                    } catch { errorMessage = "Could not save your block lists. Please try again." }
                }
            } message: {
                Text(MoriL10n.display("Lists already in use will stay unchanged."))
            }
        }
        .tint(MoriColors.botanicalInk)
    }

    private func save() {
        do {
            try MoriBlockListStore().save(list)
            dismiss()
        } catch MoriBlockListStore.ValidationError.duplicateName {
            errorMessage = "A block list already has this name. Choose another name."
        } catch {
            errorMessage = "Could not save your block lists. Please try again."
        }
    }
}

func blockListCountText(_ count: Int) -> String {
    count == 0 ? MoriL10n.display("No apps selected") : MoriL10n.string(
        "screen_time.status.selected_count", defaultValue: "%d selected", arguments: [count]
    )
}
