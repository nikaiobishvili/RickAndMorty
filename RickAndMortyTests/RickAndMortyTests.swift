import Foundation
import Testing
@testable import RickAndMorty

private actor RecordingAPIClient: APIClient {
    private(set) var requests: [URLRequest] = []
    private let responses: [String]

    init(_ responses: [String]) {
        self.responses = responses
    }

    func send<Response: Decodable & Sendable>(
        _ request: URLRequest, as responseType: Response.Type
    ) async throws -> Response {
        requests.append(request)
        let index = requests.count - 1
        guard responses.indices.contains(index) else { throw APIError.httpStatus(503) }
        return try JSONDecoder().decode(responseType, from: Data(responses[index].utf8))
    }
}

private func characterJSON(_ id: Int) -> String {
    """
    {
      "id": \(id), "name": "Character \(id)", "status": "Alive",
      "species": "Human", "type": "", "gender": "Male",
      "origin": {"name": "Earth"}, "location": {"name": "Earth"},
      "image": "https://rickandmortyapi.com/api/character/avatar/\(id).jpeg",
      "episode": []
    }
    """
}

private func pageJSON(_ ids: [Int], next: Bool = false) -> String {
    let results = ids.map(characterJSON).joined(separator: ",")
    let nextURL = next ? #""https://rickandmortyapi.com/api/character?page=2""# : "null"
    return """
    {"info":{"count":3,"pages":2,"next":\(nextURL),"prev":null},"results":[\(results)]}
    """
}

struct CharactersRepositoryTests {
    @Test
    func searchAndFiltersUseTheSameRequest() async throws {
        let client = RecordingAPIClient([pageJSON([1], next: true)])
        let repository = RemoteCharactersRepository(client: client)
        let filters = CharacterFilters(status: .alive, gender: .male, species: "Human & Alien")

        let page = try await repository.fetchCharacters(name: "  rIcK  ", filters: filters)

        let requests = await client.requests
        let request = try #require(requests.first)
        let url = try #require(request.url)
        let query = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(query.contains(.init(name: "name", value: "rIcK")))
        #expect(query.contains(.init(name: "status", value: "alive")))
        #expect(query.contains(.init(name: "gender", value: "male")))
        #expect(query.contains(.init(name: "species", value: "Human & Alien")))
        #expect(request.httpMethod == "GET")
        #expect(page.results.map(\.id) == [1])
        #expect(page.info.prev == nil)
        #expect(page.info.next != nil)
    }

    @Test
    func participantBatchesPreserveAllOtherCharactersInEpisodeOrder() async throws {
        let firstBatch = (2...21).reversed().map(characterJSON).joined(separator: ",")
        let client = RecordingAPIClient(["[\(firstBatch)]", characterJSON(22)])
        let repository = RemoteCharactersRepository(client: client)
        let references = try (1...22).map { id in
            try #require(URL(string: "https://rickandmortyapi.com/api/character/\(id)"))
        }

        let cast = try await repository.fetchParticipants(references: references, excluding: 1)

        #expect(cast.map(\.id) == Array(2...22))
        #expect(await client.requests.count == 2)
    }
}

@MainActor
struct CharacterListViewModelTests {
    @Test
    func paginationAppendsOnlyNewCharacters() async throws {
        let client = RecordingAPIClient([pageJSON([1, 2], next: true), pageJSON([2, 3])])
        let viewModel = CharacterListViewModel(repository: RemoteCharactersRepository(client: client))

        await viewModel.loadCharacters()
        await viewModel.loadNextPage()
        await viewModel.loadNextPage()

        guard case .loaded(let characters) = viewModel.state else {
            Issue.record("Expected the combined character list")
            return
        }
        #expect(characters.map(\.id) == [1, 2, 3])
        #expect(viewModel.nextPageURL == nil)
        #expect(await client.requests.count == 2)
    }

    @Test
    func paginationFailureKeepsTheFirstPage() async {
        let client = RecordingAPIClient([pageJSON([1, 2], next: true)])
        let viewModel = CharacterListViewModel(repository: RemoteCharactersRepository(client: client))

        await viewModel.loadCharacters()
        await viewModel.loadNextPage()

        guard case .loaded(let characters) = viewModel.state else {
            Issue.record("Expected the first page to stay visible")
            return
        }
        #expect(characters.map(\.id) == [1, 2])
        #expect(viewModel.nextPageURL != nil)
        #expect(viewModel.nextPageError != nil)
        #expect(!viewModel.isLoadingNextPage)
    }
}
