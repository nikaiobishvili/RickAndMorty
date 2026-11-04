//
//  CharacterListViewModel.swift
//  RickAndMorty
//
//  Created by Nika Iobishvili on 02/11/2026.
//
import Observation
import Foundation

@MainActor
@Observable
final class CharacterListViewModel {
    enum State {
        case idle
        case loading
        case loaded([CharacterDTO])
        case failed(String)
    }
    
    var searchText = ""
    private(set) var state: State = .idle
    private(set) var nextPageURL: URL?
    private(set) var isLoadingNextPage = false
    private(set) var nextPageError: String?
    
    @ObservationIgnored
    private var loadedQuery = ""
    @ObservationIgnored
    private let repository: any CharactersRepository
    @ObservationIgnored
    private var currentRequestID = UUID()
    
    init(repository: any CharactersRepository) {
        self.repository = repository
    }
    
    func loadCharacters() async {
        let requestID = UUID()
        currentRequestID = requestID
        
        nextPageURL = nil
        isLoadingNextPage = false
        nextPageError = nil
        state = .loading
        
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            if !query.isEmpty {
                try await Task.sleep(for: .milliseconds(300))
            }
            
            try Task.checkCancellation()
            
            let page = try await repository.fetchCharacters(
                name: query
            )
            
            try Task.checkCancellation()
            
            guard currentRequestID == requestID else {
                return
            }
            
            loadedQuery = query
            nextPageURL = page.info.next
            state = .loaded(page.results)
        } catch {
            guard currentRequestID == requestID else {
                return
            }
            
            if Task.isCancelled ||
                (error as? URLError)?.code == .cancelled {
                state = .idle
                return
            }
            
            state = .failed(message(for: error))
        }
    }
    
    func loadNextPage() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard query == loadedQuery,
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
            
            nextPageURL = page.info.next
            state = .loaded(existingCharacters + newCharacters)
        } catch {
            guard currentRequestID == requestID else {
                return
            }
            
            if Task.isCancelled ||
                (error as? URLError)?.code == .cancelled {
                return
            }
            
            nextPageError = message(for: error)
        }
    }
    
    private func message(for error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "You appear to be offline."
            case .timedOut:
                return "The request timed out. Please try again."
            default:
                return "Could not connect to the server."
            }
        }
        
        if error is DecodingError {
            return "The server returned data we could not read."
        }
        
        if case APIError.httpStatus(let code) = error {
            return "The server returned an error (\(code))."
        }
        
        return "Could not load characters. Please try again."
    }
}
