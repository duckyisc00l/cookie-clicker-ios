import UIKit

// Layout basics shared by every screen.
// The original lays the game out in a page 320 CSS pixels wide, scaled up to the screen width
// (www/lib/main.js: G.resize). Here every size is written in those CSS pixels and multiplied by `K`.

/// screen points per CSS pixel
var K: CGFloat = UIScreen.main.bounds.width / 320
@inline(__always) func px(_ v: Double) -> CGFloat { CGFloat(v) * K }
@inline(__always) func px(_ v: CGFloat) -> CGFloat { v * K }
@inline(__always) func px(_ v: Int) -> CGFloat { CGFloat(v) * K }

/// the notch and home bar, in CSS px (the web version's --cc-sat / --cc-sab)
enum Layout {
    static var sat = 0.0
    static var sab = 0.0
}

enum Fonts {
    static var registered = false
    static func register() {
        if registered { return }
        registered = true
        for name in ["Kavoon-Regular", "Merriweather-Black"] {
            if let url = Res.url("img/\(name).ttf") { CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil) }
        }
    }
    /// font-family:Fancy (Kavoon)
    static func fancy(_ size: Double) -> UIFont { UIFont(name: "Kavoon-Regular", size: px(size)) ?? .boldSystemFont(ofSize: px(size)) }
    /// the page's base font (Tahoma, Arial, sans-serif: iOS has no Tahoma, so Arial)
    static func base(_ size: Double, bold: Bool = false) -> UIFont {
        UIFont(name: bold ? "Arial-BoldMT" : "ArialMT", size: px(size)) ?? .systemFont(ofSize: px(size), weight: bold ? .bold : .regular)
    }
    static func georgia(_ size: Double, bold: Bool = false, italic: Bool = false) -> UIFont {
        let name = bold && italic ? "Georgia-BoldItalic" : bold ? "Georgia-Bold" : italic ? "Georgia-Italic" : "Georgia"
        return UIFont(name: name, size: px(size)) ?? .systemFont(ofSize: px(size))
    }
}

/// Colours written like CSS
extension UIColor {
    convenience init(css: String) {
        var s = css.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") {
            s.removeFirst()
            if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
            let v = UInt32(s, radix: 16) ?? 0
            self.init(red: CGFloat((v >> 16) & 255) / 255, green: CGFloat((v >> 8) & 255) / 255, blue: CGFloat(v & 255) / 255, alpha: 1)
            return
        }
        if s.hasPrefix("rgba(") || s.hasPrefix("rgb(") {
            let inner = s.drop(while: { $0 != "(" }).dropFirst().prefix(while: { $0 != ")" })
            let parts = inner.split(separator: ",").map { Double($0.trimmingCharacters(in: .whitespaces)) ?? 0 }
            self.init(red: CGFloat(parts[0]) / 255, green: CGFloat(parts[1]) / 255, blue: CGFloat(parts[2]) / 255, alpha: parts.count > 3 ? CGFloat(parts[3]) : 1)
            return
        }
        let named: [String: UInt32] = ["white": 0xffffff, "black": 0x000000, "red": 0xff0000, "transparent": 0]
        if s == "transparent" { self.init(white: 0, alpha: 0); return }
        let v = named[s] ?? 0xcccccc
        self.init(red: CGFloat((v >> 16) & 255) / 255, green: CGFloat((v >> 8) & 255) / 255, blue: CGFloat(v & 255) / 255, alpha: 1)
    }
    static let ccText = UIColor(css: "#ccc")
}

/// Pictures. The app has sharp (AI-upscaled) copies of most pictures in hd/ with their original sizes
/// listed in hd/manifest.json; they're used at the original's size, like the previous version did.
enum Res {
    static let root = Bundle.main.resourceURL!
    static func url(_ path: String) -> URL? {
        let u = root.appendingPathComponent(path)
        return FileManager.default.fileExists(atPath: u.path) ? u : nil
    }
    private static var cache: [String: UIImage] = [:]
    private static let hdManifest: [String: [Double]] = {
        guard let u = url("hd/manifest.json"), let d = try? Data(contentsOf: u),
              let o = try? JSONSerialization.jsonObject(with: d) as? [String: [Double]] else { return [:] }
        return o
    }()
    /// the only sharper picture kept: the big cookie
    private static let hdKept: Set<String> = ["perfectCookie.png"]
    /// The app's own versions of some pictures (new buildings and icons) replace the game's.
    private static let overrides: Set<String> = ["img/icons.png", "img/buildings.png"]

    /// An image by its path in the original game ("img/goldCookie.png"), at its original size in CSS pixels
    /// (UIImage.size is in CSS px, scale holds the extra detail).
    static func image(_ path: String) -> UIImage? {
        if let i = cache[path] { return i }
        let file = (path as NSString).lastPathComponent
        let base = (file as NSString).deletingPathExtension
        var img: UIImage? = nil
        if hdKept.contains(file), let size = hdManifest[file], let u = url("hd/\(base).webp"), let data = try? Data(contentsOf: u), let raw = UIImage(data: data), let cg = raw.cgImage {
            let scale = CGFloat(cg.width) / CGFloat(size[0])
            img = UIImage(cgImage: cg, scale: scale, orientation: .up)
        }
        if img == nil {
            let candidates = overrides.contains(path) ? ["override/" + file, path] : [path, "mgimg/" + file]
            for c in candidates {
                if let u = url(c), let raw = UIImage(contentsOfFile: u.path), let cg = raw.cgImage {
                    img = UIImage(cgImage: cg, scale: 1, orientation: .up); break
                }
            }
        }
        if let i = img, let cg = i.cgImage, let d = decoded(cg) {
            // decode once: crops of a lazily-decoded picture would decode the whole file again every time
            img = UIImage(cgImage: d, scale: i.scale, orientation: .up)
        }
        if let i = img { cache[path] = i }
        return img
    }
    private static func decoded(_ cg: CGImage) -> CGImage? {
        let w = cg.width, h = cg.height
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        return ctx.makeImage()
    }

    /// a cropped piece of a sprite sheet, in CSS px (background-position -x -y, size w h)
    private static var spriteCache: [String: UIImage] = [:]
    static func sprite(_ path: String, x: Double, y: Double, w: Double, h: Double) -> UIImage? {
        let key = "\(path)|\(x)|\(y)|\(w)|\(h)"
        if let i = spriteCache[key] { return i }
        guard let sheet = image(path), let cg = sheet.cgImage else { return nil }
        let s = sheet.scale
        let rect = CGRect(x: CGFloat(x) * s, y: CGFloat(y) * s, width: CGFloat(w) * s, height: CGFloat(h) * s).integral
        guard let piece = cg.cropping(to: rect) else { return nil }
        let img = UIImage(cgImage: piece, scale: s, orientation: .up)
        if spriteCache.count > 3000 { spriteCache.removeAll() }
        spriteCache[key] = img
        return img
    }
    /// a 48x48 icon from icons.png
    static func icon(_ icon: [Int]) -> UIImage? {
        guard icon.count >= 2 else { return nil }
        return sprite("img/icons.png", x: Double(icon[0] * 48), y: Double(icon[1] * 48), w: 48, h: 48)
    }
}

/// text-shadow:0px 0px 2px #000,1px 1px 1px #000 and friends
enum Shadow {
    static func apply(_ layer: CALayer, x: Double = 1, y: Double = 1, blur: Double = 1, color: UIColor = .black, opacity: Float = 1) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = CGSize(width: px(x), height: px(y))
        layer.shadowRadius = px(blur) / 2
        layer.shadowOpacity = opacity
    }
}

/// A view laid out in CSS px.
extension UIView {
    func frameCSS(_ x: Double, _ y: Double, _ w: Double, _ h: Double) { frame = CGRect(x: px(x), y: px(y), width: px(w), height: px(h)) }
}

/// A view showing part of a picture like a CSS background (position + optional size), optionally repeating.
final class BGView: UIView {
    private let imgLayer = CALayer()
    var path: String? { didSet { if path != oldValue { update() } } }
    /// background-position in CSS px
    var pos: CGPoint = .zero { didSet { if pos != oldValue { update() } } }
    /// background-size in CSS px (nil = the picture's own size)
    var bgSize: CGSize? = nil { didSet { update() } }
    var repeats = false { didSet { update() } }
    init(_ path: String? = nil) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        clipsToBounds = true
        layer.addSublayer(imgLayer)
        self.path = path
        update()
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() { super.layoutSubviews(); update() }
    private func update() {
        CATransaction.begin(); CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }
        guard let p = path, let img = Res.image(p) else { imgLayer.contents = nil; backgroundColor = nil; return }
        let size = bgSize ?? img.size
        if repeats {
            imgLayer.contents = nil
            // a pattern image in the right scale
            let fmt = UIGraphicsImageRendererFormat(); fmt.scale = UIScreen.main.scale
            let tile = UIGraphicsImageRenderer(size: CGSize(width: px(size.width), height: px(size.height)), format: fmt).image { _ in
                img.draw(in: CGRect(x: 0, y: 0, width: px(size.width), height: px(size.height)))
            }
            imgLayer.frame = .zero
            backgroundColor = UIColor(patternImage: tile)
            layer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: 1)
            // background-position for patterns: shift with bounds origin
            bounds.origin = CGPoint(x: -px(pos.x), y: -px(pos.y))
        } else {
            backgroundColor = nil
            imgLayer.contents = img.cgImage
            imgLayer.contentsScale = img.scale
            imgLayer.frame = CGRect(x: px(pos.x), y: px(pos.y), width: px(size.width), height: px(size.height))
        }
    }
}
