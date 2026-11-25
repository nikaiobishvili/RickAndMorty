import Foundation

nonisolated struct EpisodeDTO: Decodable, Identifiable, Sendable {
    let id: Int
    let name: String
    let episode: String
    let airDate: String
    let characters: [URL]

    enum CodingKeys: String, CodingKey {
        case id, name, episode, characters
        case airDate = "air_date"
    }
}
