import Foundation

/// Store error meaning rather than a translation, so visible errors change language immediately.
nonisolated enum ErrorMessage: Equatable, Sendable {
    case offline, timedOut, connection, decoding, server(Int), unknown

    init(_ error: Error) {
        if let error = error as? URLError {
            switch error.code {
            case .notConnectedToInternet: self = .offline
            case .timedOut: self = .timedOut
            default: self = .connection
            }
        } else if error is DecodingError {
            self = .decoding
        } else if case APIError.httpStatus(let code) = error {
            self = .server(code)
        } else {
            self = .unknown
        }
    }

    @MainActor
    func localized(locale: Locale) -> String {
        switch self {
        case .offline: AppLocalization.string("You appear to be offline.", locale: locale)
        case .timedOut: AppLocalization.string("The request timed out. Please try again.", locale: locale)
        case .connection: AppLocalization.string("Could not connect to the server.", locale: locale)
        case .decoding: AppLocalization.string("The server returned data we could not read.", locale: locale)
        case .server(let code): AppLocalization.string("The server returned an error (\(code)).", locale: locale)
        case .unknown: AppLocalization.string("Could not load data. Please try again.", locale: locale)
        }
    }
}
