import SwiftUI

struct CharacterFiltersView: View {
    @Environment(LocalizationStore.self) private var localization
    @Binding var filters: CharacterFilters
    @Environment(\.dismiss) private var dismiss
    @State private var draft: CharacterFilters

    init(filters: Binding<CharacterFilters>) {
        _filters = filters
        _draft = State(initialValue: filters.wrappedValue)
    }

    @Environment(\.locale) private var locale

    var body: some View {
        NavigationStack {
            Form {
                Picker(selection: $draft.status) {
                    ForEach(CharacterFilters.Status.allCases, id: \.self) {
                        Text(CharacterDisplayText.localized($0.rawValue.capitalized, locale: locale, localization: localization)).tag($0)
                    }
                } label: { LocalizedText(.status) }
                Picker(selection: $draft.gender) {
                    ForEach(CharacterFilters.Gender.allCases, id: \.self) {
                        Text(CharacterDisplayText.localized($0.rawValue.capitalized, locale: locale, localization: localization)).tag($0)
                    }
                } label: { LocalizedText(.gender) }
                TextField(text: $draft.species, prompt: Text(localization.string(.species, locale: locale))) { LocalizedText(.species) }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                LocalizedText(.enterSpeciesInEnglishForExampleHumanOrAlien)
                    .font(.footnote).foregroundStyle(.secondary)
                Button { draft = CharacterFilters() } label: { LocalizedText(.resetFilters) }
            }
            .scrollContentBackground(.hidden)
            .background(AppBackgroundSurface(grouped: true))
            .navigationTitle(Text(localization.string(.filters, locale: locale)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { LocalizedText(.cancel) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        filters = draft
                        dismiss()
                    } label: { LocalizedText(.apply) }
                }
            }
        }
    }
}
