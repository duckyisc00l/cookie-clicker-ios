import UIKit

// Building blocks that match the page's CSS: buttons, inset borders, gradients, the CSS animations.

// MARK: - CSS animations (triggerAnim in www/lib/main.js restarts a CSS animation on an element)

enum Anim {
    /// keyframes as (time 0...1, scaleX, scaleY, rotation degrees)
    private static func keyframes(_ frames: [(Double, Double, Double, Double)], base: CATransform3D = CATransform3DIdentity) -> [NSValue] {
        frames.map { f in
            var t = CATransform3DScale(base, CGFloat(f.1), CGFloat(f.2), 1)
            t = CATransform3DRotate(t, CGFloat(f.3 * .pi / 180), 0, 0, 1)
            return NSValue(caTransform3D: t)
        }
    }
    static func trigger(_ v: UIView?, _ name: String) {
        guard let v = v else { return }
        let l = v.layer
        let base = l.transform
        let a = CAKeyframeAnimation(keyPath: "transform")
        var frames: [(Double, Double, Double, Double)] = []
        var dur = 0.1
        // the final frame is "{}" (back to the element's own transform)
        switch name {
        case "plop": frames = [(0, 1.1, 0.8, 0), (0.5, 0.9, 1.1, 0), (1, 1, 1, 0)]; dur = 0.1
        case "plopHalf":
            // the quick buttons are scale(0.5) themselves
            frames = [(0, 1.1, 0.8, 0), (0.5, 0.9, 1.1, 0), (1, 1, 1, 0)]; dur = 0.1
        case "plopHeavy": frames = [(0, 1.5, 0.5, -10), (0.3, 0.6, 1.3, 10), (0.6, 1.1, 0.9, -5), (1, 1, 1, 0)]; dur = 0.25
        default: return
        }
        a.values = keyframes(frames, base: base)
        a.keyTimes = frames.map { NSNumber(value: $0.0) }
        a.duration = dur
        l.removeAnimation(forKey: "trigger")
        l.add(a, forKey: "trigger")
    }
    /// .squish: endless gentle squash (quick buttons, pets)
    static func squish(_ v: UIView, on: Bool) {
        if !on { v.layer.removeAnimation(forKey: "squish"); return }
        if v.layer.animation(forKey: "squish") != nil { return }
        let a = CAKeyframeAnimation(keyPath: "transform")
        a.values = keyframes([(0, 1.05, 0.95, 0), (0.65, 0.95, 1.05, 0), (1, 1.05, 0.95, 0)], base: v.layer.transform)
        a.keyTimes = [0, 0.65, 1]
        a.duration = 0.5
        a.repeatCount = .infinity
        a.timingFunctions = [CAMediaTimingFunction(name: .easeInEaseOut), CAMediaTimingFunction(name: .easeInEaseOut)]
        v.layer.add(a, forKey: "squish")
    }
    /// .fadeOpen: scale 0.5 → 1 and fade in, 0.1s
    static func fadeOpen(_ v: UIView, duration: Double = 0.1, from: CGFloat = 0.5) {
        let s = CABasicAnimation(keyPath: "transform.scale"); s.fromValue = from; s.toValue = 1
        let o = CABasicAnimation(keyPath: "opacity"); o.fromValue = 0; o.toValue = 1
        let g = CAAnimationGroup(); g.animations = [s, o]; g.duration = duration
        g.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        v.layer.add(g, forKey: "fadeOpen")
    }
    /// switchLeft / switchRight / switchLeftIn / switchRightIn / switchTopIn: the 3D flip between screens and panels (0.2s)
    static func switchAnim(_ v: UIView, _ name: String, perspective: CGFloat = 800, duration: Double = 0.2, removeOnEnd: Bool = false, completion: (() -> Void)? = nil) {
        let w = v.bounds.width, h = v.bounds.height
        var p = CATransform3DIdentity
        p.m34 = -1 / (px(Double(perspective)))
        func t(_ tx: CGFloat, _ ty: CGFloat, _ ry: CGFloat, _ rx: CGFloat) -> NSValue {
            var m = CATransform3DTranslate(p, tx, ty, 0)
            if ry != 0 { m = CATransform3DRotate(m, ry * .pi / 180, 0, 1, 0) }
            if rx != 0 { m = CATransform3DRotate(m, rx * .pi / 180, 1, 0, 0) }
            return NSValue(caTransform3D: m)
        }
        var from: NSValue, to: NSValue, oFrom: Float, oTo: Float
        switch name {
        case "switchLeft": from = t(0, 0, 0, 0); to = t(-w, 0, 90, 0); oFrom = 1; oTo = 0
        case "switchRight": from = t(0, 0, 0, 0); to = t(w, 0, -90, 0); oFrom = 1; oTo = 0
        case "switchLeftIn": from = t(-w, 0, 90, 0); to = t(0, 0, 0, 0); oFrom = 0; oTo = 1
        case "switchRightIn": from = t(w, 0, -90, 0); to = t(0, 0, 0, 0); oFrom = 0; oTo = 1
        case "switchTopIn": from = t(0, h, 0, -90); to = t(0, 0, 0, 0); oFrom = 0; oTo = 1
        default: return
        }
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        let a = CABasicAnimation(keyPath: "transform"); a.fromValue = from; a.toValue = to
        let o = CABasicAnimation(keyPath: "opacity"); o.fromValue = oFrom; o.toValue = oTo
        let g = CAAnimationGroup(); g.animations = [a, o]; g.duration = duration
        g.timingFunction = CAMediaTimingFunction(name: .easeOut)
        if removeOnEnd || oTo == 0 { g.fillMode = .forwards; g.isRemovedOnCompletion = false }
        v.layer.add(g, forKey: "switch")
        CATransaction.commit()
    }
}

// MARK: - inset box shadows

/// Draws the bevel of `.bumpy` / `.bumpButton`:
/// box-shadow: 0 0 0 1px #000 inset, 0 2px 0 rgba(255,255,255,0.2) inset, 0 0 0 2px rgba(255,255,255,0.1) inset; border-radius:4px
final class BevelView: UIView {
    enum Kind { case bump, wood, none }
    var kind: Kind = .bump { didSet { setNeedsDisplay() } }
    var radius: Double = 4 { didSet { setNeedsDisplay() } }
    init(_ kind: Kind = .bump) {
        self.kind = kind
        super.init(frame: .zero)
        isOpaque = false; backgroundColor = .clear; isUserInteractionEnabled = false; contentMode = .redraw
    }
    required init?(coder: NSCoder) { fatalError() }
    override func draw(_ rect: CGRect) {
        guard let c = UIGraphicsGetCurrentContext() else { return }
        let b = bounds
        let r = px(radius)
        let path = UIBezierPath(roundedRect: b, cornerRadius: r)
        c.saveGState()
        path.addClip()
        func ring(_ inset: CGFloat, _ color: UIColor) {
            let outer = UIBezierPath(roundedRect: b, cornerRadius: r)
            let inner = UIBezierPath(roundedRect: b.insetBy(dx: inset, dy: inset), cornerRadius: max(0, r - inset))
            outer.append(inner); outer.usesEvenOddFillRule = true
            color.setFill(); outer.fill()
        }
        switch kind {
        case .bump:
            ring(px(2), UIColor(white: 1, alpha: 0.1))
            // top band: the shape moved down 2px, everything outside it
            let outer = UIBezierPath(roundedRect: b, cornerRadius: r)
            let inner = UIBezierPath(roundedRect: b.offsetBy(dx: 0, dy: px(2)), cornerRadius: r)
            outer.append(inner); outer.usesEvenOddFillRule = true
            c.saveGState(); UIBezierPath(rect: CGRect(x: 0, y: 0, width: b.width, height: b.height / 2)).addClip()
            UIColor(white: 1, alpha: 0.2).setFill(); outer.fill(); c.restoreGState()
            ring(px(1), .black)
        case .wood:
            // 1px 1px 0px rgba(197,157,121,0.75) inset, -1px -1px 0px rgba(32,16,9,0.75) inset
            let light = UIColor(red: 197 / 255, green: 157 / 255, blue: 121 / 255, alpha: 0.75)
            let dark = UIColor(red: 32 / 255, green: 16 / 255, blue: 9 / 255, alpha: 0.75)
            func band(_ dx: CGFloat, _ dy: CGFloat, _ color: UIColor) {
                let outer = UIBezierPath(roundedRect: b, cornerRadius: r)
                let inner = UIBezierPath(roundedRect: b.offsetBy(dx: dx, dy: dy), cornerRadius: r)
                outer.append(inner); outer.usesEvenOddFillRule = true
                color.setFill(); outer.fill()
            }
            band(-px(1), -px(1), dark)
            band(px(1), px(1), light)
        case .none: break
        }
        c.restoreGState()
    }
}

/// A view with a CSS linear-gradient background (to bottom / to right) and optional rounded corners.
final class GradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }
    var g: CAGradientLayer { layer as! CAGradientLayer }
    init(_ colors: [UIColor], vertical: Bool = true, locations: [NSNumber]? = nil) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        set(colors, vertical: vertical, locations: locations)
    }
    required init?(coder: NSCoder) { fatalError() }
    func set(_ colors: [UIColor], vertical: Bool = true, locations: [NSNumber]? = nil) {
        g.colors = colors.map { $0.cgColor }
        g.locations = locations
        g.startPoint = vertical ? CGPoint(x: 0.5, y: 0) : CGPoint(x: 0, y: 0.5)
        g.endPoint = vertical ? CGPoint(x: 0.5, y: 1) : CGPoint(x: 1, y: 0.5)
    }
    /// linear-gradient(to bottom,rgba(255,255,255,0.1) 0%,rgba(0,0,0,0.1) 100%) used by many buttons
    static func buttonShade() -> GradientView { GradientView([UIColor(white: 1, alpha: 0.1), UIColor(white: 0, alpha: 0.1)]) }
}

// MARK: - buttons (G.button)

/// A tappable element. Like G.onclick it fires on release ("click"); `down` fires on touch start (G.ondown).
class TapView: UIView {
    var onTap: ((TapView) -> Void)?
    var onDown: ((TapView, CGPoint) -> Void)?
    var onUp: ((TapView) -> Void)?
    /// .button:active{filter:brightness(2)}
    var brightensWhenPressed = false
    private var pressed = false { didSet { if brightensWhenPressed { highlight.isHidden = !pressed } } }
    private let highlight = UIView()
    private var startPoint: CGPoint = .zero
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        isExclusiveTouch = false
        highlight.isUserInteractionEnabled = false
        highlight.backgroundColor = UIColor(white: 1, alpha: 0.18)
        highlight.isHidden = true
        highlight.layer.compositingFilter = "linearDodgeBlendMode"
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        if brightensWhenPressed {
            if highlight.superview == nil { addSubview(highlight) }
            bringSubviewToFront(highlight)
            highlight.frame = bounds
            highlight.layer.cornerRadius = layer.cornerRadius
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        pressed = true
        startPoint = touches.first?.location(in: window) ?? .zero
        if let d = onDown { d(self, touches.first?.location(in: window) ?? .zero) }
        if onDown == nil && onTap == nil { super.touchesBegan(touches, with: event) }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if onDown == nil && onTap == nil { super.touchesMoved(touches, with: event) }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let wasPressed = pressed
        pressed = false
        onUp?(self)
        if wasPressed, let t = touches.first, bounds.insetBy(dx: -px(8), dy: -px(8)).contains(t.location(in: self)), !G.panning {
            onTap?(self)
        }
        if onDown == nil && onTap == nil { super.touchesEnded(touches, with: event) }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        pressed = false
        onUp?(self)
        if onDown == nil && onTap == nil { super.touchesCancelled(touches, with: event) }
    }
}

/// `<div class="button bumpButton">text</div>` and friends: a label in a bevelled box.
final class CCButton: TapView {
    enum Look { case bump, wood, plain, popupClose, state, wide, magic, magicOff }
    let label = RichLabel()
    let bevel = BevelView()
    private var shade: GradientView?
    var look: Look
    var on = false { didSet { if on != oldValue { restyle() } } }
    var padding: UIEdgeInsets
    var font: TextStyle { didSet { label.style = font } }

    init(_ text: String, look: Look = .bump, font: TextStyle? = nil, padding: UIEdgeInsets? = nil, onTap: ((TapView) -> Void)? = nil) {
        self.look = look
        var f = font ?? TextStyle.base(11, color: .ccText)
        if font == nil { f.bold = true; f.shadow = Shadows.body }
        self.font = f
        self.padding = padding ?? UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        super.init(frame: .zero)
        brightensWhenPressed = true
        self.onTap = onTap
        label.style = f
        label.style.align = .center
        label.html = text
        if look == .popupClose || look == .state || look == .wide {
            let s = GradientView.buttonShade(); shade = s; addSubview(s)
        }
        if look == .magic || look == .magicOff {
            // .magicButton: purple gradient, glowing; .off: grey and not pressable
            let s = look == .magic ? GradientView([UIColor(red: 0, green: 0, blue: 64 / 255, alpha: 0.5), UIColor(red: 153 / 255, green: 0, blue: 1, alpha: 0.5)])
                                   : GradientView([UIColor(white: 0, alpha: 0.5), UIColor(white: 128 / 255, alpha: 0.5)])
            shade = s; addSubview(s)
            layer.shadowColor = (look == .magic ? UIColor(css: "#90f") : UIColor(css: "#999")).cgColor
            layer.shadowOpacity = 1; layer.shadowRadius = px(3); layer.shadowOffset = .zero
            if look == .magicOff { alpha = 0.8; isUserInteractionEnabled = false }
        }
        addSubview(bevel)
        addSubview(label)
        restyle()
    }
    required init?(coder: NSCoder) { fatalError() }
    var text: String { get { label.html } set { label.html = newValue } }
    private func restyle() {
        layer.cornerRadius = look == .plain ? 0 : px(4)
        switch look {
        case .bump, .popupClose, .state, .wide:
            bevel.kind = .bump
            backgroundColor = on ? UIColor(white: 1, alpha: 0.1) : .clear
        case .wood:
            bevel.kind = .wood
            // .onWood .button: background rgba(32,16,9,0.5) and an outer 1px dark glow
            backgroundColor = on ? UIColor(white: 1, alpha: 0.1) : UIColor(red: 32 / 255, green: 16 / 255, blue: 9 / 255, alpha: 0.5)
            layer.shadowColor = UIColor(red: 32 / 255, green: 16 / 255, blue: 9 / 255, alpha: 1).cgColor
            layer.shadowOpacity = 1; layer.shadowRadius = px(1); layer.shadowOffset = .zero
        case .plain:
            bevel.kind = .none
            backgroundColor = on ? UIColor(white: 1, alpha: 0.1) : .clear
        case .magic, .magicOff:
            bevel.kind = .none
            layer.cornerRadius = px(6)
        }
        var f = font
        if on && (look == .wood || look == .bump) { f.color = .white }
        if look == .magic { f.color = UIColor(css: "#cff") }
        label.style = f
        label.style.align = .center
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        bevel.frame = bounds
        shade?.frame = bounds
        shade?.layer.cornerRadius = layer.cornerRadius
        shade?.clipsToBounds = true
        let p = padding
        let inner = CGRect(x: px(Double(p.left)), y: 0, width: bounds.width - px(Double(p.left + p.right)), height: bounds.height)
        let h = CGFloat(label.fittingHeight(Double(inner.width / K))) * K
        // text sits at the top padding, like a block box
        label.frame = CGRect(x: inner.minX, y: px(Double(p.top)), width: inner.width, height: max(h, bounds.height - px(Double(p.top + p.bottom))))
    }
    /// height of this button for a width (CSS px), from its padding and text
    func fittingHeight(width: Double) -> Double {
        let inner = width - Double(padding.left + padding.right)
        return label.fittingHeight(inner) + Double(padding.top + padding.bottom)
    }
}

// MARK: - G.stateButton: a wide ON/OFF button tied to a setting

final class StateButton: TapView {
    let label = RichLabel(TextStyle.fancy(11, color: .ccText))
    let stateL = RichLabel(TextStyle.fancy(11, color: .ccText))
    let comment = RichLabel(TextStyle.base(10, color: .ccText))
    let bevel = BevelView(.bump)
    let shade = GradientView.buttonShade()
    var setting: String?
    var invert = false
    var fixedState: String?
    var onPress: ((StateButton) -> Void)?
    init(text: String, comment: String? = nil, setting: String? = nil, invert: Bool = false, state: String? = nil, onPress: ((StateButton) -> Void)? = nil) {
        self.setting = setting; self.invert = invert; self.fixedState = state; self.onPress = onPress
        super.init(frame: .zero)
        brightensWhenPressed = true
        layer.cornerRadius = px(4)
        clipsToBounds = true
        addSubview(shade); addSubview(bevel)
        label.html = text
        label.style.shadow = Shadows.body
        stateL.style.shadow = Shadows.body
        stateL.style.align = .center
        addSubview(label); addSubview(stateL)
        if let c = comment { self.comment.html = c; self.comment.style.alpha = 0.5; self.comment.style.shadow = Shadows.body; addSubview(self.comment) }
        self.onTap = { [weak self] _ in
            guard let self = self else { return }
            if let p = self.onPress { p(self) }
            else if let s = self.setting { G.setSet(s, G.getSet(s) == 0 ? 1 : 0) }
            self.update()
            PlaySound("snd/tick.mp3", 0.5)
        }
        update()
    }
    required init?(coder: NSCoder) { fatalError() }
    func update() {
        var state = fixedState ?? "OFF"
        if let s = setting {
            let v = G.getSet(s)
            if invert { if v == 1 { state = "OFF" } else if v == 0 { state = "ON" } }
            else { if v == 0 { state = "OFF" } else if v == 1 { state = "ON" } }
        }
        stateL.html = state
        if state == "ON" {
            // .stateButton.on
            shade.set([UIColor(white: 1, alpha: 0.2), UIColor(white: 1, alpha: 0.1)])
            stateL.style.color = UIColor(css: "#9f6"); stateL.style.shadow = Shadows.make(0, 0, 4, UIColor(css: "#693")); stateL.alpha = 1
        } else {
            shade.set([UIColor(white: 1, alpha: 0.1), UIColor(white: 0, alpha: 0.1)])
            stateL.style.color = .ccText; stateL.style.shadow = Shadows.body
            stateL.alpha = state == "OFF" ? 0.5 : 1
        }
    }
    /// padding 8px 16px; label 70% wide; state on the right 30%
    func height(width: Double) -> Double {
        let lw = (width - 32) * 0.7
        var h = 8 + label.fittingHeight(lw)
        if comment.superview != nil { h += comment.fittingHeight(width - 32) }
        return h + 8
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        shade.frame = bounds; bevel.frame = bounds
        let w = Double(bounds.width / K)
        let lw = (w - 32) * 0.7
        let lh = label.fittingHeight(lw)
        label.frame = CGRect(x: px(16), y: px(8), width: px(lw), height: px(lh))
        stateL.frame = CGRect(x: px(w * 0.7 + 16), y: px(8), width: px(w * 0.3 - 32), height: px(stateL.fittingHeight(w * 0.3 - 32)))
        if comment.superview != nil {
            comment.frame = CGRect(x: px(16), y: px(8 + lh), width: px(w - 32), height: px(comment.fittingHeight(w - 32)))
        }
    }
}

// MARK: - icons

/// a 48x48 icon from icons.png (or another sheet), drawn sharp
final class IconView: UIView {
    private let img = UIImageView()
    var icon: [Int] = [0, 0] { didSet { if icon != oldValue { update() } } }
    var sheet = "img/icons.png" { didSet { update() } }
    /// drop-shadow when the "shadows" setting is on
    var shadowed = false { didSet { applyShadow() } }
    init(_ icon: [Int] = [0, 0]) {
        self.icon = icon
        super.init(frame: CGRect(x: 0, y: 0, width: px(48), height: px(48)))
        isUserInteractionEnabled = false
        img.frame = bounds
        img.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        img.contentMode = .scaleToFill
        img.layer.magnificationFilter = .linear
        addSubview(img)
        update()
    }
    required init?(coder: NSCoder) { fatalError() }
    private func update() {
        img.image = Res.sprite(sheet, x: Double(icon[0] * 48), y: Double(icon[1] * 48), w: 48, h: 48)
    }
    private func applyShadow() {
        if shadowed && G.getSet("shadows") != 0 {
            // .shadowsOn .icon{filter:drop-shadow(2px 2px 2px rgba(0,0,0,0.65))}
            layer.shadowColor = UIColor.black.cgColor; layer.shadowOpacity = 0.65
            layer.shadowOffset = CGSize(width: px(2), height: px(2)); layer.shadowRadius = px(1)
        } else { layer.shadowOpacity = 0 }
    }
}

/// a picture or a piece of a sprite sheet stretched to the view (background-size:100% 100%)
final class PicView: UIImageView {
    init(_ path: String? = nil) {
        super.init(image: path.flatMap { Res.image($0) })
        isUserInteractionEnabled = false
        contentMode = .scaleToFill
    }
    required init?(coder: NSCoder) { fatalError() }
    var path: String? { didSet { if path != oldValue { image = path.flatMap { Res.image($0) } } } }
}

/// a pattern-filled view (background repeat), with an offset (background-position) in CSS px
final class PatternView: UIView {
    private var tileKey = ""
    var path: String { didSet { if path != oldValue { refresh() } } }
    var tileSize: CGSize? { didSet { refresh() } }
    var offset: CGPoint = .zero { didSet { if offset != oldValue { layer.setNeedsDisplay() } } }
    private var tile: UIImage?
    init(_ path: String, tileSize: CGSize? = nil) {
        self.path = path; self.tileSize = tileSize
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        isOpaque = false
        contentMode = .redraw
        refresh()
    }
    required init?(coder: NSCoder) { fatalError() }
    private func refresh() {
        tile = Res.image(path)
        setNeedsDisplay()
    }
    override func draw(_ rect: CGRect) {
        guard let t = tile else { return }
        let ts = tileSize ?? t.size
        let w = px(ts.width), h = px(ts.height)
        guard w > 1, h > 1 else { return }
        var ox = px(offset.x).truncatingRemainder(dividingBy: w); if ox > 0 { ox -= w }
        var oy = px(offset.y).truncatingRemainder(dividingBy: h); if oy > 0 { oy -= h }
        var y = oy
        while y < rect.maxY {
            if y + h >= rect.minY {
                var x = ox
                while x < rect.maxX {
                    if x + w >= rect.minX { t.draw(in: CGRect(x: x, y: y, width: w, height: h)) }
                    x += w
                }
            }
            y += h
        }
    }
}

/// A plain scrolling area (overflow-y:auto) holding content laid out in CSS px
class ScrollArea: UIScrollView {
    let content = UIView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(content)
        indicatorStyle = .white
        alwaysBounceVertical = true
        delaysContentTouches = false
        canCancelContentTouches = true
        showsHorizontalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
    }
    required init?(coder: NSCoder) { fatalError() }
    override func touchesShouldCancel(in view: UIView) -> Bool { true }
    func setContentHeight(_ h: CGFloat) {
        content.frame = CGRect(x: 0, y: 0, width: bounds.width, height: h)
        contentSize = CGSize(width: bounds.width, height: max(h, 0))
    }
}

// MARK: - layout helpers

/// Stacks views top to bottom like blocks in a page (heights in CSS px)
struct Flow {
    var y: Double = 0
    let width: Double
    let parent: UIView
    var x: Double = 0
    init(in parent: UIView, width: Double, x: Double = 0, y: Double = 0) { self.parent = parent; self.width = width; self.x = x; self.y = y }
    /// adds a rich text block
    @discardableResult
    mutating func text(_ html: String, style: TextStyle = TextStyle(), marginTop: Double = 0, marginBottom: Double = 0, inset: Double = 0) -> RichLabel {
        y += marginTop
        let l = RichLabel(style)
        l.html = html
        let w = width - inset * 2
        let h = l.fittingHeight(w)
        l.frame = CGRect(x: px(x + inset), y: px(y), width: px(w), height: px(h))
        parent.addSubview(l)
        y += h + marginBottom
        return l
    }
    mutating func view(_ v: UIView, height: Double, marginTop: Double = 0, marginBottom: Double = 0, inset: Double = 0) {
        y += marginTop
        v.frame = CGRect(x: px(x + inset), y: px(y), width: px(width - inset * 2), height: px(height))
        parent.addSubview(v)
        y += height + marginBottom
    }
    mutating func space(_ h: Double) { y += h }
}
