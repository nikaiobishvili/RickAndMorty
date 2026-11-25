import Foundation

nonisolated protocol APIClient: Sendable {
    func send<Response: Decodable & Sendable>(
        _ request: URLRequest, as responseType: Response.Type
    ) async throws -> Response
}

actor URLSessionAPIClient: APIClient {
    private let transport: any HTTPTransport

    init(session: URLSession = .shared, cache: any ResponseCache = DiskResponseCache.shared) {
        transport = CachingHTTPTransport(upstream: URLSessionHTTPTransport(session: session), cache: cache)
    }

    init(transport: any HTTPTransport) { self.transport = transport }

    func send<Response: Decodable & Sendable>(
        _ request: URLRequest, as responseType: Response.Type
    ) async throws -> Response {
        try Task.checkCancellation()
        let response = try await transport.response(for: request)
        try Task.checkCancellation()
        guard (200..<300).contains(response.statusCode) else {
            throw APIError.httpStatus(response.statusCode)
        }
        return try JSONDecoder().decode(responseType, from: response.data)
    }
}
