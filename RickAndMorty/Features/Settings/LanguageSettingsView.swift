import SwiftUI

struct LanguageSettingsView: View {
    @Environment(LocalizationStore.self) private var localization
    @Environment(AppSettings.self) private var settings

    var body: some View {
        Form {
            Section {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        settings.select(language)
                    } label: {
                        HStack {
                            label(for: language)
                            Spacer()
                            if settings.language == language {
                                Image(systemName: "checkmark").accessibilityHidden(true)
                            }
                        }
                        .font(.body)
                        .foregroundStyle(Color.primary)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("language-\(language.rawValue)")
                    .accessibilityAddTraits(settings.language == language ? .isSelected : [])
                }
            } footer: {
                LocalizedText(.theLanguageChangesImmediatelyAndIsRememberedNextTimeYouOpenTheApp)
                    .font(.footnote)
                    .foregroundStyle(Color.primary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppBackgroundSurface(grouped: true))
        .navigationTitle(Text(localization.string(.appLanguage, locale: settings.locale)))
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.locale, settings.locale)
    }

    @ViewBuilder
    private func label(for language: AppLanguage) -> some View {
        switch language {
        case .system: LocalizedText(.followSystem)
        case .english: Text(verbatim: "English")
        case .georgian: Text(verbatim: "ქართული")
        }
    }
}
