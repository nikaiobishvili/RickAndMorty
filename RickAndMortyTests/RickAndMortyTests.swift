//
//  RickAndMortyTests.swift
//  RickAndMortyTests
//
//  Created by Nika Iobishvili on 26/10/2026.
//

import Testing
@testable import RickAndMorty

@MainActor
struct CharacterListViewModelTests {
    @Test
    func emptySearchReturnsAllCharacters() {
        let viewModel = CharacterListViewModel()

        #expect(viewModel.filteredCharacters.map(\.id) == [1, 2, 3, 4, 5])
    }

    @Test
    func searchMatchesNameRegardlessOfCase() {
        let viewModel = CharacterListViewModel()
        viewModel.searchText = "sMiTh"

        #expect(viewModel.filteredCharacters.map(\.id) == [2, 3, 4, 5])
    }

    @Test
    func searchIgnoresSurroundingWhitespace() {
        let viewModel = CharacterListViewModel()
        viewModel.searchText = " \nRick \n"

        #expect(viewModel.filteredCharacters.map(\.id) == [1])
    }

    @Test
    func unmatchedSearchReturnsEmptyResults() {
        let viewModel = CharacterListViewModel()
        viewModel.searchText = "zzzz"

        #expect(viewModel.filteredCharacters.isEmpty)
    }

    @Test
    func clearingSearchRestoresAllCharacters() {
        let viewModel = CharacterListViewModel()
        viewModel.searchText = "Rick"

        #expect(viewModel.filteredCharacters.map(\.id) == [1])

        viewModel.searchText = ""

        #expect(viewModel.filteredCharacters.map(\.id) == [1, 2, 3, 4, 5])
    }
}
