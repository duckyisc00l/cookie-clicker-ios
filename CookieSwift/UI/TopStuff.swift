import UIKit

/// #topStuff: the news ticker, cookie counters, buffs, particles, popups and toasts, over everything else.
/// Kept clear of the notch and the home bar.
final class TopStuffView: PassView {
    let ticker1 = TapLabel()
    let ticker2 = TapLabel()
    let amount = RichLabel(TextStyle.fancy(20))
    let ps = RichLabel(TextStyle.fancy(12))
    let buffs = BuffsView()
    let version = RichLabel(TextStyle.base(8))
    let particles = ParticlesView()
    let popups = PopupsView()
    let toasts = ToastsView()
    private var lastAmount = "", lastPs = ""
    private var psState = 0

    func build(_ root: RootView) {
        clipsToBounds = false
        for t in [ticker1, ticker2] {
            t.label.style = .ticker
            addSubview(t)
        }
        ticker1.onTap = { _ in G.tapTicker(1) }
        ticker2.onTap = { _ in G.tapTicker(2) }
        amount.style.shadow = Shadows.top; amount.style.align = .center
        ps.style.shadow = Shadows.top; ps.style.align = .center
        addSubview(amount); addSubview(ps)
        insertSubview(buffs, at: 0)
        version.style.shadow = Shadows.top
        version.style.align = .right
        version.alpha = 0.35
        version.html = "v.\(jsString(Game.version)) ADLESS"
        addSubview(version)
        addSubview(popups)
        addSubview(toasts)
        addSubview(particles)
    }
    func layout() {
        let W = bounds.width
        // #ticker: margin-top 2px, 14px high, margin-bottom 4px
        ticker1.frame.origin.y = px(2); ticker2.frame.origin.y = px(2)
        amount.frame = CGRect(x: 0, y: px(20), width: W, height: px(22))
        ps.frame = CGRect(x: 0, y: px(40), width: W, height: px(14))
        version.frame = CGRect(x: W - px(204), y: px(16), width: px(200), height: px(10))
        buffs.layoutMode(in: bounds)
        popups.frame = bounds
        popups.layout()
        toasts.frame = bounds
        particles.frame = bounds
    }

    // MARK: G.Draw: the counters
    func drawCounters() {
        let a = B(G.cookiesD) + (B(G.cookiesD) == "1" ? " cookie" : " cookies")
        if a != lastAmount { amount.html = a; lastAmount = a }
        let p = B(G.cookiesPs * (1 - G.cpsSucked), 1) + "/s"
        if p != lastPs { ps.html = p; lastPs = p }
        let dif = G.cookiesPs * (1 - G.cpsSucked) - G.cookiesPsUnbuffed
        let st = dif > 0 ? 1 : dif < 0 ? -1 : 0
        if st != psState {
            psState = st
            var s = TextStyle.fancy(12)
            s.align = .center
            if st == 1 { s.color = UIColor(css: "#ffd861"); s.shadow = Shadows.make(0, 0, 4, UIColor(css: "#ffd861")) }
            else if st == -1 { s.color = UIColor(css: "#ff5134"); s.shadow = Shadows.top }
            else { s.shadow = Shadows.top }
            ps.style = s
        }
    }
    // G.tickerDraw
    func drawTicker() {
        for (t, line) in [(ticker1, G.ticker1), (ticker2, G.ticker2)] {
            if t.label.html != line.text {
                t.label.html = line.text
                let w = max(line.w, 1)
                t.bounds = CGRect(x: 0, y: 0, width: px(w), height: px(16))
                t.label.frame = t.bounds
            }
            t.isUserInteractionEnabled = line.onClick != nil
            t.frame.origin = CGPoint(x: px(line.x), y: px(2))
        }
    }
    func drawBuffs() { buffs.draw() }
    func setBuffsMode(tall: Bool) { buffs.tall = tall; buffs.layoutMode(in: bounds) }
    func plopBuff(_ name: String) { buffs.plop(name) }
}

/// a label you can tap
final class TapLabel: TapView {
    let label = RichLabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
        isUserInteractionEnabled = false
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - #buffs

final class BuffsView: TapView {
    var tall = false
    private var views: [ObjectIdentifier: BuffIcon] = [:]
    private var order: [BuffIcon] = []
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        onTap = { _ in BuffsView.showPopup() }
    }
    required init?(coder: NSCoder) { fatalError() }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // only the buff icons catch touches (#buffs is pointer-events:none, .buff is auto)
        for v in order where !v.isHidden && v.frame.contains(point) && !v.leaving { return self }
        return nil
    }
    func layoutMode(in b: CGRect) {
        if tall { frame = CGRect(x: 0, y: px(32), width: px(48), height: b.height - px(32 + 48)) }
        else { frame = CGRect(x: 0, y: px(16), width: b.width, height: px(56)) }
        relayoutIcons(animated: false)
    }
    func draw() {
        var changed = false
        for me in G.buffs {
            let id = ObjectIdentifier(me)
            if views[id] == nil {
                let v = BuffIcon(me)
                views[id] = v
                order.insert(v, at: 0)
                addSubview(v)
                changed = true
                v.appear(tall: tall)
            }
            views[id]?.setText(sayTime(me.t * 1000 + 1000, 0, true))
        }
        // buffs that ended
        let live = Set(G.buffs.map { ObjectIdentifier($0) })
        for (id, v) in views where !live.contains(id) {
            views[id] = nil
            v.leaving = true
            v.setText("")
            changed = true
            v.disappear(tall: tall) { [weak self] in
                v.removeFromSuperview()
                self?.order.removeAll { $0 === v }
                self?.relayoutIcons(animated: true)
            }
        }
        if changed { relayoutIcons(animated: true) }
    }
    private func relayoutIcons(animated: Bool) {
        var i = 0
        for v in order {
            let f: CGRect
            if tall {
                // display:block; margin:-4px (collapsing) → every 44px
                f = CGRect(x: 0, y: px(Double(i) * 44), width: px(48), height: px(48))
            } else {
                // inline-block, margin:-12px, scale(0.75): every 24px
                f = CGRect(x: px(8 - 12 + Double(i) * 24), y: px(8 - 12 + 1), width: px(48), height: px(48))
            }
            v.bounds = CGRect(x: 0, y: 0, width: f.width, height: f.height)
            let c = CGPoint(x: f.midX, y: f.midY)
            if animated { UIView.animate(withDuration: 0.2) { v.center = c } } else { v.center = c }
            v.baseScale = tall ? 1 : 0.75
            if !v.leaving && !v.appearing { v.transform = CGAffineTransform(scaleX: v.baseScale, y: v.baseScale) }
            i += 1
        }
    }
    func plop(_ name: String) {
        for (_, v) in views where v.typeName == name { Anim.trigger(v, "plop") }
    }

    /// "Active buffs" popup
    static func showPopup() {
        if G.buffs.isEmpty { return }
        Popup.open(PopupOptions(build: { c in
            c.h3("Active buffs")
            let list = UIView()
            c.add(list, height: 0, marginLeft: -16, marginRight: -16)
            c.selfUpdating(list, every: 0.15) { v, w in
                v.subviews.forEach { $0.removeFromSuperview() }
                var y = 0.0
                for me in G.buffs {
                    let type = me.type
                    let row = UIView()
                    row.clipsToBounds = true
                    let tint = type.type == 1 ? UIColor(red: 50 / 255, green: 1, blue: 100 / 255, alpha: 0.3) : type.type == 2 ? UIColor(red: 1, green: 100 / 255, blue: 50 / 255, alpha: 0.3) : UIColor(white: 1, alpha: 0.1)
                    let g = GradientView([tint, .clear], vertical: false)
                    row.addSubview(g)
                    let icon = IconView(type.icon)
                    row.addSubview(icon)
                    let text = RichLabel(TextStyle.base(11, color: .white))
                    let desc = type.desc(me).replacingOccurrences(of: "[t]", with: sayTime(me.tm * 1000, -1))
                    text.html = "<div class=\"fancy\" style=\"font-size:13px;\">\(type.nameD)</div><div style=\"padding:4px;\">\(desc)</div><div style=\"font-size:10px;opacity:0.75;\">Time left: <b>\(sayTime(me.t * 1000 + 1000, -1))</b></div>"
                    let tw = w - 48 - 8
                    let th = text.fittingHeight(tw)
                    let rh = max(th, 48) + 8
                    row.frame = CGRect(x: 0, y: px(y), width: px(w), height: px(rh))
                    g.frame = row.bounds
                    icon.frame.origin = CGPoint(x: 0, y: px((rh - 48) / 2))
                    text.frame = CGRect(x: px(52), y: px((rh - th) / 2), width: px(tw), height: px(th))
                    let top = UIView(frame: CGRect(x: 0, y: 0, width: row.bounds.width, height: px(1))); top.backgroundColor = UIColor(white: 1, alpha: 0.2)
                    let bot = UIView(frame: CGRect(x: 0, y: row.bounds.height - px(1), width: row.bounds.width, height: px(1))); bot.backgroundColor = UIColor(white: 0, alpha: 0.2)
                    row.addSubview(top); row.addSubview(bot)
                    v.addSubview(row)
                    y += rh
                }
                return y
            }
        }, close: "Close"))
    }
}

final class BuffIcon: UIView {
    let icon: IconView
    let text = RichLabel(TextStyle.fancy(11, color: .ccText))
    let typeName: String
    var leaving = false
    var appearing = false
    var baseScale: CGFloat = 1
    init(_ b: Buff) {
        icon = IconView(b.type.icon)
        typeName = b.type.name
        super.init(frame: CGRect(x: 0, y: 0, width: px(48), height: px(48)))
        isUserInteractionEnabled = false
        icon.frame = bounds
        addSubview(icon)
        text.style.shadow = Shadows.top
        text.style.align = .center
        text.style.nowrap = true
        text.frame = CGRect(x: -px(20), y: px(48 - 12), width: px(88), height: px(13))
        addSubview(text)
    }
    required init?(coder: NSCoder) { fatalError() }
    private var lastText = ""
    func setText(_ s: String) { if s != lastText { lastText = s; text.html = s } }
    func appear(tall: Bool) {
        appearing = true
        transform = tall ? CGAffineTransform(scaleX: 1, y: 0.01) : CGAffineTransform(scaleX: 0.01, y: 0.75)
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut]) {
            self.transform = tall ? .identity : CGAffineTransform(scaleX: 0.75, y: 0.75)
        } completion: { _ in self.appearing = false }
    }
    func disappear(tall: Bool, done: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut]) {
            self.transform = tall ? CGAffineTransform(scaleX: 2, y: 2) : CGAffineTransform(scaleX: 1.5, y: 1.5)
            self.alpha = 0
        } completion: { _ in done() }
    }
}

// MARK: - #particles

final class ParticlesView: UIView {
    private var slots: [ParticleSlot] = []
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
    }
    required init?(coder: NSCoder) { fatalError() }
    func draw() {
        if slots.count != G.particles.count {
            slots.forEach { $0.removeFromSuperview() }
            slots = G.particles.map { _ in let s = ParticleSlot(); addSubview(s); return s }
        }
        for (i, me) in G.particles.enumerated() {
            let v = slots[i]
            if me.t > -1 {
                v.show(me)
                v.transform = .identity
                v.center = CGPoint(x: px(me.x), y: px(me.y))
                v.transform = CGAffineTransform(scaleX: CGFloat(me.s), y: CGFloat(me.s)).rotated(by: CGFloat((me.r ?? 0) * .pi / 180))
                v.alpha = CGFloat(G.particleOpacity(me))
            } else if !v.isHidden { v.isHidden = true; v.current = nil }
        }
    }
    func clear() { slots.forEach { $0.isHidden = true; $0.current = nil } }
}

final class ParticleSlot: UIView {
    private let label = RichLabel(TextStyle.fancy(16))
    private let pic = UIImageView()
    weak var current: Particle?
    override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        label.style.align = .center
        label.style.shadow = Shadows.top
        addSubview(label); addSubview(pic)
    }
    required init?(coder: NSCoder) { fatalError() }
    func show(_ me: Particle) {
        isHidden = false
        if current === me { return }
        current = me
        if let s = me.str {
            pic.isHidden = true; label.isHidden = false
            // .textParticle: 200px wide, centred on the point
            bounds = CGRect(x: 0, y: 0, width: px(200), height: px(16))
            label.frame = CGRect(x: 0, y: px(-1), width: px(200), height: px(20))
            label.html = s
        } else {
            label.isHidden = true; pic.isHidden = false
            if let icon = me.iconPos {
                bounds = CGRect(x: 0, y: 0, width: px(48), height: px(48))
                pic.image = Res.icon(icon)
            } else if let name = me.imageName {
                if case .flare = me.pic {
                    bounds = CGRect(x: 0, y: 0, width: px(128), height: px(128))
                    pic.image = Res.image(name)
                } else if case .wrinklerBits = me.pic {
                    bounds = CGRect(x: 0, y: 0, width: px(100), height: px(200))
                    pic.image = Res.sprite(name, x: me.frameX, y: 0, w: 100, h: 200)
                } else {
                    bounds = CGRect(x: 0, y: 0, width: px(64), height: px(64))
                    pic.image = Res.sprite(name, x: me.frameX, y: 0, w: 64, h: 64)
                }
            } else { pic.image = nil }
            pic.frame = bounds
        }
    }
}

// MARK: - #toasts

final class ToastsView: PassView {
    private var pending = 0
    private var live: [UIView] = []
    func toast(title: String, top: String, icon: [Int]?, reverse: Bool) {
        let oldSeed = G.seed
        let id = pending
        pending += 1
        let delay = Double(id / 2) * 0.6 + (id % 2 == 0 ? 0 : 0.1)
        DebugLog.log("toast \(title) id=\(id) delay=\(delay) frame=\(frame) seed=\(G.seed)")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            if G.seed != oldSeed { DebugLog.log("toast dropped: seed"); self.pending -= 1; return }
            DebugLog.log("toast shown \(nowMs()) \(title) bounds=\(self.bounds) hidden=\(self.isHidden) alpha=\(self.alpha) super=\(String(describing: self.superview?.isHidden))")
            if self.live.count > 5 { self.live.first?.removeFromSuperview(); self.live.removeFirst() }
            var t = "", tp = ""
            if !title.isEmpty { t = "<div style=\"\((reverse && icon != nil) ? "padding-left:8px;" : "")font-size:16px;font-family:Fancy;\">\(title)</div>" }
            if !top.isEmpty { tp = "<div style=\"\((!reverse && icon != nil) ? "padding-left:8px;" : "")\">\(top)</div>" }
            let body = reverse ? t + tp : tp + t
            var str: String
            if let ic = icon { str = "<div class=\"icon\" style=\"display:inline-block;vertical-align:middle;background-position:\(-ic[0] * 48)px \(-ic[1] * 48)px;margin-right:-4px;\"></div><div class=\"title\">\(body)</div>" }
            else { str = body }
            G.savedToasts.insert((str, nowMs()), at: 0)
            if G.savedToasts.count > 50 { G.savedToasts.removeLast() }
            let v = ToastView(body: body, icon: icon, width: Double(self.bounds.width / K) - 32)
            let h = v.cssHeight
            v.frame = CGRect(x: px(16), y: self.bounds.height - px(h), width: self.bounds.width - px(32), height: px(h))
            self.addSubview(v)
            self.live.append(v)
            v.run(rise: id % 2 == 0 ? 64 : 112)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                v.removeFromSuperview()
                self?.live.removeAll { $0 === v }
                self?.pending -= 1
            }
        }
    }
    func closeAll() { live.forEach { $0.removeFromSuperview() }; live = [] }
}

final class ToastView: UIView {
    let cssHeight: Double
    init(body: String, icon: [Int]?, width: Double) {
        var st = TextStyle.base(11)
        st.bold = true; st.align = .center; st.shadow = Shadows.top
        let text = RichLabel(st)
        text.html = body
        var h: Double
        let iconV = icon.map { IconView($0) }
        if iconV != nil {
            // icon (48px, margin-right -4px) then .title (inline-block, max 75% wide, padding 4px, max 64px high), centred
            var ts = st; ts.align = .left
            text.style = ts
            let maxW = width * 0.75 - 8
            let s = RichText.size(RichText.render(body, style: ts, width: maxW), width: maxW)
            let tw = min(maxW, Double(s.width)) + 1
            let th = min(64 - 8, Double(s.height))
            h = max(48, th + 8)
            cssHeight = h
            super.init(frame: .zero)
            let total = 48 - 4 + tw + 8
            let x0 = (width - total) / 2
            iconV!.frame = CGRect(x: px(x0), y: px((h - 48) / 2), width: px(48), height: px(48))
            addSubview(iconV!)
            text.frame = CGRect(x: px(x0 + 44 + 4), y: px((h - th) / 2), width: px(tw), height: px(th))
            text.wrapWidth = maxW
            text.clipsToBounds = true
        } else {
            h = text.fittingHeight(width)
            cssHeight = h
            super.init(frame: .zero)
            text.frame = CGRect(x: 0, y: 0, width: px(width), height: px(h))
        }
        isUserInteractionEnabled = false
        backgroundColor = UIColor(white: 0, alpha: 0.6)
        layer.cornerRadius = min(px(96), px(h) / 2)
        layer.shadowColor = UIColor.black.cgColor; layer.shadowOpacity = 0.6; layer.shadowRadius = px(4); layer.shadowOffset = .zero
        addSubview(text)
        alpha = 0
    }
    required init?(coder: NSCoder) { fatalError() }
    /// .toast1 / .toast2: rise 64px (or 112px) and fade in over 0.6s, stay, fade out at the end of 3s
    func run(rise: Double) {
        let a = CAKeyframeAnimation(keyPath: "transform.translation.y")
        a.values = [0, -px(rise), -px(rise), -px(rise)]
        a.keyTimes = [0, 0.2, 0.8, 1]
        let o = CAKeyframeAnimation(keyPath: "opacity")
        o.values = [0, 1, 1, 0]
        o.keyTimes = [0, 0.2, 0.8, 1]
        let g = CAAnimationGroup()
        g.animations = [a, o]
        g.duration = 3
        g.timingFunction = CAMediaTimingFunction(name: .easeOut)
        g.fillMode = .forwards
        g.isRemovedOnCompletion = false
        layer.add(g, forKey: "toast")
    }
}
