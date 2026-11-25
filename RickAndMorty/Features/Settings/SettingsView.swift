import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    LanguageSettingsView()
                } label: {
                    Label("App language", systemImage: "globe")
                }
                .accessibilityIdentifier("open-language-settings")

                NavigationLink {
                    BackgroundSettingsView()
                } label: {
                    Label("Light or Dark", systemImage: "paintpalette")
                }
                .accessibilityIdentifier("open-background-settings")

            }
            .scrollContentBackground(.hidden)
            .background(AppBackgroundSurface(grouped: true))
            .navigationTitle(Text(AppLocalization.string("Settings", locale: settings.locale)))
            .navigationBarTitleDisplayMode(.inline)
        }
        .environment(\.locale, settings.locale)
        .preferredColorScheme(settings.appearance.theme.colorScheme)
    }
}
