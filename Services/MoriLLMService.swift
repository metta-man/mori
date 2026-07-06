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
        case .gemini: return "gemini-2.5-flash"
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
        self.providers = LLMProviderFactory.providers()
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
