import SwiftUI

struct CharacterFiltersView: View {
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
                Picker("Status", selection: $draft.status) {
                    ForEach(CharacterFilters.Status.allCases, id: \.self) {
                        Text(CharacterDisplayText.localized($0.rawValue.capitalized, locale: locale)).tag($0)
                    }
                }
                Picker("Gender", selection: $draft.gender) {
                    ForEach(CharacterFilters.Gender.allCases, id: \.self) {
                        Text(CharacterDisplayText.localized($0.rawValue.capitalized, locale: locale)).tag($0)
                    }
                }
                TextField("Species", text: $draft.species)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Text("Enter species in English, for example Human or Alien.")
                    .font(.footnote).foregroundStyle(.secondary)
                Button("Reset filters") { draft = CharacterFilters() }
            }
            .scrollContentBackground(.hidden)
            .background(AppBackgroundSurface(grouped: true))
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        filters = draft
                        dismiss()
                    }
                }
            }
        }
    }
}
