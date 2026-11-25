import Foundation

nonisolated struct CharacterFilters: Equatable, Sendable {
    var status = Status.any
    var gender = Gender.any
    var species = ""

    enum Status: String, CaseIterable {
        case any, alive, dead, unknown
    }

    enum Gender: String, CaseIterable {
        case any, female, male, genderless, unknown
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if status != .any { items.append(.init(name: "status", value: status.rawValue)) }
        if gender != .any { items.append(.init(name: "gender", value: gender.rawValue)) }
        let value = species.trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.isEmpty { items.append(.init(name: "species", value: value)) }
        return items
    }
}
