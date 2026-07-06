import Foundation

enum MoriClarityTopicPlanner {
    static func sanitizedTopics(_ topics: Set<PulseTopic>) -> Set<PulseTopic> {
        let sanitized = topics.subtracting([.crypto])
        return sanitized.isEmpty ? PulseTopic.defaultSelected : sanitized
    }

    static func selectedTopicLabelSet(
        selectedTopics: Set<PulseTopic>,
        customTopics: [String]
    ) -> [String] {
        let defaults = PulseTopic.allCases
            .filter { selectedTopics.contains($0) }
            .filter { $0 != .custom && $0 != .crypto }
            .map(\.title)

        return defaults + customTopics
    }

    static func normalizedTopicOrder(
        _ order: [String],
        customTopics: [String]
    ) -> [String] {
        var normalized: [String] = []
        let available = allTopicLabels(customTopics: customTopics)

        for topic in order where available.contains(where: { $0.caseInsensitiveCompare(topic) == .orderedSame }) {
            if !normalized.contains(where: { $0.caseInsensitiveCompare(topic) == .orderedSame }) {
                normalized.append(topic)
            }
        }

        for topic in available where !normalized.contains(where: { $0.caseInsensitiveCompare(topic) == .orderedSame }) {
            normalized.append(topic)
        }

        return normalized
    }

    private static func allTopicLabels(customTopics: [String]) -> [String] {
        defaultTopicLabels + customTopics
    }

    private static var defaultTopicLabels: [String] {
        PulseTopic.allCases
            .filter { $0 != .custom && $0 != .crypto }
            .map(\.title)
    }
}
