
import Foundation
import SwiftUI

struct CharacterRowView: View {
    let name: String
    let status: String
    let species: String
    var imageURL: URL? = nil

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 16))

        layout {
            CharacterAvatar(url: imageURL, size: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("\(status) · \(species)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
}

#Preview("Dark") {
    CharacterRowView(name: "Rick Sanchez", status: "Alive", species: "Human")
        .padding(16)
        .preferredColorScheme(.dark)
}
