import Foundation

// The game's object types: buildings, upgrades, achievements, tiers, effects, unlock requirements.
// Port of www/main.js "BUILDINGS", "TIERS", "UPGRADES", "ACHIEVEMENTS" sections (G.Building, G.Upgrade, G.Achiev, G.unlockAt).

/// An effect on a pool: [pool, amount, mode] in the original.
/// mode 0 adds, mode 1 multiplies, mode 2 applies a function.
struct Eff {
    enum Op { case add(Double), mul(Double), fn((Double) -> Double) }
    let pool: String
    let op: Op
    init(_ pool: String, _ v: Double, _ mode: Int = 0) { self.pool = pool; self.op = mode == 1 ? .mul(v) : .add(v) }
    init(_ pool: String, _ f: @escaping (Double) -> Double) { self.pool = pool; self.op = .fn(f) }
    /// eff[1] when it is a number (the original reads eff[1] directly for pseudoKitten)
    var value: Double { switch op { case .add(let v), .mul(let v): return v; case .fn: return 0 } }
    func apply(_ v: Double) -> Double {
        switch op { case .add(let n): return v + n; case .mul(let n): return v * n; case .fn(let f): return f(v) }
    }
}

final class Tier {
    let key: String          // "1".."15", "synergy1", "synergy2", "fortune"
    let numId: Int?          // numeric tiers
    let name: String
    let unlock: Int
    let achievUnlock: Int
    let iconRow: Int
    let color: String
    let special: Bool
    let req: String?
    let price: Double
    weak var unshackleUpgrade: Upgrade?
    init(_ key: String, _ name: String, unlock: Int, achievUnlock: Int = 0, iconRow: Int, color: String, special: Bool = false, req: String? = nil, price: Double) {
        self.key = key; self.numId = Int(key); self.name = name; self.unlock = unlock; self.achievUnlock = achievUnlock
        self.iconRow = iconRow; self.color = color; self.special = special; self.req = req; self.price = price
    }
}

/// G.unlockAt: standardized unlock requirements.
final class UnlockAt {
    var cookies = 0.0
    var cps = 0.0
    var buildings: [(Building, Int)] = []   // building, amount (-1 = ignore)
    var upgrades: [Upgrade] = []
    var achievs: [Achiev] = []
    var milk = 0.0
    var spe: (() -> Bool)? = nil
    var isEmpty: Bool { cookies == 0 && cps == 0 && buildings.isEmpty && upgrades.isEmpty && achievs.isEmpty && milk == 0 && spe == nil }
}

final class Building {
    let id: Int
    let name: String
    let single: String, plural: String, actionName: String, extraName: String, extraPlural: String
    let desc: String
    let pic: Int
    let icon: [Int]
    var cps: Double
    var baseCps: Double
    var baseCost: Double
    let foolName: String, foolPlural: String, foolDesc: String

    var amount = 0, amountMax = 0, bought = 0, free = 0
    var storedCps = 0.0
    var cookiesMade = 0.0
    var locked = 2
    // sugar lumps mod (desktop rules): building level and minigame save
    var level = 0
    var minigameSave = ""
    var style: String? = nil
    weak var unshackleUpgrade: Upgrade?

    init(id: Int, o: [String: Any]) {
        self.id = id
        name = o["name"] as? String ?? ""
        single = o["single"] as? String ?? ""
        plural = o["plural"] as? String ?? ""
        actionName = o["actionName"] as? String ?? ""
        extraName = o["extraName"] as? String ?? ""
        extraPlural = o["extraPlural"] as? String ?? ""
        desc = o["desc"] as? String ?? ""
        pic = o["pic"] as? Int ?? 0
        icon = o["icon"] as? [Int] ?? [0, 0]
        cps = (o["cps"] as? NSNumber)?.doubleValue ?? 0
        foolName = o["foolName"] as? String ?? ""
        foolPlural = o["foolPlural"] as? String ?? ""
        foolDesc = o["foolDesc"] as? String ?? ""
        if id == 0 {
            baseCps = 0.1
            baseCost = 15
        } else {
            let i = Double(id)
            var bc = (pow(i * 1, i * 0.5 + 2) * 10).rounded(.up) / 10
            var digits = pow(10, (log(bc.rounded(.up)) / M_LN10).rounded(.up)) / 100
            bc = jsRound(bc / digits) * digits
            baseCps = bc
            var cost = (i * 1 + 9 + (id < 5 ? 0 : pow(i - 5, 1.75) * 5)) * pow(10, i)
            digits = pow(10, (log(cost.rounded(.up)) / M_LN10).rounded(.up)) / 100
            cost = jsRound(cost / digits) * digits
            if id >= 16 { cost *= 10 }
            if id >= 17 { cost *= 10 }
            if id >= 18 { cost *= 10 }
            if id >= 19 { cost *= 20 }
            baseCost = cost
        }
    }

    func reset() { amount = 0; amountMax = 0; bought = 0; free = 0; storedCps = 0; cookiesMade = 0 }

    /// background-position of this building's picture in buildings.png
    func getPic() -> (Double, Double) {
        if G.season == "fools" {
            if locked == 1 { return (-192, Double(-pic * 64)) }
            return (-128, Double(-pic * 64))
        }
        if locked == 1 { return (-64, Double(-pic * 64)) }
        if id == 1 && G.elderWrath > 0 {
            if G.getSet("notScary") != 0 { return (Double(-3 * 64), Double(-(pic + 1) * 64)) }
            return (Double(-(G.elderWrath - 1) * 64), Double(-(pic + 1) * 64))
        }
        return (0, Double(-pic * 64))
    }
    func getName(_ n: Int = 1) -> String {
        if G.season == "fools" { return n == 1 ? foolName : foolPlural }
        return n == 1 ? name : plural
    }
    func getDesc() -> String { G.season == "fools" ? foolDesc : desc }

    func buy(_ amountIn: Int = 0) {
        if G.bulkMode == -1 { sell(G.bulkBuy, bypass: true); return }
        var success = false
        var amount = amountIn
        if amount == 0 { amount = G.bulkBuy }
        if amount == -1 { amount = 1000 }
        for _ in 0..<min(amount, 1000) {
            let cost = getCost()
            if G.cookies >= cost {
                G.spend(cost)
                self.amount += 1
                bought += 1
                G.refreshCps = true
                success = true
            }
        }
        amountMax = max(self.amount, amountMax)
        if success { PlaySound("snd/buy" + choose(["1", "2", "3", "4"]) + ".mp3", 0.65); G.computeBuildingAmounts(); G.onBuildingBought(self) }
    }
    func forceBuy(_ amountIn: Int = 0) {
        var success = false
        let amount = amountIn == 0 ? 1 : amountIn
        for _ in 0..<min(amount, 1000) { self.amount += 1; bought += 1; G.refreshCps = true; success = true }
        amountMax = max(self.amount, amountMax)
        if success { G.computeBuildingAmounts() }
    }
    func sell(_ amountIn: Int = 0, bypass: Bool = false) {
        var success = false
        var amount = amountIn
        if amount == -1 { amount = self.amount }
        if amount == 0 { amount = G.bulkBuy }
        var sold = 0
        if amount > 0 {
            for _ in 0..<amount {
                var cost = getCost()
                let giveBack = getSellMultiplier()
                cost = (cost * giveBack).rounded(.down)
                if self.amount > 0 {
                    sold += 1
                    G.cookies += cost
                    G.cookiesEarned = max(G.cookies, G.cookiesEarned)
                    self.amount -= 1
                    G.refreshCps = true
                    success = true
                }
            }
        }
        if success && G.shimmerTypesBN["golden"]!.n <= 0 && G.auraMult("Dragon Orbs") > 0 {
            var highest: Building? = nil
            for b in G.buildings where b.amount > 0 { highest = b }
            if highest === self && JSMath.random() < G.auraMult("Dragon Orbs") * 0.1 {
                if G.buffs.isEmpty {
                    _ = G.newShimmer("golden")
                    G.toast("<b>Dragon Orbs!</b>", "Wish granted. Golden cookie spawned.", [33, 25], true)
                }
            }
        }
        if success { PlaySound("snd/sell" + choose(["1", "2", "3", "4"]) + ".mp3", 0.75); G.computeBuildingAmounts(); G.onBuildingSold(self, sold) }
    }
    func forceSell(_ amountIn: Int = 0) {
        var success = false
        let amount = amountIn == 0 ? 1 : amountIn
        for _ in 0..<amount where self.amount > 0 { self.amount -= 1; G.refreshCps = true; success = true }
        if success { G.computeBuildingAmounts() }
    }
    func sacrifice(_ n: Int) { forceSell(n) }

    func getCost() -> Double {
        var cost = baseCost * pow(G.costIncrease, Double(max(0, amount - free)))
        cost = G.modifyBuildingCost(self, cost)
        return cost.rounded(.up)
    }
    func getSumCost(_ amount: Int) -> Double {
        var cost = 0.0
        var i = max(0, self.amount)
        while i < max(0, self.amount + amount) {
            let toAdd = baseCost * pow(G.costIncrease, Double(max(0, i - free)))
            if amount == 10000 && G.modifyBuildingCost(self, cost + toAdd) > G.cookies { break }
            cost += toAdd
            i += 1
        }
        cost = G.modifyBuildingCost(self, cost)
        if amount == 10000 { return min(cost, G.cookies) }
        return cost.rounded(.up)
    }
    func getBuyMax() -> Int {
        var cost = 0.0
        var canBuy = 0
        var i = max(0, amount)
        while i < max(0, amount + 1000) {
            let toAdd = baseCost * pow(G.costIncrease, Double(max(0, i - free)))
            if G.modifyBuildingCost(self, cost + toAdd) > G.cookies { break }
            cost += toAdd
            canBuy += 1
            i += 1
        }
        return canBuy
    }
    func getReverseSumCost(_ amount: Int) -> Double {
        var cost = 0.0
        var i = max(0, self.amount - amount)
        while i < max(0, self.amount) {
            cost += baseCost * pow(G.costIncrease, Double(max(0, i - free)))
            i += 1
        }
        cost = G.modifyBuildingCost(self, cost)
        cost *= getSellMultiplier()
        return cost.rounded(.up)
    }
    func getSellMultiplier() -> Double {
        var giveBack = 0.25
        giveBack *= 1 + G.auraMult("Earth Shatterer")
        return giveBack
    }
}

final class Upgrade {
    var unimplemented = false
    var effs: [Eff] = []
    var id = 0
    var pool = ""
    var tier: Tier? = nil
    var unlockAt: UnlockAt? = nil
    var power = 0.0
    var powerFunc: (() -> Double)? = nil
    var cost = 0.0
    var costFunc: ((Upgrade) -> Double)? = nil
    /// called when bought (or toggled); for prestige upgrades, after every ascension. Second argument: forced.
    var funcB: ((Upgrade, Bool) -> Void)? = nil
    var order = 0.0
    var icon: [Int] = [0, 0]
    var iconFunc: (() -> [Int])? = nil
    var name = ""
    var q = ""
    var desc = ""
    var descFunc: ((Upgrade) -> String)? = nil
    var preDescFunc: ((Upgrade) -> String)? = nil
    var qFunc: ((Upgrade) -> String)? = nil
    var style: String? = nil
    var tie: Building? = nil
    var tie2: Building? = nil
    var parentNames: [String] = []
    var permanentSlotIndex: Int? = nil

    var unlocked = 0
    var owned = 0
    var ping = false

    func getPower() -> Double { powerFunc?() ?? power }

    func reset() { unlocked = 0; owned = 0; ping = false }
    func unlock() {
        if pool == "prestige" { return }
        if unlocked != 0 { return }
        unlocked = 1
        if pool != "toggle" && pool != "science" { G.pingScreen("store") }
        ping = true
    }
    func lock() { lose() }
    func toggleOff() { unlocked = 0 }
    func toggleOn() { lose(); unlocked = 1 }

    @discardableResult
    func buy() -> Bool {
        if pool == "prestige" {
            if owned != 0 { return false }
            for p in G.HeavenlyUpgradeParents[id] ?? [] {
                if G.upgradesBID[p]?.owned ?? 0 == 0 { return false }
            }
            let cost = getCost()
            if G.heavenlyChips < cost { return false }
            G.heavenlyChips -= cost
            G.heavenlyChipsSpent += cost
            PlaySound("snd/buy" + choose(["1", "2", "3", "4"]) + ".mp3", 0.75)
            PlaySound("snd/shimmerClick.mp3", 0.5)
            owned = 1
            return true
        }
        if owned != 0 || (pool != "toggle" && unlocked == 0) { return false }
        var success = false
        let cost = getCost()
        if G.cookies >= cost {
            G.spend(cost)
            owned = 1
            G.refreshCps = true
            success = true
            if pool != "toggle" && pool != "prestige" {
                G.upgradesN += 1
                G.recentUpgrades.insert(self, at: 0)
                if G.recentUpgrades.count > 5 { G.recentUpgrades.removeLast(G.recentUpgrades.count - 5) }
            }
            funcB?(self, false)
        }
        return success
    }
    @discardableResult
    func forceBuy() -> Bool {
        if owned != 0 { return false }
        owned = 1
        unlocked = 1
        if pool != "toggle" && pool != "prestige" {
            G.upgradesN += 1
            G.recentUpgrades.insert(self, at: 0)
            if G.recentUpgrades.count > 5 { G.recentUpgrades.removeLast(G.recentUpgrades.count - 5) }
        }
        funcB?(self, true)
        G.refreshCps = true
        return true
    }
    func lose() {
        if owned != 0 && pool != "toggle" && pool != "prestige" { G.upgradesN -= 1 }
        owned = 0
        unlocked = 0
        G.refreshCps = true
    }
    func getCost() -> Double {
        let c = costFunc?(self) ?? cost
        return (pool == "toggle" || pool == "prestige") ? c : G.modifyUpgradeCost(self, c).rounded(.up)
    }
    func getComputedEff(_ effName: String, _ base: Double) -> Double {
        var found: Eff? = nil
        for e in effs where e.pool == effName { found = e }
        guard let e = found else { return 0 }
        return e.apply(base)
    }
    func getDescText() -> String { descFunc?(self) ?? desc }
    func getQText() -> String { qFunc?(self) ?? q }
    func getIcon() -> [Int] { iconFunc?() ?? icon }
}

final class Achiev {
    var unimplemented = false
    var id = 0
    var name = ""
    var pool = ""
    var desc = ""
    var descFunc: ((Achiev) -> String)? = nil
    var q = ""
    var qFunc: ((Achiev) -> String)? = nil
    var order = 0.0
    var icon: [Int] = [0, 0]
    var tier = 0
    var unlockAt: UnlockAt? = nil
    var style: String? = nil
    var owned = 0

    func reset() { owned = 0 }
    func win() {
        if owned != 0 { return }
        owned = 1
        if pool != "shadow" { G.achievsN += 1 }
        G.recentAchievs.insert(self, at: 0)
        if G.recentAchievs.count > 5 { G.recentAchievs.removeLast(G.recentAchievs.count - 5) }
        G.toast(name, "Achievement unlocked", icon)
    }
    func forceWin() {
        if owned != 0 { return }
        owned = 1
        G.recentAchievs.insert(self, at: 0)
        if G.recentAchievs.count > 5 { G.recentAchievs.removeLast(G.recentAchievs.count - 5) }
        if pool != "shadow" { G.achievsN += 1 }
    }
    func lose() {
        if owned == 0 { return }
        owned = 0
        if pool != "shadow" { G.achievsN -= 1 }
    }
    func getDescText() -> String { descFunc?(self) ?? desc }
    func getQText() -> String { qFunc?(self) ?? q }
}

/// Milk types (G.AllMilks)
struct Milk {
    let name: String
    let icon: [Int]
    let type: Int
    let pic: String
    var rank = -1
}
