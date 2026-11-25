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
    func localized(locale: Locale, localization: LocalizationStore? = nil) -> String {
        let key: LocalizationKey
        var arguments: [String: String] = [:]
        switch self {
        case .offline: key = .youAppearToBeOffline
        case .timedOut: key = .theRequestTimedOutPleaseTryAgain
        case .connection: key = .couldNotConnectToTheServer
        case .decoding: key = .theServerReturnedDataWeCouldNotRead
        case .server(let code):
            key = .theServerReturnedAnErrorLld
            arguments["code"] = String(code)
        case .unknown: key = .couldNotLoadDataPleaseTryAgain
        }
        return localization?.string(key, locale: locale, arguments: arguments)
            ?? AppLocalization.render(AppLocalization.bundledTemplate(key, locale: locale), arguments: arguments)
    }
}
