import SwiftUI

/// Wrapper around `AsyncImage` with a placeholder and an error state.
///
/// Limitation: `AsyncImage` relies only on `URLCache` and does not cache decoded
/// images in memory. For long lists in production, a custom image loader
/// (NSCache plus deduplication) or a library (Kingfisher, Nuke) is often used.
struct RemoteImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeInOut)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .failure:
                placeholder(systemImage: "photo")
            case .empty:
                placeholder(systemImage: nil)
            @unknown default:
                placeholder(systemImage: nil)
            }
        }
        .accessibilityHidden(true)
    }

    private func placeholder(systemImage: String?) -> some View {
        ZStack {
            Rectangle().fill(.quaternary)
            if let systemImage {
                Image(systemName: systemImage).foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
        }
    }
}
