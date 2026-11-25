import Foundation
import Observation

@MainActor
@Observable
final class CharacterDetailsViewModel {
    enum State {
        case loading
        case loaded(CharacterDTO, [EpisodeDTO])
        case failed(ErrorMessage)
    }

    enum ParticipantsState {
        case loading
        case loaded([CharacterDTO])
        case failed(ErrorMessage)
    }

    private(set) var state: State = .loading
    private(set) var participants: [Int: ParticipantsState] = [:]

    @ObservationIgnored
    private var participantRequests: [Int: UUID] = [:]

    private let id: Int
    private let repository: any CharacterDetailsRepository

    init(id: Int, repository: any CharacterDetailsRepository) {
        self.id = id
        self.repository = repository
    }

    func load() async {
        if case .loaded = state { return }
        state = .loading
        do {
            let character = try await repository.fetchCharacter(id: id)
            let episodes = try await repository.fetchEpisodes(references: character.episode)
            try Task.checkCancellation()
            state = .loaded(character, episodes)
        } catch {
            if !Task.isCancelled, (error as? URLError)?.code != .cancelled {
                state = .failed(ErrorMessage(error))
            }
        }
    }

    func loadParticipants(for episode: EpisodeDTO, retry: Bool = false) async {
        guard !Task.isCancelled else { return }
        switch participants[episode.id] {
        case .some(.loaded):
            return
        case .some(.failed) where !retry:
            return
        default:
            break
        }

        let requestID = UUID()
        participantRequests[episode.id] = requestID
        participants[episode.id] = .loading
        defer {
            if participantRequests[episode.id] == requestID {
                participantRequests[episode.id] = nil
            }
        }
        do {
            let cast = try await repository.fetchParticipants(
                references: episode.characters, excluding: id
            )
            try Task.checkCancellation()
            guard participantRequests[episode.id] == requestID else { return }
            participants[episode.id] = .loaded(cast)
        } catch {
            guard participantRequests[episode.id] == requestID else { return }
            participants[episode.id] = Task.isCancelled || (error as? URLError)?.code == .cancelled
                ? nil : .failed(ErrorMessage(error))
        }
    }
}
