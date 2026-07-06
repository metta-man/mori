import Foundation
import Combine

@MainActor
final class MoriFactorTagStore: ObservableObject {
    static let shared = MoriFactorTagStore()

    @Published private(set) var todayTags: [MoriFactorTag] = []

    private let overrideStore: MoriRecoveryTagOverrideStore

    private init(overrideStore: MoriRecoveryTagOverrideStore = MoriRecoveryTagOverrideStore()) {
        self.overrideStore = overrideStore
    }

    func refresh(date: Date = Date()) {
        todayTags = tags(for: date)
    }

    func tags(for date: Date) -> [MoriFactorTag] {
        let autoTags = MoriLocalTaggingEngine.automaticTags(for: date)
        return applyOverrides(to: autoTags, date: date)
    }

    func hide(_ tag: MoriFactorTag, date: Date = Date()) {
        var overrides = loadOverrides()
        var day = overrides[MoriDateKey.value(for: date)] ?? MoriFactorTagOverride()
        day.hidden.insert(tag.id)
        day.added.remove(tag.id)
        overrides[MoriDateKey.value(for: date)] = day
        saveOverrides(overrides)
        refresh(date: date)
    }

    func add(_ id: MoriFactorTagID, date: Date = Date()) {
        var overrides = loadOverrides()
        var day = overrides[MoriDateKey.value(for: date)] ?? MoriFactorTagOverride()
        day.added.insert(id)
        day.hidden.remove(id)
        overrides[MoriDateKey.value(for: date)] = day
        saveOverrides(overrides)
        refresh(date: date)
    }

    private func applyOverrides(to tags: [MoriFactorTag], date: Date) -> [MoriFactorTag] {
        let override = loadOverrides()[MoriDateKey.value(for: date)] ?? MoriFactorTagOverride()
        var merged: [MoriFactorTagID: MoriFactorTag] = [:]

        for tag in tags where !override.hidden.contains(tag.id) {
            if let existing = merged[tag.id] {
                merged[tag.id] = existing.confidence >= tag.confidence ? existing : tag
            } else {
                merged[tag.id] = tag
            }
        }

        for id in override.added {
            merged[id] = MoriFactorTag(id: id, confidence: 1, sourceKind: .user, userEdited: true)
        }

        return merged.values.sorted { lhs, rhs in
            if lhs.sourceKind == .user && rhs.sourceKind != .user { return true }
            if lhs.sourceKind != .user && rhs.sourceKind == .user { return false }
            if lhs.confidence != rhs.confidence { return lhs.confidence > rhs.confidence }
            return lhs.id.label < rhs.id.label
        }
    }

    private func loadOverrides() -> [String: MoriFactorTagOverride] {
        overrideStore.loadOverrides()
    }

    private func saveOverrides(_ overrides: [String: MoriFactorTagOverride]) {
        overrideStore.saveOverrides(overrides)
    }
}
