
import Foundation

nonisolated enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
}
