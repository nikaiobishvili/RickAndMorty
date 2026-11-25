import SwiftUI

struct CharacterFiltersView: View {
    @Binding var filters: CharacterFilters
    @Environment(\.dismiss) private var dismiss
    @State private var draft: CharacterFilters

    init(filters: Binding<CharacterFilters>) {
        _filters = filters
        _draft = State(initialValue: filters.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Status", selection: $draft.status) {
                    ForEach(CharacterFilters.Status.allCases, id: \.self) {
                        Text($0.rawValue.capitalized).tag($0)
                    }
                }
                Picker("Gender", selection: $draft.gender) {
                    ForEach(CharacterFilters.Gender.allCases, id: \.self) {
                        Text($0.rawValue.capitalized).tag($0)
                    }
                }
                TextField("Species", text: $draft.species)
                Button("Reset filters") { draft = CharacterFilters() }
            }
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
