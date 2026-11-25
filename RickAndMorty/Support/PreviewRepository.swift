#if DEBUG
import Foundation

/// Deterministic UI test data. The Release app always uses the remote repository.
nonisolated struct PreviewRepository: CharactersRepository, CharacterDetailsRepository {
    private func character(_ id: Int) -> CharacterDTO {
        CharacterDTO(id: id, name: id == 1 ? "Rick Sanchez" : id == 2 ? "Morty Smith" : "Character \(id)",
                     status: "Alive", species: "Human", image: URL(string: "https://rickandmortyapi.com/api/character/avatar/\(id).jpeg")!,
                     type: "", gender: "Male", origin: .init(name: "Earth"), location: .init(name: "Earth"),
                     episode: [URL(string: "https://rickandmortyapi.com/api/episode/1")!])
    }
    func fetchCharacters(name: String, filters: CharacterFilters) async throws -> CharacterPageDTO {
        let characters = [character(1), character(2)].filter {
            (name.isEmpty || $0.name.localizedCaseInsensitiveContains(name)) &&
            (filters.status == .any || filters.status == .alive) &&
            (filters.gender == .any || filters.gender == .male) &&
            (filters.species.isEmpty || $0.species.localizedCaseInsensitiveContains(filters.species))
        }
        return .init(info: .init(count: characters.count, pages: 1, next: nil, prev: nil), results: characters)
    }
    func fetchNextPage(at url: URL) async throws -> CharacterPageDTO { throw APIError.invalidURL }
    func fetchCharacter(id: Int) async throws -> CharacterDTO { character(id) }
    func fetchEpisodes(references: [URL]) async throws -> [EpisodeDTO] {
        [.init(id: 1, name: "Pilot", episode: "S01E01", airDate: "December 2, 2013",
               characters: (1...22).map { URL(string: "https://rickandmortyapi.com/api/character/\($0)")! })]
    }
    func fetchParticipants(references: [URL], excluding id: Int) async throws -> [CharacterDTO] {
        (1...22).filter { $0 != id }.map(character)
    }
}
#endif

#if DEBUG
nonisolated struct PreviewImageLoader: ImageDataLoader {
    func data(for url: URL) async throws -> Data {
        // A local one-pixel PNG keeps UI tests independent of networking.
        Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=")!
    }
}
#endif

#if DEBUG
nonisolated struct PreviewLocalizationProvider: RemoteLocalizationProviding {
    func fetch() async throws -> RemoteLocalization {
        RemoteLocalization(schemaVersion: 1, revision: 1, languages: [
            "en": .init(strings: ["settings": "Remote settings", "characters": "Remote characters",
                                  "app_language": "Remote language", "alive": "Remote Alive"]),
            "ka": .init(strings: ["settings": "პარამეტრები სერვერიდან", "characters": "პერსონაჟები სერვერიდან",
                                  "app_language": "ენა სერვერიდან", "alive": "ცოცხალი სერვერიდან",
                                  "the_language_changes_immediately_and_is_remembered_next_time_you_open_the_app": "ენა მაშინვე იცვლება და აპლიკაციის ხელახლა გახსნის შემდეგაც ინახება111."])
        ])
    }
}
#endif
