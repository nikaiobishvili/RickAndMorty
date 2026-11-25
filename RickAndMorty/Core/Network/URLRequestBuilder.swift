import Foundation

nonisolated struct URLRequestBuilder: Sendable {
    private let host = "rickandmortyapi.com"

    func url(resource: String, query: [URLQueryItem] = []) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/api/" + resource
        components.queryItems = query.isEmpty ? nil : query

        guard let url = components.url else { throw APIError.invalidURL }
        return url
    }

    func get(_ url: URL) throws -> URLRequest {
        guard url.scheme == "https", url.host == host,
              url.port == nil || url.port == 443,
              url.user == nil, url.password == nil,
              url.path.hasPrefix("/api/") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}
