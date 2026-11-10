import UIKit

// The stats screen (www/main.js "stats"): numbers, log and news, upgrades and achievements.

/// a box with the faint doily border (.doilyTrim inside a block with margin:-2px)
final class DoilyBox: UIView {
    let doily = BorderImageView(image: "img/doilyBorder.png", slice: 16, width: 6)
    override init(frame: CGRect) {
        super.init(frame: frame)
        doily.alpha = 0.3
        addSubview(doily)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        doily.frame = bounds.insetBy(dx: px(1), dy: px(1))
        sendSubviewToBack(doily)
    }
}

/// .smallHeader: Georgia bold centred on a wooden bar (barH.png) spanning the screen
final class SmallHeader: UIView {
    let bar = PicView("img/barH.png")
    let label = RichLabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        clipsToBounds = false
        addSubview(bar)
        var st = TextStyle(); st.family = .georgia; st.bold = true; st.align = .center; st.color = .ccText; st.shadow = Shadows.print
        label.style = st
        addSubview(label)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        // margin 0 -8px (so it spans the section), bar 320x28 from 4px above
        bar.frame = CGRect(x: -px(8), y: -px(4), width: px(320), height: px(28))
        label.frame = CGRect(x: 0, y: px(4), width: bounds.width, height: px(13))
    }
}

/// .bumpButton.fullButton: 56px high, Fancy 16px, an icon then the text
final class FullButton: TapView {
    let shade = GradientView.buttonShade()
    let bevel = BevelView(.bump)
    let icon: IconView
    let label = RichLabel()
    init(text: String, icon ic: [Int]) {
        icon = IconView(ic)
        super.init(frame: .zero)
        brightensWhenPressed = true
        layer.cornerRadius = px(4)
        clipsToBounds = true
        addSubview(shade); addSubview(bevel); addSubview(icon)
        var st = TextStyle.fancy(16, color: .ccText); st.bold = true; st.nowrap = true; st.shadow = Shadows.body
        label.style = st
        label.html = text
        addSubview(label)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        shade.frame = bounds; bevel.frame = bounds
        let tw = Double(label.textSize.width)
        let total = 4 + 48 + 4 + tw
        let x = (Double(bounds.width / K) - total) / 2
        icon.frame = CGRect(x: px(x + 4), y: px(28 - 24 + 2), width: px(48), height: px(48))
        label.frame = CGRect(x: px(x + 56), y: px(20 + 1), width: px(tw + 4), height: px(18))
    }
}

/// a row (or grid) of tappable icons
final class IconGrid: UIView {
    private var items: [(TapView, IconView)] = []
    func set(_ icons: [([Int], CGFloat, (() -> Void)?)]) {
        items.forEach { $0.0.removeFromSuperview() }
        items = icons.map { ic in
            let t = TapView(frame: CGRect(x: 0, y: 0, width: px(48), height: px(48)))
            let iv = IconView(ic.0)
            iv.alpha = ic.1
            t.addSubview(iv)
            if let f = ic.2 { t.onTap = { v in Anim.trigger(v, "plop"); f() } }
            addSubview(t)
            return (t, iv)
        }
    }
    /// inline-blocks centred in lines; maxLines limits the height (overflow hidden)
    func height(_ w: Double, maxLines: Int = 1000) -> Double {
        let perLine = max(1, Int(w / 48))
        let n = items.count
        let lines = (n + perLine - 1) / perLine
        for (i, it) in items.enumerated() {
            let line = i / perLine
            let inLine = min(perLine, n - line * perLine)
            let x0 = (w - Double(inLine) * 48) / 2
            it.0.frame = CGRect(x: px(x0 + Double(i % perLine) * 48), y: px(Double(line) * 48), width: px(48), height: px(48))
            it.0.isHidden = line >= maxLines
        }
        return Double(min(lines, maxLines)) * 48
    }
}

final class StatsScreen: GameScreen {
    private var panel: SectionPanel?
    private var lastTick = 0.0
    private var relayout: (() -> Void)?
    private var updaters: [() -> Bool] = []

    init() { super.init(name: "stats") }

    override func build() {
        updaters = []
        let p = SectionPanel(in: view)
        panel = p
        let c = p.scroll.content
        let W = p.width

        let header = PinHeader("Stats")
        c.addSubview(header)

        // Log / News buttons, floating right
        func sideButton(_ icon: [Int], _ name: String, _ act: @escaping () -> Void) -> TapView {
            let b = TapView()
            b.brightensWhenPressed = true
            b.layer.cornerRadius = px(4); b.clipsToBounds = true
            let sh = GradientView.buttonShade(); let bv = BevelView(.bump)
            let iv = IconView(icon)
            var st = TextStyle(); st.family = .georgia; st.bold = true; st.align = .center; st.color = .ccText; st.shadow = Shadows.print
            let l = RichLabel(st); l.html = name
            b.addSubview(sh); b.addSubview(bv); b.addSubview(iv); b.addSubview(l)
            b.frame = CGRect(x: 0, y: 0, width: px(56), height: px(54))
            sh.frame = b.bounds; bv.frame = b.bounds
            iv.frame = CGRect(x: px(4), y: px(-1), width: px(48), height: px(48))
            l.frame = CGRect(x: 0, y: px(35), width: px(56), height: px(14))
            b.onTap = { v in act() }
            return b
        }
        let logB = sideButton([15, 9], "Log") { StatsScreen.logPopup() }
        let newsB = sideButton([27, 7], "News") { StatsScreen.newsPopup() }
        c.addSubview(logB); c.addSubview(newsB)

        // the numbers
        let statsBox = DoilyBox()
        let stats = RichLabel(TextStyle.base(11)); stats.style.shadow = Shadows.body; stats.style.pPad = 2
        statsBox.addSubview(stats)
        c.addSubview(statsBox)
        stats.html = StatsScreen.statsHTML()
        updaters.append { let s = StatsScreen.statsHTML(); if s != stats.html { stats.html = s; return true }; return false }

        // upgrades
        let upH = SmallHeader()
        func upText() -> String { "<p>Upgrades owned: <b>\(B(Double(G.upgradesN)))/\(B(Double(G.upgradesTotal)))</b> (\(B(Double(G.upgradesN) / Double(G.upgradesTotal) * 100, 1))%)</p>" }
        upH.label.style.pPad = 2; upH.label.html = upText()
        c.addSubview(upH)
        let upBox = DoilyBox()
        let recentUpL = RichLabel(TextStyle.base(11)); recentUpL.style.shadow = Shadows.body; recentUpL.style.pPad = 2; recentUpL.html = "<p>Recent upgrades:</p>"
        let recentUp = IconGrid()
        let viewUp = FullButton(text: "View upgrades", icon: [29, 30])
        viewUp.onTap = { _ in StatsScreen.upgradesPopup() }
        upBox.addSubview(recentUpL); upBox.addSubview(recentUp); upBox.addSubview(viewUp)
        c.addSubview(upBox)

        // achievements
        let acH = SmallHeader()
        func acText() -> String { "<p>Achievements unlocked: <b>\(B(Double(G.achievsN)))/\(B(Double(G.achievsTotal)))</b> (\(B(Double(G.achievsN) / Double(G.achievsTotal) * 100, 1))%)</p>" }
        acH.label.style.pPad = 2; acH.label.html = acText()
        c.addSubview(acH)
        let acBox = DoilyBox()
        let milkL = RichLabel(TextStyle.base(11)); milkL.style.shadow = Shadows.body; milkL.style.pPad = 2
        func milkHTML() -> String {
            let milk = G.milks[min(G.milks.count - 1, G.achievsN / 25)]
            return "<p>Milk: <span class=\"tinyIcon\" style=\"background-position:\(-milk.icon[0] * 48)px \(-milk.icon[1] * 48)px;\"></span> <b>\(milk.name)</b></p><div style=\"font-size:70%;margin:4px 0px;text-align:center;opacity:0.75;\">(Milk is gained with each achievement. May unlock unique upgrades over time.)</div>"
        }
        milkL.html = milkHTML()
        let recentAcL = RichLabel(TextStyle.base(11)); recentAcL.style.shadow = Shadows.body; recentAcL.style.pPad = 2; recentAcL.html = "<p>Recent achievements:</p>"
        let recentAc = IconGrid()
        let viewAc = FullButton(text: "View achievements", icon: [29, 7])
        viewAc.onTap = { _ in StatsScreen.achievsPopup() }
        acBox.addSubview(milkL); acBox.addSubview(recentAcL); acBox.addSubview(recentAc); acBox.addSubview(viewAc)
        c.addSubview(acBox)

        var lastUp = "", lastAc = ""
        func refreshRecent() -> Bool {
            let u = G.recentUpgrades.map { String($0.id) }.joined(separator: ",")
            let a = G.recentAchievs.map { String($0.id) }.joined(separator: ",")
            var changed = false
            if u != lastUp {
                lastUp = u; changed = true
                recentUp.set(G.recentUpgrades.map { me in (me.iconFunc?() ?? me.icon, 1, { UpgradeUI.showInfo(me) }) })
            }
            if a != lastAc {
                lastAc = a; changed = true
                recentAc.set(G.recentAchievs.map { me in (me.icon, 1, { AchievUI.showInfo(me) }) })
            }
            return changed
        }
        _ = refreshRecent()
        updaters.append(refreshRecent)
        updaters.append {
            var ch = false
            let u = upText(); if u != upH.label.html { upH.label.html = u; ch = true }
            let a = acText(); if a != acH.label.html { acH.label.html = a; ch = true }
            let m = milkHTML(); if m != milkL.html { milkL.html = m; ch = true }
            return ch
        }

        func layoutAll() {
            guard let p = self.panel else { return }
            var y: Double = 8.0
            header.frame = CGRect(x: px(8 + (W - header.cssWidth) / 2), y: px(y + 2), width: px(header.cssWidth), height: px(45))
            y += 45 + 2 - 12
            // float right: Log, News (margin-top 4px, each a bumpButton with 2px margins)
            logB.frame.origin = CGPoint(x: px(8 + W - 2 - 56), y: px(y + 4 + 2))
            newsB.frame.origin = CGPoint(x: px(8 + W - 2 - 56), y: px(y + 4 + 2 + 54 + 4 + 4))
            // the numbers flow around them
            let floatBottom: Double = 4 + 2 + 54 + 8 + 54 + 2 - 8
            stats.exclusions = [CGRect(x: W - 60, y: 0, width: 60, height: floatBottom)]
            let sh = stats.fittingHeight(W)
            statsBox.frame = CGRect(x: px(8), y: px(y + 4), width: px(W), height: px(sh + 8))
            stats.frame = CGRect(x: 0, y: px(4), width: px(W), height: px(sh))
            y += 4 + sh + 8 + 4
            y = max(y, Double(newsB.frame.maxY / K) + 4)
            // upgrades
            upH.frame = CGRect(x: px(8), y: px(y), width: px(W), height: px(16))
            y += 16 + 4
            var by = 4.0
            if !G.recentUpgrades.isEmpty {
                recentUpL.isHidden = false; recentUp.isHidden = false
                let lh = recentUpL.fittingHeight(W - 16)
                recentUpL.frame = CGRect(x: px(8), y: px(by), width: px(W - 16), height: px(lh)); by += lh
                let gh = recentUp.height(W - 16, maxLines: 1)
                recentUp.frame = CGRect(x: px(8), y: px(by), width: px(W - 16), height: px(gh)); by += gh + 4
            } else { recentUpL.isHidden = true; recentUp.isHidden = true }
            viewUp.frame = CGRect(x: px(8), y: px(by + 4), width: px(W - 16), height: px(56)); by += 4 + 56 + 4 + 4
            upBox.frame = CGRect(x: px(8), y: px(y), width: px(W), height: px(by))
            y += by + 4
            // achievements
            acH.frame = CGRect(x: px(8), y: px(y), width: px(W), height: px(16))
            y += 16 + 4
            by = 4
            let mh = milkL.fittingHeight(W - 16)
            milkL.frame = CGRect(x: px(8), y: px(by), width: px(W - 16), height: px(mh)); by += mh
            if !G.recentAchievs.isEmpty {
                recentAcL.isHidden = false; recentAc.isHidden = false
                let lh = recentAcL.fittingHeight(W - 16)
                recentAcL.frame = CGRect(x: px(8), y: px(by), width: px(W - 16), height: px(lh)); by += lh
                let gh = recentAc.height(W - 16, maxLines: 1)
                recentAc.frame = CGRect(x: px(8), y: px(by), width: px(W - 16), height: px(gh)); by += gh + 4
            } else { recentAcL.isHidden = true; recentAc.isHidden = true }
            viewAc.frame = CGRect(x: px(8), y: px(by + 4), width: px(W - 16), height: px(56)); by += 4 + 56 + 4 + 4
            acBox.frame = CGRect(x: px(8), y: px(y), width: px(W), height: px(by))
            y += by + 4
            p.scroll.setContentHeight(px(y + 8))
            p.scroll.content.bringSubviewToFront(header)
        }
        relayout = layoutAll
        layoutAll()
    }
    override func clean() { panel = nil; relayout = nil; updaters = [] }
    override func draw() {
        if nowMs() - lastTick < 150 { return }
        lastTick = nowMs()
        var changed = false
        for u in updaters { if u() { changed = true } }
        if changed { relayout?() }
    }

    static func statsHTML() -> String {
        var s = ""
        if G.resets > 0 { s += "<p>Legacy started: <b>\(sayTime(nowMs() - G.gameStart)) ago</b><br><span style=\"padding-left:16px;font-size:80%;\">with \(B(Double(G.resets))) ascension\(G.resets == 1 ? "" : "s")</span></p>" }
        s += "<p>Run started: <b>\(sayTime(nowMs() - G.runStart)) ago</b></p>"
        s += "<p>Cookies in bank: <span class=\"tinyCookie\"></span><b>\(B(G.cookies, 0, 2))</b></p>"
        if G.cookies >= 1000 { s += "<p style=\"font-size:80%;opacity:0.75;padding-left:16px;margin-top:-3px;\">...or <span class=\"tinyCookie\"></span><b>\(B(G.cookies, 0, 1))</b></p>" }
        s += "<p>Cookies baked: <span class=\"tinyCookie\"></span><b>\(B(G.cookiesEarned, 0, 2))</b></p>"
        if G.cookiesEarned >= 1000 { s += "<p style=\"font-size:80%;opacity:0.75;padding-left:16px;margin-top:-3px;\">...or <span class=\"tinyCookie\"></span><b>\(B(G.cookiesEarned, 0, 1))</b></p>" }
        s += "<p>Cookies per second (CpS): <span class=\"tinyCookie\"></span><b>\(B(G.cookiesPs, 1, 2))</b></p>"
        if G.cookiesPs >= 1000 { s += "<p style=\"font-size:80%;opacity:0.75;padding-left:16px;margin-top:-3px;\">...or <span class=\"tinyCookie\"></span><b>\(B(G.cookiesPs, 1, 1))</b>/s</p>" }
        let cpsM = G.pool["cpsM"] ?? 1, buffM = G.pool["cpsBuffM"] ?? 1
        s += "<p>CpS multiplier: <b>\(cpsM * 100 - 100 >= 0 ? "+" : "")\(B(cpsM * 100 - 100, 1, 1))%</b></p>"
        if buffM != 1 { s += "<p style=\"font-size:80%;opacity:0.75;padding-left:16px;margin-top:-3px;\">...plus from buffs: <b>\(buffM * 100 - 100 >= 0 ? "+" : "")\(B(buffM * 100 - 100, 1, 1))%</b></p>" }
        if G.prestige > 0 { s += "<p style=\"font-size:80%;opacity:0.75;padding-left:16px;margin-top:-3px;\">...plus from prestige: <b>+\(B(G.prestige * G.GetHeavenlyMultiplier(), 1))%</b></p>" }
        if G.cpsSucked > 0 { s += "<p class=\"warning\">CpS withered by wrinklers: <b>\(B(G.cpsSucked * 100, 1, 1))%</b> of total</p>" }
        if G.wrinklersPopped > 0 { s += "<p>Wrinklers popped: <b>\(B(Double(G.wrinklersPopped)))</b></p>" }
        s += "<p>Cookie taps: <b>\(B(Double(G.cookieClicks), 0, 1))</b></p>"
        s += "<p>Cookies per tap: <span class=\"tinyCookie\"></span><b>\(B(G.cookiesPc, 0, 1))</b></p>"
        s += "<p>Hand-made cookies: <span class=\"tinyCookie\"></span><b>\(B(G.cookiesHandmade, 0, 1))</b></p>"
        s += "<p>Golden cookie clicks: <b>\(B(G.gcClicksTotal, 0, 1))</b></p>"
        if G.reindeerClicks > 0 { s += "<p>Reindeer clicks: <b>\(B(Double(G.reindeerClicks), 0, 1))</b></p>" }
        s += "<p>Buildings owned: <b>\(B(Double(G.buildingsN)))</b></p>"
        return s
    }

    static func timeOf(_ t: Double) -> String {
        let d = Date(timeIntervalSince1970: t / 1000)
        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
        return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
    }
    static func logPopup() {
        Popup.open(PopupOptions(build: { c in
            c.h3("<span class=\"tinyIcon\" style=\"background-position:\(-15 * 48)px \(-9 * 48)px;\"></span> Log")
            if G.savedToasts.isEmpty { c.line(); c.html("<div style=\"text-align:center;\">(no logs on record.)</div>") }
            for (html, t) in G.savedToasts {
                c.line()
                let l = c.html("<div style=\"text-align:center;\">\(html)</div>")
                let stamp = RichLabel(TextStyle.base(8)); stamp.style.bold = true; stamp.alpha = 0.5
                stamp.html = "[\(timeOf(t))]"
                stamp.frame = CGRect(x: -px(8), y: -px(8), width: px(40), height: px(10))
                l.clipsToBounds = false
                l.addSubview(stamp)
            }
        }, close: "Close"))
    }
    static func newsPopup() {
        var o = PopupOptions(build: { c in
            c.h3("<span class=\"tinyIcon\" style=\"background-position:\(-27 * 48)px \(-7 * 48)px;\"></span> News")
            if G.savedNews.isEmpty { c.line(); c.html("<div style=\"text-align:center;\">(no news on record.)</div>") }
            for (html, t) in G.savedNews {
                c.line()
                let l = c.html("<div style=\"text-align:center;\"><span class=\"fancy\">\(html)</span></div>")
                let stamp = RichLabel(TextStyle.base(8)); stamp.style.bold = true; stamp.alpha = 0.5
                stamp.html = "[\(timeOf(t))]"
                stamp.frame = CGRect(x: -px(8), y: -px(8), width: px(40), height: px(10))
                l.clipsToBounds = false
                l.addSubview(stamp)
            }
        }, close: "Close")
        o.onClose = nil
        Popup.open(o)
        G.win("Tabloid addiction")
    }
    static func upgradesPopup() {
        Popup.open(PopupOptions(build: { c in
            c.h3("Upgrades")
            c.html("<div style=\"text-align:center;opacity:0.75;margin-bottom:4px;\">Owned: <b>\(B(Double(G.upgradesN)))/\(B(Double(G.upgradesTotal)))</b> (\(B(Double(G.upgradesN) / Double(G.upgradesTotal) * 100, 1))% of total)</div>")
            c.line()
            let list = G.upgrades.filter { $0.pool != "prestige" && $0.owned != 0 }.sorted { $0.order < $1.order }
            let grid = IconGrid()
            grid.set(list.map { me in (me.iconFunc?() ?? me.icon, 1, { UpgradeUI.showInfo(me) }) })
            c.add(grid) { w in grid.height(w) }
        }, close: "Close"))
    }
    static func achievsPopup() {
        Popup.open(PopupOptions(build: { c in
            c.h3("Achievements")
            c.html("<div style=\"text-align:center;opacity:0.75;margin-bottom:4px;\">Unlocked: <b>\(B(Double(G.achievsN)))/\(B(Double(G.achievsTotal)))</b> (\(B(Double(G.achievsN) / Double(G.achievsTotal) * 100, 1))% of total)</div>")
            c.line()
            let list = G.achievs.filter { !$0.unimplemented && $0.pool != "shadow" }.sorted { $0.order < $1.order }
            let shadow = G.achievs.filter { !$0.unimplemented && $0.pool == "shadow" && $0.owned != 0 }.sorted { $0.order < $1.order }
            let grid = IconGrid()
            func items() -> [([Int], CGFloat, (() -> Void)?)] {
                list.map { me in
                    if me.owned != 0 { return (me.icon, 1, { AchievUI.showInfo(me) }) }
                    return ([0, 7], 0.5, me.name == "Here you go" ? {
                        G.win(me.name)
                        PlaySound("snd/tick.mp3", 1); PlaySound("snd/shimmerClick.mp3", 1)
                        grid.set(items()); _ = grid.height(Double(grid.bounds.width / K))
                    } : nil)
                }
            }
            grid.set(items())
            c.add(grid) { w in grid.height(w) }
            if !shadow.isEmpty {
                c.html("<div style=\"text-align:center;opacity:0.75;margin-top:8px;\"><b>Shadow achievements</b><br>(These are feats that are either unfair or difficult to attain. They do not give milk.)</div>")
                let sg = IconGrid()
                sg.set(shadow.map { me in (me.icon, 1, { AchievUI.showInfo(me) }) })
                c.add(sg) { w in sg.height(w) }
            }
        }, close: "Close"))
    }
}
