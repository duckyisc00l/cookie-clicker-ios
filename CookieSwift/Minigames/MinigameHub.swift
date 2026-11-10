import Foundation

// Swift port of the app's mods/minigame-bridge.js and the desktop "Game" shim (mods/minigames/shim.js):
// connects the four minigames (desktop rules) to the phone game.

/// What each minigame provides (the desktop minigame objects: M.launch/reset/save/load/logic/draw).
protocol Minigame: AnyObject {
    var parent: Building { get }
    var name: String { get }
    func reset(_ hard: Bool)
    func save() -> String
    func load(_ str: String)
    /// called 30 times a second (M.logic)
    func logic()
}

enum Minigames {
    static let names: [String: String] = ["Farm": "Garden", "Bank": "Stock Market", "Temple": "Pantheon", "Wizard tower": "Grimoire"]
    static let order = ["Farm", "Bank", "Temple", "Wizard tower"]
    /// loaded minigames by building name (Game.ccLoaded)
    static var loaded: [String: Minigame] = [:]
    static var garden: Garden? { loaded["Farm"] as? Garden }
    static var market: Market? { loaded["Bank"] as? Market }
    static var pantheon: Pantheon? { loaded["Temple"] as? Pantheon }
    static var grimoire: Grimoire? { loaded["Wizard tower"] as? Grimoire }
    /// the minigame window currently open
    static var shown: String? = nil

    // MARK: setup (achievements and buff types)
    static let achievs: [(String, String, [Int], String?)] = [
        ("Bibbidi-bobbidi-boo", "Cast <b>9</b> spells.", [21, 11], nil),
        ("I'm the wiz", "Cast <b>99</b> spells.", [22, 11], nil),
        ("A wizard is you", "Cast <b>999</b> spells.<q>I'm a what?</q>", [29, 11], nil),
        ("Botany enthusiast", "Harvest <b>100</b> mature garden plants.", [26, 20], nil),
        ("Green, aching thumb", "Harvest <b>1,000</b> mature garden plants.", [27, 20], nil),
        ("In the garden of Eden (baby)", "Fill every tile of the biggest garden plot with plants.<q>Isn't tending to those precious little plants just so rock and/or roll?</q>", [28, 20], nil),
        ("Keeper of the conservatory", "Unlock every garden seed.", [25, 20], nil),
        ("Seedless to nay", "Convert a complete seed log into sugar lumps by sacrificing your garden to the sugar hornets.<div class=\"line\"></div>Owning this achievement makes seeds <b>5% cheaper</b>, plants mature <b>5% sooner</b>, and plant upgrades drop <b>5% more</b>.", [29, 20], nil),
        ("Initial public offering", "Make your first stock market profit.", [0, 33], nil),
        ("Rookie numbers", "Own at least <b>100</b> of every stock market good.<q>Gotta pump those numbers up!</q>", [9, 33], nil),
        ("No nobility in poverty", "Own at least <b>500</b> of every stock market good.<q>What kind of twisted individual is out there cramming camels through needle holes anyway?</q>", [10, 33], nil),
        ("Full warehouses", "Own at least <b>1,000</b> of a stock market good.", [11, 33], nil),
        ("Make my day", "Make <b>a day</b> of CpS ($86,400) in 1 stock market sale.", [1, 33], nil),
        ("Buy buy buy", "Spend <b>a day</b> of CpS ($86,400) in 1 stock market purchase.", [1, 33], nil),
        ("Liquid assets", "Have your stock market profits surpass <b>$10,000,000</b>.", [12, 33], nil),
        ("Gaseous assets", "Have your stock market profits surpass <b>a whole year</b> of CpS ($31,536,000).<q>Boy, how volatile!</q>", [18, 33], "shadow"),
        ("Pyramid scheme", "Unlock the <b>highest-tier</b> stock market headquarters.", [18, 33], nil),
    ]

    /// G.addData part: buff types (achievements come from Content.json, they're created by the same mod)
    static func setup() {
        func reg(_ name: String, _ nameD: String, _ icon: [Int], _ type: Int, _ effs: @escaping (Buff) -> [Eff], _ desc: @escaping (Buff) -> String) {
            if G.buffTypesBN[name] != nil { return }
            G.registerBuffType(BuffType(name: name, nameD: nameD, icon: icon, desc: desc, t: 60, pow: 1, type: type, stackT: 2, stackPow: 2, effsFunc: effs))
        }
        let pct: (Buff) -> String = { B($0.pow) }
        reg("haggler luck", "Haggler's luck", [25, 11], 1, { [Eff("upgradeCostM", 1 - $0.pow / 100, 1)] }, { "All upgrades are \(pct($0))% cheaper for [t]!" })
        reg("haggler misery", "Haggler's misery", [25, 11], 2, { [Eff("upgradeCostM", 1 + $0.pow / 100, 1)] }, { "All upgrades are \(pct($0))% pricier for [t]!" })
        reg("pixie luck", "Crafty pixies", [26, 11], 1, { [Eff("buildingCostM", 1 - $0.pow / 100, 1)] }, { "All buildings are \(pct($0))% cheaper for [t]!" })
        reg("pixie misery", "Nasty goblins", [26, 11], 2, { [Eff("buildingCostM", 1 + $0.pow / 100, 1)] }, { "All buildings are \(pct($0))% pricier for [t]!" })
        reg("magic adept", "Magic adept", [29, 11], 1, { _ in [] }, { "Spells backfire \(B($0.pow)) times less for [t]." })
        reg("magic inept", "Magic inept", [29, 11], 2, { _ in [] }, { "Spells backfire \(B($0.pow)) times more for [t]." })
        reg("devastation", "Devastation", [23, 18], 1, { [Eff("clickM", $0.pow, 1)] }, { "Clicking power +\(jsString(($0.pow * 100 - 100).rounded(.down)))% for [t]!" })
        reg("sugar blessing", "Sugar blessing", [29, 16], 1, { _ in [Eff("gcFreqM", 1.1, 1)] }, { _ in "You find 10% more golden cookies for the next [t]." })
        for n in 1...3 {
            reg("loan \(n)", "Loan \(n)", [1, 33], 1, { [Eff("cpsBuffM", $0.pow, 1)] }, { "Cookie production x\(B($0.pow, 2)) for [t]!" })
            reg("loan \(n) interest", "Loan \(n) (interest)", [1, 33], 2, { [Eff("cpsBuffM", $0.pow, 1)] }, { "Cookie production x\(B($0.pow, 2)) for [t]!" })
        }
        // the minigame page is started as soon as any minigame is unlocked (keeps them running in the background)
        loadAll()
    }

    /// G.toastBuff
    static func toastBuff(_ me: Buff?) {
        guard let me = me else { return }
        G.toast(me.type.nameD, me.type.desc(me).replacingOccurrences(of: "[t]", with: sayTime(me.tm * 1000, -1)), me.type.icon)
    }

    // MARK: loading (Game.ccLoad / ccLoadAll / ccSaveAll / ccLoadSaves / ccReset)
    static func load(_ buildingName: String) {
        guard let b = G.buildingsBN[buildingName], b.level > 0, loaded[buildingName] == nil else { return }
        let m: Minigame
        switch buildingName {
        case "Farm": m = Garden(b)
        case "Bank": m = Market(b)
        case "Temple": m = Pantheon(b)
        default: m = Grimoire(b)
        }
        loaded[buildingName] = m
        m.reset(true)
        if !b.minigameSave.isEmpty { m.reset(true); m.load(b.minigameSave) }
        else if let mk = m as? Market { mk.graphCols = 1; mk.toRedraw = 2 }  // shim.js: new markets get the dark graph
        G.refreshCps = true
    }
    static func loadAll() { for n in order { load(n) } }
    static func saveAll() { for (n, m) in loaded { G.buildingsBN[n]?.minigameSave = m.save() } }
    static func loadSaves() {
        for (n, m) in loaded {
            guard let b = G.buildingsBN[n] else { continue }
            m.reset(true)
            if !b.minigameSave.isEmpty { m.load(b.minigameSave) }
        }
        loadAll()
    }

    // MARK: hooks from the game
    static func afterLoad() { loadSaves() }
    static func onReset(_ hard: Bool) {
        for (_, m) in loaded { m.reset(hard) }
        if hard {
            for b in G.buildings { b.minigameSave = "" }
            loaded = [:]
        }
    }
    static func logic(_ delta: Double) {
        if G.onAscend != 0 { return }
        for n in order { loaded[n]?.logic() }
        // the lump refill cooldown counts down in frames, like the desktop game
        if G.lumpRefill > 0 { G.lumpRefill -= 1 }
    }
    static func onLevelUp(_ me: Building) {
        guard let mg = names[me.name] else { return }
        loadAll()
        if me.level == 1 { G.toast("\(mg) unlocked!", "Open it from your \(me.plural)' info in the Store.", me.icon) }
    }
    static func onBuy(_ b: Building) {}
    /// Godzamok: selling buildings boosts clicking for 10 seconds
    static func onSell(_ b: Building, _ sold: Int) {
        let l = G.hasGod("ruin")
        if sold > 0 && l > 0 {
            let per = [0, 0.01, 0.005, 0.0025][l]
            if let old = G.hasBuff("devastation") {
                old.pow += Double(sold) * per
                old.effs = old.type.effsFunc?(old) ?? []
                G.refreshCps = true
            } else { G.addBuff("devastation", t: 10, pow: 1 + Double(sold) * per) }
        }
    }
    /// Holobore: clicking a golden cookie unslots him and uses up all worship swaps
    static func onGoldenClicked(_ me: Shimmer) {
        guard let p = pantheon, p.hasGod("asceticism") > 0 else { return }
        if p.forceUnslotGod("asceticism") { p.useSwap(1000000) }
    }
    static func onBuffCreated(_ b: Buff) {}
    /// loans: when a loan runs out, its interest starts
    static func onBuffEnded(_ b: Buff) {
        let n = b.type.name
        if n.count == 6 && n.hasPrefix("loan "), let k = Int(n.suffix(1)) { market?.takeLoan(k, interest: true) }
    }

    // MARK: effects on the game's numbers (window.__ccMinigameEffs, run inside G.computeCps)
    static func applyEffects(_ pool: inout [String: Double]) {
        if let g = garden {
            let e = g.effs
            let map: [(String, String)] = [("cps", "cpsM"), ("click", "clickM"), ("cursorCps", "building0M"), ("grandmaCps", "building1M"),
                ("goldenCookieGain", "gcEffectsMultM"), ("goldenCookieFreq", "gcFreqM"), ("goldenCookieDur", "gcLifeM"), ("goldenCookieEffDur", "gcEffectsLifeM"),
                ("wrathCookieGain", "gcWrathEffectsMultM"), ("wrathCookieFreq", "gcFreqM"), ("wrathCookieDur", "gcWrathLifeM"), ("wrathCookieEffDur", "gcWrathEffectsLifeM"),
                ("reindeerGain", "reindeerEffectsMultM"), ("reindeerFreq", "reindeerFreqM"), ("reindeerDur", "reindeerLifeM"), ("itemDrops", "dropChanceM"),
                ("milk", "milkPowerM"), ("upgradeCost", "upgradeCostM"), ("buildingCost", "buildingCostM")]
            for (k, p) in map {
                if k == "wrathCookieFreq" { continue }   // golden and wrath cookies share one timer in the phone game
                if let v = e[k], pool[p] != nil { pool[p]! *= v }
            }
        }
        guard pantheon != nil else { return }
        var lvl = 0
        var mult = 1.0, build = 1.0
        lvl = G.hasGod("asceticism"); if lvl == 1 { mult *= 1.15 } else if lvl == 2 { mult *= 1.1 } else if lvl == 3 { mult *= 1.05 }
        lvl = G.hasGod("ages"); if lvl > 0 { mult *= 1 + 0.15 * sin((nowMs() / 1000 / (60 * 60 * [0, 3, 12, 24][lvl])) * Double.pi * 2) }
        lvl = G.hasGod("decadence"); if lvl == 1 { build *= 0.93 } else if lvl == 2 { build *= 0.95 } else if lvl == 3 { build *= 0.98 }
        lvl = G.hasGod("industry"); if lvl == 1 { build *= 1.1 } else if lvl == 2 { build *= 1.06 } else if lvl == 3 { build *= 1.03 }
        if lvl > 0 { pool["gcFreqM"]! /= [1, 1.1, 1.06, 1.03][lvl] }
        lvl = G.hasGod("labor"); if lvl == 1 { build *= 0.97 } else if lvl == 2 { build *= 0.98 } else if lvl == 3 { build *= 0.99 }
        if lvl > 0 { pool["clickM"]! *= [1, 1.15, 1.1, 1.05][lvl] }
        lvl = G.hasGod("decadence"); if lvl > 0 { pool["gcEffectsLifeM"]! *= [1, 1.07, 1.05, 1.02][lvl]; pool["gcWrathEffectsLifeM"]! *= [1, 1.07, 1.05, 1.02][lvl] }
        lvl = G.hasGod("mother"); if lvl > 0 { pool["milkPowerM"]! *= [1, 1.1, 1.05, 1.03][lvl]; pool["gcFreqM"]! /= [1, 1.15, 1.1, 1.05][lvl] }
        lvl = G.hasGod("seasons"); if lvl > 0 && G.season != "" && G.season != "fools" { pool["gcFreqM"]! /= [1, 0.97, 0.98, 0.99][lvl] }
        lvl = G.hasGod("creation"); if lvl > 0 { pool["buildingCostM"]! *= [1, 0.93, 0.95, 0.98][lvl] }
        pool["cpsM"]! *= mult
        for i in 0..<G.buildings.count { if pool["building\(i)M"] != nil { pool["building\(i)M"]! *= build } }
    }
    /// Dotjeiess: heavenly chips have less effect
    static func heavenlyMult() -> Double {
        let l = G.hasGod("creation")
        return l > 0 ? [1, 0.7, 0.8, 0.9][l] : 1
    }
    /// Rigidel: sugar lumps ripen sooner while your building count ends in 0
    static func rigidel() -> Double {
        let l = G.hasGod("order")
        if l == 0 { return 0 }
        let n = G.buildings.reduce(0) { $0 + $1.amount }
        if n % 10 != 0 { return 0 }
        return [0, Lumps.HOUR, Lumps.HOUR * 2 / 3, Lumps.HOUR / 3][l]
    }
}

extension Game {
    /// G.hasGod: the slot (1-3) a spirit is in, or 0
    func hasGod(_ what: String) -> Int { Minigames.pantheon?.hasGod(what) ?? 0 }
}
