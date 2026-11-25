
import SwiftUI

@main
struct RickAndMortyApp: App {
    @State private var settings: AppSettings = {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            let defaults = UserDefaults(suiteName: "RickAndMorty.UITests")!
            if ProcessInfo.processInfo.arguments.contains("--reset-settings") {
                defaults.removePersistentDomain(forName: "RickAndMorty.UITests")
            }
            return AppSettings(store: UserDefaultsSettingsStore(defaults: defaults))
        }
        #endif
        return AppSettings()
    }()

    private let repository: any CharactersRepository & CharacterDetailsRepository = {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") { return PreviewRepository() }
        #endif
        return RemoteCharactersRepository(client: URLSessionAPIClient())
    }()
    
    private var imageLoader: any ImageDataLoader {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") { return PreviewImageLoader() }
        #endif
        return RemoteImageDataLoader()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(repository: repository, imageLoader: imageLoader)
            .environment(settings)
        }
    }
}

/// A View observes language changes and updates the existing navigation hierarchy.
private struct AppRootView: View {
    @Environment(AppSettings.self) private var settings
    let repository: any CharactersRepository & CharacterDetailsRepository
    let imageLoader: any ImageDataLoader

    private var preferredScheme: ColorScheme? {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--dark-mode") { return .dark }
        #endif
        return settings.appearance.theme.colorScheme
    }

    var body: some View {
        CharacterListView(
            viewModel: CharacterListViewModel(repository: repository),
            detailsRepository: repository
        )
        .environment(\.locale, settings.locale)
        .environment(\.imageDataLoader, imageLoader)
        .preferredColorScheme(preferredScheme)
    }
}
