import Foundation

final class Plant {
    let key: String, id: Int, name: String, icon: Int, cost: Double, costM: Double
    let ageTick: Double, ageTickR: Double, matureBase: Double
    let children: [String], effs: String, q: String, details: String
    let weed: Bool, fungus: Bool, immortal: Bool, noContam: Bool, contam: Double, plantable: Bool
    var mature: Double
    var unlocked = 0
    init(_ d: [String: Any]) {
        key = d["key"] as? String ?? ""
        id = d["id"] as? Int ?? 0
        name = d["name"] as? String ?? ""
        icon = d["icon"] as? Int ?? 0
        cost = (d["cost"] as? NSNumber)?.doubleValue ?? 0
        costM = (d["costM"] as? NSNumber)?.doubleValue ?? 0
        ageTick = (d["ageTick"] as? NSNumber)?.doubleValue ?? 1
        ageTickR = (d["ageTickR"] as? NSNumber)?.doubleValue ?? 0
        matureBase = (d["mature"] as? NSNumber)?.doubleValue ?? 50
        mature = matureBase
        children = d["children"] as? [String] ?? []
        effs = d["effs"] as? String ?? ""
        q = d["q"] as? String ?? ""
        details = d["details"] as? String ?? ""
        weed = d["weed"] as? Bool ?? false
        fungus = d["fungus"] as? Bool ?? false
        immortal = d["immortal"] as? Bool ?? false
        noContam = d["noContam"] as? Bool ?? false
        contam = (d["contam"] as? NSNumber)?.doubleValue ?? 0
        plantable = d["plantable"] as? Bool ?? true
    }
}

struct Soil { let key: String, name: String, icon: Int, tick: Double, effMult: Double, weedMult: Double, req: Int, effs: String, q: String }

/// Garden (Farm minigame): plant seeds, cross-breed new plants, harvest them. Rules from the desktop game.
final class Garden: Minigame {
    let building: Building
    let name = "Garden"
    var plants: [Plant] = []
    var plantsBN: [String: Plant] = [:]
    var plot: [[(Int, Double)]] = Array(repeating: Array(repeating: (0, 0), count: 6), count: 6)  // (plant id + 1, age)
    var plotBoost: [[[Double]]] = Array(repeating: Array(repeating: [1, 1, 1], count: 6), count: 6)
    var effs: [String: Double] = [:]
    var soil = 0, freeze = 0
    var nextSoil = now(), nextStep = now(), nextFreeze = now()
    var stepT = 300.0
    var harvests = 0, harvestsTotal = 0, convertTimes = 0.0
    var loopsMult = 1
    var seedSelected = -1

    static let soils: [Soil] = [
        Soil(key: "dirt", name: "Dirt", icon: 0, tick: 5, effMult: 1, weedMult: 1, req: 0, effs: "<span style=\"color:#aaa\">&bull; tick every <b>5 minutes</b></span>", q: "Simple, regular old dirt that you'd find in nature."),
        Soil(key: "fertilizer", name: "Fertilizer", icon: 1, tick: 3, effMult: 0.75, weedMult: 1.2, req: 50, effs: "<span style=\"color:#aaa\">&bull; tick every <b>3 minutes</b></span><br><span class=\"red\">&bull; passive plant effects <b>-25%</b></span><br><span class=\"red\">&bull; weed growth <b>+20%</b></span>", q: "Soil with a healthy helping of fresh manure. Plants grow faster but are less efficient."),
        Soil(key: "clay", name: "Clay", icon: 2, tick: 15, effMult: 1.25, weedMult: 1, req: 100, effs: "<span style=\"color:#aaa\">&bull; tick every <b>15 minutes</b></span><br><span class=\"green\">&bull; passive plant effects <b>+25%</b></span>", q: "Rich soil with very good water retention. Plants grow slower but are more efficient."),
        Soil(key: "pebbles", name: "Pebbles", icon: 3, tick: 5, effMult: 0.25, weedMult: 0.1, req: 200, effs: "<span style=\"color:#aaa\">&bull; tick every <b>5 minutes</b></span><br><span class=\"red\">&bull; passive plant effects <b>-75%</b></span><br><span class=\"green\">&bull; <b>35% chance</b> of collecting seeds automatically when plants expire</span><br><span class=\"green\">&bull; weed growth <b>-90%</b></span>", q: "Dry soil made of small rocks tightly packed together. Not very conducive to plant health, but whatever falls off your crops will be easy to retrieve.<br>Useful if you're one of those farmers who just want to find new seeds without having to micromanage their garden too much."),
        Soil(key: "woodchips", name: "Wood chips", icon: 4, tick: 5, effMult: 0.25, weedMult: 0.1, req: 300, effs: "<span style=\"color:#aaa\">&bull; tick every <b>5 minutes</b></span><br><span class=\"red\">&bull; passive plant effects <b>-75%</b></span><br><span class=\"green\">&bull; plants spread and mutate <b>3 times more</b></span><br><span class=\"green\">&bull; weed growth <b>-90%</b></span>", q: "Soil made of bits and pieces of bark and sawdust. Helpful for young sprouts to develop, not so much for mature plants."),
    ]
    static let plotLimits: [[Int]] = [[2, 2, 4, 4], [2, 2, 5, 4], [2, 2, 5, 5], [1, 2, 5, 5], [1, 1, 5, 5], [1, 1, 6, 5], [1, 1, 6, 6], [0, 1, 6, 6], [0, 0, 6, 6]]

    init(_ b: Building) {
        building = b
        if let url = Bundle.main.url(forResource: "GardenPlants", withExtension: "json"),
           let d = try? Data(contentsOf: url), let arr = try? JSONSerialization.jsonObject(with: d) as? [[String: Any]] {
            plants = arr.map(Plant.init)
        }
        for p in plants { plantsBN[p.key] = p }
        reset(hard: true)
    }

    var unlockedN: Int { plants.filter { $0.unlocked > 0 }.count }
    func plant(_ tile: (Int, Double)) -> Plant? { tile.0 > 0 ? plants[safe: tile.0 - 1] : nil }

    func eff(_ name: String) -> Double { effs[name] ?? 1 }

    func checkUnlockedAll() { if unlockedN >= plants.count { Game.shared.win("Keeper of the conservatory") } }
    @discardableResult
    func unlockSeed(_ p: Plant) -> Bool {
        if p.unlocked > 0 { return false }
        p.unlocked = 1
        checkUnlockedAll()
        return true
    }
    func dropUpgrade(_ name: String, _ rate: Double) {
        let g = Game.shared
        guard g.upgradesBN[name] != nil, !g.Has(name) else { return }
        if rnd() <= rate * g.dropRateMult() * (g.HasAchiev("Seedless to nay") ? 1.05 : 1) { g.unlock(name) }
    }
    func computeMatures() {
        let mult = Game.shared.HasAchiev("Seedless to nay") ? 0.95 : 1
        for p in plants { p.mature = p.matureBase * mult }
    }
    func computeStepT() {
        stepT = Game.shared.Has("Turbo-charged soil") ? 1 : Garden.soils[soil].tick * 60
    }
    func cost(_ p: Plant) -> Double {
        let g = Game.shared
        if g.Has("Turbo-charged soil") { return 0 }
        return max(p.costM, g.cookiesPs * p.cost * 60) * (g.HasAchiev("Seedless to nay") ? 0.95 : 1)
    }
    func isTileUnlocked(_ x: Int, _ y: Int) -> Bool {
        let lvl = max(1, min(Garden.plotLimits.count, building.level)) - 1
        let l = Garden.plotLimits[lvl]
        return x >= l[0] && x < l[2] && y >= l[1] && y < l[3]
    }
    func tile(_ x: Int, _ y: Int) -> (Int, Double) {
        if x < 0 || x > 5 || y < 0 || y > 5 || !isTileUnlocked(x, y) { return (0, 0) }
        return plot[y][x]
    }
    func stage(_ p: Plant, _ age: Double) -> Int {
        if age >= p.mature { return 4 }
        if age >= p.mature * 0.666 { return 3 }
        if age >= p.mature * 0.333 { return 2 }
        return 1
    }

    // MARK: effects
    func computeBoostPlot() {
        plotBoost = Array(repeating: Array(repeating: [1, 1, 1], count: 6), count: 6)
        func effectOn(_ X: Int, _ Y: Int, _ s: Int, _ mult: [Double]) {
            for y in max(0, Y - s)..<min(6, Y + s + 1) {
                for x in max(0, X - s)..<min(6, X + s + 1) where !(X == x && Y == y) {
                    for i in 0..<3 { plotBoost[y][x][i] *= mult[i] }
                }
            }
        }
        for y in 0..<6 { for x in 0..<6 {
            guard let me = plant(plot[y][x]) else { continue }
            let st = stage(me, plot[y][x].1)
            var mult = Garden.soils[soil].effMult
            mult *= [0, 0.1, 0.25, 0.5, 1][st]
            var age = 1.0, power = 1.0, weed = 1.0, range = 0
            switch me.key {
            case "elderwort": age = 1.03; range = 1
            case "queenbeetLump": power = 0.8; range = 1
            case "nursetulip": power = 1.2; range = 1
            case "shriekbulb": power = 0.95; range = 1
            case "tidygrass": weed = 0; range = 2
            case "everdaisy": weed = 0; range = 1
            case "ichorpuff": age = 0.5; power = 0.5; range = 1
            default: break
            }
            if age >= 1 { age = (age - 1) * mult + 1 } else if mult >= 1 { age = 1 / ((1 / age) * mult) } else { age = 1 - (1 - age) * mult }
            if power >= 1 { power = (power - 1) * mult + 1 } else if mult >= 1 { power = 1 / ((1 / power) * mult) } else { power = 1 - (1 - power) * mult }
            if range > 0 { effectOn(x, y, range, [age, power, weed]) }
        } }
    }

    func computeEffs() {
        var e: [String: Double] = [:]
        for k in ["cps", "click", "cursorCps", "grandmaCps", "goldenCookieGain", "goldenCookieFreq", "goldenCookieDur", "goldenCookieEffDur",
                  "wrathCookieGain", "wrathCookieFreq", "wrathCookieDur", "wrathCookieEffDur", "reindeerGain", "reindeerFreq", "reindeerDur",
                  "itemDrops", "milk", "wrinklerSpawn", "wrinklerEat", "upgradeCost", "buildingCost"] { e[k] = 1 }
        if freeze == 0 {
            let soilMult = Garden.soils[soil].effMult
            for y in 0..<6 { for x in 0..<6 {
                guard let me = plant(plot[y][x]) else { continue }
                var m = soilMult * [0, 0.1, 0.25, 0.5, 1][stage(me, plot[y][x].1)]
                m *= plotBoost[y][x][1]
                func add(_ k: String, _ v: Double) { e[k]! += v * m }
                func mul(_ k: String, _ v: Double) { e[k]! *= 1 - v * m }
                switch me.key {
                case "bakerWheat", "bakeberry", "chocoroot", "whiteMildew": add("cps", 0.01)
                case "thumbcorn": add("click", 0.02)
                case "cronerice": add("grandmaCps", 0.03)
                case "gildmillet": add("goldenCookieGain", 0.01); add("goldenCookieEffDur", 0.001)
                case "clover": add("goldenCookieFreq", 0.01)
                case "goldenClover": add("goldenCookieFreq", 0.03)
                case "shimmerlily": add("goldenCookieGain", 0.01); add("goldenCookieFreq", 0.01); add("itemDrops", 0.01)
                case "elderwort": add("wrathCookieGain", 0.01); add("wrathCookieFreq", 0.01); add("grandmaCps", 0.01)
                case "whiteChocoroot": add("goldenCookieGain", 0.01)
                case "brownMold": mul("cps", 0.01)
                case "whiskerbloom": add("milk", 0.002)
                case "chimerose": add("reindeerGain", 0.01); add("reindeerFreq", 0.01)
                case "nursetulip": mul("cps", 0.02)
                case "drowsyfern": add("cps", 0.03); mul("click", 0.05); mul("goldenCookieFreq", 0.1)
                case "wardlichen": mul("wrinklerSpawn", 0.15); mul("wrathCookieFreq", 0.02)
                case "keenmoss": add("itemDrops", 0.03)
                case "queenbeet": add("goldenCookieEffDur", 0.003); mul("cps", 0.02)
                case "queenbeetLump": mul("cps", 0.1)
                case "glovemorel": add("click", 0.04); add("cursorCps", 0.01); mul("cps", 0.01)
                case "cheapcap": mul("upgradeCost", 0.002); mul("buildingCost", 0.002)
                case "foolBolete": add("goldenCookieFreq", 0.02); mul("goldenCookieGain", 0.05); mul("goldenCookieDur", 0.02); mul("goldenCookieEffDur", 0.02)
                case "wrinklegill": add("wrinklerSpawn", 0.02); add("wrinklerEat", 0.01)
                case "greenRot": add("goldenCookieDur", 0.005); add("goldenCookieFreq", 0.01); add("itemDrops", 0.01)
                case "shriekbulb": mul("cps", 0.02)
                default: break
                }
            } }
        }
        effs = e
        Game.shared.refreshCps = true
    }

    /// how the garden's effects change the game's numbers
    func applyEffects(_ g: Game) {
        func m(_ pool: String, _ k: String) { g.pool[pool]! *= eff(k) }
        m("cpsM", "cps"); m("clickM", "click"); m("building0M", "cursorCps"); m("building1M", "grandmaCps")
        m("gcFreqM", "goldenCookieFreq"); m("gcLifeM", "goldenCookieDur"); m("gcEffectsLifeM", "goldenCookieEffDur")
        m("gcWrathLifeM", "wrathCookieDur"); m("gcWrathEffectsLifeM", "wrathCookieEffDur")
        m("reindeerEffectsMultM", "reindeerGain"); m("reindeerFreqM", "reindeerFreq"); m("reindeerLifeM", "reindeerDur")
        m("dropChanceM", "itemDrops"); m("milkPowerM", "milk"); m("upgradeCostM", "upgradeCost"); m("buildingCostM", "buildingCost")
    }

    // MARK: mutations
    func muts(_ n: [String: Int], _ nm: [String: Int]) -> [(String, Double)] {
        func a(_ k: String) -> Int { n[k] ?? 0 }
        func m(_ k: String) -> Int { nm[k] ?? 0 }
        var r: [(String, Double)] = []
        if m("bakerWheat") >= 2 { r += [("bakerWheat", 0.2), ("thumbcorn", 0.05), ("bakeberry", 0.001)] }
        if m("bakerWheat") >= 1 && m("thumbcorn") >= 1 { r += [("cronerice", 0.01)] }
        if m("thumbcorn") >= 2 { r += [("thumbcorn", 0.1), ("bakerWheat", 0.05)] }
        if m("cronerice") >= 1 && m("thumbcorn") >= 1 { r += [("gildmillet", 0.03)] }
        if m("cronerice") >= 2 { r += [("thumbcorn", 0.02)] }
        if m("bakerWheat") >= 1 && m("gildmillet") >= 1 { r += [("clover", 0.03), ("goldenClover", 0.0007)] }
        if m("clover") >= 1 && m("gildmillet") >= 1 { r += [("shimmerlily", 0.02)] }
        if m("clover") >= 2 && a("clover") < 5 { r += [("clover", 0.007), ("goldenClover", 0.0001)] }
        if m("clover") >= 4 { r += [("goldenClover", 0.0007)] }
        if m("shimmerlily") >= 1 && m("cronerice") >= 1 { r += [("elderwort", 0.01)] }
        if m("wrinklegill") >= 1 && m("cronerice") >= 1 { r += [("elderwort", 0.002)] }
        if m("bakerWheat") >= 1 && a("brownMold") >= 1 { r += [("chocoroot", 0.1)] }
        if m("chocoroot") >= 1 && a("whiteMildew") >= 1 { r += [("whiteChocoroot", 0.1)] }
        if m("whiteMildew") >= 1 && a("brownMold") <= 1 { r += [("brownMold", 0.5)] }
        if m("brownMold") >= 1 && a("whiteMildew") <= 1 { r += [("whiteMildew", 0.5)] }
        if m("meddleweed") >= 1 && a("meddleweed") <= 3 { r += [("meddleweed", 0.15)] }
        if m("shimmerlily") >= 1 && m("whiteChocoroot") >= 1 { r += [("whiskerbloom", 0.01)] }
        if m("shimmerlily") >= 1 && m("whiskerbloom") >= 1 { r += [("chimerose", 0.05)] }
        if m("chimerose") >= 2 { r += [("chimerose", 0.005)] }
        if m("whiskerbloom") >= 2 { r += [("nursetulip", 0.05)] }
        if m("chocoroot") >= 1 && m("keenmoss") >= 1 { r += [("drowsyfern", 0.005)] }
        if (m("cronerice") >= 1 && m("keenmoss") >= 1) || (m("cronerice") >= 1 && m("whiteMildew") >= 1) { r += [("wardlichen", 0.005)] }
        if m("wardlichen") >= 1 && a("wardlichen") < 2 { r += [("wardlichen", 0.05)] }
        if m("greenRot") >= 1 && m("brownMold") >= 1 { r += [("keenmoss", 0.1)] }
        if m("keenmoss") >= 1 && a("keenmoss") < 2 { r += [("keenmoss", 0.05)] }
        if m("chocoroot") >= 1 && m("bakeberry") >= 1 { r += [("queenbeet", 0.01)] }
        if m("queenbeet") >= 8 { r += [("queenbeetLump", 0.001)] }
        if m("queenbeet") >= 2 { r += [("duketater", 0.001)] }
        if m("crumbspore") >= 1 && a("crumbspore") <= 1 { r += [("crumbspore", 0.07)] }
        if m("crumbspore") >= 1 && m("thumbcorn") >= 1 { r += [("glovemorel", 0.02)] }
        if m("crumbspore") >= 1 && m("shimmerlily") >= 1 { r += [("cheapcap", 0.04)] }
        if m("doughshroom") >= 1 && m("greenRot") >= 1 { r += [("foolBolete", 0.04)] }
        if m("crumbspore") >= 2 { r += [("doughshroom", 0.005)] }
        if m("doughshroom") >= 1 && a("doughshroom") <= 1 { r += [("doughshroom", 0.07)] }
        if m("doughshroom") >= 2 { r += [("crumbspore", 0.005)] }
        if m("crumbspore") >= 1 && m("brownMold") >= 1 { r += [("wrinklegill", 0.06)] }
        if m("whiteMildew") >= 1 && m("clover") >= 1 { r += [("greenRot", 0.05)] }
        if m("wrinklegill") >= 1 && m("elderwort") >= 1 { r += [("shriekbulb", 0.001)] }
        if m("elderwort") >= 5 { r += [("shriekbulb", 0.001)] }
        if a("duketater") >= 3 { r += [("shriekbulb", 0.005)] }
        if a("doughshroom") >= 4 { r += [("shriekbulb", 0.002)] }
        if m("queenbeet") >= 5 { r += [("shriekbulb", 0.001)] }
        if a("shriekbulb") >= 1 && a("shriekbulb") < 2 { r += [("shriekbulb", 0.005)] }
        if m("bakerWheat") >= 1 && m("whiteChocoroot") >= 1 { r += [("tidygrass", 0.002)] }
        if m("tidygrass") >= 3 && m("elderwort") >= 3 { r += [("everdaisy", 0.002)] }
        if m("elderwort") >= 1 && m("crumbspore") >= 1 { r += [("ichorpuff", 0.002)] }
        return r
    }

    private func neighbors(_ x: Int, _ y: Int, diagonal: Bool) -> ([String: Int], [String: Int], Int) {
        var n: [String: Int] = [:], nm: [String: Int] = [:], any = 0
        var spots = [(x, y - 1), (x, y + 1), (x - 1, y), (x + 1, y)]
        if diagonal { spots += [(x - 1, y - 1), (x - 1, y + 1), (x + 1, y - 1), (x + 1, y + 1)] }
        for (a, b) in spots {
            let t = tile(a, b)
            if let p = plant(t) {
                any += 1
                n[p.key, default: 0] += 1
                if t.1 >= p.mature { nm[p.key, default: 0] += 1 }
            }
        }
        return (n, nm, any)
    }

    // MARK: planting and harvesting
    func say(_ s: String) { Game.shared.toast("", s, nil, true) }

    func onHarvest(_ p: Plant, _ age: Double) {
        let g = Game.shared
        let mature = age >= p.mature
        func gain(_ v: Double, _ label: String) { if v != 0 { g.earn(v); say("(\(label))<br>+\(B(v)) cookies!") } }
        switch p.key {
        case "bakerWheat": if mature { dropUpgrade("Wheat slims", 0.001) }
        case "elderwort": if mature { dropUpgrade("Elderwort biscuits", 0.01) }
        case "bakeberry": if mature { gain(min(g.cookies * 0.03, g.cookiesPs * 60 * 30), "Bakeberry"); dropUpgrade("Bakeberry cookies", 0.015) }
        case "chocoroot": if mature { gain(min(g.cookies * 0.03, g.cookiesPs * 60 * 3), "Chocoroot") }
        case "whiteChocoroot": if mature { gain(min(g.cookies * 0.03, g.cookiesPs * 60 * 3), "White chocoroot") }
        case "drowsyfern": if mature { dropUpgrade("Fern tea", 0.01) }
        case "queenbeet": if mature { gain(min(g.cookies * 0.04, g.cookiesPs * 3600), "Queenbeet") }
        case "queenbeetLump": if mature { Lumps.gain(g, 1); say("(Juicy queenbeet)<br>Sweet!<br><small>Found 1 sugar lump!</small>") }
        case "duketater": if mature { gain(min(g.cookies * 0.08, g.cookiesPs * 7200), "Duketater"); dropUpgrade("Duketater cookies", 0.005) }
        case "greenRot": if mature { dropUpgrade("Green yeast digestives", 0.005) }
        case "ichorpuff": if mature { dropUpgrade("Ichor syrup", 0.005) }
        default: break
        }
    }
    func onDie(_ p: Plant) {
        let g = Game.shared
        if p.key == "crumbspore" { let v = min(g.cookies * 0.01, g.cookiesPs * 60) * rnd(); if v != 0 { g.earn(v); say("(Crumbspore)<br>+\(B(v)) cookies!") } }
        if p.key == "doughshroom" { let v = min(g.cookies * 0.03, g.cookiesPs * 300) * rnd(); if v != 0 { g.earn(v); say("(Doughshroom)<br>+\(B(v)) cookies!") } }
    }
    func onKill(_ p: Plant, _ x: Int, _ y: Int, _ age: Double) {
        if p.key == "meddleweed" && rnd() < 0.2 * (age / 100), let n = plantsBN[choose(["brownMold", "crumbspore"])] { plot[y][x] = (n.id + 1, 0) }
    }

    @discardableResult
    func harvest(_ x: Int, _ y: Int, manual: Bool = false) -> Bool {
        let t = plot[y][x]
        guard let me = plant(t) else { return false }
        let age = t.1
        onHarvest(me, age)
        if age >= me.mature {
            if unlockSeed(me) { say("(\(me.name))<br>Unlocked \(me.name) seed.") }
            harvests += 1; harvestsTotal += 1
            if harvestsTotal >= 100 { Game.shared.win("Botany enthusiast") }
            if harvestsTotal >= 1000 { Game.shared.win("Green, aching thumb") }
        }
        plot[y][x] = (0, 0)
        onKill(me, x, y, age)
        computeEffs()
        return true
    }
    func harvestAll(matureOnly: Bool = false, mortalOnly: Bool = false) {
        var n = 0
        for _ in 0..<2 { for y in 0..<6 { for x in 0..<6 {
            guard let me = plant(plot[y][x]) else { continue }
            if mortalOnly && me.immortal { continue }
            if matureOnly && plot[y][x].1 < me.mature { continue }
            if harvest(x, y) { n += 1 }
        } } }
        if n > 0 { Sound.play("snd/harvest1.mp3", 1) }
        if n > 2 { DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { Sound.play("snd/harvest2.mp3", 1) } }
        if n > 6 { DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { Sound.play("snd/harvest3.mp3", 1) } }
    }

    /// tap on a tile: harvest what's there, or plant the selected seed
    func clickTile(_ x: Int, _ y: Int) {
        guard isTileUnlocked(x, y) else { return }
        if harvest(x, y, manual: true) {
            Sound.play("snd/harvest\(Int.random(in: 1...3)).mp3", 1)
            return
        }
        guard seedSelected >= 0, let p = plants[safe: seedSelected], p.plantable, p.unlocked > 0 else { return }
        let c = cost(p)
        guard Game.shared.cookies >= c else { Sound.play("snd/clickOff2.mp3", 0.5); return }
        plot[y][x] = (p.id + 1, 0)
        Game.shared.spend(c)
        Sound.play("snd/tillb\(Int.random(in: 1...3)).mp3", 1)
        computeEffs()
        checkEden()
    }
    func checkEden() {
        guard building.level >= 9 else { return }
        for y in 0..<6 { for x in 0..<6 { if plot[y][x].0 == 0 { return } } }
        Game.shared.win("In the garden of Eden (baby)")
    }

    func setSoil(_ i: Int) {
        guard i != soil, freeze == 0 else { return }
        let s = Garden.soils[i]
        if now() < nextSoil || building.amount < s.req { Sound.play("snd/clickOff2.mp3", 0.5); return }
        soil = i
        nextSoil = now() + (Game.shared.Has("Turbo-charged soil") ? 1 : 600_000)
        computeStepT()
        computeEffs()
        Sound.play("snd/toneTick.mp3")
    }
    func toggleFreeze() {
        Sound.play("snd/toneTick.mp3")
        freeze = freeze == 0 ? 1 : 0
        if freeze == 1 {
            Sound.play("snd/freezeGarden.mp3")
            for y in 0..<6 { for x in 0..<6 {
                if let me = plant(plot[y][x]), me.key == "cheapcap" && rnd() < 0.15 {
                    let age = plot[y][x].1
                    plot[y][x] = (0, 0)
                    onKill(me, x, y, age)
                }
            } }
        }
        computeEffs()
    }
    func convert() {
        guard unlockedN >= plants.count else { return }
        harvestAll()
        for p in plants { p.unlocked = 0 }
        plantsBN["bakerWheat"]?.unlocked = 1
        Lumps.gain(Game.shared, 10)
        Game.shared.toast("Sacrifice!", "You've sacrificed your garden to the sugar hornets, destroying your crops and your knowledge of seeds.<br>In the remains, you find <b>10 sugar lumps</b>.", [29, 14])
        seedSelected = -1
        Game.shared.win("Seedless to nay")
        convertTimes += 1
        computeMatures()
        Sound.play("snd/spellFail.mp3", 0.75)
    }

    func refill(_ g: Game) {
        LumpRefill.refill(g, 1) {
            self.loopsMult = 3
            self.nextStep = now()
            Sound.play("snd/pop\(Int.random(in: 1...3)).mp3", 0.75)
        }
    }

    // MARK: growth, once per tick (every few minutes)
    func logic(_ g: Game) {
        let t = now()
        guard freeze == 0 else { return }
        nextStep = min(nextStep, t + stepT * 1000)
        guard t >= nextStep else { return }
        computeStepT()
        nextStep = t + stepT * 1000
        computeBoostPlot()
        computeMatures()
        let weedMult = Garden.soils[soil].weedMult
        let dragonBoost = 1 + 0.05 * g.auraMult("Supreme Intellect")
        var loops = Garden.soils[soil].key == "woodchips" ? 3.0 : 1
        loops = randomFloor(loops * dragonBoost)
        loops *= Double(loopsMult)
        loopsMult = 1
        let contamList = plants.filter { $0.contam > 0 }
        for y in 0..<6 { for x in 0..<6 {
            guard isTileUnlocked(x, y) else { continue }
            if let me = plant(plot[y][x]) {
                var age = plot[y][x].1
                age += randomFloor((me.ageTick + me.ageTickR * rnd()) * plotBoost[y][x][0] * dragonBoost)
                age = max(age, 0)
                plot[y][x].1 = age
                if me.immortal { plot[y][x].1 = min(me.mature + 1, age) }
                else if age >= 100 {
                    plot[y][x] = (0, 0)
                    onDie(me)
                    if Garden.soils[soil].key == "pebbles" && rnd() < 0.35 { if unlockSeed(me) { say("Unlocked \(me.name) seed.") } }
                } else if !me.noContam {
                    var list: [Plant] = []
                    for c in contamList where rnd() < c.contam && (!c.weed || rnd() < weedMult) { list.append(c) }
                    if let c = list.randomElement(), c.key != me.key {
                        if (!c.weed && !c.fungus) || rnd() < plotBoost[y][x][2] {
                            let nb = neighbors(x, y, diagonal: false)
                            if (nb.1[c.key] ?? 0) >= 1 { plot[y][x] = (c.id + 1, 0) }
                        }
                    }
                }
            } else {
                for loop in 0..<Int(loops) {
                    let nb = neighbors(x, y, diagonal: true)
                    if nb.2 > 0 {
                        var list: [String] = []
                        for (k, chance) in muts(nb.0, nb.1) {
                            guard let p = plantsBN[k] else { continue }
                            if rnd() < chance && (!p.weed || rnd() < weedMult) && ((!p.weed && !p.fungus) || rnd() < plotBoost[y][x][2]) { list.append(k) }
                        }
                        if let k = list.randomElement(), let p = plantsBN[k] { plot[y][x] = (p.id + 1, 0) }
                    } else if loop == 0 {
                        let chance = 0.002 * weedMult * plotBoost[y][x][2]
                        if rnd() < chance, let w = plantsBN["meddleweed"] { plot[y][x] = (w.id + 1, 0) }
                    }
                }
            }
        } }
        computeEffs()
    }

    func onLevel(_ level: Int) {}

    func reset(hard: Bool) {
        soil = 0; seedSelected = -1
        nextStep = now(); nextSoil = now(); nextFreeze = now()
        plot = Array(repeating: Array(repeating: (0, 0), count: 6), count: 6)
        harvests = 0
        if hard { convertTimes = 0; harvestsTotal = 0; for p in plants { p.unlocked = 0 } }
        plantsBN["bakerWheat"]?.unlocked = 1
        loopsMult = 1
        computeStepT(); computeMatures(); computeBoostPlot(); computeEffs()
    }

    func save() -> String {
        var s = "\(Fmt.jsNumber(nextStep)):\(soil):\(Fmt.jsNumber(nextSoil)):\(freeze):\(harvests):\(harvestsTotal):0:\(Fmt.jsNumber(convertTimes)):\(Fmt.jsNumber(nextFreeze)): "
        for p in plants { s += p.unlocked > 0 ? "1" : "0" }
        s += " "
        for y in 0..<6 { for x in 0..<6 { s += "\(plot[y][x].0):\(Int(plot[y][x].1)):" } }
        return s
    }
    func load(_ str: String) {
        let spl = str.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        let a = (spl[safe: 0] ?? "").split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        nextStep = Double(a[safe: 0] ?? "") ?? nextStep
        soil = min(Garden.soils.count - 1, max(0, Int(a[safe: 1] ?? "") ?? soil))
        nextSoil = Double(a[safe: 2] ?? "") ?? nextSoil
        freeze = (Int(a[safe: 3] ?? "") ?? 0) != 0 ? 1 : 0
        harvests = Int(a[safe: 4] ?? "") ?? 0
        harvestsTotal = Int(a[safe: 5] ?? "") ?? 0
        convertTimes = Double(a[safe: 7] ?? "") ?? convertTimes
        nextFreeze = Double(a[safe: 8] ?? "") ?? nextFreeze
        if let seeds = spl[safe: 1], !seeds.isEmpty {
            for (i, c) in seeds.enumerated() where i < plants.count { plants[i].unlocked = c == "1" ? 1 : 0 }
        }
        plantsBN["bakerWheat"]?.unlocked = 1
        if let p = spl[safe: 2], !p.isEmpty {
            let v = p.split(separator: ":").map { Double($0) ?? 0 }
            var n = 0
            for y in 0..<6 { for x in 0..<6 {
                if n + 1 < v.count { plot[y][x] = (Int(v[n]), v[n + 1]) }
                n += 2
            } }
        }
        computeStepT(); computeMatures(); computeBoostPlot(); computeEffs()
    }
}

func randomFloor(_ x: Double) -> Double { x.truncatingRemainder(dividingBy: 1) < rnd() ? x.rounded(.down) : x.rounded(.up) }
