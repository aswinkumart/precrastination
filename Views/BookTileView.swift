import SwiftUI

struct BookTileView: View {
    let book: Book
    @State private var isPlaying = false
    @State private var summary: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            ZStack {
                // Book Cover (remote)
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))

                    if let url = book.coverURL {
                        CachedImageView(url: url, placeholderColor: .gray)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        BookCoverPlaceholder(title: book.title, author: book.author, color: .gray)
                    }

                    // Subtle gradient overlay
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.25)]), startPoint: .center, endPoint: .bottom))
                        .blendMode(.overlay)
                }
                .shadow(radius: 5)
                
                // Loading Overlay
                if isLoading {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.7))
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
                
                // Play Button
                if !isLoading {
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                        )
                }
            }
            .frame(height: 200)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(book.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 3)
        .onTapGesture {
            handleTap()
        }
    }
    
    private func handleTap() {
        if !isLoading && !isPlaying {
            isLoading = true
            LLMService.shared.fetchSummary(for: book.title, author: book.author) { result in
                if let summary = result {
                    self.summary = summary
                    AudioService.shared.speak(summary) {
                        isPlaying = false
                    }
                    isPlaying = true
                }
                isLoading = false
            }
        } else if isPlaying {
            AudioService.shared.stopSpeaking()
            isPlaying = false
        }
    }
}
