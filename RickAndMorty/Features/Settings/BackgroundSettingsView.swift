import SwiftUI

struct BackgroundSettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        Form {
            Section {
                ForEach(AppTheme.allCases) { theme in
                    Button {
                        settings.selectTheme(theme)
                    } label: {
                        HStack {
                            Text(theme.title)
                            Spacer()
                            if settings.appearance.theme == theme {
                                Image(systemName: "checkmark").accessibilityHidden(true)
                            }
                        }
                        .font(.body)
                        .foregroundStyle(Color.primary)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("theme-\(theme.rawValue)")
                    .accessibilityAddTraits(settings.appearance.theme == theme ? .isSelected : [])
                }
            } footer: {
                Text("The background changes immediately and is remembered next time you open the app.")
                    .font(.footnote).foregroundStyle(Color.primary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppBackgroundSurface(grouped: true))
        .navigationTitle(Text(AppLocalization.string("Background", locale: settings.locale)))
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.locale, settings.locale)
    }
}
