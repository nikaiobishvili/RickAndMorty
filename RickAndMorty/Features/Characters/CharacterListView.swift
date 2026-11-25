
import SwiftUI

struct CharacterListView: View {
    @Environment(LocalizationStore.self) private var localization
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
                        ProgressView { LocalizedText(.updatingCharacters) }
                            .padding(8).frame(maxWidth: .infinity)
                            .background(.regularMaterial)
                    }
                    if let message = viewModel.loadError {
                        VStack(spacing: 8) {
                            Text(message.localized(locale: locale, localization: localization)).font(.callout)
                            Button { retryCount += 1 } label: { LocalizedText(.tryAgain) }
                        }
                        .padding().frame(maxWidth: .infinity).background(.regularMaterial)
                        .accessibilityElement(children: .contain)
                    }
                }
                .background(AppBackgroundSurface())
                .navigationTitle(Text(localization.string(.characters, locale: locale)))
                .navigationBarTitleDisplayMode(.large)
                .searchable(
                    text: $viewModel.searchText,
                    prompt: Text(localization.string(.searchCharacters, locale: locale))
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
                        .accessibilityLabel(Text(localization.string(.settings, locale: locale)))
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
                        .accessibilityLabel(Text(localization.string(.filterCharacters, locale: locale)))
                        .accessibilityIdentifier("character-filters")
                    }
                }
                .sheet(item: $activeSheet) { sheet in
                    switch sheet {
                    case .filters: CharacterFiltersView(filters: $viewModel.filters)
                    case .settings:
                        SettingsView()
                            .presentationDragIndicator(.visible)
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
            ProgressView { LocalizedText(.loadingCharacters) }
                .frame(maxWidth: .infinity,
                    maxHeight: .infinity
                )

        case .loaded(let characters):
            if characters.isEmpty {
                ScrollView {
                    ContentUnavailableView {
                        Label { LocalizedText(.noCharactersFound) } icon: { Image(systemName: "magnifyingglass") }
                    } description: {
                        LocalizedText(.tryAnotherNameOrResetTheFilters)
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
                            .accessibilityHint(Text(localization.string(.openCharacterDetails, locale: locale)))
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
                Label { LocalizedText(.couldNotLoadCharacters) } icon: { Image(systemName: "exclamationmark.triangle") }
            } description: {
                Text(message.localized(locale: locale, localization: localization))
            } actions: {
                Button {
                    retryCount += 1
                } label: { LocalizedText(.tryAgain) }
            }
        }
    }

    private var paginationFooter: some View {
        VStack(spacing: 8) {
            if let message = viewModel.nextPageError {
                Text(message.localized(locale: locale, localization: localization))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    Task { await viewModel.loadNextPage(retry: true) }
                } label: { LocalizedText(.retryLoadingMore) }
            } else {
                ProgressView { LocalizedText(.loadingMore) }
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
