//
//  BookTileView.swift
//  HeadwayClone
//
//  Created by Aswinkumar Thulasiraman on 8/23/25.
//
import SwiftUI

struct BookTileView: View {
    let book: Book
    var onTap: (() -> Void)? = nil

    @State private var fetchedCoverURL: URL?

    private var displayURL: URL? {
        return fetchedCoverURL ?? book.coverURL
    }

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(spacing: 8) {
                // Use CachedImageView (Kingfisher) to load the cover
                CachedImageView(url: displayURL, placeholder: AnyView(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 140)
                        .overlay(ProgressView())
                ))
                .frame(height: 140)
                .clipped()
                .cornerRadius(12)
                .task {
                    // Quick attempt for a cover; if it fails within short timeout, fall back to a seeded image
                    if displayURL == nil {
                        CoverFetcher.shared.fetchCoverQuick(for: book.title, author: book.author) { url in
                            if let u = url {
                                DispatchQueue.main.async {
                                    self.fetchedCoverURL = u
                                }
                            } else {
                                // Fallback seeded image to avoid blank tiles while a full fetch runs
                                let seed = book.title.replacingOccurrences(of: " ", with: "_").lowercased()
                                if let fallback = URL(string: "https://picsum.photos/seed/\(seed)/400/600") {
                                    DispatchQueue.main.async {
                                        self.fetchedCoverURL = fallback
                                    }
                                }
                                // Also trigger full fetch in background
                                CoverFetcher.shared.fetchCover(for: book.title, author: book.author) { fullUrl in
                                    if let fu = fullUrl {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                            self.fetchedCoverURL = fu
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Book title
                Text(book.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)

                // Book author
                Text(book.author)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
