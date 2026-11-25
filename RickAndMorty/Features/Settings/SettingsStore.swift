import Foundation

@MainActor
protocol SettingsStore {
    func readLanguage() -> AppLanguage
    func saveLanguage(_ language: AppLanguage)
    func readAppearance() -> AppAppearance
    func saveAppearance(_ appearance: AppAppearance)
}

struct UserDefaultsSettingsStore: SettingsStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func readLanguage() -> AppLanguage {
        defaults.string(forKey: "appLanguage").flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    func saveLanguage(_ language: AppLanguage) {
        defaults.set(language.rawValue, forKey: "appLanguage")
    }

    func readAppearance() -> AppAppearance {
        guard let data = defaults.data(forKey: "appAppearance"),
              let appearance = try? JSONDecoder().decode(AppAppearance.self, from: data) else {
            return AppAppearance()
        }
        return appearance
    }

    func saveAppearance(_ appearance: AppAppearance) {
        guard let data = try? JSONEncoder().encode(appearance) else { return }
        defaults.set(data, forKey: "appAppearance")
    }
}
