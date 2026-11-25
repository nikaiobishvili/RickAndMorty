import SwiftUI

struct CharacterDetailsView: View {
    @State private var viewModel: CharacterDetailsViewModel
    @State private var retryCount = 0
    @State private var expandedEpisodes: Set<Int> = []
    @State private var participantRetries: [Int: Int] = [:]

    init(id: Int, repository: any CharacterDetailsRepository) {
        _viewModel = State(initialValue: CharacterDetailsViewModel(id: id, repository: repository))
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading character…")
            case .failed:
                ContentUnavailableView {
                    Label("Could not load character", systemImage: "exclamationmark.triangle")
                } actions: {
                    Button("Try again") { retryCount += 1 }
                }
            case .loaded(let character, let episodes):
                details(character, episodes: episodes)
            }
        }
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
                    LabeledContent("Status", value: character.status)
                    LabeledContent("Species", value: character.species)
                    if !character.type.isEmpty {
                        LabeledContent("Type", value: character.type)
                    }
                    LabeledContent("Gender", value: character.gender)
                    LabeledContent("Origin", value: character.origin.name)
                    LabeledContent("Last known location", value: character.location.name)
                }
                .padding(16)
                .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))

                Text("Episodes").font(.title2.bold()).accessibilityAddTraits(.isHeader)
                if episodes.isEmpty {
                    Text("No episodes found.").foregroundStyle(.secondary)
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
                        Text("\(episode.episode) · \(episode.airDate)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .accessibilityHidden(true)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
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
        case .some(.failed):
            Button("Retry loading participants") {
                participantRetries[episode.id, default: 0] += 1
            }
        case .some(.loaded(let cast)):
            if cast.isEmpty {
                Text("No other participants.").foregroundStyle(.secondary)
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
                        }
                    }
                }
            }
        }
    }
}
