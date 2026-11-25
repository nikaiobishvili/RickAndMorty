import SwiftUI

struct CharacterDetailsView: View {
    @Environment(LocalizationStore.self) private var localization
    @State private var viewModel: CharacterDetailsViewModel
    @State private var retryCount = 0
    @State private var expandedEpisodes: Set<Int> = []
    @State private var participantRetries: [Int: Int] = [:]

    init(id: Int, repository: any CharacterDetailsRepository) {
        _viewModel = State(initialValue: CharacterDetailsViewModel(id: id, repository: repository))
    }

    @Environment(\.locale) private var locale

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView { LocalizedText(.loadingCharacter) }
            case .failed(let message):
                ContentUnavailableView {
                    Label { LocalizedText(.couldNotLoadCharacter) } icon: { Image(systemName: "exclamationmark.triangle") }
                } description: {
                    Text(message.localized(locale: locale, localization: localization))
                } actions: {
                    Button { retryCount += 1 } label: { LocalizedText(.tryAgain) }
                }
            case .loaded(let character, let episodes):
                details(character, episodes: episodes)
            }
        }
        .background(AppBackgroundSurface())
        .navigationTitle(Text(localization.string(.characterDetails, locale: locale)))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: retryCount) { await viewModel.load() }
    }

    private func details(_ character: CharacterDTO, episodes: [EpisodeDTO]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                CharacterAvatar(url: character.image, size: 120)
                Text(character.name)
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                VStack(alignment: .leading, spacing: 12) {
                    DetailInfoRow(title: .status, value: CharacterDisplayText.localized(character.status, locale: locale, localization: localization))
                    DetailInfoRow(title: .species, value: CharacterDisplayText.localized(character.species, locale: locale, localization: localization))
                    if !character.type.isEmpty {
                        DetailInfoRow(title: .typeText, value: character.type)
                    }
                    DetailInfoRow(title: .gender, value: CharacterDisplayText.localized(character.gender, locale: locale, localization: localization))
                    DetailInfoRow(title: .origin, value: CharacterDisplayText.localized(character.origin.name, locale: locale, localization: localization))
                    DetailInfoRow(title: .lastKnownLocation, value: CharacterDisplayText.localized(character.location.name, locale: locale, localization: localization))
                }
                .padding(16)
                .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))

                LocalizedText(.episodes)
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                if episodes.isEmpty {
                    LocalizedText(.noEpisodesFound).foregroundStyle(.primary)
                }
                ForEach(episodes) { episode in
                    episodeSection(episode)
                }
            }
            .frame(maxWidth: 700)
            .padding(16)
            .frame(maxWidth: .infinity)
        }
    }

    private func localizedDate(_ value: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM d, yyyy"
        guard let date = formatter.date(from: value) else { return value }
        return date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted).locale(locale))
    }

    private func episodeSection(_ episode: EpisodeDTO) -> some View {
        let expanded = expandedEpisodes.contains(episode.id)
        let retry = participantRetries[episode.id, default: 0]

        return VStack(alignment: .leading, spacing: 12) {
            Button {
                if expanded {
                    expandedEpisodes.remove(episode.id)
                } else {
                    expandedEpisodes.insert(episode.id)
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(episode.name).font(.headline)
                        Text(verbatim: "\(episode.episode) · \(localizedDate(episode.airDate))")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .accessibilityHidden(true)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("episode-\(episode.id)")
            .accessibilityValue(Text(localization.string(expanded ? .expanded : .collapsed, locale: locale)))

            if expanded {
                participantList(for: episode)
                    .task(id: retry) {
                        await viewModel.loadParticipants(for: episode, retry: retry > 0)
                    }
            }
        }
        .padding(12)
        .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func participantList(for episode: EpisodeDTO) -> some View {
        switch viewModel.participants[episode.id] {
        case .none, .some(.loading):
            ProgressView { LocalizedText(.loadingParticipants) }
        case .some(.failed(let message)):
            VStack(alignment: .leading, spacing: 8) {
                Text(message.localized(locale: locale, localization: localization))
                    .font(.callout)
                    .foregroundStyle(.primary)
                Button {
                    participantRetries[episode.id, default: 0] += 1
                } label: { LocalizedText(.retryLoadingParticipants) }
                .frame(minHeight: 44)
            }
        case .some(.loaded(let cast)):
            if cast.isEmpty {
                LocalizedText(.noOtherParticipants).foregroundStyle(.primary)
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 12) {
                        ForEach(cast) { character in
                            NavigationLink(value: character.id) {
                                VStack(spacing: 4) {
                                    CharacterAvatar(url: character.image, size: 72)
                                    Text(character.name)
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(width: 84)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("participant-\(character.id)")
                            .accessibilityLabel(character.name)
                            .accessibilityHint(Text(localization.string(.openCharacterDetails, locale: locale)))
                        }
                    }
                }
                .accessibilityIdentifier("participants-\(episode.id)")
            }
        }
    }
}
