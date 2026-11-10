import Foundation

// Port of www/main.js: SAVE & LOAD, RESET, SETTINGS, the LOGIC loop, ASCENDING (logic parts),
// plus the 30-fps loop from www/lib/main.js.

final class Setting {
    let name: String
    let base: Int
    var val: Int
    init(_ name: String, _ base: Int) { self.name = name; self.base = base; self.val = base }
}

extension Game {
    static let savedVars = ["lastVersion", "runStart", "gameStart", "seed", "cookies", "cookiesEarned", "cookiesTotal", "cookiesHandmade", "cookieClicks", "gcClicks", "gcClicksTotal", "gcMissed", "reindeerClicks", "reindeerClicksTotal", "reindeerMissed", "elderWrath", "pledges", "pledgeT", "wrinklersPopped", "cookiesSucked", "cookiesReset", "heavenlyChips", "heavenlyChipsSpent", "resets", "seasonT", "seasonUses", "season", "santaLevel", "dragonLevel", "dragonAura", "dragonAura2", "fortuneGC", "fortuneCPS", "powerClicks", "powerClicksTotal", "bgType", "milkType", "chimeType", "quickButtons", "tippedN",
        // the app's sugar lumps mod adds these
        "lumps", "lumpsTotal", "lumpT", "lumpCurrentType", "lumpRefill", "cookiesPsRawHighest"]

    // MARK: settings (G.settings)
    func initSettings() {
        settings = [:]
        settingsOrder = ["fancy", "particles", "cookiepops", "cookiewobble", "lowMotion", "cursors", "diagnostic", "debug", "sound", "pan", "dislodge", "shadows", "milk", "notScary"]
        let bases: [String: Int] = ["fancy": 1, "particles": 1, "cookiepops": 1, "cookiewobble": 1, "lowMotion": 0, "cursors": 1, "diagnostic": 0, "debug": 0, "sound": 1, "pan": 0, "dislodge": 1, "shadows": 0, "milk": 1, "notScary": 0]
        for k in settingsOrder { settings[k] = Setting(k, bases[k]!) }
    }
    func getSet(_ name: String) -> Int {
        guard let me = settings[name] else { return 0 }
        if name == "diagnostic" || name == "debug" { return 0 }   // override: DEV is off
        return me.val
    }
    func setSet(_ name: String, _ valIn: Int) {
        guard let me = settings[name] else { return }
        var val = valIn
        if name == "diagnostic" || name == "debug" { val = 0 }
        me.val = val
        UIEvents.shared.settingChanged(name)
    }
    func resetSettings() { for k in settingsOrder { setSet(k, settings[k]!.base) } }

    // MARK: quick buttons
    static let quickButtonsPos: [[Double]] = [[10, 10], [0, 52], [52, 0], [42, 42]]
    func quickButtonCond(_ id: String) -> Bool {
        switch id {
        case "none": return true
        case "powerClicks": return Has("Power clicks")
        case "goldenSwitch": return Has("Golden switch")
        case "dragonAura1": return dragonLevel >= 5
        case "dragonAura2": return dragonLevel == dragonLevels.count - 1
        case "seasonSwitcher": return Has("Season switcher")
        default: return false
        }
    }
    static let quickButtonOptions: [(id: String, name: String, icon: [Int])] = [
        ("none", "None", [0, 7]), ("powerClicks", "Power clicks", [30, 36]), ("goldenSwitch", "Golden switch", [20, 10]),
        ("dragonAura1", "Dragon aura", [30, 12]), ("dragonAura2", "Dragon aura 2", [30, 12]), ("seasonSwitcher", "Season switcher", [16, 6]),
    ]
    func resetQuickButtons() { quickButtons = Array(repeating: "none", count: Game.quickButtonsPos.count); quickButtons[0] = "powerClicks" }
    func loadQuickButtons() {
        if quickButtons.isEmpty { resetQuickButtons() }
        if quickButtons.count > Game.quickButtonsPos.count { quickButtons.removeLast(quickButtons.count - Game.quickButtonsPos.count) }
        let valid = Set(Game.quickButtonOptions.map { $0.id })
        for i in 0..<Game.quickButtonsPos.count {
            if i >= quickButtons.count { quickButtons.append("none") }
            if !valid.contains(quickButtons[i]) { quickButtons[i] = "none" }
        }
    }

    // MARK: G.Save
    func Save(toObj: Bool = false) -> [String: Any] {
        var o: [String: Any] = [:]
        o["time"] = nowMs()
        var s: [String: Any] = [:]
        for (k, v) in settings { s[k] = v.val }
        o["settings"] = s
        o["screen"] = onScreen
        lastVersion = Game.version
        for k in Game.savedVars { o[k] = savedValue(k) }
        o["researchT"] = researchT
        o["researchTM"] = researchTM
        o["researchUpgrade"] = researchUpgrade?.id ?? -1
        o["researchUpgradeLast"] = researchUpgradeLast?.id ?? -1
        o["permanentUpgrades"] = permanentUpgrades
        var bs: [String: Any] = [:]
        for b in buildings {
            bs[b.name] = ["amount": b.amount, "amountMax": b.amountMax, "bought": b.bought, "cookiesMade": b.cookiesMade,
                          "level": b.level, "minigameSave": b.minigameSave]
        }
        o["buildings"] = bs
        var us: [String: Any] = [:]
        for u in upgrades { us[String(u.id)] = (u.unlocked << 1) | u.owned }
        o["upgrades"] = us
        var ac: [String: Any] = [:]
        for a in achievs { ac[String(a.id)] = a.owned }
        o["achievs"] = ac
        o["buffs"] = buffs.map { ["type": $0.type.name, "tm": $0.tm, "t": $0.t, "p": $0.pow] as [String: Any] }
        o["shimmers"] = shimmerTypes.map { ["t": $0.n <= 0 ? $0.lastTime : -1] }
        o["wrinklers"] = saveWrinklers()
        if !toObj { SaveStore.write(o) }
        return o
    }
    private func savedValue(_ k: String) -> Any {
        switch k {
        case "lastVersion": return lastVersion
        case "runStart": return runStart
        case "gameStart": return gameStart
        case "seed": return seed
        case "cookies": return cookies
        case "cookiesEarned": return cookiesEarned
        case "cookiesTotal": return cookiesTotal
        case "cookiesHandmade": return cookiesHandmade
        case "cookieClicks": return cookieClicks
        case "gcClicks": return gcClicks
        case "gcClicksTotal": return gcClicksTotal
        case "gcMissed": return gcMissed
        case "reindeerClicks": return reindeerClicks
        case "reindeerClicksTotal": return reindeerClicksTotal
        case "reindeerMissed": return reindeerMissed
        case "elderWrath": return elderWrath
        case "pledges": return pledges
        case "pledgeT": return pledgeT
        case "wrinklersPopped": return wrinklersPopped
        case "cookiesSucked": return cookiesSucked
        case "cookiesReset": return cookiesReset
        case "heavenlyChips": return heavenlyChips
        case "heavenlyChipsSpent": return heavenlyChipsSpent
        case "resets": return resets
        case "seasonT": return seasonT
        case "seasonUses": return seasonUses
        case "season": return season
        case "santaLevel": return santaLevel
        case "dragonLevel": return dragonLevel
        case "dragonAura": return dragonAura
        case "dragonAura2": return dragonAura2
        case "fortuneGC": return fortuneGC
        case "fortuneCPS": return fortuneCPS
        case "powerClicks": return powerClicks
        case "powerClicksTotal": return powerClicksTotal
        case "bgType": return bgType
        case "milkType": return milkType
        case "chimeType": return chimeType
        case "quickButtons": return quickButtons
        case "tippedN": return tippedN
        case "lumps": return lumps
        case "lumpsTotal": return lumpsTotal
        case "lumpT": return lumpT
        case "lumpCurrentType": return lumpCurrentType
        case "lumpRefill": return lumpRefill
        case "cookiesPsRawHighest": return cookiesPsRawHighest
        default: return 0
        }
    }
    /// G[k]=o[k]||(o[k]===''?'':0)
    private func loadValue(_ k: String, _ v: Any?) {
        func num() -> Double {
            if let n = v as? NSNumber { let d = n.doubleValue; return d.isNaN ? 0 : d }
            if let s = v as? String { return s.isEmpty ? 0 : (Double(s) ?? 0) }
            return 0
        }
        func int() -> Int { let d = num(); return d.isFinite ? Int(d) : 0 }
        switch k {
        case "lastVersion": lastVersion = num()
        case "runStart": runStart = num()
        case "gameStart": gameStart = num()
        case "seed": seed = (v as? String) ?? (v.map { "\($0)" } ?? "")
        case "cookies": cookies = num()
        case "cookiesEarned": cookiesEarned = num()
        case "cookiesTotal": cookiesTotal = num()
        case "cookiesHandmade": cookiesHandmade = num()
        case "cookieClicks": cookieClicks = num()
        case "gcClicks": gcClicks = num()
        case "gcClicksTotal": gcClicksTotal = num()
        case "gcMissed": gcMissed = num()
        case "reindeerClicks": reindeerClicks = num()
        case "reindeerClicksTotal": reindeerClicksTotal = num()
        case "reindeerMissed": reindeerMissed = num()
        case "elderWrath": elderWrath = int()
        case "pledges": pledges = num()
        case "pledgeT": pledgeT = num()
        case "wrinklersPopped": wrinklersPopped = num()
        case "cookiesSucked": cookiesSucked = num()
        case "cookiesReset": cookiesReset = num()
        case "heavenlyChips": heavenlyChips = num()
        case "heavenlyChipsSpent": heavenlyChipsSpent = num()
        case "resets": resets = num()
        case "seasonT": seasonT = num()
        case "seasonUses": seasonUses = num()
        case "season": season = (v as? String) ?? ""
        case "santaLevel": santaLevel = int()
        case "dragonLevel": dragonLevel = int()
        case "dragonAura": dragonAura = int()
        case "dragonAura2": dragonAura2 = int()
        case "fortuneGC": fortuneGC = int()
        case "fortuneCPS": fortuneCPS = int()
        case "powerClicks": powerClicks = num()
        case "powerClicksTotal": powerClicksTotal = num()
        case "bgType": bgType = int()
        case "milkType": milkType = int()
        case "chimeType": chimeType = int()
        case "quickButtons": quickButtons = (v as? [Any])?.map { "\($0)" } ?? []
        case "tippedN": tippedN = int()
        case "lumps": lumps = num()
        case "lumpsTotal": lumpsTotal = num()
        case "lumpT": lumpT = num()
        case "lumpCurrentType": lumpCurrentType = int()
        case "lumpRefill": lumpRefill = num()
        case "cookiesPsRawHighest": cookiesPsRawHighest = num()
        default: break
        }
    }

    // MARK: G.LoadFromObject
    @discardableResult
    func LoadFromObject(_ o: [String: Any]) -> Bool {
        let time = (o["time"] as? NSNumber)?.doubleValue ?? 0
        let delta = (nowMs() - time) * fps / 1000
        if let s = o["settings"] as? [String: Any] {
            for (k, v) in s where settings[k] != nil { setSet(k, (v as? NSNumber)?.intValue ?? 0) }
        }
        for k in Game.savedVars { loadValue(k, o[k]) }

        researchT = (o["researchT"] as? NSNumber)?.doubleValue ?? 0
        researchTM = (o["researchTM"] as? NSNumber)?.doubleValue ?? 0
        let ru = (o["researchUpgrade"] as? NSNumber)?.intValue ?? -1
        researchUpgrade = ru != -1 ? upgradesBID[ru] : nil
        let rul = (o["researchUpgradeLast"] as? NSNumber)?.intValue ?? -1
        researchUpgradeLast = rul != -1 ? upgradesBID[rul] : nil
        permanentUpgrades = (o["permanentUpgrades"] as? [Any])?.map { ($0 as? NSNumber)?.intValue ?? -1 } ?? [-1, -1, -1, -1, -1]

        prestige = HowMuchPrestige(cookiesReset).rounded(.down)
        loadQuickButtons()

        if let bs = o["buildings"] as? [String: Any] {
            for (name, v) in bs {
                guard let b = buildingsBN[name], let d = v as? [String: Any] else { continue }
                b.amount = (d["amount"] as? NSNumber)?.intValue ?? 0
                b.amountMax = (d["amountMax"] as? NSNumber)?.intValue ?? 0
                b.bought = (d["bought"] as? NSNumber)?.intValue ?? 0
                b.cookiesMade = (d["cookiesMade"] as? NSNumber)?.doubleValue ?? 0
                b.level = (d["level"] as? NSNumber)?.intValue ?? 0
                b.minigameSave = (d["minigameSave"] as? String) ?? ""
            }
        }
        upgradesN = 0
        achievsN = 0
        if let us = o["upgrades"] as? [String: Any] {
            for (k, v) in us {
                guard let id = Int(k), let it = upgradesBID[id] else { continue }
                let n = (v as? NSNumber)?.intValue ?? 0
                it.unlocked = (n >> 1) & 1
                it.owned = n & 1
                if it.owned != 0 && it.pool != "toggle" && it.pool != "prestige" { upgradesN += 1 }
            }
        }
        if let ac = o["achievs"] as? [String: Any] {
            for (k, v) in ac {
                guard let id = Int(k), let it = achievsBID[id] else { continue }
                it.owned = (v as? NSNumber)?.intValue ?? 0
                if it.owned != 0 && it.pool != "shadow" { achievsN += 1 }
            }
        }
        for b in (o["buffs"] as? [[String: Any]]) ?? [] {
            guard let type = b["type"] as? String else { continue }
            addBuff(type, t: (b["t"] as? NSNumber)?.doubleValue, tm: (b["tm"] as? NSNumber)?.doubleValue,
                    pow: (b["p"] as? NSNumber)?.doubleValue, loaded: true)
        }
        let shs = (o["shimmers"] as? [[String: Any]]) ?? []
        for (i, me) in shs.enumerated() where i < shimmerTypes.count {
            let it = shimmerTypes[i]
            let t = (me["t"] as? NSNumber)?.doubleValue ?? -1
            it.lastTime = t != -1 ? t : nowMs()
            let mx = it.delayMod(it.delayMaxBase)
            if (nowMs() - it.lastTime) > mx * 1000 { it.lastTime = nowMs() - (JSMath.random() * mx * 1000).rounded(.down) }
        }
        loadWrinklers(o["wrinklers"], lastVersion)
        computeCps()
        for me in buildings { me.free = Int(pool["building\(me.id)Free"] ?? 0) }
        computeBuildingAmounts()
        setScreen((o["screen"] as? String) ?? "cookie", force: true)
        updateBG(true)
        Minigames.afterLoad()
        Logic(delta)
        return true
    }

    // MARK: G.Reset
    func makeSeed() -> String {
        let chars = Array("abcdefghijklmnopqrstuvwxyz").map(String.init)
        return (0..<5).map { _ in choose(chars) }.joined()
    }
    func Reset(_ hard: Bool) {
        UIEvents.shared.closeAllPopups()
        UIEvents.shared.closeAllToasts()
        savedToasts = []
        savedNews = []
        lastVersion = Game.version
        lastResetTimestamp = nowMs()
        runStart = nowMs()
        if hard { gameStart = nowMs() }
        seed = makeSeed()
        intro = 0
        milkLevel = 0
        let cookiesForfeited = cookiesEarned
        let currentCookies = cookies
        cookies = 0
        cookiesD = cookies
        if hard { cookiesReset = 0 }
        cookiesEarned = 0
        cookiesHandmade = 0
        if hard { cookiesTotal = 0 }
        cookiesPs = 0
        cookiesPsUnbuffed = 0
        cookiesPc = 1
        powerClicksOn = false
        powerClicks = 0
        gcClicks = 0
        reindeerClicks = 0
        if hard {
            gcClicksTotal = 0; gcMissed = 0
            reindeerClicksTotal = 0; reindeerMissed = 0
            cookieClicks = 0
            powerClicksTotal = 0
            setSet("dislodge", 1)
            recentAchievs = []
            bgType = 0; milkType = 0; chimeType = 0
            tippedN = 0
        }
        recentUpgrades = []
        fortuneGC = 0
        fortuneCPS = 0
        onAscend = 0
        prestige = 0
        if !hard { prestige = HowMuchPrestige(cookiesReset).rounded(.down) }
        if hard {
            heavenlyChips = 0
            heavenlyChipsSpent = 0
            heavenlyChipsD = 0
            resets = 0
        } else if gainedPrestige > 0 { resets += 1 }
        gainedPrestige = 0
        resetWrinklers(hard)
        bulkBuy = 1
        bulkMode = 1
        buildingsN = 0
        buildingsNmin = 0
        for me in buildings { me.reset() }
        upgradesN = 0
        for me in upgrades where me.pool != "prestige" || hard {
            var isUnlocked = me.unlocked != 0
            me.reset()
            if !hard && isUnlocked {
                if lastingUpgrades.contains(me.name) {}
                else if Has("Keepsakes") && Game.seasonDrops.contains(me.name) && JSMath.random() < 1.0 / 5 {}
                else if HasAchiev("O Fortuna") && me.tier?.key == "fortune" && JSMath.random() < 0.4 {}
                else { isUnlocked = false }
                if isUnlocked { me.unlocked = 1 }
            }
        }
        if !hard {
            for me in upgradePools["prestige"] ?? [] where me.owned != 0 { me.funcB?(me, false) }
        }
        if hard {
            achievsN = 0
            for me in achievs { me.reset() }
        }
        for s in screenNames { unpingScreen(s) }
        if !hard {
            let thresholds: [(Double, String)] = [
                (1e6, "Sacrifice"), (1e9, "Oblivion"), (1e12, "From scratch"), (1e15, "Nihilism"), (1e18, "Dematerialize"),
                (1e21, "Nil zero zilch"), (1e24, "Transcendence"), (1e27, "Obliterate"), (1e30, "Negative void"),
                (1e33, "To crumbs, you say?"), (1e36, "You get nothing"), (1e39, "Humble rebeginnings"), (1e42, "The end of the world"),
                (1e45, "Oh, you're back"), (1e48, "Lazarus"), (1e51, "Smurf account"), (1e54, "If at first you don't succeed"), (1e57, "No more room in hell"),
            ]
            // the original writes these as integer literals; JS parses them to the nearest double, like these
            for (t, name) in thresholds where cookiesForfeited >= t { win(name) }
            if currentCookies.rounded(.down) == 1_000_000_000_000 { win("When the cookies ascend just right") }
        }
        researchT = 0
        researchTM = 0
        researchUpgrade = nil
        researchUpgradeLast = nil
        elderWrath = 0
        elderWrathD = 0
        pledges = 0
        pledgeT = 0
        resetBuffs()
        resetShimmers()
        resetPets(hard)
        resetSeasonData(hard)
        if hard { resetQuickButtons() }
        if hard { permanentUpgrades = [-1, -1, -1, -1, -1] }
        else {
            for id in permanentUpgrades where id != -1 { upgradesBID[id]?.forceBuy() }
        }
        Lumps.onReset(hard)
        Minigames.onReset(hard)
        computeCps()
        for me in buildings {
            me.free = Int(pool["building\(me.id)Free"] ?? 0)
            me.amount += me.free
            me.bought += me.free
        }
        computeBuildingAmounts()
        setScreen("cookie")
        updateBG(true)
    }

    // MARK: ascending (logic parts of the special screen)
    func EarnHeavenlyChips(_ cookiesForfeited: Double) {
        let p = HowMuchPrestige(cookiesReset + cookiesForfeited).rounded(.down)
        if p > prestige {
            let dif = p - prestige
            gainedPrestige = dif
            heavenlyChips += dif
            prestige = p
            toast("You gain <b>\(B(dif))</b> prestige level\(dif == 1 ? "" : "s")!", "You forfeit your \(B(cookiesForfeited)) cookie\(cookiesForfeited == 1 ? "" : "s").", [19, 7])
        }
    }
    func GetHeavenlyMultiplier() -> Double {
        var m = 0.0
        if Has("Heavenly chip secret") { m += 0.05 }
        if Has("Heavenly cookie stand") { m += 0.20 }
        if Has("Heavenly bakery") { m += 0.25 }
        if Has("Heavenly confectionery") { m += 0.25 }
        if Has("Heavenly key") { m += 0.25 }
        m *= 1 + auraMult("Dragon God") * 0.05
        // Dotjeiess (pantheon) - the minigames mod wraps this
        m *= Minigames.heavenlyMult()
        return m
    }
    /// G.showAscend: the game part (the screen part is in the UI)
    func showAscend(_ mode: Int) {
        onAscend = mode
        if onAscend == 1 {
            resetBuffs()
            resetShimmers()
            resetPools()
            EarnHeavenlyChips(cookiesEarned)
            cookiesReset += cookiesEarned
            PlaySound("snd/cymbalRev.mp3", 0.5)
            PlaySound("snd/choir.mp3")
        }
        UIEvents.shared.showAscend(mode)
    }
    func explodeThenAscend() {
        UIEvents.shared.closeAllPopups()
        explodeT = 0
        resetShimmers()
        setScreen("cookie", force: true)
        PlaySound("snd/charging.mp3")
    }
    /// Reincarnate button
    func reincarnate() {
        PlaySound("snd/smallTick.mp3", 1)
        UIEvents.shared.closeAllPopups()
        Reset(false)
        onAscend = 0
        setScreen("cookie", force: true)
        PlaySound("snd/pop\(Int((JSMath.random() * 3 + 1).rounded(.down))).mp3", 0.75)
        toast("Hello, cookies!", "", [10, 0])
    }

    // MARK: G.Logic
    func Logic(_ deltaIn: Double) {
        let delta = max(0, deltaIn)
        if sparklesT > 0 {
            sparklesT -= 1
        }
        particlesLogic(delta)
        if onAscend > 0 {
            heavenlyChipsD += (heavenlyChips - heavenlyChipsD) * 0.2
            if abs(heavenlyChips - heavenlyChipsD) < 0.01 { heavenlyChipsD = heavenlyChips }
        }
        if onAscend != 1 {
            screenLogic(delta)
            tickerLogic(delta)
            let oldCookies = cookies
            var breakpoints: [Double] = []
            for me in buffs where me.t * fps - delta <= 0 { breakpoints.append(me.t * fps) }
            if !breakpoints.isEmpty {
                breakpoints.append(delta)
                // the original sorts with a broken comparator, which leaves the list as it is
                for i in 0..<breakpoints.count {
                    var deltaStep = breakpoints[i]
                    if i > 0 { deltaStep -= breakpoints[i - 1] }
                    if refreshCps { computeCps(); refreshCps = false }
                    earn((cookiesPs / fps) * deltaStep)
                    logicBuffs(deltaStep)
                }
            } else {
                if T % Int(fps * 10) == 0 || refreshCps { computeCps(); refreshCps = false }
                earn((cookiesPs / fps) * delta)
                logicBuffs(delta)
            }
            if T % Int(fps) == 0 {
                if JSMath.random() < 1.0 / 1000000 { win("Just plain lucky") }
                if cookiesEarned >= 1e14 && !hasAchiev("You win a cookie") { win("You win a cookie"); earn(1) }
            }
            logicSeasons(delta)
            logicWrinklers(delta)
            // grandmapocalypse
            if buildingN("Grandma") == 0 || Has("Elder Covenant") || pledgeT > nowMs() {
                if elderWrath > 0 { collectWrinklers() }
                elderWrath = 0
            } else if elderWrath == 0 && Has("One mind") { elderWrath = 1 }
            else if JSMath.random() < 0.001 && elderWrath < (Has("One mind") ? 1 : 0) + (Has("Communal brainsweep") ? 1 : 0) + (Has("Elder Pact") ? 1 : 0) { elderWrath += 1 }

            if T % Int(fps) == 0 { doUnlocks(6) }

            var lastLocked = 0
            for me in buildings {
                me.cookiesMade += (me.storedCps / fps) * delta * Double(me.amount)
                if lastLocked >= 2 { me.locked = 2 }
                else if cookiesEarned >= me.baseCost || me.bought > 0 { me.locked = 0; lastLocked = 0 }
                else { me.locked = 1; lastLocked += 1 }
            }
            if explodeT > -1 { milkLevel += (0 - milkLevel) * 0.02 }
            else { milkLevel += (min(1, fullH / 640) - milkLevel) * 0.1 }
            cookiesD += (cookies - cookiesD) * 0.2
            if abs(cookies - cookiesD) < 0.01 { cookiesD = cookies }

            if delta / fps >= 30 {
                particlesClear()
                let cookieDif = cookies - oldCookies
                let time = (delta / fps) * 1000
                if cookieDif >= 1 {
                    toast("Welcome back!", "<div style=\"margin:2px 16px 8px 16px;\">You were away for \(sayTime(time)), and made <b>\(B(cookieDif))</b> cookie\(B(cookieDif) == "1" ? "" : "s").</div>", [10, 0], true)
                }
                earnPowerClicks(delta / fps)
            }
            if onScreen == "cookie" { cookieScreenLogic(delta) }
            logicShimmers(delta)
            // the app's mods: sugar lumps, minigames, auto-harvest
            Lumps.logic()
            Minigames.logic(delta)
            if T % Int(fps * Game.saveInterval) == 0 && (nowMs() - lastResetTimestamp) >= 1000 * 8 { _ = Save() }
        }
    }
    /// G._Logic (lib/main.js): the game's logic, then the frame counter
    func _Logic(_ delta: Double) {
        Logic(max(0, delta))
        T += 1
    }
    static let saveInterval = 5.0

    /// screens' logic function for the cookie screen (big cookie wobble, explosion, intro)
    func cookieScreenLogic(_ d: Double) {
        freeCookie.logic(d)
        if getSet("fancy") != 0 && getSet("cookiewobble") != 0 {
            if bigCookieState == 1 || bigCookieClicked { bigCookieSizeT = 0.95 }
            else if bigCookieState == 2 { bigCookieSizeT = 1.1 }
            else { bigCookieSizeT = 1 }
            bigCookieSizeD += (bigCookieSizeT - bigCookieSize) * 0.75
            bigCookieSizeD *= 0.75
            if bigCookieState != 1 && abs(bigCookieSizeD) < 0.0001 { bigCookieSizeD = 0; bigCookieSize = 1 }
            bigCookieSize += bigCookieSizeD
            bigCookieSize = max(0.1, bigCookieSize)
        }
        bigCookieClicked = false
        if explodeT > -1 {
            if explodeT == Int(fps * 2) { PlaySound("snd/thud.mp3") }
            explodeT += 1
            if explodeT >= Int(fps * 3) {
                explodeT = -1
                showAscend(1)
            }
        }
        if intro > -1 {
            intro += 1
            if intro >= Int(fps * 2) { intro = -1 }
        }
    }

    // MARK: big cookie click (cookie screen G.ondown)
    func clickBigCookie(x: Double, y: Double) {
        bigCookieState = 1
        bigCookieClicked = true
        var mult = 1.0
        if powerClicksOn && powerClicks >= 1 { mult *= usePowerClick() }
        let toEarn = cookiesPc * mult
        earn(toEarn)
        cookiesHandmade += toEarn
        cookieClicks += 1
        cookiesD = cookies
        let n = toEarn
        cookiePop(x + (JSMath.random() - 0.5) * 8, y + (JSMath.random() - 0.5) * 8)
        var str = "+" + B(n, 1)
        if mult > 1 { str += " <span style=\"font-size:75%;animation:chromaFocus 0.5s ease-out infinite;\">(x\(jsString(jsRound(mult * 1000) / 1000)))</span>" }
        particleAt(Particle(x: x, y: y, xd: JSMath.random() * 8 - 4, yd: -JSMath.random() * 3 - 5, str: str))
        playCookieClickSound()
        canPan = false
    }
    func releaseBigCookie() {
        bigCookieState = 0
        playCookieClickSound()
    }
    func playCookieClickSound() {
        PlaySound("snd/clickb\(cookieClickSound).mp3", 0.75)
        cookieClickSound += Int((JSMath.random() * 4).rounded(.down)) + 1
        if cookieClickSound > 7 { cookieClickSound -= 7 }
    }
}
