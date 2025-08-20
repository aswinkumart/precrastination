import AVFoundation

class AudioService: ObservableObject {
    static let shared = AudioService()
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isPlaying = false
    @Published var currentVoice: AVSpeechSynthesisVoice?
    @Published var rate: Float = 0.5
    
    func play(text: String, voice: AVSpeechSynthesisVoice?, rate: Float) {
        stop()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = rate
        synthesizer.speak(utterance)
        isPlaying = true
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
    }
    
    func availableVoices() -> [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
    }
}
