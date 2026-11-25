import Foundation
import Testing
@testable import RickAndMorty

@MainActor
private final class MemorySettingsStore: SettingsStore {
    var language: AppLanguage = .system
    var appearance = AppAppearance()
    private(set) var writes = 0
    func readAppearance() -> AppAppearance { appearance }
    func saveAppearance(_ appearance: AppAppearance) { self.appearance = appearance }
    func readLanguage() -> AppLanguage { language }
    func saveLanguage(_ language: AppLanguage) { self.language = language; writes += 1 }
}

@MainActor
struct AppSettingsTests {
    @Test func selectionUpdatesLocaleAndIsRestoredByNewSettings() {
        let store = MemorySettingsStore()
        let settings = AppSettings(store: store)
        #expect(settings.language == .system)
        settings.select(.georgian)
        #expect(settings.locale.language.languageCode?.identifier == "ka")
        #expect(AppSettings(store: store).language == .georgian)
        settings.select(.georgian)
        #expect(store.writes == 1)
        settings.select(.system)
        #expect(AppSettings(store: store).language == .system)
    }

    @Test func userDefaultsPersistsSelectionAndUnknownValuesFallBackToSystem() throws {
        let suite = "AppSettingsTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        UserDefaultsSettingsStore(defaults: defaults).saveLanguage(.english)
        #expect(UserDefaultsSettingsStore(defaults: defaults).readLanguage() == .english)
        defaults.set("invalid-language", forKey: "appLanguage")
        #expect(UserDefaultsSettingsStore(defaults: defaults).readLanguage() == .system)
    }

    @Test func dynamicValuesAndExistingErrorsUseTheSelectedLanguage() {
        let english = Locale(identifier: "en")
        let georgian = Locale(identifier: "ka")
        #expect(CharacterDisplayText.localized("Alive", locale: georgian) == "ცოცხალი")
        #expect(CharacterDisplayText.localized("Alive", locale: english) == "Alive")
        #expect(CharacterDisplayText.localized("Rick Sanchez", locale: georgian) == "Rick Sanchez")
        let error = ErrorMessage(URLError(.notConnectedToInternet))
        #expect(error.localized(locale: english) == "You appear to be offline.")
        #expect(error.localized(locale: georgian) == "ინტერნეტთან კავშირი არ არის.")
        #expect(ErrorMessage.server(503).localized(locale: georgian) == "სერვერმა დააბრუნა შეცდომა (503).")
    }

    @Test func themePersistsIndependentlyOfLanguageAndLegacyColorsAreDiscarded() throws {
        let suite = "AppearanceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = AppSettings(store: UserDefaultsSettingsStore(defaults: defaults))
        settings.select(.georgian)
        settings.selectTheme(.dark)
        let restored = AppSettings(store: UserDefaultsSettingsStore(defaults: defaults))
        #expect(restored.language == .georgian)
        #expect(restored.appearance == AppAppearance(theme: .dark))
        settings.selectTheme(.light)
        #expect(settings.appearance.theme == .light)
        defaults.set(Data(#"{"theme":"dark","background":"rose"}"#.utf8), forKey: "appAppearance")
        #expect(UserDefaultsSettingsStore(defaults: defaults).readAppearance() == AppAppearance(theme: .dark))
        defaults.set(Data("broken".utf8), forKey: "appAppearance")
        #expect(UserDefaultsSettingsStore(defaults: defaults).readAppearance() == AppAppearance())
    }

}
