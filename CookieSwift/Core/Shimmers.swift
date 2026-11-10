import Foundation

// Port of www/main.js "SHIMMERS" section: golden cookies and reindeer.

final class ShimmerType {
    let name: String
    var delayMinBase: Double
    var delayMaxBase: Double
    var lastTime = nowMs()
    var dur: Double
    var n = 0
    var i = 0
    var spawned = 0
    // golden cookie chain state
    var chain = 0
    var totalFromChain = 0.0
    var last = ""
    var lastChainPos: (Double, Double)? = nil
    init(name: String, delayMinBase: Double, delayMaxBase: Double, dur: Double) {
        self.name = name; self.delayMinBase = delayMinBase; self.delayMaxBase = delayMaxBase; self.dur = dur
    }
    func reset() {
        if name == "golden" { chain = 0; totalFromChain = 0; last = ""; lastChainPos = nil }
    }
    func spawnConditions() -> Bool {
        if name == "golden" { return !G.Has("Golden switch [off]") }
        return G.season == "christmas"
    }
    func delayMod(_ mIn: Double) -> Double {
        var m = mIn
        if name == "golden" {
            m -= G.pool["gcFreqA"]!
            m /= G.pool["gcFreqM"]!
            if chain > 0 { m = 0 }
            return m
        }
        m -= G.pool["reindeerFreqA"]!
        m /= G.pool["reindeerFreqM"]!
        return m
    }
    func durMod(_ me: Shimmer, _ durIn: Double) -> Double {
        var d = durIn
        if name == "golden" {
            if me.wrath { d = (d + G.pool["gcWrathLifeA"]!) * G.pool["gcWrathLifeM"]! }
            else { d = (d + G.pool["gcLifeA"]!) * G.pool["gcLifeM"]! }
            d *= pow(0.95, Double(n - 1))
            if chain > 0 { d = max(2, 10 / Double(chain)) }
            return d
        }
        return (d + G.pool["reindeerLifeA"]!) * G.pool["reindeerLifeM"]!
    }
}

final class Shimmer {
    let type: ShimmerType
    var spawnLead = false
    var dur = 13.0
    var t = 0.0
    var id = 0
    var noCount = false
    var clicked = false
    var s = 1.0
    var r = 0.0
    var x = 0.0, y = 0.0
    var wrath = false
    var force = ""
    var noWrath = false
    var forceWrath = false
    /// picked once when the shimmer is first shown (seasonal sprites)
    var frame = -1
    init(_ type: ShimmerType) { self.type = type }

    func click() {
        if t <= 0 || clicked { return }
        if type.name == "golden" { G.clickGolden(self) } else { G.clickReindeer(self) }
        clicked = true
        t = 0
    }
}

struct ShimmerOptions {
    var spawnLead = false
    var noCount = false
    var force = ""
    var noWrath = false
    var forceWrath = false
    var dur: Double? = nil
    var s: Double? = nil
}

extension Game {
    func initShimmerTypes() {
        let golden = ShimmerType(name: "golden", delayMinBase: 60 * 5, delayMaxBase: 60 * 15, dur: 13)
        let reindeer = ShimmerType(name: "reindeer", delayMinBase: 60 * 3, delayMaxBase: 60 * 6, dur: 8)
        shimmerTypes = [golden, reindeer]
        shimmerTypesBN = ["golden": golden, "reindeer": reindeer]
    }

    func resetShimmers() {
        shimmers = []
        for me in shimmerTypes {
            me.i = 0; me.n = 0; me.spawned = 0
            me.lastTime = nowMs()
            me.reset()
        }
        refreshCps = true
    }

    /// new G.shimmer(type,o)
    @discardableResult
    func newShimmer(_ typeName: String, _ o: ShimmerOptions = ShimmerOptions()) -> Shimmer? {
        if explodeT > -1 || onAscend == 1 { return nil }
        guard let type = shimmerTypesBN[typeName] else { return nil }
        let me = Shimmer(type)
        me.spawnLead = false
        // durMod runs before transfer(me,o), so it sees the shimmer without its options (wrath=false)
        me.dur = type.durMod(me, type.dur)
        me.spawnLead = o.spawnLead
        me.noCount = o.noCount
        me.force = o.force
        me.noWrath = o.noWrath
        me.forceWrath = o.forceWrath
        if let d = o.dur { me.dur = d }
        if let s = o.s { me.s = s }
        if me.spawnLead { type.lastTime = nowMs() }
        me.t = (fps * me.dur).rounded(.up)
        me.id = type.i
        type.i += 1
        if !me.noCount { type.n += 1 }
        me.clicked = false
        shimmers.append(me)
        pingScreen("cookie")
        if type.name == "golden" { initGolden(me, hadSize: o.s != nil) } else { me.s = o.s ?? 1; me.r = 0; me.x = 0; me.y = 0 }
        return me
    }

    private func initGolden(_ me: Shimmer, hadSize: Bool) {
        let type = me.type
        me.s = (hadSize ? me.s : 1) * (JSMath.random() * 32 + 64)
        if season == "easter" || season == "halloween" || season == "christmas" || season == "valentines" {
            me.r = (JSMath.random() * 2 - 1) * 8
        } else if season == "fools" {
            me.r = 0
            me.s = 128
        } else { me.r = JSMath.random() * 360 }
        me.x = (JSMath.random() * (w - me.s) + me.s / 2).rounded(.down)
        me.y = (JSMath.random() * (h - me.s - 128) + me.s / 2 + 48).rounded(.down)
        me.wrath = false
        // the || chain short-circuits, so the random rolls only happen at the matching wrath level
        var isWrath = false
        if !me.noWrath {
            if me.forceWrath { isWrath = true }
            else if elderWrath == 1 && JSMath.random() < 1.0 / 3 { isWrath = true }
            else if elderWrath == 2 && JSMath.random() < 2.0 / 3 { isWrath = true }
            else if elderWrath == 3 { isWrath = true }
        }
        me.wrath = isWrath
        if type.chain > 0, let (x1, y1) = type.lastChainPos, me.force == "" {
            let x2 = me.x, y2 = me.y
            let d = ((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)).squareRoot()
            let n = max(1, Int((d / 40).rounded(.up)))
            for i in 0...n {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) / Double(n) * 0.25) {
                    self.particleAt(Particle(x: x1 + (x2 - x1) * (Double(i) / Double(n)), y: y1 + (y2 - y1) * (Double(i) / Double(n)),
                                             xd: (JSMath.random() - 0.5) * 4, yd: (JSMath.random() - 0.5) * 4,
                                             s: 0.5 + JSMath.random() * 0.3, sd: 0.7 + JSMath.random() * 0.2,
                                             r: JSMath.random() * Double.pi * 360, rd: JSMath.random() * 10 - 5,
                                             grav: 0, a: 0.75, life: 0.2, pic: .flare))
                }
            }
        }
    }

    // MARK: golden cookie click
    func clickGolden(_ me: Shimmer) {
        let type = me.type
        var list: [String] = []
        if me.wrath { list += ["clot", "multiply cookies", "ruin cookies"] }
        else { list += ["frenzy", "multiply cookies"] }
        if me.wrath && hasGod("scorn") > 0 { list += ["clot", "ruin cookies", "clot", "ruin cookies"] }
        if me.wrath && JSMath.random() < 0.3 { list += ["blood frenzy", "chain cookie", "cookie storm"] }
        else if JSMath.random() < 0.03 && cookiesEarned >= 100000 { list += ["chain cookie", "cookie storm"] }
        if JSMath.random() < 0.05 && season == "fools" { list.append("everything must go") }
        if JSMath.random() < 0.1 && (JSMath.random() < 0.05 || hasBuff("dragonflight") == nil) { list.append("click frenzy") }
        if me.wrath && JSMath.random() < 0.1 { list.append("cursed finger") }
        if buildingsN >= 10 && JSMath.random() < 0.25 { list.append("building special") }
        if (!me.wrath && JSMath.random() < 0.15) || JSMath.random() < 0.05 {
            if JSMath.random() < auraMult("Reaper of Fields") { list.append("dragon harvest") }
            if JSMath.random() < auraMult("Dragonflight") { list.append("dragonflight") }
        }
        if type.last != "" && JSMath.random() < 0.8, let idx = list.firstIndex(of: type.last) { list.remove(at: idx) }
        if Has("Golden switch [off]"), let idx = list.firstIndex(of: "chain cookie") { list.remove(at: idx) }
        if JSMath.random() < 0.0001 { list.append("blab") }
        var choice = choose(list)

        if type.chain > 0 || me.force == "chain cookie" { type.lastChainPos = (me.x, me.y) }
        if type.chain > 0 { choice = "chain cookie" }
        if me.force != "" { type.chain = 0; choice = me.force; me.force = "" }
        if choice != "chain cookie" { type.chain = 0 }
        type.last = choice

        var powerClick = false
        if powerClicksOn && powerClicks >= 1 {
            spendPowerClick()
            powerClick = true
            PlaySound("snd/powerShimmer.mp3", 0.4)
            PlaySound("snd/powerClick" + choose(["1", "2", "3"]) + "b.mp3", 0.7 - JSMath.random() * 0.3)
        }

        if choice != "" {
            var effectDurMod = 1.0
            if me.wrath { effectDurMod = (effectDurMod + pool["gcWrathEffectsLifeA"]!) * pool["gcWrathEffectsLifeM"]! }
            else { effectDurMod = (effectDurMod + pool["gcEffectsLifeA"]!) * pool["gcEffectsLifeM"]! }
            var mult = 1.0
            if me.wrath { mult = (mult + pool["gcWrathEffectsMultA"]!) * pool["gcWrathEffectsMultM"]! }
            else { mult = (mult + pool["gcEffectsMultA"]!) * pool["gcEffectsMultM"]! }
            if powerClick { effectDurMod *= 1.2; mult *= 1.2 }

            var popup = ""
            var buff: Buff? = nil

            if choice == "building special" {
                let time = (30 * effectDurMod).rounded(.up)
                let candidates = buildings.filter { $0.amount >= 10 }
                if candidates.isEmpty { choice = "frenzy" }
                else {
                    let obj = choose(candidates)
                    let pw = Double(obj.amount) / 10 + 1
                    if me.wrath && JSMath.random() < 0.3 { buff = addBuff("buildingDebuff\(obj.id)", t: time, pow: pw) }
                    else { buff = addBuff("buildingBuff\(obj.id)", t: time, pow: pw) }
                }
            }
            if choice == "frenzy" { buff = addBuff("frenzy", t: (77 * effectDurMod).rounded(.up), pow: 7) }
            else if choice == "dragon harvest" { buff = addBuff("dragonHarvest", t: (60 * effectDurMod).rounded(.up), pow: 15) }
            else if choice == "everything must go" { buff = addBuff("sales", t: (8 * effectDurMod).rounded(.up), pow: 0.95) }
            else if choice == "multiply cookies" {
                let moni = mult * min(cookies * 0.15, cookiesPs * 60 * 15) + 13
                earn(moni)
                popup = "Lucky!|+" + B(moni) + " cookies!"
            } else if choice == "ruin cookies" {
                var moni = min(cookies * 0.05, cookiesPs * 60 * 10) + 13
                moni = min(cookies, moni)
                spend(moni)
                popup = "Ruin!|Lost " + B(moni) + " cookies!"
            } else if choice == "blood frenzy" { buff = addBuff("elderFrenzy", t: (6 * effectDurMod).rounded(.up), pow: 666) }
            else if choice == "clot" { buff = addBuff("clot", t: (66 * effectDurMod).rounded(.up), pow: 0.5) }
            else if choice == "cursed finger" {
                let t = (10 * effectDurMod).rounded(.up)
                buff = addBuff("cursedFinger", t: t, pow: cookiesPs * t)
            } else if choice == "click frenzy" { buff = addBuff("clickFrenzy", t: (13 * effectDurMod).rounded(.up), pow: 777) }
            else if choice == "dragonflight" {
                buff = addBuff("dragonflight", t: (10 * effectDurMod).rounded(.up), pow: 1111)
                if JSMath.random() < 0.8 { killBuff("clickFrenzy") }
            } else if choice == "chain cookie" {
                if type.chain == 0 { type.totalFromChain = 0 }
                type.chain += 1
                let digit = me.wrath ? 6.0 : 7.0
                if type.chain == 1 { type.chain += max(0, Int((log(cookies) / M_LN10).rounded(.up)) - 10) }
                let maxPayout = min(cookiesPs * 60 * 60 * 6, cookies * 0.5) * mult
                let moni = max(digit, min((1.0 / 9 * pow(10, Double(type.chain)) * digit * mult).rounded(.down), maxPayout))
                let nextMoni = max(digit, min((1.0 / 9 * pow(10, Double(type.chain + 1)) * digit * mult).rounded(.down), maxPayout))
                type.totalFromChain += moni
                let moniStr = B(moni)
                if JSMath.random() < 0.01 || nextMoni >= maxPayout {
                    type.chain = 0
                    popup = "Cookie chain over!|+" + moniStr + " cookies!<br>You made " + B(type.totalFromChain) + " cookies."
                    for i in 0...10 {
                        let a = (Double(i) / 10) * Double.pi * 2
                        particleAt(Particle(x: me.x + sin(a) * me.s * 0.4, y: me.y + cos(a) * me.s * 0.4,
                                            xd: sin(a) * 6, yd: cos(a) * 6,
                                            s: 0.5 + JSMath.random() * 0.3, sd: 0.7 + JSMath.random() * 0.2,
                                            r: JSMath.random() * Double.pi * 360, rd: JSMath.random() * 10 - 5,
                                            grav: 0, a: 0.75, life: 0.6, pic: .flare))
                    }
                } else {
                    popup = "Cookie chain|+" + moniStr + " cookies!"
                }
                earn(moni)
            } else if choice == "cookie storm" { buff = addBuff("cookieStorm", t: (7 * effectDurMod).rounded(.up), pow: 7) }
            else if choice == "cookie storm drop" {
                let moni = max(mult * (cookiesPs * 60 * (JSMath.random() * 7 + 1).rounded(.down)), (JSMath.random() * 7 + 1).rounded(.down))
                earn(moni)
                particleAt(Particle(x: me.x, y: me.y, xd: JSMath.random() * 8 - 4, yd: -JSMath.random() * 3 - 5, str: "+" + B(moni)))
            } else if choice == "blab" {
                let str = choose([
                    "Cookie crumbliness x3 for 60 seconds!",
                    "Chocolatiness x7 for 77 seconds!",
                    "Dough elasticity halved for 66 seconds!",
                    "Golden cookie shininess doubled for 3 seconds!",
                    "World economy halved for 30 seconds!",
                    "Grandma kisses 23% stingier for 45 seconds!",
                    "Thanks for clicking!",
                    "Fooled you! This one was just a test.",
                    "Golden cookies clicked +1!",
                    "Your click has been registered. Thank you for your cooperation.",
                    "Thanks! That hit the spot!",
                    "Thank you. A team has been dispatched.",
                    "They know.",
                    "Oops. This was just a chocolate cookie with shiny aluminium foil.",
                    "Eschaton immanentized!",
                    "Oh, that tickled!",
                    "Again.",
                    "You've made a grave mistake.",
                    "Chocolate chips reshuffled!",
                    "Randomized chance card outcome!",
                    "Mouse acceleration +0.03%!",
                    "Ascension bonuses x5,000 for 0.1 seconds!",
                    "Gained 1 extra!",
                    "Sorry, better luck next time!",
                    "I felt that.",
                    "Nice try, but no.",
                    "Wait, sorry, I wasn't ready yet.",
                    "Yippee!",
                    "Bones removed.",
                    "Organs added.",
                    "Did you just click that?",
                    "Huh? Oh, there was nothing there.",
                    "You saw nothing.",
                    "It seems you hallucinated that golden cookie.",
                    "This golden cookie was a complete fabrication.",
                    "In theory there's no wrong way to click a golden cookie, but you just did that, somehow.",
                    "All cookies multiplied by 999!<br>All cookies divided by 999!",
                    "Why?",
                ])
                popup = "|<div style=\"margin:8px 16px;\">\(str)</div>"
            }

            if popup != "" || buff != nil {
                var title = "", text = ""
                if popup != "" {
                    let parts = popup.components(separatedBy: "|")
                    title = parts[0]; text = parts.count > 1 ? parts[1] : ""
                }
                if let b = buff {
                    title = b.type.nameD
                    text = b.type.desc(b).replacingOccurrences(of: "[t]", with: sayTime(b.tm * 1000, -1))
                }
                toast(title, text, buff?.type.icon, true)
            }

            DropEgg(0.9)

            if me.spawnLead {
                gcClicks += 1
                gcClicksTotal += 1
                if me.t / fps >= me.dur - 1 { win("Early bird") }
                if me.t / fps <= 1 { win("Fading luck") }
                if me.wrath { win("Wrath cookie") }
            }
            if choice == "cookie storm drop" { PlaySound("snd/clickb\(Int((JSMath.random() * 7 + 1).rounded(.down))).mp3", 0.75) }
            else { PlaySound("snd/shimmerClick.mp3") }
            sparkleAt(me.x, me.y)
        }
        Minigames.onGoldenClicked(me)
    }

    func dieGolden(_ me: Shimmer) {
        let type = me.type
        if type.chain > 0 && type.totalFromChain > 0 {
            toast("Cookie chain broken", "You made " + B(type.totalFromChain) + " cookies.", nil, true)
            type.chain = 0; type.totalFromChain = 0
        }
        if me.spawnLead { gcMissed += 1 }
    }

    // MARK: reindeer
    func clickReindeer(_ me: Shimmer) {
        var val = cookiesPs * 60
        val += pool["reindeerEffectsMultA"]!
        val *= pool["reindeerEffectsMultM"]!
        let moni = max(25, val)
        earn(moni)
        let popup = "+" + B(moni) + " cookies!"
        if hasBuff("elderFrenzy") != nil { win("Eldeer") }
        toast(popup, "", nil, true)
        DropReindeer(0.8)
        if me.spawnLead { reindeerClicks += 1; reindeerClicksTotal += 1 }
        PlaySound("snd/jingleClick.mp3")
        // G.sparkleOn(me.l): the middle of the reindeer picture
        sparkleAt(me.x - 167.0 / 2 + 167 * 0.5, me.y - 212.0 / 2 + 212 * 0.5)
    }
    /// reindeer position is updated while drawn (draw function in the original)
    func updateReindeer(_ me: Shimmer) {
        let r = 1 - me.t / (fps * me.dur)
        me.x = (w + 167) * r + sin(Double(T) * 0.1 + Double(me.id)) * 32 - 167.0 / 2
        me.y = (h + 212) * r - abs(cos(Double(T) * 0.1 + Double(me.id)) * 16) - 212.0 / 2
    }

    // MARK: G.logicShimmers
    func logicShimmers(_ delta: Double) {
        var i = shimmers.count - 1
        while i >= 0 {
            let me = shimmers[i]
            if me.t > 0 { me.t -= delta }
            if me.t <= 0 {
                if !me.clicked {
                    if me.type.name == "golden" { dieGolden(me) } else if me.spawnLead { reindeerMissed += 1 }
                }
                shimmers.remove(at: i)
                if !me.noCount { me.type.n = max(0, me.type.n - 1) }
                if me.spawnLead {
                    me.type.lastTime = nowMs()
                    me.type.spawned = 0
                }
                if shimmers.isEmpty { unpingScreen("cookie") }
            }
            i -= 1
        }
        // cookie storm!
        if JSMath.random() < 0.5 && hasBuff("cookieStorm") != nil {
            var o = ShimmerOptions()
            o.force = "cookie storm drop"; o.noCount = true
            o.dur = (JSMath.random() * 4 + 1).rounded(.up)
            o.s = JSMath.random() * 0.5 + 0.5
            newShimmer("golden", o)
        }
        // spawn shimmers
        for me in shimmerTypes {
            if me.spawned == 0 && me.spawnConditions() {
                let mn = me.delayMod(me.delayMinBase)
                let mx = me.delayMod(me.delayMaxBase)
                if JSMath.random() < pow(max(0, ((nowMs() - me.lastTime) / 1000 - mn) / (mx - mn)), 5) {
                    var o = ShimmerOptions(); o.spawnLead = true
                    newShimmer(me.name, o)
                    if Has("Distilled essence of redoubled luck") && JSMath.random() < 0.01 { newShimmer(me.name) }
                    me.spawned = 1
                }
            }
        }
    }

    func shimmersOnResize() {
        for me in shimmers {
            me.x = max(min(me.x, w - me.s / 2), me.s / 2)
            me.y = max(min(me.y, h - me.s - 128 + 48), me.s / 2 + 48)
        }
    }
}
