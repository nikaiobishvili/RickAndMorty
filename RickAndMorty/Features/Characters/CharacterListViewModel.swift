
import Observation
import Foundation

@MainActor
@Observable
final class CharacterListViewModel {
    enum State {
        case idle
        case loading
        case loaded([CharacterDTO])
        case failed(ErrorMessage)
    }
    
    var searchText = ""
    var filters = CharacterFilters()
    private(set) var state: State = .idle
    private(set) var nextPageURL: URL?
    private(set) var isLoadingNextPage = false
    private(set) var nextPageError: ErrorMessage?
    private(set) var isRefreshing = false
    private(set) var loadError: ErrorMessage?
    
    @ObservationIgnored
    private var loadedQuery = ""
    @ObservationIgnored
    private var loadedFilters = CharacterFilters()
    @ObservationIgnored
    private let repository: any CharactersRepository
    @ObservationIgnored
    private var currentRequestID = UUID()
    
    init(repository: any CharactersRepository) {
        self.repository = repository
    }
    
    /// Returning from details should keep the loaded pages and scroll position.
    func loadIfNeeded() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if case .loaded = state, query == loadedQuery,
           filters == loadedFilters, loadError == nil { return }
        await loadCharacters()
    }

    func loadCharacters(debounce: Bool = true) async {
        guard !Task.isCancelled else { return }
        let filters = self.filters
        let requestID = UUID()
        currentRequestID = requestID
        
        let previousNextPageURL = nextPageURL
        nextPageURL = nil
        isLoadingNextPage = false
        nextPageError = nil
        loadError = nil
        isRefreshing = true
        let previousState = state
        if case .loaded = state { } else { state = .loading }
        defer {
            if currentRequestID == requestID { isRefreshing = false }
        }
        
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            if debounce && !query.isEmpty {
                try await Task.sleep(for: .milliseconds(300))
            }
            
            try Task.checkCancellation()
            
            let page = try await repository.fetchCharacters(
                name: query, filters: filters
            )
            
            try Task.checkCancellation()
            
            guard currentRequestID == requestID else {
                return
            }
            
            loadedQuery = query
            loadedFilters = filters
            nextPageURL = page.info.next
            state = .loaded(page.results)
        } catch {
            guard currentRequestID == requestID else {
                return
            }
            
            if Task.isCancelled ||
                (error as? URLError)?.code == .cancelled {
                state = previousState
                nextPageURL = query == loadedQuery && filters == loadedFilters ? previousNextPageURL : nil
                return
            }
            
            if case .loaded = previousState {
                state = previousState
                nextPageURL = query == loadedQuery && filters == loadedFilters ? previousNextPageURL : nil
                loadError = ErrorMessage(error)
            } else {
                state = .failed(ErrorMessage(error))
            }
        }
    }
    
    func loadNextPage(retry: Bool = false) async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !Task.isCancelled,
              query == loadedQuery,
              filters == loadedFilters,
              nextPageError == nil || retry,
              !isLoadingNextPage,
              let url = nextPageURL,
              case .loaded = state else {
            return
        }
        
        let requestID = currentRequestID
        
        isLoadingNextPage = true
        nextPageError = nil
        
        defer {
            if currentRequestID == requestID {
                isLoadingNextPage = false
            }
        }
        
        do {
            let page = try await repository.fetchNextPage(at: url)
            
            try Task.checkCancellation()
            
            guard currentRequestID == requestID,
                  case .loaded(let existingCharacters) = state else {
                return
            }
            
            var seenIDs = Set(existingCharacters.map(\.id))
            
            let newCharacters = page.results.filter { character in
                seenIDs.insert(character.id).inserted
            }
            
            nextPageURL = page.info.next == url ? nil : page.info.next
            state = .loaded(existingCharacters + newCharacters)
        } catch {
            guard currentRequestID == requestID else {
                return
            }
            
            if Task.isCancelled ||
                (error as? URLError)?.code == .cancelled {
                return
            }
            
            nextPageError = ErrorMessage(error)
        }
    }
    
}
