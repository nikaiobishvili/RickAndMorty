import Foundation
import Testing
@testable import RickAndMorty

private actor MemoryResponseCache: ResponseCache {
    private var values: [String: HTTPPayload] = [:]
    func read(key: String) -> HTTPPayload? { values[key] }
    func write(_ payload: HTTPPayload, key: String) { values[key] = payload }
}

private actor StubTransport: HTTPTransport {
    enum Failure: Error, Sendable { case unexpectedRequest }
    private var replies: [Result<HTTPPayload, URLError>]
    private(set) var calls = 0
    init(_ replies: [Result<HTTPPayload, URLError>]) { self.replies = replies }
    func response(for request: URLRequest) async throws -> HTTPPayload {
        calls += 1
        guard !replies.isEmpty else { throw Failure.unexpectedRequest }
        return try replies.removeFirst().get()
    }
}

struct NetworkingAndCacheTests {
    private let request = URLRequest(url: URL(string: "https://rickandmortyapi.com/api/character")!)
    private let payload = HTTPPayload(data: Data("{}".utf8), statusCode: 200)

    @Test func successfulResponseIsAvailableOffline() async throws {
        let upstream = StubTransport([.success(payload), .failure(URLError(.notConnectedToInternet))])
        let transport = CachingHTTPTransport(upstream: upstream, cache: MemoryResponseCache())
        _ = try await transport.response(for: request)
        let saved = try await transport.response(for: request)
        #expect(saved.data == payload.data)
        #expect(await upstream.calls == 2)
    }

    @Test func cachedImagesAvoidAnotherNetworkRequest() async throws {
        let upstream = StubTransport([.success(payload)])
        let transport = CachingHTTPTransport(upstream: upstream, cache: MemoryResponseCache(), policy: .cacheFirst)
        _ = try await transport.response(for: request)
        _ = try await transport.response(for: request)
        #expect(await upstream.calls == 1)
    }

    @Test func cancellationDoesNotReturnCachedData() async throws {
        let cache = MemoryResponseCache()
        await cache.write(payload, key: request.url!.absoluteString)
        let transport = CachingHTTPTransport(upstream: StubTransport([.failure(URLError(.cancelled))]), cache: cache)
        await #expect(throws: URLError.self) { try await transport.response(for: request) }
    }

    @Test func serverErrorDoesNotReturnCachedSuccess() async throws {
        let cache = MemoryResponseCache()
        await cache.write(payload, key: request.url!.absoluteString)
        let transport = CachingHTTPTransport(
            upstream: StubTransport([.success(.init(data: Data(), statusCode: 503))]), cache: cache
        )
        let client = URLSessionAPIClient(transport: transport)
        await #expect(throws: APIError.self) {
            try await client.send(request, as: [String: String].self)
        }
    }

    @Test func malformedJSONProducesDecodingError() async {
        let client = URLSessionAPIClient(transport: StubTransport([
            .success(.init(data: Data("not-json".utf8), statusCode: 200))
        ]))
        await #expect(throws: DecodingError.self) {
            try await client.send(request, as: [String: String].self)
        }
    }

    @Test func offlineWithoutCachePropagatesError() async {
        let transport = CachingHTTPTransport(
            upstream: StubTransport([.failure(URLError(.notConnectedToInternet))]), cache: MemoryResponseCache()
        )
        await #expect(throws: URLError.self) { try await transport.response(for: request) }
    }

    @Test func diskCacheSurvivesRecreationAndExpires() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let date = Date(timeIntervalSince1970: 1_000_000)
        let cache = DiskResponseCache(directory: directory, lifetime: 60, now: { date })
        await cache.write(payload, key: "page")
        let reopened = DiskResponseCache(directory: directory, lifetime: 60, now: { date })
        #expect(await reopened.read(key: "page")?.data == payload.data)
        let expired = DiskResponseCache(directory: directory, lifetime: 60, now: { date.addingTimeInterval(61) })
        #expect(await expired.read(key: "page") == nil)
    }

    @Test func diskCacheHonorsSizeLimitAndCorruptionIsAMiss() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = DiskResponseCache(directory: directory, byteLimit: 500)
        await cache.write(payload, key: "page")
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        try Data("broken".utf8).write(to: #require(files.first))
        #expect(await cache.read(key: "page") == nil)
        await cache.write(.init(data: Data(repeating: 1, count: 1000), statusCode: 200), key: "large")
        #expect(await cache.read(key: "large") == nil)
    }

    @Test func builderRejectsUntrustedNextPageURLs() throws {
        for value in ["http://rickandmortyapi.com/api/character", "https://example.com/api/character",
                      "https://rickandmortyapi.com:8080/api/character", "https://rickandmortyapi.com/other"] {
            #expect(throws: APIError.self) { try URLRequestBuilder().get(#require(URL(string: value))) }
        }
    }
}

@MainActor
struct LocalizationTests {
    @Test func georgianCatalogContainsTranslatedLabels() throws {
        let bundle = Bundle.main
        let resource = try #require(bundle.path(forResource: "ka", ofType: "lproj"))
        let georgian = try #require(Bundle(path: resource))
        #expect(georgian.localizedString(forKey: "Characters", value: nil, table: nil) == "პერსონაჟები")
        #expect(georgian.localizedString(forKey: "Try again", value: nil, table: nil) == "სცადე ხელახლა")
    }
}


nonisolated private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let url = request.url else { return }
        let response: URLResponse
        if url.path == "/not-http" {
            response = URLResponse(url: url, mimeType: "application/json", expectedContentLength: 2, textEncodingName: nil)
        } else {
            response = HTTPURLResponse(url: url, statusCode: url.path == "/unavailable" ? 503 : 200,
                                       httpVersion: nil, headerFields: nil)!
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("{}".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

struct URLSessionTransportTests {
    @Test func sessionTransportAcceptsHTTPAndRejectsNonHTTPResponses() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let transport = URLSessionHTTPTransport(session: session)
        let request = URLRequest(url: URL(string: "https://example.invalid/ok")!)
        let response = try await transport.response(for: request)
        #expect(response.statusCode == 200)
        #expect(response.data == Data("{}".utf8))
        await #expect(throws: APIError.self) {
            try await transport.response(for: URLRequest(url: URL(string: "https://example.invalid/not-http")!))
        }
        let client = URLSessionAPIClient(transport: transport)
        await #expect(throws: APIError.self) {
            try await client.send(URLRequest(url: URL(string: "https://example.invalid/unavailable")!), as: [String: String].self)
        }
    }
}
