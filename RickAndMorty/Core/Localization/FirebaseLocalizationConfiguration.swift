import Foundation

nonisolated enum FirebaseLocalizationConfiguration {
    // Public translations only. REST does not require an API key or Firebase SDK.
    static let endpoint = URL(string: "https://rickandmorty-11c08-default-rtdb.europe-west1.firebasedatabase.app/localization/v1.json")!
}
