import Foundation

struct GameSettings {
    var vals: [String: Int] = ["fancy": 1, "particles": 1, "cookiepops": 1, "cookiewobble": 1, "lowMotion": 0, "cursors": 1,
                               "diagnostic": 0, "debug": 0, "sound": 1, "pan": 0, "dislodge": 1, "shadows": 0, "milk": 1, "notScary": 0]
    var volume = 100
    subscript(_ k: String) -> Bool {
        get { (vals[k] ?? 0) != 0 }
        set { vals[k] = newValue ? 1 : 0 }
    }
    var notScary: Bool { self["notScary"] }
}

/// Saving and loading, in the same JSON layout as the original game's save,
/// so saves can move between this app and the original one (QR code, backups, files).
extension Game {
    static var saveURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("CookieClickerSave.txt")
    }
    static var prevSaveURL: URL { saveURL.deletingLastPathComponent().appendingPathComponent("CookieClickerSavePrev.txt") }

    func saveObject() -> [String: Any] {
        var o: [String: Any] = [:]
        o["time"] = now()
        o["settings"] = settings.vals
        o["screen"] = "cookie"
        lastVersion = 8.0
        let vars: [String: Any] = [
            "lastVersion": lastVersion, "runStart": runStart, "gameStart": gameStart, "seed": seed,
            "cookies": cookies, "cookiesEarned": cookiesEarned, "cookiesTotal": cookiesTotal, "cookiesHandmade": cookiesHandmade,
            "cookieClicks": cookieClicks, "gcClicks": gcClicks, "gcClicksTotal": gcClicksTotal, "gcMissed": gcMissed,
            "reindeerClicks": reindeerClicks, "reindeerClicksTotal": reindeerClicksTotal, "reindeerMissed": reindeerMissed,
            "elderWrath": elderWrath, "pledges": pledges, "pledgeT": pledgeT, "wrinklersPopped": wrinklersPopped, "cookiesSucked": cookiesSucked,
            "cookiesReset": cookiesReset, "heavenlyChips": heavenlyChips, "heavenlyChipsSpent": heavenlyChipsSpent, "resets": resets,
            "seasonT": seasonT, "seasonUses": seasonUses, "season": season, "santaLevel": santaLevel, "dragonLevel": dragonLevel,
            "dragonAura": dragonAura, "dragonAura2": dragonAura2, "fortuneGC": fortuneGC, "fortuneCPS": fortuneCPS,
            "powerClicks": powerClicks, "powerClicksTotal": powerClicksTotal, "bgType": bgType, "milkType": milkType,
            "chimeType": chimeType, "quickButtons": quickButtons, "tippedN": tippedN,
            "lumps": lumps, "lumpsTotal": lumpsTotal, "lumpT": lumpT, "lumpCurrentType": lumpCurrentType, "lumpRefill": lumpRefill, "cookiesPsRawHighest": cookiesPsRawHighest,
        ]
        for (k, v) in vars { o[k] = v }
        o["researchT"] = researchT; o["researchTM"] = researchTM
        o["researchUpgrade"] = researchUpgrade?.id ?? -1; o["researchUpgradeLast"] = researchUpgradeLast?.id ?? -1
        o["permanentUpgrades"] = permanentUpgrades
        Minigames.shared.saveAll(self)
        var bo: [String: Any] = [:]
        for b in buildings {
            var d: [String: Any] = ["amount": b.amount, "amountMax": b.amountMax, "bought": b.bought, "cookiesMade": b.cookiesMade, "level": b.level]
            if !b.minigameSave.isEmpty { d["minigameSave"] = b.minigameSave }
            bo[b.def.name] = d
        }
        o["buildings"] = bo
        var uo: [String: Int] = [:]
        for u in upgrades { uo[String(u.id)] = (u.unlocked << 1) | u.owned }
        o["upgrades"] = uo
        var ao: [String: Int] = [:]
        for a in achievs { ao[String(a.id)] = a.owned }
        o["achievs"] = ao
        o["buffs"] = buffs.map { ["type": $0.type.name, "tm": $0.tm, "t": $0.t, "p": $0.pow] as [String: Any] }
        o["shimmers"] = shimmerTypes.map { ["t": $0.n <= 0 ? $0.lastTime : -1] }
        o["wrinklers"] = Wrinklers.shared.save()
        return o
    }

    func save() {
        let o = saveObject()
        guard let data = try? JSONSerialization.data(withJSONObject: o) else { return }
        let fm = FileManager.default
        if fm.fileExists(atPath: Game.saveURL.path) {
            try? fm.removeItem(at: Game.prevSaveURL)
            try? fm.copyItem(at: Game.saveURL, to: Game.prevSaveURL)
        }
        try? data.write(to: Game.saveURL, options: .atomic)
        onSave?(o)
    }

    private func num(_ o: [String: Any], _ k: String) -> Double {
        if let n = o[k] as? NSNumber { return n.doubleValue }
        if let s = o[k] as? String { return Double(s) ?? 0 }
        return 0
    }

    func load(from o: [String: Any]) {
        let delta = (now() - num(o, "time")) * Game.fps / 1000
        if let s = o["settings"] as? [String: Any] { for (k, v) in s { settings.vals[k] = (v as? NSNumber)?.intValue ?? 0 } }
        lastVersion = num(o, "lastVersion"); runStart = num(o, "runStart"); gameStart = num(o, "gameStart")
        seed = o["seed"] as? String ?? seed
        cookies = num(o, "cookies"); cookiesEarned = num(o, "cookiesEarned"); cookiesTotal = num(o, "cookiesTotal")
        cookiesHandmade = num(o, "cookiesHandmade"); cookieClicks = num(o, "cookieClicks")
        gcClicks = num(o, "gcClicks"); gcClicksTotal = num(o, "gcClicksTotal"); gcMissed = num(o, "gcMissed")
        reindeerClicks = num(o, "reindeerClicks"); reindeerClicksTotal = num(o, "reindeerClicksTotal"); reindeerMissed = num(o, "reindeerMissed")
        elderWrath = Int(num(o, "elderWrath")); pledges = num(o, "pledges"); pledgeT = num(o, "pledgeT")
        wrinklersPopped = num(o, "wrinklersPopped"); cookiesSucked = num(o, "cookiesSucked")
        cookiesReset = num(o, "cookiesReset"); heavenlyChips = num(o, "heavenlyChips"); heavenlyChipsSpent = num(o, "heavenlyChipsSpent")
        resets = num(o, "resets"); seasonT = num(o, "seasonT"); seasonUses = num(o, "seasonUses")
        season = o["season"] as? String ?? ""
        santaLevel = Int(num(o, "santaLevel")); dragonLevel = Int(num(o, "dragonLevel"))
        dragonAura = Int(num(o, "dragonAura")); dragonAura2 = Int(num(o, "dragonAura2"))
        fortuneGC = Int(num(o, "fortuneGC")); fortuneCPS = Int(num(o, "fortuneCPS"))
        powerClicks = num(o, "powerClicks"); powerClicksTotal = num(o, "powerClicksTotal")
        bgType = Int(num(o, "bgType")); milkType = Int(num(o, "milkType")); chimeType = Int(num(o, "chimeType"))
        quickButtons = o["quickButtons"] as? [Any] ?? []; tippedN = Int(num(o, "tippedN"))
        lumps = num(o, "lumps"); lumpsTotal = num(o, "lumpsTotal"); lumpT = num(o, "lumpT")
        lumpCurrentType = Int(num(o, "lumpCurrentType")); lumpRefill = num(o, "lumpRefill"); cookiesPsRawHighest = num(o, "cookiesPsRawHighest")
        researchT = num(o, "researchT"); researchTM = num(o, "researchTM")
        let ru = Int(num(o, "researchUpgrade")), rl = Int(num(o, "researchUpgradeLast"))
        researchUpgrade = (o["researchUpgrade"] != nil && ru != -1) ? upgradesBID[ru] : nil
        researchUpgradeLast = (o["researchUpgradeLast"] != nil && rl != -1) ? upgradesBID[rl] : nil
        permanentUpgrades = (o["permanentUpgrades"] as? [NSNumber])?.map { $0.intValue } ?? [-1, -1, -1, -1, -1]
        prestige = howMuchPrestige(cookiesReset).rounded(.down)

        if let bo = o["buildings"] as? [String: [String: Any]] {
            for (name, d) in bo {
                guard let b = buildingsBN[name] else { continue }
                b.amount = Int(num(d, "amount")); b.amountMax = Int(num(d, "amountMax")); b.bought = Int(num(d, "bought"))
                b.cookiesMade = num(d, "cookiesMade"); b.level = Int(num(d, "level"))
                b.minigameSave = d["minigameSave"] as? String ?? ""
            }
        }
        upgradesN = 0; achievsN = 0
        if let uo = o["upgrades"] as? [String: Any] {
            for (k, v) in uo {
                guard let id = Int(k), let u = upgradesBID[id] else { continue }
                let n = (v as? NSNumber)?.intValue ?? 0
                u.unlocked = (n >> 1) & 1; u.owned = n & 1
                if u.owned > 0 && u.pool != "toggle" && u.pool != "prestige" { upgradesN += 1 }
            }
        }
        if let ao = o["achievs"] as? [String: Any] {
            for (k, v) in ao {
                guard let id = Int(k), let a = achievsBID[id] else { continue }
                a.owned = (v as? NSNumber)?.intValue ?? 0
                if a.owned > 0 && a.def.pool != "shadow" { achievsN += 1 }
            }
        }
        for b in o["buffs"] as? [[String: Any]] ?? [] {
            addBuff(b["type"] as? String ?? "", t: num(b, "t"), tm: num(b, "tm"), pow: num(b, "p"), loaded: true)
        }
        for (i, s) in (o["shimmers"] as? [[String: Any]] ?? []).enumerated() where i < shimmerTypes.count {
            let st = shimmerTypes[i]
            let t = num(s, "t")
            st.lastTime = t != -1 ? t : now()
            let mx = shimmerDelayMod(st, st.delayMaxBase)
            if (now() - st.lastTime) > mx * 1000 { st.lastTime = now() - (rnd() * mx * 1000).rounded(.down) }
        }
        Wrinklers.shared.load(o["wrinklers"])
        Minigames.shared.loadAll(self)
        computeCps()
        for b in buildings { b.free = Int(p("building\(b.id)Free")) }
        computeBuildingAmounts()
        logic(delta)
    }

    func loadFromDisk() -> Bool {
        for url in [Game.saveURL, Game.prevSaveURL] {
            if let data = try? Data(contentsOf: url),
               let o = try? JSONSerialization.jsonObject(with: data) as? [String: Any], o["cookies"] != nil {
                load(from: o)
                return true
            }
        }
        return false
    }

    static func makeSeed() -> String { String((0..<5).map { _ in "abcdefghijklmnopqrstuvwxyz".randomElement()! }) }

    func reset(hard: Bool) {
        toasts = []
        lastVersion = 8.0
        lastResetTimestamp = now()
        runStart = now()
        if hard { gameStart = now() }
        seed = Game.makeSeed()
        let forfeited = cookiesEarned
        let currentCookies = cookies
        cookies = 0; cookiesD = 0
        if hard { cookiesReset = 0 }
        cookiesEarned = 0; cookiesHandmade = 0
        if hard { cookiesTotal = 0 }
        cookiesPs = 0; cookiesPsUnbuffed = 0; cookiesPc = 1; cookiesPsRawHighest = 0
        powerClicksOn = false; powerClicks = 0
        gcClicks = 0; reindeerClicks = 0
        if hard {
            gcClicksTotal = 0; gcMissed = 0; reindeerClicksTotal = 0; reindeerMissed = 0; cookieClicks = 0; powerClicksTotal = 0
            settings.vals["dislodge"] = 1
            recentAchievs = []; bgType = 0; milkType = 0; chimeType = 0; tippedN = 0
        }
        recentUpgrades = []
        fortuneGC = 0; fortuneCPS = 0
        onAscend = 0
        prestige = hard ? 0 : howMuchPrestige(cookiesReset).rounded(.down)
        if hard { heavenlyChips = 0; heavenlyChipsSpent = 0; resets = 0 }
        else if gainedPrestige > 0 { resets += 1 }
        gainedPrestige = 0
        Wrinklers.shared.reset(self)
        bulkBuy = 1; bulkMode = 1
        for b in buildings { b.reset() }
        if hard { for b in buildings { b.level = 0; b.minigameSave = "" } }
        upgradesN = 0
        let lasting = data.extraStrings("lasting")
        let seasonDrops = Seasons.seasonDrops
        for u in upgrades where u.pool != "prestige" || hard {
            var wasUnlocked = u.unlocked > 0
            u.unlocked = 0; u.owned = 0; u.ping = false
            if !hard && wasUnlocked {
                if lasting.contains(u.name) {}
                else if Has("Keepsakes") && seasonDrops.contains(u.name) && rnd() < 1.0 / 5 {}
                else if HasAchiev("O Fortuna") && u.def.tier == "Fortune" && rnd() < 0.4 {}
                else { wasUnlocked = false }
                if wasUnlocked { u.unlocked = 1 }
            }
        }
        if !hard { for u in upgradePools["prestige"] ?? [] where u.owned > 0 { upgradeBought(u, forced: true) } }
        if hard { achievsN = 0; for a in achievs { a.owned = 0 } }
        pings = []
        if !hard {
            let wins: [(Double, String)] = [(1e6, "Sacrifice"), (1e9, "Oblivion"), (1e12, "From scratch"), (1e15, "Nihilism"), (1e18, "Dematerialize"),
                (1e21, "Nil zero zilch"), (1e24, "Transcendence"), (1e27, "Obliterate"), (1e30, "Negative void"), (1e33, "To crumbs, you say?"),
                (1e36, "You get nothing"), (1e39, "Humble rebeginnings"), (1e42, "The end of the world"), (1e45, "Oh, you're back"),
                (1e48, "Lazarus"), (1e51, "Smurf account"), (1e54, "If at first you don't succeed"), (1e57, "No more room in hell")]
            for (n, name) in wins where forfeited >= n { win(name) }
            if currentCookies.rounded(.down) == 1e12 { win("When the cookies ascend just right") }
        }
        researchT = 0; researchTM = 0; researchUpgrade = nil; researchUpgradeLast = nil
        elderWrath = 0; pledges = 0; pledgeT = 0
        resetBuffs()
        resetShimmers()
        santaLevel = 0; dragonLevel = 0; dragonAura = 0; dragonAura2 = 0
        Seasons.reset(self)
        if hard { quickButtons = []; permanentUpgrades = [-1, -1, -1, -1, -1] }
        else { for id in permanentUpgrades where id != -1 { if let u = upgradesBID[id] { forceBuyUpgrade(u) } } }
        Lumps.reset(self, hard: hard)
        Minigames.shared.reset(self, hard: hard)
        computeCps()
        for b in buildings {
            b.free = Int(p("building\(b.id)Free"))
            b.amount += b.free; b.bought += b.free
        }
        computeBuildingAmounts()
    }

    // MARK: ascending
    func earnHeavenlyChips(_ forfeited: Double) {
        let pr = howMuchPrestige(cookiesReset + forfeited).rounded(.down)
        if pr > prestige {
            let dif = pr - prestige
            gainedPrestige = dif
            heavenlyChips += dif
            prestige = pr
            toast("You gain <b>\(B(dif))</b> prestige level\(dif == 1 ? "" : "s")!", "You forfeit your \(B(forfeited)) cookie\(forfeited == 1 ? "" : "s").", [19, 7])
        }
    }
    /// start ascending: the run's cookies turn into prestige; the heavenly upgrade tree opens
    func ascend() {
        onAscend = 1
        resetBuffs()
        resetShimmers()
        resetPools()
        earnHeavenlyChips(cookiesEarned)
        cookiesReset += cookiesEarned
        Sound.play("snd/cymbalRev.mp3", 0.5)
        Sound.play("snd/choir.mp3")
    }
    func reincarnate() {
        reset(hard: false)
        onAscend = 0
        Sound.play("snd/choir.mp3")
        save()
    }
}
