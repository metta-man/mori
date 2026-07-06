import Foundation
import PhotosUI
import SwiftUI

extension View {
    func gratitudeEditorLifecycle(
        entryContent: String,
        characterCountStatus: Binding<CharacterCountStatus>,
        selectedPhotoItems: Binding<[PhotosPickerItem]>,
        onAddPhoto: @escaping (Data) -> Void
    ) -> some View {
        modifier(
            GratitudeEditorLifecycleModifier(
                entryContent: entryContent,
                characterCountStatus: characterCountStatus
            )
        )
        .moriPhotoPickerImporter(
            selectedItems: selectedPhotoItems,
            onImport: onAddPhoto
        )
    }

    func gratitudeJournalLifecycle(
        scenePhase: ScenePhase,
        onPrepare: @escaping () -> Void,
        onCleanup: @escaping () -> Void,
        onReloadJournal: @escaping () -> Void,
        onReloadHabitData: @escaping () -> Void
    ) -> some View {
        modifier(
            GratitudeJournalLifecycleModifier(
                scenePhase: scenePhase,
                onPrepare: onPrepare,
                onCleanup: onCleanup,
                onReloadJournal: onReloadJournal,
                onReloadHabitData: onReloadHabitData
            )
        )
    }

    func gratitudeJournalToast(
        isPresented: Binding<Bool>,
        message: String,
        type: ToastType
    ) -> some View {
        modifier(
            GratitudeJournalToastModifier(
                isPresented: isPresented,
                message: message,
                type: type
            )
        )
    }

    func gratitudeHistoryLifecycle(
        onReload: @escaping () -> Void
    ) -> some View {
        modifier(GratitudeHistoryLifecycleModifier(onReload: onReload))
    }
}

private struct GratitudeEditorLifecycleModifier: ViewModifier {
    let entryContent: String
    @Binding var characterCountStatus: CharacterCountStatus

    func body(content: Content) -> some View {
        content
            .onChange(of: entryContent) { newValue in
                characterCountStatus = CharacterCountStatus.status(for: newValue.count)
            }
    }
}

private struct GratitudeJournalLifecycleModifier: ViewModifier {
    let scenePhase: ScenePhase
    let onPrepare: () -> Void
    let onCleanup: () -> Void
    let onReloadJournal: () -> Void
    let onReloadHabitData: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear(perform: onPrepare)
            .onDisappear(perform: onCleanup)
            .onChange(of: scenePhase) { newPhase in
                guard newPhase == .active else { return }
                onReloadJournal()
            }
            .onMoriDataChange(.significantTime, perform: onReloadJournal)
            .onMoriDataChange(.gratitude, perform: onReloadJournal)
            .onMoriDataChange(.habit, perform: onReloadHabitData)
    }
}

private struct GratitudeJournalToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let type: ToastType

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if isPresented {
                    GratitudeJournalToastView(message: message, type: type)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear(perform: dismissAfterDelay)
                }
            }
    }

    private func dismissAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isPresented = false
            }
        }
    }
}

private struct GratitudeHistoryLifecycleModifier: ViewModifier {
    let onReload: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear(perform: onReload)
            .onMoriDataChange(.significantTime, perform: onReload)
            .onMoriDataChange(.gratitude, perform: onReload)
            .onMoriDataChange(.dailySpark, perform: onReload)
            .onMoriDataChange(.habit, perform: onReload)
    }
}
