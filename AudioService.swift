import AVFoundation

class AudioService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = AudioService()
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isPlaying = false
    @Published var isPaused = false
    @Published var currentVoice: AVSpeechSynthesisVoice?
    @Published var rate: Float = 0.5
    
    override init() {
        super.init()
        synthesizer.delegate = self
        
        // Set default voice to English
        if let englishVoice = AVSpeechSynthesisVoice(language: "en-US") {
            currentVoice = englishVoice
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = true
            print("🔊 Started speaking")
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
            print("✅ Finished speaking")
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
            print("⏹️ Speech cancelled")
        }
    }
    
    func play(text: String, voice: AVSpeechSynthesisVoice?, rate: Float) {
        print("🎯 Attempting to play text with length: \(text.count)")
    stop()
    isPaused = false
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = rate
        
        // Store current settings
        currentVoice = utterance.voice
        self.rate = rate
        
        print("🎤 Using voice: \(utterance.voice?.name ?? "default")")
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        isPaused = false
    }

    func pause() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.pauseSpeaking(at: .word)
        isPaused = true
        isPlaying = false
    }

    func resume() {
        guard synthesizer.isPaused else { return }
        synthesizer.continueSpeaking()
        isPaused = false
        isPlaying = true
    }

    func togglePause() {
        if isPaused {
            resume()
        } else {
            pause()
        }
    }
    
    func availableVoices() -> [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
    }
}
