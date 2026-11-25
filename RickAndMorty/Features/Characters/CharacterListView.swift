
import SwiftUI

struct CharacterListView: View {
    @State private var viewModel: CharacterListViewModel
    @State private var retryCount = 0
    @State private var activeSheet: Sheet?
    @Environment(\.locale) private var locale
    private let detailsRepository: any CharacterDetailsRepository

    init(viewModel: CharacterListViewModel, detailsRepository: any CharacterDetailsRepository) {
        self.detailsRepository = detailsRepository
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .safeAreaInset(edge: .top, spacing: 0) {
                    if viewModel.isRefreshing, case .loaded = viewModel.state {
                        ProgressView("Updating characters…")
                            .padding(8).frame(maxWidth: .infinity)
                            .background(.regularMaterial)
                    }
                    if let message = viewModel.loadError {
                        VStack(spacing: 8) {
                            Text(message.localized(locale: locale)).font(.callout)
                            Button("Try again") { retryCount += 1 }
                        }
                        .padding().frame(maxWidth: .infinity).background(.regularMaterial)
                        .accessibilityElement(children: .contain)
                    }
                }
                .background(AppBackgroundSurface())
                .navigationTitle("Characters")
                .navigationBarTitleDisplayMode(.large)
                .searchable(
                    text: $viewModel.searchText,
                    prompt: "Search characters"
                )
                .task(
                    id: LoadTrigger(query: viewModel.searchText, filters: viewModel.filters, retryCount: retryCount)
                ) {
                    await viewModel.loadIfNeeded()
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            activeSheet = .settings
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityLabel("Settings")
                        .accessibilityIdentifier("app-settings")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            activeSheet = .filters
                        } label: {
                            Image(systemName: viewModel.filters == CharacterFilters()
                                  ? "line.3.horizontal.decrease.circle"
                                  : "line.3.horizontal.decrease.circle.fill")
                        }
                        .accessibilityLabel("Filter characters")
                        .accessibilityIdentifier("character-filters")
                    }
                }
                .sheet(item: $activeSheet) { sheet in
                    switch sheet {
                    case .filters: CharacterFiltersView(filters: $viewModel.filters)
                    case .settings: SettingsView()
                    }
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
                ScrollView {
                    ContentUnavailableView {
                        Label("No characters found", systemImage: "magnifyingglass")
                    } description: {
                        Text("Try another name or reset the filters.")
                    }
                }
                .refreshable { await viewModel.loadCharacters(debounce: false) }
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
                            .accessibilityIdentifier("character-\(character.id)")
                            .accessibilityHint("Open character details")
                        }
                        if let nextPageURL = viewModel.nextPageURL {
                            paginationFooter.task(id: nextPageURL) {
                                await viewModel.loadNextPage()
                            }
                        }
                    }
                    .frame(maxWidth: 700)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                }
                .refreshable { await viewModel.loadCharacters(debounce: false) }
            }

        case .failed(let message):
            ContentUnavailableView {
                Label("Could not load characters", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message.localized(locale: locale))
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
                Text(message.localized(locale: locale))
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

    private enum Sheet: Identifiable {
        case filters, settings
        var id: Self { self }
    }

    private struct LoadTrigger: Equatable {
        let query: String
        let filters: CharacterFilters
        let retryCount: Int
    }
}
