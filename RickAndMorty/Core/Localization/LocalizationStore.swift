import Foundation
import Observation

@MainActor
@Observable
final class LocalizationStore {
    private(set) var document: RemoteLocalization?
    private(set) var lastRefreshFailed = false
    private let provider: (any RemoteLocalizationProviding)?
    private let cache: (any LocalizationCache)?
    @ObservationIgnored private var didReadCache = false
    @ObservationIgnored private var refreshTask: Task<Void, Never>?

    init(provider: (any RemoteLocalizationProviding)? = nil, cache: (any LocalizationCache)? = nil) {
        self.provider = provider
        self.cache = cache
    }

    func string(_ key: LocalizationKey, locale: Locale, arguments: [String: String] = [:]) -> String {
        let requested = locale.language.languageCode?.identifier ?? "en"
        let code = ["en", "ka"].contains(requested) ? requested : "en"
        let template = document?.languages[code]?.strings[key.rawValue]
            ?? AppLocalization.bundledTemplate(key, locale: locale)
        return AppLocalization.render(template, arguments: arguments)
    }

    /// One request per foreground transition; concurrent callers share the same operation.
    /// The app can keep displaying bundled/cached text throughout the refresh.
    func refresh() async {
        if let refreshTask { await refreshTask.value; return }
        let task = Task { await performRefresh() }
        refreshTask = task
        await task.value
        refreshTask = nil
    }

    private func performRefresh() async {
        if !didReadCache {
            didReadCache = true
            if let cached = await cache?.load(), let valid = try? cached.validated() {
                document = valid
            }
        }
        guard let provider else { return }
        do {
            let incoming = try await provider.fetch().validated()
            // A delayed old snapshot must not replace a newer cached revision.
            guard incoming.revision >= (document?.revision ?? 0) else {
                lastRefreshFailed = true
                return
            }
            if incoming != document { document = incoming }
            lastRefreshFailed = false
            await cache?.save(incoming)
        } catch {
            lastRefreshFailed = true
        }
    }
}
