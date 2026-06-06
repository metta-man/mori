import AudioToolbox
import AVFoundation
import Foundation

enum SettleBellTone: String, CaseIterable, Identifiable {
    case singingBowlA = "Singing Bowl A.wav"
    case defaultChime = "Default.mp3"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .singingBowlA: return "Singing Bowl"
        case .defaultChime: return "Soft Chime"
        }
    }

    var fileName: String {
        rawValue
    }
}

enum SettleBreathingCue {
    case inhale
    case exhale
    case hold

    var fileName: String {
        switch self {
        case .inhale: return "Singing Bowl E_2.wav"
        case .exhale: return "Singing Bowl A.wav"
        case .hold: return "Mokugyo.wav"
        }
    }

    var volume: Float {
        switch self {
        case .inhale, .exhale: return 0.6
        case .hold: return 0.7
        }
    }
}

final class SettleBellService {
    static let shared = SettleBellService()

    private var audioPlayer: AVAudioPlayer?
    private var inhaleAudioPlayer: AVAudioPlayer?
    private var exhaleAudioPlayer: AVAudioPlayer?
    private var holdAudioPlayer: AVAudioPlayer?
    private var inhaleFadeTimer: Timer?
    private var exhaleFadeTimer: Timer?

    private init() {}

    func playStartBell(_ tone: SettleBellTone = .singingBowlA) {
        play(tone)
    }

    func playIntervalBell(_ tone: SettleBellTone = .defaultChime) {
        play(tone, volume: 0.72)
    }

    func playEndingBell(_ tone: SettleBellTone = .singingBowlA) {
        play(tone)
    }

    func playBreathingCue(_ cue: SettleBreathingCue) {
        configureAudioSession()

        switch cue {
        case .inhale:
            fadeOutExhaleSound()
            holdAudioPlayer?.stop()
            inhaleAudioPlayer = makeCuePlayer(fileName: cue.fileName, volume: cue.volume)
            inhaleAudioPlayer?.play()
        case .exhale:
            fadeOutInhaleSound()
            holdAudioPlayer?.stop()
            exhaleAudioPlayer = makeCuePlayer(fileName: cue.fileName, volume: cue.volume)
            exhaleAudioPlayer?.play()
        case .hold:
            fadeOutInhaleSound()
            fadeOutExhaleSound()
            holdAudioPlayer = makeCuePlayer(fileName: cue.fileName, volume: cue.volume)
            holdAudioPlayer?.play()
        }
    }

    func fadeOutBreathingCue(_ cue: SettleBreathingCue) {
        switch cue {
        case .inhale:
            fadeOutInhaleSound()
        case .exhale:
            fadeOutExhaleSound()
        case .hold:
            holdAudioPlayer?.stop()
            holdAudioPlayer = nil
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        stopBreathingCues()
    }

    func stopBreathingCues() {
        inhaleFadeTimer?.invalidate()
        exhaleFadeTimer?.invalidate()
        inhaleFadeTimer = nil
        exhaleFadeTimer = nil
        inhaleAudioPlayer?.stop()
        exhaleAudioPlayer?.stop()
        holdAudioPlayer?.stop()
        inhaleAudioPlayer = nil
        exhaleAudioPlayer = nil
        holdAudioPlayer = nil
    }

    private func play(_ tone: SettleBellTone, volume: Float = 1.0) {
        configureAudioSession()

        guard let url = findAudioFile(named: tone.fileName) ?? findAudioFile(named: SettleBellTone.defaultChime.fileName) else {
            AudioServicesPlaySystemSound(1013)
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            AudioServicesPlaySystemSound(1013)
        }
    }

    private func makeCuePlayer(fileName: String, volume: Float) -> AVAudioPlayer? {
        guard let url = findAudioFile(named: fileName) else {
            AudioServicesPlaySystemSound(1013)
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            return player
        } catch {
            AudioServicesPlaySystemSound(1013)
            return nil
        }
    }

    private func fadeOutInhaleSound() {
        inhaleFadeTimer?.invalidate()
        inhaleFadeTimer = nil
        fadeOut(player: inhaleAudioPlayer) { [weak self] in
            self?.inhaleAudioPlayer = nil
            self?.inhaleFadeTimer = nil
        } assignTimer: { [weak self] timer in
            self?.inhaleFadeTimer = timer
        }
    }

    private func fadeOutExhaleSound() {
        exhaleFadeTimer?.invalidate()
        exhaleFadeTimer = nil
        fadeOut(player: exhaleAudioPlayer) { [weak self] in
            self?.exhaleAudioPlayer = nil
            self?.exhaleFadeTimer = nil
        } assignTimer: { [weak self] timer in
            self?.exhaleFadeTimer = timer
        }
    }

    private func fadeOut(
        player: AVAudioPlayer?,
        onComplete: @escaping () -> Void,
        assignTimer: @escaping (Timer?) -> Void
    ) {
        guard let player, player.isPlaying else {
            onComplete()
            return
        }

        let fadeDuration: TimeInterval = 1.5
        let steps = 30
        let stepDuration = fadeDuration / Double(steps)
        let startVolume = player.volume
        var currentStep = 0

        let timer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            currentStep += 1
            let progress = Double(currentStep) / Double(steps)
            player.volume = startVolume * Float(1.0 - progress)

            if currentStep >= steps {
                timer.invalidate()
                player.stop()
                onComplete()
            }
        }
        assignTimer(timer)
        RunLoop.current.add(timer, forMode: .common)
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            #if DEBUG
            print("[SettleBellService] Audio session failed: \(error.localizedDescription)")
            #endif
        }
    }

    private func findAudioFile(named name: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: nil) {
            return url
        }

        let baseName = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension

        if !ext.isEmpty, let url = Bundle.main.url(forResource: baseName, withExtension: ext) {
            return url
        }

        for candidateExtension in ["mp3", "wav", "caf", "m4a"] {
            if let url = Bundle.main.url(forResource: baseName, withExtension: candidateExtension) {
                return url
            }
        }

        return nil
    }
}
