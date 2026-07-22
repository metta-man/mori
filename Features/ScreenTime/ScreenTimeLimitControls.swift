import SwiftUI
import FamilyControls

struct ScreenTimeLimitControls: View {
    let contextTitle: String
    let feature: MoriScreenTimeFeature

    @Environment(\.moriOpenRoute) private var openRoute
    @StateObject private var appLimitManager = AppLimitManager.shared
    @State private var pickerTarget: AppLimitSelectionTarget?
    @State private var pickerSelection = FamilyActivitySelection()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if !presentation.isAuthorized {
                MoriPermissionState(
                    title: "Allow Screen Time",
                    message: "Required before this session can limit selected apps. Mori asks only after you tap Allow.",
                    buttonTitle: "Allow Screen Time",
                    buttonAction: requestScreenTimeAuthorization
                )
            }

            if presentation.isAuthorized {
                appLimitControls
            }

            Button(action: openAppLimits) {
                HStack(spacing: 6) {
                    MoriBitmapIconImage(icon: .settings, size: 15, opacity: 0.84)

                    Text(MoriL10n.display("All App Limits"))
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(MoriColors.botanicalInk)
                .frame(maxWidth: .infinity, minHeight: MoriV2Layout.minimumHitTarget)
                .background(MoriColors.botanicalInk.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            if let message = presentation.lastErrorMessage {
                Text(MoriL10n.display(message))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.botanicalClay)
            }
        }
        .padding(14)
        .background(MoriColors.botanicalPaperDeep.opacity(0.52))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .task {
            reconcileAppLimitState()
        }
        .sheet(item: $pickerTarget) { target in
            ScreenTimeSettingsPickerSheet(
                title: target.inlineTitle,
                selection: $pickerSelection,
                onDone: { finishPicker(target) }
            )
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            MoriBitmapIconImage(icon: summary.isEnabled && summary.hasEffectiveSelection ? .leaf : .timer, size: 18, opacity: 0.86)
                .frame(width: 36, height: 36)
                .background(MoriColors.sanctuarySurface.opacity(0.74))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(MoriL10n.display("App Limit"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.botanicalInk)

                Text(MoriL10n.display(statusText))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private var appLimitControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: enabledBinding) {
                Text(MoriL10n.string("screen_time.limit_context", defaultValue: "Limit %@", arguments: [contextTitle]))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)
            }
            .tint(MoriColors.botanicalInk)
            .frame(minHeight: MoriV2Layout.minimumHitTarget)

            if summary.isEnabled {
                Picker(MoriL10n.display("App list"), selection: sourceBinding) {
                    ForEach(MoriScreenTimeBlockListSource.allCases) { source in
                        Text(source.title).tag(source)
                    }
                }
                .pickerStyle(.segmented)
                .frame(minHeight: MoriV2Layout.minimumHitTarget)

                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(MoriL10n.display(sourceTitle))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(MoriColors.botanicalInk)

                        Text(MoriL10n.display(sourceStatusText))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(MoriColors.botanicalMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Button {
                        showPicker(currentSource == .defaultList ? .defaultList : .feature(feature))
                    } label: {
                        HStack(spacing: 5) {
                            MoriBitmapIconImage(icon: currentSource.icon, size: 13, opacity: 0.82)

                            Text(MoriL10n.display(selectionButtonTitle))
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalInk)
                        .padding(.horizontal, 11)
                        .frame(minHeight: MoriV2Layout.minimumHitTarget)
                        .background(MoriColors.botanicalInk.opacity(0.08))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(MoriColors.botanicalSurface.opacity(0.62))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private var presentation: ScreenTimeInlineLimitPresentation {
        ScreenTimeInlineLimitPresentation(
            appLimitManager: appLimitManager,
            contextTitle: contextTitle,
            feature: feature
        )
    }

    private var summary: MoriScreenTimeProfileSummary {
        presentation.summary
    }

    private var currentSource: MoriScreenTimeBlockListSource {
        presentation.currentSource
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { summary.isEnabled },
            set: { isEnabled in
                appLimitManager.perform(.setFeatureEnabled(isEnabled, feature))
            }
        )
    }

    private var sourceBinding: Binding<MoriScreenTimeBlockListSource> {
        Binding(
            get: { currentSource },
            set: { source in
                appLimitManager.perform(
                    .setFeatureUsesDefaultSelection(source == .defaultList, feature)
                )
            }
        )
    }

    private var statusText: String {
        presentation.statusText
    }

    private var sourceTitle: String {
        presentation.sourceTitle
    }

    private var sourceStatusText: String {
        presentation.sourceStatusText
    }

    private var selectionButtonTitle: String {
        presentation.selectionButtonTitle
    }

    private func requestScreenTimeAuthorization() {
        appLimitManager.perform(.requestAuthorization)
    }

    private func reconcileAppLimitState() {
        appLimitManager.perform(.reconcileAppLimitState)
    }

    private func showPicker(_ target: AppLimitSelectionTarget) {
        let draft = appLimitManager.selectionDraft(for: target)
        pickerSelection = draft.selection
        pickerTarget = draft.target
    }

    private func openAppLimits() {
        openRoute(.appLimits)
    }

    private func finishPicker(_ target: AppLimitSelectionTarget) {
        appLimitManager.perform(
            .commitSelectionDraft(
                AppLimitSelectionDraft(
                    target: target,
                    selection: pickerSelection
                )
            )
        )
    }
}
