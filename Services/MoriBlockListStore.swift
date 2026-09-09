import Foundation
import FamilyControls

struct MoriBlockList: Codable, Identifiable {
    var id = UUID()
    var name: String
    var selection = FamilyActivitySelection()

    var selectedCount: Int {
        selection.applicationTokens.count + selection.webDomainTokens.count
    }
}

/// Reusable snapshots, deliberately independent of the currently applied shields.
struct MoriBlockListStore {
    static let storageKey = "mori_saved_block_lists_v1"
    let defaults: UserDefaults

    init(defaults: UserDefaults = MoriAppGroup.defaults) {
        self.defaults = defaults
    }

    func load() throws -> [MoriBlockList] {
        guard let data = defaults.data(forKey: Self.storageKey) else { return [] }
        return try JSONDecoder().decode([MoriBlockList].self, from: data)
    }

    func save(_ draft: MoriBlockList) throws {
        var list = draft
        list.name = list.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !list.name.isEmpty else { throw ValidationError.emptyName }
        // Match Mori's existing supported selection contract: apps and websites.
        list.selection.categoryTokens = []
        var lists = try load()
        guard !lists.contains(where: {
            $0.id != list.id && $0.name.caseInsensitiveCompare(list.name) == .orderedSame
        }) else { throw ValidationError.duplicateName }
        if let index = lists.firstIndex(where: { $0.id == list.id }) {
            lists[index] = list
        } else {
            lists.append(list)
        }
        try persist(lists)
    }

    func delete(id: UUID) throws {
        try persist(load().filter { $0.id != id })
    }

    private func persist(_ lists: [MoriBlockList]) throws {
        defaults.set(try JSONEncoder().encode(lists), forKey: Self.storageKey)
    }

    enum ValidationError: Error {
        case emptyName
        case duplicateName
    }
}
