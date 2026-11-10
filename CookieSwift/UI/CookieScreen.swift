import UIKit

// The cookie screen (www/main.js "COOKIE SCREEN"): the big cookie with its shine, shadow and ring of cursors,
// the quick buttons, golden cookies, reindeer and wrinklers.

final class CookieScreen: GameScreen {
    /// #cookieContainer (moves when the cookie is pulled loose)
    private let container = PassView()
    private let bigCookie = BigCookieTouch()
    private let cookieLayer = CALayer()
    private var shadowLayer: CALayer?
    private var shine: UIView?
    private var cursorRing: UIImageView?
    private var quick: [String: QuickButton] = [:]
    private var quickBox: PassView?
    private var shimmerViews: [ObjectIdentifier: ShimmerView] = [:]
    private var wrinklerViews: [Int: WrinklerView] = [:]
    private var lastFreeOn = false
    private var lump: LumpWidget?

    init() { super.init(name: "cookie") }

    override func build() {
        let W = view.bounds.width, H = view.bounds.height
        container.subviews.forEach { $0.removeFromSuperview() }
        container.layer.sublayers?.filter { $0.delegate == nil }.forEach { $0.removeFromSuperlayer() }
        container.transform = .identity
        container.frame = view.bounds
        container.clipsToBounds = false
        view.addSubview(container)
        // the quick buttons, bottom right
        let qb = PassView(frame: CGRect(x: W, y: H, width: 0, height: 0))
        qb.clipsToBounds = false
        view.addSubview(qb)
        quickBox = qb
        buildQuickButtons()

        let center = CGPoint(x: W / 2, y: H / 2)
        let fancy = G.getSet("fancy") != 0
        if fancy {
            // #bigCookieShine: two flares fading and spinning, the whole thing turning once a minute
            let s = UIView(frame: CGRect(x: 0, y: 0, width: px(240), height: px(240)))
            s.center = center
            s.isUserInteractionEnabled = false
            for second in [false, true] {
                let f = CALayer()
                f.contents = Res.image("img/flare.png")?.cgImage
                f.bounds = CGRect(x: 0, y: 0, width: px(420), height: px(420))
                f.position = CGPoint(x: px(120), y: px(120))
                f.opacity = 0
                s.layer.addSublayer(f)
                spinFade(f, second: second)
            }
            spin(s.layer, seconds: 60, delay: 0)
            container.addSubview(s)
            shine = s
        }
        if G.getSet("cursors") != 0 && G.explodeT == -1 {
            // #cursorCanvas: the cursors you own in rings around the cookie, turning every 3 minutes
            let ring = UIImageView(frame: CGRect(x: 0, y: 0, width: px(480), height: px(480)))
            ring.center = center
            ring.isUserInteractionEnabled = false
            ring.image = CookieScreen.cursorImage(amount: min(350, G.buildings.first?.amount ?? 0))
            spin(ring.layer, seconds: 180, delay: Double(Int(JSMath.random() * 180)))
            container.addSubview(ring)
            cursorRing = ring
        }
        if fancy {
            let sh = CALayer()
            sh.contents = Res.image("img/cookieShadow.png")?.cgImage
            sh.bounds = CGRect(x: 0, y: 0, width: px(240), height: px(240))
            sh.position = center
            sh.cornerRadius = px(120)
            container.layer.addSublayer(sh)
            shadowLayer = sh
        }
        // #bigCookie
        cookieLayer.contents = Res.image("img/perfectCookie.png")?.cgImage
        cookieLayer.contentsScale = Res.image("img/perfectCookie.png")?.scale ?? 1
        cookieLayer.bounds = CGRect(x: 0, y: 0, width: px(240), height: px(240))
        cookieLayer.position = center
        cookieLayer.transform = CATransform3DIdentity
        container.layer.addSublayer(cookieLayer)
        bigCookie.frame = CGRect(x: 0, y: 0, width: px(240), height: px(240))
        bigCookie.center = center
        bigCookie.onDown = { [weak self] v, p in
            guard let self = self else { return }
            let loc = self.view.superview!.convert(p, from: nil)
            G.clickBigCookie(x: Double(loc.x / K), y: Double(loc.y / K))
        }
        bigCookie.onUp = { _ in G.releaseBigCookie() }
        container.addSubview(bigCookie)

        G.bigCookieState = 0
        G.bigCookieClicked = false
        G.bigCookieSize = 0
        G.bigCookieSizeD = 0
        G.bigCookieSizeT = 1
        if fancy && G.getSet("cookiewobble") != 0 {
            G.bigCookieSize = 0.95
            G.onX = Double((center.x - px(120)) / K)
            G.onY = Double(center.y / K)
        }
        G.freeCookie.reset()
        lastFreeOn = false
        // the sugar lump (mods/sugar-lumps.js), top left
        let lw = LumpWidget()
        lw.layer.zPosition = 100
        view.addSubview(lw)
        lump = lw
        lw.update()
    }

    override func clean() {
        if G.getSet("fancy") != 0 && G.getSet("cookiewobble") != 0 {
            G.bigCookieSize = 0.95
            G.onX = Double((view.bounds.width / 2 + px(120)) / K)
            G.onY = Double(view.bounds.height / 2 / K)
        }
        G.freeCookie.reset()
        for (_, v) in shimmerViews { v.removeFromSuperview() }
        shimmerViews = [:]
        for (_, v) in wrinklerViews { v.removeFromSuperview() }
        wrinklerViews = [:]
        G.undrawWrinklers()
        quick = [:]
        quickBox = nil
        shine = nil; cursorRing = nil; shadowLayer?.removeFromSuperlayer(); shadowLayer = nil
        cookieLayer.removeFromSuperlayer()
        (view.superview?.superview as? RootView)?.setMilkOnTop(false)
        (view.superview?.superview as? RootView)?.setBackScale(1)
        (view.superview?.superview as? RootView)?.rain.extraScale = 1.1
    }

    private var root: RootView? { view.superview?.superview as? RootView }

    // MARK: draw (the screen's draw function)
    override func draw() {
        let W = Double(view.bounds.width / K), H = Double(view.bounds.height / K)
        // freeCookie.draw
        let fc = G.freeCookie
        if fc.on != lastFreeOn {
            lastFreeOn = fc.on
            root?.setMilkOnTop(fc.on)
        }
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.1)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .default))
        if fc.on {
            container.transform = CGAffineTransform(translationX: px(fc.x * W), y: px(fc.y * H)).scaledBy(x: CGFloat(fc.s), y: CGFloat(fc.s))
        } else { container.transform = .identity }
        CATransaction.commit()
        // the cookie's box centre, in the game's coordinates
        let x1 = W / 2 + (fc.on ? fc.x * W : 0)
        let y1 = H / 2 + (fc.on ? fc.y * H : 0)
        if G.getSet("fancy") != 0 && G.getSet("cookiewobble") != 0 {
            let x2 = G.onX, y2 = G.onY
            var a = 0.0, d = 0.0, s = 1.0
            let x = 0.0, y = 0.0
            if G.intro > -1 {
                let t = Double(G.intro) / (G.fps * 2)
                d = (1 - t) * 100
                a = pow(t, 1.5) * 50
                s = 1 + abs(cos(pow(t, 1.5) * 20)) * (1 - pow(t, 0.25))
                shine?.alpha = CGFloat(t)
            } else {
                a = -atan2(y1 - y2, x1 - x2) - Double.pi / 2
                d = ((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)).squareRoot() * (1 - G.bigCookieSize) * 15
                if shine?.alpha != 1 { shine?.alpha = 1 }
            }
            let t = CookieScreen.cookieTransform(scale: G.bigCookieSize * s, tx: sin(a) * d / 4 + x, ty: cos(a) * d / 4 + y, tz: 0,
                                                 rx: -cos(-a), ry: -sin(-a), deg: min(d / 4, 20))
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.1)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .default))
            cookieLayer.transform = t
            if let sh = shadowLayer {
                let damp = 0.75
                sh.transform = CookieScreen.cookieTransform(scale: G.bigCookieSize * s + 0.15, tx: sin(a) * d / 4 * damp + 1 + x, ty: cos(a) * d / 4 * damp + 3 + y, tz: -10,
                                                            rx: -cos(-a) * damp, ry: -sin(-a) * damp, deg: min(d / 4, 20))
            }
            CATransaction.commit()
            root?.setBackScale(max(0.8, (G.bigCookieSize - 1) * 0.5 + 1))
            root?.rain.extraScale = max(0.8, (1 - G.bigCookieSize) * 0.5 + 1 + 0.1)
        }
        // the explosion before ascending hides the cookie
        container.alpha = G.explodeT > -1 ? 0 : 1
        quickBox?.alpha = G.explodeT > -1 ? 0 : 1
        updateQuickButtons()
        lump?.update()
        drawShimmers()
        drawWrinklers()
    }

    /// scale() perspective(300px) translate3d() rotate3d(), like the CSS (applied right to left)
    static func cookieTransform(scale: Double, tx: Double, ty: Double, tz: Double, rx: Double, ry: Double, deg: Double) -> CATransform3D {
        var p = CATransform3DIdentity
        p.m34 = -1 / px(300)
        var m = CATransform3DIdentity
        if deg != 0 && (rx != 0 || ry != 0) { m = CATransform3DMakeRotation(CGFloat(deg * .pi / 180), CGFloat(rx), CGFloat(ry), 0) }
        m = CATransform3DConcat(m, CATransform3DMakeTranslation(px(tx), px(ty), px(tz)))
        m = CATransform3DConcat(m, p)
        m = CATransform3DConcat(m, CATransform3DMakeScale(CGFloat(scale), CGFloat(scale), 1))
        return m
    }

    private func spin(_ l: CALayer, seconds: Double, delay: Double) {
        // @keyframes bigCookieShineSpin: rotate(360deg) → rotate(0deg)
        let a = CABasicAnimation(keyPath: "transform.rotation.z")
        a.fromValue = 2 * Double.pi
        a.toValue = 0
        a.duration = seconds
        a.repeatCount = .infinity
        a.timeOffset = delay
        a.isRemovedOnCompletion = false
        l.add(a, forKey: "spin")
    }
    private func spinFade(_ l: CALayer, second: Bool) {
        let rot = CAKeyframeAnimation(keyPath: "transform")
        func t(_ deg: Double, _ s: Double) -> NSValue {
            NSValue(caTransform3D: CATransform3DScale(CATransform3DMakeRotation(CGFloat(deg * .pi / 180), 0, 0, 1), CGFloat(s), CGFloat(s), 1))
        }
        let op = CAKeyframeAnimation(keyPath: "opacity")
        if !second {
            rot.values = [t(0, 0.5), t(45, 1), t(90, 1.5)]; rot.keyTimes = [0, 0.5, 1]
            op.values = [0, 0.75, 0]; op.keyTimes = [0, 0.5, 1]
        } else {
            rot.values = [t(225, 1), t(270, 1.5), t(180, 0.5), t(225, 1)]; rot.keyTimes = [0, 0.5, 0.501, 1]
            op.values = [0.75, 0, 0, 0.75]; op.keyTimes = [0, 0.5, 0.501, 1]
        }
        let g = CAAnimationGroup()
        g.animations = [rot, op]
        g.duration = 3
        g.repeatCount = .infinity
        g.isRemovedOnCompletion = false
        l.add(g, forKey: "spinFade")
    }

    /// the ring of cursors (drawCursors)
    static func cursorImage(amount: Int) -> UIImage? {
        guard amount > 0, let pic = Res.image("img/cursor.png") else { return nil }
        let size = CGSize(width: px(480), height: px(480))
        let fmt = UIGraphicsImageRendererFormat(); fmt.scale = UIScreen.main.scale
        return UIGraphicsImageRenderer(size: size, format: fmt).image { ctx in
            let c = ctx.cgContext
            c.translateBy(x: px(240), y: px(240))
            for i in 0..<amount {
                let n = i / 50
                let alpha = 1 - Double(n) / 8
                let y = Double(140 + n * 16) - 24
                var rot = 7.2
                if i % 50 == 0 { rot += 7.2 / 2 }
                c.rotate(by: CGFloat(rot / 360 * Double.pi * 2))
                pic.draw(in: CGRect(x: 0, y: px(y), width: px(32), height: px(32)), blendMode: .normal, alpha: CGFloat(alpha))
            }
        }
    }

    // MARK: quick buttons
    private func buildQuickButtons() {
        guard let box = quickBox else { return }
        for (i, name) in G.quickButtons.enumerated() where name != "none" && G.quickButtonCond(name) {
            let pos = Game.quickButtonsPos[i]
            var icon = [30, 36]
            switch name {
            case "goldenSwitch": icon = [20, 10]
            case "dragonAura1", "dragonAura2": icon = [0, 7]
            case "seasonSwitcher": icon = [16, 6]
            default: break
            }
            let b = QuickButton(icon: icon)
            // right/bottom offsets of the 48px box, then scale(0.5) about its centre
            b.center = CGPoint(x: -px(pos[0] + 5 + 24), y: -px(pos[1] + 5 + 24))
            b.onTap = { [weak b] _ in
                guard let b = b else { return }
                if CookieScreen.quickButtonClick(name) {
                    PlaySound("snd/smallTick.mp3", 1)
                    Anim.trigger(b, "plopHalf")
                }
            }
            box.addSubview(b)
            quick[name] = b
        }
        updateQuickButtons()
    }
    static func quickButtonClick(_ name: String) -> Bool {
        switch name {
        case "powerClicks":
            if G.powerClicks < 1 { return false }
            G.powerClicksOn.toggle()
            if G.powerClicksOn {
                PlaySound("snd/roarOn2.mp3", 0.4)
                G.lastPowerClickUse = nowMs()
            }
            return true
        case "goldenSwitch":
            if G.isUnlocked("Golden switch [on]") { UpgradeUI.showInfo(G.upgradesBN["Golden switch [on]"]!) }
            else if let u = G.upgradesBN["Golden switch [off]"] { UpgradeUI.showInfo(u) }
            return true
        case "dragonAura1": PetsUI.selectDragonAura(0); return true
        case "dragonAura2": PetsUI.selectDragonAura(1); return true
        case "seasonSwitcher": PetsUI.seasonSwitcherPopup(); return true
        default: return false
        }
    }
    private func updateQuickButtons() {
        for (name, b) in quick {
            switch name {
            case "powerClicks":
                let n = G.powerClicks.rounded(.down)
                if G.powerClicksOn && (nowMs() - G.lastPowerClickUse) >= 1000 * 60 * 5 { G.powerClicksOn = false }
                if G.powerClicks >= 1 && !G.powerClicksOn { b.setStatus(1) }
                else if G.powerClicks < 1 || !G.powerClicksOn { b.setStatus(0); G.powerClicksOn = false }
                else if G.powerClicksOn { b.setStatus(2) }
                if n < 1 { b.setText("") }
                else { b.setText("\(jsString(n))/\(jsString(G.getPowerClickCapacity()))<br>power click\(n == 1 ? "" : "s")") }
            case "goldenSwitch":
                if G.isUnlocked("Golden switch [on]") { b.setIcon([21, 10]); b.setStatus(2) }
                else { b.setIcon([20, 10]); b.setStatus(1) }
            case "dragonAura1": b.setIcon(G.dragonAuras[G.dragonAura].pic); b.setStatus(1)
            case "dragonAura2": b.setIcon(G.dragonAuras[G.dragonAura2].pic); b.setStatus(1)
            case "seasonSwitcher": b.setStatus(1)
            default: break
            }
        }
    }
    func plopQuickButton(_ name: String, heavy: Bool) {
        if let b = quick[name] { Anim.trigger(b, heavy ? "plopHeavy" : "plopHalf") }
    }

    // MARK: shimmers (G.drawShimmers)
    private func drawShimmers() {
        var live = Set<ObjectIdentifier>()
        for me in G.shimmers {
            let id = ObjectIdentifier(me)
            live.insert(id)
            let v: ShimmerView
            if let e = shimmerViews[id] { v = e }
            else {
                v = ShimmerView(me)
                v.onDown = { _, _ in me.click() }
                view.addSubview(v)
                shimmerViews[id] = v
            }
            v.drawShimmer()
        }
        for (id, v) in shimmerViews where !live.contains(id) { v.removeFromSuperview(); shimmerViews[id] = nil }
    }

    // MARK: wrinklers (G.drawWrinklers)
    private func drawWrinklers() {
        // centred 10px above the cookie, like the original on a phone
        G.layoutWrinklers(fromX: G.w / 2, fromY: h / 2 + 20)
        for (i, me) in G.wrinklers.enumerated() {
            if me.shown && G.explodeT == -1 {
                let v: WrinklerView
                if let e = wrinklerViews[i] { v = e }
                else {
                    v = WrinklerView(me)
                    v.onDown = { _, _ in G.clickWrinkler(me) }
                    container.addSubview(v)
                    wrinklerViews[i] = v
                }
                v.drawWrinkler(i)
            } else if let v = wrinklerViews[i] {
                v.removeFromSuperview(); wrinklerViews[i] = nil
            }
        }
    }
}

/// the big cookie's touch area: a circle (border-radius:240px)
final class BigCookieTouch: TapView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let c = CGPoint(x: bounds.midX, y: bounds.midY)
        let dx = point.x - c.x, dy = point.y - c.y
        return dx * dx + dy * dy <= (bounds.width / 2) * (bounds.width / 2)
    }
}

/// .prestigeIcon.quickButton: an icon in a slot, at half size, with a caption
final class QuickButton: TapView {
    private let slot = UIImageView()
    private let iconV: IconView
    private let text = RichLabel()
    private var status = -1
    private var icon: [Int]
    init(icon: [Int]) {
        self.icon = icon
        iconV = IconView(icon)
        super.init(frame: CGRect(x: 0, y: 0, width: px(48), height: px(48)))
        clipsToBounds = false
        addSubview(iconV)
        // .prestigeIcon:before: the 88px slot frame around it, above the icon
        slot.frame = CGRect(x: -px(20), y: -px(20), width: px(88), height: px(88))
        slot.isUserInteractionEnabled = false
        addSubview(slot)
        var st = TextStyle.fancy(15, color: UIColor(css: "#fcc"))
        st.align = .center; st.shadow = Shadows.top
        text.style = st
        text.frame = CGRect(x: px(24 - 75), y: 0, width: px(150), height: px(40))
        addSubview(text)
        transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        chroma()
    }
    required init?(coder: NSCoder) { fatalError() }
    /// .chromaFocus: the caption cycles through soft pink, green and blue
    private func chroma() {
        let a = CAKeyframeAnimation(keyPath: "opacity")
        _ = a
        Timer.scheduledTimer(withTimeInterval: 1.0 / 15, repeats: true) { [weak self] t in
            guard let self = self, self.superview != nil else { t.invalidate(); return }
            let p = (nowMs() / 4000).truncatingRemainder(dividingBy: 1)
            let cols: [(CGFloat, CGFloat, CGFloat)] = [(1, 0.8, 0.8), (0.8, 1, 0.8), (0.8, 0.8, 1), (1, 0.8, 0.8)]
            let seg = min(2, Int(p * 3)), f = CGFloat(p * 3 - Double(seg))
            let e = f < 0.5 ? 2 * f * f : 1 - pow(-2 * f + 2, 2) / 2
            let a0 = cols[seg], a1 = cols[seg + 1]
            self.text.layer.opacity = 1
            self.textColor = UIColor(red: a0.0 + (a1.0 - a0.0) * e, green: a0.1 + (a1.1 - a0.1) * e, blue: a0.2 + (a1.2 - a0.2) * e, alpha: 1)
        }
    }
    private var textColor: UIColor = UIColor(css: "#fcc") { didSet { if !lastText.isEmpty { text.style.color = textColor } } }
    private var lastText = ""
    func setText(_ s: String) {
        if s == lastText { return }
        lastText = s
        text.html = s
        let h = text.fittingHeight(150)
        text.frame = CGRect(x: px(24 - 75), y: 0, width: px(150), height: px(h))
    }
    func setIcon(_ i: [Int]) { if i != icon { icon = i; iconV.icon = i } }
    /// prestigeStatus1 (faded, can't press), 2 (dimmed icon), 3 (full slot, squishing)
    func setStatus(_ v: Int) {
        if v == status { return }
        status = v
        switch v {
        case 1:
            // prestigeStatus1 (on a .quickButton: still fully visible and pressable)
            alpha = 1
            isUserInteractionEnabled = true
            slot.image = Res.sprite("img/ascendSlot.png", x: 88, y: 0, w: 88, h: 88)
            iconV.alpha = 1
            Anim.squish(iconV, on: false)
        case 2:
            alpha = 1
            isUserInteractionEnabled = true
            slot.image = Res.sprite("img/ascendSlot.png", x: 0, y: 0, w: 88, h: 88)
            iconV.alpha = 1
            Anim.squish(iconV, on: true)
        default:
            alpha = 1
            isUserInteractionEnabled = true
            slot.image = Res.sprite("img/ascendSlot.png", x: 88, y: 0, w: 88, h: 88)
            iconV.alpha = 0.5   // filter:brightness(50%)
            iconV.backgroundColor = .clear
            Anim.squish(iconV, on: false)
        }
    }
}

/// a golden cookie or reindeer (.shimmer)
final class ShimmerView: TapView {
    let me: Shimmer
    private let pic = UIImageView()
    init(_ me: Shimmer) {
        self.me = me
        super.init(frame: .zero)
        pic.isUserInteractionEnabled = false
        pic.contentMode = .scaleToFill
        addSubview(pic)
        alpha = 0
        if me.type.name == "golden" { buildGolden() } else { buildReindeer() }
    }
    required init?(coder: NSCoder) { fatalError() }
    private func buildGolden() {
        bounds = CGRect(x: 0, y: 0, width: px(me.s), height: px(me.s))
        pic.frame = bounds
        var file = "goldCookie.png"
        var frames: (Int, Int)? = nil   // columns, picked column
        switch G.season {
        case "easter": file = "bunnies.png"; frames = (4, Int(JSMath.random() * 4))
        case "halloween": file = "familiars.png"; frames = (4, Int(JSMath.random() * 4))
        case "valentines": file = "hearts.png"; frames = (8, Int(JSMath.random() * 8))
        case "fools": file = "spamCookies.gif"; frames = (4, Int(JSMath.random() * 4))
        case "christmas": file = me.wrath ? "wrathCookieWreath.png" : "goldCookieWreath.png"
        default: if me.wrath { file = "wrathCookie.png" }
        }
        let path = "img/" + file
        if let (cols, col) = frames, let img = Res.image(path) {
            let fw = Double(img.size.width) / Double(cols), fh = Double(img.size.height) / 2
            let row = (me.wrath && !(G.season == "fools" && G.getSet("notScary") != 0)) ? 1.0 : 0
            pic.image = Res.sprite(path, x: Double(col) * fw, y: row * fh, w: fw, h: fh)
        } else {
            pic.image = Res.image(path)
        }
    }
    private func buildReindeer() {
        bounds = CGRect(x: 0, y: 0, width: px(me.s * 167), height: px(me.s * 212))
        pic.frame = bounds
        pic.image = Res.image("img/frostedReindeer.png")
    }
    func drawShimmer() {
        if me.type.name == "golden" {
            let curve = 1 - pow((me.t / (G.fps * me.dur)) * 2 - 1, 4)
            alpha = CGFloat(curve)
            transform = .identity
            center = CGPoint(x: px(me.x), y: px(me.y))
            if G.season != "fools" {
                let k = CGFloat(me.s / 96)
                transform = CGAffineTransform(scaleX: k, y: k).rotated(by: CGFloat((me.r + sin(Double(G.T) * 0.25 + Double(me.id)) * 8) * .pi / 180))
            }
        } else {
            // reindeer: the engine moved it (type.draw sets x/y), drawn at 60%
            let r = 1 - me.t / (G.fps * me.dur)
            me.x = (G.w + 167) * r + sin(Double(G.T) * 0.1 + Double(me.id)) * 32 - 167 / 2
            me.y = (G.h + 212) * r - abs(cos(Double(G.T) * 0.1 + Double(me.id)) * 16) - 212 / 2
            alpha = 1
            transform = .identity
            // translate(x-167/2, y-212/2) of a (s*167 x s*212) box, rotated and scaled about its centre
            center = CGPoint(x: px(me.x - 167 / 2 + me.s * 167 / 2), y: px(me.y - 212 / 2 + me.s * 212 / 2))
            transform = CGAffineTransform(rotationAngle: CGFloat((sin(Double(G.T) * 0.1 + Double(me.id) + Double.pi * 0.2) * 16 + 8) * .pi / 180)).scaledBy(x: 0.6, y: 0.6)
        }
    }
}

/// .wrinkler: 100x200, turning about (50%,10%)
final class WrinklerView: TapView {
    let me: Wrinkler
    private let pic = UIImageView()
    private let googly = UIImageView()
    init(_ me: Wrinkler) {
        self.me = me
        super.init(frame: CGRect(x: 0, y: 0, width: px(100), height: px(200)))
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.1)
        pic.frame = bounds
        pic.isUserInteractionEnabled = false
        var file = "img/wrinkler.png"
        if G.season == "christmas" { file = "img/winterWrinkler.png" }
        if me.type == 1 { file = "img/shinyWrinkler.png" }
        pic.image = Res.image(file)
        addSubview(pic)
        if G.getSet("notScary") != 0 {
            googly.frame = bounds
            googly.image = Res.image("img/wrinklerGooglies.png")
            addSubview(googly)
        }
        alpha = 0
    }
    required init?(coder: NSCoder) { fatalError() }
    private var wasBlinky = false
    func drawWrinkler(_ i: Int) {
        if googly.superview != nil && me.blinky != wasBlinky {
            wasBlinky = me.blinky
            googly.image = Res.image(me.blinky ? "img/wrinklerBlink.png" : "img/wrinklerGooglies.png")
        }
        transform = .identity
        // translate(x-50, y-10) of the box whose turning point is (50, 20)
        center = CGPoint(x: px(me.x - 50 + 50), y: px(me.y - 10 + 20))
        let deg = -me.r / Double.pi / 2 * 360 + me.hurt * sin(Double(G.T) * 1 + me.seed * 97) * 18
        transform = CGAffineTransform(rotationAngle: CGFloat(deg * .pi / 180)).scaledBy(x: CGFloat(me.s), y: CGFloat(me.s))
        alpha = CGFloat(me.close)
        layer.zPosition = 100
    }
}
