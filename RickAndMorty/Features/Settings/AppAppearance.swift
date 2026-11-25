import Foundation

nonisolated enum AppTheme: String, Codable, CaseIterable, Identifiable, Sendable {
    case light, dark
    var id: String { rawValue }
}

nonisolated struct AppAppearance: Codable, Equatable, Sendable {
    var theme: AppTheme = .light
}
