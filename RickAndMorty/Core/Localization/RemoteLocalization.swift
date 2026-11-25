import Foundation

nonisolated struct RemoteLocalization: Codable, Equatable, Sendable {
    struct Language: Codable, Equatable, Sendable {
        let strings: [String: String]
    }
    let schemaVersion: Int
    let revision: Int
    let languages: [String: Language]

    func validated() throws -> Self {
        guard schemaVersion == 1, revision > 0,
              languages.keys.contains(where: { ["en", "ka"].contains($0) }) else {
            throw RemoteLocalizationError.invalidDocument
        }
        let expression = try NSRegularExpression(pattern: #"\{[a-zA-Z][a-zA-Z0-9_]*\}"#)
        for (code, language) in languages where ["en", "ka"].contains(code) {
            for (id, text) in language.strings {
                guard LocalizationKey(rawValue: id) != nil else { continue }
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      text.utf8.count <= 4096 else { throw RemoteLocalizationError.invalidDocument }
                let range = NSRange(text.startIndex..., in: text)
                let matches = expression.matches(in: text, range: range).map {
                    (text as NSString).substring(with: $0.range)
                }
                let expected: Set<String> = id == "the_server_returned_an_error_lld" ? ["{code}"] : []
                guard Set(matches) == expected else { throw RemoteLocalizationError.invalidDocument }
            }
        }
        return self
    }
}

nonisolated enum RemoteLocalizationError: Error, Equatable {
    case invalidURL, invalidDocument, responseTooLarge, httpStatus(Int)
}

nonisolated protocol RemoteLocalizationProviding: Sendable {
    func fetch() async throws -> RemoteLocalization
}

nonisolated struct FirebaseLocalizationProvider: RemoteLocalizationProviding {
    let endpoint: URL
    let transport: any HTTPTransport

    init(endpoint: URL, transport: any HTTPTransport = URLSessionHTTPTransport(session: .shared)) {
        self.endpoint = endpoint
        self.transport = transport
    }

    func fetch() async throws -> RemoteLocalization {
        guard endpoint.scheme == "https", let host = endpoint.host,
              host.hasSuffix(".firebaseio.com") || host.hasSuffix(".firebasedatabase.app"),
              endpoint.path == "/localization/v1.json",
              endpoint.user == nil, endpoint.password == nil,
              endpoint.query == nil, endpoint.fragment == nil,
              endpoint.port == nil || endpoint.port == 443 else {
            throw RemoteLocalizationError.invalidURL
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let response = try await transport.response(for: request)
        try Task.checkCancellation()
        guard response.statusCode == 200 else { throw RemoteLocalizationError.httpStatus(response.statusCode) }
        guard response.data.count <= 256 * 1024 else { throw RemoteLocalizationError.responseTooLarge }
        return try JSONDecoder().decode(RemoteLocalization.self, from: response.data).validated()
    }
}
