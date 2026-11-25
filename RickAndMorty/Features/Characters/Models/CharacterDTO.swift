
import Foundation

nonisolated struct CharacterDTO: Decodable, Identifiable, Sendable {
    let id: Int
    let name: String
    let status: String
    let species: String
    let image: URL
    let type: String
    let gender: String
    let origin: LocationReference
    let location: LocationReference
    let episode: [URL]

    struct LocationReference: Decodable, Sendable {
        let name: String
    }
}
