import SwiftUI

struct BookCoverPlaceholder: View {
    let title: String
    let author: String
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(color.opacity(0.3))
                    .overlay(
                        color.opacity(0.1)
                            .blur(radius: 20)
                    )
                
                VStack(spacing: 12) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                    
                    Text(author)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }
}
