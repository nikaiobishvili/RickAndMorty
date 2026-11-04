//
//  CharacterListView.swift
//  RickAndMorty
//
//  Created by Nika Iobishvili on 25/10/2026.
//

import SwiftUI

struct CharacterListView: View {
    @State private var viewModel: CharacterListViewModel
    @State private var retryCount = 0
    @State private var nextPageRetryCount = 0

    init(viewModel: CharacterListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Characters")
                .navigationBarTitleDisplayMode(.large)
                .searchable(
                    text: $viewModel.searchText,
                    prompt: "Search characters"
                )
                .task(
                    id: LoadTrigger(query: viewModel.searchText, retryCount: retryCount)
                ) {
                    await viewModel.loadCharacters()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading characters…")
                .frame(maxWidth: .infinity,
                    maxHeight: .infinity
                )

        case .loaded(let characters):
            if characters.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(characters) { character in
                            CharacterRowView(
                                name: character.name,
                                status: character.status,
                                species: character.species
                            )
                        }
                        if let nextPageURL = viewModel.nextPageURL {
                            paginationFooter
                                .task(
                                    id: NextPageTrigger(
                                        url: nextPageURL,
                                        retryCount: nextPageRetryCount
                                    )
                                ) {
                                    await viewModel.loadNextPage()
                                }
                        }
                    }
                    .padding(16)
                }
            }

        case .failed(let message):
            ContentUnavailableView {
                Label("Could not load characters", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try again") {
                    retryCount += 1
                }
            }
        }
    }

    private var paginationFooter: some View {
        VStack(spacing: 8) {
            if let message = viewModel.nextPageError {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Retry loading more") {
                    nextPageRetryCount += 1
                }
            } else {
                ProgressView("Loading more…")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private struct NextPageTrigger: Equatable {
        let url: URL
        let retryCount: Int
    }

    private struct LoadTrigger: Equatable {
        let query: String
        let retryCount: Int
    }
}
