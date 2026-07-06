import Foundation
import NaturalLanguage

@MainActor
enum MoriLocalTaggingEngine {
    static func automaticTags(for date: Date) -> [MoriFactorTag] {
        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? date
        let habitEntries = HabitDataManager.shared.getEntries(from: dayStart, to: dayStart)
        let journalEntries = GratitudeEntryStore.live.loadEntries().filter { entry in
            entry.date >= dayStart && entry.date < dayEnd
        }
        let actions = MoriClarityStore.shared.actions(for: date)
        let recovery = MoriRecoveryHistoryStore.shared.indicator(for: date)

        var tags: [MoriFactorTag] = []

        for entry in habitEntries {
            let text = [
                entry.note,
                entry.trigger,
                entry.thought,
                entry.feeling,
                entry.responsePlan
            ].compactMap { $0 }.joined(separator: " ")
            tags.append(contentsOf: tagsFromText(text, sourceID: entry.id.uuidString))

            if entry.tone == .negative {
                tags.append(MoriFactorTag(id: .emotionalStrain, confidence: 0.68, sourceKind: .auto, sourceID: entry.id.uuidString))
            }
        }

        for entry in journalEntries {
            tags.append(contentsOf: tagsFromText(entry.displayContent, sourceID: entry.id.uuidString))
        }

        for action in actions {
            switch action.kind {
            case .breathingSession:
                tags.append(MoriFactorTag(id: .breathingPractice, confidence: 1, sourceKind: .practice, sourceID: action.id.uuidString))
            case .settleSession:
                tags.append(MoriFactorTag(id: .meditation, confidence: 0.92, sourceKind: .practice, sourceID: action.id.uuidString))
            case .replacementAction:
                tags.append(MoriFactorTag(id: .walk, confidence: 0.82, sourceKind: .practice, sourceID: action.id.uuidString))
            case .urgeCheckIn, .screenTimeThresholdReached:
                tags.append(MoriFactorTag(id: .screenTimePressure, confidence: 0.80, sourceKind: .practice, sourceID: action.id.uuidString))
            default:
                break
            }
        }

        if let recovery {
            if recovery.sleepMinutes.map({ $0 < 360 }) == true {
                tags.append(MoriFactorTag(id: .poorSleep, confidence: 0.86, sourceKind: .health))
            }
            if recovery.highIntensityMinutes.map({ $0 >= 10 }) == true || recovery.trainingLoadPoints > 45 {
                tags.append(MoriFactorTag(id: .hardWorkout, confidence: 0.88, sourceKind: .health))
            }
            if recovery.bodyLoadScore >= 1.5 {
                tags.append(MoriFactorTag(id: .bodyLoad, confidence: 0.84, sourceKind: .health))
            }
        }

        return dedup(tags)
    }

    private static func tagsFromText(_ text: String, sourceID: String?) -> [MoriFactorTag] {
        let lowered = text.lowercased()
        guard !lowered.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }

        var tags: [MoriFactorTag] = []
        for id in MoriFactorTagID.allCases {
            guard id.keywords.contains(where: { lowered.contains($0.lowercased()) }) else { continue }
            tags.append(MoriFactorTag(id: id, confidence: 0.76, sourceKind: .auto, sourceID: sourceID))
        }

        if sentimentScore(for: text) < -0.35 {
            tags.append(MoriFactorTag(id: .emotionalStrain, confidence: 0.62, sourceKind: .auto, sourceID: sourceID))
        }

        return tags
    }

    private static func sentimentScore(for text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        let range = text.startIndex..<text.endIndex
        let sentiment = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore).0
        if let raw = sentiment?.rawValue, let value = Double(raw) {
            return value
        }

        var score = 0.0
        tagger.enumerateTags(in: range, unit: .sentence, scheme: .sentimentScore) { tag, _ in
            if let raw = tag?.rawValue, let value = Double(raw) {
                score += value
            }
            return true
        }
        return score
    }

    private static func dedup(_ tags: [MoriFactorTag]) -> [MoriFactorTag] {
        var best: [MoriFactorTagID: MoriFactorTag] = [:]
        for tag in tags {
            if let existing = best[tag.id] {
                best[tag.id] = existing.confidence >= tag.confidence ? existing : tag
            } else {
                best[tag.id] = tag
            }
        }
        return best.values.sorted { $0.id.label < $1.id.label }
    }
}
