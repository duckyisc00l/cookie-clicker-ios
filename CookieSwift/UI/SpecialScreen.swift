import UIKit

// The special screen (www/main.js "special"): legacy/ascension, research, grandmapocalypse, golden switch,
// season, pets, quick buttons and customisation; and the popups those open.

// MARK: - shared pieces

/// .section: the dark scrolling panel under the gilded trim (top 56px, bottom 4px, padding 8px)
final class SectionPanel {
    let scroll = ScrollArea()
    let trimTop: PicView
    let trimBottom = PicView("img/trimBottom.png")
    init(in v: UIView, noLeft: Bool = false) {
        trimTop = PicView(noLeft ? "img/trimTopNoLeft.png" : "img/trimTop.png")
        let H = v.bounds.height
        scroll.frame = CGRect(x: 0, y: px(56), width: v.bounds.width, height: H - px(56 + 4))
        scroll.backgroundColor = UIColor(white: 0, alpha: 0.5)
        v.addSubview(scroll)
        trimTop.frame = CGRect(x: 0, y: px(56 - 16), width: px(320), height: px(59))
        trimBottom.frame = CGRect(x: 0, y: H - px(8) + px(16) - px(59), width: px(320), height: px(59))
        v.addSubview(trimTop); v.addSubview(trimBottom)
    }
    /// inner width (padding 8px)
    var width: Double { Double(scroll.bounds.width / K) - 16 }
}

/// .headerTitle: the screen's name on a pinned scroll of paper (pinMid with pinLeft/pinRight ends); swings when touched
final class PinHeader: TapView {
    private let mid = PicView("img/pinMid.png")
    private let left = PicView("img/pinLeft.png")
    private let right = PicView("img/pinRight.png")
    private let label = RichLabel()
    let textWidth: Double
    init(_ text: String) {
        var st = TextStyle(); st.family = .georgia; st.bold = true; st.size = 18; st.smallCaps = true
        st.letterSpacing = 2; st.color = .ccText; st.shadow = Shadows.print; st.nowrap = true
        textWidth = Double(RichText.size(RichText.render(text, style: st, width: nil), width: nil).width)
        super.init(frame: .zero)
        label.style = st
        label.html = text
        addSubview(left); addSubview(right); addSubview(mid); addSubview(label)
        onDown = { [weak self] _, _ in self?.swing() }
    }
    required init?(coder: NSCoder) { fatalError() }
    /// width:max-content + padding 6px 6px 0 8px
    var cssWidth: Double { textWidth + 14 }
    override func layoutSubviews() {
        super.layoutSubviews()
        let h = bounds.height
        mid.frame = bounds
        left.frame = CGRect(x: -px(30), y: 0, width: px(30), height: h)
        right.frame = CGRect(x: bounds.width, y: 0, width: px(22), height: h)
        label.frame = CGRect(x: px(8), y: px(6), width: px(textWidth + 4), height: px(22))
    }
    /// G.toyPins: the paper swings on its pins
    private func swing() {
        var p = CATransform3DIdentity; p.m34 = -1 / px(200)
        let a = CAKeyframeAnimation(keyPath: "transform")
        let angles: [CGFloat] = [0, 0.5, -0.35, 0.2, -0.1, 0]
        a.values = angles.map { NSValue(caTransform3D: CATransform3DRotate(p, $0, 1, 0, 0)) }
        a.duration = 1.2
        label.layer.add(a, forKey: "swing")
    }
}

/// .bumpy: a bevelled box
final class BumpyBox: UIView {
    let bevel = BevelView(.bump)
    var header: UIView?
    init() {
        super.init(frame: .zero)
        clipsToBounds = true
        layer.cornerRadius = px(4)
        addSubview(bevel)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        bevel.frame = bounds
        bringSubviewToFront(bevel)
        if let h = header { bringSubviewToFront(h) }
    }
    /// .sliverHeader: a black tab in the top-left corner, optional small icon
    @discardableResult
    func sliverHeader(_ text: String, icon: [Int]? = nil) -> UIView {
        let v = UIView()
        v.backgroundColor = .black
        v.layer.cornerRadius = px(4)
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMaxYCorner]
        var st = TextStyle.base(9.9, color: .ccText); st.bold = true; st.shadow = Shadows.body; st.nowrap = true
        let l = RichLabel(st)
        l.html = text
        let tw = text.isEmpty ? 0 : Double(RichText.size(RichText.render(text, style: st, width: nil), width: nil).width)
        let padL = icon != nil ? 24.0 : 6
        v.frame = CGRect(x: px(2), y: px(2), width: px(padL + tw + 6), height: px(22))
        l.frame = CGRect(x: px(padL), y: px(3 + 2.5), width: px(tw + 2), height: px(14))
        v.addSubview(l)
        if let ic = icon {
            let iv = IconView(ic)
            iv.frame = CGRect(x: px(2), y: px(-5), width: px(24), height: px(24))
            v.clipsToBounds = false
            v.addSubview(iv)
        }
        addSubview(v)
        header = v
        return v
    }
}

/// a square icon button on a bar indent (G.visualButton / G.toggleButton)
final class SquareButton: TapView {
    let indent = PicView("img/barIndent.png")
    let icon = IconView()
    let label = RichLabel()
    init(icon ic: [Int]?, text: String? = nil) {
        super.init(frame: CGRect(x: 0, y: 0, width: px(48), height: px(48)))
        brightensWhenPressed = true
        layer.cornerRadius = px(4)
        indent.frame = bounds
        addSubview(indent)
        if let ic = ic { icon.icon = ic; icon.frame = bounds; addSubview(icon) }
        if let t = text {
            var st = TextStyle.fancy(10, color: .ccText); st.bold = true; st.align = .center; st.shadow = Shadows.body
            label.style = st
            label.html = t
            let h = label.fittingHeight(48)
            label.frame = CGRect(x: 0, y: px(48 - h), width: px(48), height: px(h))
            addSubview(label)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
}

/// a pet picture (96px frame at half size) on a shaded backdrop, wiggling
final class PetPic: UIView {
    let backdrop = PicView("img/shadedBackdrop.png")
    let pic = UIImageView()
    init(sheet: String, frame f: Int, wiggle: Bool, delay: Double = 0) {
        super.init(frame: CGRect(x: 0, y: 0, width: px(48), height: px(48)))
        isUserInteractionEnabled = false
        backdrop.frame = bounds
        addSubview(backdrop)
        pic.frame = bounds
        pic.image = Res.sprite(sheet, x: Double(96 * f), y: 0, w: 96, h: 96)
        addSubview(pic)
        if wiggle {
            // petWiggle: squash and tilt about (50%, 90%)
            pic.layer.anchorPoint = CGPoint(x: 0.5, y: 0.9)
            pic.frame = bounds
            func t(_ sx: CGFloat, _ sy: CGFloat, _ r: CGFloat) -> NSValue {
                NSValue(caTransform3D: CATransform3DRotate(CATransform3DMakeScale(sx, sy, 1), r * .pi / 180, 0, 0, 1))
            }
            let a = CAKeyframeAnimation(keyPath: "transform")
            a.values = [t(0.95, 1.05, -4), t(1.05, 0.95, 0), t(0.95, 1.05, 4), t(1.05, 0.95, 0), t(0.95, 1.05, -4)]
            a.keyTimes = [0, 0.3, 0.5, 0.8, 1]
            a.timingFunctions = Array(repeating: CAMediaTimingFunction(name: .easeInEaseOut), count: 4)
            a.duration = 1
            a.repeatCount = .infinity
            a.timeOffset = delay
            pic.layer.add(a, forKey: "wiggle")
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    func setFrame(_ sheet: String, _ f: Int) { pic.image = Res.sprite(sheet, x: Double(96 * f), y: 0, w: 96, h: 96) }
}

/// a .bumpButton holding a .listing: picture on the left, name/description/details, tinted, maybe glowing
final class ListingButton: TapView {
    let bevel = BevelView(.bump)
    let tint: GradientView
    let body = RichLabel()
    let leftPic: UIView?
    let padLeft: Double
    var glow: UIColor?
    init(html: String, icon: [Int]? = nil, pet: (String, Int)? = nil, color: (Int, Int, Int)? = (255, 255, 255), active: Bool = false, highlight: Bool = false, bevel showBevel: Bool = true, dim: Bool = false) {
        if let c = color {
            let col = UIColor(red: CGFloat(c.0) / 255, green: CGFloat(c.1) / 255, blue: CGFloat(c.2) / 255, alpha: 1)
            tint = GradientView([col.withAlphaComponent(0.2), col.withAlphaComponent(0.1)])
        } else { tint = GradientView([.clear, .clear]) }
        if let ic = icon { leftPic = IconView(ic); padLeft = 48 }
        else if let p = pet { leftPic = PetPic(sheet: p.0, frame: p.1, wiggle: false); padLeft = pet!.0.contains("dragon") ? 64 : 48 }
        else { leftPic = nil; padLeft = 6 }
        super.init(frame: .zero)
        brightensWhenPressed = true
        layer.cornerRadius = px(4)
        addSubview(tint)
        tint.layer.cornerRadius = px(4); tint.clipsToBounds = true
        if let p = leftPic { addSubview(p) }
        var st = TextStyle.base(11, color: .ccText); st.align = .center; st.shadow = Shadows.body
        body.style = st
        body.html = html
        addSubview(body)
        if showBevel { addSubview(bevel) }
        if active || highlight {
            // .listing.active: cyan ring with a purple glow
            layer.shadowColor = UIColor(red: 0, green: 252 / 255, blue: 1, alpha: 1).cgColor
            layer.shadowOpacity = 1; layer.shadowRadius = px(2); layer.shadowOffset = .zero
        }
        if dim { alpha = 0.5 }
    }
    required init?(coder: NSCoder) { fatalError() }
    func height(_ w: Double) -> Double { max(56, body.fittingHeight(w - padLeft - 6) + 12) }
    override func layoutSubviews() {
        super.layoutSubviews()
        let w = Double(bounds.width / K), h = Double(bounds.height / K)
        tint.frame = bounds; bevel.frame = bounds
        if let p = leftPic { p.frame = CGRect(x: 0, y: px((h - 48) / 2), width: px(48), height: px(48)) }
        let bh = body.fittingHeight(w - padLeft - 6)
        body.frame = CGRect(x: px(padLeft), y: px((h - bh) / 2), width: px(w - padLeft - 6), height: px(bh))
    }
}

extension PopupContent {
    func listing(_ b: ListingButton) { add(b) { w in b.height(w) } }
    /// <div style="text-align:center;padding:4px;font-size:80%;">…</div>
    func note(_ s: String) { html("<div style=\"text-align:center;padding:4px;font-size:80%;\">\(s)</div>") }
}

// MARK: - the screen

final class SpecialScreen: GameScreen {
    private var panel: SectionPanel?
    private var blocks: [(UIView, (Double) -> Double, () -> Bool)] = []
    private var updaters: [() -> Void] = []
    private var lastTick = 0.0

    init() { super.init(name: "special") }

    override func build() {
        blocks = []; updaters = []
        let p = SectionPanel(in: view)
        panel = p
        let W = p.width
        let c = p.scroll.content
        // header
        let header = PinHeader("Special")
        c.addSubview(header)
        blocks.append((header, { _ in 45 - 12 + 2 }, { true }))

        buildLegacy(c)
        if G.Has("Bingo center/Research facility") { buildResearch(c) }
        buildGrandmapocalypse(c)
        buildGoldenSwitch(c)
        buildSeason(c)
        buildPets(c)
        buildQuickButtons(c)
        buildCustomization(c)
        _ = W
        layout()
        p.scroll.bringSubviewToFront(c)
        view.bringSubviewToFront(p.trimTop); view.bringSubviewToFront(p.trimBottom)
    }
    override func clean() { blocks = []; updaters = []; panel = nil }

    private func layout() {
        guard let p = panel else { return }
        let W = p.width
        var y = 8.0
        for (v, h, show) in blocks {
            let visible = show()
            v.isHidden = !visible
            if !visible { continue }
            if let ph = v as? PinHeader {
                let w = ph.cssWidth
                ph.frame = CGRect(x: px(8 + (W - w) / 2), y: px(y + 2), width: px(w), height: px(45))
                y += 45 + 2 - 12
                continue
            }
            let hh = h(W)
            if v.tag == 50 {
                // inline-block pets row: boxes are already placed inside
                v.frame = CGRect(x: px(8), y: px(y), width: px(W), height: px(hh))
            } else {
                v.frame = CGRect(x: px(8), y: px(y), width: px(W), height: px(hh))
            }
            v.setNeedsLayout()
            y += hh
        }
        p.scroll.setContentHeight(px(y + 8))
        // the pin header sits over the boxes
        if let h = blocks.first?.0 { p.scroll.content.bringSubviewToFront(h) }
    }

    override func draw() {
        if nowMs() - lastTick < 150 { return }
        lastTick = nowMs()
        updaters.forEach { $0() }
        layout()
    }

    // MARK: legacy
    private func buildLegacy(_ c: UIView) {
        let box = BumpyBox()
        box.sliverHeader("Legacy", icon: [19, 7])
        let info = RichLabel(TextStyle.base(11)); info.style.align = .center; info.style.shadow = Shadows.body
        box.addSubview(info)
        var prevChips = 0.0, prevChipsTime = 0.0
        func infoHTML() -> String {
            let chipsOwned = G.HowMuchPrestige(G.cookiesReset)
            let rawAscendNowToOwn = G.HowMuchPrestige(G.cookiesReset + G.cookiesEarned)
            let ascendNowToOwn = rawAscendNowToOwn.rounded(.down)
            let cookiesToNext = G.HowManyCookiesReset(ascendNowToOwn + 1) - (G.cookiesEarned + G.cookiesReset)
            _ = chipsOwned
            var next = "<b>\(B(max(cookiesToNext, 0), 0))</b> more <span class=\"tinyCookie\"></span>cookies needed for next level"
            if prevChipsTime != 0 {
                let elapsed = (nowMs() - prevChipsTime) / 1000
                let dif = (rawAscendNowToOwn - prevChips) / elapsed
                if dif >= 1.5 { next = "Earning <b>\(B(dif, 1))</b> levels per second" }
            }
            if !next.hasPrefix("Earning") { prevChips = rawAscendNowToOwn; prevChipsTime = nowMs() }
            return "Prestige level: <b style=\"color:#90f;\">\(B(G.prestige, 0, 2))</b><span style=\"font-size:85%;\"> at <b>\(B(G.GetHeavenlyMultiplier() * 100, 1))%</b> of its potential</span><br><span style=\"font-size:85%;\">(CpS boost: <b>+\(B(G.prestige * G.GetHeavenlyMultiplier(), 1))%</b>)</span><br>\(next)<br>"
        }
        info.html = infoHTML()
        // Ascend / View prestige
        let ascend = StarButton(html: "<div class=\"fancy\" style=\"font-size:11px;font-weight:bold;\">Ascend</div>", glow: true, bgOffsetY: -10)
        let grant = RichLabel(TextStyle.base(9, color: UIColor(white: 1, alpha: 0.75)))
        grant.style.align = .center; grant.style.shadow = Shadows.body; grant.style.bold = true
        ascend.addSubview(grant)
        func grantHTML() -> String {
            let chipsOwned = G.HowMuchPrestige(G.cookiesReset)
            let get = G.HowMuchPrestige(G.cookiesReset + G.cookiesEarned).rounded(.down) - chipsOwned.rounded(.down)
            return "will grant you <span style=\"color:#cff;\">\(get > 0 ? B(get, 0, 2) : "no")</span> prestige"
        }
        grant.html = grantHTML()
        ascend.onTap = { _ in SpecialScreen.ascendPopup() }
        let view = StarButton(html: "<div class=\"fancy\" style=\"font-size:11px;font-weight:bold;\">View<br>prestige</div>", glow: false, bgOffsetY: 0)
        view.onTap = { _ in G.showAscend(2) }
        box.addSubview(ascend); box.addSubview(view)
        // legacy off
        let off = BumpyBox()
        off.sliverHeader("Legacy", icon: [19, 7])
        let offText = RichLabel(TextStyle.base(11)); offText.style.textIndent = 64; offText.style.shadow = Shadows.body; offText.style.align = .center
        off.addSubview(offText)
        func offHTML() -> String { "This feature becomes available once you've baked <b><span class=\"tinyCookie\"></span>1 trillion cookies</b> in total.<br>(<b><span class=\"tinyCookie\"></span>\(B(1e12 - G.cookiesEarned, 0, 1))</b> more needed)" }
        offText.html = offHTML()
        updaters.append {
            let s = infoHTML(); if s != info.html { info.html = s }
            let g = grantHTML(); if g != grant.html { grant.html = g }
            let o = offHTML(); if o != offText.html { offText.html = o }
        }
        c.addSubview(box); c.addSubview(off)
        blocks.append((box, { w in
            let ih = info.fittingHeight(w - 16)
            info.frame = CGRect(x: px(8), y: px(20), width: px(w - 16), height: px(ih))
            let by = 20 + ih + 8
            let row = CGRect(x: 0, y: by, width: w, height: 48)
            ascend.frame = CGRect(x: px(row.minX + 2), y: px(row.minY + 2), width: px(w * 0.67 - 4), height: px(44))
            grant.frame = CGRect(x: 0, y: px(18 + 4 - 2), width: ascend.bounds.width, height: px(12))
            view.frame = CGRect(x: px(w * 0.66 + 2), y: px(row.minY + 2), width: px(w * 0.34 - 4), height: px(44))
            return by + 48
        }, { G.resets > 0 || G.cookiesEarned >= 1e12 }))
        blocks.append((off, { w in
            let h = offText.fittingHeight(w - 16)
            offText.frame = CGRect(x: px(8), y: px(8), width: px(w - 16), height: px(h))
            return h + 16
        }, { G.resets == 0 && G.cookiesEarned < 1e12 }))
    }

    static func ascendPopup() {
        let chipsOwned = G.HowMuchPrestige(G.cookiesReset)
        let get = G.HowMuchPrestige(G.cookiesReset + G.cookiesEarned).rounded(.down) - chipsOwned.rounded(.down)
        Popup.open(PopupOptions(build: { c in
            c.h3("<span class=\"tinyIcon\" style=\"background-position:\(-19 * 48)px \(-7 * 48)px;\"></span> Ascend")
            c.html("<p>Do you <b>REALLY</b> want to ascend?</p><p style=\"font-size:80%;\">You will lose your progress and start over from scratch.</p><p style=\"font-size:80%;\">All your cookies will be converted into <b>prestige</b>, which permanently improves your CpS, and <b>heavenly chips</b>, which let you purchase special permanent upgrades.</p><p style=\"font-size:80%;\">You will keep your achievements.</p><p>Ascending now will grant you <b style=\"color:#90f;\">\(get > 0 ? B(get, 0, 1) : "no") heavenly chip\(get == 1 ? "" : "s")</b> \(get > 0 ? "and just as much prestige" : "or prestige").</p>")
            c.line()
            let b = BigPictureButton(text: "Ascend!", pics: ["img/starbg.jpg"], glow: UIColor(css: "#90f"))
            b.onTap = { _ in Popup.close(); G.explodeThenAscend() }
            c.add(b, height: 56, marginTop: 8, marginBottom: 8)
        }, close: "Cancel"))
    }

    // MARK: research
    private func buildResearch(_ c: UIView) {
        let box = ListingButton(html: "", color: nil)
        box.backgroundColor = .clear
        let bar = PicView("img/researchBar.jpg"); bar.contentMode = .scaleAspectFill; bar.clipsToBounds = true
        box.insertSubview(bar, at: 0)
        let hdr = BumpyBox(); hdr.isUserInteractionEnabled = false; hdr.bevel.isHidden = true; hdr.backgroundColor = .clear
        hdr.sliverHeader("Bingo center/Research facility", icon: [11, 9])
        box.addSubview(hdr)
        let foot = RichLabel(TextStyle.base(8.8)); foot.style.bold = true; foot.style.align = .center; foot.style.shadow = Shadows.body
        box.addSubview(foot)
        func update() {
            let pool = G.upgradePools["science"] ?? []
            if pool.allSatisfy({ $0.owned != 0 }) {
                box.body.html = "<div style=\"padding:20px 8px 12px 8px;\"><span class=\"tinyIcon\" style=\"background-position:\(-9 * 48)px \(-14 * 48)px;\"></span> You've researched everything.</div>"
                foot.html = ""; bar.isHidden = true; return
            }
            if let r = G.researchUpgrade {
                let ic = r.iconFunc?() ?? r.icon
                box.body.html = "<div style=\"padding:16px 8px;\">Current research:<br><span class=\"tinyIcon\" style=\"background-position:\(-ic[0] * 48)px \(-ic[1] * 48)px;\"></span><b>\(r.name)</b></div>"
                let left = G.researchT - nowMs() + G.researchTM
                foot.html = left > 0 ? "Time left: \(sayTime(left + 1000))" : "<span style=\"color:#fff;\">Research complete. Tap to see!</span>"
                bar.isHidden = false
            } else {
                box.body.html = "<div style=\"padding:16px 8px;\">Current research:<br><b>None</b></div>"
                foot.html = "Tap to set research."
                bar.isHidden = true
            }
        }
        update()
        updaters.append(update)
        box.onTap = { _ in ResearchUI.popup() }
        c.addSubview(box)
        blocks.append((box, { w in
            let h = box.body.fittingHeight(w - 12) + 16
            bar.frame = CGRect(x: px(2), y: px(2), width: px(w - 4), height: px(h - 4))
            hdr.frame = CGRect(x: 0, y: 0, width: px(w), height: px(30))
            foot.frame = CGRect(x: 0, y: px(h - 4 - 10), width: px(w), height: px(11))
            return h
        }, { true }))
    }

    // MARK: grandmapocalypse / golden switch / season (a bumpy box with toggle buttons on the right)
    private func statusBox(_ c: UIView, title: String, icon: [Int], toggles: [(String, String, () -> Bool, (() -> Void)?)], text: @escaping () -> String, show: @escaping () -> Bool, noHeaderSpace: @escaping () -> Bool = { false }) {
        let box = BumpyBox()
        box.sliverHeader(title, icon: icon)
        let l = RichLabel(TextStyle.base(11)); l.style.align = .center; l.style.shadow = Shadows.body
        box.addSubview(l)
        l.html = text()
        var buttons: [(SquareButton, () -> Bool)] = []
        for (what, label, cond, custom) in toggles {
            guard let me = G.upgradesBN[what] else { continue }
            let b = SquareButton(icon: me.iconFunc?() ?? me.icon, text: label)
            b.onTap = { _ in if let cc = custom { cc() } else { UpgradeUI.showInfo(me) } }
            box.addSubview(b)
            buttons.append((b, cond))
        }
        updaters.append { let s = text(); if s != l.html { l.html = s } }
        c.addSubview(box)
        blocks.append((box, { w in
            // float:right buttons (margin 2px), text next to them
            var x = w - 8
            var any = false
            for (b, cond) in buttons.reversed() {
                b.isHidden = !cond()
                if b.isHidden { continue }
                any = true
                x -= 50
                b.frame = CGRect(x: px(x + 1), y: px(4 + 2), width: px(48), height: px(48))
            }
            let textW = (any ? x : w - 8) - 8
            let top = noHeaderSpace() ? 4.0 : 24
            let th = l.fittingHeight(textW)
            l.frame = CGRect(x: px(8), y: px(top), width: px(textW), height: px(th))
            return max(any ? 4 + 52 + 4 : 0, top + th + 4)
        }, show))
    }
    private func buildGrandmapocalypse(_ c: UIView) {
        statusBox(c, title: "Grandmapocalypse", icon: [10, 9], toggles: [
            ("Elder Covenant", "Covenant", { G.isUnlocked("Elder Covenant") }, nil),
            ("Revoke Elder Covenant", "Revoke<br>Covenant", { G.isUnlocked("Revoke Elder Covenant") }, nil),
            ("Elder Pledge", "Pledge", { G.Has("Elder Pact") && !G.Has("Elder Covenant") && G.isUnlocked("Elder Pledge") && G.pledgeT <= nowMs() }, nil),
        ], text: {
            var s = "elderly"
            if G.elderWrath == 1 { s = "awoken" } else if G.elderWrath == 2 { s = "displeased" } else if G.elderWrath == 3 { s = "angered" }
            else if G.elderWrath == 0 && G.pledges > 0 { s = "appeased" }
            if G.elderWrath > 0 { s = "<span class=\"warning\">\(s)</span>" }
            let pledge = G.pledgeT > nowMs() ? "<br>Pledge duration left: <b>\(sayTime(G.pledgeT - nowMs() + 1000))</b>" : ""
            return "Grandmatriarchs status: <b>\(s)</b>\(pledge)"
        }, show: { G.elderWrath > 0 || G.pledges > 0 || G.Has("Elder Covenant") })
    }
    private func buildGoldenSwitch(_ c: UIView) {
        statusBox(c, title: "Golden switch", icon: [21, 10], toggles: [
            ("Golden switch [on]", "Turn off!", { G.isUnlocked("Golden switch [on]") }, nil),
            ("Golden switch [off]", "Turn on!", { G.isUnlocked("Golden switch [off]") }, nil),
        ], text: {
            let eff = (G.upgradesBN["Golden switch [off]"]?.getComputedEff("cpsM", 1) ?? 1) - 1
            return "\(G.Has("Golden switch [off]") ? "Active." : "Inactive.")<br>Grants <b>+\(B(eff * 100, 1))% CpS when active.</b>"
        }, show: { G.Has("Golden switch") })
    }
    private func buildSeason(_ c: UIView) {
        statusBox(c, title: "Season", icon: [16, 6], toggles: [
            ("Season switcher", "Switch!", { G.Has("Season switcher") }, { PetsUI.seasonSwitcherPopup() }),
        ], text: {
            var s = "No seasonal event."
            if G.season != "", let se = G.seasons[G.season] {
                let ic = se.triggerUpgrade.icon
                s = "<span class=\"tinyIcon\" style=\"background-position:\(-ic[0] * 48)px \(-ic[1] * 48)px;\"></span> It's <b>\(se.name)</b>!"
            }
            if G.season != G.baseSeason && G.seasonT > nowMs() { s += "<br><span style=\"font-size:85%;\">Time left: <b>\(sayTime(G.seasonT - nowMs() + 1000))</b></span>" }
            return s
        }, show: { true }, noHeaderSpace: { !G.Has("Season switcher") && G.season == "" })
    }

    // MARK: pets
    private func buildPets(_ c: UIView) {
        var pets: [(String, [Int], () -> (String, Int), () -> String, () -> Void)] = []
        if G.Has("A festive hat") { pets.append(("img/santa.png", [19, 9], { ("img/santa.png", G.santaLevel) }, { Game.santaLevels[G.santaLevel] }, { PetsUI.santaPopup() })) }
        if G.Has("A crumbly egg") { pets.append(("img/dragon.png", [21, 12], { ("img/dragon.png", G.dragonLevels[G.dragonLevel].pic) }, { G.dragonLevels[G.dragonLevel].name }, { PetsUI.dragonPopup() })) }
        if pets.isEmpty { return }
        let row = UIView()
        row.tag = 50
        var boxes: [BumpyBox] = []
        for (i, p) in pets.enumerated() {
            let box = BumpyBox()
            box.sliverHeader("", icon: p.1)
            let btn = SquareButton(icon: nil)
            let wiggle = G.getSet("fancy") != 0 && G.getSet("lowMotion") == 0
            let (sheet, f) = p.2()
            let pic = PetPic(sheet: sheet, frame: f, wiggle: wiggle, delay: i == 1 ? 0.667 : 0)
            pic.frame = CGRect(x: 0, y: px(1), width: px(48), height: px(48))
            btn.addSubview(pic)
            btn.onTap = { _ in p.4() }
            box.addSubview(btn)
            var st = TextStyle(); st.family = .georgia; st.bold = true; st.size = 10; st.smallCaps = true; st.shadow = Shadows.print; st.color = .ccText
            let name = RichLabel(st)
            name.html = p.3()
            box.addSubview(name)
            updaters.append {
                let (s, f) = p.2(); pic.setFrame(s, f)
                let n = p.3(); if n != name.html { name.html = n }
            }
            row.addSubview(box)
            boxes.append(box)
            box.tag = 0
            // layout inside the 50%-wide box
            box.frame = CGRect(x: 0, y: 0, width: px(152), height: px(60))
            btn.frame = CGRect(x: px(152 - 8 - 48 - 2), y: px(4 + 2), width: px(48), height: px(48))
            name.frame = CGRect(x: px(4), y: px(60 - 4 - 11), width: px(96), height: px(12))
        }
        c.addSubview(row)
        blocks.append((row, { w in
            let bw = w * 0.5
            let total = bw * Double(boxes.count)
            var x = (w - total) / 2
            for b in boxes {
                b.frame = CGRect(x: px(x), y: 0, width: px(bw), height: px(60))
                if let btn = b.subviews.first(where: { $0 is SquareButton }) { btn.frame = CGRect(x: px(bw - 8 - 48 - 2), y: px(6), width: px(48), height: px(48)) }
                x += bw
            }
            return 60
        }, { true }))
    }

    // MARK: quick buttons
    private func buildQuickButtons(_ c: UIView) {
        let box = BumpyBox()
        box.sliverHeader("Set quick buttons...")
        let note = RichLabel(TextStyle.base(8.8)); note.style.shadow = Shadows.body; note.alpha = 0.75; note.style.align = .right
        note.html = "Action shortcuts on the cookie screen."
        box.addSubview(note)
        let area = UIView()
        box.addSubview(area)
        var previews: [QuickButtonPreview] = []
        for i in 0..<G.quickButtons.count {
            let pv = QuickButtonPreview(index: i)
            area.addSubview(pv)
            previews.append(pv)
            pv.onTap = { [weak pv] _ in SpecialScreen.quickButtonPicker(i) { pv?.update(); if let p = pv { Anim.trigger(p, "plopHalf") } } }
        }
        updaters.append { previews.forEach { $0.update() } }
        c.addSubview(box)
        blocks.append((box, { w in
            note.frame = CGRect(x: px(w / 2), y: px(4), width: px(w / 2 - 8), height: px(10))
            area.frame = CGRect(x: px(8), y: px(4 + 20), width: px(w - 16), height: px(110))
            for (i, pv) in previews.enumerated() {
                let pos = Game.quickButtonsPos[i]
                pv.center = CGPoint(x: px(w - 16 - pos[0] - 24), y: px(110 - pos[1] - 24))
            }
            return 4 + 20 + 110 + 4
        }, { Game.quickButtonOptions.contains { $0.id != "none" && G.quickButtonCond($0.id) } }))
    }
    static func quickButtonPicker(_ n: Int, done: @escaping () -> Void) {
        Popup.open(PopupOptions(build: { c in
            c.h3("Set quick button #\(n + 1)")
            for me in Game.quickButtonOptions where G.quickButtonCond(me.id) {
                let active = G.quickButtons[n] == me.id
                var hidden = 0
                if me.id != "none" && !active, let idx = G.quickButtons.firstIndex(of: me.id) { hidden = idx + 1 }
                let col = active ? (167, 10, 249) : hidden > 0 ? (100, 100, 100) : (176, 109, 73)
                let b = ListingButton(html: "<div class=\"fancy\" style=\"font-size:13px;\">\(me.name)</div>" + (hidden > 0 ? "<div style=\"font-size:10px;\">(in quick button #\(hidden))</div>" : ""), icon: me.icon, color: col, active: active, dim: hidden > 0)
                if hidden == 0 {
                    b.onTap = { _ in
                        if G.quickButtons[n] == me.id { return }
                        G.quickButtons[n] = me.id
                        PlaySound("snd/tick.mp3", 0.5)
                        Popup.close()
                        done()
                    }
                } else { b.isUserInteractionEnabled = false }
                c.listing(b)
                if active { c.scrollTarget = b }
            }
        }, close: "Cancel"))
    }

    // MARK: customisation
    private func buildCustomization(_ c: UIView) {
        let box = BumpyBox()
        box.sliverHeader("Customize...")
        let milkB = SquareButton(icon: [1, 8])
        milkB.onTap = { _ in SpecialScreen.milkPicker() }
        let bgB = SquareButton(icon: [29, 5])
        bgB.onTap = { _ in SpecialScreen.bgPicker() }
        box.addSubview(milkB); box.addSubview(bgB)
        c.addSubview(box)
        blocks.append((box, { w in
            let shown = [(milkB, G.Has("Classic dairy selection")), (bgB, G.Has("Basic wallpaper assortment"))].filter { $0.1 }
            milkB.isHidden = !G.Has("Classic dairy selection"); bgB.isHidden = !G.Has("Basic wallpaper assortment")
            let total = Double(shown.count) * 52
            var x = (w - total) / 2
            for (b, _) in shown { b.frame = CGRect(x: px(x + 2), y: px(4 + 20), width: px(48), height: px(48)); x += 52 }
            return 4 + 20 + 52 + 4
        }, { G.Has("Classic dairy selection") }))
    }
    static func milkPicker() {
        var choices: [(id: Int, name: String, icon: [Int], order: Double, div: Bool)] = []
        let maxRank = G.achievsN / 25
        for (i, it) in G.AllMilks.enumerated() {
            if it.type == 1 && !G.Has("Fanciful dairy selection") { continue }
            if it.rank > 0 && it.rank > maxRank { continue }
            choices.append((i, it.name, it.icon, Double(it.type), i == 11))
        }
        PickerPopup.open(title: "Milk selector", choices: choices, selected: G.milkType) { G.milkType = $0 }
    }
    static func bgPicker() {
        var choices: [(id: Int, name: String, icon: [Int], order: Double, div: Bool)] = []
        for (i, it) in Game.AllBGs.enumerated() {
            let order = it.order ?? Double(i)
            if order >= 4.9 && !G.Has("Distinguished wallpaper assortment") { continue }
            choices.append((i, it.name, it.icon, order, i == 13))
        }
        PickerPopup.open(title: "Background selector", choices: choices, selected: G.bgType) { G.bgType = $0; G.updateBG(true) }
    }
}

/// a Legacy button on a starry background (Ascend / View prestige)
final class StarButton: TapView {
    private let bg = UIView()
    private let stars: PatternView
    private let bevel = BevelView(.bump)
    private let label = RichLabel()
    private let glowRing = UIView()
    init(html: String, glow: Bool, bgOffsetY: Double) {
        stars = PatternView("img/starbg.jpg")
        super.init(frame: .zero)
        brightensWhenPressed = true
        layer.cornerRadius = px(4)
        bg.clipsToBounds = true
        bg.layer.cornerRadius = px(4)
        stars.offset = CGPoint(x: 0, y: bgOffsetY)
        bg.addSubview(stars)
        addSubview(bg)
        addSubview(bevel)
        if glow {
            // box-shadow:0 0 4px 2px #90f
            glowRing.isUserInteractionEnabled = false
            glowRing.layer.borderColor = UIColor(css: "#90f").cgColor
            glowRing.layer.borderWidth = px(2)
            glowRing.layer.cornerRadius = px(4)
            glowRing.layer.shadowColor = UIColor(css: "#90f").cgColor
            glowRing.layer.shadowOpacity = 1; glowRing.layer.shadowRadius = px(2); glowRing.layer.shadowOffset = .zero
            addSubview(glowRing)
        }
        var st = TextStyle.base(11, color: .ccText); st.align = .center; st.shadow = Shadows.body
        label.style = st
        label.html = html
        addSubview(label)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        bg.frame = bounds; stars.frame = bg.bounds; bevel.frame = bounds
        glowRing.frame = bounds.insetBy(dx: -px(1), dy: -px(1))
        label.frame = CGRect(x: 0, y: px(10 + 4 - 2), width: bounds.width, height: px(label.fittingHeight(Double(bounds.width / K))))
        for v in subviews where v is RichLabel { bringSubviewToFront(v) }
    }
}

/// .fullButton with a picture background (Ascend! / Reincarnate!), squishing
final class BigPictureButton: TapView {
    init(text: String, pics: [String], glow: UIColor) {
        super.init(frame: .zero)
        brightensWhenPressed = true
        layer.cornerRadius = px(8)
        clipsToBounds = false
        let clip = UIView(); clip.clipsToBounds = true; clip.layer.cornerRadius = px(8); clip.tag = 1
        for p in pics.reversed() {
            if p.contains("perfectCookie") {
                let v = PicView(p); v.contentMode = .scaleAspectFit; v.tag = 2; clip.addSubview(v)
            } else { let v = PatternView(p); v.tag = 3; clip.addSubview(v) }
        }
        addSubview(clip)
        layer.shadowColor = glow.cgColor; layer.shadowOpacity = 1; layer.shadowRadius = px(3); layer.shadowOffset = .zero
        var st = TextStyle.fancy(16, color: .ccText); st.bold = true; st.align = .center; st.shadow = Shadows.body; st.nowrap = true
        let l = RichLabel(st); l.html = text; l.tag = 4
        addSubview(l)
        Anim.squish(l, on: true)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        if let c = viewWithTag(1) {
            c.frame = bounds
            for v in c.subviews {
                if v.tag == 2 { let s = bounds.width * 0.5; v.frame = CGRect(x: (bounds.width - s) / 2, y: (bounds.height - s) / 2, width: s, height: s) }
                else { v.frame = bounds }
            }
        }
        viewWithTag(4)?.frame = CGRect(x: 0, y: px(20), width: bounds.width, height: px(18))
    }
}

/// a quick button slot in the special screen
final class QuickButtonPreview: TapView {
    let index: Int
    private let slot = UIImageView()
    private let icon = IconView()
    private let text = RichLabel()
    init(index: Int) {
        self.index = index
        super.init(frame: CGRect(x: 0, y: 0, width: px(48), height: px(48)))
        addSubview(icon)
        slot.frame = CGRect(x: -px(20), y: -px(20), width: px(88), height: px(88))
        slot.image = Res.sprite("img/ascendSlot.png", x: 88, y: 0, w: 88, h: 88)
        addSubview(slot)
        var st = TextStyle.fancy(15, color: UIColor(css: "#fcc")); st.align = .center; st.shadow = Shadows.top
        text.style = st
        text.frame = CGRect(x: px(24 - 75), y: 0, width: px(150), height: px(36))
        addSubview(text)
        transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        update()
    }
    required init?(coder: NSCoder) { fatalError() }
    func update() {
        let id = G.quickButtons[index]
        guard let me = Game.quickButtonOptions.first(where: { $0.id == id }) else { return }
        icon.icon = me.icon
        let t = me.id == "none" ? "" : me.name
        if text.html != t { text.html = t }
    }
}

/// PickerPopup: a grid of icons with the picked one's name, over the milk and background it would give
enum PickerPopup {
    static func open(title: String, choices cIn: [(id: Int, name: String, icon: [Int], order: Double, div: Bool)], selected: Int, pick: @escaping (Int) -> Void) {
        let choices = cIn.sorted { $0.order < $1.order }
        var o = PopupOptions(build: { c in
            c.h3(title)
            let nameBox = UIView()
            nameBox.backgroundColor = UIColor(white: 0, alpha: 0.5)
            nameBox.layer.cornerRadius = px(3)
            var st = TextStyle(); st.family = .georgia; st.bold = true; st.align = .center; st.color = .ccText; st.nowrap = true
            let nameL = RichLabel(st)
            nameBox.addSubview(nameL)
            let nameRow = UIView(); nameRow.addSubview(nameBox)
            var current = selected
            func setName() {
                let n = choices.first(where: { $0.id == current })?.name ?? "-"
                nameL.html = n
                let w = Double(RichText.size(RichText.render(n, style: st, width: nil), width: nil).width) + 16
                nameBox.frame = CGRect(x: (nameRow.bounds.width - px(w)) / 2, y: 0, width: px(w), height: px(15))
                nameL.frame = nameBox.bounds
            }
            c.add(nameRow) { w in DispatchQueue.main.async { setName() }; return 15 }
            c.line()
            let grid = UIView()
            var icons: [(Int, TapView, IconView)] = []
            for ch in choices {
                let t = TapView(frame: CGRect(x: 0, y: 0, width: px(48), height: px(48)))
                let iv = IconView(ch.icon)
                t.addSubview(iv)
                grid.addSubview(t)
                icons.append((ch.id, t, iv))
            }
            func highlight() {
                for (id, t, _) in icons {
                    t.layer.shadowColor = UIColor.white.cgColor
                    t.layer.shadowOpacity = id == current ? 1 : 0
                    t.layer.shadowRadius = px(3); t.layer.shadowOffset = .zero
                }
            }
            for (id, t, _) in icons {
                t.onTap = { v in
                    pick(id); current = id; setName(); highlight()
                    Anim.trigger(v, "plop")
                    PlaySound("snd/tick.mp3", 1)
                    c.popup?.updatePickerBack()
                }
            }
            highlight()
            c.add(grid) { w in
                var x = 0.0, y = 0.0
                var lines: [[(Int, TapView)]] = [[]]
                for (i, ch) in choices.enumerated() {
                    if ch.div && i > 0 { lines.append([]) }
                    if x + 48 > w { lines.append([]); x = 0 }
                    lines[lines.count - 1].append((ch.id, icons[i].1))
                    x = Double(lines[lines.count - 1].count) * 48
                }
                y = 0
                for line in lines where !line.isEmpty {
                    let total = Double(line.count) * 48
                    var lx = (w - total) / 2
                    for (_, t) in line { t.frame = CGRect(x: px(lx), y: px(y), width: px(48), height: px(48)); lx += 48 }
                    y += 48 + 13
                }
                return y
            }
        }, close: "Close")
        o.background = nil
        let p = Popup.open(o)
        p?.isPicker = true
        p?.updatePickerBack()
    }
}

extension PopupView {
    private static var pickerKey = 0
    var isPicker: Bool {
        get { objc_getAssociatedObject(self, &PopupView.pickerKey) as? Bool ?? false }
        set { objc_setAssociatedObject(self, &PopupView.pickerKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    /// the picker shows the chosen background and milk behind it
    func updatePickerBack() {
        var bgPic = "bgBlue"
        if G.bgType != 0 { bgPic = Game.AllBGs[G.bgType].pic }
        bg.path = "img/\(bgPic).jpg"
        bg.tileSize = nil
        let milkTag = 77
        let milk = (viewWithTag(milkTag) as? PatternView) ?? {
            let m = PatternView("img/milkPlain.png"); m.tag = milkTag; insertSubview(m, aboveSubview: bg); return m
        }()
        milk.path = "img/\(G.milkPic).png"
        milk.frame = CGRect(x: 0, y: bounds.height - px(240), width: bounds.width, height: px(240))
        milk.offset = CGPoint(x: Double((bounds.width / K - 240) / 2), y: 0)
    }
}

// MARK: - research popup

enum ResearchUI {
    static func popup() {
        Popup.open(PopupOptions(build: { c in
            let pool = G.upgradePools["science"] ?? []
            var list = pool.filter { $0.unlocked != 0 && $0.owned == 0 && G.researchUpgrade !== $0 }
            let owned = pool.filter { $0.owned != 0 }
            list.sort { $0.getCost() < $1.getCost() }
            func render(_ me: Upgrade) {
                let icon = me.iconFunc?() ?? me.icon
                var col = (255, 255, 255)
                var detail = ""
                if me === G.researchUpgrade {
                    let left = G.researchT - nowMs() + G.researchTM
                    detail = left > 0 ? "Time left: " + sayTime(left + 1000) : "<span style=\"color:#fff;\">Research complete. Tap to unlock!</span>"
                } else if me.owned == 0 {
                    col = (167, 10, 249)
                    let cost = me.getCost()
                    detail = "Research cost: <span class=\"cost\(cost > G.cookies ? " cantAfford" : "")\">\(B(cost))</span><br>Research time: \(sayTime(G.researchTime))"
                } else { col = (176, 109, 73) }
                let html = "<div class=\"fancy\" style=\"font-size:13px;\">\(me.name)</div><div style=\"padding:4px;\">\(me.descFunc?(me) ?? me.desc)</div>" + (detail.isEmpty ? "" : "<line></line><div style=\"text-align:center;padding:2px;font-weight:bold;font-size:80%;\">\(detail)</div>")
                let b = ListingButton(html: html, icon: icon, color: col, highlight: me.unlocked != 0 && me.owned == 0)
                b.onTap = { _ in
                    if G.researchUpgrade == nil && me.unlocked != 0 && me.owned == 0 {
                        if G.startResearch(me) { Popup.close(); popup() }
                    } else if G.researchUpgrade === me {
                        if G.finishResearch(me) { Popup.close(); popup() }
                    } else if me.owned != 0 { UpgradeUI.showInfo(me) }
                }
                c.listing(b)
            }
            c.h3("<span class=\"tinyIcon\" style=\"background-position:\(-11 * 48)px \(-9 * 48)px;\"></span> Bingo center/Research facility")
            c.note("Research technologies to boost your cookie production.")
            c.line()
            c.html("<div style=\"text-align:center;padding:4px;font-variant:small-caps;\">Current research:\(G.researchUpgrade == nil ? " <b>None</b>" : "")</div>")
            if let r = G.researchUpgrade { render(r) }
            c.line()
            c.html("<div style=\"text-align:center;padding:4px;font-variant:small-caps;\">Available to research:\(list.isEmpty ? " <b>None</b>" : "")</div>")
            for me in list { render(me) }
            if owned.count == pool.count { c.note("<span class=\"tinyIcon\" style=\"background-position:\(-9 * 48)px \(-14 * 48)px;\"></span> You've researched everything.") }
            c.line()
            c.html("<div style=\"text-align:center;padding:4px;font-variant:small-caps;\">Completed research:\(owned.isEmpty ? " <b>None</b>" : "")</div>")
            for me in owned { render(me) }
        }, close: "Close"))
    }
}

// MARK: - pets and seasons popups

enum PetsUI {
    static func santaPopup(_ justUpgraded: Bool = false) {
        Popup.open(PopupOptions(build: { c in
            c.h3("<span class=\"tinyIcon\" style=\"background-position:\(-19 * 48)px \(-9 * 48)px;\"></span> \(Game.santaLevels[G.santaLevel])")
            if G.santaLevel == Game.santaLevels.count - 1 { c.note("Fully evolved."); c.line() }
            let moni = G.SantaUpgradeCost()
            for i in stride(from: G.santaLevel, through: 0, by: -1) {
                let active = i == G.santaLevel
                var html = "<div class=\"printText\" style=\"font-size:13px;\">\(Game.santaLevels[i])</div>"
                if active && G.santaLevel < Game.santaLevels.count - 1 {
                    html += "<div style=\"font-weight:bold;padding:4px;\">Evolve!</div><div style=\"text-align:center;padding:2px;font-weight:bold;font-size:80%;\">Sacrifice <span class=\"cost\(G.cookies < moni ? " cantAfford" : "")\">\(B(moni)) cookie\(moni == 1 ? "" : "s")</span></div>"
                }
                let b = ListingButton(html: html, pet: ("img/santa.png", i), color: nil, active: active, bevel: active)
                if active {
                    b.onTap = { _ in if G.UpgradeSanta() { Popup.close(); santaPopup(true) } }
                    c.scrollTarget = b
                    if justUpgraded { DispatchQueue.main.async { Anim.switchAnim(b, "switchLeftIn") } }
                } else { b.isUserInteractionEnabled = false }
                c.listing(b)
            }
        }, close: "Close"))
    }

    static func dragonPopup(_ justUpgraded: Bool = false) {
        Popup.open(PopupOptions(build: { c in
            c.h3("<span class=\"tinyIcon\" style=\"background-position:\(-21 * 48)px \(-12 * 48)px;\"></span> \(G.dragonLevels[G.dragonLevel].name)")
            let last = G.dragonLevels.count - 1
            if G.dragonLevel >= 5 {
                c.html("<div style=\"text-align:center;padding:4px;font-size:80%;\"><b>Aura\(G.dragonLevel == last ? "s" : ""):</b></div>")
                var bs: [SquareButton] = []
                let a0 = SquareButton(icon: G.dragonAuras[G.dragonAura].pic); a0.onTap = { _ in selectDragonAura(0) }; bs.append(a0)
                if G.dragonLevel == last { let a1 = SquareButton(icon: G.dragonAuras[G.dragonAura2].pic); a1.onTap = { _ in selectDragonAura(1) }; bs.append(a1) }
                let row = UIView(); bs.forEach { row.addSubview($0) }
                c.add(row) { w in
                    var x = (w - Double(bs.count) * 52) / 2
                    for b in bs { b.frame = CGRect(x: px(x + 2), y: px(2), width: px(48), height: px(48)); x += 52 }
                    return 56
                }
                c.line()
            }
            let current = G.dragonLevels[G.dragonLevel]
            let main = [0, 4, 8, last - 2, last - 1, last]
            for i in stride(from: G.dragonLevel, through: 0, by: -1) {
                let active = i == G.dragonLevel
                let level = G.dragonLevels[i]
                if !active && (!main.contains(i) || current.pic == level.pic) { continue }
                var html = "<div class=\"printText\" style=\"font-size:13px;\">\(level.name)</div>"
                if active && G.dragonLevel < last {
                    let can = level.cost?() ?? false
                    html += "<line></line><div style=\"font-weight:bold;padding:4px;\">\(level.action)</div><line></line><div style=\"text-align:center;padding:2px;font-weight:bold;font-size:80%;\">Cost: sacrifice <span class=\"cost\(i > 4 ? " otherCost" : "")\(!can ? " cantAfford" : "")\">\(level.costStr?() ?? "")</span></div>"
                } else if i == last { html += "<div style=\"font-size:80%;padding:4px;\">Fully trained.</div>" }
                let b = ListingButton(html: html, pet: ("img/dragon.png", level.pic), color: nil, active: active, bevel: active)
                if active {
                    b.onTap = { _ in if G.UpgradeDragon() { Popup.close(); dragonPopup(true) } }
                    c.scrollTarget = b
                    if justUpgraded { DispatchQueue.main.async { Anim.switchAnim(b, "switchLeftIn") } }
                } else { b.isUserInteractionEnabled = false }
                c.listing(b)
            }
        }, close: "Close"))
    }

    static func selectDragonAura(_ slot: Int) {
        let currentAura = slot == 0 ? G.dragonAura : G.dragonAura2
        let otherAura = slot == 0 ? G.dragonAura2 : G.dragonAura
        let cur = G.dragonAuras[currentAura]
        let highest = G.buildings.last(where: { $0.amount > 0 })
        Popup.open(PopupOptions(build: { c in
            c.h3("<span class=\"tinyIcon\" style=\"background-position:\(-21 * 48)px \(-12 * 48)px;\"></span> Set your dragon's \(slot == 1 ? "secondary " : "")aura")
            c.note("Select an aura from those your dragon knows.<br><br>" + (highest == nil ? "Switching your aura is <b>free</b> because you own no buildings." : "The cost of switching your aura is <b class=\"cost otherCost\">1 \(highest!.single)</b>.<br><b class=\"warning\">This will affect your CpS!</b>"))
            c.note("<span style=\"margin-right:12px;\">Current:</span> <span class=\"tinyIcon\" style=\"background-position:\(-cur.pic[0] * 48)px \(-cur.pic[1] * 48)px;\"></span> <b>\(cur.name)</b>")
            c.line()
            for me in G.dragonAuras {
                if me.drop || G.dragonLevel < me.id + 4 || (me.id != 0 && me.id == otherAura) { continue }
                let active = currentAura == me.id
                let html = "<div class=\"fancy\" style=\"font-size:13px;\">\(me.name)</div>" + (me.desc.isEmpty ? "" : "<div style=\"padding:4px;\">\(me.desc)</div>")
                let b = ListingButton(html: html, icon: me.pic, color: active ? (167, 10, 249) : (176, 109, 73), active: active)
                b.onTap = { _ in
                    if currentAura == me.id { return }
                    if slot == 0 { G.dragonAura = me.id } else { G.dragonAura2 = me.id }
                    if let h = G.buildings.last(where: { $0.amount > 0 }) { h.sacrifice(1) }
                    G.refreshCps = true
                    PlaySound("snd/thud.mp3", 0.5)
                    PlaySound("snd/tick.mp3", 0.5)
                    Popup.close()
                }
                if active { c.scrollTarget = b }
                c.listing(b)
            }
        }, close: "Cancel"))
    }

    static func seasonSwitcherPopup() {
        Popup.open(PopupOptions(build: { c in
            c.h3("<span class=\"tinyIcon\" style=\"background-position:\(-16 * 48)px \(-6 * 48)px;\"></span> Season switcher")
            let uses = G.seasonUses
            c.note("Change seasons at any time... for a price!<br>Each triggered season lasts for 24 hours.<br>Cost scales with unbuffed CpS and increases with every season switch. " + (uses == 0 ? "You haven't switched seasons this ascension yet." : "You've switched seasons <b>\(uses == 1 ? "once" : uses == 2 ? "twice" : "\(uses) times")</b> this ascension.") + " Cancelling out of a season is free.")
            c.line()
            for se in G.seasonsList {
                let me = se.triggerUpgrade
                let icon = me.iconFunc?() ?? me.icon
                let active = G.seasonT > 0 && G.season != "" && G.seasons[G.season]?.trigger == me.name
                let b = ListingButton(html: "", icon: icon, color: active ? (167, 10, 249) : (176, 109, 73), active: active)
                func text() -> String {
                    let cost = me.getCost()
                    let detail = active ? "Active! Tap to cancel." : "Trigger for <span class=\"cost\(cost > G.cookies ? " cantAfford" : "")\">\(B(cost))</span>."
                    return "<div class=\"fancy\" style=\"font-size:13px;\">\(me.name)</div><div style=\"padding:4px;\">\(me.descFunc?(me) ?? me.desc)</div><div style=\"text-align:center;padding:2px;font-weight:bold;font-size:80%;\">\(detail)</div>"
                }
                b.body.html = text()
                c.every(0.15) { let t = text(); if t != b.body.html { b.body.html = t; return true }; return false }
                b.onTap = { _ in
                    if active {
                        G.switchSeason()
                        G.refreshCps = true
                        PlaySound("snd/thud.mp3", 0.5)
                        G.doUnlocks()
                        Popup.close(); seasonSwitcherPopup()
                    } else {
                        let cost = me.getCost()
                        if cost > G.cookies { return }
                        G.switchSeason()
                        G.switchSeason(se.key)
                        G.seasonUses += 1
                        G.spend(cost)
                        G.computeSeasonPrices()
                        G.refreshCps = true
                        PlaySound("snd/thud.mp3", 0.5)
                        G.doUnlocks()
                        Popup.close(); seasonSwitcherPopup()
                    }
                }
                if active { c.scrollTarget = b }
                c.listing(b)
            }
        }, close: "Close"))
    }
}
