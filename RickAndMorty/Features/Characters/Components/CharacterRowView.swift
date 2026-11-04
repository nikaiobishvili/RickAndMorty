//
//  CharacterRowView.swift
//  RickAndMorty
//
//  Created by Nika Iobishvili on 03/11/2026.
//

import Foundation
import SwiftUI

struct CharacterRowView: View {
    let name: String
    let status: String
    let species: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.square.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("\(status) · \(species)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light")  {
    CharacterRowView(
        name: "Rick Sanches",
        status: "Alive",
        species: "Human"
    )
    .padding(16)
    .preferredColorScheme(.light)
}

//#Preview("Dark") {
//    CharacterRowView(
//        name: "Rick Sanchez",
//        status: "Alive",
//        species: "Human"
//    )
//    .padding(16)
//    .preferredColorScheme(.dark)
//}
