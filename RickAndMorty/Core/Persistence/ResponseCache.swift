import CryptoKit
import Foundation

nonisolated protocol ResponseCache: Sendable {
    func read(key: String) async -> HTTPPayload?
    func write(_ payload: HTTPPayload, key: String) async
}

/// Best-effort disposable cache: failures must never prevent online use.
actor DiskResponseCache: ResponseCache {
    static let shared = DiskResponseCache()
    private let directory: URL
    private let lifetime: TimeInterval
    private let byteLimit: Int
    private let now: @Sendable () -> Date

    private struct Entry: Codable {
        let savedAt: Date
        let payload: HTTPPayload
    }

    init(directory: URL = URL.cachesDirectory.appending(path: "RickAndMortyResponses"),
         lifetime: TimeInterval = 7 * 24 * 60 * 60,
         byteLimit: Int = 100 * 1024 * 1024,
         now: @escaping @Sendable () -> Date = { Date() }) {
        self.directory = directory
        self.lifetime = lifetime
        self.byteLimit = byteLimit
        self.now = now
    }

    func read(key: String) -> HTTPPayload? {
        let url = location(key)
        guard let data = try? Data(contentsOf: url),
              let entry = try? JSONDecoder().decode(Entry.self, from: data),
              now().timeIntervalSince(entry.savedAt) < lifetime,
              (200..<300).contains(entry.payload.statusCode) else {
            try? FileManager.default.removeItem(at: url)
            return nil
        }
        return entry.payload
    }

    func write(_ payload: HTTPPayload, key: String) {
        guard (200..<300).contains(payload.statusCode),
              let data = try? JSONEncoder().encode(Entry(savedAt: now(), payload: payload)),
              data.count <= byteLimit else { return }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: location(key), options: .atomic)
            trim()
        } catch { /* The app remains usable when storage is unavailable. */ }
    }

    private func location(_ key: String) -> URL {
        let digest = SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
        return directory.appending(path: digest + ".json")
    }

    private func trim() {
        let manager = FileManager.default
        guard let urls = try? manager.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
        ) else { return }
        let files = urls.compactMap { url -> (URL, Int, Date)? in
            guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]),
                  let size = values.fileSize, let date = values.contentModificationDate else { return nil }
            return (url, size, date)
        }.sorted { $0.2 < $1.2 }
        var total = files.reduce(0) { $0 + $1.1 }
        for (url, size, date) in files {
            if total > byteLimit || now().timeIntervalSince(date) >= lifetime {
                if (try? manager.removeItem(at: url)) != nil { total -= size }
            }
        }
    }
}
