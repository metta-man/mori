import Foundation

enum LLMProviderID: String, CaseIterable {
    case openAI = "openai"
    case gemini
    case zai
    case deepSeek = "deepseek"
    case mock

    var defaultModel: String {
        switch self {
        case .openAI: return "gpt-4o-mini"
        case .gemini: return "gemini-3.5-flash"
        case .zai: return "glm-5.1"
        case .deepSeek: return "deepseek-v4-flash"
        case .mock: return "mori-mock"
        }
    }

    var fallbackModel: String {
        switch self {
        case .openAI: return "gpt-4o-mini"
        case .gemini: return "gemini-2.5-flash"
        case .zai: return "glm-4.6"
        case .deepSeek: return "deepseek-v4-flash"
        case .mock: return "mori-mock"
        }
    }
}

enum LLMError: LocalizedError {
    case missingAPIKey(LLMProviderID)
    case invalidResponse
    case httpStatus(Int, String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let provider):
            return "Missing API key for \(provider.rawValue)."
        case .invalidResponse:
            return "The LLM provider returned an invalid response."
        case .httpStatus(let status, let body):
            return "The LLM provider returned HTTP \(status): \(body)"
        case .emptyResponse:
            return "The LLM provider returned an empty response."
        }
    }
}

struct LLMMessage: Codable, Equatable {
    let role: String
    let content: String
}

struct LLMCompletionRequest: Equatable {
    let messages: [LLMMessage]
    var temperature: Double = 0.35
    var maxTokens: Int = 900
}

struct MoriLLMConfiguration {
    let providerID: LLMProviderID
    let model: String
    let fallbackModel: String
    let timeout: TimeInterval
    let retryCount: Int

    static func fromEnvironment(_ environment: [String: String] = ProcessInfo.processInfo.environment) -> MoriLLMConfiguration {
        let providerID = LLMProviderID(rawValue: environment["MORI_LLM_PROVIDER"]?.lowercased() ?? "") ?? .mock
        let timeout = TimeInterval(environment["MORI_LLM_TIMEOUT_SECONDS"] ?? "") ?? 20
        let retryCount = Int(environment["MORI_LLM_RETRY_COUNT"] ?? "") ?? 1

        return MoriLLMConfiguration(
            providerID: providerID,
            model: environment["MORI_LLM_MODEL"] ?? providerID.defaultModel,
            fallbackModel: environment["MORI_LLM_FALLBACK_MODEL"] ?? providerID.fallbackModel,
            timeout: timeout,
            retryCount: max(0, retryCount)
        )
    }
}

protocol LLMProvider {
    var id: LLMProviderID { get }
    var isConfigured: Bool { get }

    func complete(_ request: LLMCompletionRequest, model: String, timeout: TimeInterval) async throws -> String
}

final class LLMClient {
    private let configuration: MoriLLMConfiguration
    private let providers: [LLMProviderID: any LLMProvider]

    init(configuration: MoriLLMConfiguration = .fromEnvironment()) {
        self.configuration = configuration
        self.providers = [
            .openAI: OpenAICompatibleChatProvider(
                id: .openAI,
                apiKeyEnvironmentName: "OPENAI_API_KEY",
                baseURL: URL(string: "https://api.openai.com/v1/chat/completions")!
            ),
            .gemini: GeminiProvider(apiKeyEnvironmentName: "GEMINI_API_KEY"),
            .zai: OpenAICompatibleChatProvider(
                id: .zai,
                apiKeyEnvironmentName: "ZAI_API_KEY",
                baseURL: URL(string: ProcessInfo.processInfo.environment["MORI_ZAI_BASE_URL"] ?? "https://api.z.ai/api/paas/v4/chat/completions")!
            ),
            .deepSeek: OpenAICompatibleChatProvider(
                id: .deepSeek,
                apiKeyEnvironmentName: "DEEPSEEK_API_KEY",
                baseURL: URL(string: ProcessInfo.processInfo.environment["MORI_DEEPSEEK_BASE_URL"] ?? "https://api.deepseek.com/chat/completions")!
            ),
            .mock: MockLLMProvider()
        ]
    }

    func complete(_ request: LLMCompletionRequest) async throws -> String {
        guard let provider = providers[configuration.providerID], provider.isConfigured else {
            return try await mockComplete(request)
        }

        do {
            return try await completeWithRetry(provider: provider, request: request, model: configuration.model)
        } catch {
            if configuration.fallbackModel != configuration.model {
                do {
                    return try await completeWithRetry(provider: provider, request: request, model: configuration.fallbackModel)
                } catch {
                    return try await mockComplete(request)
                }
            }
            return try await mockComplete(request)
        }
    }

    private func completeWithRetry(
        provider: any LLMProvider,
        request: LLMCompletionRequest,
        model: String
    ) async throws -> String {
        var lastError: Error?

        for attempt in 0...configuration.retryCount {
            do {
                return try await provider.complete(request, model: model, timeout: configuration.timeout)
            } catch {
                lastError = error
                if attempt < configuration.retryCount {
                    let delay = UInt64(350_000_000 * UInt64(attempt + 1))
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
        }

        throw lastError ?? LLMError.emptyResponse
    }

    private func mockComplete(_ request: LLMCompletionRequest) async throws -> String {
        guard let mock = providers[.mock] else { throw LLMError.emptyResponse }
        return try await mock.complete(request, model: "mori-mock", timeout: 1)
    }
}

private struct OpenAICompatibleChatProvider: LLMProvider {
    let id: LLMProviderID
    let apiKeyEnvironmentName: String
    let baseURL: URL

    private var apiKey: String? {
        ProcessInfo.processInfo.environment[apiKeyEnvironmentName]
    }

    var isConfigured: Bool {
        apiKey?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    func complete(_ request: LLMCompletionRequest, model: String, timeout: TimeInterval) async throws -> String {
        guard let apiKey, !apiKey.isEmpty else {
            throw LLMError.missingAPIKey(id)
        }

        var urlRequest = URLRequest(url: baseURL)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = timeout
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(
            OpenAIChatRequest(
                model: model,
                messages: request.messages,
                temperature: request.temperature,
                maxTokens: request.maxTokens,
                stream: false
            )
        )

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        try validate(response: response, data: data)

        let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty else {
            throw LLMError.emptyResponse
        }

        return content
    }
}

private struct GeminiProvider: LLMProvider {
    let id: LLMProviderID = .gemini
    let apiKeyEnvironmentName: String

    private var apiKey: String? {
        ProcessInfo.processInfo.environment[apiKeyEnvironmentName]
    }

    var isConfigured: Bool {
        apiKey?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    func complete(_ request: LLMCompletionRequest, model: String, timeout: TimeInterval) async throws -> String {
        guard let apiKey, !apiKey.isEmpty else {
            throw LLMError.missingAPIKey(.gemini)
        }

        let modelPath = model.hasPrefix("models/") ? model : "models/\(model)"
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/\(modelPath):generateContent") else {
            throw LLMError.invalidResponse
        }

        let prompt = request.messages
            .map { "\($0.role.uppercased()): \($0.content)" }
            .joined(separator: "\n\n")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = timeout
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(
            GeminiGenerateContentRequest(
                contents: [
                    GeminiContent(
                        role: "user",
                        parts: [GeminiPart(text: prompt)]
                    )
                ],
                generationConfig: GeminiGenerationConfig(
                    temperature: request.temperature,
                    maxOutputTokens: request.maxTokens
                )
            )
        )

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        try validate(response: response, data: data)

        let decoded = try JSONDecoder().decode(GeminiGenerateContentResponse.self, from: data)
        let text = decoded.candidates
            .first?
            .content
            .parts
            .compactMap(\.text)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let text, !text.isEmpty else {
            throw LLMError.emptyResponse
        }

        return text
    }
}

private struct MockLLMProvider: LLMProvider {
    let id: LLMProviderID = .mock
    let isConfigured = true

    func complete(_ request: LLMCompletionRequest, model: String, timeout: TimeInterval) async throws -> String {
        let prompt = request.messages.map(\.content).joined(separator: "\n")

        if prompt.contains("MORI_DAILY_PULSE_JSON") {
            return """
            {
              "reclaimedMinutes": 28,
              "cards": [
                {
                  "kind": "worthKnowing",
                  "headline": "Your first check sets the tone",
                  "body": "The strongest signal is to choose one meaningful area before opening a feed: mind, body, work, love, or rest.",
                  "actionLabel": "Mark useful"
                },
                {
                  "kind": "worthIgnoring",
                  "headline": "Urgent commentary is mostly repetition",
                  "body": "Most hot takes today do not change a real decision. Let the loop pass unless it protects your time, health, or relationships.",
                  "actionLabel": "Skip the loop"
                },
                {
                  "kind": "attentionTrap",
                  "headline": "Live feeds can turn curiosity into a scroll session",
                  "body": "Avoid comment chains framed as urgent reactions. They are designed to keep your thumb moving.",
                  "actionLabel": "Open Quiet Mode"
                },
                {
                  "kind": "resetAction",
                  "headline": "Choose one practice before another scan",
                  "body": "Breathe for one minute, Settle for three, write a quiet note, or step outside before returning to the day.",
                  "actionLabel": "Choose practice"
                },
                {
                  "kind": "reclaimedTime",
                  "headline": "About 28 minutes reclaimed",
                  "body": "The briefing replaces a noisy scan with a calmer signal check.",
                  "minutes": 28
                }
              ]
            }
            """
        }

        if prompt.contains("MORI_CLASSIFY_NOISE") {
            return "noise"
        }

        if prompt.contains("MORI_WEEKLY_REFLECTION_JSON") {
            return """
            {
              "title": "Your roots are getting steadier",
              "body": "You reclaimed attention in small blocks. The pattern to protect is the pause before opening a feed.",
              "nextSeed": "Start one morning with ten quiet minutes before checking updates."
            }
            """
        }

        if prompt.contains("MORI_RESET_ACTION") {
            return "Put the phone face down, breathe for two minutes, then write the next honest action."
        }

        return "Here is the useful signal: keep the summary small, skip the noisy loop, and return to one grounded action."
    }
}

final class MoriPulseService {
    static let shared = MoriPulseService()

    private let client: LLMClient
    private let decoder = JSONDecoder()

    init(client: LLMClient = LLMClient()) {
        self.client = client
    }

    func generateDailyPulse(
        userContext: MoriPulseUserContext,
        topics: [String],
        recentInputs: [String]
    ) async -> MoriDailyPulse {
        let prompt = dailyPulsePrompt(
            userContext: userContext,
            topics: topics,
            recentInputs: recentInputs
        )
        let request = LLMCompletionRequest(messages: [
            LLMMessage(role: "system", content: "You are Mori, a calm life clarity assistant. Protect attention and avoid sensational framing."),
            LLMMessage(role: "user", content: prompt)
        ])

        do {
            let text = try await client.complete(request)
            let pulse = try decodePulse(from: text, topics: topics, isMock: false)
            return pulse
        } catch {
            return MoriDailyPulse.mock(topics: topics.isEmpty ? ["Mind", "Wellness", "Learning"] : topics)
        }
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

        let body = (try? await client.complete(request)) ?? "Breathe for two minutes, stretch your shoulders, and write the next honest action."
        return MoriPulseCard(
            kind: .resetAction,
            headline: "A small reset",
            body: body,
            actionLabel: "Plant this seed"
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
                title: "Your roots are getting steadier",
                body: "Small pauses are becoming a practice. Keep protecting the moment before the scroll begins.",
                nextSeed: "Start one day with ten quiet minutes before checking updates."
            )
        }
    }

    private func dailyPulsePrompt(
        userContext: MoriPulseUserContext,
        topics: [String],
        recentInputs: [String]
    ) -> String {
        """
        MORI_DAILY_PULSE_JSON
        Build a daily Clarity Pulse using only aggregate context.
        Mori Pulse is an attention filter for life clarity, not a news feed.
        Avoid sensational, speculative, crypto-first, or market-dashboard framing unless the user explicitly named that custom topic.
        End the resetAction card with a real Mori practice suggestion: Breathe 1 min, Settle 3 min, Journal, Focus 15 min, Quiet Mode, or Walk / Offline Reset.
        Topics: \(topics.joined(separator: ", "))
        Context: clarityScore=\(userContext.clarityScore), seedsToday=\(userContext.seedsToday), quietMinutesToday=\(userContext.quietMinutesToday), reclaimedMinutesToday=\(userContext.reclaimedMinutesToday), weeklyProofCompleted=\(userContext.weeklyProofCompleted).
        Recent summarized inputs: \(recentInputs.prefix(4).joined(separator: " | "))

        Return only valid JSON:
        {
          "reclaimedMinutes": 25,
          "cards": [
            {"kind":"worthKnowing","headline":"...","body":"...","actionLabel":"..."},
            {"kind":"worthIgnoring","headline":"...","body":"...","actionLabel":"..."},
            {"kind":"attentionTrap","headline":"...","body":"...","actionLabel":"..."},
            {"kind":"resetAction","headline":"...","body":"...","actionLabel":"..."},
            {"kind":"reclaimedTime","headline":"...","body":"...","minutes":25}
          ]
        }
        """
    }

    private func decodePulse(from text: String, topics: [String], isMock: Bool) throws -> MoriDailyPulse {
        let payload = try decoder.decode(PulsePayload.self, from: Data(extractJSONObject(from: text).utf8))
        return MoriDailyPulse(
            dateKey: MoriDateKey.value(),
            generatedAt: Date(),
            topics: topics,
            cards: payload.cards.map {
                MoriPulseCard(
                    kind: $0.kind,
                    headline: $0.headline,
                    body: $0.body,
                    actionLabel: $0.actionLabel,
                    minutes: $0.minutes
                )
            },
            reclaimedMinutes: payload.reclaimedMinutes ?? payload.cards.compactMap(\.minutes).max() ?? 0,
            isMock: isMock
        )
    }

    private func privacyTrimmed(_ content: String) -> String {
        String(content.trimmingCharacters(in: .whitespacesAndNewlines).prefix(2_000))
    }
}

private struct OpenAIChatRequest: Encodable {
    let model: String
    let messages: [LLMMessage]
    let temperature: Double
    let maxTokens: Int
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
        case stream
    }
}

private struct OpenAIChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }

        let message: Message
    }

    let choices: [Choice]
}

private struct GeminiGenerateContentRequest: Encodable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

private struct GeminiContent: Codable {
    let role: String?
    let parts: [GeminiPart]
}

private struct GeminiPart: Codable {
    let text: String?
}

private struct GeminiGenerationConfig: Encodable {
    let temperature: Double
    let maxOutputTokens: Int
}

private struct GeminiGenerateContentResponse: Decodable {
    struct Candidate: Decodable {
        let content: GeminiContent
    }

    let candidates: [Candidate]
}

private struct PulsePayload: Decodable {
    struct Card: Decodable {
        let kind: MoriPulseCardKind
        let headline: String
        let body: String
        let actionLabel: String?
        let minutes: Int?
    }

    let reclaimedMinutes: Int?
    let cards: [Card]
}

private func validate(response: URLResponse, data: Data) throws {
    guard let http = response as? HTTPURLResponse else {
        throw LLMError.invalidResponse
    }

    guard (200..<300).contains(http.statusCode) else {
        let body = String(data: data, encoding: .utf8) ?? ""
        throw LLMError.httpStatus(http.statusCode, body)
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
