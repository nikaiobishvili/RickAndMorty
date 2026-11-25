import Foundation

/// Only API enum values are translated; proper names remain untouched.
enum CharacterDisplayText {
    static func localized(_ value: String, locale: Locale) -> String {
        switch value.lowercased() {
        case "any": AppLocalization.string("Any", locale: locale)
        case "alive": AppLocalization.string("Alive", locale: locale)
        case "dead": AppLocalization.string("Dead", locale: locale)
        case "unknown": AppLocalization.string("Unknown", locale: locale)
        case "female": AppLocalization.string("Female", locale: locale)
        case "male": AppLocalization.string("Male", locale: locale)
        case "genderless": AppLocalization.string("Genderless", locale: locale)
        case "human": AppLocalization.string("Human", locale: locale)
        case "alien": AppLocalization.string("Alien", locale: locale)
        default: value
        }
    }
}
