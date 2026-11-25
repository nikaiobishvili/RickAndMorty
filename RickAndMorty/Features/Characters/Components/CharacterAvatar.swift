import SwiftUI

struct CharacterAvatar: View {
    let url: URL?
    let size: CGFloat

    var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                ZStack {
                    Color(.tertiarySystemFill)
                    if phase.error == nil, url != nil {
                        ProgressView()
                    } else {
                        Image(systemName: "person.crop.square")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityHidden(true)
    }
}
