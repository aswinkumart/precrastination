import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var bookTitle = ""
    @State private var author = ""
    @State private var summary = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @ObservedObject private var audioService = AudioService.shared
    @State private var selectedVoice: AVSpeechSynthesisVoice?
    @State private var rate: Float = 0.5
    
    private func generateSummary() {
        isLoading = true
        errorMessage = nil
        print("🔍 Starting summary generation for '\(bookTitle)' by \(author)")
        
        LLMService.shared.fetchSummary(for: bookTitle, author: author) { result in
            DispatchQueue.main.async {
                isLoading = false
                if let result = result {
                    summary = result
                    print("✅ Summary generated successfully")
                } else {
                    errorMessage = "Failed to generate summary. Please check your API keys and internet connection."
                    print("❌ Failed to generate summary")
                }
            }
        }
    }
    
    private func playAudio() {
        guard !summary.isEmpty else {
            errorMessage = "No summary available to play"
            return
        }
        
        print("🔊 Playing audio with voice: \(selectedVoice?.name ?? "default") at rate: \(rate)")
        audioService.play(text: summary, voice: selectedVoice, rate: rate)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Book Title", text: $bookTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Author", text: $author)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Summarize & Generate Audio") {
                    generateSummary()
                }
                .disabled(bookTitle.isEmpty || author.isEmpty)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                ScrollView {
                    Text(summary.isEmpty ? "Summary will appear here" : summary)
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
                            playAudio()
                        }
                    }
                    .disabled(summary.isEmpty)
                    .padding()
                }
            }
            .padding()
            .navigationTitle("Headway Clone")
        }
    }
}
