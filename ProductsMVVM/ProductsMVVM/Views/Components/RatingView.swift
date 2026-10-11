import SwiftUI

struct RatingView: View {
    let rating: Double

    var body: some View {
        Label {
            Text(rating, format: .number.precision(.fractionLength(1)))
        } icon: {
            Image(systemName: "star.fill").foregroundStyle(.yellow)
        }
        .font(.caption)
        .labelStyle(.titleAndIcon)
        .accessibilityLabel("Rating \(rating.formatted(.number.precision(.fractionLength(1)))) out of 5")
    }
}
