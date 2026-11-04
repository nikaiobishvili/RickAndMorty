//
//  CharactersRepository.swift
//  RickAndMorty
//
//  Created by Nika Iobishvili on 04/11/2026.
//

import Foundation

nonisolated protocol CharactersRepository: Sendable {
    func fetchCharacters(name: String) async throws -> CharacterPageDTO
    func fetchNextPage(at url: URL) async throws -> CharacterPageDTO
}

nonisolated struct RemoteCharactersRepository: CharactersRepository {
    private let client: any APIClient

    init(client: any APIClient) {
        self.client = client
    }

    func fetchCharacters(name: String) async throws -> CharacterPageDTO {
        let query = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var components = URLComponents()
        components.scheme = "https"
        components.host = "rickandmortyapi.com"
        components.path = "/api/character"

        if !query.isEmpty {
            components.queryItems = [
                URLQueryItem(name: "name", value: query)
            ]
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            return try await client.send(
                request,
                as: CharacterPageDTO.self
            )
        } catch APIError.httpStatus(404) where !query.isEmpty {
            return CharacterPageDTO(
                info: .init(count: 0, pages: 0, next: nil, prev: nil),
                results: []
            )
        }
    }

    func fetchNextPage(at url: URL) async throws -> CharacterPageDTO {
        try await fetchPage(at: url)
    }

    private func fetchPage(at url: URL) async throws -> CharacterPageDTO {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        return try await client.send(
            request,
            as: CharacterPageDTO.self
        )
    }
}
