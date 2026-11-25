import SwiftUI

struct CharacterDetailsView: View {
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
                ProgressView("Loading character…")
            case .failed(let message):
                ContentUnavailableView {
                    Label("Could not load character", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message.localized(locale: locale))
                } actions: {
                    Button("Try again") { retryCount += 1 }
                }
            case .loaded(let character, let episodes):
                details(character, episodes: episodes)
            }
        }
        .background(AppBackgroundSurface())
        .navigationTitle("Character Details")
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
                    DetailInfoRow(title: "Status", value: CharacterDisplayText.localized(character.status, locale: locale))
                    DetailInfoRow(title: "Species", value: CharacterDisplayText.localized(character.species, locale: locale))
                    if !character.type.isEmpty {
                        DetailInfoRow(title: "Type", value: character.type)
                    }
                    DetailInfoRow(title: "Gender", value: CharacterDisplayText.localized(character.gender, locale: locale))
                    DetailInfoRow(title: "Origin", value: CharacterDisplayText.localized(character.origin.name, locale: locale))
                    DetailInfoRow(title: "Last known location", value: CharacterDisplayText.localized(character.location.name, locale: locale))
                }
                .padding(16)
                .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))

                Text("Episodes").font(.title2.bold()).accessibilityAddTraits(.isHeader)
                if episodes.isEmpty {
                    Text("No episodes found.").foregroundStyle(.primary)
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
            .accessibilityValue(expanded ? Text("Expanded") : Text("Collapsed"))

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
            ProgressView("Loading participants…")
        case .some(.failed(let message)):
            VStack(alignment: .leading, spacing: 8) {
                Text(message.localized(locale: locale)).font(.callout).foregroundStyle(.primary)
                Button("Retry loading participants") {
                    participantRetries[episode.id, default: 0] += 1
                }
                .frame(minHeight: 44)
            }
        case .some(.loaded(let cast)):
            if cast.isEmpty {
                Text("No other participants.").foregroundStyle(.primary)
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
                            .accessibilityHint("Open character details")
                        }
                    }
                }
                .accessibilityIdentifier("participants-\(episode.id)")
            }
        }
    }
}
