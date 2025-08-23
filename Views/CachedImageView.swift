import SwiftUI
import Kingfisher

struct CachedImageView: View {
    let url: URL?
    let placeholderColor: Color

    var body: some View {
        Group {
            if let url = url {
                KFImage(url)
                    .resizable()
                    .placeholder {
                        Rectangle().fill(placeholderColor.opacity(0.2))
                    }
                    .cancelOnDisappear(true)
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle().fill(placeholderColor.opacity(0.2))
            }
        }
    }
}
