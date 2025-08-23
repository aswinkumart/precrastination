import SwiftUI

/// Lightweight cached image view using `AsyncImage`.
/// Uses system URLCache; not as feature-rich as Kingfisher but avoids an external dependency.
struct CachedImageView: View {
    let url: URL?
    let placeholder: AnyView

    init(url: URL?, placeholder: AnyView = AnyView(ProgressView())) {
        self.url = url
        self.placeholder = placeholder
    }

    var body: some View {
        if let u = url {
            AsyncImage(url: u) { phase in
                switch phase {
                case .empty:
                    placeholder
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }
}
