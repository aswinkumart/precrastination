import AVFoundation
import NaturalLanguage

@MainActor
class AudioService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = AudioService()
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isPlaying = false
    @Published var isPaused = false
    @Published var currentVoice: AVSpeechSynthesisVoice?
    @Published var rate: Float = 0.5
    /// When true, calling `stop()` will preserve the current sentence index so playback
    /// resumes from the same position; otherwise stop resets to the start.
    @Published var preservePositionOnStop: Bool = true

    // Internal queueing for sentence-level playback to support mid-playback rate changes
    private var sentences: [String] = []
    private var currentSentenceIndex: Int = 0
    private var currentText: String = ""
    
    override init() {
        super.init()
        synthesizer.delegate = self
        
        // Choose a human-like default voice from preferred list
        if let preferred = preferredVoices().first {
            currentVoice = preferred
        } else if let englishVoice = AVSpeechSynthesisVoice(language: "en-US") {
            currentVoice = englishVoice
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = true
            print("🔊 Started speaking")
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            // Move to next sentence if present
            self.currentSentenceIndex += 1
            if self.currentSentenceIndex < self.sentences.count {
                self.speakNextSentence()
            } else {
                self.isPlaying = false
                print("✅ Finished speaking")
            }
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
            print("⏹️ Speech cancelled")
        }
    }
    
    func play(text: String, voice: AVSpeechSynthesisVoice?, rate: Float) {
        print("🎯 Attempting to play text with length: \(text.count)")
    stop()
    isPaused = false

    // Prepare sentence-level queue
    self.currentText = text
    self.sentences = AudioService.splitIntoSentences(text)
    self.currentSentenceIndex = 0

    // Store current settings
    currentVoice = voice ?? AVSpeechSynthesisVoice(language: "en-US")
    self.rate = rate

    print("🎤 Using voice: \(currentVoice?.name ?? "default")")
    speakNextSentence()
    }
    
    /// Stop speaking. By default this follows the `preservePositionOnStop` setting.
    /// Pass `preservePosition` explicitly to override the setting for this call.
    func stop(preservePosition: Bool? = nil) {
        DispatchQueue.main.async {
            self.synthesizer.stopSpeaking(at: .immediate)
        }
        isPlaying = false
        isPaused = false

        let keepPosition = preservePosition ?? preservePositionOnStop
    if keepPosition {
            // Keep currentText and currentSentenceIndex so playback can resume where it left off.
            if currentText.isEmpty {
                sentences = []
                currentSentenceIndex = 0
            } else {
                // Ensure sentences array reflects currentText
                if sentences.isEmpty {
                    sentences = AudioService.splitIntoSentences(currentText)
                }
                // Do not modify currentSentenceIndex
            }
        } else {
            // Reset to the beginning so "Play" after Stop will start from start.
            if !currentText.isEmpty {
                self.sentences = AudioService.splitIntoSentences(currentText)
                self.currentSentenceIndex = 0
            } else {
                sentences = []
                currentSentenceIndex = 0
                currentText = ""
            }
        }
    }

    func pause() {
        // Pause if the synthesizer is speaking; regardless, update our published state
        if synthesizer.isSpeaking {
            DispatchQueue.main.async {
                self.synthesizer.pauseSpeaking(at: .word)
            }
        }
        isPaused = true
        isPlaying = false
    }

    func resume() {
    // Allow resume when either AVSpeechSynthesizer isPaused or our flag is true.
    guard synthesizer.isPaused || isPaused else { return }

        // To ensure rate/voice changes made while paused are applied, stop the
        // current utterance and re-speak the current sentence with the latest settings.
        DispatchQueue.main.async {
            self.synthesizer.stopSpeaking(at: .immediate)
            self.speakNextSentence()
        }
    isPaused = false
    isPlaying = true
    }

    func togglePause() {
        if isPaused {
            // If paused, resume and ensure updated voice/rate are used.
            resume()
        } else if isPlaying {
            // If currently playing, pause.
            pause()
        } else {
            // Not playing: start playback if we have prepared sentences (e.g., after Stop)
            if !sentences.isEmpty {
                // Ensure currentVoice and rate are used (they are read in speakNextSentence())
                speakNextSentence()
            }
        }
    }

    // Update rate while speaking: if currently playing (not paused), stop current utterance and resume from current sentence with new rate.
    func updateRate(_ newRate: Float) {
        DispatchQueue.main.async {
            self.rate = newRate
            if self.isPlaying && !self.isPaused {
                // Stop current utterance immediately and re-speak current sentence and the rest at new rate
                self.synthesizer.stopSpeaking(at: .immediate)
                self.speakNextSentence()
            }
        }
    }

    private func speakNextSentence() {
        // If sentences were cleared but we still have text (e.g., after stop), rebuild.
        if sentences.isEmpty && !currentText.isEmpty {
            sentences = AudioService.splitIntoSentences(currentText)
            currentSentenceIndex = 0
        }

        guard currentSentenceIndex < sentences.count else {
            // finished
            DispatchQueue.main.async {
                self.isPlaying = false
                self.isPaused = false
                self.currentSentenceIndex = 0
                self.sentences = []
            }
            return
        }

        let sentence = sentences[currentSentenceIndex]
        let utterance = AVSpeechUtterance(string: sentence)
        utterance.voice = currentVoice ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = rate

        DispatchQueue.main.async {
            self.isPlaying = true
            self.synthesizer.speak(utterance)
        }
    }
    
    func availableVoices() -> [AVSpeechSynthesisVoice] {
        return preferredVoices()
    }

    /// Returns a short list (up to 5) of preferred, human-like voices.
    private func preferredVoices() -> [AVSpeechSynthesisVoice] {
        let all = AVSpeechSynthesisVoice.speechVoices()
        // Prefer English voices first
        var english = all.filter { $0.language.lowercased().hasPrefix("en") }

        // Sort by common human-like names and language preference
    // Higher priority names first — tweakable per device / iOS version
    let preferredNames = ["Samantha", "Alex", "Daniel", "Moira", "Siri", "Serena", "Victoria", "Emma", "John", "Alloy"]
        english.sort { a, b in
            let ai = preferredNames.firstIndex(of: a.name) ?? Int.max
            let bi = preferredNames.firstIndex(of: b.name) ?? Int.max
            if ai != bi { return ai < bi }
            // prefer en-US over others
            if a.language == "en-US" && b.language != "en-US" { return true }
            if b.language == "en-US" && a.language != "en-US" { return false }
            return a.name < b.name
        }

        var result = english
        if result.count < 5 {
            // fill with other voices if not enough English voices
            let others = all.filter { !result.contains($0) }
            result.append(contentsOf: others.prefix(5 - result.count))
        }
        return Array(result.prefix(5))
    }

    // Helper: rudimentary sentence splitter (keeps punctuation)
    private static func splitIntoSentences(_ text: String) -> [String] {
        var sentences: [String] = []
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let s = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !s.isEmpty { sentences.append(s) }
            return true
        }
        return sentences.isEmpty ? [text] : sentences
    }
}
