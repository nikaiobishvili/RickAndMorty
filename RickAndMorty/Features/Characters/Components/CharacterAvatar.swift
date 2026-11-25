import SwiftUI

struct CharacterAvatar: View {
    let url: URL?
    let size: CGFloat
    @Environment(\.imageDataLoader) private var loader
    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        ZStack {
            Color(.tertiarySystemFill)
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else if url != nil && !failed {
                ProgressView()
            } else {
                Image(systemName: "person.crop.square").foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityHidden(true)
        .task(id: url) {
            image = nil
            failed = false
            guard let url else { return }
            do {
                let data = try await loader.data(for: url)
                try Task.checkCancellation()
                image = UIImage(data: data)
                failed = image == nil
            } catch {
                if !Task.isCancelled { failed = true }
            }
        }
    }
}
