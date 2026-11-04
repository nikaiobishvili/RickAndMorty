//
//  CharacterDTO.swift
//  RickAndMorty
//
//  Created by Nika Iobishvili on 04/11/2026.
//

import Foundation

struct CharacterDTO: Decodable, Identifiable, Sendable {
    let id: Int
    let name: String
    let status: String
    let species: String
    let image: URL
}
