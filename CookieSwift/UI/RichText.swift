import UIKit

// The game's texts (descriptions, news, tooltips, stats...) are little bits of HTML. This turns them into
// styled text that lays out like the page did: the same fonts, sizes, colours, line height (line-height:1
// everywhere, from lib/style.css), paragraphs, quotes, icons and cost tags.

struct TextStyle {
    enum Family { case base, fancy, georgia, arial }
    var family: Family = .base
    var size: Double = 11
    var bold = false
    var italic = false
    var smallCaps = false
    var color: UIColor = .ccText
    var alpha: CGFloat = 1
    var align: NSTextAlignment = .left
    var shadow: NSShadow? = nil
    var letterSpacing: Double = 0
    var lineHeight: Double? = nil   // in multiples of the font size; nil = 1 (lib/style.css body{line-height:1})
    var textIndent: Double = 0
    var nowrap = false
    /// padding of <p> (4px; #statsData p has 2px)
    var pPad: Double = 4

    static let ticker: TextStyle = {
        var s = TextStyle(); s.family = .fancy; s.size = 14; s.color = .white; s.nowrap = true
        s.shadow = Shadows.top; return s
    }()
    static func fancy(_ size: Double, color: UIColor = .white) -> TextStyle {
        var s = TextStyle(); s.family = .fancy; s.size = size; s.color = color; return s
    }
    static func base(_ size: Double = 11, color: UIColor = .ccText) -> TextStyle {
        var s = TextStyle(); s.size = size; s.color = color; return s
    }

    func font() -> UIFont {
        var f: UIFont
        switch family {
        case .fancy: f = Fonts.fancy(size)
        case .georgia: f = Fonts.georgia(size, bold: bold, italic: italic)
        case .base, .arial:
            let name = bold && italic ? "Arial-BoldItalicMT" : bold ? "Arial-BoldMT" : italic ? "Arial-ItalicMT" : "ArialMT"
            f = UIFont(name: name, size: px(size)) ?? .systemFont(ofSize: px(size))
        }
        if family == .fancy && italic {
            // the browser slants a font that has no italic face (bold is faked with a stroke, see attributes)
            let m = CGAffineTransform(a: 1, b: 0, c: 0.2, d: 1, tx: 0, ty: 0)
            f = UIFont(descriptor: f.fontDescriptor.withMatrix(m), size: f.pointSize)
        }
        if smallCaps && family != .fancy && false {
            let d = f.fontDescriptor.addingAttributes([.featureSettings: [
                [UIFontDescriptor.FeatureKey.type: kLowerCaseType, UIFontDescriptor.FeatureKey.selector: kLowerCaseSmallCapsSelector]
            ]])
            f = UIFont(descriptor: d, size: f.pointSize)
        }
        return f
    }
}

/// CSS text-shadows (UIKit draws one shadow per run; the first visible one of each is used)
enum Shadows {
    static func make(_ x: Double, _ y: Double, _ blur: Double, _ color: UIColor = .black) -> NSShadow {
        let s = NSShadow(); s.shadowOffset = CGSize(width: px(x), height: px(y)); s.shadowBlurRadius = px(blur); s.shadowColor = color; return s
    }
    /// #topStuff: 0px 0px 2px #000,1px 1px 1px #000
    static let top = make(0.5, 0.5, 2)
    /// body: 1px 1px 0px #000
    static let body = make(1, 1, 0)
    /// .bar: 0px 0px 1px #000,1px 1px 0px rgba(0,0,0,0.5)
    static let bar = make(0.5, 0.5, 1)
    /// .cost: 1px 1px 0px #0f4b35,0px 0px 1px #000
    static let cost = make(1, 1, 0, UIColor(css: "#0f4b35"))
    static let costRed = make(1, 1, 0, UIColor(css: "#49091e"))
    /// .printText/.headerTitle: 0px -0.5px 0px #fff,0px 1px 2px #000
    static let print = make(0, 1, 2)
    /// .warning: 1px 1px 0px #000,0px 0px 4px #900
    static let warning = make(1, 1, 0)
    /// .buttonBox .button: 1px 1px 1px #000
    static let button = make(1, 1, 1)
    /// #tabs: 1px 1px 2px #000
    static let tabs = make(1, 1, 2)
}

enum RichText {
    // MARK: - entry points
    private static var cache: [String: NSAttributedString] = [:]

    /// Lays out `html` for a box `width` CSS px wide (nil = no wrapping)
    static func render(_ html: String, style: TextStyle, width: Double? = nil) -> NSAttributedString {
        let key = "\(style.family)|\(style.size)|\(style.bold)|\(style.color.hashValue)|\(style.align.rawValue)|\(width ?? -1)|\(style.shadow?.shadowOffset.width ?? -9)|\(style.alpha)|\(style.smallCaps)|\(style.pPad)|\(style.textIndent)|\(style.lineHeight ?? 0)|\(style.nowrap)|\(style.italic)|\(style.letterSpacing)|\(K)|\(html)"
        if let c = cache[key] { return c }
        let r = Builder(style: style, width: width).build(html)
        if cache.count > 1500 { cache.removeAll() }
        cache[key] = r
        return r
    }

    /// size of the laid-out text in CSS px
    static func size(_ s: NSAttributedString, width: Double?) -> CGSize {
        let w = width.map { px($0) } ?? .greatestFiniteMagnitude
        let r = s.boundingRect(with: CGSize(width: w, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return CGSize(width: ceil(r.width) / K, height: ceil(r.height) / K)
    }

    /// the text without tags (for measuring, accessibility, notifications)
    static func plain(_ html: String) -> String {
        var out = ""
        var i = html.startIndex
        while i < html.endIndex {
            if html[i] == "<", let close = html[i...].firstIndex(of: ">") { i = html.index(after: close); continue }
            out.append(html[i]); i = html.index(after: i)
        }
        return decodeEntities(out)
    }

    static func decodeEntities(_ s: String) -> String {
        guard s.contains("&") else { return s }
        var out = ""
        var i = s.startIndex
        while i < s.endIndex {
            if s[i] == "&", let semi = s[i...].prefix(12).firstIndex(of: ";") {
                let name = String(s[s.index(after: i)..<semi])
                if let rep = entity(name) { out += rep; i = s.index(after: semi); continue }
            }
            out.append(s[i]); i = s.index(after: i)
        }
        return out
    }
    private static func entity(_ n: String) -> String? {
        switch n {
        case "amp": return "&"
        case "lt": return "<"
        case "gt": return ">"
        case "quot": return "\""
        case "apos": return "'"
        case "nbsp": return "\u{00A0}"
        case "bull": return "•"
        case "times": return "×"
        case "mdash": return "—"
        case "ndash": return "–"
        case "hellip": return "…"
        case "eacute": return "é"
        case "egrave": return "è"
        case "ecirc": return "ê"
        case "agrave": return "à"
        case "ccedil": return "ç"
        case "ouml": return "ö"
        case "uuml": return "ü"
        case "auml": return "ä"
        case "deg": return "°"
        case "copy": return "©"
        case "laquo": return "«"
        case "raquo": return "»"
        case "rsquo": return "’"
        case "lsquo": return "‘"
        case "ldquo": return "“"
        case "rdquo": return "”"
        case "infin": return "∞"
        case "pi": return "π"
        case "frac12": return "½"
        case "trade": return "™"
        case "reg": return "®"
        case "hearts": return "♥"
        case "larr": return "←"
        case "rarr": return "→"
        default:
            if n.hasPrefix("#x"), let v = UInt32(n.dropFirst(2), radix: 16), let u = Unicode.Scalar(v) { return String(Character(u)) }
            if n.hasPrefix("#"), let v = UInt32(n.dropFirst()), let u = Unicode.Scalar(v) { return String(Character(u)) }
            return nil
        }
    }

    // MARK: - tiny CSS parser for style="" attributes
    static func parseStyle(_ s: String) -> [String: String] {
        var out: [String: String] = [:]
        for decl in s.split(separator: ";") {
            guard let c = decl.firstIndex(of: ":") else { continue }
            let k = decl[..<c].trimmingCharacters(in: .whitespaces).lowercased()
            let v = decl[decl.index(after: c)...].trimmingCharacters(in: .whitespaces)
            out[k] = v
        }
        return out
    }
    /// "12px" → 12, "80%" → 0.8 * relativeTo, "1.2em" → 1.2 * relativeTo
    static func length(_ v: String, relativeTo: Double) -> Double? {
        let t = v.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "!important", with: "").trimmingCharacters(in: .whitespaces)
        if t.hasSuffix("px") { return Double(t.dropLast(2)) }
        if t.hasSuffix("%") { return Double(t.dropLast()).map { $0 / 100 * relativeTo } }
        if t.hasSuffix("em") { return Double(t.dropLast(2)).map { $0 * relativeTo } }
        return Double(t)
    }
    /// "4px 8px" etc. → top right bottom left
    static func box(_ v: String, relativeTo: Double) -> (Double, Double, Double, Double) {
        let p = v.split(separator: " ").map { length(String($0), relativeTo: relativeTo) ?? 0 }
        switch p.count {
        case 1: return (p[0], p[0], p[0], p[0])
        case 2: return (p[0], p[1], p[0], p[1])
        case 3: return (p[0], p[1], p[2], p[1])
        case 4...: return (p[0], p[1], p[2], p[3])
        default: return (0, 0, 0, 0)
        }
    }

    // MARK: - the builder
    private struct Attr {
        var tag: String
        var classes: Set<String>
        var style: [String: String]
    }

    private final class Builder {
        var styles: [TextStyle]
        let width: Double?
        let out = NSMutableAttributedString()
        // block state
        struct Block { var align: NSTextAlignment; var left: Double; var right: Double; var indent: Double; var spaceBefore: Double; var spaceAfter: Double }
        var blocks: [Block] = []
        var pendingSpaceBefore = 0.0
        var atLineStart = true
        var paragraphStart = 0
        var openTags: [(String, Bool)] = []   // tag name, is block
        var blockPadBottom: [Double] = []
        var hidden = 0
        var noIndentNext = false

        init(style: TextStyle, width: Double?) {
            styles = [style]
            self.width = width
            blocks = [Block(align: style.align, left: 0, right: 0, indent: style.textIndent, spaceBefore: 0, spaceAfter: 0)]
        }
        var cur: TextStyle { styles[styles.count - 1] }

        func build(_ html: String) -> NSAttributedString {
            var i = html.startIndex
            var text = ""
            func flushText() {
                if !text.isEmpty { appendText(RichText.decodeEntities(text)); text = "" }
            }
            while i < html.endIndex {
                let c = html[i]
                if c == "<", let close = findTagEnd(html, from: i) {
                    flushText()
                    handleTag(String(html[html.index(after: i)..<close]))
                    i = html.index(after: close)
                    continue
                }
                text.append(c)
                i = html.index(after: i)
            }
            flushText()
            finishParagraph()
            // trailing newline makes boundingRect add an empty line
            while out.length > 0, out.string.hasSuffix("\n") { out.deleteCharacters(in: NSRange(location: out.length - 1, length: 1)) }
            return out
        }
        func findTagEnd(_ s: String, from: String.Index) -> String.Index? {
            var j = s.index(after: from)
            guard j < s.endIndex else { return nil }
            // a lone "<" followed by a space or digit is text (e.g. "<3", "a < b")
            let n = s[j]
            if !(n.isLetter || n == "/" || n == "!") { return nil }
            var quote: Character? = nil
            while j < s.endIndex {
                let ch = s[j]
                if let q = quote { if ch == q { quote = nil } }
                else if ch == "\"" || ch == "'" { quote = ch }
                else if ch == ">" { return j }
                j = s.index(after: j)
            }
            return nil
        }

        // MARK: text
        func attributes(_ st: TextStyle) -> [NSAttributedString.Key: Any] {
            let f = st.font()
            var a: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: st.color.withAlphaComponent(st.color.cgColor.alpha * st.alpha)]
            if let sh = st.shadow { a[.shadow] = sh }
            if st.letterSpacing != 0 { a[.kern] = px(st.letterSpacing) }
            if st.bold && st.family == .fancy {
                // the browser fakes bold for a font that has no bold face
                a[.strokeWidth] = -4.0
                a[.strokeColor] = a[.foregroundColor]
            }
            // line-height:1 → centre the glyphs in a line as tall as the font size (see paragraph())
            let natural = f.ascender - f.descender
            a[.baselineOffset] = -(natural - f.pointSize * CGFloat(st.lineHeight ?? 1)) / 2
            return a
        }
        func appendText(_ sIn: String) {
            if hidden > 0 { return }
            var s = sIn
            if !cur.nowrap || true {
                // collapse whitespace like HTML
                s = s.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "\t", with: " ")
                while s.contains("  ") { s = s.replacingOccurrences(of: "  ", with: " ") }
                if atLineStart { s = String(s.drop(while: { $0 == " " })) }
                if s.isEmpty { return }
                if s.hasPrefix(" "), out.string.hasSuffix(" ") { s.removeFirst() }
            }
            if cur.nowrap { s = s.replacingOccurrences(of: " ", with: "\u{00A0}") }
            if s.isEmpty { return }
            if cur.smallCaps {
                // fonts without real small capitals get them faked: lowercase letters as capitals at 70%
                var small = cur; small.smallCaps = false; small.size = cur.size * 0.7
                var big = cur; big.smallCaps = false
                let aBig = attributes(big)
                var aSmall = attributes(small)
                // keep the small letters on the same baseline as the big ones
                aSmall[.baselineOffset] = aBig[.baselineOffset]
                var run = "", runSmall = false
                func flush() { if !run.isEmpty { out.append(NSAttributedString(string: run, attributes: runSmall ? aSmall : aBig)); run = "" } }
                for ch in s {
                    let isSmall = ch.isLowercase
                    if isSmall != runSmall { flush(); runSmall = isSmall }
                    run += isSmall ? ch.uppercased() : String(ch)
                }
                flush()
                atLineStart = false
                return
            }
            out.append(NSAttributedString(string: s, attributes: attributes(cur)))
            atLineStart = false
        }
        func appendAttachment(_ img: UIImage?, w: Double, h: Double, kernBefore: Double = 0, kernAfter: Double = 0, raise: Double = 0) {
            if hidden > 0 { return }
            let att = NSTextAttachment()
            att.image = img
            let f = cur.font()
            // vertical-align:middle: the middle of the picture sits at the baseline + half the x-height
            let mid = f.xHeight / 2
            att.bounds = CGRect(x: 0, y: mid - px(h) / 2 + px(raise), width: px(w), height: px(h))
            if kernBefore != 0 {
                // a zero-width space carrying the negative kern pulls the picture left
                out.append(NSAttributedString(string: "\u{200B}", attributes: [.kern: px(kernBefore), .font: f]))
            }
            var a = attributes(cur)
            a[.kern] = px(kernAfter)
            a[.baselineOffset] = 0
            let s = NSMutableAttributedString(attachment: att)
            s.addAttributes(a, range: NSRange(location: 0, length: s.length))
            out.append(s)
            atLineStart = false
        }

        // MARK: paragraphs
        func paragraph() -> NSParagraphStyle {
            let b = blocks.last!
            let p = NSMutableParagraphStyle()
            p.alignment = b.align
            p.headIndent = px(b.left)
            p.firstLineHeadIndent = px(b.left + (noIndentNext ? 0 : b.indent))
            if b.right != 0 { p.tailIndent = -px(b.right) }
            let lh = CGFloat(cur.lineHeight ?? 1)
            let base = styles[0].font()
            _ = base
            p.lineBreakMode = cur.nowrap ? .byClipping : .byWordWrapping
            // line-height:1 → each line is as tall as the paragraph's font size
            let size = px(paragraphFontSize) * lh
            p.minimumLineHeight = size
            p.maximumLineHeight = size
            p.paragraphSpacingBefore = px(b.spaceBefore)
            return p
        }
        var paragraphFontSize: Double = 11
        func finishParagraph() {
            let range = NSRange(location: paragraphStart, length: out.length - paragraphStart)
            if range.length > 0 {
                out.addAttribute(.paragraphStyle, value: paragraph(), range: range)
                fixLineHeights(range)
            }
        }
        /// lines with bigger text get taller (like the CSS line box)
        func fixLineHeights(_ range: NSRange) {
            var maxSize: CGFloat = 0
            out.enumerateAttribute(.font, in: range) { v, _, _ in if let f = v as? UIFont { maxSize = max(maxSize, f.pointSize) } }
            let lh = CGFloat(cur.lineHeight ?? 1)
            if maxSize > 0, let p = (out.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle {
                p.minimumLineHeight = maxSize * lh
                p.maximumLineHeight = maxSize * lh
                out.addAttribute(.paragraphStyle, value: p, range: range)
            }
        }
        /// starts a new line/paragraph (block element boundary)
        func breakBlock(spaceBefore: Double = 0) {
            if out.length > paragraphStart {
                finishParagraph()
                out.append(NSAttributedString(string: "\n", attributes: attributes(cur)))
                paragraphStart = out.length
                atLineStart = true
                pendingSpaceBefore = 0
            }
            pendingSpaceBefore += spaceBefore
            paragraphFontSize = cur.size
            blocks[blocks.count - 1].spaceBefore = pendingSpaceBefore
            noIndentNext = false
        }

        // MARK: tags
        func handleTag(_ raw: String) {
            if raw.hasPrefix("!") { return }
            let closing = raw.hasPrefix("/")
            let body = closing ? String(raw.dropFirst()) : raw
            let selfClosing = body.hasSuffix("/")
            let nameEnd = body.firstIndex(where: { $0 == " " || $0 == "/" || $0 == "\n" || $0 == "\t" }) ?? body.endIndex
            let name = body[..<nameEnd].lowercased()
            if closing { close(name); return }
            let attrs = parseAttrs(String(body[nameEnd...]))
            open(name, attrs, selfClosing: selfClosing)
        }
        func parseAttrs(_ s: String) -> [String: String] {
            var out: [String: String] = [:]
            var i = s.startIndex
            while i < s.endIndex {
                while i < s.endIndex, s[i] == " " || s[i] == "/" || s[i] == "\n" || s[i] == "\t" { i = s.index(after: i) }
                guard i < s.endIndex else { break }
                let ks = i
                while i < s.endIndex, s[i] != "=" && s[i] != " " { i = s.index(after: i) }
                let key = s[ks..<i].lowercased()
                if i < s.endIndex, s[i] == "=" {
                    i = s.index(after: i)
                    guard i < s.endIndex else { break }
                    if s[i] == "\"" || s[i] == "'" {
                        let q = s[i]; i = s.index(after: i)
                        let vs = i
                        while i < s.endIndex, s[i] != q { i = s.index(after: i) }
                        out[key] = String(s[vs..<i])
                        if i < s.endIndex { i = s.index(after: i) }
                    } else {
                        let vs = i
                        while i < s.endIndex, s[i] != " " { i = s.index(after: i) }
                        out[key] = String(s[vs..<i])
                    }
                } else { out[key] = "" }
            }
            return out
        }

        static let blockTags: Set<String> = ["div", "p", "h3", "line", "br", "trim", "ul", "li", "h1", "h2", "h4", "center"]

        func open(_ name: String, _ attrs: [String: String], selfClosing: Bool) {
            let classes = Set((attrs["class"] ?? "").split(separator: " ").map(String.init))
            let css = RichText.parseStyle(attrs["style"] ?? "")
            var st = cur
            st.nowrap = st.nowrap || css["white-space"] == "nowrap"
            switch name {
            case "br":
                if hidden == 0 {
                    finishParagraph()
                    out.append(NSAttributedString(string: "\n", attributes: attributes(cur)))
                    paragraphStart = out.length
                    atLineStart = true
                    blocks[blocks.count - 1].spaceBefore = 0
                    noIndentNext = true
                }
                return
            case "line":
                // a thin fading line, 90% wide, 6px margins
                breakBlock(spaceBefore: 6)
                let w = (width ?? 200) - blocks.last!.left - blocks.last!.right
                let saveAlign = blocks[blocks.count - 1].align
                blocks[blocks.count - 1].align = .center
                appendAttachment(Decor.fadeLine(width: w * 0.9), w: w * 0.9, h: 3, raise: 0)
                paragraphFontSize = 3
                breakBlock(spaceBefore: 6)
                blocks[blocks.count - 1].align = saveAlign
                if !selfClosing { openTags.append(("line-skip", false)) }
                return
            case "img":
                return
            default: break
            }
            // element defaults
            var isBlock = Builder.blockTags.contains(name)
            var padTop = 0.0, padBottom = 0.0, padLeft = 0.0, padRight = 0.0
            var indent: Double? = nil
            var align: NSTextAlignment? = nil
            var before: (() -> Void)? = nil
            switch name {
            case "b", "strong": st.bold = true
            case "i", "em": st.italic = true
            case "small": st.size *= 0.8
            case "big": st.size *= 1.2
            case "u": break
            case "p": padTop = cur.pPad; padBottom = cur.pPad; indent = 8
            case "h3":
                st.family = .fancy; st.size = 15; st.smallCaps = true; align = .center; padTop = 8; padBottom = 8
            case "q":
                st.italic = true; st.family = .georgia
                before = { [unowned self] in
                    var qs = self.cur; qs.size = 14; qs.bold = true; qs.italic = false; qs.family = .georgia
                    self.out.append(NSAttributedString(string: "“", attributes: self.attributes(qs)))
                    self.atLineStart = false
                }
            case "sig":
                st.size *= 0.7; st.alpha *= 0.7
                before = { [unowned self] in
                    self.out.append(NSAttributedString(string: "\u{2003}-", attributes: self.attributes(self.cur)))
                    self.atLineStart = false
                }
            default: break
            }
            // classes
            for c in classes {
                switch c {
                case "fancy": st.family = .fancy
                case "warning": st.color = UIColor(css: "#c00"); st.shadow = Shadows.warning
                case "green": st.color = UIColor(css: "#6f6")
                case "red": st.color = UIColor(css: "#f66")
                case "printText": st.family = .georgia; st.bold = true; st.shadow = Shadows.print
                case "smallHeader", "headerTitle": st.family = .georgia; st.bold = true; st.shadow = Shadows.print; align = .center
                case "tag":
                    st.family = .arial; st.size = 10; st.color = .black; st.bold = true
                case "cost":
                    st.size = 11; st.color = UIColor(css: "#9fff38"); st.shadow = Shadows.cost
                    if classes.contains("cantAfford") { st.color = UIColor(css: "#ff5134"); st.shadow = Shadows.costRed }
                    if classes.contains("neutralCost") { st.color = .white; st.shadow = cur.shadow }
                    if !classes.contains("otherCost") {
                        // .cost:before: a little cookie (or heavenly chip) in front
                        let heavenly = classes.contains("heavenlyCost")
                        before = { [unowned self] in
                            self.appendAttachment(Res.image(heavenly ? "img/heavenlyMoney.png" : "img/cookicon.png"), w: 11.2, h: 11.2, kernBefore: 0.4, kernAfter: 0.4)
                        }
                    }
                case "hidden", "debugOnly": hidden += 1; openTags.append(("hidden", false)); return
                case "chromaFocus": st.color = UIColor(css: "#fcc"); st.shadow = Shadows.top
                case "title": isBlock = false
                default: break
                }
            }
            // inline styles
            if let v = css["display"] {
                if v == "none" { hidden += 1; openTags.append(("hidden", false)); return }
                if v == "block" || v == "flex" { isBlock = true }
                if v.hasPrefix("inline") { isBlock = false }
            }
            if let v = css["font-size"], let s = RichText.length(v, relativeTo: cur.size) { st.size = s }
            if let v = css["font-weight"] { st.bold = v == "bold" || (Int(v) ?? 400) >= 600 }
            if let v = css["font-style"] { st.italic = v == "italic" }
            if let v = css["font-variant"] { st.smallCaps = v.contains("small-caps") }
            if let v = css["font-family"] {
                let l = v.lowercased()
                if l.contains("fancy") { st.family = .fancy } else if l.contains("georgia") { st.family = .georgia } else if l.contains("arial") || l.contains("tahoma") { st.family = .base }
            }
            if let v = css["color"] { st.color = UIColor(css: v) }
            if let v = css["opacity"], let o = Double(v) { st.alpha *= CGFloat(o) }
            if let v = css["letter-spacing"], let s = RichText.length(v, relativeTo: st.size) { st.letterSpacing = s }
            if let v = css["text-shadow"] { st.shadow = v == "none" ? nil : Shadows.top }
            if let v = css["line-height"] {
                if v.hasSuffix("%") { st.lineHeight = (Double(v.dropLast()) ?? 100) / 100 }
                else if v.hasSuffix("px") { st.lineHeight = (Double(v.dropLast(2)) ?? st.size) / st.size }
                else if let d = Double(v) { st.lineHeight = d }
            }
            if let v = css["text-align"] { align = v == "center" ? .center : v == "right" ? .right : v == "justify" ? .justified : .left }
            if let v = css["text-indent"], let s = RichText.length(v, relativeTo: st.size) { indent = s }
            var marginTop = 0.0, marginBottom = 0.0, marginLeft = 0.0, marginRight = 0.0
            if let v = css["margin"] { (marginTop, marginRight, marginBottom, marginLeft) = RichText.box(v, relativeTo: width ?? 0) }
            if let v = css["padding"] { (padTop, padRight, padBottom, padLeft) = RichText.box(v, relativeTo: width ?? 0) }
            if let v = css["margin-top"] { marginTop = RichText.length(v, relativeTo: 0) ?? 0 }
            if let v = css["margin-bottom"] { marginBottom = RichText.length(v, relativeTo: 0) ?? 0 }
            if let v = css["margin-left"] { marginLeft = RichText.length(v, relativeTo: 0) ?? 0 }
            if let v = css["margin-right"] { marginRight = RichText.length(v, relativeTo: 0) ?? 0 }
            if let v = css["padding-top"] { padTop = RichText.length(v, relativeTo: 0) ?? 0 }
            if let v = css["padding-bottom"] { padBottom = RichText.length(v, relativeTo: 0) ?? 0 }
            if let v = css["padding-left"] { padLeft = RichText.length(v, relativeTo: 0) ?? 0 }
            if let v = css["padding-right"] { padRight = RichText.length(v, relativeTo: 0) ?? 0 }

            // pictures
            if classes.contains("icon") || classes.contains("tinyIcon") || classes.contains("tinyCookie") || classes.contains("tinyHeavenly") || classes.contains("usesIcon") {
                inlinePicture(classes, css)
                if !selfClosing { openTags.append(("pic", false)); hidden += 1 }
                return
            }

            if isBlock {
                breakBlock(spaceBefore: max(0, marginTop) + padTop)
                var b = blocks.last!
                b.left += marginLeft + padLeft
                b.right += marginRight + padRight
                if let a = align { b.align = a }
                if let ind = indent { b.indent = ind } else if name != "p" { b.indent = blocks.last!.indent }
                b.spaceBefore = pendingSpaceBefore
                blocks.append(b)
                styles.append(st)
                paragraphFontSize = st.size
                blockPadBottom.append(max(0, marginBottom) + padBottom)
                openTags.append((name, true))
            } else {
                if let a = align, atLineStart { blocks[blocks.count - 1].align = a }
                styles.append(st)
                openTags.append((name, false))
            }
            before?()
        }
        func inlinePicture(_ classes: Set<String>, _ css: [String: String]) {
            var bx = 0.0, by = 0.0
            if let v = css["background-position"] {
                let p = v.split(separator: " ").map { RichText.length(String($0), relativeTo: 0) ?? 0 }
                if p.count >= 2 { bx = p[0]; by = p[1] } else if p.count == 1 { bx = p[0] }
            }
            if classes.contains("tinyHeavenly") {
                appendAttachment(Res.image("img/heavenlyMoney.png"), w: 11.2, h: 11.2, kernBefore: 0.4, kernAfter: 0.4)
                return
            }
            if classes.contains("tinyCookie") {
                appendAttachment(Res.image("img/cookicon.png"), w: 11.2, h: 11.2, kernBefore: 0.4, kernAfter: 0.4)
                return
            }
            var sheet = "img/icons.png"
            if let bg = css["background-image"] ?? css["background"], let r = bg.range(of: "url(") {
                let rest = bg[r.upperBound...]
                if let e = rest.firstIndex(of: ")") { sheet = String(rest[..<e]).trimmingCharacters(in: CharacterSet(charactersIn: "'\" ")) }
            }
            let img = Res.sprite(sheet, x: -bx, y: -by, w: 48, h: 48)
            if classes.contains("tinyIcon") {
                // 48px box scaled to 0.5, margins -12px right / -26px left: 24px picture that starts 14px before the pen
                appendAttachment(img, w: 24, h: 24, kernBefore: -14, kernAfter: 0)
            } else {
                // G.icon: inline-block, margin:-24px 4px → takes no height, 4px each side
                appendAttachment(img, w: 48, h: 48, kernBefore: 4, kernAfter: 4)
            }
        }
        func close(_ name: String) {
            guard let idx = openTags.lastIndex(where: { $0.0 == name || ($0.0 == "hidden") || $0.0 == "pic" || $0.0 == "line-skip" }) else { return }
            let (tag, isBlock) = openTags[idx]
            if tag == "line-skip" { openTags.remove(at: idx); return }
            if tag == "hidden" || tag == "pic" { hidden = max(0, hidden - 1); openTags.remove(at: idx); return }
            // close anything left open inside
            while openTags.count > idx + 1 { let t = openTags.removeLast(); popOne(t) }
            openTags.removeLast()
            if tag == "q" {
                var qs = cur; qs.size = 14; qs.bold = true; qs.italic = false; qs.family = .georgia
                out.append(NSAttributedString(string: "”", attributes: attributes(qs)))
            }
            popOne((tag, isBlock), already: true)
        }
        func popOne(_ t: (String, Bool), already: Bool = false) {
            if t.0 == "hidden" || t.0 == "pic" { hidden = max(0, hidden - 1); return }
            if t.0 == "line-skip" { return }
            if t.1 {
                let pad = blockPadBottom.popLast() ?? 0
                finishParagraph()
                if blocks.count > 1 { blocks.removeLast() }
                if styles.count > 1 { styles.removeLast() }
                if out.length > paragraphStart || true {
                    if out.length > 0 && !out.string.hasSuffix("\n") {
                        out.append(NSAttributedString(string: "\n", attributes: attributes(cur)))
                    }
                    paragraphStart = out.length
                    atLineStart = true
                }
                pendingSpaceBefore = pad
                blocks[blocks.count - 1].spaceBefore = pad
                paragraphFontSize = cur.size
            } else {
                if styles.count > 1 { styles.removeLast() }
            }
        }
    }
}

/// Decorations drawn in code (gradient lines and the like)
enum Decor {
    private static var cache: [String: UIImage] = [:]
    /// <line>: linear-gradient(to right, transparent, rgba(255,255,255,0.25), transparent) 1px high,
    /// with darker lines just above and below
    static func fadeLine(width: Double) -> UIImage? {
        let key = "line\(width)"
        if let c = cache[key] { return c }
        let size = CGSize(width: px(width), height: px(3))
        let fmt = UIGraphicsImageRendererFormat(); fmt.scale = UIScreen.main.scale; fmt.opaque = false
        let img = UIGraphicsImageRenderer(size: size, format: fmt).image { ctx in
            let c = ctx.cgContext
            let cs = CGColorSpaceCreateDeviceRGB()
            func band(_ y: CGFloat, _ color: UIColor) {
                let g = CGGradient(colorsSpace: cs, colors: [color.withAlphaComponent(0).cgColor, color.cgColor, color.withAlphaComponent(0).cgColor] as CFArray, locations: [0, 0.5, 1])!
                c.saveGState()
                c.clip(to: CGRect(x: 0, y: y, width: size.width, height: px(1)))
                c.drawLinearGradient(g, start: .zero, end: CGPoint(x: size.width, y: 0), options: [])
                c.restoreGState()
            }
            band(0, UIColor(white: 0, alpha: 0.25))
            band(px(1), UIColor(white: 1, alpha: 0.25))
            band(px(2), UIColor(white: 0, alpha: 0.25))
        }
        cache[key] = img
        return img
    }
    /// a horizontal gradient bar image of any colours
    static func hGradient(width: Double, height: Double, colors: [UIColor], locations: [CGFloat]? = nil) -> UIImage {
        let size = CGSize(width: max(1, px(width)), height: max(1, px(height)))
        let fmt = UIGraphicsImageRendererFormat(); fmt.scale = UIScreen.main.scale; fmt.opaque = false
        return UIGraphicsImageRenderer(size: size, format: fmt).image { ctx in
            let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors.map { $0.cgColor } as CFArray, locations: locations)!
            ctx.cgContext.drawLinearGradient(g, start: .zero, end: CGPoint(x: size.width, y: 0), options: [])
        }
    }
}

/// A label for game HTML, sized in CSS px.
final class RichLabel: UIView {
    var html: String = "" { didSet { if html != oldValue { rebuild() } } }
    var style: TextStyle { didSet { rebuild() } }
    /// wrap width in CSS px (nil = the view's own width)
    var wrapWidth: Double? = nil
    private var text = NSAttributedString()
    init(_ style: TextStyle = TextStyle()) {
        self.style = style
        super.init(frame: .zero)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
        contentMode = .redraw
    }
    required init?(coder: NSCoder) { fatalError() }
    private var builtFor: CGFloat = -1
    private func rebuild() {
        let w = wrapWidth ?? (bounds.width > 0 ? Double(bounds.width / K) : nil)
        text = RichText.render(html, style: style, width: style.nowrap ? nil : w)
        builtFor = bounds.width
        setNeedsDisplay()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if builtFor != bounds.width { rebuild() }
    }
    /// areas the text flows around (floats), in CSS px
    var exclusions: [CGRect] = [] { didSet { setNeedsDisplay() } }
    private func textKit(_ t: NSAttributedString, width: CGFloat) -> (NSLayoutManager, NSTextContainer, NSTextStorage) {
        let storage = NSTextStorage(attributedString: t)
        let lm = NSLayoutManager()
        let tc = NSTextContainer(size: CGSize(width: width, height: 100000))
        tc.lineFragmentPadding = 0
        tc.exclusionPaths = exclusions.map { UIBezierPath(rect: CGRect(x: px($0.minX), y: px($0.minY), width: px($0.width), height: px($0.height))) }
        lm.addTextContainer(tc)
        storage.addLayoutManager(lm)
        lm.ensureLayout(for: tc)
        // the storage owns the layout manager, so it's handed back to keep it alive
        return (lm, tc, storage)
    }
    /// height in CSS px for a width in CSS px
    func fittingHeight(_ width: Double) -> Double {
        let t = RichText.render(html, style: style, width: width)
        if !exclusions.isEmpty {
            let (lm, tc, st) = textKit(t, width: px(width))
            return withExtendedLifetime(st) { Double(ceil(lm.usedRect(for: tc).maxY) / K) }
        }
        return Double(RichText.size(t, width: width).height)
    }
    var textSize: CGSize { RichText.size(text, width: style.nowrap ? nil : Double(bounds.width / K)) }
    override func draw(_ rect: CGRect) {
        if style.nowrap {
            // one line: place it ourselves (alignment needs a width)
            let w = text.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).width
            var x: CGFloat = 0
            if style.align == .center { x = (bounds.width - w) / 2 } else if style.align == .right { x = bounds.width - w }
            text.draw(with: CGRect(x: x, y: 0, width: w + 2, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            return
        }
        if !exclusions.isEmpty {
            let (lm, tc, st) = textKit(text, width: bounds.width)
            withExtendedLifetime(st) {
                let r = lm.glyphRange(for: tc)
                lm.drawBackground(forGlyphRange: r, at: .zero)
                lm.drawGlyphs(forGlyphRange: r, at: .zero)
            }
            return
        }
        text.draw(with: CGRect(x: 0, y: 0, width: bounds.width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
    }
}
