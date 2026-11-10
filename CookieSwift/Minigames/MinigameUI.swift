import UIKit

// The minigame window (mods/minigame-bridge.js #ccMinigame and mods/minigames/*.css): a wooden bar with the
// minigame's name and Close, the minigame below, info boxes docked at the bottom, prompts in the middle.

/// what a minigame's screen provides
protocol MinigameScreen: UIView {
    /// lays out for a width in CSS px, returns the height
    func layoutContent(width: Double, minHeight: Double) -> Double
    /// called every frame while shown (M.draw)
    func drawFrame()
}

/// desktop text helpers (loc() with English plurals)
enum Loc {
    static func n(_ v: Double, _ one: String, _ many: String) -> String { "\(B(v)) \(v == 1 ? one : many)" }
    static func cookies(_ v: Double) -> String { n(v, "cookie", "cookies") }
    static func lumps(_ v: Double) -> String { n(v, "sugar lump", "sugar lumps") }
    /// Game.sayTime (time in frames)
    static func sayTime(_ timeIn: Double, _ detail: Int = 0) -> String {
        if timeIn <= 0 { return "" }
        let fps = G.fps
        let time = timeIn.rounded(.down)
        func unit(_ v: Double, _ u: String) -> String { "\(B(v)) \(u)\(v == 1 ? "" : "s")" }
        if detail == -1 {
            var days = 0.0, hours = 0.0, minutes = 0.0, seconds = 0.0
            if time >= fps * 60 * 60 * 24 { days = (time / (fps * 60 * 60 * 24)).rounded(.down) }
            if time >= fps * 60 * 60 { hours = (time / (fps * 60 * 60)).rounded(.down) }
            if time >= fps * 60 { minutes = (time / (fps * 60)).rounded(.down) }
            if time >= fps { seconds = (time / fps).rounded(.down) }
            hours -= days * 24
            minutes -= hours * 60 + days * 24 * 60
            seconds -= minutes * 60 + hours * 60 * 60 + days * 24 * 60 * 60
            if days > 10 { hours = 0 }
            if days > 0 { minutes = 0; seconds = 0 }
            if hours > 0 { seconds = 0 }
            var bits: [String] = []
            if days > 0 { bits.append(unit(days, "day")) }
            if hours > 0 { bits.append(unit(hours, "hour")) }
            if minutes > 0 { bits.append(unit(minutes, "minute")) }
            if seconds > 0 { bits.append(unit(seconds, "second")) }
            return bits.isEmpty ? "less than 1 second" : bits.joined(separator: ", ")
        }
        if time >= fps * 60 * 60 * 24 && detail < 2 { return unit((time / (fps * 60 * 60 * 24)).rounded(.down), "day") }
        if time >= fps * 60 * 60 && detail < 3 { return unit((time / (fps * 60 * 60)).rounded(.down), "hour") }
        if time >= fps * 60 && detail < 4 { return unit((time / (fps * 60)).rounded(.down), "minute") }
        if time >= fps && detail < 5 { return unit((time / fps).rounded(.down), "second") }
        return "less than 1 second"
    }
}

/// .framed (desktop): darkNoise with soft shaded borders, a bevelled gold edge
final class DesktopFrame: UIView {
    private let noise = PatternView("img/darkNoise.jpg")
    private let shade = PicView("mgimg/shadedBordersSoft.png")
    private let edge = CAShapeLayer()
    var radius: CGFloat = 2 { didSet { setNeedsLayout() } }
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        clipsToBounds = false
        let inner = UIView()
        inner.clipsToBounds = true
        inner.tag = 9
        inner.addSubview(noise); inner.addSubview(shade)
        addSubview(inner)
        // box-shadow:0 0 1px 2px rgba(0,0,0,0.5),0 2px 4px rgba(0,0,0,0.25)
        layer.shadowColor = UIColor.black.cgColor; layer.shadowOpacity = 0.6; layer.shadowRadius = px(2); layer.shadowOffset = CGSize(width: 0, height: px(1))
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = px(radius)
        if let inner = viewWithTag(9) {
            inner.frame = bounds; inner.layer.cornerRadius = px(radius)
            noise.frame = inner.bounds; shade.frame = inner.bounds
            sendSubviewToBack(inner)
        }
        drawEdge()
    }
    private func drawEdge() {
        layer.sublayers?.filter { $0.name == "edge" }.forEach { $0.removeFromSuperlayer() }
        let b = bounds, w = px(1)
        // border colours: top #ece2b6, right #875526, bottom #733726, left #dfbc9a
        let sides: [(CGRect, String)] = [
            (CGRect(x: 0, y: 0, width: b.width, height: w), "#ece2b6"),
            (CGRect(x: b.width - w, y: 0, width: w, height: b.height), "#875526"),
            (CGRect(x: 0, y: b.height - w, width: b.width, height: w), "#733726"),
            (CGRect(x: 0, y: 0, width: w, height: b.height), "#dfbc9a"),
        ]
        for (r, c) in sides {
            let l = CALayer(); l.name = "edge"; l.frame = r; l.backgroundColor = UIColor(css: c).cgColor
            layer.addSublayer(l)
        }
        // inset: 0 0 2px 2px #000, 0 1px 0 1px rgba(255,255,255,0.5)
        let hi = CALayer(); hi.name = "edge"; hi.frame = CGRect(x: w * 2, y: w, width: b.width - w * 4, height: w); hi.backgroundColor = UIColor(white: 1, alpha: 0.5).cgColor
        layer.addSublayer(hi)
        let dark = CAShapeLayer(); dark.name = "edge"
        dark.path = UIBezierPath(roundedRect: b.insetBy(dx: w * 2, dy: w * 2), cornerRadius: px(radius)).cgPath
        dark.fillColor = UIColor.clear.cgColor; dark.strokeColor = UIColor.black.withAlphaComponent(0.8).cgColor; dark.lineWidth = w * 2
        layer.addSublayer(dark)
    }
}

/// #ccMinigame: the minigame window
final class MinigameWindow: UIView {
    static weak var current: MinigameWindow?
    let buildingName: String
    let bar = UIView()
    let title = RichLabel(TextStyle.fancy(20))
    let close = CCButton("Close", look: .popupClose, font: { var f = TextStyle.fancy(14, color: .ccText); f.shadow = Shadows.body; return f }(), padding: UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0))
    let scroll = ScrollArea()
    let screen: MinigameScreen
    private let tipDock = UIView()
    private let tipFrame = DesktopFrame()
    private let tipText = RichLabel()
    private let tipIcon = IconView()
    private let tipHint = RichLabel()
    private var tipFunc: (() -> (String, [Int]?))?
    private var promptView: UIView?
    /// where the finger last touched, in this window (Game.mouseX/Y)
    var mouse: CGPoint = .zero

    init(building: String, screen: MinigameScreen) {
        buildingName = building
        self.screen = screen
        super.init(frame: .zero)
        backgroundColor = .black
        let noise = PatternView("img/darkNoise.jpg"); noise.tag = 3
        addSubview(noise)
        addSubview(scroll)
        scroll.content.addSubview(screen)
        scroll.alwaysBounceVertical = false
        // the bar
        let woodClip = UIView(); woodClip.clipsToBounds = true; woodClip.tag = 5
        let wood = PicView("img/woodPanels.png"); wood.tag = 4
        woodClip.addSubview(wood)
        bar.addSubview(woodClip)
        bar.layer.shadowColor = UIColor.black.cgColor; bar.layer.shadowOpacity = 0.6; bar.layer.shadowRadius = px(2); bar.layer.shadowOffset = CGSize(width: 0, height: px(2))
        bar.layer.masksToBounds = false
        title.style.shadow = Shadows.top
        title.html = Minigames.names[building] ?? ""
        bar.addSubview(title)
        close.onTap = { _ in PlaySound("snd/clickOff2.mp3", 0.5); Minigames.closeWindow() }
        bar.addSubview(close)
        addSubview(bar)
        // the info box
        tipDock.isHidden = true
        tipDock.isUserInteractionEnabled = false
        tipDock.addSubview(tipFrame)
        var ts = TextStyle.base(12, color: .ccText); ts.shadow = Shadows.make(0, 1, 1)
        tipText.style = ts
        tipFrame.addSubview(tipText)
        tipFrame.addSubview(tipIcon)
        var hs = TextStyle.base(10, color: UIColor(white: 1, alpha: 0.55)); hs.align = .center; hs.shadow = Shadows.make(0, 1, 2)
        tipHint.style = hs
        tipHint.html = "Tap anywhere to close"
        tipDock.addSubview(tipHint)
        addSubview(tipDock)
        MinigameWindow.current = self
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let W = bounds.width
        viewWithTag(3)?.frame = bounds
        let barH = px(Layout.sat + 36)
        bar.frame = CGRect(x: 0, y: 0, width: W, height: barH)
        bar.viewWithTag(5)?.frame = bar.bounds
        bar.viewWithTag(4)?.frame = CGRect(x: 0, y: 0, width: px(320), height: px(160))
        title.frame = CGRect(x: px(10), y: barH - px(6 + 20), width: px(250), height: px(24))
        close.frame = CGRect(x: W - px(8 + 72), y: barH - px(5 + 24), width: px(72), height: px(24))
        scroll.frame = CGRect(x: 0, y: barH, width: W, height: bounds.height - barH)
        relayoutContent()
        layoutTip()
    }
    func relayoutContent() {
        let w = Double(scroll.bounds.width / K)
        let h = screen.layoutContent(width: w, minHeight: Double(scroll.bounds.height / K))
        screen.frame = CGRect(x: 0, y: 0, width: scroll.bounds.width, height: px(h))
        scroll.setContentHeight(px(h))
    }

    // MARK: touches: remember the finger, and a tap anywhere hides the info box
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if event?.type == .touches { mouse = point }
        return super.hitTest(point, with: event)
    }
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool { true }
    func touchBegan(at p: CGPoint) {
        mouse = p
        if !tipDock.isHidden { hideTooltip() }
    }

    // MARK: the info box (Game.tooltip, docked at the bottom)
    func showTooltip(_ f: @escaping () -> (String, [Int]?)) {
        tipFunc = f
        tipDock.isHidden = false
        updateTooltip()
    }
    func hideTooltip() { tipFunc = nil; tipDock.isHidden = true }
    private var lastTip = ""
    private var lastTipIcon: [Int]? = nil
    func updateTooltip() {
        guard let f = tipFunc else { return }
        let (html, icon) = f()
        if html == lastTip && lastTipIcon == icon { return }
        lastTip = html
        lastTipIcon = icon
        if let ic = icon {
            // a third number picks the sheet: 1 is the garden's plants
            tipIcon.sheet = ic.count > 2 && ic[2] == 1 ? "mgimg/gardenPlants.png" : "img/icons.png"
            tipIcon.icon = [ic[0], ic[1]]; tipIcon.isHidden = false
        } else { tipIcon.isHidden = true }
        tipText.html = html
        layoutTip()
    }
    private func layoutTip() {
        guard !tipDock.isHidden else { return }
        let W = Double(bounds.width / K)
        let fw = W - 12
        let tw = fw - 16
        tipText.exclusions = tipIcon.isHidden ? [] : [CGRect(x: -8, y: -8, width: 48 + 4, height: 48)]
        let th = min(tipText.fittingHeight(tw), Double(bounds.height / K) * 0.55 - 16)
        let fh = th + 16
        let dockH = fh + 3 + 12
        tipDock.frame = CGRect(x: px(6), y: bounds.height - px(6 + Layout.sab + dockH), width: px(fw), height: px(dockH))
        tipFrame.frame = CGRect(x: 0, y: 0, width: px(fw), height: px(fh))
        tipText.frame = CGRect(x: px(8), y: px(8), width: px(tw), height: px(th))
        tipText.clipsToBounds = true
        tipIcon.frame = CGRect(x: 0, y: 0, width: px(48), height: px(48))
        tipHint.frame = CGRect(x: 0, y: px(fh + 3), width: px(fw), height: px(12))
    }

    // MARK: Game.Popup: a little text floating up from the finger
    func popup(_ html: String, at p: CGPoint? = nil) {
        let at = p ?? mouse
        var st = TextStyle.base(14, color: .white); st.bold = true; st.shadow = Shadows.make(0, 1, 2)
        let l = RichLabel(st)
        l.html = html
        let w = 160.0
        let h = l.fittingHeight(w)
        l.frame = CGRect(x: max(0, at.x - px(40)), y: at.y - px(20), width: px(w), height: px(h))
        l.isUserInteractionEnabled = false
        addSubview(l)
        UIView.animate(withDuration: 1.2, delay: 0, options: [.curveEaseOut]) {
            l.transform = CGAffineTransform(translationX: 0, y: -px(40)); l.alpha = 0
        } completion: { _ in l.removeFromSuperview() }
    }

    // MARK: Game.Prompt: a framed box in the middle with options
    var promptOn: Bool { promptView != nil }
    func prompt(_ html: String, icon: [Int]? = nil, options: [(String, (() -> Void)?)], update: (() -> String)? = nil) {
        closePrompt()
        let darken = TapView(frame: bounds)
        darken.backgroundColor = UIColor(white: 0, alpha: 0.5)
        darken.onTap = { _ in }
        let box = DesktopFrame()
        darken.addSubview(box)
        let W = Double(bounds.width / K) - 32
        var st = TextStyle.base(13, color: .ccText); st.align = .center; st.shadow = Shadows.make(0, 1, 1)
        let text = RichLabel(st)
        text.html = html
        box.addSubview(text)
        var y = 16.0
        if let ic = icon {
            let iv = IconView(ic); iv.frame = CGRect(x: px(-8 + 8), y: px(-8 + 8), width: px(48), height: px(48))
            box.addSubview(iv)
            text.exclusions = [CGRect(x: 0, y: 0, width: 40, height: 40)]
        }
        let th = text.fittingHeight(W - 32)
        text.frame = CGRect(x: px(16), y: px(y), width: px(W - 32), height: px(th))
        y += th + 12
        var of = TextStyle(); of.family = .georgia; of.bold = true; of.size = 14; of.color = .ccText; of.align = .center; of.shadow = Shadows.make(0, 1, 1); of.nowrap = true
        var x = 0.0
        var buttons: [(UIView, Double)] = []
        for (label, act) in options {
            let b = TapView()
            b.brightensWhenPressed = true
            let fr = DesktopFrame(); fr.isUserInteractionEnabled = false; b.addSubview(fr)
            let l = RichLabel(of); l.html = label; b.addSubview(l)
            let w = Double(RichText.size(RichText.render(label, style: of, width: nil), width: nil).width) + 24
            fr.frame = CGRect(x: 0, y: 0, width: px(w), height: px(26))
            l.frame = CGRect(x: 0, y: px(6), width: px(w), height: px(16))
            b.onTap = { [weak self] _ in
                if let a = act { PlaySound("snd/tick.mp3", 1); a() } else { PlaySound("snd/tickOff.mp3", 1) }
                self?.closePrompt()
            }
            buttons.append((b, w))
            x += w + 8
        }
        var bx = (W - (x - 8)) / 2
        for (b, w) in buttons { b.frame = CGRect(x: px(bx), y: px(y), width: px(w), height: px(26)); box.addSubview(b); bx += w + 8 }
        y += 26 + 12
        box.frame = CGRect(x: px(16), y: (bounds.height - px(y)) / 2 - px(16), width: px(W), height: px(y))
        addSubview(darken)
        promptView = darken
        PlaySound("snd/tick.mp3", 1)
        if let u = update {
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak text, weak darken] t in
                guard let text = text, darken?.superview != nil else { t.invalidate(); return }
                let s = u(); if s != text.html { text.html = s }
            }
        }
    }
    func closePrompt() { promptView?.removeFromSuperview(); promptView = nil }
}

/// keeps track of the finger for the minigame window
final class MinigameTouchWatcher: UIGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        if let w = view as? MinigameWindow, let t = touches.first { w.touchBegan(at: t.location(in: w)) }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) { super.touchesEnded(touches, with: event); state = .failed }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) { super.touchesCancelled(touches, with: event); state = .failed }
    override func canPrevent(_ p: UIGestureRecognizer) -> Bool { false }
    override func canBePrevented(by p: UIGestureRecognizer) -> Bool { false }
}

extension Minigames {
    static weak var root: RootView?
    /// window.__ccOpenMinigame
    static func openWindow(_ buildingName: String) {
        guard let b = G.buildingsBN[buildingName], b.level > 0, let root = root else { return }
        load(buildingName)
        guard let m = loaded[buildingName] else { return }
        Popup.close()
        PlaySound("snd/clickOn2.mp3", 0.5)
        let screen: MinigameScreen
        switch m {
        case let g as Garden: screen = GardenScreen(g)
        case let mk as Market: screen = MarketScreen(mk)
        case let p as Pantheon: screen = PantheonScreen(p)
        case let gr as Grimoire: screen = GrimoireScreen(gr)
        default: return
        }
        let w = MinigameWindow(building: buildingName, screen: screen)
        w.frame = root.bounds
        let watcher = MinigameTouchWatcher(target: nil, action: nil)
        watcher.cancelsTouchesInView = false; watcher.delaysTouchesBegan = false; watcher.delaysTouchesEnded = false
        w.addGestureRecognizer(watcher)
        root.addSubview(w)
        shown = buildingName
    }
    /// window.__ccCloseMinigame
    static func closeWindow() {
        MinigameWindow.current?.removeFromSuperview()
        MinigameWindow.current = nil
        shown = nil
    }
    /// M.draw for the shown minigame (30 times a second)
    static func drawShown() {
        guard let w = MinigameWindow.current else { return }
        w.screen.drawFrame()
        if G.drawT % 10 == 0 { w.updateTooltip() }
    }
    static func popup(_ html: String) { MinigameWindow.current?.popup(html) }
}
