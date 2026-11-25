import Foundation

nonisolated struct HTTPPayload: Codable, Sendable {
    let data: Data
    let statusCode: Int
}

nonisolated protocol HTTPTransport: Sendable {
    func response(for request: URLRequest) async throws -> HTTPPayload
}

nonisolated struct URLSessionHTTPTransport: HTTPTransport {
    let session: URLSession

    func response(for request: URLRequest) async throws -> HTTPPayload {
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        return HTTPPayload(data: data, statusCode: response.statusCode)
    }
}

/// API requests refresh from the server first; immutable avatar URLs use the cache first.
nonisolated struct CachingHTTPTransport: HTTPTransport {
    enum Policy: Sendable { case networkFirst, cacheFirst }
    let upstream: any HTTPTransport
    let cache: any ResponseCache
    var policy: Policy = .networkFirst

    func response(for request: URLRequest) async throws -> HTTPPayload {
        try Task.checkCancellation()
        guard request.httpMethod == nil || request.httpMethod == "GET",
              let key = request.url?.absoluteString else {
            return try await upstream.response(for: request)
        }
        if policy == .cacheFirst, let saved = await cache.read(key: key) {
            try Task.checkCancellation()
            return saved
        }
        do {
            let payload = try await upstream.response(for: request)
            try Task.checkCancellation()
            if (200..<300).contains(payload.statusCode) {
                await cache.write(payload, key: key)
            }
            return payload
        } catch {
            try Task.checkCancellation()
            // Never mask HTTP/decoding errors or cancellation with stale content.
            if let error = error as? URLError,
               [.notConnectedToInternet, .networkConnectionLost, .timedOut,
                .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed].contains(error.code),
               let saved = await cache.read(key: key) {
                try Task.checkCancellation()
                return saved
            }
            throw error
        }
    }
}
