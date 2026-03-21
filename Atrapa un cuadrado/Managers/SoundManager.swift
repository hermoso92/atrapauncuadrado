import AudioToolbox
import AVFoundation
import Foundation

@MainActor
final class SoundManager {
    enum Soundscape: Equatable {
        case menu
        case arcadeRun
        case evolutionRun
        case ghostRun
    }

    private struct SoundscapeProfile {
        let baseFrequency: Double
        let overtoneFrequency: Double
        let pulseFrequency: Double
        let shimmerFrequency: Double
        let noiseMix: Float
        let gain: Float
    }

    private struct ProceduralRenderer {
        private let profile: SoundscapeProfile
        private let sampleRate: Double
        private var basePhase: Double = 0
        private var overtonePhase: Double = 0
        private var pulsePhase: Double = 0
        private var shimmerPhase: Double = 0
        private var noiseState: UInt32 = 0xA341_316C

        init(profile: SoundscapeProfile, sampleRate: Double) {
            self.profile = profile
            self.sampleRate = sampleRate
        }

        mutating func nextSample() -> Float {
            let pulse = max(0, sin(.pi * 2 * pulsePhase))
            let bass = sin(.pi * 2 * basePhase)
            let overtone = sin(.pi * 2 * overtonePhase)
            let shimmer = sin(.pi * 2 * shimmerPhase)
            let square = bass >= 0 ? 1.0 : -1.0
            let hiss = randomNoise() * profile.noiseMix * Float(0.15 + (pulse * 0.85))

            let layered = Float(bass) * 0.26
                + Float(overtone) * 0.14
                + Float(square) * 0.05
                + Float(shimmer) * 0.08
                + hiss
            let shaped = layered * Float(0.3 + pulse * 0.7)

            basePhase = Self.advancedPhase(basePhase, frequency: profile.baseFrequency, sampleRate: sampleRate)
            overtonePhase = Self.advancedPhase(overtonePhase, frequency: profile.overtoneFrequency, sampleRate: sampleRate)
            pulsePhase = Self.advancedPhase(pulsePhase, frequency: profile.pulseFrequency, sampleRate: sampleRate)
            shimmerPhase = Self.advancedPhase(shimmerPhase, frequency: profile.shimmerFrequency, sampleRate: sampleRate)

            return shaped * profile.gain
        }

        private mutating func randomNoise() -> Float {
            noiseState = noiseState &* 1_664_525 &+ 1_013_904_223
            let normalized = Float(noiseState & 0x00FF_FFFF) / Float(0x00FF_FFFF)
            return (normalized * 2) - 1
        }

        private static func advancedPhase(_ phase: Double, frequency: Double, sampleRate: Double) -> Double {
            var phase = phase + (frequency / sampleRate)
            if phase >= 1 {
                phase -= floor(phase)
            }
            return phase
        }
    }

    static let shared = SoundManager(saveManager: .shared)

    private let saveManager: SaveManager
    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var activeSoundscape: Soundscape?

    init(saveManager: SaveManager) {
        self.saveManager = saveManager
    }

    func playButtonTap() {
        play(systemSoundID: 1104)
    }

    func playSuccess() {
        play(systemSoundID: 1110)
    }

    func playWarning() {
        play(systemSoundID: 1053)
    }

    func playCapture() {
        play(systemSoundID: 1057)
    }

    func playGameOver() {
        play(systemSoundID: 1052)
    }

    func playPauseToggle() {
        play(systemSoundID: 1111)
    }

    func playSoundscape(_ soundscape: Soundscape) {
        guard saveManager.loadProgress().soundEnabled else {
            stopSoundscape()
            return
        }

        if activeSoundscape == soundscape, engine?.isRunning == true {
            return
        }

        activeSoundscape = soundscape
        startSoundscape(soundscape)
    }

    func stopSoundscape() {
        engine?.stop()
        if let sourceNode, let engine {
            engine.detach(sourceNode)
        }
        sourceNode = nil
        engine = nil
    }

    private func play(systemSoundID: SystemSoundID) {
        guard saveManager.loadProgress().soundEnabled else {
            return
        }
        AudioServicesPlaySystemSound(systemSoundID)
    }

    private func startSoundscape(_ soundscape: Soundscape) {
        stopSoundscape()

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            return
        }

        let engine = AVAudioEngine()
        let outputFormat = engine.outputNode.inputFormat(forBus: 0)
        let profile = profile(for: soundscape)
        var renderer = ProceduralRenderer(profile: profile, sampleRate: outputFormat.sampleRate)

        let sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let sample = renderer.nextSample()
                for buffer in buffers {
                    guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else {
                        continue
                    }
                    data[frame] = sample
                }
            }
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: outputFormat)
        engine.mainMixerNode.outputVolume = 0.85

        do {
            try engine.start()
            self.engine = engine
            self.sourceNode = sourceNode
        } catch {
            self.engine = nil
            self.sourceNode = nil
        }
    }

    private func profile(for soundscape: Soundscape) -> SoundscapeProfile {
        switch soundscape {
        case .menu:
            return SoundscapeProfile(
                baseFrequency: 55,
                overtoneFrequency: 82.5,
                pulseFrequency: 1.35,
                shimmerFrequency: 219,
                noiseMix: 0.04,
                gain: 0.14
            )
        case .arcadeRun:
            return SoundscapeProfile(
                baseFrequency: 82.5,
                overtoneFrequency: 123.47,
                pulseFrequency: 2.1,
                shimmerFrequency: 329.63,
                noiseMix: 0.06,
                gain: 0.16
            )
        case .evolutionRun:
            return SoundscapeProfile(
                baseFrequency: 73.42,
                overtoneFrequency: 110,
                pulseFrequency: 2.45,
                shimmerFrequency: 293.66,
                noiseMix: 0.08,
                gain: 0.18
            )
        case .ghostRun:
            return SoundscapeProfile(
                baseFrequency: 61.74,
                overtoneFrequency: 92.5,
                pulseFrequency: 3.4,
                shimmerFrequency: 277.18,
                noiseMix: 0.12,
                gain: 0.2
            )
        }
    }
}
