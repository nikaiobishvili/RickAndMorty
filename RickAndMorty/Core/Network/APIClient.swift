//
//  APIClient.swift
//  RickAndMorty
//
//  Created by Nika Iobishvili on 04/11/2026.
//
import Foundation

nonisolated protocol APIClient: Sendable {
    func send<Response: Decodable & Sendable>(
        _ request: URLRequest,
        as responseType: Response.Type
    ) async throws -> Response
}

actor URLSessionAPIClient: APIClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func send<Response: Decodable & Sendable>(
        _ request: URLRequest,
        as responseType: Response.Type
    ) async throws -> Response {
        try Task.checkCancellation()

        let (data, response) = try await session.data(for: request)

        try Task.checkCancellation()

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.httpStatus(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(
            responseType,
            from: data
        )
    }
}
