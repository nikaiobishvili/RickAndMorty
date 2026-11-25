
import Foundation

nonisolated struct CharacterPageDTO: Decodable, Sendable {
    let info: PageInfo
    let results: [CharacterDTO]

    struct PageInfo: Decodable, Sendable {
        let count: Int
        let pages: Int
        let next: URL?
        let prev: URL?
    }
}
