import Foundation

// Port of www/main.js "WRINKLERS" section.

final class Wrinkler {
    let id: Int
    var close = 0.0
    var sucked = 0.0
    var phase = 0
    var x = 0.0, y = 0.0, r = 0.0, s = 0.0
    var clicks = 0
    var hurt = 0.0
    var hp: Double
    var selected = 0
    var type = 0
    var seed = 0.0
    /// the screen has an element for it (me.l in the original)
    var shown = false
    var blinky = false
    init(id: Int, hp: Double) { self.id = id; self.hp = hp }
}

extension Game {
    static let wrinklerHP = 2.1

    func resetWrinklers(_ hard: Bool) {
        wrinklers = (0..<14).map { Wrinkler(id: $0, hp: Game.wrinklerHP) }
        cookiesSucked = 0
        cpsSucked = 0
        wrinklersPopped = 0
    }
    func getWrinklersMax() -> Int {
        var n = 10
        if Has("Elder spice") { n += 2 }
        n += Int(jsRound(auraMult("Dragon Guts") * 2))
        return n
    }
    func collectWrinklers() { for w in wrinklers { w.hp = 0 } }
    func playWrinklerSquishSound() {
        PlaySound("snd/squish\(wrinklerSquishSound).mp3", 0.35)
        wrinklerSquishSound += Int((JSMath.random() * 1.5).rounded(.down)) + 1
        if wrinklerSquishSound > 4 { wrinklerSquishSound -= 4 }
    }
    @discardableResult
    func spawnWrinkler(_ meIn: Wrinkler? = nil) -> Wrinkler? {
        var me = meIn
        if me == nil {
            let max = getWrinklersMax()
            let n = wrinklers.filter { $0.phase > 0 }.count
            for it in wrinklers where it.phase == 0 && elderWrath > 0 && n < max && it.id < max { me = it; break }
        }
        guard let w = me else { return nil }
        w.phase = 1
        w.hp = Game.wrinklerHP
        w.seed = JSMath.random()
        w.type = 0
        w.clicks = 0
        w.shown = false
        if JSMath.random() < 0.0001 { w.type = 1 }
        return w
    }
    @discardableResult
    func PopRandomWrinkler() -> Wrinkler? {
        let list = wrinklers.filter { $0.phase > 0 && $0.hp > 0 }
        if list.isEmpty { return nil }
        let me = choose(list)
        me.hp = -10
        return me
    }
    func clickWrinkler(_ me: Wrinkler) {
        if me.phase <= 0 { return }
        if powerClicksOn && powerClicks >= 1 {
            spendPowerClick()
            PlaySound("snd/powerSquish" + choose(["1", "2", "3"]) + ".mp3", 0.6)
            PlaySound("snd/powerClick" + choose(["1", "2", "3"]) + "b.mp3", 0.7 - JSMath.random() * 0.3)
            me.hp -= 100
        } else {
            playWrinklerSquishSound()
            me.hp -= 0.75
        }
        me.hurt = 1
        me.clicks += 1
        if me.clicks >= 50 { win("Wrinkler poker") }
        canPan = false
        if getSet("notScary") == 0 {
            particleAt(Particle(x: me.x, y: me.y, xd: JSMath.random() * 4 - 2, yd: -JSMath.random() * 3 - 2,
                                s: me.s, r: -me.r / Double.pi * 180, rd: JSMath.random() * 10 - 5,
                                pic: .wrinklerBits(shiny: me.type == 1, frame: Int((JSMath.random() * 8).rounded(.down)))))
        }
    }

    func logicWrinklers(_ delta: Double) {
        let max = getWrinklersMax()
        let n = wrinklers.filter { $0.phase > 0 }.count
        for me in wrinklers {
            if me.phase == 0 && elderWrath > 0 && n < max && me.id < max {
                var chance = 0.00001 * Double(elderWrath) * delta
                if Has("Unholy bait") { chance *= 5 }
                if JSMath.random() < chance {
                    spawnWrinkler(me)
                    if delta >= fps { me.close = 1; me.phase = 2; refreshCps = true }
                }
            }
            if me.phase > 0 {
                if me.close < 1 { me.close += ((1 / fps) / 10) * delta }
                if me.close > 1 { me.close = 1 }
                if me.id >= max { me.hp = 0 }
            } else { me.close = 0 }
            if me.close == 1 && me.phase == 1 {
                me.phase = 2
                refreshCps = true
            }
            if me.phase == 2 {
                me.sucked += ((cookiesPs / fps) * cpsSucked) * delta
            }
            if me.phase > 0 {
                if me.type == 0 {
                    if me.hp < Game.wrinklerHP { me.hp += 0.04 }
                    me.hp = min(Game.wrinklerHP, me.hp)
                } else if me.type == 1 {
                    if me.hp < Game.wrinklerHP * 3 { me.hp += 0.04 }
                    me.hp = min(Game.wrinklerHP * 3, me.hp)
                }
                if JSMath.random() < 0.01 && getSet("notScary") == 0 { me.hurt = Swift.max(me.hurt, JSMath.random()) }
                if me.hurt > 0 { me.hurt -= delta / 5 }
            }
            me.hurt = Swift.max(me.hurt, 0)

            if me.hp <= 0.5 && me.phase > 0 {
                playWrinklerSquishSound()
                PlaySound("snd/pop\(Int((JSMath.random() * 3 + 1).rounded(.down))).mp3", 0.75)
                wrinklersPopped += 1
                refreshCps = true
                me.phase = 0
                me.close = 0
                me.hurt = 0
                let powerKill = me.hp <= -90
                me.hp = Game.wrinklerHP
                var toSuck = 1.1
                if Has("Sacrilegious corruption") { toSuck *= 1.05 }
                toSuck *= 1 + auraMult("Dragon Guts") * 0.2
                if me.type == 1 { toSuck *= 3 }
                if powerKill { toSuck *= 1.2 }
                me.sucked *= toSuck
                if Has("Wrinklerspawn") { me.sucked *= 1.05 }
                let godLvl = hasGod("scorn")
                if godLvl == 1 { me.sucked *= 1.15 }
                else if godLvl == 2 { me.sucked *= 1.1 }
                else if godLvl == 3 { me.sucked *= 1.05 }
                if me.sucked > 0.5 {
                    toast("", (powerKill ? "Obliterated" : "Exploded") + " a " + (me.type == 1 ? "shiny " : "") + "wrinkler:<br>found " + B(me.sucked) + " cookies!", me.type == 1 ? [24, 12] : [19, 8])
                    if !HasUnlocked("Wrinkler ambergris") && JSMath.random() < 1 / (me.type == 1 ? 1000 : 10000) {
                        unlock("Wrinkler ambergris")
                        let up = upgradesBN["Wrinkler ambergris"]!
                        toast("<b>" + up.name + "</b>", "You found:", up.icon)
                    }
                    DropHalloween(me.type == 1 ? 0.9 : 0.95)
                    DropEgg(0.98)
                }
                if me.type == 1 { win("Last Chance to See") }
                earn(me.sucked)
                if getSet("notScary") == 0 {
                    for ii in 0..<8 {
                        particleAt(Particle(x: me.x, y: me.y,
                                            xd: (JSMath.random() * 4 - 2) * (powerKill ? 3 : 1), yd: (-JSMath.random() * 3 - 2) * (powerKill ? 3 : 1),
                                            s: me.s, r: -me.r / Double.pi * 180, rd: JSMath.random() * 10 - 5,
                                            pic: .wrinklerBits(shiny: me.type == 1, frame: ii)))
                    }
                }
                me.sucked = 0
            }
        }
        if cpsSucked > 0 {
            let c = (cookiesPs / fps) * cpsSucked * delta
            dissolve(c)
            cookiesSucked += c
        }
    }

    /// G.drawWrinklers: works out where each wrinkler is around the big cookie (called by the cookie screen every frame)
    func layoutWrinklers(fromX: Double, fromY: Double) {
        if explodeT > -1 { return }
        if wrinklersPosX == -1000 { wrinklersPosX = fromX; wrinklersPosY = fromY }
        wrinklersPosX += (fromX - wrinklersPosX) * 0.2
        wrinklersPosY += (fromY - wrinklersPosY) * 0.2
        for (i, me) in wrinklers.enumerated() {
            if me.phase == 0 { me.hp = 0 }
            if me.hp <= 0 && me.shown { me.shown = false }
            else if me.hp > 0 && !me.shown { me.shown = true }
            else if me.hp > 0 && me.shown {
                let seed = me.seed
                var d = 110.0
                var r = (Double(i) / 11 + 0.25) * 0.35
                if getSet("fancy") != 0 {
                    d += sin(seed * 741 + 37 + Double(T) * (0.02 + sin(seed * 4.17) * 0.01)) * 5 + 100 * (1 - me.close)
                    r += 0.005 * sin(seed * 3.7 + 0.3 + Double(T) * (0.03 + sin(seed * 0.91) * 0.02))
                }
                r *= Double.pi * 2
                let x = wrinklersPosX + sin(r) * d
                let y = wrinklersPosY + cos(r) * d - 30
                let s = 0.25 + 0.1 * sin(seed)
                me.x = x; me.y = y; me.r = r; me.s = s
                let ti = Double(T)
                me.blinky = getSet("notScary") != 0 && sin(ti * 0.003 + Double(i) * 11 + 137 + sin(ti * 0.017 + Double(i) * 13)) > 0.9997
                if onPopup == 0 && JSMath.random() < 0.01 && me.phase > 1 { cookiePop(x, y, 0.25) }
            }
        }
    }
    func undrawWrinklers() { for w in wrinklers { w.shown = false } }

    func saveWrinklers() -> [[String: Any]] { wrinklers.map { ["s": $0.sucked, "t": $0.type] } }
    func loadWrinklers(_ o: Any?, _ version: Double) {
        guard let o = o else { return }
        if version < 6 {
            guard let d = o as? [String: Any] else { return }
            var n = (d["n"] as? NSNumber)?.intValue ?? 0
            let amount = (d["amount"] as? NSNumber)?.doubleValue ?? 0
            let amountShinies = (d["amountShinies"] as? NSNumber)?.doubleValue ?? 0
            var shinies = (d["shinies"] as? NSNumber)?.intValue ?? 0
            if n > 0 && (amount > 0 || amountShinies > 0) {
                let fullNumber = Double(n - shinies)
                let fullNumberShinies = Double(shinies)
                for me in wrinklers where n > 0 {
                    me.phase = 2; me.close = 1; me.hp = Game.wrinklerHP
                    me.seed = JSMath.random(); me.shown = false; me.type = 0
                    if shinies > 0 { me.type = 1; me.sucked = amountShinies / fullNumberShinies; shinies -= 1 }
                    else { me.sucked = amount / fullNumber }
                    n -= 1
                }
            }
        } else {
            guard let arr = o as? [Any] else { return }
            for (i, it) in wrinklers.enumerated() where i < arr.count {
                guard let d = arr[i] as? [String: Any] else { continue }
                it.sucked = jsParseFloat(d["s"])
                if it.sucked > 0 {
                    it.phase = 2; it.close = 1; it.hp = Game.wrinklerHP
                    it.seed = JSMath.random(); it.shown = false
                    it.type = Int(jsParseFloat(d["t"]))
                }
            }
        }
    }
}

/// parseFloat on a JSON value
func jsParseFloat(_ v: Any?) -> Double {
    if let n = v as? NSNumber { return n.doubleValue }
    if let s = v as? String { return Double(s.trimmingCharacters(in: .whitespaces)) ?? .nan }
    return .nan
}
