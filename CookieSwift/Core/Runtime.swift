import Foundation

// Port of the remaining runtime sections of www/main.js: PARTICLES, sparkles, TICKER (logic),
// hidden slots, screens (setScreen/pingScreen/screenLogic), toasts, the big cookie's "freeCookie" drag,
// research, plus G.Init.

// MARK: - particles

enum ParticlePic {
    case none
    case cookie                 // 'cookie': a random small cookie
    case cookieIcon             // a random owned cookie upgrade icon
    case icon([Int])            // an icon from icons.png
    case image(String)          // a 64px frame from a strip picture (random frame)
    case flare                  // the 128px flare (cssText in the original)
    case wrinklerBits(shiny: Bool, frame: Int)
}

final class Particle {
    var x = 0.0, y = 0.0, xd = 0.0, yd = 0.0
    var s = 1.0, sd = 1.0
    var grav = 1.0
    var str: String? = nil
    var pic: ParticlePic = .none
    var a = 1.0
    var r: Double? = nil
    var rd = 0.0
    var t = -1.0
    var life = 1.0
    /// worked out when the particle is shown (random frame or icon)
    var iconPos: [Int]? = nil
    var frameX = 0.0
    var imageName: String? = nil
    var rot: Double { r ?? 0 }
    init() {}
    init(x: Double = 0, y: Double = 0, xd: Double = 0, yd: Double = 0, s: Double = 1, sd: Double = 1, r: Double? = nil, rd: Double = 0,
         grav: Double = 1, a: Double = 1, life: Double = 1, str: String? = nil, pic: ParticlePic = .none) {
        self.x = x; self.y = y; self.xd = xd; self.yd = yd; self.s = s; self.sd = sd; self.r = r; self.rd = rd
        self.grav = grav; self.a = a; self.life = life; self.str = str; self.pic = pic
    }
}

struct TickerLine {
    var text = ""
    var w = 0.0
    var x = 0.0
    var onClick: (() -> Void)? = nil
}

/// The big cookie can be pulled loose and dragged around (cookie screen's this.freeCookie).
final class FreeCookie {
    var on = false
    var startPull = 0.0, lastOn = 0.0, lastReleased = 0.0
    var x = 0.0, xd = 0.0, xprev = 0.0
    var y = 0.0, yd = 0.0, yprev = 0.0
    var s = 1.0, pull = 0.0, d = 0.0, a = 0.0

    func start() {
        PlaySound("snd/click\(Int((JSMath.random() * 7 + 1).rounded(.down))).mp3", 0.75)
        G.bigCookieSizeD = -0.5
        on = true
        lastOn = nowMs()
        lastReleased = 0
    }
    func logic(_ dd: Double) {
        if G.getSet("dislodge") == 0 { return }
        if on && G.bigCookieState != 1 && lastReleased == 0 {
            xd = (x - xprev) * 1
            yd = (y - yprev) * 1
            lastReleased = nowMs()
            G.bigCookieSizeD = 0.05
        }
        if G.bigCookieState == 1 && startPull == 0 { startPull = nowMs() }
        if G.bigCookieState == 1 || lastReleased > 0 {
            if x != 0 && y != 0 { xprev = x; yprev = y }
            if lastReleased == 0 {
                x = G.onX / G.w - 0.5
                y = G.onY / G.h - 0.5
                s = 0.5
                if on {
                    let w = (120 * s) / G.w
                    let h = (120 * s) / G.h
                    x = max(-0.5 + w, min(0.5 - w, x))
                    y = max(-0.5 + h, min(0.5 - h, y))
                }
            } else {
                let r = pow((nowMs() - lastReleased) / (1000 * 0.75), 4)
                x += xd; y += yd
                xd *= 0.95; yd *= 0.95
                yd += 0.01 * dd
                x = 0 * r + x * (1 - r)
                y = 0 * r + y * (1 - r)
                s = 0.5 + 0.5 * r
                let w = (120 * s) / G.w
                let h = (120 * s) / G.h
                let xdprev = xd, ydprev = yd
                if x < -0.5 + w { xd = abs(xd) } else if x > 0.5 - w { xd = -abs(xd) }
                if y < -0.5 + h { yd = abs(yd) } else if y > 0.5 - h { yd = -abs(yd) }
                if xd != xdprev || yd != ydprev {
                    G.bigCookieSizeD += 0.1
                    PlaySound("snd/clickb\(Int((JSMath.random() * 7 + 1).rounded(.down))).mp3", 0.3)
                }
                if r >= 1 { lastReleased = 0 }
            }
            if on && lastReleased == 0 {
                let milkH = G.h - (240 + 35) * G.milkLevel
                let cookieBottom = (y + 0.5) * G.h + 30
                let cookieBottomPrev = (yprev + 0.5) * G.h + 30
                if nowMs() - lastOn > 1000 * 0.5 {
                    if (cookieBottom - milkH) >= 15 && (cookieBottomPrev - milkH) < 15 {
                        PlaySound("snd/clickb\(Int((JSMath.random() * 7 + 1).rounded(.down))).mp3", 0.3)
                        G.bigCookieSizeD += 0.1
                        if !G.HasAchiev("Cookie-dunker") {
                            PlaySound("snd/shimmerClick.mp3", 1)
                            G.win("Cookie-dunker")
                        }
                    } else if (cookieBottom - milkH) <= 15 && (cookieBottomPrev - milkH) > 15 {
                        PlaySound("snd/clickb\(Int((JSMath.random() * 7 + 1).rounded(.down))).mp3", 0.3)
                        G.bigCookieSizeD -= 0.1
                    }
                }
            }
            if !on {
                lastReleased = 0
                let dx = x - xprev, dy = y - yprev
                pull *= 0.95
                let vel = min(0.2, (dx * dx + dy * dy).squareRoot())
                let x1 = 0.0, y1 = 0.0, x2 = x, y2 = y
                a = -atan2(y1 - y2, x1 - x2) - Double.pi / 2
                d = ((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)).squareRoot() * (1 - G.bigCookieSize) * 5
                if d > 0.09 { pull += vel }
                if pull >= 1 && nowMs() - startPull >= 600 { start() }
            }
            if G.bigCookieState == 1 && lastReleased > 0 { start() }
        }
        if G.bigCookieState != 1 && lastReleased == 0 {
            on = false
            x = 0; xd = 0; xprev = 0
            y = 0; yd = 0; yprev = 0
            s = 1
            pull = 0
            d = 0; a = 0
            lastReleased = 0
            startPull = 0
        }
    }
    func reset() { on = false; x = 0; y = 0; xd = 0; yd = 0; xprev = 0; yprev = 0; s = 1; pull = 0; d = 0; a = 0; lastReleased = 0; startPull = 0 }
}

extension Game {
    var particlesN: Int { 50 }

    func particlesReset() {
        pendingParticles = []
        particles = (0..<particlesN).map { _ in Particle() }
    }
    func particlesClear() { for p in particles { p.t = -1 } }
    func particleAt(_ o: Particle) {
        if !hasFocus { return }
        if getSet("particles") == 0 { return }
        if pendingParticles.count < 50 { pendingParticles.append(o) }
    }
    /// G._particleAt: shows a pending particle in the next free slot
    func _particleAt(_ o: Particle) {
        if particles.isEmpty { particlesReset() }
        let me = o
        switch me.pic {
        case .none: break
        default:
            if me.r == nil { me.r = JSMath.random() * 360 }
            switch me.pic {
            case .cookie:
                me.imageName = "img/smallCookies.png"; me.frameX = (JSMath.random() * 8).rounded(.down) * 64
            case .cookieIcon:
                var cookies: [Upgrade] = []
                if let u = upgradesBID[590] { cookies.append(u) }
                for c in upgradePools["cookie"] ?? [] where c.owned != 0 { cookies.append(c) }
                me.iconPos = cookies.isEmpty ? [0, 0] : choose(cookies).icon
            case .icon(let icon): me.iconPos = icon
            case .image(let url): me.imageName = url; me.frameX = (JSMath.random() * 8).rounded(.down) * 64
            case .flare: me.imageName = "img/flare.png"
            case .wrinklerBits(let shiny, let frame): me.imageName = shiny ? "img/shinyWrinklerBits.png" : "img/wrinklerBits.png"; me.frameX = Double(frame) * 100
            case .none: break
            }
        }
        me.t = 0
        particles[particleI] = me
        particleI += 1
        if particleI >= particlesN { particleI = 0 }
    }
    func particlesLogic(_ delta: Double) {
        for me in particles where me.t > -1 {
            me.x += me.xd
            me.y += me.yd
            me.xd *= 1 - 0.05 * me.grav
            me.yd += 0.5 * me.grav
            me.s *= me.sd
            if me.r != nil { me.r! += me.rd } else { me.r = me.rd }
            me.t += 1
            if me.t >= fps * me.life { me.t = -2 }
        }
    }
    /// G.particlesDraw (the bookkeeping part): returns the particles to show this frame
    func particlesDraw() {
        for p in pendingParticles { _particleAt(p) }
        pendingParticles = []
        for me in particles where me.t == -2 { me.t = -1 }
    }
    func particleOpacity(_ me: Particle) -> Double {
        var o = 1.0
        let life = fps * me.life
        if me.t >= life / 2 { o = 1 - (me.t - life / 2) / (life / 2) }
        return o * me.a
    }
    func cookiePop(_ x: Double, _ y: Double, _ s: Double = 1) {
        particleAt(Particle(x: x, y: y, xd: JSMath.random() * 4 - 2, yd: -JSMath.random() * 3 - 2,
                            s: s * (JSMath.random() * 0.2 + 0.9), rd: JSMath.random() * 10 - 5,
                            pic: season == "fools" ? .image("img/smallDollars.png") : .cookieIcon))
    }
    func sparkleAt(_ x: Double, _ y: Double) {
        sparklesT = sparklesFrames + 1
        sparkleX = (x - 64).rounded(.down)
        sparkleY = (y - 64).rounded(.down)
    }

    // MARK: - ticker
    /// G.getTicker, wrapped by the app's extra headlines (mods/more-content.js)
    func getTicker() -> TickerLine {
        let base = getTickerOriginal()
        if base.onClick != nil { return base }
        let pick = base.text
        if !pick.hasPrefix("News :") || JSMath.random() >= 0.35 { return base }
        var extra: [String] = []
        for (name, lines) in ExtraNews.building where buildingsBN[name] != nil && buildingN(name) > 0 { extra += lines }
        if cookiesEarned >= 100000 { extra += ExtraNews.general }
        return extra.isEmpty ? base : TickerLine(text: choose(extra))
    }
    private func getTickerOriginal() -> TickerLine {
        var list = generatedNews().map { TickerLine(text: $0) }
        if Double(T) > fps * 10 && Has("Fortune cookies") && JSMath.random() < (HasAchiev("O Fortuna") ? 0.04 : 0.02) {
            enum F { case gc, cps, up(Upgrade) }
            var fortunes: [F] = []
            for it in upgradeTiers["fortune"] ?? [] where !HasUnlocked(it.name) { fortunes.append(.up(it)) }
            if fortuneGC == 0 { fortunes.append(.gc) }
            if fortuneCPS == 0 { fortunes.append(.cps) }
            if !fortunes.isEmpty {
                let effect = choose(fortunes)
                var me: String
                switch effect {
                case .gc: me = "Today is your lucky day!"
                case .cps:
                    JSMath.seedrandom(seed + "-fortune")
                    let a = (JSMath.random() * 100).rounded(.down), b = (JSMath.random() * 100).rounded(.down)
                    let c = (JSMath.random() * 100).rounded(.down), d = (JSMath.random() * 100).rounded(.down)
                    me = "Your lucky numbers are: \(jsString(a)) \(jsString(b)) \(jsString(c)) \(jsString(d))"
                    JSMath.seedrandom()
                case .up(let u):
                    let idx = u.name.firstIndex(of: "#") ?? u.name.startIndex
                    me = String(u.name[idx...]) + " : " + u.q
                }
                me = "<span style=\"color:#ade000;pointer-events:auto;\"><div class=\"icon\" style=\"vertical-align:middle;display:inline-block;background-position:\(-29 * 48)px \(-8 * 48)px;transform:scale(0.5);margin:-16px;position:relative;left:-4px;top:0px;\"></div>" + me + "</span>"
                list = [TickerLine(text: me, onClick: {
                    PlaySound("snd/fortune.mp3", 1)
                    switch effect {
                    case .gc:
                        G.toast("Fortune!", "A golden cookie has appeared.", [10, 32], true)
                        G.fortuneGC = 1
                        var o = ShimmerOptions(); o.noWrath = true
                        G.newShimmer("golden", o)
                    case .cps:
                        G.toast("Fortune!", "You gain <b>one hour</b> of your CpS (capped at double your bank).", [10, 32], true)
                        G.fortuneCPS = 1
                        G.earn(min(G.cookiesPs * 60 * 60, G.cookies))
                    case .up(let u):
                        if u.unlocked == 0 {
                            G.toast(u.name, "You've unlocked a new upgrade.", u.icon, true)
                            u.unlock()
                        }
                    }
                })]
            }
        }
        return choose(list)
    }
    func tickerLogic(_ delta: Double) {
        let left = 0.0
        let right = w - left
        let speed = 2 * delta
        let gap = 48.0
        var ticker: String? = nil
        if ticker1.w == 0 {
            let t = getTicker()
            ticker1.onClick = t.onClick
            ticker1.text = t.text
            ticker1.w = TextMeasure.tickerWidth(t.text)
            ticker1.x = max(right, left + ticker2.x + ticker2.w) + gap
            ticker = t.text
        } else if ticker2.w == 0 {
            let t = getTicker()
            ticker2.onClick = t.onClick
            ticker2.text = t.text
            ticker2.w = TextMeasure.tickerWidth(t.text)
            ticker2.x = max(right, left + ticker1.x + ticker1.w) + gap
            ticker = t.text
        }
        if let t = ticker, !t.isEmpty {
            if let ind = savedNews.firstIndex(where: { $0.0 == t }) { savedNews.remove(at: ind) }
            savedNews.insert((t, nowMs()), at: 0)
            if savedNews.count > 50 { savedNews.removeLast() }
            tickerN += 1
        }
        ticker1.x -= speed
        ticker2.x -= speed
        if ticker1.x < -ticker1.w + left { ticker1.w = 0 }
        if ticker2.x < -ticker2.w + left { ticker2.w = 0 }
    }
    func tapTicker(_ which: Int) {
        if which == 1, let f = ticker1.onClick { f(); ticker1.onClick = nil; ticker1.text = "" }
        if which == 2, let f = ticker2.onClick { f(); ticker2.onClick = nil; ticker2.text = "" }
    }

    // MARK: - hidden slots (G.getHiddenUpgradeForSlot)
    static let hiddenSlots = ["pinSpecial", "pinStats", "pinMisc", "orteilTip"]
    func getHiddenUpgradeForSlot(_ slot: String) -> Upgrade? {
        JSMath.seedrandom(seed + "-hiddenSlot-" + slot)
        var names: [String] = []
        if Has("Fortune cookies") { names += (1...20).map { String(format: "Fortune #%03d", $0) } }
        if season == "easter" { names += Game.easterEggs }
        if season == "christmas" { names += Game.reindeerDrops }
        if season == "halloween" { names += Game.halloweenDrops }
        var ups = names.compactMap { upgradesBN[$0] }.filter { $0.unlocked == 0 }
        shuffle(&ups)
        var ups2: [Upgrade] = []
        for u in ups {
            JSMath.seedrandom(seed + "-hiddenSlotUpgrade-\(u.id)")
            if JSMath.random() < 0.15 && slot == choose(Game.hiddenSlots) { ups2.append(u) }
        }
        JSMath.seedrandom()
        return ups2.first
    }

    // MARK: - screens
    func pingScreen(_ s: String) {
        if onScreen == s { return }
        screenPing[s] = true
    }
    func unpingScreen(_ s: String) { screenPing[s] = false }
    func setScreen(_ nameIn: String, force: Bool = false) {
        let name = screenNames.contains(nameIn) ? nameIn : "cookie"
        let old = onScreen
        onScreen = name
        if old != name || force {
            particlesClear()
            if old != name {
                let oi = screenNames.firstIndex(of: old) ?? 0, ni = screenNames.firstIndex(of: name) ?? 0
                if oi < ni { PlaySound("snd/clickb4.mp3", 0.75) } else if oi > ni { PlaySound("snd/clickb3.mp3", 0.75) }
                if old == "cookie" { freeCookie.reset(); undrawWrinklers() }
            }
            unpingScreen(name)
            if name == "cookie" && getSet("fancy") != 0 && getSet("cookiewobble") != 0 { bigCookieSize = 0.95 }
            if name == "store" && onStoreSection == "upgrades" { doUnlocks() }
            UIEvents.shared.screenChanged(from: old, to: name)
            shimmersOnResize()
        }
    }
    func screenLogic(_ delta: Double) {
        if panning {
            let idx = max(0, min(screenNames.count - 1, Int(jsRound(panTo / 90))))
            if screenNames[idx] != onScreen { setScreen(screenNames[idx]) }
        }
    }

    // MARK: - toasts (G.toast)
    /// title is the main text; top is the smaller text above it (below it if reverse)
    func toast(_ title: String, _ top: String, _ icon: [Int]? = nil, _ reverse: Bool = false) {
        UIEvents.shared.toast(title: title, top: top, icon: icon, reverse: reverse)
    }

    // MARK: - research (special screen)
    var researchTime: Double { Has("Persistent memory") ? (1000.0 * 60 * 30 / 10).rounded(.up) : 1000.0 * 60 * 30 }
    func startResearch(_ me: Upgrade) -> Bool {
        if researchUpgrade == nil && me.unlocked != 0 && me.owned == 0 {
            let cost = me.getCost()
            if cost > cookies { return false }
            spend(cost)
            researchT = nowMs()
            researchTM = researchTime
            researchUpgrade = me
            toast(me.name, "Research started.", me.icon)
            refreshCps = true
            PlaySound("snd/thud.mp3", 0.5)
            return true
        }
        return false
    }
    func finishResearch(_ me: Upgrade) -> Bool {
        if researchUpgrade === me && researchT - nowMs() + researchTM <= 0 {
            researchT = 0
            researchTM = 0
            researchUpgrade = nil
            researchUpgradeLast = me
            toast(me.name, "Research complete!", me.icon)
            PlaySound("snd/smallCymbalCrash.mp3", 0.5)
            me.owned = 1
            upgradesN += 1
            refreshCps = true
            me.funcB?(me, false)
            doUnlocks()
            return true
        }
        return false
    }

    // MARK: - helpers used by the generated ticker and others
    func getSetB(_ name: String) -> Bool { getSet(name) != 0 }

    // MARK: - G.Init: build everything, then reset and load the save
    func Init() {
        initSettings()
        resetQuickButtons()
        particlesReset()
        initBuffTypes()
        initShimmerTypes()
        loadContent()
        initDragon()
        initSeasons()
        baseSeason = getBaseSeason()
        season = baseSeason
        // G.addPostData, in the order the original registers them
        resetSettings()
        goldenCookieUpgrades = ["Get lucky", "Lucky day", "Serendipity", "Heavenly luck", "Lasting fortune", "Decisive fate", "Lucky digit", "Lucky number", "Lucky payout", "Golden goose egg"].compactMap { upgradesBN[$0] }
        initBuildingBuffTypes()
        seasonsPostData()
        afterData()
        Minigames.setup()
        resetPools()
        for s in screenNames { screenPing[s] = false }
        reloadFromSave()
    }
    /// reset, then load from the save (or the backup)
    func reloadFromSave() {
        Reset(true)
        var toToast: (String, String)? = nil
        switch SaveStore.load(SaveStore.savePath) {
        case .loaded(let o): _ = LoadFromObject(o)
        case .none: Reset(true)
        case .error:
            toToast = ("Failed to load save.", "Restoring backup...")
            Reset(true)
            switch SaveStore.load(SaveStore.savePathPrev) {
            case .loaded(let o): _ = LoadFromObject(o); toToast = ("Failed to load save.", "Restored from backup instead.")
            default: toToast = ("Failed to load save or backup.", "Starting new save."); Reset(true)
            }
        }
        if let t = toToast { toast(t.0, t.1, nil, true) }
    }
}

/// Measures text the way the page lays it out (set up by the screens, which know the fonts).
enum TextMeasure {
    static var tickerWidth: (String) -> Double = { s in Double(s.count) * 7 }
}
