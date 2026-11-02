//
//  ContentView.swift
//  RickAndMorty
//
//  Created by Nika Iobishvili on 25/10/2026.
//

import SwiftUI

struct CharacterListView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
            }
            .padding()
            .navigationTitle("Characters")
        }
    }
}

#Preview {
    CharacterListView()
}
