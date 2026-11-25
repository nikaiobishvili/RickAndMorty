import SwiftUI

private struct ImageLoaderKey: EnvironmentKey {
    static let defaultValue: any ImageDataLoader = RemoteImageDataLoader()
}

extension EnvironmentValues {
    var imageDataLoader: any ImageDataLoader {
        get { self[ImageLoaderKey.self] }
        set { self[ImageLoaderKey.self] = newValue }
    }
}
