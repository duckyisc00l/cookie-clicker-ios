import Foundation
import AVFoundation

/// Plays the game's sound effects (from the original snd folder).
enum Sound {
    private static var players: [AVAudioPlayer] = []
    private static var cache: [String: Data] = [:]
    static var enabled = true
    static var volume = 1.0

    static func play(_ path: String, _ vol: Double = 1) {
        guard enabled, Game.shared.settings["sound"] else { return }
        DispatchQueue.main.async {
            let data: Data
            if let d = cache[path] { data = d }
            else {
                let name = (path as NSString).lastPathComponent
                let base = (name as NSString).deletingPathExtension
                guard let url = Bundle.main.url(forResource: base, withExtension: "mp3", subdirectory: "snd")
                        ?? Bundle.main.url(forResource: base, withExtension: "mp3"),
                      let d = try? Data(contentsOf: url) else { return }
                cache[path] = d; data = d
            }
            guard let p = try? AVAudioPlayer(data: data) else { return }
            p.volume = Float(max(0, min(1, vol)) * volume * Double(Game.shared.settings.volume) / 100)
            p.play()
            players.removeAll { !$0.isPlaying }
            players.append(p)
        }
    }
}

/// Floating numbers, sparkles and cookie bits drawn on the cookie screen.
final class Effects {
    static let shared = Effects()
    struct Particle: Identifiable {
        let id = UUID()
        var text: String? = nil
        var pic: String? = nil
        var x: Double, y: Double, xd: Double = 0, yd: Double = 0, r: Double = 0, rd: Double = 0
        var s: Double = 1, grav: Double = 0.4, life: Double = 1, t: Double = 0
    }
    var particles: [Particle] = []

    func floatText(_ text: String, _ x: Double, _ y: Double) {
        guard Game.shared.settings["particles"] else { return }
        particles.append(Particle(text: text, x: x, y: y, xd: rnd() * 2 - 1, yd: -3, grav: 0, life: 1.2))
    }
    func cookiePop(_ x: Double, _ y: Double) {
        guard Game.shared.settings["cookiepops"] else { return }
        particles.append(Particle(pic: "cookieBit", x: x, y: y, xd: rnd() * 8 - 4, yd: -rnd() * 6 - 3, r: rnd() * 360, rd: rnd() * 20 - 10, s: 0.5 + rnd() * 0.3, life: 1))
    }
    func sparkle(_ x: Double, _ y: Double) {
        particles.append(Particle(pic: "sparkle", x: x, y: y, grav: 0, life: 0.5))
    }
    func wrinklerBurst(_ w: Wrinkler) {
        for _ in 0..<6 {
            particles.append(Particle(pic: w.type == 1 ? "shinyWrinklerBits" : "wrinklerBits", x: w.x, y: w.y, xd: rnd() * 8 - 4, yd: -rnd() * 4 - 2, r: rnd() * 360, rd: rnd() * 10 - 5, life: 1.2))
        }
    }
    func logic(_ dt: Double) {
        for i in particles.indices {
            particles[i].t += dt
            particles[i].x += particles[i].xd
            particles[i].y += particles[i].yd
            particles[i].yd += particles[i].grav
            particles[i].r += particles[i].rd
        }
        particles.removeAll { $0.t >= $0.life }
        if particles.count > 120 { particles.removeFirst(particles.count - 120) }
    }
}

/// Research (Bingo center): pick a research, wait, then tap to complete it.
enum Research {
    static func time(_ g: Game) -> Double {
        var t = 1000.0 * 60 * 30
        if g.Has("Persistent memory") { t = (t / 10).rounded(.up) }
        return t
    }
    static func left(_ g: Game) -> Double { g.researchT - now() + g.researchTM }
    static func start(_ g: Game, _ u: Upgrade) {
        guard g.researchUpgrade == nil, u.unlocked > 0, u.owned == 0 else { return }
        let c = g.upgradeCost(u)
        guard c <= g.cookies else { return }
        g.spend(c)
        g.researchT = now(); g.researchTM = time(g); g.researchUpgrade = u
        g.toast(u.name, "Research started.", u.def.icon)
        g.refreshCps = true
        Sound.play("snd/thud.mp3", 0.5)
    }
    static func complete(_ g: Game) {
        guard let u = g.researchUpgrade, left(g) <= 0 else { return }
        g.researchT = 0; g.researchTM = 0; g.researchUpgrade = nil; g.researchUpgradeLast = u
        g.toast(u.name, "Research complete!", u.def.icon)
        Sound.play("snd/smallCymbalCrash.mp3", 0.5)
        u.owned = 1
        g.upgradesN += 1
        g.refreshCps = true
        g.upgradeBought(u, forced: false)
        g.doUnlocks()
    }
    static func logic(_ g: Game) {
        if g.researchUpgrade != nil && left(g) <= 0 { g.pings.insert("special") }
    }
}
