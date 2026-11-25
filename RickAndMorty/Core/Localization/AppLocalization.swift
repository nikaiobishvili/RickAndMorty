import Foundation

enum AppLocalization {
    static func string(_ value: String.LocalizationValue, locale: Locale) -> String {
        let code = locale.language.languageCode?.identifier ?? "en"
        let path = Bundle.main.path(forResource: code, ofType: "lproj")
            ?? Bundle.main.path(forResource: "en", ofType: "lproj")
        let bundle = path.flatMap(Bundle.init(path:)) ?? .main
        return String(localized: value, bundle: bundle, locale: locale)
    }
}
