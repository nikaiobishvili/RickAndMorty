//
//  RickAndMortyApp.swift
//  RickAndMorty
//
//  Created by Nika Iobishvili on 25/10/2026.
//

import SwiftUI

@main
struct RickAndMortyApp: App {
    private let repository = RemoteCharactersRepository(client: URLSessionAPIClient())
    
    var body: some Scene {
        WindowGroup {
            CharacterListView(
                viewModel: CharacterListViewModel(
                    repository: repository
                )
            )
        }
    }
}
