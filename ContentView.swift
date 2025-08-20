import SwiftUI

struct ContentView: View {
    @State private var bookTitle = ""
    @State private var author = ""
    @State private var summary = ""
    @State private var isLoading = false
    @ObservedObject private var audioService = AudioService.shared
    @State private var selectedVoice: AVSpeechSynthesisVoice?
    @State private var rate: Float = 0.5
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Book Title", text: $bookTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Author", text: $author)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Summarize & Generate Audio") {
                    isLoading = true
                    LLMService.shared.fetchSummary(for: bookTitle, author: author) { result in
                        summary = result ?? "No summary found."
                        isLoading = false
                    }
                }
                .disabled(bookTitle.isEmpty || author.isEmpty)
                if isLoading {
                    ProgressView()
                }
                ScrollView {
                    Text(summary)
                        .padding()
                }
                HStack {
                    Picker("Voice", selection: $selectedVoice) {
                        ForEach(audioService.availableVoices(), id: \ .identifier) { voice in
                            Text(voice.name).tag(voice as AVSpeechSynthesisVoice?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    Slider(value: $rate, in: 0.4...0.6, step: 0.05) {
                        Text("Speed")
                    }
                    .frame(width: 100)
                }
                HStack {
                    Button(audioService.isPlaying ? "Stop" : "Play") {
                        if audioService.isPlaying {
                            audioService.stop()
                        } else {
                            audioService.play(text: summary, voice: selectedVoice, rate: rate)
                        }
                    }
                    .padding()
                }
            }
            .padding()
            .navigationTitle("Headway Clone")
        }
    }
}
