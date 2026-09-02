import AudioToolbox
import AVFoundation
import Foundation

protocol SettleBellAudioSessionManaging: AnyObject {
    var secondaryAudioShouldBeSilencedHint: Bool { get }
    var isOtherAudioPlaying: Bool { get }

    func configureForMixedPlayback() throws
    func activateForPlayback() throws
    func deactivateAfterPlayback() throws
}

final class SystemSettleBellAudioSessionManager: SettleBellAudioSessionManaging {
    private let session: AVAudioSession

    init(session: AVAudioSession = .sharedInstance()) {
        self.session = session
    }

    var secondaryAudioShouldBeSilencedHint: Bool {
        session.secondaryAudioShouldBeSilencedHint
    }

    var isOtherAudioPlaying: Bool {
        session.isOtherAudioPlaying
    }

    func configureForMixedPlayback() throws {
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
    }

    func activateForPlayback() throws {
        try session.setActive(true)
    }

    func deactivateAfterPlayback() throws {
        try session.setActive(false, options: [.notifyOthersOnDeactivation])
    }
}

enum SettleBellAudioInterruptionPolicy {
    static func shouldPlaySecondaryAudio(
        secondaryAudioShouldBeSilenced: Bool,
        isOtherAudioPlaying: Bool
    ) -> Bool {
        !secondaryAudioShouldBeSilenced && !isOtherAudioPlaying
    }
}

private enum SettleBellPlayerPreparationOutcome {
    case ready(AVAudioPlayer)
    case suppressed
    case failed
}

private enum SettleBellAudioActivationOutcome {
    case activated
    case suppressed
    case failed
}

final class SettleBellService: NSObject, AVAudioPlayerDelegate {
    static let shared = SettleBellService()

    private var audioPlayer: AVAudioPlayer?
    private var inhaleAudioPlayer: AVAudioPlayer?
    private var exhaleAudioPlayer: AVAudioPlayer?
    private var holdAudioPlayer: AVAudioPlayer?
    private var inhaleFadeTimer: Timer?
    private var exhaleFadeTimer: Timer?
    private let audioSessionQueue = DispatchQueue(label: "com.mori.settleBell.audioSession", qos: .userInitiated)
    private let audioSessionManager: SettleBellAudioSessionManaging
    private let playbackGenerationLock = NSLock()
    private var audioSessionConfigured = false
    private var audioSessionOwned = false
    private var pendingPlayerPreparations = 0
    private var playbackGeneration = 0

    private override init() {
        audioSessionManager = SystemSettleBellAudioSessionManager()
        super.init()
    }

    init(audioSessionManager: SettleBellAudioSessionManaging) {
        self.audioSessionManager = audioSessionManager
        super.init()
    }

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
        preparePlayer(fileName: cue.fileName, volume: cue.volume) { [weak self] outcome in
            guard let self else { return }
            switch outcome {
            case .ready(let player):
                guard self.playbackGenerationIsCurrent(requestID) else {
                    self.discardPreparedPlayer(player)
                    return
                }
                self.playPreparedBreathingCue(cue, player: player, generation: requestID)
            case .suppressed:
                break
            case .failed:
                self.playFallbackSoundIfPermitted()
            }
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
                self?.deactivateAudioSessionIfIdleOnMain()
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
        deactivateAudioSessionIfIdleOnMain()
    }

    private func play(_ tone: SettleBellTone, volume: Float = 1.0) {
        let requestID = nextPlaybackGeneration()

        preparePlayer(
            fileName: tone.fileName,
            fallbackFileName: SettleBellTone.defaultChime.fileName,
            volume: volume
        ) { [weak self] outcome in
            guard let self else { return }
            switch outcome {
            case .ready(let player):
                guard self.playbackGenerationIsCurrent(requestID) else {
                    self.discardPreparedPlayer(player)
                    return
                }
                self.audioPlayer = player
                self.playPreparedPlayer(player, generation: requestID)
            case .suppressed:
                break
            case .failed:
                self.playFallbackSoundIfPermitted()
            }
        }
    }

    private func prepareForBreathingCue(_ cue: SettleBreathingCue) {
        switch cue {
        case .inhale:
            fadeOutExhaleSound()
            holdAudioPlayer?.stop()
            holdAudioPlayer = nil
        case .exhale:
            fadeOutInhaleSound()
            holdAudioPlayer?.stop()
            holdAudioPlayer = nil
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
        completion: @escaping (SettleBellPlayerPreparationOutcome) -> Void
    ) {
        pendingPlayerPreparations += 1
        audioSessionQueue.async { [weak self] in
            guard let self else { return }

            guard self.shouldPlaySecondaryAudio else {
                self.deliverPreparationOutcome(.suppressed, completion: completion)
                return
            }

            guard let url = self.findAudioFile(named: fileName)
                ?? fallbackFileName.flatMap({ self.findAudioFile(named: $0) })
            else {
                self.deliverPreparationOutcome(.failed, completion: completion)
                return
            }

            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = volume
                player.delegate = self
                player.prepareToPlay()
                switch self.activateAudioSessionOnQueue() {
                case .activated:
                    self.deliverPreparationOutcome(.ready(player), completion: completion)
                case .suppressed:
                    self.deliverPreparationOutcome(.suppressed, completion: completion)
                case .failed:
                    self.deliverPreparationOutcome(.failed, completion: completion)
                }
            } catch {
                self.deliverPreparationOutcome(.failed, completion: completion)
            }
        }
    }

    private func deliverPreparationOutcome(
        _ outcome: SettleBellPlayerPreparationOutcome,
        completion: @escaping (SettleBellPlayerPreparationOutcome) -> Void
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.pendingPlayerPreparations = max(0, self.pendingPlayerPreparations - 1)
            completion(outcome)
            switch outcome {
            case .ready:
                break
            case .suppressed, .failed:
                self.deactivateAudioSessionIfIdleOnMain()
            }
        }
    }

    private func fadeOutInhaleSound() {
        inhaleFadeTimer?.invalidate()
        inhaleFadeTimer = nil
        fadeOut(player: inhaleAudioPlayer) { [weak self] in
            self?.inhaleAudioPlayer = nil
            self?.inhaleFadeTimer = nil
            self?.deactivateAudioSessionIfIdleOnMain()
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
            self?.deactivateAudioSessionIfIdleOnMain()
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
            guard let self, let player else { return }
            guard self.playbackGenerationIsCurrent(generation) else {
                DispatchQueue.main.async { [weak self, weak player] in
                    guard let self, let player else { return }
                    self.releasePlayer(player)
                    self.deactivateAudioSessionIfIdleOnMain()
                }
                return
            }
            guard player.play() else {
                DispatchQueue.main.async { [weak self, weak player] in
                    guard let self, let player else { return }
                    self.releasePlayer(player)
                    self.deactivateAudioSessionIfIdleOnMain()
                }
                return
            }
        }
    }

    private var shouldPlaySecondaryAudio: Bool {
        SettleBellAudioInterruptionPolicy.shouldPlaySecondaryAudio(
            secondaryAudioShouldBeSilenced: audioSessionManager.secondaryAudioShouldBeSilencedHint,
            isOtherAudioPlaying: audioSessionManager.isOtherAudioPlaying
        )
    }

    private func activateAudioSessionOnQueue() -> SettleBellAudioActivationOutcome {
        guard shouldPlaySecondaryAudio else { return .suppressed }

        do {
            if !audioSessionConfigured {
                try audioSessionManager.configureForMixedPlayback()
                audioSessionConfigured = true
            }
            try audioSessionManager.activateForPlayback()
            audioSessionOwned = true
            return .activated
        } catch {
            #if DEBUG
            print("[SettleBellService] Audio session failed: \(error.localizedDescription)")
            #endif
            return .failed
        }
    }

    private func deactivateAudioSessionIfIdleOnMain() {
        guard pendingPlayerPreparations == 0,
              ![audioPlayer, inhaleAudioPlayer, exhaleAudioPlayer, holdAudioPlayer]
                .compactMap({ $0 })
                .contains(where: \.isPlaying)
        else {
            return
        }

        audioSessionQueue.async { [weak self] in
            guard let self, self.audioSessionOwned else { return }
            do {
                try self.audioSessionManager.deactivateAfterPlayback()
                self.audioSessionOwned = false
            } catch {
                #if DEBUG
                print("[SettleBellService] Audio session deactivation failed: \(error.localizedDescription)")
                #endif
            }
        }
    }

    private func discardPreparedPlayer(_ player: AVAudioPlayer) {
        player.stop()
        releasePlayer(player)
        deactivateAudioSessionIfIdleOnMain()
    }

    private func releasePlayer(_ player: AVAudioPlayer) {
        if audioPlayer === player { audioPlayer = nil }
        if inhaleAudioPlayer === player { inhaleAudioPlayer = nil }
        if exhaleAudioPlayer === player { exhaleAudioPlayer = nil }
        if holdAudioPlayer === player { holdAudioPlayer = nil }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        performOnMain { [weak self] in
            self?.releasePlayer(player)
            self?.deactivateAudioSessionIfIdleOnMain()
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        performOnMain { [weak self] in
            self?.releasePlayer(player)
            self?.deactivateAudioSessionIfIdleOnMain()
        }
    }

    private func playFallbackSoundIfPermitted() {
        guard shouldPlaySecondaryAudio else { return }
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
