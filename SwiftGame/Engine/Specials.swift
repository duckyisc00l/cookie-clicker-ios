import Foundation

/// The handful of upgrades and achievements whose rules are written as code in the original game.
extension Game {
    func specialEff(_ name: String, _ key: String, _ v: Double) -> Double {
        switch name {
        case "Thousand fingers":
            var n = 0
            for i in 1..<buildings.count { n += buildings[i].amount }
            var mult = 1.0
            let pows: [Double] = [2, 2, 2, 0.1, 5, 10, 20]
            let finger = upgradePools["finger"] ?? []
            if finger.count > 4 { for i in 4..<finger.count where finger[i].owned > 0 { mult *= i < 7 ? pows[i] : 20 } }
            if Has("Unshackled cursors") { mult *= 25 }
            return v + Double(n) * 0.1 * mult
        case "Santa's legacy": return v * (1 + 0.03 * Double(santaLevel))
        case "Century egg":
            var day = ((now() - runStart) / 1000 / 10).rounded(.down) * 10 / 60 / 60 / 24
            day = max(0, min(day, 100))
            return v * (1 + (1 - pow(1 - day / 100, 3)) * 0.1)
        case "Pure heart biscuits", "Ardent heart biscuits", "Sour heart biscuits", "Weeping heart biscuits",
             "Golden heart biscuits", "Eternal heart biscuits", "Prism heart biscuits":
            return v * (1 + (2 + (Has("Starlove") ? 1 : 0)) * 0.01)
        case "One mind", "Communal brainsweep": return v + (1 + 0.02 * Double(buildings[1].amount))
        case "Elder Pact": return v + (1 + 0.05 * Double(buildings[10].amount))
        case "Starspawn": return v * (1 + (season == "easter" ? 0.02 : 0))
        case "Starterror": return v * (1 + (season == "halloween" ? 0.02 : 0))
        case "Starlove": return v * (1 + (season == "valentines" ? 0.02 : 0))
        case "Startrade": return v * (1 + (season == "fools" ? 0.05 : 0))
        case "Golden switch [off]":
            let lucky = Has("Residual luck") ? Double(Game.goldenCookieUpgradeNames.filter { Has($0) }.count) : 0
            return v * (1 + 0.5 + 0.1 * lucky)
        case "Five-finger discount": return v * pow(0.99, Double(buildings[0].amount) / 100)
        default: return v
        }
    }
    static let goldenCookieUpgradeNames = ["Get lucky", "Lucky day", "Serendipity", "Heavenly luck", "Lasting fortune", "Decisive fate", "Lucky digit", "Lucky number", "Lucky payout", "Golden goose egg"]

    func specialCost(_ u: Upgrade, _ kind: String) -> Double {
        if kind.contains("tie2.baseCost") {
            // synergy upgrades: (cheaper building cost*10 + pricier building cost) * tier price
            var ids: [Int] = []
            for e in u.def.effs { if case .syn(let p, _, _) = e, let i = Int(p.dropFirst(8).dropLast(1)) { ids.append(i) } }
            ids.sort()
            let tier = data.tiers.values.first { $0.name == u.def.tier }
            if ids.count == 2, let tier = tier {
                return (data.buildings[ids[0]].baseCost * 10 + data.buildings[ids[1]].baseCost) * tier.price * (Has("Chimera") ? 0.98 : 1)
            }
            return u.def.cost
        }
        if kind.contains("santaLevel") { return pow(3, Double(santaLevel)) * 2525 }
        if kind.contains("Math.pow(2,G.GetHowManyEggs())") { return pow(2, Double(Seasons.howManyEggs(self))) * 999 }
        if kind.contains("Math.pow(3,G.GetHowManyEggs())") { return pow(3, Double(Seasons.howManyEggs(self))) * 999 }
        if kind.contains("G.hasGod") {
            var m = 1.0
            let lvl = Minigames.shared.hasGod("seasons")
            if lvl == 1 { m *= 2 } else if lvl == 2 { m *= 1.5 } else if lvl == 3 { m *= 1.25 }
            return 1e9 + cookiesPsUnbuffed * 60 * pow(1.5, seasonUses) * m
        }
        if kind.contains("dragonLevel") { return cookiesPsUnbuffed * 60 * 30 * (dragonLevel < Dragon.levels.count - 1 ? 1 : 0.1) }
        if kind.contains("Math.min(me.cost") { return min(u.def.cost, cookiesPsUnbuffed * 86400) }
        if kind.contains("Math.pow(8") { return pow(8, Double(min(Int(pledges) + 2, 14))) }
        if kind.contains("Math.max(1000000") { return max(1_000_000, cookiesPsUnbuffed * 3600) }
        if kind.contains("G.cookiesPs*60*60") { return cookiesPs * 3600 }
        return u.def.cost
    }

    func specialCond(_ s: SpecialCond, _ name: String) -> Bool {
        switch s {
        case .stat(let k, let n): return stat(k) >= n
        case .season(let v): return season == v
        case .made(let b, let n): return buildings[b].cookiesMade >= n
        case .named(let n):
            switch n {
            case "Heavenly chip secret": return resets > 0
            case "A festive hat": return cookiesEarned >= 25 && season == "christmas"
            case "A crumbly egg": return cookiesEarned >= 1_000_000 && Has("How to bake your dragon")
            case "Just wrong": let g = buildings[1]; return g.bought > g.amount
            case "Elder": return (upgradePools["grandma"] ?? []).filter { $0.owned > 0 }.count >= 7
            case "Veteran": return (upgradePools["grandma"] ?? []).filter { $0.owned > 0 }.count >= 14
            case "Polymath": return buildingsN >= 3000 && upgradesN >= 300
            case "Renaissance baker": return buildingsN >= 4000 && upgradesN >= 400
            case "The elder scrolls": return buildings[0].amount + buildings[1].amount >= 777
            case "One with everything": return buildings.allSatisfy { $0.amount > 0 }
            case "Mathematician":
                let n = buildings.count
                for (i, b) in buildings.enumerated() { if Double(b.amount) < min(128, pow(2, Double(n - i - 1))) { return false } }
                return true
            case "Base 10":
                let n = buildings.count
                for (i, b) in buildings.enumerated() { if b.amount < (n - i) * 10 { return false } }
                return true
            case "O Fortuna": return (tierUpgrades["Fortune"] ?? []).allSatisfy { $0.owned > 0 }
            case "The hunt is on": return season == "easter" && Seasons.howManyEggs(self) >= 1
            case "Egging on": return season == "easter" && Seasons.howManyEggs(self) >= 7
            case "Mass Easteria": return season == "easter" && Seasons.howManyEggs(self) >= 14
            case "Hide & seek champion": return season == "easter" && Seasons.howManyEggs(self) >= Seasons.easterEggs.count
            case "Spooky cookies": return season == "halloween" && Seasons.count(self, Seasons.halloweenDrops) >= Seasons.halloweenDrops.count
            case "Let it snow": return season == "christmas" && Seasons.count(self, Seasons.reindeerDrops) >= Seasons.reindeerDrops.count
            case "Jellicles": return (upgradePools["kitten"] ?? []).filter { $0.owned > 0 }.count >= 10
            case "Cookie Clicker": let b = buildings[19]; return b.bought > 0 || cookiesEarned >= b.def.baseCost
            default: return false
            }
        }
    }

    func stat(_ k: String) -> Double {
        switch k {
        case "buildingsNmin": return Double(buildingsNmin)
        case "buildingsN": return Double(buildingsN)
        case "upgradesN": return Double(upgradesN)
        case "gcClicksTotal": return gcClicksTotal
        case "wrinklersPopped": return wrinklersPopped
        case "reindeerClicksTotal": return reindeerClicksTotal
        case "elderWrath": return Double(elderWrath)
        case "resets": return resets
        case "pledges": return pledges
        case "cookiesHandmade": return cookiesHandmade
        default: return 0
        }
    }

    /// what buying certain upgrades does right away (the original upgrades' func)
    func upgradeBought(_ u: Upgrade, forced: Bool) {
        switch u.name {
        case "A festive hat":
            let drop = choose(Seasons.santaDrops)
            unlock(drop)
            toast("In the festive hat, you find...", "a festive test tube<br>and <b>\(drop)</b>.", upgradesBN[drop]?.def.icon, true)
            pings.insert("special")
        case "A crumbly egg", "Bingo center/Research facility": pings.insert("special")
        case "Chocolate egg":
            let c = cookies * 0.05
            toast("Chocolate egg", "The egg bursts into <b>\(B(c))</b> cookies!", u.def.icon, true)
            earn(c)
        case "Elder Pact": unlock("Elder Pledge")
        case "Elder Pledge":
            elderWrath = 0
            Wrinklers.shared.collect(self)
            pledges += 1
            win("Elder nap")
            if pledges >= 5 { win("Elder slumber") }
            pledgeT = now() + 60 * (Has("Sacrificial rolling pins") ? 60 : 30) * 1000
            unlock("Elder Covenant")
            u.owned = 0
            toast(u.name, "Grandmatriarchs appeased.", u.def.icon, true)
        case "Elder Covenant":
            elderWrath = 0
            Wrinklers.shared.collect(self)
            pledgeT = 0
            win("Elder calm")
            toggleOff("Elder Covenant"); toggleOn("Revoke Elder Covenant")
            toast(u.name, "Grandmapocalypse ended.", u.def.icon, true)
        case "Revoke Elder Covenant":
            toggleOff("Revoke Elder Covenant"); toggleOn("Elder Covenant")
            toast(u.name, "Covenant has been revoked...", u.def.icon, true)
        case "Season switcher":
            for s in Seasons.list { upgradesBN[s.trigger]?.unlocked = 1 }
        case "Golden switch": unlock("Golden switch [off]")
        case "Golden switch [off]": toggleOff("Golden switch [off]"); toggleOn("Golden switch [on]")
        case "Golden switch [on]": toggleOff("Golden switch [on]"); toggleOn("Golden switch [off]")
        default: break
        }
    }
}
