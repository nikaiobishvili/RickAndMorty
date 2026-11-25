import SwiftUI

extension AppTheme {
    var colorScheme: ColorScheme {
        switch self {
        case .light: .light
        case .dark: .dark
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

/// Semantic backgrounds follow the app's explicitly selected Light or Dark theme.
struct AppBackgroundSurface: View {
    var grouped = false

    var body: some View {
        Color(uiColor: grouped ? .systemGroupedBackground : .systemBackground)
            .ignoresSafeArea()
    }
}
