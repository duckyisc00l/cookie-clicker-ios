import Foundation

struct Spell {
    let key: String, name: String, desc: String, failDesc: String?, icon: [Int], costMin: Double, costPercent: Double
}

/// Grimoire (Wizard tower minigame): spend magic to cast spells. Rules from the desktop game.
final class Grimoire: Minigame {
    let building: Building
    let name = "Grimoire"
    var magic = 0.0, magicM = 0.0, magicPS = 0.0
    var spellsCast = 0, spellsCastTotal = 0
    var lastMessage: String? = nil

    let spells: [Spell] = [
        Spell(key: "conjure baked goods", name: "Conjure Baked Goods", desc: "Summon half an hour worth of your CpS, capped at 15% of your cookies owned.", failDesc: "Trigger a 15-minute clot and lose 15 minutes of CpS.", icon: [21, 11], costMin: 2, costPercent: 0.4),
        Spell(key: "hand of fate", name: "Force the Hand of Fate", desc: "Summon a random golden cookie. Each existing golden cookie makes this spell +15% more likely to backfire.", failDesc: "Summon an unlucky wrath cookie.", icon: [22, 11], costMin: 10, costPercent: 0.6),
        Spell(key: "stretch time", name: "Stretch Time", desc: "All active buffs gain 10% more time (up to 5 more minutes).", failDesc: "All active buffs are shortened by 20% (up to 10 minutes shorter).", icon: [23, 11], costMin: 8, costPercent: 0.2),
        Spell(key: "spontaneous edifice", name: "Spontaneous Edifice", desc: "The spell picks a random building you could afford if you had twice your current cookies, and gives it to you for free. The building selected must be under 400, and cannot be your most-built one (unless it is your only one).", failDesc: "Lose a random building.", icon: [24, 11], costMin: 20, costPercent: 0.75),
        Spell(key: "haggler's charm", name: "Haggler's Charm", desc: "Upgrades are 2% cheaper for 1 minute.", failDesc: "Upgrades are 2% more expensive for an hour.<q>What's that spell? Loadsamoney!</q>", icon: [25, 11], costMin: 10, costPercent: 0.1),
        Spell(key: "summon crafty pixies", name: "Summon Crafty Pixies", desc: "Buildings are 2% cheaper for 1 minute.", failDesc: "Buildings are 2% more expensive for an hour.", icon: [26, 11], costMin: 10, costPercent: 0.2),
        Spell(key: "gambler's fever dream", name: "Gambler's Fever Dream", desc: "Cast a random spell at half the magic cost, with twice the chance of backfiring.", failDesc: nil, icon: [27, 11], costMin: 3, costPercent: 0.05),
        Spell(key: "resurrect abomination", name: "Resurrect Abomination", desc: "Instantly summon a wrinkler if conditions are fulfilled.", failDesc: "Pop one of your wrinklers.", icon: [28, 11], costMin: 20, costPercent: 0.1),
        Spell(key: "diminish ineptitude", name: "Diminish Ineptitude", desc: "Spells backfire 10 times less for the next 5 minutes.", failDesc: "Spells backfire 5 times more for the next 10 minutes.", icon: [29, 11], costMin: 5, costPercent: 0.2),
    ]

    init(_ b: Building) { building = b; computeMagicM(); magic = magicM }

    func computeMagicM() {
        let towers = Double(max(building.amount, 1))
        let lvl = Double(max(building.level, 1))
        magicM = (4 + pow(towers, 0.6) + log((towers + (lvl - 1) * 10) / 15 + 1) * 15).rounded(.down)
        magic = min(magicM, magic)
    }

    func cost(_ s: Spell) -> Double {
        var out = s.costMin + magicM * s.costPercent
        out *= 1 - 0.1 * Game.shared.auraMult("Supreme Intellect")
        return out.rounded(.down)
    }

    func failChance(_ s: Spell) -> Double {
        let g = Game.shared
        var f = 0.15
        if g.hasBuff("magic adept") != nil { f *= 0.1 }
        if g.hasBuff("magic inept") != nil { f *= 5 }
        f *= 1 + 0.1 * g.auraMult("Supreme Intellect")
        if s.key == "hand of fate" { f += 0.15 * Double(g.shimmerTypes[0].n) }
        return f
    }

    /// returns true if the spell went off
    @discardableResult
    func cast(_ s: Spell, costOverride: Double? = nil, failChanceMax: Double? = nil, passthrough: Bool = false) -> Bool {
        let g = Game.shared
        let c = costOverride ?? cost(s)
        if magic < c { return false }
        var fc = failChance(s)
        if let m = failChanceMax { fc = max(fc, m) }
        var r = SeededRandom(g.seed + "/" + String(spellsCastTotal))
        let roll = r.next()
        let fail = s.failDesc != nil && !(roll < 1 - fc)
        let out = fail ? backfire(s) : win(s)
        if out {
            if !passthrough {
                spellsCast += 1; spellsCastTotal += 1
                if spellsCastTotal >= 9 { g.win("Bibbidi-bobbidi-boo") }
                if spellsCastTotal >= 99 { g.win("I'm the wiz") }
                if spellsCastTotal >= 999 { g.win("A wizard is you") }
            }
            magic = max(0, magic - c)
            Sound.play(fail ? "snd/spellFail.mp3" : "snd/spell.mp3", 0.75)
            return true
        }
        Sound.play("snd/spellFail.mp3", 0.75)
        return false
    }

    private func say(_ s: String) { lastMessage = s; Game.shared.toast("", s, nil, true) }

    private func win(_ s: Spell) -> Bool {
        let g = Game.shared
        switch s.key {
        case "conjure baked goods":
            let v = max(7, min(g.cookies * 0.15, g.cookiesPs * 60 * 30))
            g.earn(v)
            g.toast("Conjure Baked Goods!", "You magic <b>\(B(v)) cookie\(v == 1 ? "" : "s")</b> out of thin air.", [21, 11])
        case "hand of fate":
            var choices = ["frenzy", "multiply cookies"]
            if g.hasBuff("dragonflight") == nil { choices.append("click frenzy") }
            if rnd() < 0.1 { choices += ["cookie storm", "cookie storm", "blab"] }
            if g.buildingsN >= 10 && rnd() < 0.25 { choices.append("building special") }
            if rnd() < 0.15 { choices = ["cookie storm drop"] }
            if rnd() < 0.0001 { choices.append("free sugar lump") }
            let force = choose(choices)
            g.spawnShimmer(0) { $0.noWrath = true; $0.force = force }
            say("Promising fate!")
        case "stretch time":
            if g.buffs.isEmpty { say("No buffs to alter!"); return false }
            for b in g.buffs { let gain = min(300, b.tm * 0.1); b.tm += gain; b.t += gain }
            say("Zap! Buffs lengthened.")
        case "spontaneous edifice":
            let mx = g.buildings.map(\.amount).max() ?? 0
            let n = g.buildings.filter { $0.amount > 0 }.count
            let list = g.buildings.filter { ($0.amount < mx || n == 1) && g.cost($0) <= g.cookies * 2 && $0.amount < 400 }
            if list.isEmpty { say("No buildings to improve!"); return false }
            let b = choose(list)
            g.forceBuy(b, 1)
            say("A new \(b.def.single)<br>bursts out of the ground.")
        case "haggler's charm":
            g.killBuff("haggler misery"); g.addBuff("haggler luck", t: 60, pow: 2); say("Upgrades are cheaper!")
        case "summon crafty pixies":
            g.killBuff("pixie misery"); g.addBuff("pixie luck", t: 60, pow: 2); say("Crafty pixies<br>Buildings are cheaper!")
        case "gambler's fever dream":
            let selfCost = cost(s)
            let list = spells.filter { $0.key != s.key && (magic - selfCost) >= cost($0) * 0.5 }
            if list.isEmpty { say("No eligible spells!"); return false }
            let sp = choose(list)
            let c = cost(sp) * 0.5
            let seed = g.seed
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                guard Game.shared.seed == seed else { return }
                if !self.cast(sp, costOverride: c, failChanceMax: 0.5, passthrough: true) {
                    self.magic += selfCost
                    self.say("That's too bad!<br>Magic refunded.")
                }
            }
            say("Casting \(sp.name)<br>for \(B(c)) magic...")
        case "resurrect abomination":
            if Wrinklers.shared.spawn(g) == nil { say("Unable to spawn a wrinkler!"); return false }
            say("Rise, my precious!")
        case "diminish ineptitude":
            g.killBuff("magic inept"); g.addBuff("magic adept", t: 300, pow: 10); say("Ineptitude diminished!")
        default: return false
        }
        return true
    }

    private func backfire(_ s: Spell) -> Bool {
        let g = Game.shared
        switch s.key {
        case "conjure baked goods":
            if let b = g.addBuff("clot", t: 900, pow: 0.5) { g.toast(b.type.nameD, g.buffDesc(b), b.type.icon) }
            var v = min(g.cookies * 0.15, g.cookiesPs * 60 * 15) + 13
            v = min(g.cookies, v)
            g.spend(v)
            say("Backfire!<br>Summoning failed! Lost \(B(v)) cookie\(v == 1 ? "" : "s")!")
        case "hand of fate":
            var choices = ["clot", "ruin cookies"]
            if rnd() < 0.1 { choices += ["cursed finger", "blood frenzy"] }
            if rnd() < 0.003 { choices.append("free sugar lump") }
            if rnd() < 0.1 { choices = ["blab"] }
            let force = choose(choices)
            g.spawnShimmer(0) { $0.forceWrath = true; $0.force = force }
            say("Backfire!<br>Sinister fate!")
        case "stretch time":
            if g.buffs.isEmpty { say("No buffs to alter!"); return false }
            for b in g.buffs { let loss = min(600, b.t * 0.2); b.t = max(0, b.t - loss) }
            say("Backfire!<br>Fizz! Buffs shortened.")
        case "spontaneous edifice":
            if g.buildingsN == 0 { say("Backfired, but no buildings to destroy!"); return false }
            let b = choose(g.buildings.filter { $0.amount > 0 })
            g.forceSell(b, 1)
            say("Backfire!<br>One of your \(b.def.plural)<br>disappears in a puff of smoke.")
        case "haggler's charm":
            g.killBuff("haggler luck"); g.addBuff("haggler misery", t: 3600, pow: 2); say("Backfire!<br>Upgrades are pricier!")
        case "summon crafty pixies":
            g.killBuff("pixie luck"); g.addBuff("pixie misery", t: 3600, pow: 2); say("Backfire!<br>Nasty goblins<br>Buildings are pricier!")
        case "resurrect abomination":
            if Wrinklers.shared.popRandom() == nil { say("Backfire!<br>But no wrinkler was harmed."); return false }
            say("Backfire!<br>So long, ugly...")
        case "diminish ineptitude":
            g.killBuff("magic adept"); g.addBuff("magic inept", t: 600, pow: 5); say("Backfire!<br>Ineptitude magnified!")
        default: return false
        }
        return true
    }

    private var tick = 0
    func logic(_ g: Game) {
        if tick % 5 == 0 { computeMagicM() }
        tick += 1
        magicPS = max(0.002, pow(magic / max(magicM, 100), 0.5)) * 0.002
        magic = min(magic + magicPS, magicM)
    }

    func refill(_ g: Game) {
        guard magic < magicM else { return }
        LumpRefill.refill(g, 1) {
            self.magic += 100
            self.magic = min(self.magic, self.magicM)
            Sound.play("snd/pop\(Int.random(in: 1...3)).mp3", 0.75)
        }
    }

    func reset(hard: Bool) {
        computeMagicM(); magic = magicM; spellsCast = 0
        if hard { spellsCastTotal = 0 }
    }
    func save() -> String { Fmt.jsNumber(magic) + " " + String(spellsCast) + " " + String(spellsCastTotal) + " 0" }
    func load(_ s: String) {
        let spl = s.split(separator: " ").map(String.init)
        computeMagicM()
        magic = spl.count > 0 ? Double(spl[0]) ?? magicM : magicM
        spellsCast = spl.count > 1 ? Int(Double(spl[1]) ?? 0) : 0
        spellsCastTotal = spl.count > 2 ? Int(Double(spl[2]) ?? 0) : 0
    }
}
