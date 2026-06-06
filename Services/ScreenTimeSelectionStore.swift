import Foundation
import FamilyControls

struct ScreenTimeSelectionStore {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = MoriAppGroup.defaults) {
        self.defaults = defaults
    }

    func loadSelection() -> FamilyActivitySelection {
        guard let data = defaults.data(forKey: MoriScreenTimeShared.selectionKey),
              let selection = try? decoder.decode(FamilyActivitySelection.self, from: data)
        else {
            return FamilyActivitySelection()
        }
        return selection
    }

    func saveSelection(_ selection: FamilyActivitySelection) {
        guard let data = try? encoder.encode(selection) else { return }
        defaults.set(data, forKey: MoriScreenTimeShared.selectionKey)
    }

    var hasSelection: Bool {
        let selection = loadSelection()
        return !selection.applicationTokens.isEmpty ||
            !selection.categoryTokens.isEmpty ||
            !selection.webDomainTokens.isEmpty
    }

    var selectedCount: Int {
        let selection = loadSelection()
        return selection.applicationTokens.count +
            selection.categoryTokens.count +
            selection.webDomainTokens.count
    }
}
