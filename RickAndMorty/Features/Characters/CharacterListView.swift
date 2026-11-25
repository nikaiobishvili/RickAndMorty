
import SwiftUI

struct CharacterListView: View {
    @State private var viewModel: CharacterListViewModel
    @State private var retryCount = 0
    @State private var showingFilters = false
    private let detailsRepository: any CharacterDetailsRepository

    init(viewModel: CharacterListViewModel, detailsRepository: any CharacterDetailsRepository) {
        self.detailsRepository = detailsRepository
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
                    id: LoadTrigger(query: viewModel.searchText, filters: viewModel.filters, retryCount: retryCount)
                ) {
                    await viewModel.loadCharacters()
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingFilters = true
                        } label: {
                            Image(systemName: viewModel.filters == CharacterFilters()
                                  ? "line.3.horizontal.decrease.circle"
                                  : "line.3.horizontal.decrease.circle.fill")
                        }
                        .accessibilityLabel("Filter characters")
                    }
                }
                .sheet(isPresented: $showingFilters) {
                    CharacterFiltersView(filters: $viewModel.filters)
                }
                .navigationDestination(for: Int.self) { id in
                    CharacterDetailsView(id: id, repository: detailsRepository)
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
                            NavigationLink(value: character.id) {
                                CharacterRowView(
                                    name: character.name,
                                    status: character.status,
                                    species: character.species,
                                    imageURL: character.image
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        if let nextPageURL = viewModel.nextPageURL {
                            paginationFooter.task(id: nextPageURL) {
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
                    Task { await viewModel.loadNextPage(retry: true) }
                }
            } else {
                ProgressView("Loading more…")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private struct LoadTrigger: Equatable {
        let query: String
        let filters: CharacterFilters
        let retryCount: Int
    }
}
