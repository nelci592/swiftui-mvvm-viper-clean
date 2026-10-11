import SwiftUI

struct NextPageFooter: View {
    let errorMessage: String?
    let retry: () -> Void

    var body: some View {
        HStack {
            Spacer()
            if let errorMessage {
                VStack(spacing: 8) {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry", action: retry)
                        .buttonStyle(.bordered)
                }
            } else {
                ProgressView()
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .listRowSeparator(.hidden)
    }
}
