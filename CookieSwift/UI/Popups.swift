import UIKit

// G.popup / G.closePopup / G.closeAllPopups (www/main.js "POPUPS") and the pieces popups are made of.

struct PopupOptions {
    var build: (PopupContent) -> Void
    /// the close button's text; nil = no close button ('[NONE]')
    var close: String? = "Close"
    var fullPopup = false
    var replace = false
    var introAnim: String? = nil
    /// extra look (e.g. the ascension popup's star background)
    var background: String? = nil
    var contentPadding = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    var onClose: (() -> Void)? = nil
    init(build: @escaping (PopupContent) -> Void, close: String? = "Close", fullPopup: Bool = false, replace: Bool = false) {
        self.build = build; self.close = close; self.fullPopup = fullPopup; self.replace = replace
    }
}

enum Popup {
    static weak var container: PopupsView?
    @discardableResult
    static func open(_ o: PopupOptions) -> PopupView? { container?.open(o) }
    static func close(_ v: PopupView? = nil) { container?.close(v) }
    static func closeAll() { container?.closeAll() }
}

/// #popups: dims everything and holds the open popups (only the top one takes touches)
final class PopupsView: UIView {
    private(set) var stack: [PopupView] = []
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(white: 0, alpha: 0.5)
        isHidden = true
        Popup.container = self
    }
    required init?(coder: NSCoder) { fatalError() }
    func layout() { for p in stack { p.frame = p.targetFrame(in: bounds); p.relayout() } }

    @discardableResult
    func open(_ o: PopupOptions) -> PopupView {
        if o.replace { close(nil) }
        G.particlesClear()
        let p = PopupView(o)
        stack.last?.isUserInteractionEnabled = false
        addSubview(p)
        stack.append(p)
        isHidden = false
        p.frame = p.targetFrame(in: bounds)
        p.relayout()
        if let a = o.introAnim { if a == "ascendPopupAnimIn" { p.ascendIn() } }
        else if G.getSet("lowMotion") == 0 { Anim.fadeOpen(p) }
        PlaySound("snd/press.mp3", 0.15)
        G.onPopup = 1
        p.scrollToMarked()
        return p
    }
    func close(_ el: PopupView?) {
        guard let p = el ?? stack.last else { return }
        p.removeFromSuperview()
        stack.removeAll { $0 === p }
        p.options.onClose?()
        stack.last?.isUserInteractionEnabled = true
        if stack.isEmpty { isHidden = true; G.onPopup = 0 }
    }
    func closeAll() {
        stack.forEach { $0.removeFromSuperview() }
        stack = []
        isHidden = true
        G.onPopup = 0
    }
    /// self-updating texts (G.selfUpdatingText refreshes every 150ms)
    func tick() { for p in stack { p.content.tick() } }

    // MARK: ascension
    private(set) var ascend: AscendView?
    func showAscend(_ mode: Int) {
        closeAll()
        let a = AscendView(mode: mode)
        ascend = a
        open(a.options)
    }
}

/// .popup.framed: a dark noisy panel with a gold frame, a faint doily trim and a close button at the bottom
final class PopupView: UIView {
    let options: PopupOptions
    let bg: PatternView
    let frameBorder = BorderImageView(image: "img/frameBorder.png", slice: 3, width: 3)
    let doily = BorderImageView(image: "img/doilyBorder.png", slice: 16, width: 6)
    let content: PopupContent
    var closeButton: CCButton?
    init(_ o: PopupOptions) {
        options = o
        bg = PatternView(o.background ?? "img/darkNoise.jpg")
        content = PopupContent(padding: o.contentPadding)
        super.init(frame: .zero)
        clipsToBounds = false
        addSubview(bg)
        if !o.fullPopup {
            doily.alpha = 0.3
            addSubview(doily)
        }
        addSubview(content)
        if let c = o.close {
            let b = CCButton(c, look: .popupClose, font: { var f = TextStyle.fancy(14, color: .ccText); f.bold = true; f.shadow = Shadows.body; return f }(),
                             padding: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
            b.onTap = { [weak self] _ in
                PlaySound("snd/smallTick.mp3", 1)
                Popup.close(self)
            }
            closeButton = b
            addSubview(b)
        }
        if !o.fullPopup { addSubview(frameBorder) }
        // box-shadow:0px 0px 1px 2px rgba(0,0,0,0.5),0px 2px 4px rgba(0,0,0,0.25)
        layer.shadowColor = UIColor.black.cgColor; layer.shadowOpacity = 0.5; layer.shadowRadius = px(2); layer.shadowOffset = .zero
        content.popup = self
        o.build(content)
    }
    required init?(coder: NSCoder) { fatalError() }
    /// margin:60px 10px 44px 10px, plus the safe-area adjustments the web version made
    func targetFrame(in b: CGRect) -> CGRect {
        let top = px(60 + Layout.sat), bottom = px(44 + Layout.sab)
        // .fullPopup has no side margins (its top and bottom ones come from the safe-area rules)
        if options.fullPopup { return CGRect(x: 0, y: top, width: b.width, height: b.height - top - bottom) }
        return CGRect(x: px(10), y: top, width: b.width - px(20), height: b.height - top - bottom)
    }
    func relayout() {
        bg.frame = bounds
        frameBorder.frame = bounds.insetBy(dx: -px(3), dy: -px(3))
        doily.frame = CGRect(x: px(3), y: px(3), width: bounds.width - px(6), height: bounds.height - px(3) - px(31) - px(3))
        let closeH = closeButton != nil ? 32.0 : 0
        content.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - px(closeH))
        content.relayout()
        if let b = closeButton {
            b.frame = CGRect(x: px(2), y: bounds.height - px(32), width: bounds.width - px(4), height: px(30))
        }
    }
    func ascendIn() {
        let s = CABasicAnimation(keyPath: "transform.scale"); s.fromValue = 2; s.toValue = 1
        let o = CABasicAnimation(keyPath: "opacity"); o.fromValue = 0; o.toValue = 1
        let g = CAAnimationGroup(); g.animations = [s, o]; g.duration = 0.35
        g.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(g, forKey: "in")
    }
    func scrollToMarked() {
        if let v = content.scrollTarget {
            let r = v.convert(v.bounds, to: content)
            content.scrollRectToVisible(r, animated: false)
            content.scrollTarget = nil
        }
    }
}

/// .popupContent: the scrolling inside of a popup, laid out top to bottom like the page.
final class PopupContent: ScrollArea {
    weak var popup: PopupView?
    let padding: UIEdgeInsets
    private struct Block {
        let view: UIView
        var height: (Double) -> Double
        var marginTop: Double
        var marginBottom: Double
        var marginLeft: Double
        var marginRight: Double
        var x: ((Double, Double) -> Double)? = nil   // (available width, own width) → x
        var fixedWidth: Double? = nil
    }
    private var blocks: [Block] = []
    private var updaters: [(interval: Double, last: Double, run: () -> Bool)] = []
    var scrollTarget: UIView?
    /// inner width in CSS px
    var width: Double { Double(bounds.width / K) - Double(padding.left + padding.right) }

    init(padding: UIEdgeInsets) {
        self.padding = padding
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: adding blocks
    /// a block of game HTML
    @discardableResult
    func html(_ s: String, style: TextStyle = TextStyle(), marginTop: Double = 0, marginBottom: Double = 0, marginLeft: Double = 0, marginRight: Double = 0) -> RichLabel {
        let l = RichLabel(style)
        l.html = s
        add(l, marginTop: marginTop, marginBottom: marginBottom, marginLeft: marginLeft, marginRight: marginRight) { w in l.fittingHeight(w) }
        return l
    }
    /// <h3>
    func h3(_ s: String) { add(H3View(s), height: 23, marginTop: 4, marginBottom: 4) }
    /// <line>
    func line() { add(LineView(), height: 3, marginTop: 5, marginBottom: 5) }
    func space(_ h: Double) { add(UIView(), height: h) }
    func add(_ v: UIView, height: Double, marginTop: Double = 0, marginBottom: Double = 0, marginLeft: Double = 0, marginRight: Double = 0) {
        add(v, marginTop: marginTop, marginBottom: marginBottom, marginLeft: marginLeft, marginRight: marginRight) { _ in height }
    }
    func add(_ v: UIView, marginTop: Double = 0, marginBottom: Double = 0, marginLeft: Double = 0, marginRight: Double = 0, width: Double? = nil, x: ((Double, Double) -> Double)? = nil, height: @escaping (Double) -> Double) {
        content.addSubview(v)
        blocks.append(Block(view: v, height: height, marginTop: marginTop, marginBottom: marginBottom, marginLeft: marginLeft, marginRight: marginRight, x: x, fixedWidth: width))
    }
    /// a centred row of buttons (inline-block buttons in a text-align:center div)
    @discardableResult
    func buttons(_ bs: [CCButton], marginTop: Double = 0, marginBottom: Double = 0, height: Double = 26, widths: [Double]? = nil, spacing: Double = 4) -> UIView {
        let row = UIView()
        for b in bs { row.addSubview(b) }
        add(row, marginTop: marginTop, marginBottom: marginBottom) { w in
            var ws: [Double] = []
            for (i, b) in bs.enumerated() {
                if let fw = widths?[i] { ws.append(fw) }
                else { ws.append(Double(RichText.size(RichText.render(b.text, style: b.font, width: nil), width: nil).width) + Double(b.padding.left + b.padding.right) + 1) }
            }
            let total = ws.reduce(0, +) + spacing * Double(max(0, bs.count - 1))
            var x = (w - total) / 2
            var hMax = height
            for (i, b) in bs.enumerated() {
                let bh = max(height, b.fittingHeight(width: ws[i]))
                b.frame = CGRect(x: px(x), y: 0, width: px(ws[i]), height: px(bh))
                hMax = max(hMax, bh)
                x += ws[i] + spacing
            }
            return hMax
        }
        return row
    }
    /// G.selfUpdatingText: rebuilds a block every `every` seconds; the closure fills the view and returns its height
    func selfUpdating(_ v: UIView, every: Double = 0.15, _ fill: @escaping (UIView, Double) -> Double) {
        guard let idx = blocks.firstIndex(where: { $0.view === v }) else { return }
        var cached: Double = -1
        blocks[idx].height = { w in
            if cached < 0 { cached = fill(v, w) }
            return cached
        }
        updaters.append((every, nowMs(), { [weak self] in
            guard let self = self else { return false }
            let old = cached
            cached = fill(v, self.width)
            return abs(old - cached) > 0.01
        }))
    }
    /// a self-updating HTML block
    @discardableResult
    func liveHTML(style: TextStyle = TextStyle(), every: Double = 0.15, marginTop: Double = 0, marginBottom: Double = 0, _ make: @escaping () -> String) -> RichLabel {
        let l = RichLabel(style)
        l.html = make()
        add(l, marginTop: marginTop, marginBottom: marginBottom) { w in l.fittingHeight(w) }
        updaters.append((every, nowMs(), {
            let s = make()
            if s == l.html { return false }
            l.html = s
            return true
        }))
        return l
    }
    /// runs something regularly while the popup is open (G.displayIf and the like)
    func every(_ seconds: Double, _ f: @escaping () -> Bool) { updaters.append((seconds, nowMs(), f)) }

    func tick() {
        let now = nowMs()
        var needs = false
        for i in updaters.indices where now - updaters[i].last >= updaters[i].interval * 1000 {
            updaters[i].last = now
            if updaters[i].run() { needs = true }
        }
        if needs { relayout() }
    }

    func relayout() {
        let W = width
        guard W > 0 else { return }
        var y = Double(padding.top)
        for b in blocks {
            if b.view.isHidden { continue }
            y += b.marginTop
            let avail = W - b.marginLeft - b.marginRight
            let bw = b.fixedWidth ?? avail
            let h = b.height(bw)
            let x = Double(padding.left) + b.marginLeft + (b.x?(avail, bw) ?? (b.fixedWidth != nil ? (avail - bw) / 2 : 0))
            b.view.frame = CGRect(x: px(x), y: px(y), width: px(bw), height: px(h))
            b.view.setNeedsLayout()
            y += h + b.marginBottom
        }
        y += Double(padding.bottom)
        setContentHeight(px(y))
    }
}

// MARK: - decorations

/// <h3>: Fancy 15px small caps on a fading dark band with thin light lines above and below
final class H3View: UIView {
    let label = RichLabel()
    private let band = GradientView([.clear, UIColor(white: 0, alpha: 0.75), .clear], vertical: false)
    private let top = GradientView([UIColor(white: 1, alpha: 0), UIColor(white: 1, alpha: 0.25), UIColor(white: 1, alpha: 0)], vertical: false)
    private let bottom = GradientView([UIColor(white: 1, alpha: 0), UIColor(white: 1, alpha: 0.25), UIColor(white: 1, alpha: 0)], vertical: false)
    init(_ html: String) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        addSubview(band); addSubview(top); addSubview(bottom)
        var s = TextStyle.fancy(15, color: .ccText)
        s.smallCaps = true; s.align = .center
        label.style = s
        label.html = html
        addSubview(label)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        band.frame = bounds
        top.frame = CGRect(x: 0, y: -px(1), width: bounds.width, height: px(1))
        bottom.frame = CGRect(x: 0, y: bounds.height, width: bounds.width, height: px(1))
        label.frame = CGRect(x: px(8), y: px(4), width: bounds.width - px(16), height: bounds.height - px(8))
    }
}

/// <line>: a thin fading line, 90% wide
final class LineView: UIView {
    private let img = UIImageView()
    init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        addSubview(img)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        let w = Double(bounds.width / K) * 0.9
        img.image = Decor.fadeLine(width: w)
        img.frame = CGRect(x: (bounds.width - px(w)) / 2, y: 0, width: px(w), height: px(3))
    }
}

/// CSS border-image (no fill): corners scaled to the border width, edges repeated ("round")
final class BorderImageView: UIView {
    let image: UIImage?
    let slice: CGFloat
    let borderWidth: CGFloat
    init(image: String, slice: CGFloat, width: CGFloat) {
        self.image = Res.image(image)
        self.slice = slice
        self.borderWidth = width
        super.init(frame: .zero)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
        contentMode = .redraw
    }
    required init?(coder: NSCoder) { fatalError() }
    override func draw(_ rect: CGRect) {
        guard let img = image, let cg = img.cgImage else { return }
        let sc = img.scale
        let iw = img.size.width, ih = img.size.height
        let s = slice, bw = px(borderWidth)
        func piece(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> UIImage? {
            guard let c = cg.cropping(to: CGRect(x: x * sc, y: y * sc, width: w * sc, height: h * sc)) else { return nil }
            return UIImage(cgImage: c, scale: sc, orientation: .up)
        }
        let W = bounds.width, H = bounds.height
        // corners
        piece(0, 0, s, s)?.draw(in: CGRect(x: 0, y: 0, width: bw, height: bw))
        piece(iw - s, 0, s, s)?.draw(in: CGRect(x: W - bw, y: 0, width: bw, height: bw))
        piece(0, ih - s, s, s)?.draw(in: CGRect(x: 0, y: H - bw, width: bw, height: bw))
        piece(iw - s, ih - s, s, s)?.draw(in: CGRect(x: W - bw, y: H - bw, width: bw, height: bw))
        // edges, "round": the tile is stretched so a whole number fits
        let midW = iw - 2 * s, midH = ih - 2 * s
        let edgeLen = W - 2 * bw, edgeLenV = H - 2 * bw
        if midW > 0 && edgeLen > 0 {
            let tileW = midW * bw / s
            let n = max(1, (edgeLen / tileW).rounded())
            let tw = edgeLen / n
            let top = piece(s, 0, midW, s), bot = piece(s, ih - s, midW, s)
            for i in 0..<Int(n) {
                top?.draw(in: CGRect(x: bw + CGFloat(i) * tw, y: 0, width: tw, height: bw))
                bot?.draw(in: CGRect(x: bw + CGFloat(i) * tw, y: H - bw, width: tw, height: bw))
            }
        }
        if midH > 0 && edgeLenV > 0 {
            let tileH = midH * bw / s
            let n = max(1, (edgeLenV / tileH).rounded())
            let th = edgeLenV / n
            let l = piece(0, s, s, midH), r = piece(iw - s, s, s, midH)
            for i in 0..<Int(n) {
                l?.draw(in: CGRect(x: 0, y: bw + CGFloat(i) * th, width: bw, height: th))
                r?.draw(in: CGRect(x: W - bw, y: bw + CGFloat(i) * th, width: bw, height: th))
            }
        }
    }
}

/// .framed.nameBox: a marble box with a doily trim, used at the top of info popups
final class NameBox: UIView {
    let marble = PatternView("img/marbleSolid.jpg", tileSize: CGSize(width: 300, height: 300))
    let shade = GradientView([UIColor(white: 0, alpha: 0.1), UIColor(white: 0, alpha: 0.5)])
    let frameBorder = BorderImageView(image: "img/frameBorder.png", slice: 3, width: 3)
    let doily = BorderImageView(image: "img/doilyBorder.png", slice: 16, width: 6)
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false
        let inner = UIView()
        inner.clipsToBounds = true
        addSubview(marble); addSubview(shade)
        doily.alpha = 0.3
        addSubview(doily)
        addSubview(frameBorder)
        layer.shadowColor = UIColor.black.cgColor; layer.shadowOpacity = 0.5; layer.shadowRadius = px(2); layer.shadowOffset = .zero
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        marble.frame = bounds; shade.frame = bounds
        frameBorder.frame = bounds.insetBy(dx: -px(3), dy: -px(3))
        doily.frame = bounds.insetBy(dx: px(3), dy: px(3))
        for v in [marble, shade, doily, frameBorder] as [UIView] { sendSubviewToBack(v) }
        sendSubviewToBack(shade); sendSubviewToBack(marble)
        bringSubviewToFront(doily); bringSubviewToFront(frameBorder)
    }
}
