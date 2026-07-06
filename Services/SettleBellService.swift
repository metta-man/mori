import AudioToolbox
import AVFoundation
import Foundation

final class SettleBellService {
    static let shared = SettleBellService()

    private var audioPlayer: AVAudioPlayer?
    private var inhaleAudioPlayer: AVAudioPlayer?
    private var exhaleAudioPlayer: AVAudioPlayer?
    private var holdAudioPlayer: AVAudioPlayer?
    private var inhaleFadeTimer: Timer?
    private var exhaleFadeTimer: Timer?
    private let audioSessionQueue = DispatchQueue(label: "com.mori.settleBell.audioSession", qos: .userInitiated)
    private let playbackGenerationLock = NSLock()
    private var audioSessionConfigured = false
    private var playbackGeneration = 0

    private init() {}

    func playStartBell(_ tone: SettleBellTone = .singingBowlA) {
        performOnMain { [weak self] in
            self?.play(tone)
        }
    }

    func playIntervalBell(_ tone: SettleBellTone = .defaultChime) {
        performOnMain { [weak self] in
            self?.play(tone, volume: 0.72)
        }
    }

    func playEndingBell(_ tone: SettleBellTone = .singingBowlA) {
        performOnMain { [weak self] in
            self?.play(tone)
        }
    }

    func playBreathingCue(_ cue: SettleBreathingCue) {
        performOnMain { [weak self] in
            self?.playBreathingCueOnMain(cue)
        }
    }

    private func playBreathingCueOnMain(_ cue: SettleBreathingCue) {
        let requestID = nextPlaybackGeneration()

        prepareForBreathingCue(cue)
        preparePlayer(fileName: cue.fileName, volume: cue.volume) { [weak self] player in
            guard let self, self.playbackGenerationIsCurrent(requestID) else { return }
            guard let player else {
                self.playFallbackSound()
                return
            }
            self.playPreparedBreathingCue(cue, player: player, generation: requestID)
        }
    }

    func fadeOutBreathingCue(_ cue: SettleBreathingCue) {
        performOnMain { [weak self] in
            switch cue {
            case .inhale:
                self?.fadeOutInhaleSound()
            case .exhale:
                self?.fadeOutExhaleSound()
            case .hold:
                self?.holdAudioPlayer?.stop()
                self?.holdAudioPlayer = nil
            }
        }
    }

    func stop() {
        performOnMain { [weak self] in
            self?.cancelPendingPlayback()
            self?.audioPlayer?.stop()
            self?.audioPlayer = nil
            self?.stopBreathingCuesOnMain(cancelPendingPlayback: false)
        }
    }

    func stopBreathingCues() {
        performOnMain { [weak self] in
            self?.stopBreathingCuesOnMain()
        }
    }

    private func stopBreathingCuesOnMain(cancelPendingPlayback shouldCancelPendingPlayback: Bool = true) {
        if shouldCancelPendingPlayback {
            cancelPendingPlayback()
        }

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
        let requestID = nextPlaybackGeneration()

        preparePlayer(
            fileName: tone.fileName,
            fallbackFileName: SettleBellTone.defaultChime.fileName,
            volume: volume
        ) { [weak self] player in
            guard let self, self.playbackGenerationIsCurrent(requestID) else { return }
            guard let player else {
                self.playFallbackSound()
                return
            }
            self.audioPlayer = player
            self.playPreparedPlayer(player, generation: requestID)
        }
    }

    private func prepareForBreathingCue(_ cue: SettleBreathingCue) {
        switch cue {
        case .inhale:
            fadeOutExhaleSound()
            holdAudioPlayer?.stop()
        case .exhale:
            fadeOutInhaleSound()
            holdAudioPlayer?.stop()
        case .hold:
            fadeOutInhaleSound()
            fadeOutExhaleSound()
        }
    }

    private func playPreparedBreathingCue(_ cue: SettleBreathingCue, player: AVAudioPlayer, generation: Int) {
        switch cue {
        case .inhale:
            inhaleAudioPlayer = player
        case .exhale:
            exhaleAudioPlayer = player
        case .hold:
            holdAudioPlayer = player
        }
        playPreparedPlayer(player, generation: generation)
    }

    private func preparePlayer(
        fileName: String,
        fallbackFileName: String? = nil,
        volume: Float,
        completion: @escaping (AVAudioPlayer?) -> Void
    ) {
        audioSessionQueue.async { [weak self] in
            guard let self else { return }

            self.configureAudioSessionOnQueue()

            guard let url = self.findAudioFile(named: fileName)
                ?? fallbackFileName.flatMap({ self.findAudioFile(named: $0) })
            else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = volume
                player.prepareToPlay()
                DispatchQueue.main.async {
                    completion(player)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
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

        let fadeDuration = SettleBreathingCue.fadeDuration
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

    private func performOnMain(_ action: @escaping () -> Void) {
        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.async(execute: action)
        }
    }

    private func nextPlaybackGeneration() -> Int {
        playbackGenerationLock.lock()
        defer { playbackGenerationLock.unlock() }
        playbackGeneration += 1
        return playbackGeneration
    }

    private func cancelPendingPlayback() {
        playbackGenerationLock.lock()
        defer { playbackGenerationLock.unlock() }
        playbackGeneration += 1
    }

    private func playbackGenerationIsCurrent(_ generation: Int) -> Bool {
        playbackGenerationLock.lock()
        defer { playbackGenerationLock.unlock() }
        return playbackGeneration == generation
    }

    private func playPreparedPlayer(_ player: AVAudioPlayer, generation: Int) {
        audioSessionQueue.async { [weak self, weak player] in
            guard let self, let player, self.playbackGenerationIsCurrent(generation) else { return }
            player.play()
        }
    }

    private func configureAudioSessionOnQueue() {
        do {
            let session = AVAudioSession.sharedInstance()
            if !audioSessionConfigured {
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                audioSessionConfigured = true
            }
            try session.setActive(true)
        } catch {
            #if DEBUG
            print("[SettleBellService] Audio session failed: \(error.localizedDescription)")
            #endif
        }
    }

    private func playFallbackSound() {
        AudioServicesPlaySystemSound(1013)
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
