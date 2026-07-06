import Foundation

enum LLMProviderFactory {
    static func providers(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> [LLMProviderID: any LLMProvider] {
        [
            .openAI: OpenAICompatibleChatProvider(
                id: .openAI,
                apiKeyEnvironmentName: "OPENAI_API_KEY",
                baseURL: URL(string: "https://api.openai.com/v1/chat/completions")!
            ),
            .gemini: GeminiProvider(apiKeyEnvironmentName: "GEMINI_API_KEY"),
            .zai: OpenAICompatibleChatProvider(
                id: .zai,
                apiKeyEnvironmentName: "ZAI_API_KEY",
                baseURL: URL(string: environment["MORI_ZAI_BASE_URL"] ?? "https://api.z.ai/api/paas/v4/chat/completions")!
            ),
            .deepSeek: OpenAICompatibleChatProvider(
                id: .deepSeek,
                apiKeyEnvironmentName: "DEEPSEEK_API_KEY",
                baseURL: URL(string: environment["MORI_DEEPSEEK_BASE_URL"] ?? "https://api.deepseek.com/chat/completions")!
            ),
            .mock: MockLLMProvider()
        ]
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

private func validate(response: URLResponse, data: Data) throws {
    guard let http = response as? HTTPURLResponse else {
        throw LLMError.invalidResponse
    }

    guard (200..<300).contains(http.statusCode) else {
        let body = String(data: data, encoding: .utf8) ?? ""
        throw LLMError.httpStatus(http.statusCode, body)
    }
}
