import Foundation

// Sugar lumps and building levels: Swift port of the app's mods/sugar-lumps.js
// (itself ported from the desktop game).

enum Lumps {
    static let HOUR = 1000.0 * 60 * 60
    static let baseMatureAge = HOUR * 20
    static let baseRipeAge = HOUR * 23
    static let baseOverripeAge = HOUR * 24
    private static var lastTick = 0.0

    static let achievs: [(String, String, [Int], String?)] = [
        ("Dude, sweet", "Harvest <b>7 coalescing sugar lumps</b>.", [24, 14], nil),
        ("Sugar rush", "Harvest <b>30 coalescing sugar lumps</b>.", [26, 14], nil),
        ("Year's worth of cavities", "Harvest <b>365 coalescing sugar lumps</b>.<q>My lumps my lumps my lumps.</q>", [29, 14], nil),
        ("Hand-picked", "Successfully harvest a coalescing sugar lump before it's ripe.", [28, 14], nil),
        ("Sugar sugar", "Harvest a <b>bifurcated sugar lump</b>.", [29, 15], nil),
        ("All-natural cane sugar", "Harvest a <b>golden sugar lump</b>.", [29, 16], "shadow"),
        ("Sweetmeats", "Harvest a <b>meaty sugar lump</b>.", [29, 17], nil),
        ("Maillard reaction", "Harvest a <b>caramelized sugar lump</b>.", [29, 27], nil),
    ]

    /// The lump ages; the Pantheon's Rigidel shortens them (the minigames mod wraps these getters).
    static var matureAge: Double { baseMatureAge * Minigames.lumpAgeMult() }
    static var ripeAge: Double { baseRipeAge * Minigames.lumpAgeMult() }
    static var overripeAge: Double { baseOverripeAge * Minigames.lumpAgeMult() }

    static func canLumps() -> Bool { G.lumpT > 0 || (G.cookiesEarned + G.cookiesReset) >= 1e9 }

    static func computeLumpType() {
        JSMath.seedrandom(G.seed + "/" + jsString(G.lumpT))
        var types = [0]
        if JSMath.random() < 0.1 { types.append(1) }
        if JSMath.random() < 3.0 / 1000 { types.append(2) }
        if JSMath.random() < 0.1 * Double(G.elderWrath) { types.append(3) }
        if JSMath.random() < 1.0 / 50 { types.append(4) }
        G.lumpCurrentType = choose(types)
        JSMath.seedrandom()
    }

    static func gainLumps(_ total: Double) {
        G.lumps += total
        G.lumpsTotal += total
        if G.lumpsTotal >= 7 { G.win("Dude, sweet") }
        if G.lumpsTotal >= 30 { G.win("Sugar rush") }
        if G.lumpsTotal >= 365 { G.win("Year's worth of cavities") }
    }

    @discardableResult
    static func harvestLumps(_ amount: Double, silent: Bool = false) -> Double {
        G.lumpT = nowMs()
        var total = amount
        let type = G.lumpCurrentType
        if type == 1 { total *= choose([1.0, 2]) }
        else if type == 2 {
            total *= choose([2.0, 3, 4, 5, 6, 7])
            G.earn(min(G.cookiesPs * 60 * 60 * 24, G.cookies))
            G.toast("Sugar blessing!", "Your golden sugar lump doubled your cookies.", [29, 16])
        } else if type == 3 { total *= choose([0.0, 0, 1, 2, 2]) }
        else if type == 4 { total *= choose([1.0, 2, 3]) }
        total = total.rounded(.down)
        gainLumps(total)
        if type == 1 { G.win("Sugar sugar") }
        else if type == 2 { G.win("All-natural cane sugar") }
        else if type == 3 { G.win("Sweetmeats") }
        else if type == 4 { G.win("Maillard reaction") }
        if !silent {
            if total > 0 { G.toast("+\(B(total)) sugar lump\(total == 1 ? "" : "s")", "You now have \(B(G.lumps)).", [29, 14]) }
            else { G.toast("Botched harvest!", "The sugar lump crumbled away.", [23, 14]) }
            PlaySound("snd/pop\(Int((JSMath.random() * 3 + 1).rounded(.down))).mp3", 0.75)
        }
        computeLumpType()
        return total
    }

    static func harvestLumpNow() {
        let age = nowMs() - G.lumpT
        if age < matureAge { return }
        if age < ripeAge {
            let amount = choose([0.0, 1])
            if amount != 0 { G.win("Hand-picked") }
            harvestLumps(amount)
        } else { harvestLumps(1) }
    }

    static func doLumps() {
        if !canLumps() { return }
        if G.lumpT <= 0 {
            G.lumpT = nowMs()
            G.lumps = max(0, G.lumps)
            G.lumpsTotal = max(0, G.lumpsTotal)
            computeLumpType()
            G.toast("Sugar lumps!", "Because you've baked a <b>billion cookies</b>, you're now attracting <b>sugar lumps</b>. One is growing next to your cookie count. Harvest it when it's ripe and spend lumps to level up your buildings!", [23, 14])
        }
        G.lumpT = min(nowMs(), G.lumpT)
        let age = nowMs() - G.lumpT
        if age >= overripeAge {
            let amount = (age / overripeAge).rounded(.down)
            if amount > 1 {
                harvestLumps(1, silent: true)
                G.lumpCurrentType = 0
                harvestLumps(amount - 1, silent: true)
                G.toast("Welcome back!", "You harvested <b>\(B(amount)) sugar lumps</b> while you were away.", [29, 14])
                G.lumpT = nowMs() - (age - amount * overripeAge)
                computeLumpType()
            } else { harvestLumps(1) }
        }
    }

    /// the lump picture next to the cookie count: two stacked icons, the second fading in
    static func lumpIcons() -> (a: [Int], b: [Int], opacity: Double) {
        let age = nowMs() - G.lumpT
        let phase = min(6, Int(((age / overripeAge) * 7).rounded(.down)))
        let phase2 = min(6, Int(((age / overripeAge) * 7).rounded(.down)) + 1)
        var row = 14, row2 = 14
        let type = G.lumpCurrentType
        if type == 1 { if phase2 >= 6 { row2 = 15 } }
        else if type == 2 { if phase >= 4 { row = 16 }; if phase2 >= 4 { row2 = 16 } }
        else if type == 3 { if phase >= 4 { row = 17 }; if phase2 >= 4 { row2 = 17 } }
        else if type == 4 { if phase >= 4 { row = 27 }; if phase2 >= 4 { row2 = 27 } }
        var opacity = min(6, (age / overripeAge) * 7).truncatingRemainder(dividingBy: 1)
        if phase >= 6 { opacity = 1 }
        return ([23 + min(phase, 5), row], [23 + phase2, row2], opacity)
    }

    @discardableResult
    static func levelUpBuilding(_ me: Building) -> Bool {
        let cost = Double(me.level + 1)
        if G.lumps < cost { return false }
        G.lumps -= cost
        me.level += 1
        G.computeCps()
        PlaySound("snd/upgrade.mp3", 0.6)
        G.toast("\(me.getName()) level \(me.level)!", "\(cap(me.plural)) now make <b>+\(me.level)%</b> more cookies.", me.icon)
        Minigames.onLevelUp(me)
        return true
    }

    static func onReset(_ hard: Bool) {
        if hard {
            G.lumps = 0; G.lumpsTotal = 0; G.lumpT = 0; G.lumpCurrentType = 0; G.lumpRefill = 0
            for b in G.buildings { b.level = 0 }
        }
    }

    /// setInterval(doLumps,1000) in the mod, plus the auto-harvest from mods/reminders.js
    static func logic() {
        let now = nowMs()
        if now - lastTick >= 1000 {
            lastTick = now
            doLumps()
        }
        if now - lastAutoHarvest >= 2000 {
            lastAutoHarvest = now
            if AppSettings.shared.autoHarvest && canLumps() && G.lumpT > 0 && now - G.lumpT >= ripeAge { harvestLumpNow() }
        }
    }
    private static var lastAutoHarvest = 0.0
}
