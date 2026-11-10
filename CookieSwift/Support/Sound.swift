import AVFoundation

/// PlaySound(url, vol) from www/main.js: the WebAudio version. Every call starts a new overlapping
/// playback of the sound at gain `vol`. Sounds load on first use (that first call is silent, as in the original
/// where the sound plays once decoding finishes; here it plays right after loading too).
final class SoundPlayer {
    static let shared = SoundPlayer()
    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var next = 0
    private var buffers: [String: AVAudioPCMBuffer] = [:]
    private var format: AVAudioFormat?
    private let queue = DispatchQueue(label: "sounds")

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        let fmt = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        format = fmt
        for _ in 0..<24 {
            let p = AVAudioPlayerNode()
            engine.attach(p)
            engine.connect(p, to: engine.mainMixerNode, format: fmt)
            players.append(p)
        }
        try? engine.start()
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] _ in
            try? self?.engine.start()
        }
    }

    private func load(_ url: String) -> AVAudioPCMBuffer? {
        if let b = buffers[url] { return b }
        guard let file = Bundle.main.url(forResource: "www/" + url, withExtension: nil) ?? Bundle.main.url(forResource: url, withExtension: nil),
              let f = try? AVAudioFile(forReading: file), let fmt = format else { return nil }
        guard let src = AVAudioPCMBuffer(pcmFormat: f.processingFormat, frameCapacity: AVAudioFrameCount(f.length)) else { return nil }
        try? f.read(into: src)
        // convert to the mixer's format so every sound can share the player nodes
        guard let conv = AVAudioConverter(from: f.processingFormat, to: fmt) else { return nil }
        let ratio = fmt.sampleRate / f.processingFormat.sampleRate
        guard let out = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: AVAudioFrameCount(Double(src.frameLength) * ratio) + 1024) else { return nil }
        var done = false
        conv.convert(to: out, error: nil) { _, status in
            if done { status.pointee = .noDataNow; return nil }
            done = true
            status.pointee = .haveData
            return src
        }
        buffers[url] = out
        return out
    }

    func play(_ url: String, _ vol: Double) {
        queue.async {
            guard let buf = self.load(url) else { return }
            DispatchQueue.main.async {
                if !self.engine.isRunning { try? self.engine.start() }
                let p = self.players[self.next]
                self.next = (self.next + 1) % self.players.count
                p.stop()
                p.volume = Float(vol)
                p.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
                p.play()
            }
        }
    }
    func preload(_ url: String) { queue.async { _ = self.load(url) } }
}

func PlaySound(_ url: String, _ vol: Double = 1) {
    if G.getSet("sound") == 0 { return }
    if G.volume == 0 || vol == 0 { return }
    SoundPlayer.shared.play(url, vol)
}
func PreloadSound(_ url: String) { SoundPlayer.shared.preload(url) }
