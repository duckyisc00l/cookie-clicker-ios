import UIKit

/// A screen (G.screens): built when shown, cleaned when left.
class GameScreen {
    let name: String
    let view = PassView()
    init(name: String) { self.name = name; view.clipsToBounds = false }
    /// width/height of the screen in CSS px
    var w: Double { Double(view.bounds.width / K) }
    var h: Double { Double(view.bounds.height / K) }
    func build() {}
    func clean() {}
    func draw() {}
    func relayout() { clean(); view.subviews.forEach { $0.removeFromSuperview() }; build() }
}

/// a view that lets touches through where it has nothing of its own (pointer-events:none containers)
class PassView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let v = super.hitTest(point, with: event)
        return v === self ? nil : v
    }
}

/// #game: everything on screen.
final class RootView: UIView, GameUI {
    weak var host: GameViewController?

    // z-index 0, in page order: #back, #back2, #backShade, #rain, #milk
    let back = PatternView("img/bgBlue.jpg")
    let back2 = PatternView("img/bgBlue.jpg")
    let backShade = PicView("img/shadedEdges.png")
    let rain = RainView()
    let milk = PatternView("img/milkPlain.png")
    /// #screens (z-index 1)
    let screensL = PassView()
    /// #tabs (z-index 1000)
    let tabs = TabsView()
    /// #topStuff (z-index 10000)
    let top = TopStuffView()
    let sparkles = SparklesView()

    var screens: [String: GameScreen] = [:]
    var current: GameScreen?
    private var lastMilkPic = ""
    private var lastBG = BGState(pic1: "", pic2: "", ratio: -1)
    private var built = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        clipsToBounds = true
        isMultipleTouchEnabled = true
        TextMeasure.tickerWidth = { html in
            let s = RichText.render(html, style: .ticker)
            return Double(RichText.size(s, width: nil).width)
        }
        for v in [back, back2, backShade, rain, milk, screensL, tabs, top, sparkles] as [UIView] { addSubview(v) }
        back2.isHidden = true
        milk.alpha = 0.8
        milk.tileSize = CGSize(width: 240, height: 240)
        screensL.clipsToBounds = true
        let obs = TouchObserver(target: nil, action: nil)
        obs.cancelsTouchesInView = false
        obs.delaysTouchesBegan = false
        obs.delaysTouchesEnded = false
        addGestureRecognizer(obs)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: building
    func build() {
        built = true
        screens = [
            "cookie": CookieScreen(),
            "store": StoreScreen(),
            "special": SpecialScreen(),
            "stats": StatsScreen(),
            "misc": MiscScreen(),
        ]
        for n in G.screenNames { if let s = screens[n] { s.view.isHidden = true; screensL.addSubview(s.view) } }
        tabs.build(self)
        top.build(self)
        layoutAll()
        screenChanged(from: "", to: G.onScreen)
    }
    func relayout() {
        guard built else { return }
        layoutAll()
        current?.relayout()
    }
    private func layoutAll() {
        let W = bounds.width, H = bounds.height
        // #back,#back2: left/right/top/bottom -20%
        for b in [back, back2] {
            b.transform = .identity
            b.frame = CGRect(x: -W * 0.2, y: -H * 0.2, width: W * 1.4, height: H * 1.4)
        }
        backShade.frame = bounds
        screensL.frame = CGRect(x: 0, y: px(Layout.sat), width: W, height: H - px(Layout.sat) - px(40 + Layout.sab))
        for s in screens.values { s.view.frame = screensL.bounds }
        tabs.frame = CGRect(x: 0, y: H - px(40 + Layout.sab), width: W, height: px(40 + Layout.sab))
        tabs.layout()
        top.frame = CGRect(x: 0, y: px(Layout.sat), width: W, height: H - px(Layout.sat + Layout.sab))
        top.layout()
        rain.layoutRain()
        milk.transform = .identity
        milk.frame = CGRect(x: 0, y: H - px(240), width: px(640), height: px(240))
        sparkles.frame = CGRect(x: 0, y: 0, width: px(128), height: px(128))
    }

    // MARK: G.Draw (www/main.js)
    func draw() {
        guard built else { return }
        G.drawT += 1
        if G.onAscend > 0 {
        } else {
            top.drawCounters()
            top.drawBuffs()
            if G.drawT % 10 == 0 { G.updateBG(false) }
            applyBG()
            if G.getSet("milk") != 0 {
                milk.isHidden = false
                let pic = G.milkPic
                if pic != lastMilkPic { milk.path = "img/\(pic).png"; lastMilkPic = pic }
                let tx = -(Double(G.T) * 0.5).truncatingRemainder(dividingBy: 240)
                let ty = 240 * (1 - G.milkLevel) - 35 - (G.bigCookieSize - 1) * 20
                milk.transform = CGAffineTransform(translationX: px(tx), y: px(ty))
            } else { milk.isHidden = true }
            rain.drawFrame()
            if G.getSet("particles") != 0 { G.particlesDraw(); top.particles.draw() }
            top.drawTicker()
            if G.drawT % 5 == 0 { StoreScreen.redrawSome() }
            current?.draw()
        }
        sparkles.draw()
        top.popups.tick()
    }

    func applyBG() {
        let bg = G.bg
        if bg != lastBG {
            back.path = "img/\(bg.pic1).jpg"
            if bg.ratio == 0 { back2.isHidden = true }
            else {
                back2.isHidden = false
                back2.path = "img/\(bg.pic2).jpg"
                back2.alpha = CGFloat(bg.ratio)
            }
            lastBG = bg
        }
    }
    /// #back/#back2 scale (set by the cookie screen while wobbling)
    func setBackScale(_ s: Double) {
        let t = CGAffineTransform(scaleX: CGFloat(s), y: CGFloat(s))
        back.transform = t; back2.transform = t
    }

    // MARK: screens (G.setScreen's page part)
    func screenChanged(from old: String, to new: String) {
        guard built, let me = screens[new] else { return }
        let oldS = screens[old]
        if let o = oldS {
            o.clean()
            let oi = G.screenNames.firstIndex(of: old) ?? 0, ni = G.screenNames.firstIndex(of: new) ?? 0
            if o !== me {
                if G.getSet("lowMotion") == 0 && oi != ni {
                    let ov = o.view
                    Anim.switchAnim(ov, oi < ni ? "switchLeft" : "switchRight", completion: {
                        if G.onScreen != old { ov.isHidden = true; ov.subviews.forEach { $0.removeFromSuperview() } }
                        ov.layer.removeAllAnimations()
                    })
                    Anim.switchAnim(me.view, oi < ni ? "switchRightIn" : "switchLeftIn")
                } else {
                    o.view.isHidden = true
                    o.view.subviews.forEach { $0.removeFromSuperview() }
                }
                o.view.isUserInteractionEnabled = false
            }
        }
        tabs.update()
        me.view.isHidden = false
        me.view.isUserInteractionEnabled = true
        me.view.subviews.forEach { $0.removeFromSuperview() }
        me.view.layer.zPosition = 1
        oldS?.view.layer.zPosition = 0
        current = me
        top.setBuffsMode(tall: new == "cookie")
        me.build()
        milk.layer.zPosition = 0
    }
    /// the milk goes above the cookie while it's dragged around
    func setMilkOnTop(_ on: Bool) {
        if on { bringSubviewToFront(milk); bringSubviewToFront(tabs); bringSubviewToFront(top); bringSubviewToFront(sparkles) }
        else { insertSubview(milk, aboveSubview: rain) }
    }

    // MARK: GameUI
    func toast(title: String, top t: String, icon: [Int]?, reverse: Bool) { top.toasts.toast(title: title, top: t, icon: icon, reverse: reverse) }
    func plopBuff(_ name: String) { top.plopBuff(name) }
    func plopQuickButton(_ name: String, heavy: Bool) { (screens["cookie"] as? CookieScreen)?.plopQuickButton(name, heavy: heavy) }
    func settingChanged(_ name: String) {
        switch name {
        case "shadows", "fancy", "cursors", "milk", "notScary":
            if name == "notScary" { G.updateBG(true); lastBG = BGState(pic1: "", pic2: "", ratio: -1) }
            if G.onScreen == "cookie" || name == "shadows" { current?.relayout() }
        default: break
        }
    }
    func closeAllPopups() { top.popups.closeAll() }
    func closeAllToasts() { top.toasts.closeAll() }
    func showAscend(_ mode: Int) { top.popups.showAscend(mode) }
}

// MARK: - touch tracking (the capture-phase touch handlers on #game)

final class TouchObserver: UIGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        guard let v = view else { return }
        let all = event.touches(for: v) ?? touches
        if all.count == 1, let t = touches.first {
            G.panFrom = Double(G.screenNames.firstIndex(of: G.onScreen) ?? 0) * G.panStep
            let p = t.location(in: v)
            G.fromX = Double(p.x / K); G.fromY = Double(p.y / K) - Layout.sat
            G.onX = G.fromX; G.onY = G.fromY
            G.velX = 0; G.velY = 0
            G.dragging = true
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard let v = view, let t = touches.first else { return }
        let p = t.location(in: v)
        G.onX = Double(p.x / K); G.onY = Double(p.y / K) - Layout.sat
        G.velX = G.onX - G.fromX
        G.velY = G.onY - G.fromY
        let all = event.touches(for: v) ?? touches
        if G.canPan && all.count == 1 {
            let dx = G.velX, dy = G.velY
            if G.getSet("pan") != 0 && G.onPopup == 0 && abs(dy) < G.panStep / 2 {
                G.panTo = G.panFrom - (abs(dx) < G.panStep ? dx * 1.5 : dx)
                G.panning = true
            }
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        end(touches, event)
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        end(touches, event)
    }
    private func end(_ touches: Set<UITouch>, _ event: UIEvent) {
        // the click handlers run before this (touchend → click), so panning is cleared afterwards
        DispatchQueue.main.async {
            G.panning = false
        }
        guard let v = view else { return }
        let remaining = (event.touches(for: v) ?? []).filter { $0.phase != .ended && $0.phase != .cancelled }
        if remaining.isEmpty {
            G.panFrom = 0
            G.dragging = false
            G.canPan = true
            G.velX = 0; G.velY = 0
            state = .failed
        }
    }
    override func reset() { super.reset() }
    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool { false }
    override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool { false }
}

// MARK: - #tabs: the five screen tabs on the bottom shelf

final class TabsView: UIView {
    private let shelf = PicView("img/bottomShelf.png")
    private let shelfMirror = UIView()
    private let shelfMirrorPic = PicView("img/bottomShelf.png")
    private var tabViews: [TabView] = []
    func build(_ root: RootView) {
        clipsToBounds = false
        addSubview(shelf)
        shelfMirror.clipsToBounds = true
        shelfMirror.isUserInteractionEnabled = false
        shelfMirror.addSubview(shelfMirrorPic)
        addSubview(shelfMirror)
        let names = ["Cookie", "Store", "Special", "Stats", "Misc"]
        for (i, n) in G.screenNames.enumerated() {
            let t = TabView(icon: i, name: names[i])
            t.onTap = { v in
                if !G.panning {
                    Anim.trigger(v, "plop")
                    G.setScreen(n)
                }
            }
            tabViews.append(t)
            addSubview(t)
        }
    }
    func layout() {
        // .bottomShelf:before, bottom: calc(var(--cc-sab) - 3px)
        shelf.frame = CGRect(x: 0, y: px(43 - 73), width: px(320), height: px(73))
        // the mirrored shelf under it, filling the home-bar area
        shelfMirror.frame = CGRect(x: 0, y: px(40), width: px(320), height: px(Layout.sab))
        shelfMirrorPic.frame = CGRect(x: 0, y: px(-3), width: px(320), height: px(73))
        shelfMirrorPic.transform = CGAffineTransform(scaleX: 1, y: -1)
        shelfMirrorPic.frame = CGRect(x: 0, y: px(-3), width: px(320), height: px(73))
        for (i, t) in tabViews.enumerated() {
            t.bounds = CGRect(x: 0, y: 0, width: px(64), height: px(40))
            t.baseCenter = CGPoint(x: px(Double(i) * 64 + 32), y: px(20))
            t.layoutTab()
        }
        update()
    }
    func update() {
        for (i, t) in tabViews.enumerated() {
            let n = G.screenNames[i]
            t.setOn(n == G.onScreen)
            t.setPing(G.screenPing[n] == true)
        }
    }
}

final class TabView: TapView {
    private let backdrop = PicView("img/shadedBackdrop.png")
    private let icon = UIImageView()
    private let nameL = RichLabel(TextStyle.fancy(12, color: .ccText))
    private let ping = PicView("img/pingDot.png")
    private let iconIndex: Int
    var baseCenter: CGPoint = .zero
    private var isOn = false
    init(icon: Int, name: String) {
        iconIndex = icon
        super.init(frame: .zero)
        backdrop.isHidden = true
        addSubview(backdrop)
        self.icon.isUserInteractionEnabled = false
        addSubview(self.icon)
        nameL.style.shadow = Shadows.tabs
        nameL.style.nowrap = true
        nameL.html = name
        addSubview(nameL)
        ping.isHidden = true
        addSubview(ping)
    }
    required init?(coder: NSCoder) { fatalError() }
    func layoutTab() {
        center = CGPoint(x: baseCenter.x, y: baseCenter.y - (isOn ? px(3) : 0))
        backdrop.frame = bounds
        // 128px icon at scale(0.25) from its top centre: 32x32, top at 40-44 = -4 (on: -7, the tab itself moves up 3)
        icon.frame = CGRect(x: px(16), y: px(-4), width: px(32), height: px(32))
        icon.image = Res.sprite("img/tabIcons.png", x: Double(iconIndex * 128), y: isOn ? 0 : 128, w: 128, h: 128)
        let sz = nameL.textSize
        nameL.frame = CGRect(x: (bounds.width - sz.width * K) / 2, y: px(40 - 4 - 12), width: sz.width * K + 2, height: px(14))
        // .tab.ping:after: left 50%, top -4px, margin-left 8px
        ping.frame = CGRect(x: px(32 + 8), y: px(-4), width: px(16), height: px(16))
    }
    func setOn(_ on: Bool) {
        let changed = on != isOn
        isOn = on
        backdrop.isHidden = !on
        nameL.style.color = on ? .white : .ccText
        if changed {
            UIView.animate(withDuration: 0.2) { self.center = CGPoint(x: self.baseCenter.x, y: self.baseCenter.y - (on ? px(3) : 0)) }
            icon.image = Res.sprite("img/tabIcons.png", x: Double(iconIndex * 128), y: on ? 0 : 128, w: 128, h: 128)
            layer.zPosition = on ? 1 : 0
        }
    }
    func setPing(_ on: Bool) { ping.isHidden = !on }
}

// MARK: - #rain: the canvas behind the cookie (cookie pops, snow, hearts, explosion)

final class RainView: UIView {
    private var ctx: CGContext?
    private var cw = 0.0, ch = 0.0   // canvas size in its own units
    private var pxScale: CGFloat = 1
    private let scaleBase = 2.0      // G.rainScale
    private var empty = true
    var extraScale: Double = 1.1 { didSet { if extraScale != oldValue { applyTransform() } } }
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        layer.contentsGravity = .resize
    }
    required init?(coder: NSCoder) { fatalError() }
    /// G.stabilizeResize: width=w/2, height=h/2-18, left/top 25%, margin-top -10px
    func layoutRain() {
        // positioned in the whole screen, like the web version
        cw = G.w / scaleBase
        ch = G.fullH / scaleBase - 18
        transform = .identity
        frame = CGRect(x: px(G.w * 0.25), y: px(G.fullH * 0.25 - 10), width: px(cw), height: px(ch))
        // the web version gave the canvas device pixels for its CSS size (before the 2x zoom)
        pxScale = K * UIScreen.main.scale
        let pw = Int(CGFloat(cw) * pxScale), ph = Int(CGFloat(ch) * pxScale)
        guard pw > 0, ph > 0 else { return }
        ctx = CGContext(data: nil, width: pw, height: ph, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        ctx?.translateBy(x: 0, y: CGFloat(ph))
        ctx?.scaleBy(x: pxScale, y: -pxScale)
        ctx?.interpolationQuality = .high
        applyTransform()
    }
    private func applyTransform() {
        transform = CGAffineTransform(scaleX: CGFloat(scaleBase * extraScale), y: CGFloat(scaleBase * extraScale))
    }
    /// draws an image (or part of it) like ctx.drawImage, in canvas units, with the y axis pointing down
    private func drawImage(_ c: CGContext, _ img: UIImage?, src: CGRect? = nil, _ dst: CGRect) {
        guard let img = img, var cg = img.cgImage else { return }
        if let s = src {
            let sc = img.scale
            guard let piece = cg.cropping(to: CGRect(x: s.minX * sc, y: s.minY * sc, width: s.width * sc, height: s.height * sc)) else { return }
            cg = piece
        }
        c.saveGState()
        c.translateBy(x: dst.minX, y: dst.maxY)
        c.scaleBy(x: 1, y: -1)
        c.draw(cg, in: CGRect(x: 0, y: 0, width: dst.width, height: dst.height))
        c.restoreGState()
    }
    private func fillPattern(_ c: CGContext, _ img: UIImage?, _ X: Double, _ Y: Double, _ W: Double, _ H: Double, _ iW: Double, _ iH: Double, _ offXIn: Double, _ offYIn: Double) {
        guard let img = img else { return }
        var offX = offXIn, offY = offYIn
        if offX < 0 { offX = offX - (offX / iW).rounded(.down) * iW }
        if offX > 0 { offX = offX.truncatingRemainder(dividingBy: iW) - iW }
        if offY < 0 { offY = offY - (offY / iH).rounded(.down) * iH }
        if offY > 0 { offY = offY.truncatingRemainder(dividingBy: iH) - iH }
        var y = offY
        while y < H {
            var x = offX
            while x < W { drawImage(c, img, CGRect(x: X + x, y: Y + y, width: iW, height: iH)); x += iW }
            y += iH
        }
    }

    /// the canvas part of G.Draw
    func drawFrame() {
        guard let c = ctx else { return }
        let w = cw, h = ch, scale = scaleBase
        var drew = false
        if G.getSet("particles") != 0 {
            if !empty {
                c.saveGState()
                c.setBlendMode(.destinationOut)
                c.setFillColor(UIColor(white: 0, alpha: 0.1).cgColor)
                c.fill(CGRect(x: 0, y: 0, width: w, height: h))
                c.restoreGState()
                drew = true
            }
            // cookies popping up randomly
            if G.explodeT == -1 && G.getSet("cookiepops") != 0 && G.cookiesPs > 0 {
                let period = Int((90 - pow(min(G.cookiesPs, 1000) / 1000, 0.5) * 90 + 1).rounded(.up))
                let pic = Res.image("img/smallCookies.png")
                if G.getSet("fancy") != 0 && G.getSet("lowMotion") == 0 {
                    for i in 0..<3 {
                        if (G.drawT - i) % period > 0 { continue }
                        JSMath.seedrandom("cookiepops-\(G.drawT - i)")
                        let s = (JSMath.random() * 0.5 + 0.25) * (i == 0 ? 0.6 : i == 1 ? 0.95 : 1) * 128 / scale
                        let tx = JSMath.random() * w, ty = JSMath.random() * h
                        let rot = JSMath.random() * Double.pi * 2
                        let fx = (JSMath.random() * 8).rounded(.down) * 64
                        c.saveGState()
                        c.translateBy(x: CGFloat(tx), y: CGFloat(ty))
                        c.rotate(by: CGFloat(rot))
                        drawImage(c, pic, src: CGRect(x: fx, y: 0, width: 64, height: 64), CGRect(x: -s / 2, y: -s / 2, width: s, height: s))
                        c.restoreGState()
                        drew = true
                    }
                    JSMath.seedrandom()
                } else if G.drawT % period == 0 {
                    let s = (JSMath.random() * 0.5 + 0.25) * 128 / scale
                    let tx = JSMath.random() * w, ty = JSMath.random() * h
                    let rot = JSMath.random() * Double.pi * 2
                    let fx = (JSMath.random() * 8).rounded(.down) * 64
                    c.saveGState()
                    c.translateBy(x: CGFloat(tx), y: CGFloat(ty))
                    c.rotate(by: CGFloat(rot))
                    drawImage(c, pic, src: CGRect(x: fx, y: 0, width: 64, height: 64), CGRect(x: -s / 2, y: -s / 2, width: s, height: s))
                    c.restoreGState()
                    drew = true
                }
            }
            if G.season == "christmas" {
                let s = 512 / scale
                let x = (Double(G.T) * 0.06 / scale).truncatingRemainder(dividingBy: s)
                let y = (Double(G.T) * 0.2 / scale).truncatingRemainder(dividingBy: s)
                c.saveGState(); c.setAlpha(0.1); c.setBlendMode(.plusLighter)
                fillPattern(c, Res.image("img/snow2\(G.elderWrath >= 3 ? "Wrath" : "").jpg"), 0, 0, w, h, s, s, x, y)
                c.restoreGState(); drew = true
            }
            if G.season == "valentines" {
                let s = 512 / scale
                let x = (-Double(G.T) * 0.034 / scale).truncatingRemainder(dividingBy: s)
                let y = (Double(G.T) * 0.2 / scale).truncatingRemainder(dividingBy: s)
                c.saveGState(); c.setAlpha(0.3)
                fillPattern(c, Res.image("img/heartStorm\(G.elderWrath >= 3 ? "Wrath" : "").png"), 0, 0, w, h, s, s, x, y)
                c.restoreGState(); drew = true
            }
        }
        let cookieX = w / 2, cookieY = (h - 8) / 2
        c.saveGState()
        c.translateBy(x: CGFloat(cookieX), y: CGFloat(cookieY))
        if G.explodeT > -1 {
            drew = true
            drawExplosion(c, w: w, h: h, cookieX: cookieX, cookieY: cookieY, scale: scale)
        } else {
            if G.hasBuff("dragonflight") != nil || G.hasBuff("dragonHarvest") != nil {
                let s = 300 * 2 * (1 + sin(Double(G.T) * 0.013) * 0.2) * 0.7 / scale
                let x = -s / 2
                let y = -s / (1.4 + 0.2 * sin(Double(G.T) * 0.01))
                drawImage(c, Res.image("img/dragonBG2.png"), CGRect(x: x, y: y, width: s, height: s))
                drew = true
            }
            if G.season == "easter" && G.onScreen == "cookie" {
                let nestW = 304 * 0.98 * 0.8 / scale, nestH = 161 * 0.98 * 0.8 / scale
                drawImage(c, Res.image("img/nest.png"), CGRect(x: -nestW / 2, y: -nestH / 2 + (120 + sin(Double(G.T) * 0.1) * 3) / scale, width: nestW, height: nestH))
                drew = true
            }
        }
        c.restoreGState()
        if drew || !empty {
            layer.contents = c.makeImage()
            empty = !drew && G.getSet("particles") == 0
            if !drew { fadeFrames += 1; if fadeFrames > 60 { empty = true; c.clear(CGRect(x: 0, y: 0, width: w, height: h)); layer.contents = nil } } else { fadeFrames = 0 }
        }
    }
    private var fadeFrames = 0

    private func drawExplosion(_ c: CGContext, w: Double, h: Double, cookieX: Double, cookieY: Double, scale: Double) {
        JSMath.seedrandom(G.seed + "-explodeAnim3")
        let explosionSeed = JSMath.random() * 29
        JSMath.seedrandom()
        var x = 0.0, y = 0.0
        let fps = G.fps
        let et = Double(G.explodeT)
        let timeline = min(et / (fps * 2), 1)
        let isCracking = et < fps * 2
        let post = max((et - fps * 2) / fps, 0)
        c.saveGState()
        c.setAlpha(CGFloat(timeline))
        var s = 1024 / scale
        fillPattern(c, Res.image("img/starbg.jpg"), -cookieX, -cookieY, w, h, s, s, x, y)
        c.restoreGState()
        c.setFillColor(UIColor(red: 15 / 255, green: 15 / 255, blue: 15 / 255, alpha: CGFloat(post)).cgColor)
        c.fill(CGRect(x: -cookieX, y: -cookieY, width: w, height: h))
        c.saveGState()
        c.setAlpha(CGFloat((isCracking ? timeline : pow(1 - post, 5)) * (1 - 0.2 * JSMath.random())))
        s = 512 / scale
        drawImage(c, Res.image("img/flare.png"), CGRect(x: x - s / 2, y: y - s / 2, width: s, height: s))
        c.restoreGState()
        if isCracking {
            x += 5 * (JSMath.random() - 0.5) / scale * timeline
            y += 5 * (JSMath.random() - 0.5) / scale * timeline
        }
        let halo = min(1, max(0, timeline * 2 - 0.2))
        c.saveGState()
        c.setAlpha(CGFloat(0.5 * (1 - halo)))
        s = 384 * (1 + pow(halo, 0.2) * 0.5) * 0.8 / scale
        drawImage(c, Res.image("img/brokenCookieHalo.png"), CGRect(x: x - s / 2, y: y - s / 2, width: s, height: s))
        c.restoreGState()
        let pic = Res.image("img/brokenCookie.png")
        let d = pow(post, 0.5) * 96 / scale
        c.saveGState()
        c.setAlpha(CGFloat(1 - post))
        for i in 0..<10 {
            let di = Double(i)
            let s = 256 * (isCracking ? 1 : (1 - 0.5 * post)) * (0.8 + sin(Double(G.T) * 1.8 + di + explosionSeed * 11) * 0.03 * (isCracking ? timeline : 0)) / scale
            let dd = d * (1 + 0.2 * sin(di + 2 + explosionSeed * 17))
            let a = -Double.pi * 2 * (di / 10 + 0.42)
            if isCracking {
                let jx = 5 * (JSMath.random() - 0.5) * timeline, jy = 5 * (JSMath.random() - 0.5) * timeline
                drawImage(c, pic, src: CGRect(x: 256 * di, y: 0, width: 256, height: 256), CGRect(x: x - s / 2 + dd * sin(a) + jx, y: y - s / 2 + dd * cos(a) + jy, width: s, height: s))
            } else {
                let fall = pow(post, 4 + 2 * sin(di * 13 + explosionSeed)) * (256 * 1 + 0.75 * sin(di * 7 + explosionSeed * 7))
                drawImage(c, pic, src: CGRect(x: 256 * di, y: 0, width: 256, height: 256), CGRect(x: x - s / 2 + dd * sin(a), y: y - s / 2 + dd * cos(a) - fall, width: s, height: s))
            }
        }
        c.restoreGState()
        c.saveGState()
        c.setAlpha(CGFloat(isCracking ? (timeline * (1 - 0.3 * JSMath.random())) : pow(1 - post, 10)))
        s = 384 * 0.8 / scale
        drawImage(c, Res.image("img/brokenCookieHalo.png"), CGRect(x: x - s / 2, y: y - s / 2, width: s, height: s))
        c.restoreGState()
        if G.getSet("fancy") != 0, let snap = c.makeImage() {
            // ctx.filter='blur(3px) saturate(200%)', drawn over itself with "screen"
            if let blurred = RainView.blurSaturate(snap, radius: 3 * pxScale) {
                c.saveGState()
                c.setAlpha(CGFloat(timeline - post))
                c.setBlendMode(.screen)
                c.translateBy(x: CGFloat(-cookieX), y: CGFloat(-cookieY))
                c.translateBy(x: 0, y: CGFloat(h)); c.scaleBy(x: 1, y: -1)
                c.draw(blurred, in: CGRect(x: 0, y: 0, width: w, height: h))
                c.restoreGState()
            }
        }
    }
    private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    static func blurSaturate(_ img: CGImage, radius: CGFloat) -> CGImage? {
        let ci = CIImage(cgImage: img)
        guard let blur = CIFilter(name: "CIGaussianBlur", parameters: [kCIInputImageKey: ci, kCIInputRadiusKey: radius]),
              let out1 = blur.outputImage?.cropped(to: ci.extent),
              let sat = CIFilter(name: "CIColorControls", parameters: [kCIInputImageKey: out1, kCIInputSaturationKey: 2]),
              let out = sat.outputImage else { return nil }
        return ciContext.createCGImage(out, from: ci.extent)
    }
}

// MARK: - #sparkles: a 16-frame sparkle (screen blend) shown where something good happened

final class SparklesView: UIView {
    private let img = UIImageView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        clipsToBounds = true
        isHidden = true
        img.image = Res.image("img/sparkles.jpg")
        addSubview(img)
        layer.compositingFilter = "screenBlendMode"
    }
    required init?(coder: NSCoder) { fatalError() }
    func draw() {
        if G.sparklesT > 1 {
            isHidden = false
            frame = CGRect(x: px(G.sparkleX), y: px(G.sparkleY), width: px(128), height: px(128))
            let f = Double(G.sparklesFrames - G.sparklesT + 1)
            let size = img.image?.size ?? CGSize(width: 2048, height: 128)
            img.frame = CGRect(x: -px(f * 128), y: 0, width: px(size.width), height: px(size.height))
        } else if !isHidden { isHidden = true }
    }
}
