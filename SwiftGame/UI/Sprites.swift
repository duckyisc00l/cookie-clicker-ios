import SwiftUI
import UIKit

/// Loads the game's original art from the app bundle and cuts icons out of the sprite sheets.
enum Sprites {
    private static var images: [String: UIImage] = [:]
    private static var crops: [String: UIImage] = [:]
    private static let lock = NSLock()
    private static let hdManifest: [String: (Int, Int)] = {
        guard let url = Bundle.main.url(forResource: "manifest", withExtension: "json", subdirectory: "hd"),
              let d = try? Data(contentsOf: url), let o = try? JSONSerialization.jsonObject(with: d) as? [String: [Int]] else { return [:] }
        var m: [String: (Int, Int)] = [:]
        for (k, v) in o where v.count == 2 { m[k] = (v[0], v[1]) }
        return m
    }()

    /// name like "perfectCookie.png" or "img/perfectCookie.png" or "minigames/gardenPlants.png"
    static func ui(_ nameIn: String) -> UIImage? {
        let name = nameIn.hasPrefix("img/") ? String(nameIn.dropFirst(4)) : nameIn
        lock.lock(); defer { lock.unlock() }
        if let i = images[name] { return i }
        let file = (name as NSString).lastPathComponent
        let base = (file as NSString).deletingPathExtension
        let ext = (file as NSString).pathExtension
        var found: UIImage? = nil
        // sharper art first (same size in points, more pixels)
        if let size = hdManifest[file], let url = Bundle.main.url(forResource: base, withExtension: "webp", subdirectory: "hd"),
           let data = try? Data(contentsOf: url), let img = UIImage(data: data), let cg = img.cgImage, size.0 > 0 {
            found = UIImage(cgImage: cg, scale: CGFloat(cg.width) / CGFloat(size.0), orientation: .up)
        }
        if found == nil {
            for d in ["override", "img", "minigames"] {
                if let url = Bundle.main.url(forResource: base, withExtension: ext, subdirectory: d),
                   let img = UIImage(contentsOfFile: url.path) { found = img; break }
            }
        }
        if let f = found { images[name] = f }
        return found
    }

    static func image(_ name: String) -> Image {
        if let u = ui(name) { return Image(uiImage: u) }
        return Image(systemName: "questionmark.square.dashed")
    }

    /// a cell of a sprite sheet (x, y in cells of size w×h pixels)
    static func cell(_ sheet: String, _ x: Int, _ y: Int, _ w: Int = 48, _ h: Int = 48) -> UIImage? {
        let key = "\(sheet)|\(x)|\(y)|\(w)|\(h)"
        lock.lock()
        if let c = crops[key] { lock.unlock(); return c }
        lock.unlock()
        guard let img = ui(sheet), let cg = img.cgImage else { return nil }
        let scale = CGFloat(cg.width) / img.size.width
        let rect = CGRect(x: CGFloat(x * w) * scale, y: CGFloat(y * h) * scale, width: CGFloat(w) * scale, height: CGFloat(h) * scale)
        guard rect.maxX <= CGFloat(cg.width), rect.maxY <= CGFloat(cg.height), let c = cg.cropping(to: rect) else { return nil }
        let out = UIImage(cgImage: c, scale: scale, orientation: .up)
        lock.lock(); crops[key] = out; lock.unlock()
        return out
    }

    static func icon(_ icon: [Int]) -> Image {
        guard icon.count >= 2, let c = cell("icons.png", icon[0], icon[1]) else { return Image(systemName: "square") }
        return Image(uiImage: c)
    }
}

/// An icon from the 48×48 icon sheet, drawn at `size` points.
struct IconView: View {
    let icon: [Int]
    var size: CGFloat = 48
    var body: some View {
        Sprites.icon(icon).resizable().interpolation(.high).frame(width: size, height: size)
    }
}

struct SheetCell: View {
    let sheet: String
    let x: Int, y: Int
    var w: Int = 48, h: Int = 48
    var width: CGFloat? = nil, height: CGFloat? = nil
    var body: some View {
        Group {
            if let c = Sprites.cell(sheet, x, y, w, h) { Image(uiImage: c).resizable().interpolation(.high) }
            else { Color.clear }
        }
        .frame(width: width ?? CGFloat(w), height: height ?? CGFloat(h))
    }
}

/// A tiled background image (like CSS background-repeat).
struct Tiled: View {
    let name: String
    var scale: CGFloat = 1
    var body: some View {
        if let img = Sprites.ui(name) {
            let scaled = UIImage(cgImage: img.cgImage!, scale: img.scale / scale, orientation: .up)
            Rectangle().fill(ImagePaint(image: Image(uiImage: scaled), scale: 1))
        } else { Color.black }
    }
}

extension Font {
    /// "Fancy" = Kavoon, the game's display font
    static func fancy(_ size: CGFloat) -> Font { .custom("Kavoon-Regular", size: size) }
    static func merri(_ size: CGFloat) -> Font { .custom("Merriweather-Black", size: size) }
}

extension View {
    /// the game's text outline/shadow
    func gameShadow() -> some View {
        self.shadow(color: .black, radius: 1, x: 0, y: 0).shadow(color: .black, radius: 0, x: 1, y: 1)
    }
}
