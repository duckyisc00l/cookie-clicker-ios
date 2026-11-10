import UIKit
import ImageIO

// The ascension screen (G.showAscend in www/main.js): the heavenly upgrade tree on a starry background,
// pinch and drag to zoom, the unspent chips on top and the Reincarnate/Return button.

final class AscendView {
    let mode: Int
    var options: PopupOptions!
    private var tree = UIScrollView()
    private let content = UIView()
    private var icons: [Int: TreeIcon] = [:]
    private var links: [(Int, UIImageView)] = []
    private var chipsL = RichLabel()
    private var lastChips = ""
    private weak var popup: PopupView?

    init(mode: Int) {
        self.mode = mode
        var o = PopupOptions(build: { [unowned self] c in self.build(c) }, close: nil, fullPopup: true)
        o.introAnim = "ascendPopupAnimIn"
        o.replace = true
        o.contentPadding = .zero
        options = o
    }

    private func build(_ c: PopupContent) {
        DebugLog.log("ascend build start")
        c.isScrollEnabled = false
        c.alwaysBounceVertical = false
        // the tree
        let pool = G.upgradePools["prestige"] ?? []
        tree.minimumZoomScale = 0.1
        tree.maximumZoomScale = 8
        tree.showsVerticalScrollIndicator = false
        tree.showsHorizontalScrollIndicator = false
        tree.delegate = ZoomDelegate.shared
        tree.bouncesZoom = true
        tree.clipsToBounds = true
        tree.addSubview(content)
        ZoomDelegate.shared.view = content
        let pulse = AscendView.linkPulse()
        for me in pool {
            guard let pos = G.HeavenlyUpgradePositions[me.id] else { continue }
            for (i, pid) in (G.HeavenlyUpgradeParents[me.id] ?? []).enumerated() where pid != -1 {
                guard let pos2 = G.HeavenlyUpgradePositions[pid] else { continue }
                let ox = pos2[0] + 28, oy = pos2[1] + 28
                let tx = pos[0] + 28, ty = pos[1] + 28
                var rot = -(atan((ty - oy) / (ox - tx)) / Double.pi) * 180
                if tx <= ox { rot += 180 }
                let dist = ((tx - ox) * (tx - ox) + (ty - oy) * (ty - oy)).squareRoot().rounded(.down)
                let l = UIImageView()
                l.backgroundColor = pulse.map { UIColor(patternImage: $0) }
                l.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
                l.bounds = CGRect(x: 0, y: 0, width: px(dist), height: px(8))
                l.tag = me.id
                l.alpha = 0
                l.accessibilityHint = "\(ox)|\(oy)|\(rot)"
                content.addSubview(l)
                links.append((me.id, l))
                _ = i
            }
        }
        for me in pool {
            guard G.HeavenlyUpgradePositions[me.id] != nil else { continue }
            let v = TreeIcon(me.iconFunc?() ?? me.icon)
            v.onTap = { [weak self] v in
                Anim.trigger(v, "plop")
                UpgradeUI.showInfo(me, onBuy: { self?.buy(me) })
            }
            content.addSubview(v)
            icons[me.id] = v
        }
        if PulseAnimator.shared.frames.isEmpty, let f = AscendView.linkPulseFrames() { PulseAnimator.shared.frames = f }
        PulseAnimator.shared.start { [weak self] img in
            self?.links.forEach { $0.1.backgroundColor = UIColor(patternImage: img) }
        }
        DebugLog.log("ascend tree made \(icons.count) icons \(links.count) links")
        c.add(tree) { [unowned self] w in
            DispatchQueue.main.async { self.fit() }
            return Double(c.bounds.height / K)
        }

        // the chips on top
        let bar = UIView()
        bar.backgroundColor = UIColor(white: 0, alpha: 0.5)
        bar.isUserInteractionEnabled = false
        var st = TextStyle.base(12); st.align = .center; st.shadow = Shadows.body
        chipsL.style = st
        bar.addSubview(chipsL)
        let pinch = RichLabel(TextStyle.fancy(10, color: .ccText))
        pinch.style.align = .center; pinch.style.shadow = Shadows.body
        pinch.alpha = 0.5
        pinch.html = "pinch &amp; drag<br>to zoom"
        // Return / Reincarnate
        var bf = TextStyle.fancy(12, color: UIColor(css: "#cff")); bf.bold = true; bf.align = .center; bf.shadow = Shadows.body
        let btn = CCButton(mode == 2 ? "Return" : "Reincarnate", look: .magic, font: bf, padding: UIEdgeInsets(top: 8, left: 18, bottom: mode == 2 ? 8 : 16, right: 18))
        let sub = RichLabel(TextStyle.base(8)); sub.style.align = .center; sub.alpha = 0.75; sub.html = "(when you're ready)"
        if mode != 2 { btn.addSubview(sub) }
        btn.onTap = { [weak self] _ in self?.returnTapped() }
        updateChips()
        c.every(0.15) { [weak self] in self?.updateChips(); return false }
        // these float over the popup
        DispatchQueue.main.async { [weak self, weak c] in
            guard let self = self, let p = c?.popup else { return }
            self.popup = p
            let W = Double(p.bounds.width / K), H = Double(p.bounds.height / K)
            bar.frame = CGRect(x: 0, y: px(16), width: px(W), height: px(20))
            let ch = self.chipsL.fittingHeight(W - 32)
            self.chipsL.frame = CGRect(x: px(16), y: px(4 + (12 - ch) / 2), width: px(W - 32), height: px(ch))
            self.chipsL.clipsToBounds = false
            p.addSubview(bar)
            pinch.frame = CGRect(x: px(8), y: px(H - 8 - 20), width: px(70), height: px(22))
            p.addSubview(pinch)
            let tw = Double(RichText.size(RichText.render(btn.text, style: bf, width: nil), width: nil).width) + 36
            let bh = 12.0 + 8 + (self.mode == 2 ? 8 : 16)
            btn.frame = CGRect(x: px(W - 6 - tw), y: px(H - 6 - bh), width: px(tw), height: px(bh))
            sub.frame = CGRect(x: 0, y: btn.bounds.height - px(4 + 10), width: btn.bounds.width, height: px(10))
            p.addSubview(btn)
            DebugLog.log("ascend overlay")
            self.updateTree()
            DebugLog.log("ascend updated")
            self.fit()
            DebugLog.log("ascend fitted")
        }
    }

    private func updateChips() {
        let n = G.heavenlyChipsD.rounded()
        let s = "<span class=\"tinyIcon\" style=\"background-position:\(-19 * 48)px \(-7 * 48)px;\"></span><b>\(B(n, 0, 1))</b> <span style=\"font-size:80%;\">unspent heavenly chip\(n == 1 ? "" : "s")</span>"
        if s != lastChips { lastChips = s; chipsL.html = s }
    }

    private var bounds = (l: 0.0, t: 0.0, r: 0.0, b: 0.0)
    /// updateHeavenlyTree: which upgrades show, and the size of the area
    private func updateTree() {
        let pool = G.upgradePools["prestige"] ?? []
        var status: [Int: Int] = [:]
        for me in pool {
            if me.owned != 0 { status[me.id] = 3; continue }
            let parents = G.HeavenlyUpgradeParents[me.id] ?? []
            status[me.id] = parents.allSatisfy({ G.upgradesBID[$0]?.owned != 0 }) ? 2 : 0
        }
        var l = 0.0, t = 0.0, r = 0.0, b = 0.0
        for me in pool {
            guard let pos = G.HeavenlyUpgradePositions[me.id] else { continue }
            if status[me.id] == 0 {
                for p in G.HeavenlyUpgradeParents[me.id] ?? [] where (status[p] ?? 0) > 1 { status[me.id] = 1; break }
            }
            let st = status[me.id] ?? 0
            icons[me.id]?.setStatus(st)
            for (id, link) in links where id == me.id {
                let a: CGFloat = st == 0 ? 0 : st == 1 ? 0.2 : 1
                if link.alpha != a { UIView.animate(withDuration: 2) { link.alpha = a } }
            }
            if st > 1 {
                l = min(l, pos[0]); r = max(r, pos[0])
                t = min(t, pos[1]); b = max(b, pos[1])
            }
        }
        bounds = (l - 128, t - 128, r + 128 + 64, b + 128 + 64)
        let ax = -bounds.l, ay = -bounds.t
        let zs = tree.zoomScale
        tree.zoomScale = 1
        content.frame = CGRect(x: 0, y: 0, width: px(bounds.r - bounds.l), height: px(bounds.b - bounds.t))
        for me in pool {
            guard let pos = G.HeavenlyUpgradePositions[me.id], let v = icons[me.id] else { continue }
            v.frame = CGRect(x: px(ax + pos[0] + 4), y: px(ay + pos[1] + 4), width: px(48), height: px(48))
        }
        for (_, link) in links {
            let parts = (link.accessibilityHint ?? "0|0|0").split(separator: "|").map { Double($0) ?? 0 }
            link.transform = .identity
            link.layer.position = CGPoint(x: px(ax + parts[0]), y: px(ay + parts[1]))
            link.transform = CGAffineTransform(rotationAngle: CGFloat(parts[2] * .pi / 180))
        }
        tree.contentSize = content.frame.size
        tree.zoomScale = zs
    }

    private var fitted = false
    /// PinchZoom's start: the whole area fits, centred
    private func fit() {
        let cw = tree.bounds.width, ch = tree.bounds.height
        guard cw > 0, content.bounds.width > 0 else { return }
        let s = min(cw / content.bounds.width, ch / content.bounds.height)
        tree.minimumZoomScale = s * 0.5
        tree.maximumZoomScale = s * 4
        if !fitted { tree.zoomScale = s; fitted = true }
        DebugLog.log("fit cw=\(cw) ch=\(ch) content=\(content.bounds) s=\(s) zoom=\(tree.zoomScale)")
        ZoomDelegate.shared.center(tree)
    }

    private func buy(_ me: Upgrade) {
        if me.buy() {
            updateTree()
            if let v = icons[me.id] {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    let p = v.convert(CGPoint(x: v.bounds.midX, y: v.bounds.midY), to: nil)
                    G.sparkleAt(Double(p.x / K), Double(p.y / K))
                }
            }
            for (i, child) in (G.HeavenlyUpgradeChildren[me.id] ?? []).enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + 0.15 * Double(i)) { [weak self] in
                    if !(G.HeavenlyUpgradeParents[child] ?? []).allSatisfy({ G.upgradesBID[$0]?.owned != 0 }) { return }
                    guard let v = self?.icons[child] else { return }
                    Anim.trigger(v, "plop")
                    PlaySound("snd/clickb\(Int(JSMath.random() * 7 + 1)).mp3", 0.3)
                }
            }
        } else {
            PlaySound("snd/clickb2.mp3", 0.75)
        }
    }

    private func returnTapped() {
        if mode == 2 {
            PlaySound("snd/smallTick.mp3", 1)
            PulseAnimator.shared.stop()
            Popup.closeAll()
            G.onAscend = 0
            return
        }
        Popup.open(PopupOptions(build: { c in
            c.h3("Reincarnate")
            c.html("<div style=\"text-align:center;\">Are you ready to return to the mortal world?</div>")
            c.line()
            let b = BigPictureButton(text: "Reincarnate!", pics: ["img/perfectCookie.png", "img/bgBlue.jpg"], glow: UIColor(css: "#36f"))
            b.onTap = { _ in
                PulseAnimator.shared.stop()
                G.reincarnate()
            }
            c.add(b, height: 56, marginTop: 8, marginBottom: 8)
        }, close: "Cancel"))
    }

    /// the first frame of linkPulse.gif
    static func linkPulse() -> UIImage? { linkPulseFrames()?.first }
    private static var framesCache: [UIImage]?
    static func linkPulseFrames() -> [UIImage]? {
        if let f = framesCache { return f }
        guard let u = Res.url("img/linkPulse.gif"), let src = CGImageSourceCreateWithURL(u as CFURL, nil) else { return nil }
        var out: [UIImage] = []
        for i in 0..<CGImageSourceGetCount(src) {
            if let cg = CGImageSourceCreateImageAtIndex(src, i, nil) {
                // drawn at CSS size: 32x8 → points
                let img = UIImage(cgImage: cg, scale: CGFloat(cg.width) / px(32), orientation: .up)
                out.append(img)
            }
        }
        framesCache = out
        return out
    }
}

/// steps through the GIF frames of the pulsing links (10ms a frame in the GIF; browsers clamp to 100ms... WebKit uses 100ms for <=10ms)
final class PulseAnimator {
    static let shared = PulseAnimator()
    var frames: [UIImage] = []
    private var timer: Timer?
    private var i = 0
    func start(_ apply: @escaping (UIImage) -> Void) {
        timer?.invalidate()
        guard !frames.isEmpty else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.i = (self.i + 1) % self.frames.count
            apply(self.frames[self.i])
        }
    }
    func stop() { timer?.invalidate(); timer = nil }
}

final class ZoomDelegate: NSObject, UIScrollViewDelegate {
    static let shared = ZoomDelegate()
    weak var view: UIView?
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { view }
    func scrollViewDidZoom(_ scrollView: UIScrollView) { center(scrollView) }
    func center(_ s: UIScrollView) {
        guard let v = view else { return }
        let dx = max(0, (s.bounds.width - v.frame.width) / 2)
        let dy = max(0, (s.bounds.height - v.frame.height) / 2)
        s.contentInset = UIEdgeInsets(top: dy, left: dx, bottom: dy, right: dx)
    }
}

/// .prestigeIcon in the tree: icon in a slot frame
final class TreeIcon: TapView {
    private let icon: IconView
    private let slot = UIImageView()
    private var status = -1
    init(_ ic: [Int]) {
        icon = IconView(ic)
        super.init(frame: CGRect(x: 0, y: 0, width: px(48), height: px(48)))
        clipsToBounds = false
        icon.frame = bounds
        addSubview(icon)
        slot.frame = CGRect(x: -px(20), y: -px(20), width: px(88), height: px(88))
        slot.isUserInteractionEnabled = false
        addSubview(slot)
        alpha = 0
    }
    required init?(coder: NSCoder) { fatalError() }
    func setStatus(_ s: Int) {
        if s == status { return }
        status = s
        isUserInteractionEnabled = s >= 2
        icon.isHidden = s == 1
        slot.image = Res.sprite("img/ascendSlot.png", x: s == 3 ? 0 : 176, y: 0, w: 88, h: 88)
        let a: CGFloat = s == 0 ? 0 : s == 1 ? 0.2 : 1
        UIView.animate(withDuration: 2) { self.alpha = a }
    }
}
