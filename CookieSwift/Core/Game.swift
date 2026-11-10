import Foundation

/// The whole game, like the original's global "G" object.
/// Split across files the same way the original main.js is split in sections.
let G = Game()

final class Game {
    static let version = 8.0          // VERSION (the mobile game's version number)

    // MARK: framework (lib/main.js)
    var T = 0
    var drawT = 0
    let fps = 30.0
    var hasFocus = true
    var w = 320.0, h = 693.0          // the game is laid out 320 px wide, then scaled to the screen
    var scale = 1.0

    // MARK: content
    var buildings: [Building] = []
    var buildingsBN: [String: Building] = [:]
    var upgrades: [Upgrade] = []
    var upgradesBN: [String: Upgrade] = [:]
    var upgradesBID: [Int: Upgrade] = [:]
    var upgradePools: [String: [Upgrade]] = [:]
    var upgradeTiers: [String: [Upgrade]] = [:]
    var lastingUpgrades: [String] = []
    var achievs: [Achiev] = []
    var achievsBN: [String: Achiev] = [:]
    var achievsBID: [Int: Achiev] = [:]
    var tiers: [String: Tier] = [:]
    var HeavenlyUpgradePositions: [Int: [Double]] = [:]
    var HeavenlyUpgradeParents: [Int: [Int]] = [:]
    var HeavenlyUpgradeChildren: [Int: [Int]] = [:]
    var AllMilks: [Milk] = []
    var milks: [Milk] = []
    let costIncrease = 1.15

    // MARK: saved stats (savedVars)
    var lastVersion = Game.version
    var runStart = 0.0, gameStart = 0.0
    var seed = "aaaaa"
    var cookies = 0.0, cookiesEarned = 0.0, cookiesTotal = 0.0, cookiesHandmade = 0.0
    var cookieClicks = 0.0
    var gcClicks = 0.0, gcClicksTotal = 0.0, gcMissed = 0.0
    var reindeerClicks = 0.0, reindeerClicksTotal = 0.0, reindeerMissed = 0.0
    var elderWrath = 0
    var pledges = 0.0, pledgeT = 0.0
    var wrinklersPopped = 0.0, cookiesSucked = 0.0
    var cookiesReset = 0.0
    var heavenlyChips = 0.0, heavenlyChipsSpent = 0.0
    var resets = 0.0
    var seasonT = 0.0, seasonUses = 0.0
    var season = ""
    var santaLevel = 0
    var dragonLevel = 0, dragonAura = 0, dragonAura2 = 0
    var fortuneGC = 0, fortuneCPS = 0
    var powerClicks = 0.0, powerClicksTotal = 0.0
    var bgType = 0, milkType = 0, chimeType = 0
    var quickButtons: [String] = []
    var tippedN = 0
    // sugar lumps mod
    var lumps = 0.0, lumpsTotal = 0.0, lumpT = 0.0, lumpCurrentType = 0, lumpRefill = 0.0
    var cookiesPsRawHighest = 0.0

    var researchT = 0.0, researchTM = 0.0
    var researchUpgrade: Upgrade? = nil
    var researchUpgradeLast: Upgrade? = nil
    var permanentUpgrades = [-1, -1, -1, -1, -1]

    // MARK: runtime
    var pool: [String: Double] = [:]
    var refreshCps = true
    var cookiesPs = 0.0, cookiesPsUnbuffed = 0.0, cookiesPc = 1.0, cpsSucked = 0.0
    var cookiesD = 0.0
    var prestige = 0.0, gainedPrestige = 0.0
    var heavenlyChipsD = 0.0
    var upgradesN = 0, achievsN = 0, buildingsN = 0, buildingsNmin = 0
    var recentUpgrades: [Upgrade] = []
    var recentAchievs: [Achiev] = []
    var powerClicksOn = false
    var lastPowerClickUse = 0.0, lastPowerClickAttempt = 0.0
    var onAscend = 0
    var lastResetTimestamp = 0.0
    var bulkBuy = 1, bulkMode = 1
    var intro = 0
    var milkLevel = 0.0
    var elderWrathD = 0.0
    var savedToasts: [SavedToast] = []
    var savedNews: [(String, Double)] = []
    var volume = 100.0

    // MARK: more runtime state (each section of main.js keeps its own)
    var upgradesTotal = 0, achievsTotal = 0
    var pendingUnlocks: [(Upgrade?, Achiev?, [String: Any])] = []
    var unimplementedUpgrades: Set<String> = []
    var unimplementedAchievs: Set<String> = []
    var goldenCookieUpgrades: [Upgrade] = []
    // buffs and shimmers
    var buffTypes: [BuffType] = []
    var buffTypesBN: [String: BuffType] = [:]
    var buffs: [Buff] = []
    var shimmerTypes: [ShimmerType] = []
    var shimmerTypesBN: [String: ShimmerType] = [:]
    var shimmers: [Shimmer] = []
    var explodeT = -1
    // wrinklers
    var wrinklers: [Wrinkler] = []
    var wrinklersPosX = -1000.0, wrinklersPosY = -1000.0
    var wrinklerSquishSound = Int((JSMath.random() * 4).rounded(.down)) + 1
    // pets and seasons
    var dragonLevels: [DragonLevel] = []
    var dragonAuras: [DragonAura] = []
    var dragonAurasBN: [String: DragonAura] = [:]
    var seasons: [String: Season] = [:]
    var seasonsList: [Season] = []
    var baseSeason = ""
    var lastSeasonCheck = 0.0
    // settings
    var settings: [String: Setting] = [:]
    var settingsOrder: [String] = []
    // screens
    let screenNames = ["cookie", "store", "special", "stats", "misc"]
    var onScreen = "cookie"
    var screenPing: [String: Bool] = [:]
    var screenTransitionT: [String: Double] = [:]
    var onPopup = 0
    var onStoreSection = "buildings"
    // the cookie screen
    var bigCookieState = 0
    var bigCookieClicked = false
    var bigCookieSize = 0.0
    var bigCookieSizeD = 0.0
    var bigCookieSizeT = 1.0
    var cookieClickSound = Int((JSMath.random() * 7).rounded(.down)) + 1
    let freeCookie = FreeCookie()
    var canPan = true
    var panning = false
    var panTo = 0.0
    var onX = 0.0, onY = 0.0
    // particles, sparkles, ticker
    var particles: [Particle] = []
    var pendingParticles: [Particle] = []
    var particleI = 0
    var sparklesT = 0
    var sparkleX = 0.0, sparkleY = 0.0
    let sparklesFrames = 16
    var ticker1 = TickerLine(), ticker2 = TickerLine()
    var bg = BGState()
    var tickerN = 0
    var recentTips: [String] = []

    init() {}

    // MARK: lookups
    func Has(_ name: String) -> Bool { (upgradesBN[name]?.owned ?? 0) != 0 }
    func isUnlocked(_ name: String) -> Bool { (upgradesBN[name]?.unlocked ?? 0) != 0 }
    func HasUnlocked(_ name: String) -> Bool { isUnlocked(name) }
    func HasAchiev(_ name: String) -> Bool { (achievsBN[name]?.owned ?? 0) != 0 }
    func hasAchiev(_ name: String) -> Bool { HasAchiev(name) }
    func buildingN(_ name: String) -> Int { buildingsBN[name]?.amount ?? 0 }
    func unlock(_ name: String) { upgradesBN[name]?.unlock() }
    func lock(_ name: String) { upgradesBN[name]?.lock() }
    func toggleOff(_ name: String) { upgradesBN[name]?.toggleOff() }
    func toggleOn(_ name: String) { upgradesBN[name]?.toggleOn() }
    func win(_ name: String) { achievsBN[name]?.win() }
    func p(_ k: String) -> Double { pool[k] ?? 0 }

    // MARK: earning (G.earn / G.spend / G.dissolve)
    func earn(_ n: Double) { cookies += n; cookiesEarned += n; cookiesTotal += n }
    func spend(_ n: Double) { cookies -= n; cookies = max(0, cookies) }
    func dissolve(_ n: Double) {
        cookies -= n; cookies = max(0, cookies)
        cookiesEarned -= n; cookiesEarned = max(0, cookiesEarned)
    }

    // MARK: pools (G.resetPools)
    func resetPools() {
        var p: [String: Double] = [:]
        p["cpsA"] = 0; p["cpsM"] = 1
        p["cpsBuffA"] = 0; p["cpsBuffM"] = 1
        p["clickA"] = 1; p["clickM"] = 1
        p["gcFreqA"] = 0; p["gcFreqM"] = 1
        p["gcLifeA"] = 0; p["gcLifeM"] = 1
        p["gcWrathLifeA"] = 0; p["gcWrathLifeM"] = 1
        p["gcEffectsLifeA"] = 0; p["gcEffectsLifeM"] = 1
        p["gcWrathEffectsLifeA"] = 0; p["gcWrathEffectsLifeM"] = 1
        p["gcEffectsMultA"] = 0; p["gcEffectsMultM"] = 1
        p["gcWrathEffectsMultA"] = 0; p["gcWrathEffectsMultM"] = 1
        p["buildingCostA"] = 0; p["buildingCostM"] = 1
        p["upgradeCostA"] = 0; p["upgradeCostM"] = 1
        p["reindeerLifeA"] = 0; p["reindeerLifeM"] = 1
        p["reindeerFreqA"] = 0; p["reindeerFreqM"] = 1
        p["reindeerEffectsMultA"] = 0; p["reindeerEffectsMultM"] = 1
        p["dropChanceA"] = 0; p["dropChanceM"] = 1
        p["milkPowerA"] = 0; p["milkPowerM"] = 1
        p["pseudoKitten"] = 1
        p["pcMultA"] = 2
        p["pcRateA"] = 30
        p["pcCapA"] = 5
        p["pcBuffMultA"] = 1.05
        p["pcBuffDurA"] = 10
        for i in 0..<buildings.count {
            p["building\(i)A"] = 0
            p["building\(i)M"] = 1
            p["buildingCost\(i)A"] = 0
            p["buildingCost\(i)M"] = 1
            p["building\(i)Free"] = 0
        }
        pool = p
    }
    private func applyEff(_ e: Eff) { pool[e.pool] = e.apply(pool[e.pool] ?? 0) }

    // MARK: G.computeCps
    func computeCps() {
        resetPools()
        for me in upgrades where me.owned != 0 { for e in me.effs { applyEff(e) } }
        for me in buffs { for e in me.effs { applyEff(e) } }

        // minigame effects (garden, pantheon) - the mods apply them right here
        Minigames.applyEffects(&pool)

        pool["clickM"]! *= 1 + auraMult("Dragon Cursor") * 0.05
        pool["milkPowerM"]! *= 1 + auraMult("Breath of Milk") * 0.05
        pool["cpsM"]! *= 1 + auraMult("Radiant Appetite")
        let n = shimmerTypesBN["golden"]!.n
        let am = auraMult("Dragon's Fortune")
        if n > 0 { for _ in 0..<n { pool["cpsM"]! *= 1 + am * 1.23 } }
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

        let prestigeMult = 1 + 0.01 * prestige * GetHeavenlyMultiplier()
        let cursedFinger = hasBuff("cursedFinger")

        let milk = Double(achievsN) / 25
        var milkPower = 1.0
        milkPower = (milkPower + pool["milkPowerA"]!) * pool["milkPowerM"]!
        for u in upgradePools["kitten"] ?? [] where u.owned != 0 {
            pool["cpsM"]! *= 1 + u.getPower() * milk * milkPower
        }
        for u in upgradePools["pseudoKitten"] ?? [] where u.owned != 0 {
            guard let eff = u.effs.first(where: { $0.pool == "pseudoKitten" }) else { continue }
            pool["cpsM"]! *= 1 + (eff.value - 1) * milk * milkPower
        }

        var cps = 0.0
        for me in buildings {
            var myCps = me.cps
            // sugar lumps mod: +1% per building level
            myCps = (myCps + pool["building\(me.id)A"]!) * pool["building\(me.id)M"]! * (1 + Double(me.level) * 0.01)
            me.storedCps = myCps * (cursedFinger != nil ? 0 : 1) * pool["cpsM"]! * pool["cpsBuffM"]! * prestigeMult
            myCps *= Double(me.amount)
            cps += myCps
        }

        var sucking = 0
        for w in wrinklers where w.phase == 2 { sucking += 1 }
        var suckRate = 1.0 / 20
        suckRate *= 1 + auraMult("Dragon Guts") * 0.2
        cpsSucked = Double(sucking) * suckRate

        cps = cps * pool["cpsM"]! + pool["cpsA"]!
        cps *= prestigeMult
        cookiesPsUnbuffed = cps
        cps = (cps + pool["cpsBuffA"]!) * pool["cpsBuffM"]!
        let oldCps = cps
        if cursedFinger != nil { cps = 0 }
        cookiesPs = cps

        var cpc = 0.0
        if let cf = cursedFinger { cpc = oldCps * cf.tm }
        else {
            var mouseBonusFromCps = 0.0
            for me in upgradePools["mouse"] ?? [] where me.owned != 0 { mouseBonusFromCps += cookiesPs * 0.01 }
            if Has("Fortune #104") { mouseBonusFromCps += cookiesPs * 0.01 }
            cpc = (pool["clickA"]! + mouseBonusFromCps) * pool["clickM"]!
        }
        cookiesPc = cpc
        // the app's sugar-lump/minigame mod tracks the highest raw CpS (for the Stock Market)
        cookiesPsRawHighest = max(cookiesPsRawHighest, cookiesPsUnbuffed)
    }

    // MARK: power clicks
    func getAngels() -> Int { ["Angels", "Archangels", "Virtues", "Dominions", "Cherubim", "Seraphim", "God"].filter { Has($0) }.count }
    func getDemons() -> Int { ["Belphegor", "Mammon", "Abaddon", "Satan", "Asmodeus", "Beelzebub", "Lucifer"].filter { Has($0) }.count }
    /// G.usePowerClick; returns the click multiplier. `onBlocked`/`onUsed` let the screen animate.
    func usePowerClick() -> Double {
        var mult = 1.0
        let blocked = hasBuff("clickFrenzy") != nil
        if blocked { UIEvents.shared.plopBuff("clickFrenzy") }
        if powerClicks < 1 {}
        else if blocked {
            if nowMs() - lastPowerClickAttempt > 5 * 1000 { PlaySound("snd/bomp.mp3") }
            UIEvents.shared.plopQuickButton("powerClicks", heavy: false)
        } else {
            spendPowerClick()
            powerClicksTotal += 1
            let demons = Double(getDemons())
            mult *= (pool["pcMultA"]! + demons) * (1 + auraMult("Dragon Cursor") * 0.05)
            let pw = (pool["pcBuffMultA"]! + 0.01 * demons) * (1 + auraMult("Dragon Cursor") * 0.05)
            addBuff("powerClick", t: pool["pcBuffDurA"]! + 5 * demons, pow: pw)
            PlaySound("snd/powerClick" + choose(["1", "2", "3"]) + "b.mp3", 0.4 - JSMath.random() * 0.3)
            particleAt(Particle(x: w / 2, y: h / 2 - 32, s: 2 + JSMath.random() * 1, sd: 1.1 + JSMath.random() * 0.1, r: 0, grav: 0, a: 1, life: 0.3, pic: .image("img/ripple.png")))
            bigCookieSizeD = -0.1
            bigCookieSize = 0.75
        }
        lastPowerClickAttempt = nowMs()
        return mult
    }
    func spendPowerClick() {
        if powerClicks >= 1 {
            powerClicks -= 1
            lastPowerClickUse = nowMs()
            UIEvents.shared.plopQuickButton("powerClicks", heavy: false)
        }
    }
    func getPowerClickCapacity() -> Double {
        if !Has("Power clicks") { return 0 }
        return (pool["pcCapA"]! + Double(getAngels()) * 5 + auraMult("Dragon Cursor") * 5).rounded(.up)
    }
    func getPowerClicksPs() -> Double {
        if !Has("Power clicks") { return 0 }
        return 60.0 / 60 / max(1, pool["pcRateA"]! - Double(getAngels()) * 2) / 60
    }
    func earnPowerClicks(_ seconds: Double) {
        let old = powerClicks
        powerClicks += getPowerClicksPs() * seconds
        powerClicks = max(old, max(0, min(powerClicks, getPowerClickCapacity())))
    }

    // MARK: buildings
    func computeBuildingAmounts() {
        buildingsN = 0
        buildingsNmin = 100000
        for me in buildings {
            buildingsN += me.amount
            buildingsNmin = min(buildingsNmin, me.amount)
        }
    }
    func modifyBuildingCost(_ b: Building, _ c: Double) -> Double {
        (c + pool["buildingCostA"]! + pool["buildingCost\(b.id)A"]!) * pool["buildingCostM"]! * pool["buildingCost\(b.id)M"]!
    }
    func modifyUpgradeCost(_ u: Upgrade, _ c: Double) -> Double {
        var cost = (c + pool["upgradeCostA"]!) * pool["upgradeCostM"]!
        if u.pool == "cookie" && Has("Divine bakeries") { cost /= 5 }
        if u.pool == "kitten" && Has("Kitten wages") { cost *= 0.9 }
        return cost
    }
    func getTieredIcon(_ type: String, _ tier: String) -> [Int] {
        let col = type == "Kitten" ? 18 : buildingsBN[type]!.icon[0]
        return [col, tiers[tier]!.iconRow]
    }
    /// hooks the minigames and mods use when buildings change hands
    func onBuildingBought(_ b: Building) { Minigames.onBuy(b) }
    func onBuildingSold(_ b: Building, _ n: Int) { Minigames.onSell(b, n) }

    // MARK: unlocks (G.doUnlocks)
    private var doUnlocksI = 0
    func doUnlocks(_ everyIn: Int = 1) {
        let every = max(1, everyIn)
        doUnlocksI = doUnlocksI % every
        let initial = every == 1 ? 0 : doUnlocksI
        if every > 1 { doUnlocksI += 1 }
        let len = upgrades.count + achievs.count
        var i = initial
        while i < len {
            if i < upgrades.count {
                let me = upgrades[i]
                if me.unlocked == 0 && me.owned == 0, let req = me.unlockAt, checkUnlock(req) { me.unlock() }
            } else {
                let me = achievs[i - upgrades.count]
                if me.owned == 0, let req = me.unlockAt, checkUnlock(req) { me.win() }
            }
            i += every
        }
    }
    private func checkUnlock(_ req: UnlockAt) -> Bool {
        if cookiesEarned < req.cookies { return false }
        if cookiesPsUnbuffed < req.cps { return false }
        if Double(achievsN) / 25 < req.milk { return false }
        for (b, n) in req.buildings { if n != -1 && b.amount < n { return false } }
        for u in req.upgrades { if u.owned == 0 { return false } }
        for a in req.achievs { if a.owned == 0 { return false } }
        if let spe = req.spe, !spe() { return false }
        return true
    }

    // MARK: heavenly chips (G.HowMuchPrestige etc)
    func HowMuchPrestige(_ cookies: Double) -> Double { pow(cookies / 1_000_000_000_000, 1.0 / 3) }
    func HowManyCookiesReset(_ chips: Double) -> Double { pow(chips, 3) * 1_000_000_000_000 }
}

/// A toast kept in the log (G.savedToasts)
struct SavedToast { let title: String; let text: String; let icon: [Int]?; let time: Double }
