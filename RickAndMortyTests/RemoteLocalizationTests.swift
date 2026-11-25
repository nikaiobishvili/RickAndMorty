import Foundation
import Testing
@testable import RickAndMorty

private func document(_ strings: [String: String] = ["settings": "Remote settings"],
                      revision: Int = 1, schema: Int = 1) -> RemoteLocalization {
    .init(schemaVersion: schema, revision: revision, languages: ["en": .init(strings: strings)])
}

private actor LocalizationTransport: HTTPTransport {
    let payload: HTTPPayload
    private(set) var requests: [URLRequest] = []
    init(_ payload: HTTPPayload) { self.payload = payload }
    func response(for request: URLRequest) async throws -> HTTPPayload {
        requests.append(request)
        return payload
    }
}

private actor MemoryLocalizationCache: LocalizationCache {
    var value: RemoteLocalization?
    private(set) var writes = 0
    init(_ value: RemoteLocalization? = nil) { self.value = value }
    func load() -> RemoteLocalization? { value }
    func save(_ document: RemoteLocalization) { value = document; writes += 1 }
}

private actor LocalizationProviderStub: RemoteLocalizationProviding {
    private var replies: [Result<RemoteLocalization, URLError>]
    init(_ replies: [Result<RemoteLocalization, URLError>]) { self.replies = replies }
    func fetch() async throws -> RemoteLocalization {
        guard !replies.isEmpty else { throw URLError(.notConnectedToInternet) }
        return try replies.removeFirst().get()
    }
}

struct RemoteLocalizationValidationTests {
    @Test func providerDecodesValidatedReadOnlyResponse() async throws {
        let expected = document()
        let transport = LocalizationTransport(.init(data: try JSONEncoder().encode(expected), statusCode: 200))
        let provider = FirebaseLocalizationProvider(endpoint: FirebaseLocalizationConfiguration.endpoint, transport: transport)
        #expect(try await provider.fetch() == expected)
        let request = try #require(await transport.requests.first)
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.cachePolicy == .reloadIgnoringLocalCacheData)
    }

    @Test func incompatibleSchemaEmptyValuesAndInvalidPlaceholdersAreRejected() {
        for invalid in [document(schema: 2), document(["settings": "  "]),
                        document(["settings": "Hello {unknown}"]),
                        document(["the_server_returned_an_error_lld": "Server failed"])] {
            #expect(throws: RemoteLocalizationError.invalidDocument) { try invalid.validated() }
        }
        #expect(throws: Never.self) {
            try document(["the_server_returned_an_error_lld": "Error {code}"]).validated()
        }
    }

    @Test func unknownKeysAndLanguagesAllowForwardCompatibility() throws {
        let value = RemoteLocalization(schemaVersion: 1, revision: 1, languages: [
            "en": .init(strings: ["settings": "Remote settings", "future_key": "Hello {future}" ]),
            "fr": .init(strings: ["settings": "Paramètres"])
        ])
        #expect(try value.validated() == value)
    }

    @Test func providerRejectsHTTPFailuresLargeResponsesAndUntrustedURLs() async throws {
        let endpoint = FirebaseLocalizationConfiguration.endpoint
        let failure = LocalizationTransport(.init(data: Data(), statusCode: 403))
        await #expect(throws: RemoteLocalizationError.httpStatus(403)) {
            try await FirebaseLocalizationProvider(endpoint: endpoint, transport: failure).fetch()
        }
        let huge = LocalizationTransport(.init(data: Data(repeating: 0, count: 256 * 1024 + 1), statusCode: 200))
        await #expect(throws: RemoteLocalizationError.responseTooLarge) {
            try await FirebaseLocalizationProvider(endpoint: endpoint, transport: huge).fetch()
        }
        let invalid = try #require(URL(string: "https://example.com/localization/v1.json"))
        await #expect(throws: RemoteLocalizationError.invalidURL) {
            try await FirebaseLocalizationProvider(endpoint: invalid, transport: failure).fetch()
        }
        #expect(await failure.requests.count == 1)
    }

    @Test func diskCacheSurvivesRecreationAndRejectsCorruption() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appending(path: "localization.json")
        await DiskLocalizationCache(file: file).save(document())
        #expect(await DiskLocalizationCache(file: file).load() == document())
        try Data("broken".utf8).write(to: file)
        #expect(await DiskLocalizationCache(file: file).load() == nil)
    }
}

@MainActor
struct LocalizationStoreTests {
    @Test func remoteOverridesFallbackUsesRequestedLanguageAndFormatsArguments() async {
        let remote = RemoteLocalization(schemaVersion: 1, revision: 1, languages: [
            "en": .init(strings: ["settings": "Remote settings"]),
            "ka": .init(strings: ["settings": "პარამეტრები სერვერიდან", "the_server_returned_an_error_lld": "შეცდომა {code}"])
        ])
        let store = LocalizationStore(provider: LocalizationProviderStub([.success(remote)]))
        await store.refresh()
        #expect(store.string(.settings, locale: Locale(identifier: "en")) == "Remote settings")
        #expect(store.string(.settings, locale: Locale(identifier: "fr")) == "Remote settings")
        #expect(store.string(.settings, locale: Locale(identifier: "ka")) == "პარამეტრები სერვერიდან")
        #expect(store.string(.characters, locale: Locale(identifier: "ka")) == "პერსონაჟები")
        #expect(ErrorMessage.server(503).localized(locale: Locale(identifier: "ka"), localization: store) == "შეცდომა 503")
    }

    @Test func offlineStartupUsesLastValidCache() async {
        let cache = MemoryLocalizationCache(document())
        let store = LocalizationStore(provider: LocalizationProviderStub([.failure(URLError(.notConnectedToInternet))]), cache: cache)
        await store.refresh()
        #expect(store.string(.settings, locale: Locale(identifier: "en")) == "Remote settings")
        #expect(store.lastRefreshFailed)
        #expect(await cache.writes == 0)
    }

    @Test func invalidDownloadNeverReplacesGoodCacheAndOlderRevisionIsIgnored() async {
        let good = document(["settings": "Good copy"], revision: 3)
        let cache = MemoryLocalizationCache(good)
        let provider = LocalizationProviderStub([.success(document(schema: 2)), .success(document(revision: 2))])
        let store = LocalizationStore(provider: provider, cache: cache)
        await store.refresh()
        #expect(store.document == good)
        await store.refresh()
        #expect(store.document == good)
        #expect(await cache.writes == 0)
    }

    @Test func editedTextWithSameRevisionIsRefreshedAndOfflineDoesNotEraseIt() async {
        let first = document()
        let updated = document(["settings": "Edited in Firebase"])
        let cache = MemoryLocalizationCache()
        let store = LocalizationStore(provider: LocalizationProviderStub([
            .success(first), .success(updated), .failure(URLError(.timedOut))
        ]), cache: cache)
        await store.refresh()
        await store.refresh()
        #expect(store.document == updated)
        await store.refresh()
        #expect(store.document == updated)
        #expect(await cache.load() == updated)
        #expect(await cache.writes == 2)
    }
}
