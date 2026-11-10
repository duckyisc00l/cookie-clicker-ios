import Foundation

// Builds the game's content from Content.json (the definitions extracted from www/data.js and the app's mods),
// replicating the G.Building / G.Upgrade / G.Achiev constructors and G.afterData from www/main.js.

extension Game {
    func initTiers() {
        let list: [Tier] = [
            Tier("1", "Plain", unlock: 1, achievUnlock: 1, iconRow: 0, color: "#ccb3ac", price: 10),
            Tier("2", "Berrylium", unlock: 5, achievUnlock: 50, iconRow: 1, color: "#ff89e7", price: 50),
            Tier("3", "Blueberrylium", unlock: 25, achievUnlock: 100, iconRow: 2, color: "#00deff", price: 500),
            Tier("4", "Chalcedhoney", unlock: 50, achievUnlock: 150, iconRow: 13, color: "#ffcc2f", price: 50000),
            Tier("5", "Buttergold", unlock: 100, achievUnlock: 200, iconRow: 14, color: "#e9d673", price: 5000000),
            Tier("6", "Sugarmuck", unlock: 150, achievUnlock: 250, iconRow: 15, color: "#a8bf91", price: 500000000),
            Tier("7", "Jetmint", unlock: 200, achievUnlock: 300, iconRow: 16, color: "#60ff50", price: 500000000000),
            Tier("8", "Cherrysilver", unlock: 250, achievUnlock: 350, iconRow: 17, color: "#f01700", price: 500000000000000),
            Tier("9", "Hazelrald", unlock: 300, achievUnlock: 400, iconRow: 18, color: "#9ab834", price: 500000000000000000),
            Tier("10", "Mooncandy", unlock: 350, achievUnlock: 450, iconRow: 19, color: "#7e7ab9", price: 500000000000000000000),
            Tier("11", "Astrofudge", unlock: 400, achievUnlock: 500, iconRow: 28, color: "#9a3316", price: 5e24),
            Tier("12", "Alabascream", unlock: 450, achievUnlock: 550, iconRow: 30, color: "#c1a88c", price: 5e28),
            Tier("13", "Iridyum", unlock: 500, achievUnlock: 600, iconRow: 31, color: "#adb1b3", price: 5e32),
            Tier("14", "Glucosmium", unlock: 550, achievUnlock: 650, iconRow: 34, color: "#ff89e7", price: 5e36),
            Tier("15", "Glimmeringue", unlock: 600, achievUnlock: 700, iconRow: 36, color: "#fffaa8", price: 5e40),
            Tier("synergy1", "Synergy I", unlock: 15, iconRow: 20, color: "#008595", special: true, req: "Synergies Vol. I", price: 200000),
            Tier("synergy2", "Synergy II", unlock: 150, iconRow: 29, color: "#008595", special: true, req: "Synergies Vol. II", price: 200000000000),
            Tier("fortune", "Fortune", unlock: -1, iconRow: 32, color: "#9ab834", special: true, price: 77777777777777777777777777777),
        ]
        tiers = [:]
        for t in list { tiers[t.key] = t }
    }

    func initMilks() {
        let all: [(String, [Int], Int, String)] = [
            ("Automatic", [0, 7], -1, "milkPlain"), ("Plain milk", [1, 8], 0, "milkPlain"), ("Chocolate milk", [2, 8], 0, "milkChocolate"),
            ("Raspberry milk", [3, 8], 0, "milkRaspberry"), ("Orange milk", [4, 8], 0, "milkOrange"), ("Caramel milk", [5, 8], 0, "milkCaramel"),
            ("Banana milk", [6, 8], 0, "milkBanana"), ("Lime milk", [7, 8], 0, "milkLime"), ("Blueberry milk", [8, 8], 0, "milkBlueberry"),
            ("Strawberry milk", [9, 8], 0, "milkStrawberry"), ("Vanilla milk", [10, 8], 0, "milkVanilla"), ("Zebra milk", [10, 7], 1, "milkZebra"),
            ("Cosmic milk", [9, 7], 1, "milkStars"), ("Flaming milk", [8, 7], 1, "milkFire"), ("Sanguine milk", [7, 7], 1, "milkBlood"),
            ("Midas milk", [6, 7], 1, "milkGold"), ("Midnight milk", [5, 7], 1, "milkBlack"), ("Green inferno milk", [4, 7], 1, "milkGreenFire"),
            ("Frostfire milk", [3, 7], 1, "milkBlueFire"), ("Honey milk", [21, 23], 0, "milkHoney"), ("Coffee milk", [22, 23], 0, "milkCoffee"),
            ("Tea milk", [23, 23], 0, "milkTea"), ("Coconut milk", [24, 23], 0, "milkCoconut"), ("Cherry milk", [25, 23], 0, "milkCherry"),
            ("Soy milk", [27, 23], 1, "milkSoy"), ("Spiced milk", [26, 23], 0, "milkSpiced"), ("Maple milk", [28, 23], 0, "milkMaple"),
            ("Mint milk", [29, 23], 0, "milkMint"), ("Licorice milk", [30, 23], 0, "milkLicorice"), ("Rose milk", [31, 23], 0, "milkRose"),
            ("Dragonfruit milk", [21, 24], 0, "milkDragonfruit"), ("Melon milk", [22, 24], 0, "milkMelon"), ("Blackcurrant milk", [23, 24], 0, "milkBlackcurrant"),
            ("Peach milk", [24, 24], 0, "milkPeach"), ("Hazelnut milk", [25, 24], 0, "milkHazelnut"),
        ]
        AllMilks = all.map { Milk(name: $0.0, icon: $0.1, type: $0.2, pic: $0.3) }
        milks = []
        for i in 0..<AllMilks.count where AllMilks[i].type == 0 {
            AllMilks[i].rank = milks.count
            milks.append(AllMilks[i])
        }
        // milk.name='Rank '+romanize(i+1)+' - '+milk.name (only the copies in G.milks)
        for i in 0..<milks.count { milks[i] = Milk(name: "Rank " + romanize(i + 1) + " - " + milks[i].name, icon: milks[i].icon, type: milks[i].type, pic: milks[i].pic, rank: milks[i].rank) }
    }

    static let AllBGs: [(pic: String, name: String, icon: [Int], order: Double?)] = [
        ("bgBlue", "Automatic", [0, 7], nil), ("bgBlue", "Blue", [21, 21], nil), ("bgRed", "Red", [22, 21], nil),
        ("bgWhite", "White", [23, 21], nil), ("bgBlack", "Black", [24, 21], nil), ("bgGold", "Gold", [25, 21], nil),
        ("grandmas1", "Grandmas", [26, 21], nil), ("grandmas2", "Displeased grandmas", [27, 21], nil), ("grandmas3", "Angered grandmas", [28, 21], nil),
        ("bgMoney", "Money", [29, 21], nil), ("bgPurple", "Purple", [21, 22], 1.1), ("bgPink", "Pink", [24, 22], 2.1),
        ("bgMint", "Mint", [22, 22], 2.2), ("bgSilver", "Silver", [25, 22], 4.9), ("bgBW", "Black & White", [23, 22], 4.1),
        ("bgSpectrum", "Spectrum", [28, 22], 4.2), ("bgCandy", "Candy", [26, 22], nil), ("bgYellowBlue", "Biscuit store", [27, 22], nil),
        ("bgChoco", "Chocolate", [30, 21], nil), ("bgChocoDark", "Dark Chocolate", [31, 21], nil), ("bgPaint", "Painter", [24, 34], nil),
        ("bgSnowy", "Snow", [30, 22], nil), ("bgSky", "Sky", [29, 22], nil), ("bgStars", "Night", [31, 22], nil), ("bgFoil", "Foil", [25, 34], nil),
    ]

    func getPledgeDuration() -> Double { 60 * (Has("Sacrificial rolling pins") ? 60 : 30) }

    // MARK: loading
    func loadContent() {
        guard let url = Bundle.main.url(forResource: "Content", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            fatalError("Content.json missing")
        }
        initTiers()
        initMilks()
        buildings = []; buildingsBN = [:]
        upgrades = []; upgradesBN = [:]; upgradesBID = [:]; upgradePools = [:]; upgradeTiers = [:]; lastingUpgrades = []
        achievs = []; achievsBN = [:]; achievsBID = [:]

        for o in root["buildings"] as? [[String: Any]] ?? [] {
            let b = Building(id: buildings.count, o: o)
            buildings.append(b)
            buildingsBN[b.name] = b
        }
        // the app's new buildings set their own price and output (mods/more-content.js)
        for b in buildings where b.id >= 20 {
            if let o = (root["buildings"] as? [[String: Any]])?[b.id] {
                b.baseCost = (o["cost"] as? NSNumber)?.doubleValue ?? b.baseCost
                b.baseCps = (o["cps"] as? NSNumber)?.doubleValue ?? b.baseCps
            }
        }
        buildingsBN["Antimatter condenser"]?.style = "letter-spacing:-1px;"

        var missing: [String] = []
        for o in root["upgrades"] as? [[String: Any]] ?? [] { makeUpgrade(o, &missing) }
        for o in root["achievs"] as? [[String: Any]] ?? [] { makeAchiev(o, &missing) }
        if !missing.isEmpty { print("Content code without a Swift translation:", missing) }

        // mods/more-content.js sets the new unshackled upgrades' power after creating them
        for b in buildings where b.id >= 20 { b.unshackleUpgrade?.power = 0.1 }

        HeavenlyUpgradePositions = [:]
        for (k, v) in root["positions"] as? [String: Any] ?? [:] {
            if let id = Int(k), let arr = v as? [NSNumber] { HeavenlyUpgradePositions[id] = arr.map { $0.doubleValue } }
        }
        HeavenlyUpgradeParents = [:]
        for (k, v) in root["parents"] as? [String: Any] ?? [:] {
            if let id = Int(k), let arr = v as? [NSNumber] { HeavenlyUpgradeParents[id] = arr.map { $0.intValue } }
        }
        unimplementedUpgrades = Set(root["unimplementedUpgrades"] as? [String] ?? [])
        unimplementedAchievs = Set(root["unimplementedAchievs"] as? [String] ?? [])
        permanentSlots()
    }

    private func numberOrNil(_ v: Any?) -> Double? { (v as? NSNumber)?.doubleValue }
    private func fnKey(_ v: Any?) -> String? { (v as? [String: Any])?["__fn"] as? String }

    private func makeUnlockAt(_ raw: [String: Any], key: String, _ missing: inout [String]) -> [String: Any] {
        var u = raw
        if let k = fnKey(raw["spe"]) {
            if let f = ContentFns.bools[k] { u["spe"] = f } else { missing.append(k); u["spe"] = nil }
        }
        return u
    }

    /// G.Upgrade(o)
    private func makeUpgrade(_ o: [String: Any], _ missing: inout [String]) {
        let me = Upgrade()
        let name = o["name"] as? String ?? ""
        let key = "Upgrade:" + name
        let tie = (o["tie"] as? NSNumber)?.intValue ?? -1
        let tie2 = (o["tie2"] as? NSNumber)?.intValue ?? -1
        if let v = o["pool"] as? String, !v.isEmpty { me.pool = v }
        me.name = name
        me.id = (o["id"] as? NSNumber)?.intValue ?? 0
        if let v = o["q"] as? String { me.q = v }
        if let v = o["desc"] as? String, !v.isEmpty { me.desc = v }
        if let k = fnKey(o["descFunc"]) { me.descFunc = ContentFns.upgradeTexts[k]; if me.descFunc == nil { missing.append(k) } }
        if let k = fnKey(o["preDescFunc"]) { me.preDescFunc = ContentFns.upgradeTexts[k]; if me.preDescFunc == nil { missing.append(k) } }
        if let k = fnKey(o["qFunc"]) { me.qFunc = ContentFns.upgradeTexts[k]; if me.qFunc == nil { missing.append(k) } }
        if let v = o["icon"] as? [NSNumber], !v.isEmpty { me.icon = v.map { $0.intValue } }
        if let v = numberOrNil(o["cost"]), v != 0 { me.cost = v }
        if let v = numberOrNil(o["order"]), v != 0 { me.order = v }
        if let k = fnKey(o["func"]) { me.funcB = ContentFns.funcs[k]; if me.funcB == nil { missing.append(k) } }
        if let k = fnKey(o["costFunc"]) { me.costFunc = ContentFns.costs[k]; if me.costFunc == nil { missing.append(k) } }
        if let effs = o["effs"] as? [[Any]] {
            for (i, e) in effs.enumerated() {
                guard let pool = e.first as? String else { continue }
                if let k = fnKey(e.count > 1 ? e[1] : nil) {
                    if let f = ContentFns.effs[k] { me.effs.append(Eff(pool, f)) } else { missing.append(k) }
                    _ = i
                } else {
                    let v = numberOrNil(e.count > 1 ? e[1] : nil) ?? 0
                    let mode = e.count > 2 ? ((e[2] as? NSNumber)?.intValue ?? 0) : 0
                    me.effs.append(Eff(pool, v, mode))
                }
            }
        }
        if let k = fnKey(o["power"]) { me.powerFunc = ContentFns.powers[k]; if me.powerFunc == nil { missing.append(k) } }
        else if let v = numberOrNil(o["power"]), v != 0 { me.power = v }
        // the birthday cookie's power is the age of the game in years, worked out when the game starts
        if name == "Birthday cookie" {
            let start = Calendar.current.date(from: DateComponents(year: 2013, month: 8, day: 8))!
            me.power = ((Date().timeIntervalSince1970 - start.timeIntervalSince1970) * 1000 / (1000 * 60 * 60 * 24 * 365)).rounded(.down)
            me.desc = "Cookie production multiplier <b>+1%</b> for every year Cookie Clicker has existed (currently: <b>+\(jsString(me.power))%</b>)."
        }
        var unlockAt: [String: Any] = [:]
        if let ua = o["unlockAt"] as? [String: Any] { unlockAt = makeUnlockAt(ua, key: key, &missing) }
        if let t = o["tier"] { me.tier = tiers["\(t)"] }
        if let v = o["unimplemented"] as? Bool, v { me.unimplemented = true }
        if o["lasting"] as? Bool == true { lastingUpgrades.append(name) }

        if me.pool == "cookie" {
            if me.powerFunc != nil {
                if me.descFunc == nil { me.descFunc = { u in "Cookie production multiplier <b>+\(jsString(u.getPower()))%</b>." } }
                me.effs.append(Eff("cpsM", { [unowned me] v in v * (1 + me.getPower() * 0.01) }))
            } else {
                if me.desc.isEmpty { me.desc = "Cookie production multiplier <b>+\(jsString(me.power))%</b>." }
                me.effs.append(Eff("cpsM", 1 + me.power * 0.01, 1))
            }
        } else if me.pool == "building" {
            let t = buildings[tie]
            me.tie = t
            me.desc = "\(cap(t.plural)) are <b>twice</b> as efficient."
            me.preDescFunc = { u in
                guard let tu = t.unshackleUpgrade, let tier = u.tier, let tierU = tier.unshackleUpgrade else { return "" }
                return (tu.owned != 0 && tierU.owned != 0) ? "<div style=\"font-size:80%;text-align:center;\">Unshackled! <b>+\(jsString(jsRound(tu.power * 100)))%</b> extra production.</div>" : ""
            }
            me.effs.append(Eff("building\(t.id)M", { [unowned me] v in
                if t.id == 0 { return v * 2 }
                if let tu = t.unshackleUpgrade, tu.owned != 0, let tierU = me.tier?.unshackleUpgrade, tierU.owned != 0 { return v * (2 + tu.power) }
                return v * 2
            }))
            if let tier = me.tier {
                me.icon = getTieredIcon(t.name, tier.key)
                unlockAt["buildings"] = [t.id, tier.unlock]
            }
        } else if me.pool == "grandma" {
            let t = buildings[tie]
            me.tie = t
            let grandmaNumber = (t.id - 1) == 1 ? "grandma" : "\(t.id - 1) grandmas"
            if me.desc.isEmpty { me.desc = "Grandma production <b>doubled</b>.<br>\(cap(t.plural)) gain <b>+1% CpS</b> per \(grandmaNumber)." }
            me.effs.append(Eff("building1M", 2, 1))
            me.effs.append(Eff("building\(t.id)M", { v in v * (1 + 0.01 * Double(G.buildings[1].amount) * (1 / Double(t.id - 1))) }))
            unlockAt["buildings"] = [1, 1, t.id, 15]
        } else if me.pool == "finger" {
            let pows: [Double] = [2, 2, 2, 0.1, 5, 10, 20]
            let unlocks = [1, 1, 10, 25, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550]
            let tier = me.tier?.numId ?? 1
            let pw = tier < 7 ? pows[tier - 1] : 20
            let unl = tier < 5 ? unlocks[tier - 1] : 50 * (tier - 4)
            if tier < 4 {
                me.desc = "Tapping and cursors are <b>twice</b> as efficient."
                me.effs.append(Eff("building0M", 2, 1))
                me.effs.append(Eff("clickA", 2, 1))
            } else if tier == 4 {
                me.desc = "Tapping and cursors gain <b>+\(B(pw, 1))</b> cookies for each non-cursor object owned."
                let f: (Double) -> Double = { v in
                    var n = 0
                    for i in 1..<G.buildings.count { n += G.buildings[i].amount }
                    var mult = 1.0
                    let fingers = G.upgradePools["finger"] ?? []
                    var i = 4
                    while i < fingers.count {
                        if fingers[i].owned != 0 { mult *= (i < 7 ? pows[i] : 20) }
                        i += 1
                    }
                    if G.Has("Unshackled cursors") { mult *= 25 }
                    return v + Double(n) * pw * mult
                }
                me.effs.append(Eff("building0A", f))
                me.effs.append(Eff("clickA", f))
            } else {
                me.desc = "Multiplies the gain from Thousand fingers by <b>\(jsString(pw))</b>."
            }
            unlockAt["buildings"] = [0, unl]
        } else if me.pool == "mouse" {
            let tier = Double(me.tier?.numId ?? 1)
            if me.desc.isEmpty { me.desc = "Tapping gains <b>+1% of your CpS</b>." }
            unlockAt["spe"] = { G.cookiesHandmade >= pow(10, tier * 2 + 1) } as () -> Bool
        } else if me.pool == "kitten" {
            if me.desc.isEmpty { me.desc = "You gain <b>more CpS</b> the more milk you have." }
            if let t = me.tier?.numId { unlockAt["milk"] = max(0.5, Double(t - 1)) }
        } else if me.pool == "synergy" {
            let t1 = buildings[tie], t2 = buildings[tie2]
            me.tie = t1; me.tie2 = t2
            let tier = me.tier!
            me.costFunc = { u in (t1.baseCost * 10 + t2.baseCost * 1) * u.tier!.price * (G.Has("Chimera") ? 0.98 : 1) }
            me.effs.append(Eff("building\(t1.id)M", { v in v * (1 + 0.05 * Double(t2.amount)) }))
            me.effs.append(Eff("building\(t2.id)M", { v in v * (1 + 0.001 * Double(t1.amount)) }))
            unlockAt["upgrade"] = "Synergies Vol. \(tier.key == "synergy1" ? "I" : "II")"
            if tier.key == "synergy1" { unlockAt["buildings"] = [t1.id, 15, t2.id, 15] }
            else { unlockAt["buildings"] = [t1.id, 75, t2.id, 75] }
        } else if me.pool == "unshackle" {
            me.pool = "prestige"
            if tie >= 0 && tie < buildings.count {
                let t = buildings[tie]
                me.tie = t
                if t.id == 0 {
                    me.power = 25
                    me.desc = "Multiplies the gain from Thousand fingers by <b>\(jsString(me.power))</b>."
                } else {
                    me.power = t.id == 1 ? 0.5 : Double(20 - t.id) * 0.1
                    if me.desc.isEmpty { me.desc = "Tiered upgrades for <b>\(cap(t.plural))</b> provide an extra <b>+\(jsString(jsRound(me.power * 100)))%</b> production.<br>Only works with unshackled upgrade tiers." }
                }
                t.unshackleUpgrade = me
            } else if let tier = me.tier {
                if me.desc.isEmpty { me.desc = "Unshackles all <b>\(tier.name)-tier upgrades</b>, making them more powerful.<br>Only applies to unshackled buildings." }
                tier.unshackleUpgrade = me
            }
        } else if me.pool == "angel" {
            me.pool = "prestige"
            let speed = 30 - me.power * 2
            let capacity = 5 + me.power * 5
            me.desc = "Power click production while the game is closed sped up to <b>one every \(jsString(speed)) minutes</b>.<br>Maximum power click capacity increased to <b>\(jsString(capacity))</b>."
        } else if me.pool == "demon" {
            me.pool = "prestige"
            let clickM = 2 + me.power
            let cpsM = 5 + me.power * 1
            let cpsMt = 10 + me.power * 5
            me.desc = "Power click effects increased to <b>\(jsString(clickM)) times</b> more cookies per click and <b>+\(jsString(cpsM))%</b> cookie production for <b>\(jsString(cpsMt)) seconds</b>."
        }
        if me.pool != "" { upgradePools[me.pool, default: []].append(me) }
        if let t = me.tier { upgradeTiers[t.key, default: []].append(me) }
        if me.effs.contains(where: { $0.pool == "pseudoKitten" }) { upgradePools["pseudoKitten", default: []].append(me) }
        if !unlockAt.isEmpty { pendingUnlocks.append((me, nil, unlockAt)) }
        me.unlocked = 0
        me.owned = 0
        upgrades.append(me)
        upgradesBN[me.name] = me
        upgradesBID[me.id] = me
    }

    /// G.Achiev(o)
    private func makeAchiev(_ o: [String: Any], _ missing: inout [String]) {
        let me = Achiev()
        let name = o["name"] as? String ?? ""
        let key = "Achiev:" + name
        let tie = (o["tie"] as? NSNumber)?.intValue ?? -1
        if let v = o["pool"] as? String, !v.isEmpty { me.pool = v }
        me.name = name
        me.id = (o["id"] as? NSNumber)?.intValue ?? 0
        if let v = o["q"] as? String { me.q = v }
        if let v = o["desc"] as? String, !v.isEmpty { me.desc = v }
        if let k = fnKey(o["descFunc"]) { me.descFunc = ContentFns.achievTexts[k]; if me.descFunc == nil { missing.append(k) } }
        if let k = fnKey(o["qFunc"]) { me.qFunc = ContentFns.achievTexts[k]; if me.qFunc == nil { missing.append(k) } }
        if let v = o["icon"] as? [NSNumber], !v.isEmpty { me.icon = v.map { $0.intValue } }
        if let v = numberOrNil(o["order"]), v != 0 { me.order = v }
        var unlockAt: [String: Any] = [:]
        if let ua = o["unlockAt"] as? [String: Any] { unlockAt = makeUnlockAt(ua, key: key, &missing) }
        if let v = (o["tier"] as? NSNumber)?.intValue, v != 0 { me.tier = v }
        if let v = o["unimplemented"] as? Bool, v { me.unimplemented = true }

        if me.pool == "bank" {
            let tier = Double(me.tier)
            var threshold = pow(10, (tier * 1.5 + 2).rounded(.down))
            if me.tier == 0 { threshold = 1 }
            if me.desc.isEmpty { me.desc = "Bake <b>\(B(threshold)) cookie\(B(threshold) == "1" ? "" : "s")</b> in one ascension." }
            unlockAt["cookies"] = threshold
        } else if me.pool == "cps" {
            let tier = Double(me.tier)
            let threshold = pow(10, (tier * 1.2).rounded(.down))
            if me.desc.isEmpty { me.desc = "Bake <b>\(B(threshold)) cookie\(B(threshold) == "1" ? "" : "s")</b> per second." }
            unlockAt["cps"] = threshold
        } else if me.pool == "building" {
            let t = buildings[tie]
            let tier = tiers["\(me.tier)"]!
            if me.desc.isEmpty { me.desc = "Have <b>\(B(Double(tier.achievUnlock)))</b> \(tier.achievUnlock == 1 ? t.single : t.plural)." }
            unlockAt["buildings"] = [t.id, tier.achievUnlock]
        } else if me.pool == "buildingProd" {
            let t = buildings[tie]
            var mult = 0
            if t.id == 0 { mult = 7 } else if t.id == 1 { mult = 6 }
            var n = 12 + t.id + mult
            if me.tier == 2 { n += 7 } else if me.tier == 3 { n += 14 }
            let threshold = pow(10, Double(n))
            if me.desc.isEmpty { me.desc = "Make <b>\(B(threshold))</b> cookies just from \(t.plural)." }
            unlockAt["spe"] = { t.cookiesMade >= threshold } as () -> Bool
        } else if me.pool == "mouse" {
            let p = pow(10, Double(me.tier) * 2 + 1)
            if me.desc.isEmpty { me.desc = "Make <b>\(B(p))</b> cookies from tapping." }
            unlockAt["spe"] = { G.cookiesHandmade >= p } as () -> Bool
        }
        if !unlockAt.isEmpty { pendingUnlocks.append((nil, me, unlockAt)) }
        me.owned = 0
        achievs.append(me)
        achievsBN[me.name] = me
        achievsBID[me.id] = me
    }

    /// new G.unlockAt(...) then G.afterData turning names and ids into references
    func resolveUnlocks() {
        for (u, a, raw) in pendingUnlocks {
            let ua = UnlockAt()
            ua.cookies = numberOrNil(raw["cookies"]) ?? 0
            ua.cps = numberOrNil(raw["cps"]) ?? 0
            let bs = (raw["building"] ?? raw["buildings"]) as? [Any] ?? []
            var i = 0
            while i + 1 < bs.count {
                let id = (bs[i] as? NSNumber)?.intValue ?? (bs[i] as? Int) ?? 0
                let n = (bs[i + 1] as? NSNumber)?.intValue ?? (bs[i + 1] as? Int) ?? 0
                if id >= 0 && id < buildings.count { ua.buildings.append((buildings[id], n)) }
                i += 2
            }
            var upNames: [String] = []
            if let s = raw["upgrade"] as? String { upNames = [s] } else if let l = raw["upgrades"] as? [String] { upNames = l }
            for n in upNames {
                if let x = upgradesBN[n] { ua.upgrades.append(x) } else { u?.unimplemented = true; a?.unimplemented = true }
            }
            var acNames: [String] = []
            if let s = raw["achiev"] as? String { acNames = [s] } else if let l = raw["achievs"] as? [String] { acNames = l }
            for n in acNames {
                if let x = achievsBN[n] { ua.achievs.append(x) } else { u?.unimplemented = true; a?.unimplemented = true }
            }
            ua.milk = numberOrNil(raw["milk"]) ?? 0
            ua.spe = raw["spe"] as? () -> Bool
            u?.unlockAt = ua
            a?.unlockAt = ua
        }
        pendingUnlocks = []
    }

    /// G.afterData: unimplemented content is removed from pools; totals are counted
    func afterData() {
        resolveUnlocks()
        for me in upgrades where unimplementedUpgrades.contains(me.name) { me.unimplemented = true }
        for me in achievs where unimplementedAchievs.contains(me.name) { me.unimplemented = true }
        upgradesTotal = 0
        achievsTotal = 0
        for me in upgrades {
            if me.unimplemented {
                if me.pool != "", let idx = upgradePools[me.pool]?.firstIndex(where: { $0 === me }) { upgradePools[me.pool]!.remove(at: idx) }
                if let t = me.tier, let idx = upgradeTiers[t.key]?.firstIndex(where: { $0 === me }) { upgradeTiers[t.key]!.remove(at: idx) }
            } else if me.pool == "toggle" || me.pool == "prestige" {}
            else { upgradesTotal += 1 }
        }
        for me in achievs {
            if me.unimplemented {}
            else if me.pool == "shadow" {}
            else { achievsTotal += 1 }
        }
        HeavenlyUpgradeChildren = [:]
        for (id, parents) in HeavenlyUpgradeParents {
            if HeavenlyUpgradeChildren[id] == nil { HeavenlyUpgradeChildren[id] = [] }
            for p in parents {
                if upgradesBID[id] != nil { HeavenlyUpgradeChildren[p, default: []].append(id) }
            }
        }
        // keep the children in the order the original builds them (object key order = ascending ids)
        for (k, v) in HeavenlyUpgradeChildren { HeavenlyUpgradeChildren[k] = v.sorted() }
    }

    /// the permanent upgrade slots (data.js builds their texts and icons in a loop)
    private func permanentSlots() {
        let slots = ["Permanent upgrade slot I", "Permanent upgrade slot II", "Permanent upgrade slot III", "Permanent upgrade slot IV", "Permanent upgrade slot V"]
        for (i, name) in slots.enumerated() {
            guard let slot = upgradesBN[name] else { continue }
            slot.descFunc = { _ in
                var str = "You can assign any upgrade you've purchased last playthrough into this slot.</p><p>Doing so will make its effects <b>permanent across all playthroughs</b>.</p><p>You can reassign this slot anytime you ascend."
                if G.permanentUpgrades[i] != -1, let up = G.upgradesBID[G.permanentUpgrades[i]] {
                    let icon = up.getIcon()
                    str = "<div style=\"text-align:center;\">Current: <div class=\"icon\" style=\"vertical-align:middle;display:inline-block;background-position:\(-icon[0] * 48)px \(-icon[1] * 48)px;transform:scale(0.5);margin:-16px;\"></div> <b>\(up.name)</b></div><line></line>" + str
                }
                return str
            }
            slot.iconFunc = {
                if G.permanentUpgrades[i] == -1 || G.upgradesBID[G.permanentUpgrades[i]] == nil { return [i, 10] }
                return G.upgradesBID[G.permanentUpgrades[i]]!.icon
            }
            slot.permanentSlotIndex = i
        }
    }

    /// upgrades allowed in a permanent slot (data.js slotAssignPopup)
    func permanentSlotCandidates(_ id: Int) -> [Upgrade] {
        let noPerm = ["Bingo center/Research facility", "Heavenly chip secret", "Heavenly cookie stand", "Heavenly bakery", "Heavenly confectionery", "Heavenly key"]
        let pools: Set<String> = ["", "finger", "mouse", "building", "kitten", "grandma", "cookie"]
        var list: [Upgrade] = []
        for me in upgrades {
            if me.owned != 0 && me.unlocked != 0 && !noPerm.contains(me.name) && pools.contains(me.pool)
                && (permanentUpgrades.firstIndex(of: me.id) == id || !permanentUpgrades.contains(me.id)) { list.append(me) }
        }
        return list.sorted { $0.order < $1.order }
    }
}
