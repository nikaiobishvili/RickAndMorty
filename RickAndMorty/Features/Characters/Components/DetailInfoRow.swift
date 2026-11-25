import SwiftUI

struct DetailInfoRow: View {
    let title: LocalizedStringKey
    let value: String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let largeText = dynamicTypeSize.isAccessibilitySize
        let layout = largeText
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 16))
        layout {
            Text(title).font(.subheadline)
            Text(value)
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity, alignment: largeText ? .leading : .trailing)
                .multilineTextAlignment(largeText ? .leading : .trailing)
        }
        .foregroundStyle(.primary)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }
}
