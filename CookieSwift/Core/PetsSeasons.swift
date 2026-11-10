import Foundation

// Port of www/main.js "PETS" (santa, dragon) and "SEASONS" sections.

struct DragonLevel {
    let name: String
    let action: String
    let pic: Int
    var drop = false
    var cost: (() -> Bool)? = nil
    var buy: (() -> Void)? = nil
    var costStr: (() -> String)? = nil
}

struct DragonAura {
    let id: Int
    let name: String
    let pic: [Int]
    let desc: String
    var drop = false
}

struct Season {
    let key: String
    let name: String
    let start: String
    let over: String
    let trigger: String
    var triggerUpgrade: Upgrade { G.upgradesBN[trigger]! }
}

/// choose() on a list that may be empty (JavaScript returns undefined)
func chooseOpt<T>(_ arr: [T]) -> T? { arr.isEmpty ? nil : choose(arr) }

extension Game {
    // MARK: santa
    static let santaLevels = ["Festive test tube", "Festive ornament", "Festive wreath", "Festive tree", "Festive present", "Festive elf fetus", "Elf toddler", "Elfling", "Young elf", "Bulky elf", "Nick", "Santa Claus", "Elder Santa", "True Santa", "Final Claus"]

    func resetPets(_ hard: Bool) {
        santaLevel = 0
        dragonLevel = 0
        dragonAura = 0
        dragonAura2 = 0
    }
    func SantaUpgradeCost() -> Double { pow(Double(santaLevel + 1), Double(santaLevel + 1)) * (1 + 0.01 * prestige) }
    @discardableResult
    func UpgradeSanta() -> Bool {
        if santaLevel >= 14 { return false }
        let moni = SantaUpgradeCost()
        if cookies < moni { return false }
        PlaySound("snd/shimmerClick.mp3")
        spend(moni)
        santaLevel = (santaLevel + 1) % 15
        if santaLevel == 14 {
            unlock("Santa's dominion")
            toast("You are granted Santa's dominion.", "", upgradesBN["Santa's dominion"]!.icon)
        }
        DropSanta()
        UpgradedSanta()
        return true
    }
    func UpgradedSanta() {
        if santaLevel >= 6 { win("Coming to town") }
        if santaLevel >= 14 { win("All hail Santa") }
        refreshCps = true
        doUnlocks()
    }

    // MARK: dragon
    func initDragon() {
        var levels: [DragonLevel] = [
            DragonLevel(name: "Dragon egg", action: "Chip it", pic: 0, cost: { G.cookies >= 1000000 }, buy: { G.spend(1000000) }, costStr: { B(1000000) + " cookies" }),
            DragonLevel(name: "Dragon egg", action: "Chip it", pic: 1, cost: { G.cookies >= 1000000 * 2 }, buy: { G.spend(1000000 * 2) }, costStr: { B(1000000 * 2) + " cookies" }),
            DragonLevel(name: "Dragon egg", action: "Chip it", pic: 2, cost: { G.cookies >= 1000000 * 4 }, buy: { G.spend(1000000 * 4) }, costStr: { B(1000000 * 4) + " cookies" }),
            DragonLevel(name: "Shivering dragon egg", action: "Hatch it", pic: 3, cost: { G.cookies >= 1000000 * 8 }, buy: { G.spend(1000000 * 8) }, costStr: { B(1000000 * 8) + " cookies" }),
            DragonLevel(name: "Krumblor, cookie hatchling", action: "Train Breath of Milk<br><small>Aura: kittens are 5% more effective</small>", pic: 4, cost: { G.cookies >= 1000000 * 16 }, buy: { G.spend(1000000 * 16) }, costStr: { B(1000000 * 16) + " cookies" }),
            DragonLevel(name: "Krumblor, cookie hatchling", action: "Train Dragon Cursor<br><small>Aura: enhanced power clicks; clicking is 5% more effective</small>", pic: 4),
            DragonLevel(name: "Krumblor, cookie hatchling", action: "Train Elder Battalion<br><small>Aura: grandmas gain +1% CpS for every non-grandma building</small>", pic: 4),
            DragonLevel(name: "Krumblor, cookie hatchling", action: "Train Reaper of Fields<br><small>Aura: golden cookies may trigger a Dragon Harvest</small>", pic: 4),
            DragonLevel(name: "Krumblor, cookie dragon", action: "Train Earth Shatterer<br><small>Aura: buildings sell back for 50% instead of 25%</small>", pic: 5),
            DragonLevel(name: "Krumblor, cookie dragon", action: "Train Master of the Armory<br><small>Aura: all upgrades are 2% cheaper</small>", pic: 5),
            DragonLevel(name: "Krumblor, cookie dragon", action: "Train Fierce Hoarder<br><small>Aura: all buildings are 2% cheaper</small>", pic: 5),
            DragonLevel(name: "Krumblor, cookie dragon", action: "Train Dragon God<br><small>Aura: prestige CpS bonus +5%</small>", pic: 5),
            DragonLevel(name: "Krumblor, cookie dragon", action: "Train Arcane Aura<br><small>Aura: golden cookies appear 5% more often</small>", pic: 5),
            DragonLevel(name: "Krumblor, cookie dragon", action: "Train Dragonflight<br><small>Aura: golden cookies may trigger a Dragonflight</small>", pic: 5),
            DragonLevel(name: "Krumblor, cookie dragon", action: "Train Ancestral Metamorphosis<br><small>Aura: golden cookies give 10% more cookies</small>", pic: 5),
            DragonLevel(name: "Krumblor, cookie dragon", action: "Train Unholy Dominion<br><small>Aura: wrath cookies give 10% more cookies</small>", pic: 5),
            DragonLevel(name: "Krumblor, cookie dragon", action: "Train Epoch Manipulator<br><small>Aura: golden cookie effects last 5% longer</small>", pic: 5),
            DragonLevel(name: "Krumblor, cookie dragon", action: "Train Mind Over Matter<br><small>Aura: +25% random drops</small>", pic: 5),
            DragonLevel(name: "Krumblor, cookie dragon", action: "Train Radiant Appetite<br><small>Aura: all cookie production multiplied by 2</small>", pic: 5),
            DragonLevel(name: "Krumblor, cookie dragon", action: "Train Dragon's Fortune<br><small>Aura: +123% CpS per golden cookie on-screen</small>", pic: 5),
            DragonLevel(name: "Krumblor, cookie dragon", action: "Train Dragon's Curve<br><small>Unlocks 2 dragon upgrades</small>", pic: 5, drop: true),
            DragonLevel(name: "Krumblor, cookie dragon", action: "Train Reality Bending<br><small>Aura: 10% of every other aura, combined</small>", pic: 5),
            DragonLevel(name: "Krumblor, cookie dragon", action: "Train Dragon Orbs<br><small>Aura: selling your best building may grant a wish</small>", pic: 5),
            DragonLevel(name: "Krumblor, cookie dragon", action: "Train Supreme Intellect<br><small>Unlocks 2 dragon upgrades</small>", pic: 5, drop: true),
            DragonLevel(name: "Krumblor, cookie dragon", action: "Train Dragon Guts<br><small>Aura: enhanced wrinklers</small>", pic: 5),
            DragonLevel(name: "Krumblor, cookie dragon", action: "Bake dragon cookie<br><small>Delicious!</small>", pic: 6,
                        cost: { !G.buildings.contains { $0.amount < 50 } },
                        buy: { for b in G.buildings { b.sacrifice(50) }; G.unlock("Dragon cookie") },
                        costStr: { "50 of every building" }),
            DragonLevel(name: "Krumblor, cookie dragon", action: "Train secondary aura<br><small>Lets you use two dragon auras simultaneously</small>", pic: 7,
                        cost: { !G.buildings.contains { $0.amount < 200 } },
                        buy: { for b in G.buildings { b.sacrifice(200) } },
                        costStr: { "200 of every building" }),
            DragonLevel(name: "Krumblor, cookie dragon", action: "Your dragon is fully trained.", pic: 8),
        ]
        // G.addPostData: levels 5.. cost 100 of a building each
        for i in 0..<levels.count where i >= 5 && i < levels.count - 3 {
            let building = buildings[i - 5]
            levels[i].costStr = { "100 " + building.plural }
            levels[i].cost = { building.amount >= 100 }
            levels[i].buy = { building.sacrifice(100) }
        }
        dragonLevels = levels
        dragonAuras = [
            DragonAura(id: 0, name: "No aura", pic: [0, 7], desc: ""),
            DragonAura(id: 1, name: "Breath of Milk", pic: [18, 25], desc: "Kittens are <b>5%</b> more effective."),
            DragonAura(id: 2, name: "Dragon Cursor", pic: [0, 25], desc: "Clicking is <b>5%</b> more powerful.<br><b>+5</b> max power clicks.<br>Power click effects <b>+5%</b>."),
            DragonAura(id: 3, name: "Elder Battalion", pic: [1, 25], desc: "Grandmas gain <b>+1% CpS</b> for each non-grandma building."),
            DragonAura(id: 4, name: "Reaper of Fields", pic: [2, 25], desc: "Golden cookies may trigger a <b>Dragon Harvest</b>."),
            DragonAura(id: 5, name: "Earth Shatterer", pic: [3, 25], desc: "Buildings sell back for <b>50%</b> instead of 25%."),
            DragonAura(id: 6, name: "Master of the Armory", pic: [4, 25], desc: "All upgrades are <b>2% cheaper</b>."),
            DragonAura(id: 7, name: "Fierce Hoarder", pic: [15, 25], desc: "All buildings are <b>2% cheaper</b>."),
            DragonAura(id: 8, name: "Dragon God", pic: [16, 25], desc: "<b>+5%</b> prestige level effect on CpS."),
            DragonAura(id: 9, name: "Arcane Aura", pic: [17, 25], desc: "Golden cookies appear <b>5%</b> more often."),
            DragonAura(id: 10, name: "Dragonflight", pic: [5, 25], desc: "Golden cookies may trigger a <b>Dragonflight</b>."),
            DragonAura(id: 11, name: "Ancestral Metamorphosis", pic: [6, 25], desc: "Golden cookies give <b>10%</b> more cookies."),
            DragonAura(id: 12, name: "Unholy Dominion", pic: [7, 25], desc: "Wrath cookies give <b>10%</b> more cookies."),
            DragonAura(id: 13, name: "Epoch Manipulator", pic: [8, 25], desc: "Golden cookies stay <b>5%</b> longer."),
            DragonAura(id: 14, name: "Mind Over Matter", pic: [13, 25], desc: "Random drops are <b>25% more common</b>."),
            DragonAura(id: 15, name: "Radiant Appetite", pic: [14, 25], desc: "All cookie production <b>multiplied by 2</b>."),
            DragonAura(id: 16, name: "Dragon's Fortune", pic: [19, 25], desc: "<b>+123% CpS</b> per golden cookie on-screen, multiplicative."),
            DragonAura(id: 17, name: "Dragon's Curve", pic: [20, 25], desc: "<b>+5%</b> sugar lump growth. Sugar lumps are <b>twice as likely</b> to be unusual.", drop: true),
            DragonAura(id: 18, name: "Reality Bending", pic: [32, 25], desc: "<b>One tenth</b> of every other dragon aura, <b>combined</b>."),
            DragonAura(id: 19, name: "Dragon Orbs", pic: [33, 25], desc: "With no buffs and no golden cookies on screen, selling your most powerful building has <b>10% chance to summon one</b>."),
            DragonAura(id: 20, name: "Supreme Intellect", pic: [34, 25], desc: "Confers various powers to your minigames while active.<br>See the bottom of each minigame for more details.", drop: true),
            DragonAura(id: 21, name: "Dragon Guts", pic: [35, 25], desc: "You can attract <b>2 more wrinklers</b>.<br>Wrinklers digest <b>20% more cookies</b>.<br>Wrinklers explode into <b>20% more cookies</b>."),
        ]
        dragonAurasBN = [:]
        for a in dragonAuras { dragonAurasBN[a.name] = a }
    }

    @discardableResult
    func UpgradeDragon() -> Bool {
        if dragonLevel >= dragonLevels.count - 1 { return false }
        let currentLevel = dragonLevels[dragonLevel]
        guard let canAfford = currentLevel.cost, canAfford() else { return false }
        currentLevel.buy?()
        PlaySound("snd/shimmerClick.mp3")
        dragonLevel = (dragonLevel + 1) % dragonLevels.count
        if dragonLevel == dragonLevels.count - 1 { win("Here be dragon") }
        if currentLevel.drop {
            let allDrops = ["Dragon scale", "Dragon claw", "Dragon fang", "Dragon teddy bear"]
            for _ in 0..<2 {
                let drops = allDrops.filter { !isUnlocked($0) }
                if let drop = chooseOpt(drops) {
                    unlock(drop)
                    toast("<b>" + upgradesBN[drop]!.name + "</b>!", "The dragon gives you:", upgradesBN[drop]!.icon)
                }
            }
        }
        UpgradedDragon()
        return true
    }
    func UpgradedDragon() {
        refreshCps = true
        doUnlocks()
    }
    func hasAura(_ what: String) -> Bool {
        dragonAuras[dragonAura].name == what || dragonAuras[dragonAura2].name == what
    }
    func auraMult(_ what: String) -> Double {
        var n = 0.0
        if dragonAuras.isEmpty { return 0 }
        if dragonAuras[dragonAura].name == what || dragonAuras[dragonAura2].name == what { n = 1 }
        if (dragonAuras[dragonAura].name == "Reality Bending" || dragonAuras[dragonAura2].name == "Reality Bending"),
           let a = dragonAurasBN[what], dragonLevel >= a.id + 4 { n += 0.1 }
        return n
    }
    /// what happens when an aura is picked in G.SelectDragonAura
    func setDragonAura(slot: Int, to id: Int) {
        let currentAura = slot == 0 ? dragonAura : dragonAura2
        if currentAura == id { return }
        if slot == 0 { dragonAura = id } else if slot == 1 { dragonAura2 = id }
        var highest: Building? = nil
        for b in buildings where b.amount > 0 { highest = b }
        if let h = highest, currentAura != id { h.sacrifice(1) }
        refreshCps = true
        PlaySound("snd/thud.mp3", 0.5)
        PlaySound("snd/tick.mp3", 0.5)
    }

    // MARK: seasons
    func initSeasons() {
        seasonsList = [
            Season(key: "christmas", name: "Christmas", start: "Christmas season has started!", over: "Christmas season is over.", trigger: "Festive biscuit"),
            Season(key: "valentines", name: "Valentine's day", start: "Valentine's day has started!", over: "Valentine's day is over.", trigger: "Lovesick biscuit"),
            Season(key: "fools", name: "Business day", start: "Business day has started!", over: "Business day is over.", trigger: "Fool's biscuit"),
            Season(key: "easter", name: "Easter", start: "Easter season has started!", over: "Easter season is over.", trigger: "Bunny biscuit"),
            Season(key: "halloween", name: "Halloween", start: "Halloween has started!", over: "Halloween is over.", trigger: "Ghostly biscuit"),
        ]
        seasons = [:]
        for s in seasonsList { seasons[s.key] = s }
    }

    /// G.getBaseSeason: automatic season from the date
    func getBaseSeason(_ dateIn: Date? = nil) -> String {
        var season = ""
        let date = dateIn ?? Date()
        let cal = Calendar.current
        let year = cal.component(.year, from: date)
        let leap = (((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0)) ? 1 : 0
        // new Date(year,0,0) is December 31st of the previous year, local time
        let jan0 = cal.date(from: DateComponents(year: year, month: 1, day: 0))!
        let day = Int((date.timeIntervalSince(jan0) / 86400).rounded(.down))
        if day >= 41 && day <= 46 { season = "valentines" }
        else if day + leap >= 90 && day <= 92 + leap { season = "fools" }
        else if day >= 304 - 7 + leap && day <= 304 + leap { season = "halloween" }
        else if day >= 349 + leap && day <= 365 + leap { season = "christmas" }
        else {
            func fl(_ x: Double) -> Int { Int(x.rounded(.down)) }
            let Y = year
            let C = fl(Double(Y) / 100)
            let N = Y - 19 * fl(Double(Y) / 19)
            let K = fl(Double(C - 17) / 25)
            var I = C - fl(Double(C) / 4) - fl(Double(C - K) / 3) + 19 * N + 15
            I = I - 30 * fl(Double(I) / 30)
            I = I - fl(Double(I) / 28) * (1 - fl(Double(I) / 28) * fl(29 / Double(I + 1)) * fl(Double(21 - N) / 11))
            var J = Y + fl(Double(Y) / 4) + I + 2 - C + fl(Double(C) / 4)
            J = J - 7 * fl(Double(J) / 7)
            let L = I - J
            let M = 3 + fl(Double(L + 40) / 44)
            let D = L + 28 - 31 * fl(Double(M) / 4)
            let easter = cal.date(from: DateComponents(year: Y, month: M, day: D))!
            let easterDay = Int((easter.timeIntervalSince(jan0) / 86400).rounded(.down))
            if day >= easterDay - 7 && day <= easterDay { season = "easter" }
        }
        return season
    }

    func resetSeasonData(_ hard: Bool) {
        season = baseSeason
        seasonT = 0
        seasonUses = 0
        computeSeasonPrices()
    }
    static let seasonTriggerBasePrice = 1_000_000_000.0
    func computeSeasonPrices() {
        for s in seasonsList {
            s.triggerUpgrade.costFunc = { _ in
                var m = 1.0
                let godLvl = G.hasGod("seasons")
                if godLvl == 1 { m *= 2 }
                else if godLvl == 2 { m *= 1.50 }
                else if godLvl == 3 { m *= 1.25 }
                return Game.seasonTriggerBasePrice + G.cookiesPsUnbuffed * 60 * pow(1.5, G.seasonUses) * m
            }
        }
    }
    func computeSeasons() {
        for s in seasonsList { s.triggerUpgrade.pool = "toggle" }
    }
    func getSeasonDuration() -> Double { 60 * 60 * 24 * 1000 }
    func switchSeason(_ s: String? = nil) {
        if let s = s, s != "" {
            if season != s { toast(seasons[s]!.start, "", seasons[s]!.triggerUpgrade.icon) }
            season = s
            seasonT = nowMs() + getSeasonDuration()
        } else {
            if season != "", let cur = seasons[season] { toast(cur.over, "", cur.triggerUpgrade.icon) }
            season = ""
            seasonT = 0
        }
    }
    func logicSeasons(_ delta: Double) {
        let prevSeason = season
        if nowMs() >= lastSeasonCheck + 1000 * 60 {
            baseSeason = getBaseSeason()
            if season == "" { season = baseSeason }
            lastSeasonCheck = nowMs()
        }
        if season != "" && season != baseSeason && seasonT <= nowMs() {
            if let cur = seasons[season] { toast(cur.over, "", cur.triggerUpgrade.icon) }
            season = baseSeason
            seasonT = 0
        }
        if prevSeason != season && season != "", let cur = seasons[season] {
            toast(cur.start, "", cur.triggerUpgrade.icon)
        }
    }

    // MARK: drops
    static let santaDrops = ["Increased merriness", "Improved jolliness", "A lump of coal", "An itchy sweater", "Reindeer baking grounds", "Weighted sleighs", "Ho ho ho-flavored frosting", "Season savings", "Toy workshop", "Naughty list", "Santa's bottomless bag", "Santa's helpers", "Santa's legacy", "Santa's milk and cookies"]
    static let reindeerDrops = ["Christmas tree biscuits", "Snowflake biscuits", "Snowman biscuits", "Holly biscuits", "Candy cane biscuits", "Bell biscuits", "Present biscuits"]
    static let heartDrops = ["Pure heart biscuits", "Ardent heart biscuits", "Sour heart biscuits", "Weeping heart biscuits", "Golden heart biscuits", "Eternal heart biscuits", "Prism heart biscuits"]
    static let easterEggs = ["Chicken egg", "Duck egg", "Turkey egg", "Quail egg", "Robin egg", "Ostrich egg", "Cassowary egg", "Salmon roe", "Frogspawn", "Shark egg", "Turtle egg", "Ant larva", "Golden goose egg", "Faberge egg", "Wrinklerspawn", "Cookie egg", "Omelette", "Chocolate egg", "Century egg", "\"egg\""]
    static let eggDrops = ["Chicken egg", "Duck egg", "Turkey egg", "Quail egg", "Robin egg", "Ostrich egg", "Cassowary egg", "Salmon roe", "Frogspawn", "Shark egg", "Turtle egg", "Ant larva"]
    static let rareEggDrops = ["Golden goose egg", "Faberge egg", "Wrinklerspawn", "Cookie egg", "Omelette", "Chocolate egg", "Century egg", "\"egg\""]
    static let halloweenDrops = ["Skull cookies", "Ghost cookies", "Bat cookies", "Slime cookies", "Pumpkin cookies", "Eyeball cookies", "Spider cookies"]
    static var seasonDrops: [String] { heartDrops + halloweenDrops + easterEggs + santaDrops + reindeerDrops }

    func GetHowManySantaDrops() -> Int { Game.santaDrops.filter { isUnlocked($0) }.count }
    func GetHowManyReindeerDrops() -> Int { Game.reindeerDrops.filter { isUnlocked($0) }.count }
    func GetHowManyHeartDrops() -> Int { Game.heartDrops.filter { isUnlocked($0) }.count }
    func GetHowManyEggs() -> Int { Game.easterEggs.filter { isUnlocked($0) }.count }
    func GetHowManyHalloweenDrops() -> Int { Game.halloweenDrops.filter { isUnlocked($0) }.count }

    func DropSanta() {
        let drops = Game.santaDrops.filter { !isUnlocked($0) }
        if let drop = chooseOpt(drops) {
            unlock(drop)
            toast("<b>" + upgradesBN[drop]!.name + "</b>!", "You find a present which contains...", upgradesBN[drop]!.icon)
        }
    }
    private func seasonsGodFail(_ f: inout Double) {
        let godLvl = hasGod("seasons")
        if godLvl == 1 { f *= 0.9 }
        else if godLvl == 2 { f *= 0.95 }
        else if godLvl == 3 { f *= 0.97 }
    }
    func DropReindeer(_ failRateIn: Double) {
        if season != "christmas" { return }
        var failRate = failRateIn
        if HasAchiev("Let it snow") { failRate *= 0.6 }
        if Has("Starsnow") { failRate *= 0.95 }
        failRate *= 1 / dropRateMult()
        seasonsGodFail(&failRate)
        if JSMath.random() >= failRate {
            let drop = choose(Game.reindeerDrops)
            if Has(drop) || HasUnlocked(drop) { return }
            unlock(drop)
            toast("<b>" + upgradesBN[drop]!.name + "</b>", "The reindeer gives you:", upgradesBN[drop]!.icon)
        }
    }
    func DropEgg(_ failRateIn: Double) {
        if season != "easter" { return }
        var failRate = failRateIn
        failRate *= 1 / dropRateMult()
        if HasAchiev("Hide & seek champion") { failRate *= 0.7 }
        if Has("Omelette") { failRate *= 0.9 }
        if Has("Starspawn") { failRate *= 0.9 }
        seasonsGodFail(&failRate)
        if JSMath.random() >= failRate {
            var drop = JSMath.random() < 0.1 ? choose(Game.rareEggDrops) : choose(Game.eggDrops)
            if Has(drop) || HasUnlocked(drop) {
                drop = JSMath.random() < 0.1 ? choose(Game.rareEggDrops) : choose(Game.eggDrops)
            }
            if Has(drop) || HasUnlocked(drop) { return }
            unlock(drop)
            toast("<b>" + upgradesBN[drop]!.name + "</b>", "You found an egg!", upgradesBN[drop]!.icon)
        }
    }
    func DropHalloween(_ failRateIn: Double) {
        if season != "halloween" { return }
        var failRate = failRateIn
        if HasAchiev("Spooky cookies") { failRate *= 0.8 }
        if Has("Starterror") { failRate *= 0.9 }
        failRate *= 1 / dropRateMult()
        seasonsGodFail(&failRate)
        if JSMath.random() >= failRate {
            let drop = choose(Game.halloweenDrops)
            if Has(drop) || HasUnlocked(drop) { return }
            unlock(drop)
            toast("<b>" + upgradesBN[drop]!.name + "</b>", "You found:", upgradesBN[drop]!.icon)
        }
    }
    func dropRateMult() -> Double { (1 + pool["dropChanceA"]!) * pool["dropChanceM"]! }

    /// G.addPostData (seasons): season prices, santa and egg upgrade prices
    func seasonsPostData() {
        computeSeasons()
        for d in Game.santaDrops { upgradesBN[d]?.costFunc = { _ in pow(3, Double(G.santaLevel)) * 2525 } }
        for d in Game.eggDrops { upgradesBN[d]?.costFunc = { _ in pow(2, Double(G.GetHowManyEggs())) * 999 } }
        for d in Game.rareEggDrops { upgradesBN[d]?.costFunc = { _ in pow(3, Double(G.GetHowManyEggs())) * 999 } }
    }
}
