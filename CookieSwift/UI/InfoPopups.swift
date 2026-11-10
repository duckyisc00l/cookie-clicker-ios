import UIKit

// The info popups: buildings (store screen showInfo), upgrades (G.Upgrade.prototype.showInfo),
// achievements (G.Achiev.prototype.showInfo) and sugar lumps (mods/sugar-lumps.js).

/// the marble name box at the top of an info popup, with an icon on the left
final class IconNameBox: UIView {
    let box = NameBox()
    let icon: UIView
    let name = RichLabel()
    let sub = RichLabel()
    let isBuilding: Bool
    private var animated = false
    /// upgrade/achievement: icon + name; building: 64px picture + name + "Owned" line
    init(icon: UIView, name html: String, nameStyle: String? = nil, building: Bool = false) {
        self.icon = icon
        isBuilding = building
        super.init(frame: .zero)
        addSubview(box)
        box.addSubview(icon)
        var s = TextStyle.fancy(16, color: .ccText)
        s.align = .center
        s.shadow = Shadows.make(1, 1, 2)
        name.style = s
        name.html = nameStyle.map { "<span style=\"\($0)\">\(html)</span>" } ?? html
        box.addSubview(name)
        if building {
            var ss = TextStyle.base(10, color: .ccText)
            ss.bold = true; ss.align = .center; ss.shadow = Shadows.make(1, 1, 2)
            sub.style = ss
            box.addSubview(sub)
        } else {
            icon.layer.shadowColor = UIColor.black.cgColor; icon.layer.shadowOpacity = 0.5
            icon.layer.shadowOffset = CGSize(width: px(3), height: px(3)); icon.layer.shadowRadius = px(1)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    func height(_ w: Double) -> Double {
        if isBuilding { return 64 }
        let nw = w - 64 - 16
        return max(64, name.fittingHeight(nw) + 16)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        box.frame = bounds
        let w = Double(bounds.width / K), h = Double(bounds.height / K)
        if isBuilding {
            icon.frame = CGRect(x: 0, y: 0, width: px(64), height: px(64))
            name.frame = CGRect(x: px(64 + 8), y: px(16 + 8), width: px(w - 64 - 16), height: px(name.fittingHeight(w - 64 - 16)))
            sub.frame = CGRect(x: px(64), y: px(h - 16 - 10), width: px(w - 64), height: px(12))
        } else {
            icon.frame = CGRect(x: px(8), y: px((h - 48) / 2), width: px(48), height: px(48))
            let nw = w - 64 - 16
            let nh = name.fittingHeight(nw)
            name.frame = CGRect(x: px(64 + 8), y: px((h - nh) / 2), width: px(nw), height: px(nh))
        }
        if !animated {
            animated = true
            Anim.switchAnim(icon, "switchLeftIn")
            Anim.switchAnim(name, "switchRightIn")
        }
    }
}

extension PopupContent {
    /// .framed.nameBox (margin 8px -3px, 3px frame)
    func nameBox(_ v: IconNameBox) {
        add(v, marginTop: 11, marginBottom: 11) { w in v.height(w) }
    }
    /// <p class="switchTopIn" style="text-align:right;color:rgba(255,255,255,0.65);"><q>…</q></p>
    func quote(_ q: String) {
        let l = html("<p style=\"text-align:right;color:rgba(255,255,255,0.65);\"><q>\(q)</q></p>")
        DispatchQueue.main.async { Anim.switchAnim(l, "switchTopIn") }
    }
}

enum BuildingUI {
    static func showInfo(_ me: Building) {
        Popup.open(PopupOptions(build: { c in
            c.h3("Building info")
            let pic = UIImageView()
            let p = me.getPic()
            pic.image = Res.sprite("img/buildings.png", x: -p.0, y: -p.1, w: 64, h: 64)
            let nb = IconNameBox(icon: pic, name: me.getName(), nameStyle: me.style, building: true)
            nb.sub.html = "Owned: \(B(Double(me.amount)))" + (me.free > 0 ? " (Free: \(B(Double(me.free))))" : "")
            c.nameBox(nb)
            c.line()
            c.liveHTML {
                """
                <div>
                <p>&bull; each \(me.single) produces <b>\(B(me.storedCps, 1))</b> cookie\(B(me.storedCps, 1) == "1" ? "" : "s") per second</p>
                <p>&bull; <b>\(B(Double(me.amount))) \(me.amount == 1 ? me.single : me.plural)</b> producing <b>\(B(me.storedCps * Double(me.amount)))</b> cookie\(B(me.storedCps * Double(me.amount)) == "1" ? "" : "s") per second</p>
                <p>&bull; <b>\(B(me.cookiesMade))</b> cookie\(B(me.cookiesMade) == "1" ? "" : "s") \(me.actionName) so far</p>
                </div>
                """
            }
            c.line()
            LumpUI.levelBox(c, me)
            c.quote(me.getDesc())
        }, close: "Close"))
    }
}

enum UpgradeUI {
    static func tagsHTML(_ me: Upgrade) -> [(String, UIColor)] {
        var tags: [(String, UIColor)] = []
        let white = UIColor.white
        if me.pool == "prestige" { tags.append(("Heavenly", UIColor(css: "#efa438"))) }
        else if me.pool == "science" { tags.append(("Tech", UIColor(css: "#36a4ff"))) }
        else if me.pool == "cookie" { tags.append(("Cookie", white)) }
        else if me.pool == "debug" { tags.append(("Debug", UIColor(css: "#00c462"))) }
        else if me.pool == "toggle" {}
        else { tags.append(("Upgrade", white)) }
        if G.Has("Label printer") {
            if let t = me.tier { tags.append(("Tier: " + t.name, UIColor(css: t.color))) }
            if me.name == "Label printer" || me.name == "This upgrade" { tags.append(("Tier: Self-referential", UIColor(css: "#ff00ea"))) }
        }
        let pseudoKitten = (G.upgradePools["pseudoKitten"] ?? []).contains { $0 === me }
        if me.owned == 0 {
            if me.pool == "tech" { tags.append(("Not yet researched", white)) }
            else if me.pool == "kitten" || pseudoKitten { tags.append(("Not yet purrchased", white)) }
            else if me.pool != "toggle" { tags.append(("Not yet purchased", white)) }
        } else {
            if me.pool == "tech" { tags.append(("Researched", white)) }
            else if me.pool == "kitten" || pseudoKitten { tags.append(("Purrchased", white)) }
            else { tags.append(("Purchased", white)) }
        }
        if G.lastingUpgrades.contains(me.name) && me.unlocked != 0 { tags.append(("Unlocked forever", UIColor(css: "#f2ff87"))) }
        return tags
    }

    static func showInfo(_ me: Upgrade, onBuy: (() -> Void)? = nil) {
        let icon = me.iconFunc?() ?? me.icon
        Popup.open(PopupOptions(build: { c in
            c.h3(me.pool == "toggle" ? "Switch info" : me.pool == "science" ? "Tech info" : me.pool == "prestige" ? "Heavenly upgrade info" : "Upgrade info")
            c.nameBox(IconNameBox(icon: IconView(icon), name: me.name, nameStyle: me.style))
            c.line()
            if let pd = me.preDescFunc?(me), !pd.isEmpty {
                c.html("<div style=\"text-align:center;\">\(pd)</div>")
                c.line()
            }
            if me.pool == "prestige" && me.owned == 0 && G.onAscend == 1 {
                var f = TextStyle.fancy(14, color: UIColor(css: "#cff")); f.bold = true; f.shadow = Shadows.body
                let b = CCButton("Buy", look: me.getCost() > G.heavenlyChips ? .magicOff : .magic, font: f, padding: UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
                b.onTap = { _ in onBuy?(); Popup.close() }
                c.add(b, marginTop: 2, marginBottom: 6, marginLeft: 16, marginRight: 16) { w in b.fittingHeight(width: w) }
            }
            let tags = TagsView(tagsHTML(me))
            c.add(tags, marginTop: 0, marginBottom: 0) { w in tags.height(w) }
            if me.pool == "toggle" {
                var f = TextStyle.base(10, color: .ccText); f.shadow = Shadows.body; f.align = .center
                let sw = CCButton("", look: .bump, font: f, padding: UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8))
                let shade = GradientView([UIColor(white: 1, alpha: 0.1), .clear])
                sw.insertSubview(shade, at: 0)
                func text() -> String {
                    "<div class=\"printText\" style=\"font-size:14px;font-variant:small-caps;\">Switch</div><div>Will cost <b><span class=\"cost\(me.getCost() > G.cookies ? " cantAfford" : "")\">\(B(me.getCost()))</span></b></div>"
                }
                sw.text = text()
                sw.onTap = { _ in
                    if me.buy() { Popup.close(); PlaySound("snd/buy1.mp3", 0.65) }
                }
                c.add(sw) { w in shade.frame = CGRect(x: 0, y: 0, width: px(w), height: px(sw.fittingHeight(width: w))); return sw.fittingHeight(width: w) }
                c.every(0.15) { let t = text(); if t != sw.text { sw.text = t }; return false }
                c.line()
                c.html("<p>\(me.descFunc?(me) ?? me.desc)</p>")
            } else {
                c.liveHTML {
                    let costCls = (me.pool == "prestige" ? "heavenlyCost " : "") + "cost" + (me.owned != 0 ? " neutralCost" : me.getCost() > (me.pool == "prestige" ? G.heavenlyChips : G.cookies) ? " cantAfford" : "")
                    return "<div><div style=\"font-size:10px;font-weight:bold;text-align:center;\">Cost: <span class=\"\(costCls)\">\(B(me.getCost()))</span></div></div>"
                }
                c.line()
                c.liveHTML { "<p>\(me.descFunc?(me) ?? me.desc)</p>" }
            }
            c.line()
            let q = me.qFunc?(me) ?? me.q
            if !q.isEmpty { c.quote(q) }
        }, close: "Close"))
    }
}

enum AchievUI {
    static func showInfo(_ me: Achiev) {
        let icon = me.icon
        Popup.open(PopupOptions(build: { c in
            c.h3("Achievement info")
            c.nameBox(IconNameBox(icon: IconView(icon), name: me.name, nameStyle: me.style))
            c.line()
            c.liveHTML {
                "<div style=\"\(me.owned != 0 ? "color:#fff;" : "color:#999;")font-size:10px;font-weight:bold;text-align:center;\">\(me.owned != 0 ? "Unlocked" : "Not yet unlocked")</div>"
            }
            c.line()
            c.liveHTML { "<p>\(me.descFunc?(me) ?? me.desc)</p>" }
            c.line()
            let q = me.qFunc?(me) ?? me.q
            if !q.isEmpty { c.quote(q) }
        }, close: "Close"))
    }
}

/// .tag labels, centred and wrapping (padding:2px 4px around them)
final class TagsView: UIView {
    private var items: [(UIView, CGSize)] = []
    init(_ tags: [(String, UIColor)]) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        for (t, c) in tags {
            let v = UIView()
            v.backgroundColor = c
            v.layer.cornerRadius = px(3)
            v.clipsToBounds = true
            v.alpha = 0.85
            let g = GradientView([UIColor(white: 0, alpha: 0.3), .clear])
            v.addSubview(g)
            var st = TextStyle.base(10, color: .black)
            st.family = .arial; st.bold = true; st.nowrap = true
            st.shadow = Shadows.make(0, 1, 0, UIColor(white: 1, alpha: 0.25))
            let l = RichLabel(st)
            l.html = t
            let s = RichText.size(RichText.render(t, style: st, width: nil), width: nil)
            let size = CGSize(width: s.width + 6, height: 14)
            l.frame = CGRect(x: px(3), y: px(2), width: px(Double(s.width) + 1), height: px(12))
            g.frame = CGRect(x: 0, y: 0, width: px(Double(size.width)), height: px(14))
            v.addSubview(l)
            addSubview(v)
            items.append((v, size))
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    @discardableResult
    func height(_ w: Double) -> Double {
        if items.isEmpty { return 0 }
        // lines of inline-blocks (margin 1px 2px 0 0), centred
        var lines: [[(UIView, CGSize)]] = [[]]
        var lw = 0.0
        let inner = w - 8
        for it in items {
            let iw = Double(it.1.width) + 2
            if lw + iw > inner && !lines[lines.count - 1].isEmpty { lines.append([]); lw = 0 }
            lines[lines.count - 1].append(it); lw += iw
        }
        var y = 2.0
        for line in lines {
            let total = line.reduce(0.0) { $0 + Double($1.1.width) + 2 }
            var x = 4 + (inner - total) / 2
            for (v, s) in line {
                v.frame = CGRect(x: px(x), y: px(y + 1), width: px(Double(s.width)), height: px(14))
                x += Double(s.width) + 2
            }
            y += 15 + 1
        }
        return y + 2 - 1
    }
}

// MARK: - sugar lumps (mods/sugar-lumps.js)

enum LumpUI {
    /// __ccLevelBox: the building level section in a building's info popup
    static func levelBox(_ c: PopupContent, _ me: Building) {
        if !Lumps.canLumps() || G.lumpT <= 0 { return }
        let lvl = me.level, cost = lvl + 1, can = G.lumps >= Double(cost)
        let what = lvl > 0
            ? (lvl == 1 ? me.extraName : me.extraPlural).replacingOccurrences(of: "[X]", with: B(Double(lvl))) + " granting <b>+\(B(Double(lvl)))% \(me.single) CpS</b>."
            : "Spend sugar lumps to level up this building. Each level gives <b>+1%</b> to its production."
        c.line()
        c.add(H3View("Level \(B(Double(lvl)))"), height: 23, marginTop: 8, marginBottom: 4, marginLeft: 4, marginRight: 4)
        c.html("<p style=\"text-align:center;\">\(what)</p>", marginLeft: 4, marginRight: 4)
        let b = CCButton("Level up for \(B(Double(cost))) sugar lump\(cost == 1 ? "" : "s")", look: .bump)
        if !can { b.alpha = 0.5 }
        b.onTap = { v in
            if Lumps.levelUpBuilding(me) { Popup.close() }
            else { PlaySound("snd/clickOff2.mp3", 0.5); Anim.trigger(v, "plop") }
        }
        c.buttons([b], marginTop: 2, marginBottom: 2, height: 19)
        c.html("<p style=\"text-align:center;font-size:85%;color:rgba(255,255,255,0.6);\">You have \(B(G.lumps)) sugar lump\(G.lumps == 1 ? "" : "s").</p>", marginBottom: 4)
        // minigame-bridge.js: open the minigame, or say how to unlock it
        if let mg = Minigames.names[me.name] {
            if me.level >= 1 {
                let o = CCButton("Open \(mg)", look: .bump)
                o.onTap = { _ in Minigames.openWindow(me.name) }
                c.buttons([o], marginTop: 6, height: 19)
            } else {
                c.html("<div style=\"text-align:center;font-size:85%;color:rgba(255,255,255,0.7);\">Levelling up your \(me.plural) unlocks the <b>\(mg)</b> minigame.</div>")
            }
        }
    }

    /// G.lumpPopup
    static func popup() {
        PlaySound("snd/press.mp3", 0.15)
        let age = nowMs() - G.lumpT
        let mature = age >= Lumps.matureAge, ripe = age >= Lumps.ripeAge
        var status: String
        if !mature { status = "This sugar lump is still growing and will be <b>mature</b> in <b>\(sayTime(Lumps.matureAge - age, -1))</b>, <b>ripe</b> in <b>\(sayTime(Lumps.ripeAge - age, -1))</b> and will <b>fall</b> in <b>\(sayTime(Lumps.overripeAge - age, -1))</b>." }
        else if !ripe { status = "This sugar lump is <b>mature</b> and will be <b>ripe</b> in <b>\(sayTime(Lumps.ripeAge - age, -1))</b>. Harvesting it now has a <b>50% chance</b> of working. It will fall on its own in <b>\(sayTime(Lumps.overripeAge - age, -1))</b>." }
        else { status = "This sugar lump is <b>ripe</b>! Harvest it now, or it will fall on its own in <b>\(sayTime(Lumps.overripeAge - age, -1))</b>." }
        var typeText = ""
        switch G.lumpCurrentType {
        case 1: typeText = "This sugar lump grew to be <b>bifurcated</b>; harvesting it has a 50% chance of yielding two lumps."
        case 2: typeText = "This sugar lump grew to be <b>golden</b>; harvesting it will yield 2 to 7 lumps and double your cookies (up to a day's worth)."
        case 3: typeText = "This sugar lump was affected by the elders and grew to be <b>meaty</b>; harvesting it will yield between 0 and 2 lumps."
        case 4: typeText = "This sugar lump is <b>caramelized</b>, its stickiness binding it to unexpected things; harvesting it will yield between 1 and 3 lumps."
        default: break
        }
        let ic = Lumps.lumpIcons()
        Popup.open(PopupOptions(build: { c in
            c.h3("Sugar lumps")
            let icon = IconView(ic.b)
            let holder = UIView()
            holder.addSubview(icon)
            icon.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            c.add(holder, marginTop: 4) { _ in
                icon.center = CGPoint(x: holder.bounds.midX, y: px(36))
                return 72
            }
            c.html("<div style=\"text-align:center;\"><p>You have <b>\(B(G.lumps)) sugar lump\(G.lumps == 1 ? "" : "s")</b>.</p><p>\(status)</p>\(typeText.isEmpty ? "" : "<p>\(typeText)</p>")</div>", marginLeft: 4, marginRight: 4)
            if mature {
                let b = CCButton("Harvest", look: .bump)
                b.onTap = { _ in Popup.close(); Lumps.harvestLumpNow() }
                c.buttons([b], height: 19)
            }
            c.space(4)
            c.line()
            c.html("""
            <div style="padding:4px;font-size:90%;color:rgba(255,255,255,0.75);">
            <p>&bull; Sugar lumps can be harvested when mature; left alone they ripen (harvest is then guaranteed) and eventually fall and are harvested automatically.</p>
            <p>&bull; Spend them to <b>level up buildings</b> from each building's info screen in the Store: every level gives <b>+1%</b> to that building's production.</p>
            <p>&bull; Sugar lumps keep growing while the game is closed.</p>
            </div>
            """)
        }, close: "Close"))
    }
}

/// #ccLumps: the sugar lump on the cookie screen (top left), with how many you have
final class LumpWidget: TapView {
    private let a = IconView()
    private let b = IconView()
    private let amount = RichLabel()
    private var pulsing = false
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: px(4), y: px(58), width: px(48), height: px(62)))
        a.frame = CGRect(x: 0, y: 0, width: px(48), height: px(48))
        b.frame = a.frame
        addSubview(a); addSubview(b)
        var st = TextStyle.fancy(13)
        st.align = .center; st.shadow = Shadows.make(0, 1, 1)
        amount.style = st
        amount.frame = CGRect(x: -px(20), y: px(44), width: px(88), height: px(16))
        addSubview(amount)
        onTap = { _ in LumpUI.popup() }
    }
    required init?(coder: NSCoder) { fatalError() }
    private var lastAmount = ""
    /// G.drawLump
    func update() {
        if !Lumps.canLumps() || G.lumpT <= 0 { isHidden = true; return }
        isHidden = false
        let ic = Lumps.lumpIcons()
        a.icon = ic.a; b.icon = ic.b
        b.alpha = CGFloat(ic.opacity)
        let s = B(G.lumps)
        if s != lastAmount { lastAmount = s; amount.html = s }
        let ripe = nowMs() - G.lumpT >= Lumps.matureAge
        if ripe != pulsing {
            pulsing = ripe
            if ripe {
                // ccLumpPulse: a soft glow coming and going
                b.layer.shadowColor = UIColor(red: 1, green: 1, blue: 200 / 255, alpha: 1).cgColor
                b.layer.shadowOffset = .zero; b.layer.shadowRadius = px(3)
                let an = CABasicAnimation(keyPath: "shadowOpacity")
                an.fromValue = 0; an.toValue = 0.9; an.duration = 0.8; an.autoreverses = true; an.repeatCount = .infinity
                an.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                b.layer.add(an, forKey: "pulse")
            } else { b.layer.removeAnimation(forKey: "pulse"); b.layer.shadowOpacity = 0 }
        }
    }
}
