import Foundation

final class Wrinkler: Identifiable {
    let id: Int
    var close = 0.0, sucked = 0.0, phase = 0, hp = Wrinklers.hpMax, hurt = 0.0, clicks = 0, type = 0, seed = 0.0
    var x = 0.0, y = 0.0, r = 0.0, s = 0.0
    init(_ id: Int) { self.id = id }
}

final class Wrinklers {
    static let shared = Wrinklers()
    static let hpMax = 2.1
    var list: [Wrinkler] = (0..<14).map { Wrinkler($0) }
    var squish = Int.random(in: 1...4)

    func reset(_ g: Game) {
        list = (0..<14).map { Wrinkler($0) }
        g.cookiesSucked = 0; g.cpsSucked = 0; g.wrinklersPopped = 0
    }
    func max(_ g: Game) -> Int {
        var n = 10
        if g.Has("Elder spice") { n += 2 }
        n += Int((g.auraMult("Dragon Guts") * 2).rounded())
        return n
    }
    func collect(_ g: Game) { for w in list { w.hp = 0 } }
    func playSquish() {
        Sound.play("snd/squish\(squish).mp3", 0.35)
        squish += Int(rnd() * 1.5) + 1
        if squish > 4 { squish -= 4 }
    }
    @discardableResult
    func spawn(_ g: Game, _ meIn: Wrinkler? = nil) -> Wrinkler? {
        var me = meIn
        if me == nil {
            let mx = max(g)
            let n = list.filter { $0.phase > 0 }.count
            me = list.first { $0.phase == 0 && g.elderWrath > 0 && n < mx && $0.id < mx }
        }
        guard let w = me else { return nil }
        w.phase = 1; w.hp = Wrinklers.hpMax; w.seed = rnd(); w.type = 0; w.clicks = 0
        if rnd() < 0.0001 { w.type = 1 }
        return w
    }
    @discardableResult
    func popRandom() -> Wrinkler? {
        let alive = list.filter { $0.phase > 0 && $0.hp > 0 }
        guard !alive.isEmpty else { return nil }
        let w = choose(alive); w.hp = -10; return w
    }
    func click(_ g: Game, _ w: Wrinkler) {
        if w.phase <= 0 { return }
        if g.powerClicksOn && g.powerClicks >= 1 {
            g.powerClicks -= 1
            Sound.play("snd/powerSquish\(Int.random(in: 1...3)).mp3", 0.6)
            Sound.play("snd/powerClick\(Int.random(in: 1...3))b.mp3", 0.7 - rnd() * 0.3)
            w.hp -= 100
        } else {
            playSquish()
            w.hp -= 0.75
        }
        w.hurt = 1
        w.clicks += 1
        if w.clicks >= 50 { g.win("Wrinkler poker") }
    }

    func logic(_ g: Game, _ delta: Double) {
        let mx = max(g)
        let n = list.filter { $0.phase > 0 }.count
        for me in list {
            if me.phase == 0 && g.elderWrath > 0 && n < mx && me.id < mx {
                var chance = 0.00001 * Double(g.elderWrath) * delta
                if g.Has("Unholy bait") { chance *= 5 }
                let lvl = Minigames.shared.hasGod("scorn")
                if lvl == 1 { chance *= 2.5 } else if lvl == 2 { chance *= 2 } else if lvl == 3 { chance *= 1.5 }
                if rnd() < chance {
                    spawn(g, me)
                    if delta >= Game.fps { me.close = 1; me.phase = 2; g.refreshCps = true }
                }
            }
            if me.phase > 0 {
                if me.close < 1 { me.close += ((1 / Game.fps) / 10) * delta }
                if me.close > 1 { me.close = 1 }
                if me.id >= mx { me.hp = 0 }
            } else { me.close = 0 }
            if me.close == 1 && me.phase == 1 { me.phase = 2; g.refreshCps = true }
            if me.phase == 2 { me.sucked += ((g.cookiesPs / Game.fps) * g.cpsSucked) * delta }
            if me.phase > 0 {
                let cap = me.type == 1 ? Wrinklers.hpMax * 3 : Wrinklers.hpMax
                if me.hp < cap { me.hp += 0.04 }
                me.hp = min(cap, me.hp)
                if rnd() < 0.01 && !g.settings.notScary { me.hurt = Swift.max(me.hurt, rnd()) }
                if me.hurt > 0 { me.hurt -= delta / 5 }
            }
            me.hurt = Swift.max(me.hurt, 0)
            if me.hp <= 0.5 && me.phase > 0 {
                playSquish()
                Sound.play("snd/pop\(Int.random(in: 1...3)).mp3", 0.75)
                g.wrinklersPopped += 1
                g.refreshCps = true
                me.phase = 0; me.close = 0; me.hurt = 0
                let powerKill = me.hp <= -90
                me.hp = Wrinklers.hpMax
                var toSuck = 1.1
                if g.Has("Sacrilegious corruption") { toSuck *= 1.05 }
                toSuck *= 1 + g.auraMult("Dragon Guts") * 0.2
                if me.type == 1 { toSuck *= 3 }
                if powerKill { toSuck *= 1.2 }
                me.sucked *= toSuck
                if g.Has("Wrinklerspawn") { me.sucked *= 1.05 }
                let lvl = Minigames.shared.hasGod("scorn")
                if lvl == 1 { me.sucked *= 1.15 } else if lvl == 2 { me.sucked *= 1.1 } else if lvl == 3 { me.sucked *= 1.05 }
                if me.sucked > 0.5 {
                    g.toast("", (powerKill ? "Obliterated" : "Exploded") + " a " + (me.type == 1 ? "shiny " : "") + "wrinkler:<br>found " + B(me.sucked) + " cookies!", me.type == 1 ? [24, 12] : [19, 8])
                    if !g.HasUnlocked("Wrinkler ambergris") && rnd() < 1 / (me.type == 1 ? 1000.0 : 10000.0) {
                        g.unlock("Wrinkler ambergris")
                        if let u = g.upgradesBN["Wrinkler ambergris"] { g.toast("<b>\(u.name)</b>", "You found:", u.def.icon) }
                    }
                    Seasons.dropHalloween(g, me.type == 1 ? 0.9 : 0.95)
                    Seasons.dropEgg(g, 0.98)
                }
                if me.type == 1 { g.win("Last Chance to See") }
                g.earn(me.sucked)
                Effects.shared.wrinklerBurst(me)
                me.sucked = 0
            }
        }
        if g.cpsSucked > 0 {
            let c = (g.cookiesPs / Game.fps) * g.cpsSucked * delta
            g.dissolve(c)
            g.cookiesSucked += c
        }
    }

    func save() -> [[String: Any]] { list.map { ["s": $0.sucked, "t": $0.type] } }
    func load(_ o: Any?) {
        guard let arr = o as? [Any] else { return }
        for (i, w) in list.enumerated() where i < arr.count {
            guard let d = arr[i] as? [String: Any] else { continue }
            w.sucked = Double("\(d["s"] ?? 0)") ?? (d["s"] as? Double ?? 0)
            if w.sucked > 0 {
                w.phase = 2; w.close = 1; w.hp = Wrinklers.hpMax; w.seed = rnd()
                w.type = Int("\(d["t"] ?? 0)") ?? 0
            }
        }
    }
}
