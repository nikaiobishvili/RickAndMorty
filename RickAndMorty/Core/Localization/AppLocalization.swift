import Foundation

enum AppLocalization {
    static func bundledTemplate(_ key: LocalizationKey, locale: Locale) -> String {
        let text = bundle(for: locale).localizedString(forKey: key.bundleKey, value: key.bundleKey, table: nil)
        return key == .theServerReturnedAnErrorLld ? text.replacingOccurrences(of: "%lld", with: "{code}") : text
    }

    static func render(_ template: String, arguments: [String: String]) -> String {
        arguments.reduce(template) { $0.replacingOccurrences(of: "{\($1.key)}", with: $1.value) }
    }

    private static func bundle(for locale: Locale) -> Bundle {
        let code = locale.language.languageCode?.identifier ?? "en"
        let path = Bundle.main.path(forResource: code, ofType: "lproj")
            ?? Bundle.main.path(forResource: "en", ofType: "lproj")
        return path.flatMap(Bundle.init(path:)) ?? .main
    }
}
