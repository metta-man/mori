import SwiftUI

struct ScreenTimeFeatureSettingsRow: View {
    let summary: MoriScreenTimeProfileSummary
    let onEnabledChange: (Bool) -> Void
    let onUsesDefaultSelectionChange: (Bool) -> Void
    let onEditDefaultList: () -> Void
    let onEditCustomList: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: enabledBinding) {
                screenTimeSupportLabel(summary.feature.title, icon: summary.feature.icon)
                    .font(.system(size: 15, weight: .semibold))
            }

            Text(summary.feature.subtitle)
                .font(.footnote)
                .foregroundColor(MoriColors.botanicalMuted)

            if summary.isEnabled {
                Picker("App list", selection: sourceBinding) {
                    ForEach(MoriScreenTimeBlockListSource.allCases) { source in
                        Text(source.title).tag(source)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Text(MoriL10n.display(sourceStatusText))
                        .font(.footnote)
                        .foregroundColor(MoriColors.botanicalMuted)

                    Spacer()

                    Button(editButtonTitle) {
                        if summary.usesDefaultSelection {
                            onEditDefaultList()
                        } else {
                            onEditCustomList()
                        }
                    }
                    .font(.footnote.weight(.semibold))
                }
            }
        }
        .tint(MoriColors.botanicalInk)
        .padding(.vertical, 4)
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { summary.isEnabled },
            set: onEnabledChange
        )
    }

    private var sourceBinding: Binding<MoriScreenTimeBlockListSource> {
        Binding(
            get: { summary.usesDefaultSelection ? .defaultList : .customList },
            set: { source in
                onUsesDefaultSelectionChange(source == .defaultList)
            }
        )
    }

    private var sourceStatusText: String {
        if summary.usesDefaultSelection {
            guard summary.effectiveSelectedCount > 0 else {
                return MoriL10n.string("screen_time.source.default_empty.no_period", defaultValue: "Default app list is empty")
            }
            if !summary.displayNames.isEmpty {
                return MoriL10n.string("screen_time.source.in_default.no_period", defaultValue: "%@ in default app list", arguments: [summary.statusText])
            }
            return MoriL10n.string("screen_time.source.selected_in_default.no_period", defaultValue: "%d selected in default app list", arguments: [summary.effectiveSelectedCount])
        }

        guard summary.customSelectedCount > 0 else {
            return MoriL10n.string("screen_time.source.custom_empty.no_period", defaultValue: "Custom list is empty")
        }
        if !summary.displayNames.isEmpty {
            return MoriL10n.string("screen_time.source.in_custom.no_period", defaultValue: "%@ in custom list", arguments: [summary.statusText])
        }
        return MoriL10n.string("screen_time.source.selected_in_custom.no_period", defaultValue: "%d selected in custom list", arguments: [summary.customSelectedCount])
    }

    private var editButtonTitle: String {
        summary.usesDefaultSelection
            ? MoriL10n.string("screen_time.edit_default", defaultValue: "Edit Default")
            : MoriL10n.string("screen_time.edit_custom", defaultValue: "Edit Custom")
    }
}

private func screenTimeSupportLabel(_ title: String, icon: MoriBitmapIcon) -> some View {
    HStack(spacing: 8) {
        MoriBitmapIconImage(icon: icon, size: 16, opacity: 0.84)

        Text(MoriL10n.display(title))
    }
}

struct MoriBeforeFeedShortcutGuideSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private let steps = [
        "Open the Automation tab and tap +",
        "Choose App",
        "Select your feed apps",
        "Set the trigger to Is Opened",
        "Choose Run Immediately",
        "Tap Add Action",
        "Search Mori",
        "Choose Start Before Feed Reset",
        "Tap Done"
    ]

    var body: some View {
        NavigationStack {
            MoriPaperBackground(variant: .appLimit) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        MoriPageHeader(
                            eyebrow: MoriL10n.display("Shortcuts"),
                            title: MoriL10n.display("Optional automation"),
                            subtitle: MoriL10n.display("Use this only if you want Shortcuts to pop Mori open before selected feeds.")
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            screenTimeSupportLabel("Screen Time gate is smoother", icon: .timer)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(MoriColors.botanicalInk)

                            Text(MoriL10n.display("The Screen Time gate opens selected feed apps after the reset. A Shortcut automation can open Mori, but iOS does not tell Mori which app triggered it, so you may need to switch back manually."))
                                .font(.footnote)
                                .foregroundColor(MoriColors.botanicalMuted)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(MoriL10n.display("Use Mori's Start Before Feed Reset action. Do not use Shortcuts' plain Open App action, because that would open Mori even while your feed window is still active."))
                                .font(.footnote)
                                .foregroundColor(MoriColors.botanicalMuted)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(MoriL10n.display("Do not use Open URL with mori://; iOS may block that launch from personal automations."))
                                .font(.footnote)
                                .foregroundColor(MoriColors.botanicalMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .background(MoriColors.botanicalPaperDeep.opacity(0.58))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(MoriColors.botanicalSurface)
                                        .frame(width: 26, height: 26)
                                        .background(MoriColors.botanicalInk)
                                        .clipShape(Circle())

                                    Text(MoriL10n.display(step))
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(MoriColors.botanicalInk)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(16)
                        .background(MoriColors.botanicalSurface.opacity(0.82))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        VStack(alignment: .leading, spacing: 8) {
                            screenTimeSupportLabel("Use the same apps you selected as Feed apps in Mori.", icon: .timer)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(MoriColors.botanicalInk)

                            Text(MoriL10n.display("Apple requires each personal automation to be created in Shortcuts. Mori can open Shortcuts, but cannot preselect apps, create the automation, or return to the app that launched it."))
                                .font(.footnote)
                                .foregroundColor(MoriColors.botanicalMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .background(MoriColors.botanicalPaperDeep.opacity(0.58))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        Button {
                            if let url = URL(string: "shortcuts://") {
                                openURL(url)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                MoriBitmapIconImage(icon: .refresh, size: 16, opacity: 0.94)
                                    .frame(width: 24, height: 24)
                                    .background(MoriColors.sanctuarySurface.opacity(0.86))
                                    .clipShape(Circle())

                                Text(MoriL10n.display("Open Shortcuts"))
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
                    .padding(.top, 20)
                    .padding(.bottom, 34)
                }
            }
            .navigationTitle(MoriL10n.display("Auto-open"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(MoriL10n.display("Done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}
