import SwiftUI
import AVFoundation

struct ContentView: View {
    // State
    @State private var selectedBook: Book?
    @State private var isPlaying = false
    @State private var errorMessage: String?
    @ObservedObject private var audioService = AudioService.shared
    @State private var isLoadingSummary = false
    @State private var currentSummary: String = ""
    
    // Layout
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
    ]
    
    // Header View - Simplified
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Discover Insights")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Tap any book to listen to its summary")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    
    // Grid View - image tiles
    private var booksGridView: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(0 ..< Book.featured.count, id: \.self) { index in
                let book = Book.featured[index]
                BookTileView(book: book, onTap: {
                    // Start loading summary and play when ready
                    selectedBook = book
                    isLoadingSummary = true
                    currentSummary = ""
                    LLMService.shared.fetchSummary(for: book.title, author: book.author) { summary in
                        DispatchQueue.main.async {
                            isLoadingSummary = false
                            currentSummary = summary ?? "Unable to fetch summary."
                            if !currentSummary.isEmpty {
                                audioService.play(text: currentSummary, voice: audioService.currentVoice, rate: audioService.rate)
                            }
                        }
                    }
                })
                .frame(height: 280)
            }
        }
        .padding(.horizontal)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerView
                        booksGridView
                    }
                    .padding(.vertical)
                }
                
                // Bottom mini player overlay
                if isLoadingSummary {
                    VStack {
                        Spacer()
                        HStack {
                            ProgressView()
                            Text("Generating summary...")
                                .foregroundColor(.primary)
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding()
                        .background(BlurView(style: .systemMaterial))
                        .cornerRadius(12)
                        .padding()
                    }
                    .transition(.move(edge: .bottom))
                } else if audioService.isPlaying || !currentSummary.isEmpty {
                    VStack {
                        Spacer()
                        VStack(spacing: 8) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading) {
                                    Text(selectedBook?.title ?? "")
                                        .font(.headline)
                                    Text(selectedBook?.author ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                // Play / Pause / Stop
                                HStack(spacing: 8) {
                                    Button(action: {
                                        audioService.togglePause()
                                    }) {
                                        Image(systemName: audioService.isPaused ? "play.fill" : "pause.fill")
                                            .font(.title2)
                                            .padding(8)
                                    }
                                    Button(action: {
                                        audioService.stop()
                                    }) {
                                        Image(systemName: "stop.fill")
                                            .font(.title2)
                                            .padding(8)
                                    }
                                }
                            }

                            // Controls: Voice picker and speed slider
                            HStack(spacing: 12) {
                                // Voice picker
                                Menu {
                                    ForEach(AudioService.shared.availableVoices(), id: \.name) { voice in
                                        Button(voice.name) {
                                            audioService.currentVoice = voice
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(audioService.currentVoice?.name ?? "Voice")
                                            .font(.subheadline)
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                    }
                                    .padding(8)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                                }

                                // Speed slider
                                VStack(alignment: .leading) {
                                    Text("Speed")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Slider(value: Binding(get: {
                                        Double(audioService.rate)
                                    }, set: { newVal in
                                        audioService.rate = Float(newVal)
                                    }), in: 0.3...0.7)
                                }
                            }
                        }
                        .padding()
                        .background(BlurView(style: .systemMaterial))
                        .cornerRadius(12)
                        .padding()
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Prefetch covers for all featured books so stock images appear quickly.
                DispatchQueue.global(qos: .background).async {
                    for book in Book.featured {
                        CoverFetcher.shared.fetchCoverQuick(for: book.title, author: book.author) { _ in }
                        // Also start a full fetch to populate persistent cache
                        CoverFetcher.shared.fetchCover(for: book.title, author: book.author) { _ in }
                    }
                }
            }
        }
    }
    
        // no dynamic loader - using static `Book.featured`
}

// Helper for error alert
private struct ErrorWrapper: Identifiable {
    let id = UUID()
    let message: String
}

// Add this Color extension to support hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
