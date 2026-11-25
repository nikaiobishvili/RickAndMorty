import SwiftUI

struct SettingsView: View {
    @Environment(LocalizationStore.self) private var localization
    @Environment(AppSettings.self) private var settings

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    LanguageSettingsView()
                } label: {
                    Label { LocalizedText(.appLanguage) } icon: { Image(systemName: "globe") }
                }
                .accessibilityIdentifier("open-language-settings")

                NavigationLink {
                    BackgroundSettingsView()
                } label: {
                    Label { LocalizedText(.lightOrDark) } icon: { Image(systemName: "paintpalette") }
                }
                .accessibilityIdentifier("open-background-settings")
            }
            .scrollContentBackground(.hidden)
            .background(AppBackgroundSurface(grouped: true))
            .navigationTitle(Text(localization.string(.settings, locale: settings.locale)))
            .navigationBarTitleDisplayMode(.inline)
        }
        .environment(\.locale, settings.locale)
        .preferredColorScheme(settings.appearance.theme.colorScheme)
    }
}
