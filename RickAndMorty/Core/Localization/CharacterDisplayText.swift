import Foundation

/// Only API enum values are translated; proper names remain untouched.
enum CharacterDisplayText {
    static func localized(_ value: String, locale: Locale, localization: LocalizationStore? = nil) -> String {
        let key: LocalizationKey
        switch value.lowercased() {
        case "any": key = .anyText
        case "alive": key = .alive
        case "dead": key = .dead
        case "unknown": key = .unknown
        case "female": key = .female
        case "male": key = .male
        case "genderless": key = .genderless
        case "human": key = .human
        case "alien": key = .alien
        default: return value
        }
        return localization?.string(key, locale: locale)
            ?? AppLocalization.render(AppLocalization.bundledTemplate(key, locale: locale), arguments: [:])
    }
}
