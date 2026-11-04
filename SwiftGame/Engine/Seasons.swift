import Foundation

struct SeasonInfo { let key: String, name: String, start: String, over: String, trigger: String }

enum Seasons {
    static let list: [SeasonInfo] = [
        SeasonInfo(key: "christmas", name: "Christmas", start: "Christmas season has started!", over: "Christmas season is over.", trigger: "Festive biscuit"),
        SeasonInfo(key: "valentines", name: "Valentine's day", start: "Valentine's day has started!", over: "Valentine's day is over.", trigger: "Lovesick biscuit"),
        SeasonInfo(key: "fools", name: "Business day", start: "Business day has started!", over: "Business day is over.", trigger: "Fool's biscuit"),
        SeasonInfo(key: "easter", name: "Easter", start: "Easter season has started!", over: "Easter season is over.", trigger: "Bunny biscuit"),
        SeasonInfo(key: "halloween", name: "Halloween", start: "Halloween has started!", over: "Halloween is over.", trigger: "Ghostly biscuit"),
    ]
    static func info(_ key: String) -> SeasonInfo? { list.first { $0.key == key } }

    static let santaDrops = ["Increased merriness", "Improved jolliness", "A lump of coal", "An itchy sweater", "Reindeer baking grounds", "Weighted sleighs", "Ho ho ho-flavored frosting", "Season savings", "Toy workshop", "Naughty list", "Santa's bottomless bag", "Santa's helpers", "Santa's legacy", "Santa's milk and cookies"]
    static let reindeerDrops = ["Christmas tree biscuits", "Snowflake biscuits", "Snowman biscuits", "Holly biscuits", "Candy cane biscuits", "Bell biscuits", "Present biscuits"]
    static let heartDrops = ["Pure heart biscuits", "Ardent heart biscuits", "Sour heart biscuits", "Weeping heart biscuits", "Golden heart biscuits", "Eternal heart biscuits", "Prism heart biscuits"]
    static let easterEggs = ["Chicken egg", "Duck egg", "Turkey egg", "Quail egg", "Robin egg", "Ostrich egg", "Cassowary egg", "Salmon roe", "Frogspawn", "Shark egg", "Turtle egg", "Ant larva", "Golden goose egg", "Faberge egg", "Wrinklerspawn", "Cookie egg", "Omelette", "Chocolate egg", "Century egg", "\"egg\""]
    static let eggDrops = Array(easterEggs.prefix(12))
    static let rareEggDrops = Array(easterEggs.suffix(8))
    static let halloweenDrops = ["Skull cookies", "Ghost cookies", "Bat cookies", "Slime cookies", "Pumpkin cookies", "Eyeball cookies", "Spider cookies"]
    static var seasonDrops: [String] { heartDrops + halloweenDrops + easterEggs + santaDrops + reindeerDrops }

    static func count(_ g: Game, _ names: [String]) -> Int { names.filter { g.HasUnlocked($0) }.count }
    static func howManyEggs(_ g: Game) -> Int { count(g, easterEggs) }

    static var baseSeason = ""
    static var lastCheck = 0.0

    static func getBaseSeason(_ date: Date = Date()) -> String {
        let cal = Calendar(identifier: .gregorian)
        let year = cal.component(.year, from: date)
        let leap = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0) ? 1 : 0
        let day = cal.ordinality(of: .day, in: .year, for: date) ?? 1
        if day >= 41 && day <= 46 { return "valentines" }
        if day + leap >= 90 && day <= 92 + leap { return "fools" }
        if day >= 304 - 7 + leap && day <= 304 + leap { return "halloween" }
        if day >= 349 + leap && day <= 365 + leap { return "christmas" }
        // easter: Meeus/Jones/Butcher, same as the original
        let Y = year
        let C = Y / 100, N = Y - 19 * (Y / 19), K = (C - 17) / 25
        var I = C - C / 4 - (C - K) / 3 + 19 * N + 15
        I = I - 30 * (I / 30)
        I = I - (I / 28) * (1 - (I / 28) * (29 / (I + 1)) * ((21 - N) / 11))
        var J = Y + Y / 4 + I + 2 - C + C / 4
        J = J - 7 * (J / 7)
        let L = I - J
        let M = 3 + (L + 40) / 44
        let D = L + 28 - 31 * (M / 4)
        if let easter = cal.date(from: DateComponents(year: Y, month: M, day: D)), let eDay = cal.ordinality(of: .day, in: .year, for: easter) {
            if day >= eDay - 7 && day <= eDay { return "easter" }
        }
        return ""
    }

    static func reset(_ g: Game) {
        baseSeason = getBaseSeason()
        g.season = baseSeason; g.seasonT = 0; g.seasonUses = 0
    }

    static func switchSeason(_ g: Game, _ season: String?) {
        if let s = season {
            if g.season != s, let i = info(s) { g.toast(i.start, "", g.upgradesBN[i.trigger]?.def.icon) }
            g.season = s
            g.seasonT = now() + 86_400_000
        } else {
            if let i = info(g.season) { g.toast(i.over, "", g.upgradesBN[i.trigger]?.def.icon) }
            g.season = ""; g.seasonT = 0
        }
    }

    static func logic(_ g: Game, _ delta: Double) {
        let prev = g.season
        if now() >= lastCheck + 60_000 {
            baseSeason = getBaseSeason()
            if g.season == "" { g.season = baseSeason }
            lastCheck = now()
        }
        if g.season != "" && g.season != baseSeason && g.seasonT <= now() {
            if let i = info(g.season) { g.toast(i.over, "", g.upgradesBN[i.trigger]?.def.icon) }
            g.season = baseSeason; g.seasonT = 0
        }
        if prev != g.season && g.season != "", let i = info(g.season) {
            g.toast(i.start, "", g.upgradesBN[i.trigger]?.def.icon)
        }
    }

    private static func godMod(_ fail: inout Double) {
        let lvl = Minigames.shared.hasGod("seasons")
        if lvl == 1 { fail *= 0.9 } else if lvl == 2 { fail *= 0.95 } else if lvl == 3 { fail *= 0.97 }
    }

    static func dropSanta(_ g: Game) {
        let drops = santaDrops.filter { !g.HasUnlocked($0) }
        guard !drops.isEmpty else { return }
        let d = choose(drops)
        g.unlock(d)
        g.toast("<b>\(d)</b>!", "You find a present which contains...", g.upgradesBN[d]?.def.icon)
    }
    static func dropReindeer(_ g: Game, _ failIn: Double) {
        if g.season != "christmas" { return }
        var fail = failIn
        if g.HasAchiev("Let it snow") { fail *= 0.6 }
        if g.Has("Starsnow") { fail *= 0.95 }
        fail *= 1 / g.dropRateMult()
        godMod(&fail)
        if rnd() >= fail {
            let d = choose(reindeerDrops)
            if g.Has(d) || g.HasUnlocked(d) { return }
            g.unlock(d)
            g.toast("<b>\(d)</b>", "The reindeer gives you:", g.upgradesBN[d]?.def.icon)
        }
    }
    static func dropEgg(_ g: Game, _ failIn: Double) {
        if g.season != "easter" { return }
        var fail = failIn * (1 / g.dropRateMult())
        if g.HasAchiev("Hide & seek champion") { fail *= 0.7 }
        if g.Has("Omelette") { fail *= 0.9 }
        if g.Has("Starspawn") { fail *= 0.9 }
        godMod(&fail)
        if rnd() >= fail {
            var d = rnd() < 0.1 ? choose(rareEggDrops) : choose(eggDrops)
            if g.Has(d) || g.HasUnlocked(d) { d = rnd() < 0.1 ? choose(rareEggDrops) : choose(eggDrops) }
            if g.Has(d) || g.HasUnlocked(d) { return }
            g.unlock(d)
            g.toast("<b>\(d)</b>", "You found an egg!", g.upgradesBN[d]?.def.icon)
        }
    }
    static func dropHalloween(_ g: Game, _ failIn: Double) {
        if g.season != "halloween" { return }
        var fail = failIn
        if g.HasAchiev("Spooky cookies") { fail *= 0.8 }
        if g.Has("Starterror") { fail *= 0.9 }
        fail *= 1 / g.dropRateMult()
        godMod(&fail)
        if rnd() >= fail {
            let d = choose(halloweenDrops)
            if g.Has(d) || g.HasUnlocked(d) { return }
            g.unlock(d)
            g.toast("<b>\(d)</b>", "You found:", g.upgradesBN[d]?.def.icon)
        }
    }

    static func triggerCost(_ g: Game) -> Double {
        var m = 1.0
        let lvl = Minigames.shared.hasGod("seasons")
        if lvl == 1 { m *= 2 } else if lvl == 2 { m *= 1.5 } else if lvl == 3 { m *= 1.25 }
        return 1e9 + g.cookiesPsUnbuffed * 60 * pow(1.5, g.seasonUses) * m
    }
}
