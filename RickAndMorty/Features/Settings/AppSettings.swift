import Foundation
import Observation

/// Shared app preferences. Changes preserve navigation and existing screen data.
@MainActor
@Observable
final class AppSettings {
    private(set) var language: AppLanguage
    private(set) var appearance: AppAppearance
    private let store: any SettingsStore

    var locale: Locale { language.locale }

    init(store: (any SettingsStore)? = nil) {
        let store = store ?? UserDefaultsSettingsStore()
        self.store = store
        language = store.readLanguage()
        appearance = store.readAppearance()
    }

    func select(_ language: AppLanguage) {
        guard self.language != language else { return }
        store.saveLanguage(language)
        self.language = language
    }

    func selectTheme(_ theme: AppTheme) {
        var updated = appearance
        updated.theme = theme
        updateAppearance(updated)
    }

    private func updateAppearance(_ appearance: AppAppearance) {
        guard self.appearance != appearance else { return }
        store.saveAppearance(appearance)
        self.appearance = appearance
    }
}
