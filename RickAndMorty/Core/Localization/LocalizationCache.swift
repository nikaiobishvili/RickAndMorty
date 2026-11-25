import Foundation

nonisolated protocol LocalizationCache: Sendable {
    func load() async -> RemoteLocalization?
    func save(_ document: RemoteLocalization) async
}

actor DiskLocalizationCache: LocalizationCache {
    private let file: URL

    init(file: URL = URL.cachesDirectory.appending(path: "RickAndMortyLocalization/v1.json")) {
        self.file = file
    }

    func load() -> RemoteLocalization? {
        guard let data = try? Data(contentsOf: file), data.count <= 256 * 1024,
              let document = try? JSONDecoder().decode(RemoteLocalization.self, from: data),
              let valid = try? document.validated() else { return nil }
        return valid
    }

    func save(_ document: RemoteLocalization) {
        guard (try? document.validated()) != nil,
              let data = try? JSONEncoder().encode(document), data.count <= 256 * 1024 else { return }
        do {
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: file, options: .atomic)
        } catch { /* Bundled translations remain available if storage is full. */ }
    }
}
