
import Foundation
import SwiftUI

struct CharacterRowView: View {
    @Environment(LocalizationStore.self) private var localization
    let name: String
    let status: String
    let species: String
    var imageURL: URL? = nil
    var isLoading = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Environment(\.locale) private var locale

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 16))

        layout {
            ZStack {
                CharacterAvatar(url: imageURL, size: 64)
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .accessibilityLabel(Text(localization.string(.loadingCharacters, locale: locale)))
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(verbatim: "\(CharacterDisplayText.localized(status, locale: locale, localization: localization)) · \(CharacterDisplayText.localized(species, locale: locale, localization: localization))")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light")  {
    CharacterRowView(
        name: "Rick Sanchez",
        status: "Alive",
        species: "Human"
    )
    .padding(16)
    .preferredColorScheme(.light)
    .environment(LocalizationStore())
}

#Preview("Dark") {
    CharacterRowView(name: "Rick Sanchez", status: "Alive", species: "Human")
        .padding(16)
        .preferredColorScheme(.dark)
        .environment(LocalizationStore())
}

#Preview("Loading") {
    CharacterRowView(name: "Rick Sanchez", status: "Alive", species: "Human", isLoading: true)
        .padding(16)
        .environment(LocalizationStore())
}
