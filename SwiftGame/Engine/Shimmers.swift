import Foundation

// MARK: - Buffs

final class Buff: Identifiable {
    let id = UUID()
    let type: BuffTypeDef
    var t: Double          // seconds left
    var tm: Double         // total seconds
    var pow: Double
    init(type: BuffTypeDef, t: Double, tm: Double, pow: Double) { self.type = type; self.t = t; self.tm = tm; self.pow = pow }
}

extension Game {
    @discardableResult
    func addBuff(_ name: String, t tIn: Double? = nil, tm tmIn: Double? = nil, pow powIn: Double? = nil, loaded: Bool = false) -> Buff? {
        guard let type = buffTypesBN[name] else { return nil }
        let t = tIn ?? type.t
        let b = Buff(type: type, t: t, tm: tmIn ?? t, pow: powIn ?? type.pow)
        if !loaded && (name == "dragonHarvest" || name == "dragonflight") && Has("Dragon fang") { b.pow = (b.pow * 1.1).rounded(.up) }
        if let prev = hasBuff(name) {
            killBuff(name)
            if type.stackT == 1 { b.t += prev.t } else if type.stackT == 2 { b.t = max(prev.t, b.t) }
            if type.stackPow == 1 { b.pow += prev.pow } else if type.stackPow == 2 { b.pow = max(prev.pow, b.pow) }
            b.tm = max(b.t, b.tm)
        }
        buffs.append(b)
        refreshCps = true
        return b
    }
    func hasBuff(_ name: String) -> Buff? { buffs.first { $0.type.name == name } }
    func killBuff(_ name: String) { buffs.removeAll { $0.type.name == name }; refreshCps = true }
    func resetBuffs() { buffs = []; refreshCps = true }
    func logicBuffs(_ delta: Double) {
        for i in stride(from: buffs.count - 1, through: 0, by: -1) {
            buffs[i].t -= delta / Game.fps
            if buffs[i].t <= 0 { let dead = buffs.remove(at: i); refreshCps = true; Minigames.shared.onBuffDie(dead.type.name) }
        }
    }

    /// what each kind of buff does (the original buff types' effsFunc)
    func buffEffs(_ b: Buff) -> [(String, Double, Int)] {
        let n = b.type.name
        switch n {
        case "frenzy": return [("cpsBuffM", b.pow, 1), ("reindeerEffectsMultM", 0.75, 1)]
        case "elderFrenzy": return [("cpsBuffM", b.pow, 1), ("reindeerEffectsMultM", 0.5, 1)]
        case "clot", "dragonHarvest", "powerClick": return [("cpsBuffM", b.pow, 1)]
        case "sales": return [("buildingCostM", b.pow, 1)]
        case "clickFrenzy", "dragonflight": return [("clickM", b.pow, 1)]
        case "cursedFinger", "cookieStorm": return []
        default:
            if n.hasPrefix("buildingBuff"), let i = Int(n.dropFirst(12)), i < buildings.count {
                let a = Double(buildings[i].amount)
                return a <= 0 ? [] : [("cpsBuffM", a / 10 + 1, 1)]
            }
            if n.hasPrefix("buildingDebuff"), let i = Int(n.dropFirst(14)), i < buildings.count {
                let a = Double(buildings[i].amount)
                return a <= 0 ? [] : [("cpsBuffM", 1 / (a / 10 + 1), 1)]
            }
            return Minigames.shared.buffEffs(b)
        }
    }

    func buffDesc(_ b: Buff) -> String {
        let n = b.type.name
        func cpsDesc(_ p: Double) -> String {
            let s = p == 2 ? "doubled" : p == 0.5 ? "halved" : (p > 1 && p < 2) ? "+" + B((p - 1) * 100, 2) + "%" : "x" + B(p, 2)
            return "Cookie production <b>\(s)</b> for <b>[t]</b>."
        }
        var s: String
        switch n {
        case "frenzy", "elderFrenzy", "clot", "dragonHarvest", "powerClick": s = cpsDesc(b.pow)
        case "sales": s = "All buildings are <b>\(B(100 - b.pow * 100, 2))% cheaper</b> for <b>[t]</b>."
        case "cursedFinger": s = "Cookie production halted for <b>[t]</b>, but each click is worth <b>[t]</b> of CpS."
        case "clickFrenzy", "dragonflight": s = "Clicking power <b>x\(B(b.pow, 2))</b> for <b>[t]</b>."
        case "cookieStorm": s = "Cookies everywhere!"
        default:
            if n.hasPrefix("buildingBuff"), let i = Int(n.dropFirst(12)), i < buildings.count {
                let bl = buildings[i], a = Double(bl.amount)
                s = "Your <b>\(B(a)) \(bl.def.plural)</b> are boosting your CpS!<br>Cookie production <b>+\(B((a / 10 + 1) * 100 - 100, 2))%</b> for <b>[t]</b>."
            } else if n.hasPrefix("buildingDebuff"), let i = Int(n.dropFirst(14)), i < buildings.count {
                let bl = buildings[i], a = Double(bl.amount)
                s = "Your <b>\(B(a)) \(bl.def.plural)</b> are rusting your CpS!<br>Cookie production <b>\(B((a / 10 + 1) * 100 - 100, 2))% slower</b> for <b>[t]</b>."
            } else { s = Minigames.shared.buffDesc(b) }
        }
        return s.replacingOccurrences(of: "[t]", with: sayTime(b.tm * 1000, -1))
    }
}

// MARK: - Shimmers (golden cookies and reindeer)

final class ShimmerType {
    let name: String
    let delayMinBase: Double, delayMaxBase: Double, baseDur: Double
    var lastTime = now()
    var n = 0, i = 0, spawned = 0
    // golden cookie state
    var chain = 0, totalFromChain = 0.0, last = "", lastChainPos: (Double, Double)? = nil
    init(name: String, min: Double, max: Double, dur: Double) { self.name = name; delayMinBase = min; delayMaxBase = max; baseDur = dur }
    static func golden() -> ShimmerType { ShimmerType(name: "golden", min: 300, max: 900, dur: 13) }
    static func reindeer() -> ShimmerType { ShimmerType(name: "reindeer", min: 180, max: 360, dur: 8) }
    func reset() { chain = 0; totalFromChain = 0; last = ""; lastChainPos = nil }
}

final class Shimmer: Identifiable {
    let id = UUID()
    let type: ShimmerType
    var x = 0.0, y = 0.0, s = 1.0, r = 0.0
    var t = 0.0, dur = 13.0
    var wrath = false, force = "", noWrath = false, forceWrath = false, noCount = false, spawnLead = false
    var clicked = false
    var seq = 0
    var pic = 0
    init(_ type: ShimmerType) { self.type = type }
}

extension Game {
    func shimmerDelayMod(_ st: ShimmerType, _ mIn: Double) -> Double {
        var m = mIn
        if st.name == "golden" {
            m -= p("gcFreqA"); m /= p("gcFreqM")
            if st.chain > 0 { m = 0 }
        } else {
            m -= p("reindeerFreqA"); m /= p("reindeerFreqM")
        }
        return m
    }
    func shimmerDurMod(_ sh: Shimmer, _ dIn: Double) -> Double {
        var dur = dIn
        let st = sh.type
        if st.name == "golden" {
            if sh.wrath { dur = (dur + p("gcWrathLifeA")) * p("gcWrathLifeM") }
            else { dur = (dur + p("gcLifeA")) * p("gcLifeM") }
            dur *= pow(0.95, Double(st.n - 1))
            if st.chain > 0 { dur = max(2, 10 / Double(st.chain)) }
        } else {
            dur = (dur + p("reindeerLifeA")) * p("reindeerLifeM")
        }
        return dur
    }

    /// typeIndex 0 = golden, 1 = reindeer
    @discardableResult
    func spawnShimmer(_ typeIndex: Int, configure: ((Shimmer) -> Void)? = nil) -> Shimmer? {
        if explodeT > -1 || onAscend == 1 { return nil }
        let st = shimmerTypes[typeIndex]
        let sh = Shimmer(st)
        sh.dur = shimmerDurMod(sh, st.baseDur)
        configure?(sh)   // options given when spawning override the defaults, like the original
        if sh.spawnLead { st.lastTime = now() }
        sh.t = (Game.fps * sh.dur).rounded(.up)
        sh.seq = st.i; st.i += 1
        if !sh.noCount { st.n += 1 }
        shimmers.append(sh)
        pings.insert("cookie")
        if st.name == "golden" {
            sh.s = (sh.s) * (rnd() * 32 + 64)
            if ["easter", "halloween", "christmas", "valentines"].contains(season) { sh.r = (rnd() * 2 - 1) * 8 }
            else if season == "fools" { sh.r = 0; sh.s = 128 }
            else { sh.r = rnd() * 360 }
            sh.x = (rnd() * (playW - sh.s) + sh.s / 2).rounded(.down)
            sh.y = (rnd() * max(1, playH - sh.s - 128) + sh.s / 2 + 48).rounded(.down)
            if !sh.noWrath && (sh.forceWrath || (elderWrath == 1 && rnd() < 1.0 / 3) || (elderWrath == 2 && rnd() < 2.0 / 3) || elderWrath == 3) { sh.wrath = true }
            sh.pic = Int.random(in: 0..<8)
        } else {
            sh.r = 0
        }
        return sh
    }

    func clickShimmer(_ sh: Shimmer) {
        if sh.t <= 0 || sh.clicked { return }
        if sh.type.name == "golden" { clickGolden(sh) } else { clickReindeer(sh) }
        sh.clicked = true
        sh.t = 0
    }

    private func clickReindeer(_ sh: Shimmer) {
        var val = cookiesPs * 60
        val += p("reindeerEffectsMultA")
        val *= p("reindeerEffectsMultM")
        let moni = max(25, val)
        earn(moni)
        if hasBuff("elderFrenzy") != nil { win("Eldeer") }
        toast("+" + B(moni) + " cookies!", "", nil, true)
        Seasons.dropReindeer(self, 0.8)
        if sh.spawnLead { reindeerClicks += 1; reindeerClicksTotal += 1 }
        Sound.play("snd/jingleClick.mp3")
    }

    private func clickGolden(_ me: Shimmer) {
        let st = me.type
        var list: [String] = []
        if me.wrath { list += ["clot", "multiply cookies", "ruin cookies"] } else { list += ["frenzy", "multiply cookies"] }
        if me.wrath && Minigames.shared.hasGod("scorn") > 0 { list += ["clot", "ruin cookies", "clot", "ruin cookies"] }
        if me.wrath && rnd() < 0.3 { list += ["blood frenzy", "chain cookie", "cookie storm"] }
        else if rnd() < 0.03 && cookiesEarned >= 100000 { list += ["chain cookie", "cookie storm"] }
        if rnd() < 0.05 && season == "fools" { list.append("everything must go") }
        if rnd() < 0.1 && (rnd() < 0.05 || hasBuff("dragonflight") == nil) { list.append("click frenzy") }
        if me.wrath && rnd() < 0.1 { list.append("cursed finger") }
        if buildingsN >= 10 && rnd() < 0.25 { list.append("building special") }
        if Lumps.canLumps(self) && rnd() < 0.0005 { list.append("free sugar lump") }
        if (!me.wrath && rnd() < 0.15) || rnd() < 0.05 {
            if rnd() < auraMult("Reaper of Fields") { list.append("dragon harvest") }
            if rnd() < auraMult("Dragonflight") { list.append("dragonflight") }
        }
        if st.last != "" && rnd() < 0.8, let i = list.firstIndex(of: st.last) { list.remove(at: i) }
        if Has("Golden switch [off]"), let i = list.firstIndex(of: "chain cookie") { list.remove(at: i) }
        if rnd() < 0.0001 { list.append("blab") }
        var choice = list.isEmpty ? "frenzy" : choose(list)
        if st.chain > 0 || me.force == "chain cookie" { st.lastChainPos = (me.x, me.y) }
        if st.chain > 0 { choice = "chain cookie" }
        if me.force != "" { st.chain = 0; choice = me.force; me.force = "" }
        if choice != "chain cookie" { st.chain = 0 }
        st.last = choice

        var powerClick = false
        if powerClicksOn && powerClicks >= 1 {
            powerClicks -= 1
            powerClick = true
            Sound.play("snd/powerShimmer.mp3", 0.4)
            Sound.play("snd/powerClick\(Int.random(in: 1...3))b.mp3", 0.7 - rnd() * 0.3)
        }

        var effectDurMod = 1.0
        if me.wrath { effectDurMod = (effectDurMod + p("gcWrathEffectsLifeA")) * p("gcWrathEffectsLifeM") }
        else { effectDurMod = (effectDurMod + p("gcEffectsLifeA")) * p("gcEffectsLifeM") }
        effectDurMod *= Minigames.shared.goldenEffectDurMod(self)
        var mult = 1.0
        if me.wrath { mult = (mult + p("gcWrathEffectsMultA")) * p("gcWrathEffectsMultM") }
        else { mult = (mult + p("gcEffectsMultA")) * p("gcEffectsMultM") }
        mult *= Minigames.shared.goldenGainMod(self, wrath: me.wrath)
        if powerClick { effectDurMod *= 1.2; mult *= 1.2 }

        var popup: (String, String)? = nil
        var buff: Buff? = nil
        func dur(_ s: Double) -> Double { (s * effectDurMod).rounded(.up) }

        if choice == "building special" {
            let time = dur(30)
            let candidates = buildings.filter { $0.amount >= 10 }
            if candidates.isEmpty { choice = "frenzy" }
            else {
                let obj = choose(candidates)
                let pw = Double(obj.amount) / 10 + 1
                if me.wrath && rnd() < 0.3 { buff = addBuff("buildingDebuff\(obj.id)", t: time, pow: pw) }
                else { buff = addBuff("buildingBuff\(obj.id)", t: time, pow: pw) }
            }
        }
        switch choice {
        case "free sugar lump":
            Lumps.gain(self, 1)
            popup = ("Sweet!", "Found 1 sugar lump!")
        case "frenzy": buff = addBuff("frenzy", t: dur(77), pow: 7)
        case "dragon harvest": buff = addBuff("dragonHarvest", t: dur(60), pow: 15)
        case "everything must go": buff = addBuff("sales", t: dur(8), pow: 0.95)
        case "multiply cookies":
            let moni = mult * min(cookies * 0.15, cookiesPs * 60 * 15) + 13
            earn(moni)
            popup = ("Lucky!", "+" + B(moni) + " cookies!")
        case "ruin cookies":
            var moni = min(cookies * 0.05, cookiesPs * 60 * 10) + 13
            moni = min(cookies, moni)
            spend(moni)
            popup = ("Ruin!", "Lost " + B(moni) + " cookies!")
        case "blood frenzy": buff = addBuff("elderFrenzy", t: dur(6), pow: 666)
        case "clot": buff = addBuff("clot", t: dur(66), pow: 0.5)
        case "cursed finger": buff = addBuff("cursedFinger", t: dur(10), pow: cookiesPs * dur(10))
        case "click frenzy": buff = addBuff("clickFrenzy", t: dur(13), pow: 777)
        case "dragonflight":
            buff = addBuff("dragonflight", t: dur(10), pow: 1111)
            if rnd() < 0.8 { killBuff("clickFrenzy") }
        case "chain cookie":
            if st.chain == 0 { st.totalFromChain = 0 }
            st.chain += 1
            let digit = me.wrath ? 6.0 : 7.0
            if st.chain == 1 { st.chain += max(0, Int((log(cookies) / M_LN10).rounded(.up)) - 10) }
            let maxPayout = min(cookiesPs * 60 * 60 * 6, cookies * 0.5) * mult
            let moni = max(digit, min((1.0 / 9 * pow(10, Double(st.chain)) * digit * mult).rounded(.down), maxPayout))
            let nextMoni = max(digit, min((1.0 / 9 * pow(10, Double(st.chain + 1)) * digit * mult).rounded(.down), maxPayout))
            st.totalFromChain += moni
            if rnd() < 0.01 || nextMoni >= maxPayout {
                st.chain = 0
                popup = ("Cookie chain over!", "+" + B(moni) + " cookies!<br>You made " + B(st.totalFromChain) + " cookies.")
            } else {
                popup = ("Cookie chain", "+" + B(moni) + " cookies!")
            }
            earn(moni)
        case "cookie storm": buff = addBuff("cookieStorm", t: dur(7), pow: 7)
        case "cookie storm drop":
            let moni = max(mult * (cookiesPs * 60 * Double(Int.random(in: 1...7))), Double(Int.random(in: 1...7)))
            earn(moni)
            Effects.shared.floatText("+" + B(moni), me.x, me.y)
        case "blab":
            popup = ("", choose(Game.blabs))
        default: break
        }
        if let b = buff { toast(b.type.nameD, buffDesc(b), b.type.icon, true) }
        else if let (t, x) = popup { toast(t, x, nil, true) }
        Seasons.dropEgg(self, 0.9)
        if me.spawnLead {
            gcClicks += 1; gcClicksTotal += 1
            if me.t / Game.fps >= me.dur - 1 { win("Early bird") }
            if me.t / Game.fps <= 1 { win("Fading luck") }
            if me.wrath { win("Wrath cookie") }
        }
        Minigames.shared.onGoldenClick(self)
        if choice == "cookie storm drop" { Sound.play("snd/clickb\(Int.random(in: 1...7)).mp3", 0.75) }
        else { Sound.play("snd/shimmerClick.mp3") }
        Effects.shared.sparkle(me.x, me.y)
    }

    static let blabs = [
        "Cookie crumbliness x3 for 60 seconds!", "Chocolatiness x7 for 77 seconds!", "Dough elasticity halved for 66 seconds!",
        "Golden cookie shininess doubled for 3 seconds!", "World economy halved for 30 seconds!", "Grandma kisses 23% stingier for 45 seconds!",
        "Thanks for clicking!", "Fooled you! This one was just a test.", "Golden cookies clicked +1!",
        "Your click has been registered. Thank you for your cooperation.", "Thanks! That hit the spot!", "Thank you. A team has been dispatched.",
        "They know.", "Oops. This was just a chocolate cookie with shiny aluminium foil.",
        "Huh? Oh, there was nothing there.", "You saw nothing.", "It seems you hallucinated that golden cookie.",
        "This golden cookie was a complete fabrication.",
        "In theory there's no wrong way to click a golden cookie, but you just did that, somehow.",
        "All cookies multiplied by 999!<br>All cookies divided by 999!", "Why?",
    ]

    func logicShimmers(_ delta: Double) {
        for i in stride(from: shimmers.count - 1, through: 0, by: -1) {
            let me = shimmers[i]
            if me.t > 0 { me.t -= delta }
            if me.t <= 0 {
                if !me.clicked {
                    if me.type.name == "golden" {
                        if me.type.chain > 0 && me.type.totalFromChain > 0 {
                            toast("Cookie chain broken", "You made " + B(me.type.totalFromChain) + " cookies.", nil, true)
                            me.type.chain = 0; me.type.totalFromChain = 0
                        }
                        if me.spawnLead { gcMissed += 1 }
                    } else if me.spawnLead { reindeerMissed += 1 }
                }
                shimmers.remove(at: i)
                if !me.noCount { me.type.n = max(0, me.type.n - 1) }
                if me.spawnLead { me.type.lastTime = now(); me.type.spawned = 0 }
                if shimmers.isEmpty { pings.remove("cookie") }
            }
        }
        if rnd() < 0.5 && hasBuff("cookieStorm") != nil {
            spawnShimmer(0) { sh in sh.force = "cookie storm drop"; sh.noCount = true; sh.dur = (rnd() * 4 + 1).rounded(.up); sh.s = rnd() * 0.5 + 0.5 }
        }
        for (i, st) in shimmerTypes.enumerated() {
            let can = st.name == "golden" ? !Has("Golden switch [off]") : season == "christmas"
            if st.spawned == 0 && can {
                let mn = shimmerDelayMod(st, st.delayMinBase)
                let mx = shimmerDelayMod(st, st.delayMaxBase)
                let chance = pow(max(0, ((now() - st.lastTime) / 1000 - mn) / max(0.0001, mx - mn)), 5)
                if rnd() < chance {
                    spawnShimmer(i) { $0.spawnLead = true }
                    if Has("Distilled essence of redoubled luck") && rnd() < 0.01 { spawnShimmer(i) }
                    st.spawned = 1
                }
            }
        }
    }
    func resetShimmers() {
        shimmers = []
        for st in shimmerTypes { st.i = 0; st.n = 0; st.spawned = 0; st.lastTime = now(); st.reset() }
        refreshCps = true
    }
}
