import Foundation

/// Sugar lumps and building levels (rules from the desktop game).
enum Lumps {
    static let hour = 3_600_000.0
    static var matureAge: Double { 20 * hour - rigidel() }
    static var ripeAge: Double { 23 * hour - rigidel() }
    static var overripeAge: Double { 24 * hour - rigidel() }

    /// Rigidel (Pantheon) makes lumps ripen sooner while your building count ends in 0
    static func rigidel() -> Double {
        let g = Game.shared
        guard g.buildingsN % 10 == 0 else { return 0 }
        let lvl = Minigames.shared.hasGod("order")
        if lvl == 1 { return hour } else if lvl == 2 { return hour * 2 / 3 } else if lvl == 3 { return hour / 3 }
        return 0
    }

    static func canLumps(_ g: Game) -> Bool { g.lumpT > 0 || (g.cookiesEarned + g.cookiesReset) >= 1e9 }

    static func computeType(_ g: Game) {
        var r = SeededRandom(g.seed + "/" + String(Int(g.lumpT)))
        var types = [0]
        let curve = g.auraMult("Dragon's Curve") > 0 ? 2.0 : 1.0
        if r.next() < 0.1 * curve { types.append(1) }
        if r.next() < 3.0 / 1000 * curve { types.append(2) }
        if r.next() < 0.1 * Double(g.elderWrath) * curve { types.append(3) }
        if r.next() < 1.0 / 50 * curve { types.append(4) }
        g.lumpCurrentType = types[Int(r.next() * Double(types.count))]
    }

    static func gain(_ g: Game, _ total: Double) {
        g.lumps += total
        g.lumpsTotal += total
        if g.lumpsTotal >= 7 { g.win("Dude, sweet") }
        if g.lumpsTotal >= 30 { g.win("Sugar rush") }
        if g.lumpsTotal >= 365 { g.win("Year's worth of cavities") }
    }

    @discardableResult
    static func harvest(_ g: Game, _ amount: Double, silent: Bool = false) -> Double {
        g.lumpT = now()
        var total = amount
        let type = g.lumpCurrentType
        if type == 1 { total *= Double([1, 2].randomPick()) }
        else if type == 2 {
            total *= Double([2, 3, 4, 5, 6, 7].randomPick())
            g.earn(min(g.cookiesPs * 86400, g.cookies))
            g.toast("Sugar blessing!", "Your golden sugar lump doubled your cookies.", [29, 16])
        }
        else if type == 3 { total *= Double([0, 0, 1, 2, 2].randomPick()) }
        else if type == 4 { total *= Double([1, 2, 3].randomPick()) }
        total = total.rounded(.down)
        gain(g, total)
        if type == 1 { g.win("Sugar sugar") } else if type == 2 { g.win("All-natural cane sugar") }
        else if type == 3 { g.win("Sweetmeats") } else if type == 4 { g.win("Maillard reaction") }
        if !silent {
            if total > 0 { g.toast("+\(B(total)) sugar lump\(total == 1 ? "" : "s")", "You now have \(B(g.lumps)).", [29, 14]) }
            else { g.toast("Botched harvest!", "The sugar lump crumbled away.", [23, 14]) }
            Sound.play("snd/pop\(Int.random(in: 1...3)).mp3", 0.75)
        }
        computeType(g)
        return total
    }

    static func harvestNow(_ g: Game) {
        let age = now() - g.lumpT
        if age < matureAge { return }
        if age < ripeAge {
            let a = Double([0, 1].randomPick())
            if a != 0 { g.win("Hand-picked") }
            harvest(g, a)
        } else { harvest(g, 1) }
    }

    private static var lastCheck = 0.0
    static func logic(_ g: Game) {
        if g.lumpRefill > 0 { g.lumpRefill -= 1 }
        guard now() - lastCheck >= 1000 else { return }
        lastCheck = now()
        if !canLumps(g) { return }
        if g.lumpT <= 0 {
            g.lumpT = now()
            g.lumps = max(0, g.lumps); g.lumpsTotal = max(0, g.lumpsTotal)
            computeType(g)
            g.toast("Sugar lumps!", "Because you've baked a <b>billion cookies</b>, you're now attracting <b>sugar lumps</b>. One is growing next to your cookie count. Harvest it when it's ripe and spend lumps to level up your buildings!", [23, 14])
        }
        g.lumpT = min(now(), g.lumpT)
        let age = now() - g.lumpT
        if age >= overripeAge {
            let amount = (age / overripeAge).rounded(.down)
            if amount > 1 {
                harvest(g, 1, silent: true)
                g.lumpCurrentType = 0
                harvest(g, amount - 1, silent: true)
                g.toast("Welcome back!", "You harvested <b>\(B(amount)) sugar lumps</b> while you were away.", [29, 14])
                g.lumpT = now() - (age - amount * overripeAge)
                computeType(g)
            } else { harvest(g, 1) }
        }
    }

    /// icons for the lump on the cookie screen: current phase, next phase, and how far between them
    static func icons(_ g: Game) -> (a: [Int], b: [Int], opacity: Double) {
        let age = now() - g.lumpT
        let phase = min(6, Int((age / overripeAge) * 7))
        let phase2 = min(6, Int((age / overripeAge) * 7) + 1)
        var row = 14, row2 = 14
        switch g.lumpCurrentType {
        case 1: if phase2 >= 6 { row2 = 15 }
        case 2: if phase >= 4 { row = 16 }; if phase2 >= 4 { row2 = 16 }
        case 3: if phase >= 4 { row = 17 }; if phase2 >= 4 { row2 = 17 }
        case 4: if phase >= 4 { row = 27 }; if phase2 >= 4 { row2 = 27 }
        default: break
        }
        var op = min(6, (age / overripeAge) * 7).truncatingRemainder(dividingBy: 1)
        if phase >= 6 { op = 1 }
        return ([23 + min(phase, 5), row], [23 + phase2, row2], op)
    }

    static func levelUp(_ g: Game, _ b: Building) -> Bool {
        let cost = Double(b.level + 1)
        if g.lumps < cost { return false }
        g.lumps -= cost
        b.level += 1
        g.computeCps()
        Sound.play("snd/upgrade.mp3", 0.6)
        g.toast("\(b.def.name) level \(b.level)!", "\(cap(b.def.plural)) now make <b>+\(b.level)%</b> more cookies.", b.def.icon)
        Minigames.shared.onLevel(b)
        return true
    }

    static func reset(_ g: Game, hard: Bool) {
        if hard { g.lumps = 0; g.lumpsTotal = 0; g.lumpT = 0; g.lumpCurrentType = 0; g.lumpRefill = 0 }
    }

    static func checkAchievs(_ g: Game) {}
}
