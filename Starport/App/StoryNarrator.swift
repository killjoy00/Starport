import AVFoundation
import Foundation

/// Device-native text-to-speech; no remote audio service, user account, or
/// recording. One book segment is spoken at a time, with optional continuation
/// on the next page. Releasing the view immediately stops narration.
@MainActor
final class StoryNarrator: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published private(set) var isPlaying = false
    @Published private(set) var isPaused = false

    private let speaker = AVSpeechSynthesizer()
    private var activeUtterance: AVSpeechUtterance?
    private var onPageFinished: (() -> Void)?

    override init() {
        super.init()
        speaker.delegate = self
    }

    func read(_ text: String, speed: Float, then nextPage: @escaping () -> Void) {
        stop()
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // The iPhone can continue to speak with the screen awake; an explicit
        // recording or microphone permission is never needed.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = min(AVSpeechUtteranceMaximumSpeechRate,
                             max(AVSpeechUtteranceMinimumSpeechRate,
                                 AVSpeechUtteranceDefaultSpeechRate * speed))
        activeUtterance = utterance
        onPageFinished = nextPage
        isPlaying = true
        isPaused = false
        speaker.speak(utterance)
    }

    func pause() {
        guard isPlaying, !isPaused else { return }
        if speaker.pauseSpeaking(at: .word) { isPaused = true }
    }

    func resume() {
        guard isPlaying, isPaused else { return }
        if speaker.continueSpeaking() { isPaused = false }
    }

    func stop() {
        activeUtterance = nil
        onPageFinished = nil
        if speaker.isSpeaking || speaker.isPaused {
            speaker.stopSpeaking(at: .immediate)
        }
        isPlaying = false
        isPaused = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance) {
        guard activeUtterance === utterance else { return }
        activeUtterance = nil
        isPlaying = false
        isPaused = false
        let finished = onPageFinished
        onPageFinished = nil
        // Do not enqueue the next utterance inside AVSpeechSynthesizer's
        // callback. Let it finish tearing down the previous audio segment.
        DispatchQueue.main.async { finished?() }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didCancel utterance: AVSpeechUtterance) {
        guard activeUtterance === utterance else { return }
        activeUtterance = nil
        onPageFinished = nil
        isPlaying = false
        isPaused = false
    }
}
