import Foundation

enum MoriPulseProxyError: LocalizedError {
    case notConfigured
    case invalidURL
    case invalidResponse
    case httpStatus(Int, String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Mori Pulse proxy is not configured."
        case .invalidURL:
            return "Mori Pulse proxy URL is invalid."
        case .invalidResponse:
            return "Mori Pulse proxy returned an invalid response."
        case .httpStatus(let status, let body):
            let message = body.trimmingCharacters(in: .whitespacesAndNewlines)
            return message.isEmpty
                ? "Mori Pulse proxy returned HTTP \(status)."
                : "Mori Pulse proxy returned HTTP \(status): \(message)"
        }
    }
}

struct MoriPulseProxyConfiguration {
    let baseURL: URL?

    static func fromEnvironmentAndBundle(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        bundle: Bundle = .main
    ) -> MoriPulseProxyConfiguration {
        let bundleValue = bundle.object(forInfoDictionaryKey: "MORI_PULSE_PROXY_BASE_URL") as? String
        let rawValue = environment["MORI_PULSE_PROXY_BASE_URL"] ?? bundleValue
        let trimmed = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !trimmed.isEmpty, !trimmed.contains("$(") else {
            return MoriPulseProxyConfiguration(baseURL: nil)
        }

        return MoriPulseProxyConfiguration(baseURL: URL(string: trimmed))
    }
}

final class MoriPulseProxyClient {
    private let configuration: MoriPulseProxyConfiguration
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        configuration: MoriPulseProxyConfiguration = .fromEnvironmentAndBundle(),
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }

    func generateDailyPulse(
        userContext: MoriPulseUserContext,
        topics: [String],
        recentInputs: [String]
    ) async throws -> MoriDailyPulse {
        let request = PulseProxyDailyRequest(
            dateKey: MoriDateKey.value(),
            timezone: TimeZone.current.identifier,
            locale: localeIdentifier,
            topics: topics,
            userContext: userContext,
            recentInputs: recentInputs
        )
        return try await send(request, path: "api/pulse/daily", responseType: MoriDailyPulse.self)
    }

    func answerFollowUp(
        card: MoriPulseCard,
        question: String,
        topics: [String],
        userContext: MoriPulseUserContext,
        recentInputs: [String]
    ) async throws -> PulseProxyFollowUpResponse {
        let request = PulseProxyFollowUpRequest(
            dateKey: MoriDateKey.value(),
            timezone: TimeZone.current.identifier,
            locale: localeIdentifier,
            topics: topics,
            card: card,
            question: question,
            messages: card.followUpMessages,
            userContext: userContext,
            recentInputs: recentInputs
        )
        return try await send(request, path: "api/pulse/follow-up", responseType: PulseProxyFollowUpResponse.self)
    }

    private var localeIdentifier: String {
        MoriLocalePreference.load().resolvedLocaleIdentifier
    }

    private func send<Request: Encodable, Response: Decodable>(
        _ payload: Request,
        path: String,
        responseType: Response.Type
    ) async throws -> Response {
        guard let baseURL = configuration.baseURL else {
            throw MoriPulseProxyError.notConfigured
        }

        let url = baseURL.appendingPathComponent(path)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 28
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(payload)

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw MoriPulseProxyError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw MoriPulseProxyError.httpStatus(http.statusCode, body)
        }

        return try decoder.decode(responseType, from: data)
    }
}

private struct PulseProxyDailyRequest: Encodable {
    let dateKey: String
    let timezone: String
    let locale: String
    let topics: [String]
    let userContext: MoriPulseUserContext
    let recentInputs: [String]
}

private struct PulseProxyFollowUpRequest: Encodable {
    let dateKey: String
    let timezone: String
    let locale: String
    let topics: [String]
    let card: MoriPulseCard
    let question: String
    let messages: [MoriPulseFollowUpMessage]
    let userContext: MoriPulseUserContext
    let recentInputs: [String]
}

struct PulseProxyFollowUpResponse: Decodable, Equatable {
    let answer: String
    let sources: [MoriPulseSource]
    let followUpPrompts: [String]
}
