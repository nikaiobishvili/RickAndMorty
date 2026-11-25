import Foundation

nonisolated protocol CharactersRepository: Sendable {
    func fetchCharacters(name: String, filters: CharacterFilters) async throws -> CharacterPageDTO
    func fetchNextPage(at url: URL) async throws -> CharacterPageDTO
}

nonisolated protocol CharacterDetailsRepository: Sendable {
    func fetchCharacter(id: Int) async throws -> CharacterDTO
    func fetchEpisodes(references: [URL]) async throws -> [EpisodeDTO]
    func fetchParticipants(references: [URL], excluding id: Int) async throws -> [CharacterDTO]
}

nonisolated struct RemoteCharactersRepository: CharactersRepository, CharacterDetailsRepository {
    private let client: any APIClient
    private let requests = URLRequestBuilder()

    init(client: any APIClient) {
        self.client = client
    }

    func fetchCharacters(name: String, filters: CharacterFilters) async throws -> CharacterPageDTO {
        var query = filters.queryItems
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { query.append(.init(name: "name", value: name)) }
        let url = try requests.url(resource: "character", query: query)

        do {
            return try await fetchNextPage(at: url)
        } catch APIError.httpStatus(404) where !query.isEmpty {
            return CharacterPageDTO(
                info: .init(count: 0, pages: 0, next: nil, prev: nil),
                results: []
            )
        }
    }

    func fetchNextPage(at url: URL) async throws -> CharacterPageDTO {
        try await client.send(requests.get(url), as: CharacterPageDTO.self)
    }

    func fetchCharacter(id: Int) async throws -> CharacterDTO {
        let url = try requests.url(resource: "character/\(id)")
        return try await client.send(requests.get(url), as: CharacterDTO.self)
    }

    func fetchEpisodes(references: [URL]) async throws -> [EpisodeDTO] {
        let ids = try referenceIDs(references, resource: "episode")
        return try await fetchMany(ids: ids, resource: "episode", as: EpisodeDTO.self)
    }

    func fetchParticipants(references: [URL], excluding id: Int) async throws -> [CharacterDTO] {
        let ids = try referenceIDs(references, resource: "character").filter { $0 != id }
        return try await fetchMany(ids: ids, resource: "character", as: CharacterDTO.self)
    }

    private func referenceIDs(_ urls: [URL], resource: String) throws -> [Int] {
        try urls.map { url in
            let path = url.pathComponents
            guard path.count == 4, path[1] == "api", path[2] == resource,
                  let id = Int(path[3]), id > 0 else {
                throw APIError.invalidResponse
            }
            return id
        }
    }

    private func fetchMany<Item: Decodable & Identifiable & Sendable>(
        ids: [Int], resource: String, as type: Item.Type
    ) async throws -> [Item] where Item.ID == Int {
        var seen = Set<Int>()
        let orderedIDs = ids.filter { seen.insert($0).inserted }
        var items: [Int: Item] = [:]

        for start in stride(from: 0, to: orderedIDs.count, by: 20) {
            try Task.checkCancellation()
            let batch = orderedIDs[start..<min(start + 20, orderedIDs.count)]
            let path = batch.map(String.init).joined(separator: ",")
            let request = try requests.get(requests.url(resource: resource + "/" + path))

            if batch.count == 1 {
                let item = try await client.send(request, as: type)
                items[item.id] = item
            } else {
                for item in try await client.send(request, as: [Item].self) {
                    items[item.id] = item
                }
            }
        }

        return try orderedIDs.map { id in
            guard let item = items[id] else { throw APIError.invalidResponse }
            return item
        }
    }
}
