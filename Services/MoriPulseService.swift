import Foundation

struct MoriPulseFollowUpResult: Equatable {
    let message: MoriPulseFollowUpMessage
    let followUpPrompts: [String]
}

final class MoriPulseService {
    static let shared = MoriPulseService()

    private let client: LLMClient
    private let proxyClient: MoriPulseProxyClient
    private let decoder = JSONDecoder()

    private init(
        client: LLMClient = LLMClient(),
        proxyClient: MoriPulseProxyClient = MoriPulseProxyClient()
    ) {
        self.client = client
        self.proxyClient = proxyClient
    }

    func generateDailyPulse(
        userContext: MoriPulseUserContext,
        topics: [String],
        recentInputs: [String]
    ) async throws -> MoriDailyPulse {
        do {
            return try await proxyClient.generateDailyPulse(
                userContext: userContext,
                topics: topics,
                recentInputs: recentInputs
            )
            .localizedForCurrentLocaleIfNeeded()
        } catch MoriPulseProxyError.notConfigured {
            return MoriDailyPulse.mock(topics: topics.isEmpty ? MoriLocalePreference.load().defaultPulseTopics : topics)
                .localizedForCurrentLocaleIfNeeded()
        } catch {
            throw error
        }
    }

    func answerFollowUp(
        card: MoriPulseCard,
        question: String,
        topics: [String],
        userContext: MoriPulseUserContext,
        recentInputs: [String]
    ) async throws -> MoriPulseFollowUpResult {
        let response = try await proxyClient.answerFollowUp(
            card: card,
            question: question,
            topics: topics,
            userContext: userContext,
            recentInputs: recentInputs
        )
        return MoriPulseFollowUpResult(
            message: MoriPulseFollowUpMessage(
                role: .assistant,
                content: response.answer,
                sources: response.sources
            ),
            followUpPrompts: response.followUpPrompts
        )
    }

    func summarizeContent(_ content: String) async -> String {
        let summarized = privacyTrimmed(content)
        let request = LLMCompletionRequest(messages: [
            LLMMessage(role: "system", content: "Summarize without adding urgency or personal inference."),
            LLMMessage(role: "user", content: "MORI_SUMMARIZE\nSummarize this content in three calm bullets:\n\(summarized)")
        ], maxTokens: 260)

        do {
            return try await client.complete(request)
        } catch {
            return summarized.components(separatedBy: ".").prefix(2).joined(separator: ".")
        }
    }

    func classifyNoiseOrUseful(_ content: String) async -> MoriNoiseClassification {
        let request = LLMCompletionRequest(messages: [
            LLMMessage(role: "system", content: "Classify content as useful, noise, or attentionTrap. Return only one label."),
            LLMMessage(role: "user", content: "MORI_CLASSIFY_NOISE\n\(privacyTrimmed(content))")
        ], maxTokens: 20)

        do {
            let label = try await client.complete(request)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\"", with: "")
            return MoriNoiseClassification(rawValue: label) ?? .noise
        } catch {
            return .noise
        }
    }

    func generateResetAction(_ userState: MoriResetUserState) async -> MoriPulseCard {
        let request = LLMCompletionRequest(messages: [
            LLMMessage(role: "system", content: "Create one tiny wellness reset. No medical claims. No personal raw data."),
            LLMMessage(role: "user", content: "MORI_RESET_ACTION\nState: clarity \(userState.clarityScore), quiet minutes \(userState.quietMinutesToday), urge \(userState.likelyUrge)")
        ], maxTokens: 120)

        let body = (try? await client.complete(request)) ?? MoriL10n.string(
            "llm.reset.fallback.body",
            defaultValue: "Breathe for two minutes, stretch your shoulders, and write the next honest action."
        )
        return MoriPulseCard(
            kind: .resetAction,
            headline: MoriL10n.string("llm.reset.fallback.headline", defaultValue: "A small reset"),
            body: body,
            actionLabel: MoriL10n.string("llm.reset.fallback.action", defaultValue: "Plant this seed")
        )
    }

    func generateWeeklyReflection(_ userStats: MoriWeeklyStats) async -> MoriWeeklyReflection {
        let request = LLMCompletionRequest(messages: [
            LLMMessage(role: "system", content: "Write a short weekly reflection from aggregate stats only."),
            LLMMessage(role: "user", content: "MORI_WEEKLY_REFLECTION_JSON\nReturn JSON with title, body, nextSeed. Stats: seeds \(userStats.seeds), quietMinutes \(userStats.quietMinutes), reclaimed \(userStats.reclaimedMinutes), roots \(userStats.rootsStreak), clarityAverage \(userStats.clarityAverage)")
        ], maxTokens: 220)

        do {
            let text = try await client.complete(request)
            let json = extractJSONObject(from: text)
            return try decoder.decode(MoriWeeklyReflection.self, from: Data(json.utf8))
        } catch {
            return MoriWeeklyReflection(
                title: MoriL10n.string("weekly_reflection.fallback.title", defaultValue: "Your roots are getting steadier"),
                body: MoriL10n.string(
                    "weekly_reflection.fallback.body",
                    defaultValue: "Small pauses are becoming a reset rhythm. Keep protecting the moment before the scroll begins."
                ),
                nextSeed: MoriL10n.string(
                    "weekly_reflection.fallback.next_seed",
                    defaultValue: "Start one day with ten quiet minutes before checking updates."
                )
            )
        }
    }

    private func privacyTrimmed(_ content: String) -> String {
        String(content.trimmingCharacters(in: .whitespacesAndNewlines).prefix(2_000))
    }

}

private func extractJSONObject(from text: String) -> String {
    guard let start = text.firstIndex(of: "{"),
          let end = text.lastIndex(of: "}"),
          start <= end else {
        return text
    }

    return String(text[start...end])
}
