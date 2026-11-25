import Foundation

nonisolated protocol ImageDataLoader: Sendable {
    func data(for url: URL) async throws -> Data
}

nonisolated struct RemoteImageDataLoader: ImageDataLoader {
    private let transport: any HTTPTransport

    init(transport: any HTTPTransport = CachingHTTPTransport(
        upstream: URLSessionHTTPTransport(session: .shared),
        cache: DiskResponseCache.shared, policy: .cacheFirst
    )) {
        self.transport = transport
    }

    func data(for url: URL) async throws -> Data {
        let request = try URLRequestBuilder().get(url)
        let response = try await transport.response(for: request)
        try Task.checkCancellation()
        guard (200..<300).contains(response.statusCode) else {
            throw APIError.httpStatus(response.statusCode)
        }
        return response.data
    }
}
