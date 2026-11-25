import SwiftUI

/// Both remote activation and in-app language selection update this view.
struct LocalizedText: View {
    let key: LocalizationKey
    @Environment(LocalizationStore.self) private var localization
    @Environment(\.locale) private var locale

    init(_ key: LocalizationKey) { self.key = key }

    var body: some View {
        Text(verbatim: localization.string(key, locale: locale))
    }
}
