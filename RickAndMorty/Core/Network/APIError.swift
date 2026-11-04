//
//  APIError.swift
//  RickAndMorty
//
//  Created by Nika Iobishvili on 04/11/2026.
//

import Foundation

nonisolated enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
}
