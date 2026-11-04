import Foundation

struct God {
    let key: String, name: String, icon: [Int]
    let descBefore: String?, desc: [String], descAfter: String?, quote: String
}

/// Pantheon (Temple minigame): slot up to 3 spirits for bonuses. Rules from the desktop game.
final class Pantheon: Minigame {
    let building: Building
    let name = "Pantheon"
    var slot = [-1, -1, -1]          // god id in Diamond, Ruby, Jade
    var swaps = 3.0
    var swapT = now()
    static let slotNames = ["Diamond", "Ruby", "Jade"]

    static func g(_ s: String) -> String { "<span class=\"green\">" + s + "</span>" }
    static func r(_ s: String) -> String { "<span class=\"red\">" + s + "</span>" }

    let gods: [God] = [
        God(key: "asceticism", name: "Holobore, Spirit of Asceticism", icon: [21, 18], descBefore: nil,
            desc: [g("+15% base CpS."), g("+10% base CpS."), g("+5% base CpS.")],
            descAfter: r("If a golden cookie is clicked, this spirit is unslotted and all worship swaps will be used up."),
            quote: "An immortal life spent focusing on the inner self, away from the distractions of material wealth."),
        God(key: "decadence", name: "Vomitrax, Spirit of Decadence", icon: [22, 18], descBefore: nil,
            desc: [g("Golden and wrath cookie effect duration +7%.") + " " + r("Buildings grant -7% CpS."),
                   g("Golden and wrath cookie effect duration +5%.") + " " + r("Buildings grant -5% CpS."),
                   g("Golden and wrath cookie effect duration +2%.") + " " + r("Buildings grant -2% CpS.")],
            descAfter: nil, quote: "This sleazy spirit revels in the lust for quick easy gain and contempt for the value of steady work."),
        God(key: "ruin", name: "Godzamok, Spirit of Ruin", icon: [23, 18], descBefore: g("Selling buildings triggers a buff boosted by how many buildings were sold."),
            desc: [g("Buff boosts clicks by +1% for every building sold for 10 seconds."), g("Buff boosts clicks by +0.5% for every building sold for 10 seconds."), g("Buff boosts clicks by +0.25% for every building sold for 10 seconds.")],
            descAfter: nil, quote: "The embodiment of natural disasters. An impenetrable motive drives the devastation caused by this spirit."),
        God(key: "ages", name: "Cyclius, Spirit of Ages", icon: [24, 18], descBefore: "CpS bonus fluctuating between " + g("+15%") + " and " + r("-15%") + " over time.",
            desc: ["Effect cycles over 3 hours.", "Effect cycles over 12 hours.", "Effect cycles over 24 hours."],
            descAfter: nil, quote: "This spirit knows about everything you'll ever do, and enjoys dispensing a harsh judgment."),
        God(key: "seasons", name: "Selebrak, Spirit of Festivities", icon: [25, 18], descBefore: g("Some seasonal effects are boosted."),
            desc: [g("Large boost.") + " " + r("Switching seasons is 100% pricier."), g("Medium boost.") + " " + r("Switching seasons is 50% pricier."), g("Small boost.") + " " + r("Switching seasons is 25% pricier.")],
            descAfter: nil, quote: "This is the spirit of merry getaways and regretful Monday mornings."),
        God(key: "creation", name: "Dotjeiess, Spirit of Creation", icon: [26, 18], descBefore: nil,
            desc: [g("All buildings are <b>7% cheaper</b>.") + " " + r("Heavenly chips have 30% less effect."),
                   g("All buildings are <b>5% cheaper</b>.") + " " + r("Heavenly chips have 20% less effect."),
                   g("All buildings are <b>2% cheaper</b>.") + " " + r("Heavenly chips have 10% less effect.")],
            descAfter: nil, quote: "All things that be and ever will be were scripted long ago by this spirit's inscrutable tendrils."),
        God(key: "labor", name: "Muridal, Spirit of Labor", icon: [27, 18], descBefore: nil,
            desc: [g("Clicking is <b>15%</b> more powerful.") + " " + r("Buildings produce 3% less."),
                   g("Clicking is <b>10%</b> more powerful.") + " " + r("Buildings produce 2% less."),
                   g("Clicking is <b>5%</b> more powerful.") + " " + r("Buildings produce 1% less.")],
            descAfter: nil, quote: "This spirit enjoys a good cheese after a day of hard work."),
        God(key: "industry", name: "Jeremy, Spirit of Industry", icon: [28, 18], descBefore: nil,
            desc: [g("Buildings produce 10% more.") + " " + r("Golden and wrath cookies appear 10% less."),
                   g("Buildings produce 6% more.") + " " + r("Golden and wrath cookies appear 6% less."),
                   g("Buildings produce 3% more.") + " " + r("Golden and wrath cookies appear 3% less.")],
            descAfter: nil, quote: "While this spirit has many regrets, helping you rule the world through constant industrialization is not one of them."),
        God(key: "mother", name: "Mokalsium, Mother Spirit", icon: [29, 18], descBefore: nil,
            desc: [g("Milk is <b>10% more powerful</b>.") + " " + r("Golden and wrath cookies appear 15% less."),
                   g("Milk is <b>5% more powerful</b>.") + " " + r("Golden and wrath cookies appear 10% less."),
                   g("Milk is <b>3% more powerful</b>.") + " " + r("Golden and wrath cookies appear 5% less.")],
            descAfter: nil, quote: "A caring spirit said to contain itself, inwards infinitely."),
        God(key: "scorn", name: "Skruuia, Spirit of Scorn", icon: [21, 19], descBefore: r("All golden cookies are wrath cookies with a greater chance of a negative effect."),
            desc: [g("Wrinklers appear 150% faster and digest 15% more cookies."), g("Wrinklers appear 100% faster and digest 10% more cookies."), g("Wrinklers appear 50% faster and digest 5% more cookies.")],
            descAfter: nil, quote: "This spirit enjoys poking foul beasts and watching them squirm, but has no love for its own family."),
        God(key: "order", name: "Rigidel, Spirit of Order", icon: [22, 19], descBefore: nil,
            desc: [g("Sugar lumps ripen <b>1 hour</b> sooner."), g("Sugar lumps ripen <b>40 minutes</b> sooner."), g("Sugar lumps ripen <b>20 minutes</b> sooner.")],
            descAfter: r("Effect is only active when your total amount of buildings ends with 0."),
            quote: "You will find that life gets just a little bit sweeter if you can motivate this spirit with tidy numbers and properly-filled tax returns."),
    ]

    init(_ b: Building) { building = b }

    func godSlot(_ id: Int) -> Int { slot.firstIndex(of: id) ?? -1 }

    func hasGod(_ key: String) -> Int {
        guard let id = gods.firstIndex(where: { $0.key == key }) else { return 0 }
        for i in 0..<3 where slot[i] == id {
            return Game.shared.hasAura("Supreme Intellect") ? max(1, i) : i + 1
        }
        return 0
    }

    func useSwap(_ n: Double) { swapT = now(); swaps = max(0, swaps - n) }

    /// put god `id` in slot (or -1 to take it out); a god already there swaps places or goes back to the roster
    func slotGod(_ id: Int, _ s: Int) {
        let cur = godSlot(id)
        if s == cur { return }
        if s != -1 && slot[s] != -1 {
            if cur != -1 { slot[cur] = slot[s] }
        } else if cur != -1 { slot[cur] = -1 }
        if s != -1 { slot[s] = id }
        Game.shared.refreshCps = true
    }

    /// drag a god onto a slot (uses a worship swap)
    func place(_ id: Int, into s: Int) {
        let cur = godSlot(id)
        if s == -1 {
            if cur != -1 { slotGod(id, -1); Sound.play("snd/sell1.mp3", 0.75) }
            return
        }
        if swaps <= 0 || cur == s { Sound.play("snd/sell1.mp3", 0.75); return }
        useSwap(1)
        slotGod(id, s)
        Sound.play("snd/tick.mp3")
        Sound.play("snd/spirit.mp3", 0.5)
    }

    @discardableResult
    func forceUnslot(_ key: String) -> Bool {
        guard let id = gods.firstIndex(where: { $0.key == key }), godSlot(id) != -1 else { return false }
        slotGod(id, -1)
        return true
    }

    func swapWait() -> Double {
        swaps == 0 ? 3_600_000 * 16 : swaps == 1 ? 3_600_000 * 4 : 3_600_000
    }

    func logic(_ g: Game) {
        if swapT + swapWait() - now() <= 0 && swaps < 3 { swaps += 1; swapT = now() }
    }

    func refill(_ g: Game) {
        guard swaps < 3 else { return }
        LumpRefill.refill(g, 1) {
            self.swaps = 3; self.swapT = now()
            Sound.play("snd/pop\(Int.random(in: 1...3)).mp3", 0.75)
        }
    }

    // effects on the game
    func applyEffects(_ g: Game) {
        var mult = 1.0, build = 1.0
        var l = hasGod("asceticism"); if l == 1 { mult *= 1.15 } else if l == 2 { mult *= 1.1 } else if l == 3 { mult *= 1.05 }
        l = hasGod("ages")
        let periods = [0.0, 3, 12, 24]
        if l > 0 { mult *= 1 + 0.15 * sin((now() / 1000 / (3600 * periods[l])) * .pi * 2) }
        l = hasGod("decadence"); if l == 1 { build *= 0.93 } else if l == 2 { build *= 0.95 } else if l == 3 { build *= 0.98 }
        l = hasGod("industry"); if l == 1 { build *= 1.1 } else if l == 2 { build *= 1.06 } else if l == 3 { build *= 1.03 }
        l = hasGod("labor"); if l == 1 { build *= 0.97 } else if l == 2 { build *= 0.98 } else if l == 3 { build *= 0.99 }
        if l == 1 { g.pool["clickM"]! *= 1.15 } else if l == 2 { g.pool["clickM"]! *= 1.1 } else if l == 3 { g.pool["clickM"]! *= 1.05 }
        g.pool["cpsM"]! *= mult
        for i in 0..<g.buildings.count { g.pool["building\(i)M"]! *= build }
        l = hasGod("mother")
        if l == 1 { g.pool["milkPowerM"]! *= 1.1; g.pool["gcFreqM"]! /= 1.15 }
        else if l == 2 { g.pool["milkPowerM"]! *= 1.05; g.pool["gcFreqM"]! /= 1.1 }
        else if l == 3 { g.pool["milkPowerM"]! *= 1.03; g.pool["gcFreqM"]! /= 1.05 }
        l = hasGod("industry")
        if l == 1 { g.pool["gcFreqM"]! /= 1.1 } else if l == 2 { g.pool["gcFreqM"]! /= 1.06 } else if l == 3 { g.pool["gcFreqM"]! /= 1.03 }
        l = hasGod("seasons")
        if l > 0 && g.season != "" && g.season != "fools" {
            g.pool["gcFreqM"]! /= [1, 0.97, 0.98, 0.99][l]
        }
        l = hasGod("creation"); if l == 1 { g.pool["buildingCostM"]! *= 0.93 } else if l == 2 { g.pool["buildingCostM"]! *= 0.95 } else if l == 3 { g.pool["buildingCostM"]! *= 0.98 }
    }
    /// Dotjeiess makes heavenly chips weaker
    func heavenlyMult() -> Double {
        let l = hasGod("creation")
        return l == 1 ? 0.7 : l == 2 ? 0.8 : l == 3 ? 0.9 : 1
    }

    func onSell(_ g: Game, _ sold: Int) {
        let l = hasGod("ruin")
        guard l > 0, sold > 0 else { return }
        let per = [0, 0.01, 0.005, 0.0025][l]
        if let old = g.hasBuff("devastation") { old.pow += Double(sold) * per; g.refreshCps = true }
        else { g.addBuff("devastation", t: 10, pow: 1 + Double(sold) * per) }
    }
    func onGoldenClick(_ g: Game) {
        if forceUnslot("asceticism") { useSwap(1_000_000) }
    }

    func reset(hard: Bool) { swaps = 3; swapT = now(); slot = [-1, -1, -1] }
    func save() -> String {
        slot.map { String($0) }.joined(separator: "/") + " " + Fmt.jsNumber(swaps) + " " + Fmt.jsNumber(swapT) + " 0"
    }
    func load(_ s: String) {
        let spl = s.split(separator: " ").map(String.init)
        guard !spl.isEmpty else { return }
        let bits = spl[0].split(separator: "/").map { Int(Double($0) ?? -1) }
        slot = [-1, -1, -1]
        for (i, b) in bits.enumerated() where i < 3 && b >= 0 && b < gods.count { slot[i] = b }
        swaps = spl.count > 1 ? Double(spl[1]) ?? 3 : 3
        swapT = spl.count > 2 ? Double(spl[2]) ?? now() : now()
    }
}

/// Refilling minigame resources with a sugar lump (once every 15 minutes).
enum LumpRefill {
    static var max: Double { Game.fps * 60 * 15 }
    static func canRefill(_ g: Game) -> Bool { g.lumpRefill <= 0 }
    static func refill(_ g: Game, _ n: Double, _ f: @escaping () -> Void) {
        guard g.lumps >= n, canRefill(g) else { Sound.play("snd/clickOff2.mp3", 0.5); return }
        g.lumps -= n
        g.lumpRefill = max
        f()
        g.refreshCps = true
    }
}
