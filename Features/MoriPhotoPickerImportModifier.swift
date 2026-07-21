import Foundation
import PhotosUI
import SwiftUI

extension View {
    func moriPhotoPickerImporter(
        selectedItems: Binding<[PhotosPickerItem]>,
        onImport: @escaping (Data) -> Void
    ) -> some View {
        modifier(
            MoriPhotoPickerImportModifier(
                selectedItems: selectedItems,
                onImport: onImport
            )
        )
    }
}

private struct MoriPhotoPickerImportModifier: ViewModifier {
    @Binding var selectedItems: [PhotosPickerItem]
    let onImport: (Data) -> Void
    @State private var importTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .moriOnChange(of: selectedItems) { newItems in
                importPhotos(from: newItems)
            }
            .onDisappear {
                importTask?.cancel()
            }
    }

    private func importPhotos(from items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }

        importTask?.cancel()
        importTask = Task {
            for item in items {
                guard !Task.isCancelled else { return }

                if let data = try? await item.loadTransferable(type: Data.self) {
                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        onImport(data)
                    }
                }
            }

            guard !Task.isCancelled else { return }

            await MainActor.run {
                selectedItems = []
            }
        }
    }
}
