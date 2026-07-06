import SwiftUI

struct PulseTopicPickerCard: View {
    @ObservedObject var clarityStore: MoriClarityStore
    @Binding var customTopic: String
    @Binding var selectedCustomTopicIcon: MoriCustomPulseTopicIcon
    @State private var showsTopicLibrary = false

    private var trimmedCustomTopic: String {
        customTopic.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Manage Topics",
                subtitle: MoriL10n.string(
                    clarityStore.activeTopicLabels.count == 1 ? "pulse.topics.subtitle_one" : "pulse.topics.subtitle_many",
                    defaultValue: clarityStore.activeTopicLabels.count == 1
                        ? "%d active Pulse · up to %d. Extra topics wait in the queue."
                        : "%d active Pulses · up to %d. Extra topics wait in the queue.",
                    arguments: [clarityStore.activeTopicLabels.count, clarityStore.maxActiveTopicCount]
                )
            )

            activeTopics
            queuedTopics
            topicLibraryToggle

            if showsTopicLibrary {
                topicLibrary
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    @ViewBuilder
    private var activeTopics: some View {
        if !clarityStore.activeTopicLabels.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(MoriL10n.display("Active now"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalMuted)

                FlowLayout(spacing: 8) {
                    ForEach(clarityStore.activeTopicLabels, id: \.self) { topic in
                        MoriPill(
                            title: topic,
                            icon: clarityStore.icon(forTopicLabel: topic),
                            isSelected: true,
                            tint: MoriColors.botanicalMoss
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var queuedTopics: some View {
        if !clarityStore.queuedTopicLabels.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(MoriL10n.display("Queued"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalMuted)

                FlowLayout(spacing: 8) {
                    ForEach(clarityStore.queuedTopicLabels, id: \.self) { topic in
                        Button {
                            clarityStore.promoteTopic(topic)
                        } label: {
                            MoriPill(
                                title: topic,
                                icon: .refresh,
                                tint: MoriColors.botanicalMist
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(MoriL10n.string(
                            "pulse.topic.make_active_accessibility",
                            defaultValue: "Make %@ an active Pulse",
                            arguments: [topic]
                        ))
                    }
                }
            }
        }
    }

    private var topicLibraryToggle: some View {
        Button {
            withAnimation(.snappy(duration: 0.22)) {
                showsTopicLibrary.toggle()
            }
        } label: {
            HStack(alignment: .center, spacing: 10) {
                MoriBitmapIconImage(icon: .settings, size: 16, opacity: 0.82)
                    .frame(width: 30, height: 30)
                    .background(MoriColors.sanctuarySurface.opacity(0.78))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(showsTopicLibrary ? MoriL10n.display("Hide topic list") : MoriL10n.display("Edit topic list"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalInk)

                    Text(MoriL10n.display("Choose defaults or add one custom Pulse."))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                MoriBitmapIconImage(icon: .chevron, size: 12, opacity: 0.58)
                    .rotationEffect(.degrees(showsTopicLibrary ? -90 : 90))
            }
            .padding(10)
            .background(MoriColors.botanicalPaperDeep.opacity(0.48))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(showsTopicLibrary ? MoriL10n.display("Hide topic list") : MoriL10n.display("Edit topic list"))
    }

    private var topicLibrary: some View {
        VStack(alignment: .leading, spacing: 12) {
            defaultTopics
            customTopicEntry
            customTopics
        }
    }

    private var defaultTopics: some View {
        FlowLayout(spacing: 8) {
            ForEach(PulseTopic.allCases.filter { $0 != .custom }) { topic in
                Button {
                    clarityStore.toggleTopic(topic)
                } label: {
                    MoriPill(
                        title: topic.title,
                        icon: topic.icon,
                        isSelected: clarityStore.selectedTopics.contains(topic),
                        tint: MoriColors.botanicalMoss
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var customTopicEntry: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(MoriCustomPulseTopicIcon.allCases) { icon in
                    Button {
                        selectedCustomTopicIcon = icon
                    } label: {
                        HStack(spacing: 8) {
                            MoriBitmapIconImage(icon: icon.icon, size: 16, opacity: 0.86)

                            Text(icon.menuTitle)
                        }
                    }
                }
            } label: {
                MoriBitmapIconImage(icon: selectedCustomTopicIcon.icon, size: 18, opacity: 0.88)
                    .frame(width: 40, height: 40)
                    .background(MoriColors.botanicalInk.opacity(0.08))
                    .clipShape(Circle())
            }

            TextField(MoriL10n.display("Add custom topic"), text: $customTopic)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(MoriColors.botanicalInk)
                .textInputAutocapitalization(.words)
                .padding(12)
                .background(MoriColors.botanicalPaperDeep.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button(action: addCustomTopic) {
                MoriBitmapIconImage(icon: .plus, size: 16, opacity: trimmedCustomTopic.isEmpty ? 0.38 : 0.94)
                    .frame(width: 23, height: 23)
                    .background(trimmedCustomTopic.isEmpty ? Color.clear : MoriColors.sanctuarySurface.opacity(0.86))
                    .clipShape(Circle())
                    .frame(width: 40, height: 40)
                    .background(trimmedCustomTopic.isEmpty ? MoriColors.botanicalMuted.opacity(0.35) : MoriColors.botanicalInk)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(trimmedCustomTopic.isEmpty)
        }
    }

    @ViewBuilder
    private var customTopics: some View {
        if !clarityStore.customTopics.isEmpty {
            FlowLayout(spacing: 8) {
                ForEach(clarityStore.customTopics, id: \.self) { topic in
                    Menu {
                        Button(role: .destructive) {
                            clarityStore.removeCustomTopic(topic)
                        } label: {
                            HStack(spacing: 8) {
                                MoriBitmapIconImage(icon: .minus, size: 16, opacity: 0.86)

                                Text(MoriL10n.display("Remove topic"))
                            }
                        }
                    } label: {
                        MoriPill(
                            title: topic,
                            icon: clarityStore.icon(forCustomTopic: topic),
                            isSelected: true,
                            tint: MoriColors.botanicalMoss
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(MoriL10n.string(
                        "pulse.topic.remove_accessibility",
                        defaultValue: "Remove %@",
                        arguments: [topic]
                    ))
                }
            }
        }
    }

    private func addCustomTopic() {
        clarityStore.addCustomTopic(trimmedCustomTopic, icon: selectedCustomTopicIcon)
        customTopic = ""
    }
}

private extension MoriCustomPulseTopicIcon {
    var menuTitle: String {
        switch self {
        case .leaf: return MoriL10n.display("Leaf")
        case .sparkles: return MoriL10n.display("Signal")
        case .brain: return MoriL10n.display("Mind")
        case .heart: return MoriL10n.display("Heart")
        case .book: return MoriL10n.display("Read")
        case .briefcase: return MoriL10n.display("Work")
        case .chart: return MoriL10n.display("Market")
        case .paint: return MoriL10n.display("Create")
        case .globe: return MoriL10n.display("World")
        case .location: return MoriL10n.display("Local")
        case .tag: return MoriL10n.display("Tag")
        case .star: return MoriL10n.display("Star")
        }
    }
}
