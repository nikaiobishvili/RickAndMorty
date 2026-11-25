import Foundation
import Testing
@testable import RickAndMorty

private actor ControlledCharactersRepository: CharactersRepository {
    private var pending: [String: CheckedContinuation<CharacterPageDTO, any Error>] = [:]
    private var waiting: [String: CheckedContinuation<Void, Never>] = [:]

    func fetchCharacters(name: String, filters: CharacterFilters) async throws -> CharacterPageDTO {
        try await withCheckedThrowingContinuation { continuation in
            pending[name] = continuation
            waiting.removeValue(forKey: name)?.resume()
        }
    }
    func fetchNextPage(at url: URL) async throws -> CharacterPageDTO { throw APIError.invalidURL }
    func waitForRequest(_ name: String) async {
        if pending[name] != nil { return }
        await withCheckedContinuation { waiting[name] = $0 }
    }
    func finish(_ name: String, page: CharacterPageDTO) { pending.removeValue(forKey: name)?.resume(returning: page) }
}

private actor DetailsStub: CharacterDetailsRepository {
    let character: CharacterDTO
    let cast: [CharacterDTO]
    var shouldFail = false
    private(set) var participantCalls = 0
    init(character: CharacterDTO, cast: [CharacterDTO]) { self.character = character; self.cast = cast }
    func fail(_ value: Bool) { shouldFail = value }
    func fetchCharacter(id: Int) async throws -> CharacterDTO {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return character
    }
    func fetchEpisodes(references: [URL]) async throws -> [EpisodeDTO] { [] }
    func fetchParticipants(references: [URL], excluding id: Int) async throws -> [CharacterDTO] {
        participantCalls += 1
        if shouldFail { throw URLError(.timedOut) }
        return cast.filter { $0.id != id }
    }
}

@MainActor
struct ScreenStateTests {
    private func page(_ ids: [Int]) throws -> CharacterPageDTO {
        try JSONDecoder().decode(CharacterPageDTO.self, from: Data(pageJSON(ids).utf8))
    }

    @Test func oldSearchResponseCannotOverwriteNewResults() async throws {
        let repository = ControlledCharactersRepository()
        let model = CharacterListViewModel(repository: repository)
        let old = Task { await model.loadCharacters(debounce: false) }
        await repository.waitForRequest("")
        model.searchText = "Rick"
        let new = Task { await model.loadCharacters(debounce: false) }
        await repository.waitForRequest("Rick")
        await repository.finish("Rick", page: try page([2]))
        await new.value
        await repository.finish("", page: try page([1]))
        await old.value
        guard case .loaded(let characters) = model.state else { Issue.record("Expected loaded state"); return }
        #expect(characters.map(\.id) == [2])
    }

    @Test func cancelledRequestDoesNotPublishResults() async throws {
        let repository = ControlledCharactersRepository()
        let model = CharacterListViewModel(repository: repository)
        let task = Task { await model.loadCharacters(debounce: false) }
        await repository.waitForRequest("")
        task.cancel()
        await repository.finish("", page: try page([1]))
        await task.value
        if case .loaded = model.state { Issue.record("Cancelled result must not be published") }
        #expect(!model.isRefreshing)
    }

    @Test func searchAndFiltersResetPagination() async throws {
        let client = RecordingAPIClient([pageJSON([1], next: true), pageJSON([2])])
        let model = CharacterListViewModel(repository: RemoteCharactersRepository(client: client))
        await model.loadCharacters(debounce: false)
        model.searchText = "Morty"
        model.filters.status = .alive
        await model.loadCharacters(debounce: false)
        await model.loadNextPage()
        guard case .loaded(let characters) = model.state else { Issue.record("Expected loaded state"); return }
        #expect(characters.map(\.id) == [2])
        #expect(model.nextPageURL == nil)
        #expect(await client.requests.count == 2)
    }

    @Test func refreshFailureKeepsVisibleCharacters() async throws {
        let model = CharacterListViewModel(repository: RemoteCharactersRepository(client: RecordingAPIClient([pageJSON([1])])))
        await model.loadCharacters(debounce: false)
        await model.loadCharacters(debounce: false)
        guard case .loaded(let characters) = model.state else { Issue.record("Expected preserved results"); return }
        #expect(characters.map(\.id) == [1])
        #expect(model.loadError != nil)
        #expect(!model.isRefreshing)
    }

    @Test func detailsFailureCanBeRetriedAndLoadedParticipantsAreReused() async throws {
        let characters = try page([1, 2]).results
        let repository = DetailsStub(character: characters[0], cast: characters)
        let model = CharacterDetailsViewModel(id: 1, repository: repository)
        await repository.fail(true)
        await model.load()
        guard case .failed = model.state else { Issue.record("Expected failed state"); return }
        await repository.fail(false)
        await model.load()
        guard case .loaded(let character, _) = model.state else { Issue.record("Expected loaded state"); return }
        #expect(character.id == 1)
        let episode = EpisodeDTO(id: 1, name: "Pilot", episode: "S01E01", airDate: "December 2, 2013", characters: [])
        await model.loadParticipants(for: episode)
        await model.loadParticipants(for: episode)
        guard case .loaded(let cast) = model.participants[1] else { Issue.record("Expected participants"); return }
        #expect(cast.map(\.id) == [2])
        #expect(await repository.participantCalls == 1)
    }

    @Test func participantsFailureRequiresExplicitRetry() async throws {
        let characters = try page([1, 2]).results
        let repository = DetailsStub(character: characters[0], cast: characters)
        let model = CharacterDetailsViewModel(id: 1, repository: repository)
        let episode = EpisodeDTO(id: 1, name: "Pilot", episode: "S01E01", airDate: "", characters: [])
        await repository.fail(true)
        await model.loadParticipants(for: episode)
        await repository.fail(false)
        await model.loadParticipants(for: episode)
        #expect(await repository.participantCalls == 1)
        await model.loadParticipants(for: episode, retry: true)
        #expect(await repository.participantCalls == 2)
        guard case .loaded = model.participants[1] else { Issue.record("Expected retry success"); return }
    }
}

@MainActor
struct ListLifecycleTests {
    @Test func returningFromDetailsKeepsLoadedPages() async throws {
        let client = RecordingAPIClient([pageJSON([1], next: true), pageJSON([2])])
        let model = CharacterListViewModel(repository: RemoteCharactersRepository(client: client))
        await model.loadIfNeeded()
        await model.loadNextPage()
        await model.loadIfNeeded()
        guard case .loaded(let characters) = model.state else { Issue.record("Expected retained pages"); return }
        #expect(characters.map(\.id) == [1, 2])
        #expect(await client.requests.count == 2)
    }

    @Test func failedRefreshRetainsPaginationURL() async {
        let model = CharacterListViewModel(repository: RemoteCharactersRepository(client: RecordingAPIClient([pageJSON([1], next: true)])))
        await model.loadCharacters(debounce: false)
        let next = model.nextPageURL
        await model.loadCharacters(debounce: false)
        #expect(model.nextPageURL == next)
        #expect(model.loadError != nil)
    }

    @Test func failedNewSearchDoesNotOfferPreviousQueryPagination() async {
        let model = CharacterListViewModel(repository: RemoteCharactersRepository(client: RecordingAPIClient([pageJSON([1], next: true)])))
        await model.loadCharacters(debounce: false)
        model.searchText = "Rick"
        await model.loadCharacters(debounce: false)
        #expect(model.nextPageURL == nil)
        #expect(model.loadError != nil)
    }

}
