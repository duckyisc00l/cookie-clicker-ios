import SwiftUI

/// Shows the game's text, which uses a few HTML tags (<b>, <br>, <small>, <q>...), as styled text.
struct RichText: View {
    let html: String
    var size: CGFloat = 12
    var color: Color = .white
    var font: Font? = nil
    var align: TextAlignment = .leading
    var body: some View {
        Text(RichText.attributed(html, size: size, color: color, base: font))
            .multilineTextAlignment(align)
            .fixedSize(horizontal: false, vertical: true)
    }

    private static var cache: [String: AttributedString] = [:]

    static func plain(_ html: String) -> String {
        String(attributed(html, size: 12, color: .white, base: nil).characters)
    }

    static func attributed(_ html: String, size: CGFloat, color: Color, base: Font?) -> AttributedString {
        let key = "\(size)|\(html)"
        if base == nil, let c = cache[key] { return c }
        var out = AttributedString()
        var bold = 0, italic = 0, small = 0, quote = 0
        var colors: [Color] = []
        var i = html.startIndex
        var buf = ""
        func flush() {
            guard !buf.isEmpty else { return }
            var s = AttributedString(decode(buf))
            let sz = size * (small > 0 ? 0.8 : 1)
            var f = base ?? Font.system(size: sz)
            if base != nil { f = base! }
            if bold > 0 { f = f.bold() }
            if italic > 0 || quote > 0 { f = f.italic() }
            s.font = f
            s.foregroundColor = colors.last ?? (quote > 0 ? color.opacity(0.75) : color)
            out += s
            buf = ""
        }
        while i < html.endIndex {
            let c = html[i]
            if c == "<", let close = html[i...].firstIndex(of: ">") {
                flush()
                let tag = html[html.index(after: i)..<close].lowercased()
                let name = tag.split(whereSeparator: { $0 == " " || $0 == "/" }).first.map(String.init) ?? ""
                let closing = tag.hasPrefix("/")
                let cname = closing ? String(tag.dropFirst()).split(separator: " ").first.map(String.init) ?? "" : name
                switch cname {
                case "b", "strong": bold += closing ? -1 : 1
                case "i", "em": italic += closing ? -1 : 1
                case "small": small += closing ? -1 : 1
                case "q":
                    if closing { quote -= 1; buf += "\u{201D}" } else { quote += 1; out += AttributedString("\n"); buf += "\u{201C}" }
                case "sig": if !closing { buf += "\n– " }
                case "br": out += AttributedString("\n")
                case "div", "p", "h3", "line":
                    if !out.characters.isEmpty && out.characters.last != "\n" { out += AttributedString("\n") }
                    if cname == "h3" { bold += closing ? -1 : 1 }
                case "span", "font":
                    if closing { if !colors.isEmpty { colors.removeLast() } }
                    else if let col = colorIn(tag) { colors.append(col) } else { colors.append(colors.last ?? color) }
                default: break
                }
                i = html.index(after: close)
                continue
            }
            buf.append(c)
            i = html.index(after: i)
        }
        flush()
        if base == nil { cache[key] = out }
        return out
    }

    private static func colorIn(_ tag: String) -> Color? {
        if tag.contains("class=\"green\"") || tag.contains("class='green'") { return Color(red: 0.6, green: 1, blue: 0.22) }
        if tag.contains("class=\"red\"") || tag.contains("class='red'") { return Color(red: 1, green: 0.32, blue: 0.2) }
        guard let r = tag.range(of: "color:") else { return nil }
        let rest = tag[r.upperBound...].trimmingCharacters(in: .whitespaces)
        if rest.hasPrefix("#") {
            let hex = rest.dropFirst().prefix { $0.isHexDigit }
            return Color(hex: String(hex))
        }
        return nil
    }

    static func decode(_ s: String) -> String {
        guard s.contains("&") else { return s }
        var r = s
        for (k, v) in ["&bull;": "•", "&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&#39;": "'", "&nbsp;": " ", "&times;": "×", "&mdash;": "—", "&hellip;": "…", "&eacute;": "é"] {
            r = r.replacingOccurrences(of: k, with: v)
        }
        return r
    }
}

extension Color {
    init(hex: String) {
        var h = hex
        if h.count == 3 { h = h.map { "\($0)\($0)" }.joined() }
        let v = UInt64(h, radix: 16) ?? 0xffffff
        self.init(red: Double((v >> 16) & 0xff) / 255, green: Double((v >> 8) & 0xff) / 255, blue: Double(v & 0xff) / 255)
    }
    static let costGreen = Color(red: 0x9f / 255.0, green: 1, blue: 0x38 / 255.0)
    static let costRed = Color(red: 1, green: 0x51 / 255.0, blue: 0x34 / 255.0)
}
