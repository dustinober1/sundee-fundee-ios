#if canImport(AVFoundation)
import AVFoundation
#endif
import Foundation

// MARK: - AudioRestChimeService

/// Synthesizes and plays a distinctive Art Deco two-tone audio chime when a workout rest interval ends.
///
/// On iOS, configures `AVAudioSession` with `.duckOthers` to temporarily duck background music (e.g. Spotify, Apple Music),
/// plays the chime, and restores background audio immediately with `.notifyOthersOnDeactivation`.
@MainActor
public final class AudioRestChimeService: NSObject, @unchecked Sendable {

    public static let shared = AudioRestChimeService()

    #if canImport(AVFoundation) && !os(watchOS)
    private var audioPlayer: AVAudioPlayer?
    private var cachedChimeData: Data?
    #endif

    public override init() {
        super.init()
        #if canImport(AVFoundation) && !os(watchOS)
        cachedChimeData = Self.generateTwoToneChimeWav()
        #endif
    }

    /// Plays the rest completion chime with audio session ducking if enabled.
    public func playRestCompleteChime() {
        #if canImport(AVFoundation) && !os(watchOS)
        guard let data = cachedChimeData ?? Self.generateTwoToneChimeWav() else { return }

        do {
            #if os(iOS)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.duckOthers])
            try session.setActive(true)
            #endif

            let player = try AVAudioPlayer(data: data)
            player.delegate = self
            player.volume = 0.85
            player.prepareToPlay()
            player.play()
            self.audioPlayer = player
        } catch {
            // Audio playback is non-fatal best effort
        }
        #endif
    }

    #if canImport(AVFoundation) && !os(watchOS)
    /// Generates a simple, elegant Art Deco two-tone bell chime (587 Hz D5 -> 880 Hz A5) as a PCM WAV in memory.
    public static func generateTwoToneChimeWav() -> Data? {
        let sampleRate: Double = 44100.0
        let toneDuration: Double = 0.22
        let totalSamples = Int(sampleRate * toneDuration * 2)
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate = Int32(sampleRate) * Int32(numChannels) * Int32(bitsPerSample / 8)
        let blockAlign = Int16(numChannels * (bitsPerSample / 8))
        let dataSize = Int32(totalSamples * Int(bitsPerSample / 8))

        var data = Data()

        // RIFF header
        data.append(contentsOf: "RIFF".utf8)
        let chunkSize = 36 + dataSize
        var chunkSizeLE = chunkSize.littleEndian
        data.append(Data(bytes: &chunkSizeLE, count: 4))
        data.append(contentsOf: "WAVE".utf8)

        // "fmt " chunk
        data.append(contentsOf: "fmt ".utf8)
        var subchunk1Size: Int32 = 16.littleEndian
        data.append(Data(bytes: &subchunk1Size, count: 4))
        var audioFormat: Int16 = 1.littleEndian // PCM
        data.append(Data(bytes: &audioFormat, count: 2))
        var channels = numChannels.littleEndian
        data.append(Data(bytes: &channels, count: 2))
        var sampleRateLE = Int32(sampleRate).littleEndian
        data.append(Data(bytes: &sampleRateLE, count: 4))
        var byteRateLE = byteRate.littleEndian
        data.append(Data(bytes: &byteRateLE, count: 4))
        var blockAlignLE = blockAlign.littleEndian
        data.append(Data(bytes: &blockAlignLE, count: 2))
        var bitsLE = bitsPerSample.littleEndian
        data.append(Data(bytes: &bitsLE, count: 2))

        // "data" chunk
        data.append(contentsOf: "data".utf8)
        var dataSizeLE = dataSize.littleEndian
        data.append(Data(bytes: &dataSizeLE, count: 4))

        // Tone 1: 587.33 Hz (D5) for 0.22s with exponential decay
        // Tone 2: 880.00 Hz (A5) for 0.22s with exponential decay
        let tone1Freq: Double = 587.33
        let tone2Freq: Double = 880.00
        let tone1Samples = Int(sampleRate * toneDuration)
        let tone2Samples = totalSamples - tone1Samples

        for i in 0..<tone1Samples {
            let t = Double(i) / sampleRate
            let decay = exp(-6.0 * (t / toneDuration))
            let sampleVal = sin(2.0 * .pi * tone1Freq * t) * decay * 0.7
            var intSample = Int16(max(-32767, min(32767, sampleVal * 32767))).littleEndian
            data.append(Data(bytes: &intSample, count: 2))
        }

        for i in 0..<tone2Samples {
            let t = Double(i) / sampleRate
            let decay = exp(-5.0 * (t / toneDuration))
            let sampleVal = sin(2.0 * .pi * tone2Freq * t) * decay * 0.7
            var intSample = Int16(max(-32767, min(32767, sampleVal * 32767))).littleEndian
            data.append(Data(bytes: &intSample, count: 2))
        }

        return data
    }
    #endif
}

#if canImport(AVFoundation) && !os(watchOS)
extension AudioRestChimeService: AVAudioPlayerDelegate {
    public nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        #if os(iOS)
        Task { @MainActor in
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        }
        #endif
    }
}
#endif
