import UIKit
import UniformTypeIdentifiers

// The misc screen (www/main.js "misc"): Orteil and his tips, settings, about, version history, wiping,
// exporting/importing the save, the iPhone extras, and the live/alpha switch.

/// Orteil in the corner with his speech bubble
final class OrteilView: TapView {
    private let shade = GradientView([.clear, UIColor(white: 0, alpha: 0.5)])
    private let line = UIView()
    private let bubble = UIImageView()
    private let bubbleText = RichLabel()
    private let bottomLayer = UIImageView()
    private let topLayer = UIImageView()
    private var shirt = 1
    private var talkFor = 0.0
    private var anim = 0, animT = 0.0, animTM = 0.0
    private var upgradeUnlockedByTip: Upgrade?
    private var timer: Timer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false
        // filter:drop-shadow(2px -2px 2px rgba(0,0,0,0.5))
        layer.shadowColor = UIColor.black.cgColor; layer.shadowOpacity = 0.5; layer.shadowRadius = px(1); layer.shadowOffset = CGSize(width: px(2), height: -px(2))
        addSubview(shade)
        line.backgroundColor = UIColor(white: 1, alpha: 0.2)
        addSubview(line)
        bubble.image = Res.image("img/orteilBubble.png")
        bubble.alpha = 0
        addSubview(bubble)
        var st = TextStyle.fancy(10, color: .ccText); st.align = .center
        st.shadow = Shadows.make(0, 1.5, 0, UIColor(css: "#260401"))
        bubbleText.style = st
        bubble.addSubview(bubbleText)
        addSubview(bottomLayer); addSubview(topLayer)
        JSMath.seedrandom(G.seed + "-orteilVariant")
        shirt = choose([1, 2, 3])
        JSMath.seedrandom()
        if JSMath.random() < 1.0 / 500 { anim = 1; animTM = 500; animT = 0 }
        onTap = { [weak self] _ in self?.tapped() }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 24, repeats: true) { [weak self] t in
            guard let self = self, self.window != nil || self.superview != nil else { t.invalidate(); return }
            self.animate()
        }
        animate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in self?.talk(MiscScreen.getTip(false)) }
    }
    required init?(coder: NSCoder) { fatalError() }
    deinit { timer?.invalidate() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width, h = bounds.height
        shade.frame = CGRect(x: -px(8), y: h + px(1) - px(32), width: w + px(16), height: px(32))
        line.frame = CGRect(x: -px(8), y: h + px(1) - px(1), width: w + px(16), height: px(1))
        bubble.frame = CGRect(x: w - px(2 + 240), y: px(2), width: px(240), height: px(64))
        layoutBubbleText()
        bottomLayer.frame = CGRect(x: -px(2), y: h + px(4) - px(74), width: px(62), height: px(74))
        topLayer.frame = bottomLayer.frame
    }
    private func layoutBubbleText() {
        let tw = 240.0 - 22 - 8
        let th = min(48, bubbleText.fittingHeight(tw))
        bubbleText.frame = CGRect(x: px(22), y: px(8 + (48 - th) / 2), width: px(tw), height: px(th))
    }

    private func frame(_ c: [Int]) -> UIImage? { Res.sprite("img/orteil.png", x: Double(c[0] * 62), y: Double(c[1] * 74), w: 62, h: 74) }
    private func animate() {
        var l1 = [3, 0], l2 = [0, 0]
        var body = "shirt\(shirt)"
        if G.season == "christmas" { body = "santa" }
        else if G.season == "easter" { body = "bunny" }
        else if G.season == "fools" { body = "business" }
        else if G.season == "valentines" { body = "cupid" }
        else if G.season == "halloween" { body = G.getSet("notScary") != 0 ? "witch" : "zombie" }
        var head = 0
        if talkFor > 0 { head = G.T % 4 < 2 ? 0 : 1; talkFor -= 1000.0 / 24 }
        if head == 0 && JSMath.random() < 0.02 { head = 2 }
        switch body {
        case "zombie": l1 = [head == 1 ? 0 : 1, 2]; l2 = l1
        case "santa": l1 = [0 + head, 1]; l2 = l1
        case "bunny": l1 = [3 + head, 3]; l2 = l1
        case "witch": l1 = [0 + head, 3]; l2 = l1
        case "cupid": l1 = [2 + ((G.T % 8 < 4 && head != 1) ? 0 : (1 + head)), 2]; l2 = l1
        default:
            if body == "shirt1" { l1 = [3, 0] } else if body == "shirt2" { l1 = [4, 0] } else if body == "shirt3" { l1 = [5, 0] } else if body == "business" { l1 = [3, 1] }
            l2 = [head, 0]
            if anim == 1 {
                head = Int((animT / animTM * 7).rounded(.down))
                l2 = head < 3 ? l1 : [6, head - 3]
            }
        }
        if anim > 0 && animT < animTM {
            talkFor = 0
            animT += 1000.0 / 24
            if animT >= animTM { animT = 0; animTM = 0; anim = 0 }
        }
        bottomLayer.image = frame(l1)
        topLayer.image = frame(l2)
    }

    func talk(_ textIn: String) {
        var text = textIn
        talkFor = (pow(Double(text.count) / 3, 0.5) * 150).rounded(.down)
        upgradeUnlockedByTip = nil
        if let r = text.range(of: #"\[UP#(\d+)\]"#, options: .regularExpression) {
            let idStr = text[r].dropFirst(4).dropLast()
            if let id = Int(idStr), let up = G.upgradesBID[id] {
                text.replaceSubrange(r, with: "<span class=\"tinyIcon\" style=\"background-position:\(-up.icon[0] * 48)px \(-up.icon[1] * 48)px;\"></span>")
                upgradeUnlockedByTip = up
            }
        }
        bubbleText.html = text
        layoutBubbleText()
        bubble.alpha = 1
        // bubbleAppearFromLeft
        bubble.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
        bubble.frame = CGRect(x: bounds.width - px(2 + 240), y: px(2), width: px(240), height: px(64))
        let a = CAKeyframeAnimation(keyPath: "transform")
        a.values = [NSValue(caTransform3D: CATransform3DMakeScale(0.01, 1.2, 1)), NSValue(caTransform3D: CATransform3DMakeScale(1.05, 0.95, 1)), NSValue(caTransform3D: CATransform3DIdentity)]
        a.duration = 0.15
        a.timingFunction = CAMediaTimingFunction(name: .easeOut)
        bubble.layer.add(a, forKey: "appear")
    }
    private func tapped() {
        PlaySound("snd/clickb\(choose(["1", "2", "3", "4", "5", "6", "7"])).mp3", 0.5)
        if let up = upgradeUnlockedByTip, up.unlocked == 0 {
            PlaySound("snd/giftSend.mp3", 0.5)
            G.toast(up.name, "You unlocked an upgrade!", up.icon, true)
            up.unlock()
            let p = bubble.convert(CGPoint(x: bubble.bounds.midX, y: bubble.bounds.midY), to: superview?.window)
            let top = Double((p.y) / K) - Layout.sat
            G.particleAt(Particle(x: Double(p.x / K), y: top, xd: JSMath.random() * 4 - 2, yd: -5, s: 0.5, r: 0, pic: .icon(up.icon)))
            G.sparkleAt(Double(p.x / K), top)
        }
        upgradeUnlockedByTip = nil
        G.tippedN += 1
        talk(MiscScreen.getTip(true))
    }
}

/// .halfButton: half width, 56px high, Fancy 16px, a big faded icon behind the text
final class HalfButton: TapView {
    let shade = GradientView.buttonShade()
    let bevel = BevelView(.bump)
    let icon: IconView?
    let label = RichLabel()
    init(html: String, icon ic: [Int]?, color: UIColor = .ccText, glowRed: Bool = false, linkBlue: Bool = false) {
        icon = ic.map { IconView($0) }
        super.init(frame: .zero)
        brightensWhenPressed = true
        layer.cornerRadius = px(4)
        clipsToBounds = true
        addSubview(shade)
        if let i = icon { addSubview(i) }
        addSubview(bevel)
        var st = TextStyle.fancy(16, color: linkBlue ? UIColor(css: "#3ec6ff") : color); st.bold = true; st.align = .center
        st.shadow = glowRed ? Shadows.warning : Shadows.body
        label.style = st
        label.html = html
        addSubview(label)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        let w = Double(bounds.width / K)
        shade.frame = bounds; bevel.frame = bounds
        let lh = label.fittingHeight(w - 12)
        label.frame = CGRect(x: px(6), y: px(20), width: px(w - 12), height: px(lh))
        if let i = icon {
            // tinyIcon at scale(1.5), 8px left of where the text starts, behind it
            let firstLine = RichText.plain(label.html).components(separatedBy: "\n").first ?? ""
            let tw = Double(RichText.size(RichText.render(firstLine, style: label.style, width: nil), width: nil).width)
            let startX = 6 + (w - 12 - tw) / 2
            i.bounds = CGRect(x: 0, y: 0, width: px(48), height: px(48))
            i.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            i.center = CGPoint(x: px(startX - 8), y: px(20 + 13 - 10))
        }
    }
}

final class MiscScreen: GameScreen {
    private var panel: SectionPanel?
    init() { super.init(name: "misc") }

    static func getTip(_ isTap: Bool) -> String {
        let years = max(Int((nowMs() - MiscScreen.birthday) / (1000 * 60 * 60 * 24 * 365)), 10)
        var tips = Tips.base(years: years)
        if G.tippedN >= 20 && G.cookiesEarned >= 1000 {
            tips += Tips.unlocked().filter { G.gcMissed > 1 || !$0.contains("golden cookies since you started") }
        }
        if let up = G.getHiddenUpgradeForSlot("orteilTip"), up.unlocked == 0 {
            if JSMath.random() < 0.1 { tips = [] }
            tips += Tips.upgrade(upStr: "[UP#\(up.id)]")
        }
        if !isTap {
            if JSMath.random() < 0.25 { tips = [] }
            if G.season == "easter" { tips += Tips.easter() }
            else if G.season == "valentines" { tips += Tips.valentines() }
            else if G.season == "fools" { tips += Tips.fools() }
            else if G.season == "halloween" && G.getSet("notScary") != 0 { tips += Tips.witch() }
            else if G.season == "halloween" { tips += Tips.halloween() }
            else if G.season == "christmas" { tips += Tips.christmas() }
            if G.season == "" || JSMath.random() < 0.3 { tips += Tips.greet() }
            let d = Calendar.current.dateComponents([.day, .month], from: Date())
            if d.day == 8 && d.month == 8 { tips += ["did you know it's Cookie Clicker's birthday today? wow. that is so cool.", "it's Cookie Clicker's birthday today, by the way. yippie!", "and thus Cookie Clicker turns one year older today."] }
            else if d.day == 8 && d.month == 11 { tips += ["hey, it's my birthday today!", "it's my birthday today. so many cookies, so little cake...", "i'm celebrating my birthday today, by the way. if you care."] }
        }
        for t in G.recentTips { if let i = tips.firstIndex(of: t) { tips.remove(at: i) } }
        if tips.isEmpty { tips = ["...", "...?"] }
        var tip = choose(tips)
        if G.tippedN == 0 { tip = "oh hey! nice to meet you."; G.tippedN += 1 }
        G.recentTips.insert(tip, at: 0)
        G.recentTips = Array(G.recentTips.prefix(15))
        return tip
    }
    /// new Date(2013,7,8)
    static let birthday: Double = {
        var c = DateComponents(); c.year = 2013; c.month = 8; c.day = 8
        return (Calendar.current.date(from: c)?.timeIntervalSince1970 ?? 1375920000) * 1000
    }()

    override func build() {
        let p = SectionPanel(in: view)
        panel = p
        let c = p.scroll.content
        let W = p.width
        var y = 8.0
        let header = PinHeader("Misc")
        c.addSubview(header)
        header.frame = CGRect(x: px(8 + (W - header.cssWidth) / 2), y: px(y + 2), width: px(header.cssWidth), height: px(45))
        y += 45 + 2 - 12

        let orteil = OrteilView()
        orteil.frame = CGRect(x: px(8), y: px(y + 4), width: px(W), height: px(74))
        c.addSubview(orteil)
        y += 4 + 74 + 4

        let half = W / 2
        let buttons: [HalfButton] = [
            HalfButton(html: "Settings", icon: [16, 5]),
            HalfButton(html: "About", icon: [0, 7]),
            HalfButton(html: "<span style=\"letter-spacing:-0.8px;\">Version history</span>", icon: [23, 11]),
            HalfButton(html: "Wipe save<div style=\"font-size:8px;opacity:0.75;\">(will ask for confirmation)</div>", icon: [29, 6], color: UIColor(css: "#c00"), glowRed: true),
        ]
        buttons[0].onTap = { _ in MiscScreen.settingsPopup() }
        buttons[1].onTap = { _ in MiscScreen.aboutPopup() }
        buttons[2].onTap = { _ in MiscScreen.versionPopup() }
        buttons[3].onTap = { _ in MiscScreen.wipePopup() }
        for (i, b) in buttons.enumerated() {
            b.frame = CGRect(x: px(8 + Double(i % 2) * half), y: px(y + Double(i / 2) * 55), width: px(half), height: px(56))
            c.addSubview(b)
        }
        y += 56 * 2 - 1

        // import / export
        let box = DoilyBox()
        c.addSubview(box)
        var by = 4.0
        var st = TextStyle.base(10); st.align = .center; st.shadow = Shadows.body
        let note = RichLabel(st); note.html = "You can backup your save by <b>exporting it</b>."
        box.addSubview(note)
        note.frame = CGRect(x: px(8), y: px(by + 6), width: px(W - 16), height: px(12)); by += 6 + 12
        var bf = TextStyle.base(10, color: .ccText); bf.bold = true; bf.shadow = Shadows.body; bf.nowrap = true
        let exportB = CCButton("Export save file...", look: .bump, font: bf)
        let importB = CCButton("Import save file...", look: .bump, font: bf)
        let extrasB = CCButton("iPhone extras...", look: .bump, font: bf)
        for b in [exportB, importB, extrasB] { b.backgroundColor = UIColor(white: 0, alpha: 0.25); box.addSubview(b) }
        exportB.onTap = { _ in PlaySound("snd/press.mp3", 0.15); SaveFiles.exportFile() }
        importB.onTap = { _ in MiscScreen.importPopup() }
        extrasB.onTap = { _ in PlaySound("snd/press.mp3", 0.15); ExtrasHost.open() }
        func bw(_ b: CCButton) -> Double { Double(RichText.size(RichText.render(b.text, style: bf, width: nil), width: nil).width) + 16 }
        let w1 = bw(exportB), w2 = bw(importB), w3 = bw(extrasB)
        var bx = (W - (w1 + w2 + 8)) / 2
        exportB.frame = CGRect(x: px(bx + 2), y: px(by + 2), width: px(w1), height: px(18)); bx += w1 + 4
        importB.frame = CGRect(x: px(bx + 2), y: px(by + 2), width: px(w2), height: px(18))
        by += 22
        extrasB.frame = CGRect(x: px((W - w3) / 2), y: px(by + 4 + 2), width: px(w3), height: px(18))
        by += 4 + 22 + 4
        box.frame = CGRect(x: px(8), y: px(y + 4), width: px(W), height: px(by))
        y += 4 + by + 8

        // live / alpha
        let box2 = DoilyBox()
        c.addSubview(box2)
        by = 4
        var hs = TextStyle.base(11); hs.bold = true; hs.align = .center; hs.shadow = Shadows.body
        let live = RichLabel(hs)
        let test = SaveStore.isTest
        live.html = test ? "You are playing the <span style=\"color:#99f;\">alpha</span> version." : "You are playing the <span style=\"color:#9f0;\">live</span> version."
        box2.addSubview(live)
        live.frame = CGRect(x: px(8), y: px(by + 4), width: px(W - 16), height: px(12)); by += 4 + 11 + 4
        var sf = TextStyle.base(10, color: UIColor(css: test ? "#9f0" : "#99f")); sf.bold = true; sf.shadow = Shadows.body; sf.nowrap = true
        let sw = CCButton(test ? "Switch to live version <span style=\"font-size:7px;\">(v\(jsString(Game.version)))</span>" : "Switch to alpha version <span style=\"font-size:7px;\">(v\(jsString(Game.version)))</span>", look: .bump, font: sf)
        let tint = GradientView(test ? [UIColor(red: 0, green: 1, blue: 0, alpha: 0.25), UIColor(white: 0, alpha: 0.1)] : [UIColor(red: 0.5, green: 0, blue: 1, alpha: 0.25), UIColor(white: 0, alpha: 0.1)])
        sw.insertSubview(tint, at: 0)
        sw.onTap = { _ in SaveStore.switchSlot(test: !test) }
        let sww = Double(RichText.size(RichText.render(sw.text, style: sf, width: nil), width: nil).width) + 16
        sw.frame = CGRect(x: px((W - sww) / 2), y: px(by + 2), width: px(sww), height: px(18))
        tint.frame = sw.bounds; tint.layer.cornerRadius = px(4); tint.clipsToBounds = true
        box2.addSubview(sw)
        by += 22
        var ps = TextStyle.base(9); ps.shadow = Shadows.body
        let p1 = RichLabel(ps)
        p1.html = "<p>\(test ? "This version" : "The alpha version") uses a different save slot than the live version. It may be unstable or unbalanced. Play at your own risk!</p>"
        let h1 = p1.fittingHeight(W - 16)
        p1.frame = CGRect(x: px(8), y: px(by), width: px(W - 16), height: px(h1)); by += h1
        box2.addSubview(p1)
        let ln = LineView(); ln.frame = CGRect(x: px(8), y: px(by + 6), width: px(W - 16), height: px(3)); box2.addSubview(ln); by += 13
        let p2 = RichLabel(TextStyle.base(11))
        p2.style.shadow = Shadows.body
        p2.html = "<p class=\"printText\">No new alpha features</p><p style=\"font-size:9px;\">All alpha features have been ported to the live version. The alpha version currently contains no extra features and is only used for compatibility.</p>"
        let h2 = p2.fittingHeight(W - 16)
        p2.frame = CGRect(x: px(8), y: px(by), width: px(W - 16), height: px(h2)); by += h2 + 4
        box2.addSubview(p2)
        box2.frame = CGRect(x: px(8), y: px(y + 4), width: px(W), height: px(by))
        y += 4 + by + 8

        p.scroll.setContentHeight(px(y + 8))
        c.bringSubviewToFront(header)
    }
    override func clean() { panel = nil }

    // MARK: popups
    static func settingsPopup() {
        Popup.open(PopupOptions(build: { c in
            c.h3("<span class=\"tinyIcon\" style=\"background-position:\(-16 * 48)px \(-5 * 48)px;\"></span> Settings")
            var list: [(String, String, String, Bool)] = [
                ("Sound", "Enable or disable all sound effects.", "sound", false),
                ("Tab swipe", "Lets you swipe left and right to change tabs.", "pan", false),
            ]
            if G.hasAchiev("Cookie-dunker") { list.append(("Dislodge cookie", "Pull on the big cookie to dislodge it.", "dislodge", false)) }
            list += [
                ("Fancy graphics", "Animations and other visual effects.<br>Disabling may improve performance.", "fancy", false),
                ("Extra shadows", "Adds soft shadows under icons.<br>May have a high performance impact.", "shadows", false),
                ("Cookie wobble", "Makes the big cookie wobble at your touch.<br>Requires fancy graphics to be on.", "cookiewobble", false),
                ("Reduce motion", "Reduces interface motion.", "lowMotion", false),
                ("Particles", "Disabling may improve performance.", "particles", false),
                ("Cookie pops", "Visual effect reflecting cookie production.<br>Requires particles to be on.", "cookiepops", false),
                ("Cursors", "Cursors rotating around your cookie.<br>Disabling may improve performance.", "cursors", false),
                ("Milk", "Disabling may improve performance.", "milk", false),
                ("Scary stuff", "", "notScary", true),
            ]
            for (t, cm, s, inv) in list {
                let b = StateButton(text: t, comment: cm.isEmpty ? nil : cm, setting: s, invert: inv)
                c.add(b, marginTop: 2, marginBottom: 2, marginLeft: 2, marginRight: 2) { w in b.height(width: w) }
            }
        }, close: "Confirm"))
    }

    static func linkButton(_ html: String, _ url: String) -> HalfButton {
        let b = HalfButton(html: html, icon: nil, linkBlue: true)
        b.onTap = { _ in PlaySound("snd/smallTick.mp3", 1); if let u = URL(string: url) { UIApplication.shared.open(u) } }
        return b
    }
    static func aboutPopup() {
        Popup.open(PopupOptions(build: { c in
            c.h3("<span class=\"tinyIcon\" style=\"background-position:0px \(-7 * 48)px;\"></span> About")
            c.html("<p><span class=\"tinyCookie\"></span><span class=\"printText\">Cookie Clicker</span> is a game by Orteil and Opti, two very cool dudes from Europe.</p><p>This mobile version is adapted from our browser game. We also have a desktop version on Steam!</p><p><b>Stuck in the game?</b> Here's some resources that may help.</p><div style=\"font-size:80%;font-style:italic;color:#3ec6ff;text-align:center;\"><b>(Note: all links open in browser)</b></div><div style=\"font-size:80%;font-style:italic;color:#c00;text-align:center;\"><b>(Warning! Links may contain spoilers!)</b></div>")
            let links = [
                linkButton("<div style=\"margin-top:-6px;\">DashNet<div style=\"font-size:8px;opacity:0.75;\">our official website<br>(even more games!)</div></div>", "http://orteil.dashnet.org/"),
                linkButton("Discord<div style=\"font-size:8px;opacity:0.75;\">our official Discord server</div>", "https://discordapp.com/invite/cookie"),
                linkButton("<span style=\"letter-spacing:-0.8px;font-size:85%;\">r/cookieclicker</span><div style=\"font-size:8px;opacity:0.75;\">the unofficial subreddit</div>", "https://www.reddit.com/r/CookieClicker/"),
                linkButton("Wiki<div style=\"font-size:8px;opacity:0.75;\">the unofficial wiki</div>", "https://cookieclicker.wiki.gg/wiki/Cookie_Clicker_Wiki"),
            ]
            let grid = UIView()
            links.forEach { grid.addSubview($0) }
            c.add(grid) { w in
                for (i, b) in links.enumerated() { b.frame = CGRect(x: px(Double(i % 2) * w / 2), y: px(Double(i / 2) * 55), width: px(w / 2), height: px(56)) }
                return 111
            }
            let t = c.html("<p style=\"margin-top:24px;font-size:80%;\"><span class=\"tinyIcon\" style=\"background-position:\(-20 * 48)px \(-3 * 48)px;\"></span> Thank you so much for playing Cookie Clicker!</p>", marginTop: 24)
            let s = c.html("<p style=\"opacity:0.5;text-align:right;font-style:italic;font-size:80%;\">-Orteil &amp; Opti</p>", marginTop: -8)
            DispatchQueue.main.async { Anim.switchAnim(t, "switchRightIn"); Anim.switchAnim(s, "switchLeftIn") }
        }, close: "Got it"))
    }

    static let updates: [[Any]] = {
        guard let u = Res.url("Updates.json"), let d = try? Data(contentsOf: u), let a = try? JSONSerialization.jsonObject(with: d) as? [[Any]] else { return [] }
        return a
    }()
    static func versionPopup() {
        Popup.open(PopupOptions(build: { c in
            c.h3("<span class=\"tinyIcon\" style=\"background-position:\(-23 * 48)px \(-11 * 48)px;\"></span> Version history")
            c.html("<p>Information about every update and patch can be found here, from newest to oldest.</p><p style=\"opacity:0.75;text-align:center;\">Currently running <b>v\(jsString(Game.version))</b>.</p><p style=\"font-style:italic;opacity:0.75;\">Check out these links for news and previews on future updates:</p>")
            var lf = TextStyle.base(9.9, color: UIColor(css: "#3ec6ff")); lf.bold = true; lf.shadow = Shadows.body; lf.nowrap = true
            let links = [("Orteil's tumblr", "https://orteil42.tumblr.com/"), ("Orteil's twitter", "https://twitter.com/orteil42"), ("Patreon", "https://www.patreon.com/dashnet")].map { (t, u) -> CCButton in
                let b = CCButton(t, look: .bump, font: lf)
                b.onTap = { _ in PlaySound("snd/smallTick.mp3", 1); if let url = URL(string: u) { UIApplication.shared.open(url) } }
                return b
            }
            c.buttons(links, height: 18)
            for u in updates {
                let v = (u[0] as? Double) ?? -1
                let date = u[1] as? String ?? ""
                let title = u[2] as? String ?? ""
                let items = (u[3] as? String ?? "").split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                let box = UpdateBox(version: v > -1 ? "v" + jsString(v) : "", date: date, title: title, items: items)
                c.add(box, marginTop: 2, marginBottom: 2, marginLeft: -10, marginRight: -10) { w in box.height(w) }
            }
            if !G.hasAchiev("Olden days") {
                let b = TapView()
                let ic = IconView([12, 3]); ic.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                b.addSubview(ic)
                b.onTap = { v in
                    if G.hasAchiev("Olden days") { return }
                    v.isHidden = true
                    G.win("Olden days")
                    PlaySound("snd/tick.mp3", 1); PlaySound("snd/shimmerClick.mp3", 1)
                }
                c.add(b, marginTop: -8, width: 24, x: { a, _ in a - 24 }) { _ in ic.center = CGPoint(x: px(12), y: px(12)); return 24 }
            }
        }, close: "Got it"))
    }

    static func wipePopup() {
        Popup.open(PopupOptions(build: { c in
            c.h3("<span class=\"tinyIcon\" style=\"background-position:\(-29 * 48)px \(-6 * 48)px;\"></span> Wipe save")
            c.html("<p>Do you REALLY want to wipe your save?</p><p style=\"font-size:80%;\">You will lose all your progress and your achievements!</p>")
            c.line()
            let yes = HalfButton(html: "Yes!", icon: nil, color: UIColor(css: "#c00"), glowRed: true)
            yes.onTap = { _ in
                var o = PopupOptions(build: { c in
                    c.h3("<span class=\"tinyIcon\" style=\"background-position:\(-29 * 48)px \(-6 * 48)px;\"></span> Wipe save")
                    c.html("<p class=\"warning\">Whoah now, are you really, <b>REALLY</b> sure you want to go through with this?</p><p class=\"warning\" style=\"font-size:80%;\">Don't say we didn't warn you!</p>")
                    c.line()
                    let doIt = HalfButton(html: "Do it! Wipe the save!", icon: nil, color: UIColor(css: "#c00"), glowRed: true)
                    doIt.onTap = { _ in PlaySound("snd/thud.mp3", 1); G.Reset(true) }
                    c.add(doIt, height: 56, marginTop: 80, marginBottom: 8)
                }, close: "No!!!")
                o.replace = true
                Popup.open(o)
            }
            c.add(yes, height: 56, marginTop: 8, marginBottom: 8)
        }, close: "No"))
    }

    static func importPopup() {
        var dataToImport: [String: Any]?
        Popup.open(PopupOptions(build: { c in
            c.h3("Import save file")
            c.html("<div style=\"text-align:center;\"><div>This feature allows you to restore backups or transfer saves from other devices. Please use it responsibly.</div><div style=\"font-size:85%;margin-top:6px;font-style:italic;\">Importing may not work on some older devices!</div></div>")
            let load = HalfButton(html: "Load file...", icon: nil)
            c.add(load, height: 56, marginTop: 8, marginBottom: 8)
            c.line()
            let fileBox = NameBox()
            var fs = TextStyle.base(10); fs.shadow = Shadows.body; fs.align = .center
            let fileL = RichLabel(fs); fileL.html = "No file selected."
            fileBox.addSubview(fileL)
            c.add(fileBox, marginTop: 3, marginBottom: 3) { w in
                let tw = min(w - 16, Double(RichText.size(RichText.render(fileL.html, style: fs, width: w - 16), width: w - 16).width) + 2)
                let th = fileL.fittingHeight(tw)
                fileBox.frame.size.width = px(tw + 16)
                fileBox.frame.origin.x = px(16 + (w - tw - 16) / 2)
                fileL.frame = CGRect(x: px(8), y: px(4), width: px(tw), height: px(th))
                return th + 8
            }
            var ws = TextStyle.base(10, color: UIColor(css: "#c00")); ws.shadow = Shadows.warning; ws.align = .center
            let warn = RichLabel(ws)
            c.add(warn, marginTop: 4, marginBottom: 4) { w in warn.fittingHeight(w) }
            c.line()
            var cf = TextStyle.base(11, color: UIColor(css: "#3f0")); cf.bold = true; cf.shadow = Shadows.body; cf.nowrap = true
            let confirm = CCButton("Import this save", look: .bump, font: cf, padding: UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12))
            confirm.isHidden = true
            c.buttons([confirm], height: 23)
            confirm.onTap = { _ in
                guard let d = dataToImport else { return }
                Popup.close()
                G.Reset(true)
                _ = G.LoadFromObject(d)
                dataToImport = nil
            }
            load.onTap = { _ in
                dataToImport = nil
                fileL.html = "Loading file..."
                warn.html = ""
                confirm.isHidden = true
                c.relayout()
                PlaySound("snd/tick.mp3", 0.5)
                SaveFiles.pickFile { result in
                    switch result {
                    case .cancelled:
                        fileL.html = "No file selected."; warn.html = ""
                    case .failed(let name, let msg):
                        fileL.html = name.map { "<b>File: \(RichText.escape($0))</b>" } ?? "No file selected."
                        warn.html = "Error when reading file:<br>\(msg)"
                    case .ok(let name, let data):
                        PlaySound("snd/smallTick.mp3", 0.75)
                        let cookies = (data["cookies"] as? Double) ?? 0
                        let time = (data["time"] as? Double) ?? nowMs()
                        let ver = jsString((data["lastVersion"] as? Double) ?? 0) + ((data["alpha"] as? Bool) == true ? " ALPHA" : "")
                        fileL.html = "<b>File name:</b> \(RichText.escape(name))<br><b>Game version:</b> v.\(ver)<br><b>Cookies:</b> <span class=\"tinyCookie\"></span>\(B(cookies))<br><b>Last played:</b> \(sayTime(nowMs() - time)) ago<br>"
                        if ((data["lastVersion"] as? Double) ?? 0) > Game.version {
                            warn.html = "Error when reading file:<br>Save is from a future game version."
                        } else {
                            warn.html = "Importing this save will overwrite your current save." + ((data["edited"] != nil) ? "<br>Note: this save file was edited or converted and may have unexpected effects." : "")
                            confirm.isHidden = false
                            dataToImport = data
                        }
                    }
                    c.relayout()
                }
            }
        }, close: "Cancel"))
    }
}

/// one entry of the version history (.bumpy with a printText title and zebra lines)
final class UpdateBox: UIView {
    let bevel = BevelView(.bump)
    let title = RichLabel()
    let ver = RichLabel()
    let date = RichLabel()
    var rows: [(UIView, RichLabel)] = []
    init(version: String, date d: String, title t: String, items: [String]) {
        super.init(frame: .zero)
        layer.cornerRadius = px(4); clipsToBounds = true
        addSubview(bevel)
        var ts = TextStyle(); ts.family = .georgia; ts.bold = true; ts.align = .center; ts.shadow = Shadows.print; ts.color = .ccText
        title.style = ts; title.html = t; addSubview(title)
        var vs = ts; vs.size = 9; vs.align = .left
        ver.style = vs; ver.alpha = 0.75; ver.html = version; addSubview(ver)
        vs.align = .right
        date.style = vs; date.alpha = 0.75; date.html = d; addSubview(date)
        for (i, it) in items.enumerated() {
            let z = UIView()
            z.backgroundColor = i % 2 == 1 ? UIColor(white: 1, alpha: 0.1) : UIColor(white: 0, alpha: 0.1)
            var ps = TextStyle.base(10); ps.shadow = Shadows.body; ps.textIndent = 8
            let l = RichLabel(ps); l.html = "&bull; " + it
            z.addSubview(l)
            addSubview(z)
            rows.append((z, l))
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    func height(_ w: Double) -> Double {
        var y = 8 - 3.0
        let th = title.fittingHeight(w - 16)
        title.frame = CGRect(x: px(8), y: px(y), width: px(w - 16), height: px(th))
        ver.frame = CGRect(x: px(8), y: px(y + 1), width: px(60), height: px(10))
        date.frame = CGRect(x: px(w - 8 - 120), y: px(y + 1), width: px(120), height: px(10))
        y += th + 2
        for (z, l) in rows {
            let lh = l.fittingHeight(w - 16)
            z.frame = CGRect(x: 0, y: px(y), width: px(w), height: px(lh + 4))
            l.frame = CGRect(x: px(8), y: px(2), width: px(w - 16), height: px(lh))
            y += lh + 4
        }
        bevel.frame = CGRect(x: 0, y: 0, width: px(w), height: px(y + 8))
        return y + 8
    }
}

extension RichText {
    static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;")
    }
}

// MARK: - export/import files (what the web version did through its file plugin)

enum SaveFiles {
    enum PickResult { case ok(String, [String: Any]), failed(String?, String), cancelled }
    private static var pickerDelegate: PickerDelegate?

    static var presenter: UIViewController? {
        var vc = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow }) }.first?.rootViewController
        while let p = vc?.presentedViewController { vc = p }
        return vc
    }

    /// "Export save file...": a text file holding the save (base64 of the JSON), offered through the share sheet
    static func exportFile() {
        let d = Date()
        let c = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute], from: d)
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let name = "CookieClickerSave-\(c.day!)\(months[c.month! - 1])\(c.year!)-\(String(format: "%02d", c.hour!))h\(String(format: "%02d", c.minute!)).txt"
        let json = String(data: (try? JSONSerialization.data(withJSONObject: G.Save(toObj: true))) ?? Data(), encoding: .utf8) ?? "{}"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try? Data(json.utf8).base64EncodedString().data(using: .utf8)?.write(to: url, options: .atomic)
        guard let vc = presenter else { return }
        let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = vc.view
            pop.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.midY, width: 1, height: 1)
            pop.permittedArrowDirections = []
        }
        vc.present(sheet, animated: true)
    }

    static func pickFile(_ done: @escaping (PickResult) -> Void) {
        guard let vc = presenter else { return done(.cancelled) }
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        let d = PickerDelegate { url in
            pickerDelegate = nil
            guard let url = url else { return done(.cancelled) }
            let name = url.lastPathComponent
            guard let data = try? Data(contentsOf: url), !data.isEmpty else { return done(.failed(name, "No data in file.")) }
            guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1),
                  let obj = SaveStore.importString(text) else { return done(.failed(name, "Invalid data JSON.")) }
            if obj["cookies"] == nil || obj["buildings"] == nil || obj["upgrades"] == nil || obj["achievs"] == nil { return done(.failed(name, "Wrong save format.")) }
            done(.ok(name, obj))
        }
        pickerDelegate = d
        picker.delegate = d
        picker.allowsMultipleSelection = false
        vc.present(picker, animated: true)
    }

    private final class PickerDelegate: NSObject, UIDocumentPickerDelegate {
        let done: (URL?) -> Void
        init(_ done: @escaping (URL?) -> Void) { self.done = done }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) { done(urls.first) }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { done(nil) }
    }
}
