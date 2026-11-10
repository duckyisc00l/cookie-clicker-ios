import Foundation

// Port of www/main.js "BUFFS" section (G.buffType, G.buff, G.logicBuffs, G.resetBuffs, G.hasBuff, G.killBuff).

final class BuffType {
    let name: String
    let nameD: String
    let icon: [Int]
    var type = 0              // 1 good, 2 bad
    var stackT = 1            // 0 replace, 1 add, 2 max
    var stackPow = 2          // 0 replace, 1 add, 2 max
    var t = 1.0
    var pow = 1.0
    var desc: (Buff) -> String
    var initF: ((Buff) -> Void)? = nil
    var effsFunc: ((Buff) -> [Eff])? = nil
    var buffs: [Buff] = []
    init(name: String, nameD: String, icon: [Int], desc: @escaping (Buff) -> String, t: Double, pow: Double, type: Int,
         stackT: Int = 1, stackPow: Int = 2, initF: ((Buff) -> Void)? = nil, effsFunc: ((Buff) -> [Eff])? = nil) {
        self.name = name; self.nameD = nameD; self.icon = icon; self.desc = desc
        self.t = t; self.pow = pow; self.type = type; self.stackT = stackT; self.stackPow = stackPow
        self.initF = initF; self.effsFunc = effsFunc
    }
}

final class Buff {
    let type: BuffType
    var t: Double     // seconds left
    var tm: Double    // total duration
    var pow: Double
    var effs: [Eff] = []
    /// set by the screen while the buff's icon is shown
    var appearedAt: Double = 0
    init(_ type: BuffType, t: Double, tm: Double, pow: Double) { self.type = type; self.t = t; self.tm = tm; self.pow = pow }
}

extension Game {
    func basicCpsModDesc(_ me: Buff) -> String {
        let p = me.pow
        let s: String
        if p == 2 { s = "doubled" }
        else if p == 0.5 { s = "halved" }
        else if p > 1 && p < 2 { s = "+" + B((p - 1) * 100, 2) + "%" }
        else { s = "x" + B(p, 2) }
        return "Cookie production <b>\(s)</b> for <b>[t]</b>."
    }

    func registerBuffType(_ b: BuffType) { buffTypes.append(b); buffTypesBN[b.name] = b }

    func initBuffTypes() {
        buffTypes = []; buffTypesBN = [:]
        registerBuffType(BuffType(name: "frenzy", nameD: "Frenzy", icon: [10, 14], desc: basicCpsModDesc, t: 10, pow: 7, type: 1,
                                  effsFunc: { me in [Eff("cpsBuffM", me.pow, 1), Eff("reindeerEffectsMultM", 0.75, 1)] }))
        registerBuffType(BuffType(name: "elderFrenzy", nameD: "Elder frenzy", icon: [29, 6], desc: basicCpsModDesc, t: 10, pow: 7, type: 1,
                                  effsFunc: { me in [Eff("cpsBuffM", me.pow, 1), Eff("reindeerEffectsMultM", 0.5, 1)] }))
        registerBuffType(BuffType(name: "clot", nameD: "Clot", icon: [15, 5], desc: basicCpsModDesc, t: 10, pow: 0.5, type: 2,
                                  effsFunc: { me in [Eff("cpsBuffM", me.pow, 1)] }))
        registerBuffType(BuffType(name: "dragonHarvest", nameD: "Dragon harvest", icon: [10, 25], desc: basicCpsModDesc, t: 10, pow: 10, type: 1,
                                  initF: { me in if G.Has("Dragon fang") { me.pow = (me.pow * 1.1).rounded(.up) } },
                                  effsFunc: { me in [Eff("cpsBuffM", me.pow, 1)] }))
        registerBuffType(BuffType(name: "sales", nameD: "Everything must go!", icon: [17, 6],
                                  desc: { me in "All buildings are <b>\(B(100 - me.pow * 100, 2))% cheaper</b> for <b>[t]</b>." }, t: 10, pow: 0.95, type: 1,
                                  effsFunc: { me in [Eff("buildingCostM", me.pow, 1)] }))
        registerBuffType(BuffType(name: "cursedFinger", nameD: "Cursed finger", icon: [12, 17],
                                  desc: { _ in "Cookie production halted for <b>[t]</b>, but each click is worth <b>[t]</b> of CpS." }, t: 10, pow: 0, type: 2,
                                  effsFunc: { _ in [] }))
        registerBuffType(BuffType(name: "clickFrenzy", nameD: "Click frenzy", icon: [0, 14],
                                  desc: { me in "Clicking power <b>x\(B(me.pow, 2))</b> for <b>[t]</b>." }, t: 10, pow: 7, type: 1,
                                  effsFunc: { me in [Eff("clickM", me.pow, 1)] }))
        registerBuffType(BuffType(name: "dragonflight", nameD: "Dragonflight", icon: [0, 25],
                                  desc: { me in "Clicking power <b>x\(B(me.pow, 2))</b> for <b>[t]</b>." }, t: 10, pow: 7, type: 1,
                                  initF: { me in if G.Has("Dragon fang") { me.pow = (me.pow * 1.1).rounded(.up) } },
                                  effsFunc: { me in [Eff("clickM", me.pow, 1)] }))
        registerBuffType(BuffType(name: "cookieStorm", nameD: "Cookie storm", icon: [22, 6], desc: { _ in "Cookies everywhere!" }, t: 10, pow: 7, type: 1,
                                  effsFunc: { _ in [] }))
        registerBuffType(BuffType(name: "powerClick", nameD: "Power poked", icon: [30, 36], desc: basicCpsModDesc, t: 10, pow: 1.05, type: 1,
                                  effsFunc: { me in [Eff("cpsBuffM", me.pow, 1)] }))
    }

    /// G.addPostData: one buff and one debuff per building for "building special" golden cookies
    func initBuildingBuffTypes() {
        var names: [String: [String]] = [
            "Cursor": ["High-five", "Slap to the face"],
            "Grandma": ["Congregation", "Senility"],
            "Farm": ["Luxuriant harvest", "Locusts"],
            "Mine": ["Ore vein", "Cave-in"],
            "Factory": ["Oiled-up", "Jammed machinery"],
            "Bank": ["Juicy profits", "Recession"],
            "Temple": ["Fervent adoration", "Crisis of faith"],
            "Wizard tower": ["Manabloom", "Magivores"],
            "Shipment": ["Delicious lifeforms", "Black holes"],
            "Alchemy lab": ["Breakthrough", "Lab disaster"],
            "Portal": ["Righteous cataclysm", "Dimensional calamity"],
            "Time machine": ["Golden ages", "Time jam"],
            "Antimatter condenser": ["Extra cycles", "Predictable tragedy"],
            "Prism": ["Solar flare", "Eclipse"],
            "Chancemaker": ["Winning streak", "Dry spell"],
            "Fractal engine": ["Macrocosm", "Microcosm"],
            "Javascript console": ["Refactoring", "Antipattern"],
            "Idleverse": ["Cosmic nursery", "Big crunch"],
            "Cortex baker": ["Brainstorm", "Brain freeze"],
            "You": ["Deduplication", "Clone strike"],
        ]
        // the app's new buildings (the app patches this list the same way)
        names["Black hole"] = ["Event horizon", "Evaporation"]
        names["Galaxy"] = ["Starburst", "Galactic drift"]
        names["Multiverse mixer"] = ["Perfect blend", "Lumpy batter"]
        names["Big bang"] = ["Cosmic dawn", "Heat death"]
        for (i, building) in buildings.enumerated() {
            let n = names[building.name] ?? [building.name, building.name]
            registerBuffType(BuffType(name: "buildingBuff\(i)", nameD: n[0], icon: [building.icon[0], 14],
                desc: { _ in "Your <b>\(B(Double(building.amount))) \(building.plural)</b> are boosting your CpS!<br>Cookie production <b>+\(B((Double(building.amount) / 10 + 1) * 100 - 100, 2))%</b> for <b>[t]</b>." },
                t: 10, pow: Double(i), type: 1, stackPow: 0,
                effsFunc: { _ in [Eff("cpsBuffM", { v in building.amount <= 0 ? v : v * (Double(building.amount) / 10 + 1) })] }))
            registerBuffType(BuffType(name: "buildingDebuff\(i)", nameD: n[1], icon: [building.icon[0], 15],
                desc: { _ in "Your <b>\(B(Double(building.amount))) \(building.plural)</b> are rusting your CpS!<br>Cookie production <b>\(B((Double(building.amount) / 10 + 1) * 100 - 100, 2))% slower</b> for <b>[t]</b>." },
                t: 10, pow: Double(i), type: 2, stackPow: 0,
                effsFunc: { _ in [Eff("cpsBuffM", { v in building.amount <= 0 ? v : v * 1 / (Double(building.amount) / 10 + 1) })] }))
        }
    }

    /// new G.buff(type,{t,tm,pow,loaded})
    @discardableResult
    func addBuff(_ typeName: String, t: Double? = nil, tm: Double? = nil, pow: Double? = nil, loaded: Bool = false) -> Buff? {
        guard let type = buffTypesBN[typeName] else { return nil }
        let tt = t ?? type.t
        let me = Buff(type, t: tt, tm: tm ?? tt, pow: pow ?? type.pow)
        if !loaded { type.initF?(me) }
        if let prev = hasBuff(typeName) {
            let oldT = prev.t
            let oldPow = prev.pow
            killBuff(typeName)
            if type.stackT == 1 { me.t += oldT }
            else if type.stackT == 2 { me.t = max(oldT, me.t) }
            if type.stackPow == 1 { me.pow += oldPow }
            else if type.stackPow == 2 { me.pow = max(oldPow, me.pow) }
            me.tm = max(me.t, me.tm)
        }
        me.effs = type.effsFunc?(me) ?? []
        buffs.append(me)
        type.buffs.append(me)
        refreshCps = true
        Minigames.onBuffCreated(me)
        return me
    }

    func logicBuffs(_ delta: Double) {
        var i = buffs.count - 1
        while i >= 0 {
            let me = buffs[i]
            me.t -= delta / fps
            if me.t <= 0 {
                buffs.remove(at: i)
                if let idx = me.type.buffs.firstIndex(where: { $0 === me }) { me.type.buffs.remove(at: idx) }
                refreshCps = true
                Minigames.onBuffEnded(me)
            }
            i -= 1
        }
    }
    func resetBuffs() {
        buffs = []
        for t in buffTypes { t.buffs = [] }
        refreshCps = true
    }
    func hasBuff(_ name: String) -> Buff? { buffTypesBN[name]?.buffs.first }
    func killBuff(_ name: String) {
        guard let type = buffTypesBN[name] else { return }
        for b in type.buffs { if let idx = buffs.firstIndex(where: { $0 === b }) { buffs.remove(at: idx) } }
        type.buffs = []
    }
}
