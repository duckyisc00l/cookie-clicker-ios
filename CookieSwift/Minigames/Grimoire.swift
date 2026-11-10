import UIKit

// Port of mods/minigames/minigameGrimoire.js (the desktop game's Grimoire), with the phone layout.

final class Spell {
    let key: String, name: String, desc: String, failDesc: String?
    let icon: [Int]
    let costMin: Double, costPercent: Double
    var id = 0
    var failFunc: ((Double) -> Double)?
    var win: () -> Int = { 0 }
    var fail: (() -> Int)?
    init(_ key: String, _ name: String, desc: String, failDesc: String?, icon: [Int], costMin: Double, costPercent: Double) {
        self.key = key; self.name = name; self.desc = desc; self.failDesc = failDesc; self.icon = icon; self.costMin = costMin; self.costPercent = costPercent
    }
}

final class Grimoire: Minigame {
    let parent: Building
    let name = "Grimoire"
    var spells: [Spell] = []
    var spellsBN: [String: Spell] = [:]
    var magic = 0.0, magicM = 0.0, magicPS = 0.0
    var spellsCast = 0, spellsCastTotal = 0
    private var T = 0

    init(_ b: Building) {
        parent = b
        buildSpells()
        computeMagicM()
        magic = magicM
    }

    private func pop(_ s: String) { Minigames.popup("<div style=\"font-size:80%;\">\(s)</div>") }

    private func buildSpells() {
        func add(_ s: Spell) { s.id = spells.count; spells.append(s); spellsBN[s.key] = s }
        let conjure = Spell("conjure baked goods", "Conjure Baked Goods", desc: "Summon half an hour worth of your CpS, capped at 15% of your cookies owned.", failDesc: "Trigger a 15-minute clot and lose 15 minutes of CpS.", icon: [21, 11], costMin: 2, costPercent: 0.4)
        conjure.win = { [unowned self] in
            let val = max(7, min(G.cookies * 0.15, G.cookiesPs * 60 * 30))
            G.earn(val)
            G.toast("Conjure Baked Goods!", "You magic <b>\(Loc.cookies(val))</b> out of thin air.", [21, 11])
            self.pop("+\(Loc.cookies(val))!")
            return 0
        }
        conjure.fail = { [unowned self] in
            let buff = self.gainBuff("clot", 60 * 15, 0.5)
            var val = min(G.cookies * 0.15, G.cookiesPs * 60 * 15) + 13
            val = min(G.cookies, val)
            G.spend(val)
            if let b = buff { G.toast(b.type.nameD, "", b.type.icon) }
            self.pop("Backfire!<br>Summoning failed! Lost \(Loc.cookies(val))!")
            return 0
        }
        add(conjure)

        let fate = Spell("hand of fate", "Force the Hand of Fate", desc: "Summon a random golden cookie. Each existing golden cookie makes this spell +15% more likely to backfire.", failDesc: "Summon an unlucky wrath cookie.", icon: [22, 11], costMin: 10, costPercent: 0.6)
        fate.failFunc = { $0 + 0.15 * Double(G.shimmerTypesBN["golden"]?.n ?? 0) }
        fate.win = { [unowned self] in
            var o = ShimmerOptions(); o.noWrath = true
            let s = G.newShimmer("golden", o)
            var choices = ["frenzy", "multiply cookies"]
            if G.hasBuff("dragonflight") == nil { choices.append("click frenzy") }
            if JSMath.random() < 0.1 { choices += ["cookie storm", "cookie storm", "blab"] }
            if G.buildingsN >= 10 && JSMath.random() < 0.25 { choices.append("building special") }
            if JSMath.random() < 0.15 { choices = ["cookie storm drop"] }
            if JSMath.random() < 0.0001 { choices.append("free sugar lump") }
            s?.force = choose(choices)
            if s?.force == "cookie storm drop" { _ = JSMath.random() * 0.75 + 0.25 }
            self.pop("Promising fate!")
            return 0
        }
        fate.fail = { [unowned self] in
            var o = ShimmerOptions(); o.forceWrath = true
            let s = G.newShimmer("golden", o)
            var choices = ["clot", "ruin cookies"]
            if JSMath.random() < 0.1 { choices += ["cursed finger", "blood frenzy"] }
            if JSMath.random() < 0.003 { choices.append("free sugar lump") }
            if JSMath.random() < 0.1 { choices = ["blab"] }
            s?.force = choose(choices)
            self.pop("Backfire!<br>Sinister fate!")
            return 0
        }
        add(fate)

        let stretch = Spell("stretch time", "Stretch Time", desc: "All active buffs gain 10% more time (up to 5 more minutes).", failDesc: "All active buffs are shortened by 20% (up to 10 minutes shorter).", icon: [23, 11], costMin: 8, costPercent: 0.2)
        stretch.win = { [unowned self] in
            var changed = 0
            for me in G.buffs {
                // the desktop counts in frames; the phone game's buffs are in seconds
                let gain = min(60 * 5, me.tm * 0.1)
                me.tm += gain
                me.t += gain
                changed += 1
            }
            if changed == 0 { self.pop("No buffs to alter!"); return -1 }
            self.pop("Zap! Buffs lengthened.")
            return 0
        }
        stretch.fail = { [unowned self] in
            var changed = 0
            for me in G.buffs {
                let loss = min(60 * 10, me.t * 0.2)
                me.t -= loss
                me.t = max(me.t, 0)
                changed += 1
            }
            if changed == 0 { self.pop("No buffs to alter!"); return -1 }
            self.pop("Backfire!<br>Fizz! Buffs shortened.")
            return 0
        }
        add(stretch)

        let edifice = Spell("spontaneous edifice", "Spontaneous Edifice", desc: "The spell picks a random building you could afford if you had twice your current cookies, and gives it to you for free. The building selected must be under 400, and cannot be your most-built one (unless it is your only one).", failDesc: "Lose a random building.", icon: [24, 11], costMin: 20, costPercent: 0.75)
        edifice.win = { [unowned self] in
            var max = 0, n = 0
            for b in G.buildings { if b.amount > max { max = b.amount }; if b.amount > 0 { n += 1 } }
            let list = G.buildings.filter { ($0.amount < max || n == 1) && $0.getCost() <= G.cookies * 2 && $0.amount < 400 }
            if list.isEmpty { self.pop("No buildings to improve!"); return -1 }
            let b = choose(list)
            b.forceBuy(1)
            self.pop("A new \(b.single)<br>bursts out of the ground.")
            return 0
        }
        edifice.fail = { [unowned self] in
            if G.buildingsN == 0 { self.pop("Backfired, but no buildings to destroy!"); return -1 }
            let b = choose(G.buildings.filter { $0.amount > 0 })
            b.sacrifice(1)
            self.pop("Backfire!<br>One of your \(b.plural)<br>disappears in a puff of smoke.")
            return 0
        }
        add(edifice)

        let haggler = Spell("haggler's charm", "Haggler's Charm", desc: "Upgrades are 2% cheaper for 1 minute.", failDesc: "Upgrades are 2% more expensive for an hour.<q>What's that spell? Loadsamoney!</q>", icon: [25, 11], costMin: 10, costPercent: 0.1)
        haggler.win = { [unowned self] in
            self.killBuff("Haggler's misery"); _ = self.gainBuff("haggler luck", 60, 2)
            self.pop("Upgrades are cheaper!"); return 0
        }
        haggler.fail = { [unowned self] in
            self.killBuff("Haggler's luck"); _ = self.gainBuff("haggler misery", 60 * 60, 2)
            self.pop("Backfire!<br>Upgrades are pricier!"); return 0
        }
        add(haggler)

        let pixies = Spell("summon crafty pixies", "Summon Crafty Pixies", desc: "Buildings are 2% cheaper for 1 minute.", failDesc: "Buildings are 2% more expensive for an hour.", icon: [26, 11], costMin: 10, costPercent: 0.2)
        pixies.win = { [unowned self] in
            self.killBuff("Nasty goblins"); _ = self.gainBuff("pixie luck", 60, 2)
            self.pop("Crafty pixies<br>Buildings are cheaper!"); return 0
        }
        pixies.fail = { [unowned self] in
            self.killBuff("Crafty pixies"); _ = self.gainBuff("pixie misery", 60 * 60, 2)
            self.pop("Backfire!<br>Nasty goblins<br>Buildings are pricier!"); return 0
        }
        add(pixies)

        let gfd = Spell("gambler's fever dream", "Gambler's Fever Dream", desc: "Cast a random spell at half the magic cost, with twice the chance of backfiring.", failDesc: nil, icon: [27, 11], costMin: 3, costPercent: 0.05)
        gfd.win = { [unowned self] in
            let selfCost = self.getSpellCost(gfd)
            let list = self.spells.filter { $0.key != "gambler's fever dream" && (self.magic - selfCost) >= self.getSpellCost($0) * 0.5 }
            if list.isEmpty { self.pop("No eligible spells!"); return -1 }
            let spell = choose(list)
            let cost = self.getSpellCost(spell) * 0.5
            let seed = G.seed
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self = self, G.seed == seed else { return }
                let out = self.castSpell(spell, cost: cost, failChanceMax: 0.5, passthrough: true)
                if !out {
                    self.magic += selfCost
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.pop("That's too bad!<br>Magic refunded.") }
                }
            }
            self.pop("Casting \(spell.name)<br>for \(B(cost)) magic...")
            return 0
        }
        add(gfd)

        let resurrect = Spell("resurrect abomination", "Resurrect Abomination", desc: "Instantly summon a wrinkler if conditions are fulfilled.", failDesc: "Pop one of your wrinklers.", icon: [28, 11], costMin: 20, costPercent: 0.1)
        resurrect.win = { [unowned self] in
            if G.spawnWrinkler() == nil { self.pop("Unable to spawn a wrinkler!"); return -1 }
            self.pop("Rise, my precious!"); return 0
        }
        resurrect.fail = { [unowned self] in
            if G.PopRandomWrinkler() == nil { self.pop("Backfire!<br>But no wrinkler was harmed."); return -1 }
            self.pop("Backfire!<br>So long, ugly..."); return 0
        }
        add(resurrect)

        let diminish = Spell("diminish ineptitude", "Diminish Ineptitude", desc: "Spells backfire 10 times less for the next 5 minutes.", failDesc: "Spells backfire 5 times more for the next 10 minutes.", icon: [29, 11], costMin: 5, costPercent: 0.2)
        diminish.win = { [unowned self] in
            self.killBuff("Magic inept"); _ = self.gainBuff("magic adept", 5 * 60, 10)
            self.pop("Ineptitude diminished!"); return 0
        }
        diminish.fail = { [unowned self] in
            self.killBuff("Magic adept"); _ = self.gainBuff("magic inept", 10 * 60, 5)
            self.pop("Backfire!<br>Ineptitude magnified!"); return 0
        }
        add(diminish)
    }

    /// Game.gainBuff through the shim (toasts the buff like the phone game does)
    @discardableResult
    func gainBuff(_ type: String, _ t: Double, _ pow: Double) -> Buff? {
        guard G.buffTypesBN[type] != nil else { return nil }
        let b = G.addBuff(type, t: t, pow: pow)
        Minigames.toastBuff(b)
        return b
    }
    /// Game.killBuff by shown name
    func killBuff(_ name: String) {
        let low = name.lowercased()
        if let b = G.buffs.first(where: { $0.type.name == name || $0.type.nameD.lowercased() == low }) { G.killBuff(b.type.name) }
    }
    func hasBuffNamed(_ name: String) -> Bool {
        let low = name.lowercased()
        return G.buffs.contains { $0.type.name == name || $0.type.nameD.lowercased() == low }
    }

    func computeMagicM() {
        let towers = Double(max(parent.amount, 1))
        let lvl = Double(max(parent.level, 1))
        magicM = (4 + pow(towers, 0.6) + log((towers + (lvl - 1) * 10) / 15 + 1) * 15).rounded(.down)
        magic = min(magicM, magic)
    }
    func getFailChance(_ spell: Spell) -> Double {
        var f = 0.15
        if hasBuffNamed("Magic adept") { f *= 0.1 }
        if hasBuffNamed("Magic inept") { f *= 5 }
        f *= 1 + 0.1 * G.auraMult("Supreme Intellect")
        if let ff = spell.failFunc { f = ff(f) }
        return f
    }
    @discardableResult
    func castSpell(_ spell: Spell, cost costIn: Double? = nil, failChanceMax: Double? = nil, passthrough: Bool = false) -> Bool {
        let cost = costIn ?? getSpellCost(spell)
        if magic < cost { return false }
        var failChance = getFailChance(spell)
        if let m = failChanceMax { failChance = max(failChance, m) }
        var out = 0
        var fail = false
        JSMath.seedrandom(G.seed + "/" + String(spellsCastTotal))
        if spell.fail == nil || JSMath.random() < (1 - failChance) { out = spell.win() } else { fail = true; out = spell.fail!() }
        JSMath.seedrandom()
        if out != -1 {
            if !passthrough {
                spellsCast += 1
                spellsCastTotal += 1
                if spellsCastTotal >= 9 { G.win("Bibbidi-bobbidi-boo") }
                if spellsCastTotal >= 99 { G.win("I'm the wiz") }
                if spellsCastTotal >= 999 { G.win("A wizard is you") }
            }
            magic -= cost
            magic = max(0, magic)
            PlaySound(fail ? "snd/spellFail.mp3" : "snd/spell.mp3", 0.75)
            return true
        }
        PlaySound("snd/spellFail.mp3", 0.75)
        return false
    }
    func getSpellCost(_ spell: Spell) -> Double {
        var out = spell.costMin
        if spell.costPercent != 0 { out += magicM * spell.costPercent }
        out *= 1 - 0.1 * G.auraMult("Supreme Intellect")
        return out.rounded(.down)
    }
    func getSpellCostBreakdown(_ spell: Spell) -> String {
        if spell.costPercent != 0 { return "\(B(spell.costMin)) magic +\(B((spell.costPercent * 100).rounded(.up)))% of max magic" }
        return "\(B(spell.costMin)) magic"
    }
    func spellTooltip(_ me: Spell) -> String {
        let cost = B(getSpellCost(me))
        var breakdown = getSpellCostBreakdown(me)
        breakdown = cost != breakdown ? " <small>(\(breakdown))</small>" : ""
        let backfire = getFailChance(me)
        var s = "<div style=\"padding:0px 4px 0px 44px;font-size:15px;font-weight:bold;color:#fff;\">\(me.name)</div>"
        s += "<div style=\"padding-left:44px;\">Magic cost: <b style=\"color:#\(getSpellCost(me) <= magic ? "6f6" : "f66");\">\(cost)</b>\(breakdown)</div>"
        if me.fail != nil { s += "<div style=\"padding-left:44px;\"><small>Chance to backfire: <b style=\"color:#f66;\">\(jsString((100 * backfire).rounded(.up)))%</b></small></div>" }
        s += "<line></line><div style=\"margin:4px 0px;\"><b>Effect:</b> <span style=\"color:#3f0;\">\(me.desc)</span>"
        if let fd = me.failDesc { s += "<div style=\"height:8px;\"></div><b>Backfire:</b> <span style=\"color:#f30;\">\(fd)</span>" }
        s += "</div>"
        return s
    }
    func refillTooltip() -> String {
        "<div style=\"text-align:center;font-size:11px;\">Click to refill <b>100 units</b> of your magic meter for <span style=\"color:#6f6;font-weight:bold;\"><span class=\"tinyIcon\" style=\"background-position:\(-29 * 48)px \(-14 * 48)px;\"></span>\(Loc.lumps(1))</span>." +
            (G.lumpRefill <= 0 ? "<br><small>(can be done once every \(Loc.sayTime(G.fps * 60 * 15, -1)))</small>" : "<br><small style=\"color:#f30;\">(usable again in \(Loc.sayTime(G.lumpRefill + G.fps, -1)))</small>") + "</div>"
    }
    func refill() {
        guard magic < magicM, G.lumps >= 1, G.lumpRefill <= 0 else { return }
        Minigames.spendLump(1, "refill") { [weak self] in
            guard let self = self else { return }
            G.lumpRefill = G.fps * 60 * 15
            self.magic = min(self.magic + 100, self.magicM)
            PlaySound("snd/pop\(Int(JSMath.random() * 3 + 1)).mp3", 0.75)
        }
    }

    // MARK: Minigame
    func save() -> String {
        "\(jsString(magic)) \(spellsCast) \(spellsCastTotal) 0"
    }
    func load(_ str: String) {
        if str.isEmpty { return }
        let spl = str.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        computeMagicM()
        magic = jsParseFloat(spl.count > 0 ? spl[0] : "") ?? magicM
        spellsCast = Int(jsParseFloat(spl.count > 1 ? spl[1] : "") ?? 0)
        spellsCastTotal = Int(jsParseFloat(spl.count > 2 ? spl[2] : "") ?? 0)
    }
    func reset(_ hard: Bool) {
        computeMagicM()
        magic = magicM
        spellsCast = 0
        if hard { spellsCastTotal = 0 }
    }
    func logic() {
        if T % 5 == 0 { computeMagicM() }
        magicPS = max(0.002, pow(magic / max(magicM, 100), 0.5)) * 0.002
        magic += magicPS
        magic = min(magic, magicM)
        T += 1
    }
}

/// the Grimoire's screen
final class GrimoireScreen: UIView, MinigameScreen {
    let M: Grimoire
    private let bg = PatternView("mgimg/BGgrimoire.jpg")
    private let borders = PicView("mgimg/shadedBorders.png")
    private var spellViews: [(TapView, UIImageView, IconView, RichLabel)] = []
    private let bar = UIView()
    private let barFrame = DesktopFrame()
    private let barFull = UIView()
    private let barFill = PatternView("mgimg/prestigeBar.jpg", tileSize: CGSize(width: 128, height: 8))
    private let barText = RichLabel()
    private let refillB = TapView()
    private let info = RichLabel()
    private var drawT = 0

    init(_ m: Grimoire) {
        M = m
        super.init(frame: .zero)
        addSubview(bg); addSubview(borders)
        for (i, s) in m.spells.enumerated() {
            let v = TapView()
            v.layer.shadowColor = UIColor.black.cgColor; v.layer.shadowOpacity = 1; v.layer.shadowRadius = px(2); v.layer.shadowOffset = CGSize(width: px(4), height: px(4))
            let frame = UIImageView()
            v.addSubview(frame)
            let icon = IconView(s.icon)
            icon.layer.shadowColor = UIColor.black.cgColor; icon.layer.shadowOpacity = 0.6; icon.layer.shadowRadius = px(2); icon.layer.shadowOffset = .zero
            v.addSubview(icon)
            var st = TextStyle(); st.family = .georgia; st.bold = true; st.size = 12; st.align = .center
            st.shadow = Shadows.make(0, 0, 4)
            let price = RichLabel(st)
            v.addSubview(price)
            v.onDown = { [weak self] v, _ in self?.press(v, i, down: true) }
            v.onUp = { [weak self] v in self?.press(v, i, down: false) }
            v.onTap = { [weak self] _ in
                guard let self = self else { return }
                PlaySound("snd/tick.mp3", 1)
                MinigameWindow.current?.showTooltip { [weak self] in (self?.M.spellTooltip(s) ?? "", s.icon) }
                self.M.castSpell(s)
                self.update()
            }
            addSubview(v)
            spellViews.append((v, frame, icon, price))
        }
        // the magic bar
        bar.addSubview(barFrame)
        barFull.clipsToBounds = true
        barFull.addSubview(barFill)
        bar.addSubview(barFull)
        var bt = TextStyle(); bt.family = .georgia; bt.bold = true; bt.size = 12; bt.color = .white; bt.align = .center
        bt.shadow = Shadows.make(-1, 1, 3)
        barText.style = bt
        bar.addSubview(barText)
        let lump = IconView([29, 14])
        lump.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        refillB.addSubview(lump)
        refillB.onTap = { [weak self] _ in
            MinigameWindow.current?.showTooltip { [weak self] in (self?.M.refillTooltip() ?? "", nil) }
            self?.M.refill()
        }
        refillB.onDown = { [weak lump] _, _ in lump?.transform = CGAffineTransform(scaleX: 1, y: 1) }
        refillB.onUp = { [weak lump] _ in lump?.transform = CGAffineTransform(scaleX: 0.5, y: 0.5) }
        addSubview(bar)
        addSubview(refillB)
        var it = TextStyle.base(12, color: UIColor(white: 1, alpha: 0.75)); it.align = .center; it.shadow = Shadows.make(-1, 1, 0)
        info.style = it
        addSubview(info)
        update()
    }
    required init?(coder: NSCoder) { fatalError() }

    private var pressed = -1
    private func press(_ v: TapView, _ i: Int, down: Bool) {
        pressed = down ? i : -1
        setFrame(i)
    }
    /// .grimoireSpell frames from spellBG.png: nth-child picks the column, hover/active pick the row
    private func setFrame(_ i: Int) {
        let col = [60.0, 120, 180, 0][i % 4]
        let row = pressed == i ? 74.0 * 2 : 0  // :active uses background-position 74px → the third row
        spellViews[i].1.image = Res.sprite("mgimg/spellBG.png", x: col, y: row, w: 60, h: 74)
    }
    private func update() {
        for (i, s) in M.spells.enumerated() {
            let cost = M.getSpellCost(s)
            let ready = M.magic >= cost
            let (v, _, icon, price) = spellViews[i]
            price.html = B(cost)
            var st = price.style
            st.color = ready ? UIColor(white: 1, alpha: 0.8) : UIColor(css: "#f33")
            price.style = st
            v.alpha = ready ? 1 : 0.8
            icon.alpha = ready ? 1 : 0.8
            setFrame(i)
        }
    }

    func layoutContent(width w: Double, minHeight: Double) -> Double {
        // #grimoireContent padding 8px 4px 16px; #grimoireSpells padding 8px 0, spells 60x74 with margins 4px 3px, centred
        var y = 8.0 + 8
        let perRow = max(1, Int((w - 8) / 66))
        let n = spellViews.count
        for (i, sv) in spellViews.enumerated() {
            let row = i / perRow
            let inRow = min(perRow, n - row * perRow)
            let x0 = (w - Double(inRow) * 66) / 2
            let x = x0 + Double(i % perRow) * 66 + 3
            let yy = y + Double(row) * 82 + 4
            sv.0.frame = CGRect(x: px(x), y: px(yy), width: px(60), height: px(74))
            sv.1.frame = sv.0.bounds
            sv.2.frame = CGRect(x: px(6), y: px(2), width: px(48), height: px(48))
            sv.3.frame = CGRect(x: 0, y: px(50 + 2), width: px(60), height: px(16))
        }
        y += Double((n + perRow - 1) / perRow) * 82 + 8
        // the bar: 4px margins, 22px high, magicM*3 wide (at most 95%)
        let bw = min(M.magicM * 3, (w - 8) * 0.95)
        bar.frame = CGRect(x: px((w - bw) / 2), y: px(y + 4), width: px(bw), height: px(22))
        barFrame.radius = 8
        barFrame.frame = bar.bounds
        barText.frame = CGRect(x: 0, y: px(2 + 2), width: bar.bounds.width, height: px(16))
        refillB.frame = CGRect(x: bar.frame.minX - px(40), y: bar.frame.minY - px(17) + px(11 - 13), width: px(48), height: px(48))
        refillB.subviews.first?.center = CGPoint(x: px(24), y: px(24))
        y += 4 + 22 + 4
        info.frame = CGRect(x: 0, y: px(y + 12), width: px(w), height: px(14))
        y += 12 + 14 + 16
        let h = max(y, minHeight)
        bg.frame = CGRect(x: 0, y: 0, width: px(w), height: px(h))
        borders.frame = bg.frame
        return h
    }

    func drawFrame() {
        drawT += 1
        if drawT % 5 == 0 {
            update()
            let m = M.magic, mm = M.magicM
            barText.html = "\(B(min(mm.rounded(.down), m)))/\(B(mm.rounded(.down)))" + (m < mm ? " (+\(B(M.magicPS * G.fps, 2))/s)" : "")
            let bw = bar.bounds.width
            barFull.frame = CGRect(x: px(1), y: px(1), width: max(0, (bw - px(2)) * CGFloat(m / mm)), height: bar.bounds.height - px(2))
            barFill.frame = CGRect(x: 0, y: 0, width: bw, height: barFull.bounds.height)
            barFill.tileSize = CGSize(width: 128, height: Double(barFull.bounds.height / K))
            info.html = "Spells cast: \(B(Double(M.spellsCast))) (total: \(B(Double(M.spellsCastTotal))))"
        }
        barFill.offset = CGPoint(x: -Double(G.T) * 0.5, y: 0)
    }
}

extension Minigames {
    /// Game.spendLump with the "Do you want to spend..." question
    static func spendLump(_ n: Double, _ what: String, _ f: @escaping () -> Void) {
        guard G.lumps >= n else { return }
        guard let w = MinigameWindow.current else { G.lumps -= n; f(); G.refreshCps = true; return }
        w.prompt("Do you want to spend <b>\(Loc.lumps(n))</b> to \(what)?", icon: [29, 14], options: [("Yes", {
            G.lumps -= n
            f()
            G.refreshCps = true
        }), ("No", nil)])
    }
}
