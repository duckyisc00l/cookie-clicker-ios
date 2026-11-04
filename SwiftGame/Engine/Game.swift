import Foundation
import Combine

final class Building {
    let def: BuildingDef
    var id: Int { def.id }
    var amount = 0, amountMax = 0, bought = 0, free = 0
    var storedCps = 0.0, cookiesMade = 0.0
    var locked = 2          // 0 shown, 1 mysterious, 2 hidden
    var level = 0
    var minigameSave = ""
    init(_ d: BuildingDef) { def = d }
    func reset() { amount = 0; amountMax = 0; bought = 0; free = 0; storedCps = 0; cookiesMade = 0 }
}

final class Upgrade {
    let def: UpgradeDef
    var id: Int { def.id }
    var name: String { def.name }
    var pool: String { def.pool }
    var unlocked = 0, owned = 0
    var ping = false
    init(_ d: UpgradeDef) { def = d }
}

final class Achiev {
    let def: AchievDef
    var id: Int { def.id }
    var name: String { def.name }
    var owned = 0
    init(_ d: AchievDef) { def = d }
}

struct Toast: Identifiable {
    let id = UUID()
    let title: String
    let text: String
    let icon: [Int]?
    let created = Date()
}

/// The whole game state and rules. A Swift port of the mobile game's engine ("G").
final class Game: ObservableObject {
    static let shared = Game()
    static let fps = 30.0
    static let version = 1.0
    let data: GameData

    // content
    var buildings: [Building] = []
    var buildingsBN: [String: Building] = [:]
    var upgrades: [Upgrade] = []
    var upgradesBN: [String: Upgrade] = [:]
    var upgradesBID: [Int: Upgrade] = [:]
    var achievs: [Achiev] = []
    var achievsBN: [String: Achiev] = [:]
    var achievsBID: [Int: Achiev] = [:]
    var upgradePools: [String: [Upgrade]] = [:]
    var tierUpgrades: [String: [Upgrade]] = [:]

    // saved stats (same names as the original save)
    var lastVersion = 1.0, runStart = 0.0, gameStart = 0.0, seed = "aaaaa"
    var cookies = 0.0, cookiesEarned = 0.0, cookiesTotal = 0.0, cookiesHandmade = 0.0
    var cookieClicks = 0.0, gcClicks = 0.0, gcClicksTotal = 0.0, gcMissed = 0.0
    var reindeerClicks = 0.0, reindeerClicksTotal = 0.0, reindeerMissed = 0.0
    var elderWrath = 0, pledges = 0.0, pledgeT = 0.0, wrinklersPopped = 0.0, cookiesSucked = 0.0
    var cookiesReset = 0.0, heavenlyChips = 0.0, heavenlyChipsSpent = 0.0, resets = 0.0
    var seasonT = 0.0, seasonUses = 0.0, season = "", santaLevel = 0, dragonLevel = 0, dragonAura = 0, dragonAura2 = 0
    var fortuneGC = 0, fortuneCPS = 0, powerClicks = 0.0, powerClicksTotal = 0.0
    var bgType = 0, milkType = 0, chimeType = 0, quickButtons: [Any] = [], tippedN = 0
    var lumps = 0.0, lumpsTotal = 0.0, lumpT = 0.0, lumpCurrentType = 0, lumpRefill = 0.0
    var researchT = 0.0, researchTM = 0.0, researchUpgrade: Upgrade? = nil, researchUpgradeLast: Upgrade? = nil
    var permanentUpgrades = [-1, -1, -1, -1, -1]

    // computed / runtime
    var pool: [String: Double] = [:]
    var cookiesPs = 0.0, cookiesPsUnbuffed = 0.0, cookiesPc = 1.0, cpsSucked = 0.0
    var prestige = 0.0, gainedPrestige = 0.0
    var upgradesN = 0, achievsN = 0, buildingsN = 0, buildingsNmin = 0
    var recentUpgrades: [Upgrade] = [], recentAchievs: [Achiev] = []
    var refreshCps = true
    var T = 0
    var powerClicksOn = false
    var onAscend = 0
    var lastResetTimestamp = 0.0
    var bulkBuy = 1, bulkMode = 1
    var cookiesD = 0.0
    var buffs: [Buff] = []
    var buffTypesBN: [String: BuffTypeDef] = [:]
    var shimmers: [Shimmer] = []
    var shimmerTypes: [ShimmerType] = []
    var playW = 390.0, playH = 700.0      // size of the cookie screen, for placing golden cookies
    var explodeT = -1.0

    @Published var toasts: [Toast] = []
    @Published var frame = 0                 // bumps every draw so SwiftUI refreshes
    var pings: Set<String> = []

    var settings = Settings()
    var onSave: (([String: Any]) -> Void)? = nil

    init() {
        data = GameData.load()
        for d in data.buildings { let b = Building(d); buildings.append(b); buildingsBN[d.name] = b }
        for d in data.upgrades {
            let u = Upgrade(d); upgrades.append(u); upgradesBN[d.name] = u; upgradesBID[d.id] = u
            if let t = d.tier { tierUpgrades[t, default: []].append(u) }
        }
        for d in data.achievs { let a = Achiev(d); achievs.append(a); achievsBN[d.name] = a; achievsBID[d.id] = a }
        for (k, ids) in data.pools { upgradePools[k] = ids.compactMap { upgradesBID[$0] } }
        for b in data.buffTypes { buffTypesBN[b.name] = b }
        for b in MinigameBuffs.types { buffTypesBN[b.name] = b }
        shimmerTypes = [ShimmerType.golden(), ShimmerType.reindeer()]
        resetPools()
        Extras.setup(self)
    }

    // MARK: lookups
    func Has(_ name: String) -> Bool { upgradesBN[name]?.owned ?? 0 > 0 }
    func HasUnlocked(_ name: String) -> Bool { upgradesBN[name]?.unlocked ?? 0 > 0 }
    func HasAchiev(_ name: String) -> Bool { achievsBN[name]?.owned ?? 0 > 0 }
    func buildingN(_ name: String) -> Int { buildingsBN[name]?.amount ?? 0 }
    func p(_ key: String) -> Double { pool[key] ?? 0 }

    // MARK: earning
    func earn(_ n: Double) { cookies += n; cookiesEarned += n; cookiesTotal += n }
    func spend(_ n: Double) { cookies = max(0, cookies - n) }
    func dissolve(_ n: Double) { cookies = max(0, cookies - n); cookiesEarned = max(0, cookiesEarned - n) }

    // MARK: toasts
    func toast(_ title: String, _ text: String, _ icon: [Int]? = nil, _ reverse: Bool = false) {
        DispatchQueue.main.async {
            self.toasts.append(Toast(title: title, text: text, icon: icon))
            if self.toasts.count > 6 { self.toasts.removeFirst(self.toasts.count - 6) }
        }
    }

    // MARK: achievements
    func win(_ name: String) {
        guard let a = achievsBN[name], a.owned == 0 else { return }
        a.owned = 1
        if a.def.pool != "shadow" { achievsN += 1 }
        recentAchievs.insert(a, at: 0); if recentAchievs.count > 5 { recentAchievs.removeLast() }
        toast(a.name, "Achievement unlocked", a.def.icon)
        refreshCps = true
        Sound.play("snd/tick.mp3")
    }
    func unlock(_ name: String) { if let u = upgradesBN[name] { unlockUpgrade(u) } }
    func unlockUpgrade(_ u: Upgrade) {
        if u.pool == "prestige" || u.unlocked > 0 { return }
        u.unlocked = 1
        if u.pool != "toggle" && u.pool != "science" { pings.insert("store") }
        u.ping = true
    }

    // MARK: upgrades
    func upgradeCost(_ u: Upgrade) -> Double {
        var cost = u.def.cost
        if let k = u.def.costKind { cost = specialCost(u, k) }
        if u.pool == "toggle" || u.pool == "prestige" { return cost }
        return (modifyUpgradeCost(u, cost)).rounded(.up)
    }
    func modifyUpgradeCost(_ u: Upgrade, _ c: Double) -> Double {
        var cost = (c + p("upgradeCostA")) * p("upgradeCostM")
        if u.pool == "cookie" && Has("Divine bakeries") { cost /= 5 }
        if u.pool == "kitten" && Has("Kitten wages") { cost *= 0.9 }
        return cost
    }
    @discardableResult
    func buyUpgrade(_ u: Upgrade) -> Bool {
        if u.pool == "prestige" {
            if u.owned > 0 { return false }
            for parent in data.heavenlyParents[u.id] ?? [] { if upgradesBID[parent]?.owned ?? 0 == 0 { return false } }
            let cost = upgradeCost(u)
            if heavenlyChips < cost { return false }
            heavenlyChips -= cost; heavenlyChipsSpent += cost
            Sound.play("snd/buy\(Int.random(in: 1...4)).mp3", 0.75)
            Sound.play("snd/shimmerClick.mp3", 0.5)
            u.owned = 1
            return true
        }
        if u.owned > 0 || (u.pool != "toggle" && u.unlocked == 0) { return false }
        let cost = upgradeCost(u)
        guard cookies >= cost else { return false }
        spend(cost)
        u.owned = 1
        refreshCps = true
        if u.pool != "toggle" && u.pool != "prestige" {
            upgradesN += 1
            recentUpgrades.insert(u, at: 0); if recentUpgrades.count > 5 { recentUpgrades.removeLast() }
        }
        upgradeBought(u, forced: false)
        return true
    }
    func forceBuyUpgrade(_ u: Upgrade) {
        if u.owned > 0 { return }
        u.owned = 1; u.unlocked = 1
        if u.pool != "toggle" && u.pool != "prestige" {
            upgradesN += 1
            recentUpgrades.insert(u, at: 0); if recentUpgrades.count > 5 { recentUpgrades.removeLast() }
        }
        upgradeBought(u, forced: true)
        refreshCps = true
    }
    func loseUpgrade(_ u: Upgrade) {
        if u.owned > 0 && u.pool != "toggle" && u.pool != "prestige" { upgradesN -= 1 }
        u.owned = 0; u.unlocked = 0; refreshCps = true
    }
    func toggleOff(_ name: String) { upgradesBN[name]?.unlocked = 0 }
    func toggleOn(_ name: String) { if let u = upgradesBN[name] { loseUpgrade(u); u.unlocked = 1 } }

    // MARK: buildings
    func modifyBuildingCost(_ b: Building, _ c: Double) -> Double {
        (c + p("buildingCostA") + p("buildingCost\(b.id)A")) * p("buildingCostM") * p("buildingCost\(b.id)M")
    }
    func cost(_ b: Building) -> Double {
        let c = b.def.baseCost * pow(1.15, Double(max(0, b.amount - b.free)))
        return modifyBuildingCost(b, c).rounded(.up)
    }
    func sumCost(_ b: Building, _ amount: Int) -> Double {
        var c = 0.0
        for i in max(0, b.amount)..<max(0, b.amount + amount) {
            let add = b.def.baseCost * pow(1.15, Double(max(0, i - b.free)))
            if amount == 10000 && modifyBuildingCost(b, c + add) > cookies { break }
            c += add
        }
        c = modifyBuildingCost(b, c)
        if amount == 10000 { return min(c, cookies) }
        return c.rounded(.up)
    }
    func buyMax(_ b: Building) -> Int {
        var c = 0.0, n = 0
        for i in max(0, b.amount)..<max(0, b.amount + 1000) {
            let add = b.def.baseCost * pow(1.15, Double(max(0, i - b.free)))
            if modifyBuildingCost(b, c + add) > cookies { break }
            c += add; n += 1
        }
        return n
    }
    func reverseSumCost(_ b: Building, _ amount: Int) -> Double {
        var c = 0.0
        for i in max(0, b.amount - amount)..<max(0, b.amount) {
            c += b.def.baseCost * pow(1.15, Double(max(0, i - b.free)))
        }
        return (modifyBuildingCost(b, c) * sellMultiplier()).rounded(.up)
    }
    func sellMultiplier() -> Double { 0.25 * (1 + auraMult("Earth Shatterer")) }

    func buy(_ b: Building, _ amountIn: Int? = nil) {
        if bulkMode == -1 { sell(b, bulkBuy); return }
        var amount = amountIn ?? bulkBuy
        if amount == -1 || amount == 10000 { amount = 1000 }
        var success = false
        for _ in 0..<min(amount, 1000) {
            let c = cost(b)
            if cookies >= c { spend(c); b.amount += 1; b.bought += 1; refreshCps = true; success = true } else { break }
        }
        b.amountMax = max(b.amount, b.amountMax)
        if success { Sound.play("snd/buy\(Int.random(in: 1...4)).mp3", 0.65); computeBuildingAmounts(); Minigames.shared.onBuy(b) }
    }
    func forceBuy(_ b: Building, _ amount: Int = 1) {
        for _ in 0..<min(max(1, amount), 1000) { b.amount += 1; b.bought += 1 }
        refreshCps = true
        b.amountMax = max(b.amount, b.amountMax)
        computeBuildingAmounts()
    }
    func sell(_ b: Building, _ amountIn: Int) {
        var amount = amountIn
        if amount == -1 || amount == 10000 { amount = b.amount }
        var success = false
        for _ in 0..<max(0, amount) {
            guard b.amount > 0 else { break }
            let c = (cost(b) * sellMultiplier()).rounded(.down)
            cookies += c
            cookiesEarned = max(cookies, cookiesEarned)
            b.amount -= 1
            refreshCps = true; success = true
        }
        if success, shimmerTypes[0].n <= 0, auraMult("Dragon Orbs") > 0 {
            let highest = buildings.last(where: { $0.amount > 0 })
            if highest === b && rnd() < auraMult("Dragon Orbs") * 0.1 && buffs.isEmpty {
                _ = spawnShimmer(0)
                toast("<b>Dragon Orbs!</b>", "Wish granted. Golden cookie spawned.", [33, 25], true)
            }
        }
        if success { Sound.play("snd/sell\(Int.random(in: 1...4)).mp3", 0.75); computeBuildingAmounts(); Minigames.shared.onSell(b) }
    }
    func forceSell(_ b: Building, _ amount: Int = 1) {
        for _ in 0..<max(1, amount) where b.amount > 0 { b.amount -= 1 }
        refreshCps = true
        computeBuildingAmounts()
    }
    func computeBuildingAmounts() {
        buildingsN = 0; buildingsNmin = 100000
        for b in buildings { buildingsN += b.amount; buildingsNmin = min(buildingsNmin, b.amount) }
    }
    func buildingName(_ b: Building, _ n: Int = 1) -> String {
        if season == "fools" { return n == 1 ? b.def.foolName : b.def.foolPlural }
        return n == 1 ? b.def.name : b.def.plural
    }
    func buildingDesc(_ b: Building) -> String { season == "fools" ? b.def.foolDesc : b.def.desc }

    // MARK: pools and CpS
    func resetPools() {
        var p: [String: Double] = [:]
        p["cpsA"] = 0; p["cpsM"] = 1; p["cpsBuffA"] = 0; p["cpsBuffM"] = 1
        p["clickA"] = 1; p["clickM"] = 1
        for k in ["gcFreq", "gcLife", "gcWrathLife", "gcEffectsLife", "gcWrathEffectsLife", "gcEffectsMult", "gcWrathEffectsMult",
                  "buildingCost", "upgradeCost", "reindeerLife", "reindeerFreq", "reindeerEffectsMult", "dropChance", "milkPower"] {
            p[k + "A"] = 0; p[k + "M"] = 1
        }
        p["pseudoKitten"] = 1
        p["pcMultA"] = 2; p["pcRateA"] = 30; p["pcCapA"] = 5; p["pcBuffMultA"] = 1.05; p["pcBuffDurA"] = 10
        for i in 0..<buildings.count {
            p["building\(i)A"] = 0; p["building\(i)M"] = 1
            p["buildingCost\(i)A"] = 0; p["buildingCost\(i)M"] = 1
            p["building\(i)Free"] = 0
        }
        pool = p
    }

    func applyEff(_ e: Eff, _ u: Upgrade?) {
        let k = e.pool
        let v = pool[k] ?? 0
        switch e {
        case .num(_, let n, let mult):
            pool[k] = mult ? v * n : v + n
        case .tier(_, let b, let tu):
            if b == 0 { pool[k] = v * 2; return }
            let bu = data.buildings[b].unshackle.flatMap { upgradesBID[$0] }
            let tierU = tu.flatMap { upgradesBID[$0] }
            if let bu = bu, bu.owned > 0, let tierU = tierU, tierU.owned > 0 { pool[k] = v * (2 + bu.def.power) }
            else { pool[k] = v * 2 }
        case .syn(_, let other, let rate):
            pool[k] = v * (1 + rate * Double(buildings[other].amount))
        case .gma(_, let b):
            pool[k] = v * (1 + 0.01 * Double(buildings[1].amount) * (1 / Double(b - 1)))
        case .special(_, let name):
            pool[k] = specialEff(name, k, v)
        }
    }
    func applyBuffEffs(_ list: [(String, Double, Int)]) {
        for (k, n, m) in list {
            let v = pool[k] ?? 0
            pool[k] = m == 1 ? v * n : v + n
        }
    }

    func computeCps() {
        resetPools()
        for u in upgrades where u.owned > 0 { for e in u.def.effs { applyEff(e, u) } }
        for b in buffs { applyBuffEffs(buffEffs(b)) }
        Minigames.shared.applyEffects(self)

        pool["clickM"]! *= 1 + auraMult("Dragon Cursor") * 0.05
        pool["milkPowerM"]! *= 1 + auraMult("Breath of Milk") * 0.05
        pool["cpsM"]! *= 1 + auraMult("Radiant Appetite")
        let n = shimmerTypes[0].n
        let fortune = auraMult("Dragon's Fortune")
        for _ in 0..<max(0, n) { pool["cpsM"]! *= 1 + fortune * 1.23 }
        pool["dropChanceM"]! *= 1 + auraMult("Mind Over Matter") * 0.25
        pool["gcEffectsLifeM"]! *= 1 + auraMult("Epoch Manipulator") * 0.05
        pool["gcWrathEffectsLifeM"]! *= 1 + auraMult("Epoch Manipulator") * 0.05
        pool["gcEffectsMultM"]! *= 1 + auraMult("Unholy Dominion") * 0.1
        pool["gcWrathEffectsMultM"]! *= 1 + auraMult("Ancestral Metamorphosis") * 0.1
        pool["gcFreqM"]! *= 1 + auraMult("Arcane Aura") * 0.05
        pool["buildingCostM"]! *= 1 - auraMult("Fierce Hoarder") * 0.02
        pool["upgradeCostM"]! *= 1 - auraMult("Master of the Armory") * 0.02
        var num = 0
        for (i, b) in buildings.enumerated() where i != 1 { num += b.amount }
        pool["building1M"]! *= 1 + auraMult("Elder Battalion") * 0.01 * Double(num)

        let prestigeMult = 1 + 0.01 * prestige * heavenlyMultiplier()
        let cursed = hasBuff("cursedFinger")
        let milk = Double(achievsN) / 25
        let milkPower = (1 + p("milkPowerA")) * p("milkPowerM")
        for u in upgradePools["kitten"] ?? [] where u.owned > 0 {
            pool["cpsM"]! *= 1 + u.def.power * milk * milkPower
        }
        for u in upgradePools["pseudoKitten"] ?? [] where u.owned > 0 {
            for e in u.def.effs { if case .num("pseudoKitten", let v, _) = e { pool["cpsM"]! *= 1 + (v - 1) * milk * milkPower } }
        }

        var cps = 0.0
        for b in buildings {
            var my = baseCps(b)
            my = (my + p("building\(b.id)A")) * p("building\(b.id)M") * (1 + Double(b.level) * 0.01)
            b.storedCps = my * (cursed != nil ? 0 : 1) * p("cpsM") * p("cpsBuffM") * prestigeMult
            cps += my * Double(b.amount)
        }
        var sucking = 0
        for w in Wrinklers.shared.list where w.phase == 2 { sucking += 1 }
        var suckRate = 1.0 / 20
        suckRate *= 1 + auraMult("Dragon Guts") * 0.2
        cpsSucked = Double(sucking) * suckRate

        cps = cps * p("cpsM") + p("cpsA")
        cps *= prestigeMult
        cookiesPsUnbuffed = cps
        cps = (cps + p("cpsBuffA")) * p("cpsBuffM")
        let oldCps = cps
        if cursed != nil { cps = 0 }
        cookiesPs = cps

        var cpc = 0.0
        if let c = cursed { cpc = oldCps * c.tm }
        else {
            var fromCps = 0.0
            for u in upgradePools["mouse"] ?? [] where u.owned > 0 { fromCps += cookiesPs * 0.01 }
            if Has("Fortune #104") { fromCps += cookiesPs * 0.01 }
            cpc = (p("clickA") + fromCps) * p("clickM")
        }
        cookiesPc = cpc
        Lumps.checkAchievs(self)
    }

    /// the building's base CpS: the same numbers the original game computed for each building
    func baseCps(_ b: Building) -> Double { b.def.baseCps }

    func heavenlyMultiplier() -> Double {
        var m = 0.0
        if Has("Heavenly chip secret") { m += 0.05 }
        if Has("Heavenly cookie stand") { m += 0.20 }
        if Has("Heavenly bakery") { m += 0.25 }
        if Has("Heavenly confectionery") { m += 0.25 }
        if Has("Heavenly key") { m += 0.25 }
        m *= 1 + auraMult("Dragon God") * 0.05
        return m
    }
    static let HCfactor = 3.0
    func howMuchPrestige(_ c: Double) -> Double { pow(c / 1e12, 1 / Game.HCfactor) }
    func howManyCookiesReset(_ chips: Double) -> Double { pow(chips, Game.HCfactor) * 1e12 }
    func dropRateMult() -> Double { (1 + p("dropChanceA")) * p("dropChanceM") }

    // MARK: clicking the big cookie
    func clickCookie() -> (Double, Double) {
        var mult = 1.0
        if powerClicksOn && powerClicks >= 1 { mult *= usePowerClick() }
        let n = cookiesPc * mult
        earn(n)
        cookiesHandmade += n
        cookieClicks += 1
        cookiesD = cookies
        return (n, mult)
    }

    // MARK: unlocks
    private var unlockI = 0
    func checkCond(_ c: Cond, _ name: String) -> Bool {
        if cookiesEarned < c.cookies { return false }
        if cookiesPsUnbuffed < c.cps { return false }
        if Double(achievsN) / 25 < c.milk { return false }
        for (b, n) in c.buildings where n != -1 { if buildings[b].amount < n { return false } }
        for u in c.upgrades { if upgradesBID[u]?.owned ?? 0 == 0 { return false } }
        for a in c.achievs { if achievsBID[a]?.owned ?? 0 == 0 { return false } }
        if let s = c.spe, !specialCond(s, name) { return false }
        return true
    }
    func doUnlocks(every: Int = 1) {
        let total = upgrades.count + achievs.count
        unlockI = unlockI % every
        let initial = every == 1 ? 0 : unlockI
        if every > 1 { unlockI += 1 }
        var i = initial
        while i < total {
            if i < upgrades.count {
                let u = upgrades[i]
                if u.unlocked == 0 && u.owned == 0, let c = u.def.unlock, checkCond(c, u.name) { unlockUpgrade(u) }
            } else {
                let a = achievs[i - upgrades.count]
                if a.owned == 0, let c = a.def.unlock, checkCond(c, a.name) { win(a.name) }
            }
            i += every
        }
    }

    // MARK: main loop (30 times a second)
    func logic(_ deltaIn: Double) {
        let delta = max(0, deltaIn)
        if onAscend > 0 { return }
        Ticker.shared.logic(self, delta)
        let oldCookies = cookies
        var breakpoints: [Double] = []
        for b in buffs where b.t * Game.fps - delta <= 0 { breakpoints.append(b.t * Game.fps) }
        if !breakpoints.isEmpty {
            breakpoints.append(delta)
            breakpoints.sort()
            for (i, bp) in breakpoints.enumerated() {
                var step = bp
                if i > 0 { step -= breakpoints[i - 1] }
                if refreshCps { computeCps(); refreshCps = false }
                earn((cookiesPs / Game.fps) * step)
                logicBuffs(step)
            }
        } else {
            if T % Int(Game.fps * 10) == 0 || refreshCps { computeCps(); refreshCps = false }
            earn((cookiesPs / Game.fps) * delta)
            logicBuffs(delta)
        }
        if T % Int(Game.fps) == 0 {
            if rnd() < 1.0 / 1_000_000 { win("Just plain lucky") }
            if cookiesEarned >= 1e14 && !HasAchiev("You win a cookie") { win("You win a cookie"); earn(1) }
        }
        Seasons.logic(self, delta)
        Wrinklers.shared.logic(self, delta)
        // grandmapocalypse
        if buildingN("Grandma") == 0 || Has("Elder Covenant") || pledgeT > now() {
            if elderWrath > 0 { Wrinklers.shared.collect(self) }
            elderWrath = 0
        } else if elderWrath == 0 && Has("One mind") { elderWrath = 1 }
        else if rnd() < 0.001 && elderWrath < (Has("One mind") ? 1 : 0) + (Has("Communal brainsweep") ? 1 : 0) + (Has("Elder Pact") ? 1 : 0) { elderWrath += 1 }

        if T % Int(Game.fps) == 0 { doUnlocks(every: 6) }

        var lastLocked = 0
        for b in buildings {
            b.cookiesMade += (b.storedCps / Game.fps) * delta * Double(b.amount)
            if lastLocked >= 2 { b.locked = 2 }
            else if cookiesEarned >= b.def.baseCost || b.bought > 0 { b.locked = 0; lastLocked = 0 }
            else { b.locked = 1; lastLocked += 1 }
        }
        cookiesD += (cookies - cookiesD) * 0.2
        if abs(cookies - cookiesD) < 0.01 { cookiesD = cookies }

        if delta / Game.fps >= 30 {
            let dif = cookies - oldCookies
            if dif >= 1 {
                toast("Welcome back!", "You were away for \(sayTime(delta / Game.fps * 1000)), and made <b>\(B(dif))</b> cookie\(B(dif) == "1" ? "" : "s").", [10, 0], true)
            }
            earnPowerClicks(delta / Game.fps)
        }
        Research.logic(self)
        logicShimmers(delta)
        Lumps.logic(self)
        Minigames.shared.logic(self, delta)
        if T % Int(Game.fps * 5) == 0 && (now() - lastResetTimestamp) >= 8000 { save() }
        T += 1
    }

    // MARK: power clicks
    func angels() -> Int { ["Angels", "Archangels", "Virtues", "Dominions", "Cherubim", "Seraphim", "God"].filter { Has($0) }.count }
    func demons() -> Int { ["Belphegor", "Mammon", "Abaddon", "Satan", "Asmodeus", "Beelzebub", "Lucifer"].filter { Has($0) }.count }
    var lastPowerClickAttempt = 0.0
    func usePowerClick() -> Double {
        var mult = 1.0
        let blocked = hasBuff("clickFrenzy") != nil
        if powerClicks < 1 {}
        else if blocked {
            if now() - lastPowerClickAttempt > 5000 { Sound.play("snd/bomp.mp3") }
        } else {
            powerClicks -= 1
            powerClicksTotal += 1
            let d = Double(demons())
            mult *= (p("pcMultA") + d) * (1 + auraMult("Dragon Cursor") * 0.05)
            let pw = (p("pcBuffMultA") + 0.01 * d) * (1 + auraMult("Dragon Cursor") * 0.05)
            addBuff("powerClick", t: p("pcBuffDurA") + 5 * d, pow: pw)
            Sound.play("snd/powerClick\(Int.random(in: 1...3))b.mp3", 0.4 - rnd() * 0.3)
        }
        lastPowerClickAttempt = now()
        return mult
    }
    func powerClickCapacity() -> Double {
        if !Has("Power clicks") { return 0 }
        return (p("pcCapA") + Double(angels()) * 5 + auraMult("Dragon Cursor") * 5).rounded(.up)
    }
    func powerClicksPs() -> Double {
        if !Has("Power clicks") { return 0 }
        return 1.0 / max(1, p("pcRateA") - Double(angels()) * 2) / 60
    }
    func earnPowerClicks(_ seconds: Double) {
        let old = powerClicks
        powerClicks += powerClicksPs() * seconds
        powerClicks = max(old, max(0, min(powerClicks, powerClickCapacity())))
    }
}
