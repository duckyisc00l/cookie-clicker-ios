import Foundation

// Helpers that behave exactly like the JavaScript ones the original game relies on
// (Math.random / Math.seedrandom, choose, cap, romanize, Beautify, sayTime...).
// Sources: www/lib/main.js (helpers, seedrandom) and www/main.js (Beautify, BeautifyTime, sayTime).

// MARK: - Math.random and Math.seedrandom (David Bau's seedrandom, as bundled in lib/main.js)

/// The ARC4 generator used by seedrandom.
private final class ARC4 {
    var i = 0, j = 0
    var S = [Int](repeating: 0, count: 256)
    init(_ keyIn: [Int]) {
        var key = keyIn
        var keylen = key.count
        if keylen == 0 { key = [keylen]; keylen += 1 }
        for n in 0..<256 { S[n] = n }
        var jj = 0
        for n in 0..<256 {
            let t = S[n]
            jj = 255 & (jj + key[n % keylen] + t)
            S[n] = S[jj]
            S[jj] = t
        }
        i = 0; j = 0
        _ = g(256)
    }
    func g(_ countIn: Int) -> Double {
        var count = countIn
        var r = 0.0
        var ii = i, jj = j
        while count > 0 {
            count -= 1
            ii = 255 & (ii + 1)
            let t = S[ii]
            jj = 255 & (jj + t)
            S[ii] = S[jj]
            S[jj] = t
            r = r * 256 + Double(S[255 & (S[ii] + S[jj])])
        }
        i = ii; j = jj
        return r
    }
}

enum JSMath {
    private static var arc4: ARC4? = nil
    private static var pool = [Int](repeating: 0, count: 256)

    /// Math.random(): the system generator, or the seeded one after seedrandom(seed).
    static func random() -> Double {
        guard let a = arc4 else { return Double.random(in: 0..<1) }
        // significance = 2^52, overflow = 2^53, startdenom = 2^48
        var n = a.g(6), d = 281474976710656.0, x = 0.0
        while n < 4503599627370496.0 {
            n = (n + x) * 256
            d *= 256
            x = a.g(1)
        }
        while n >= 9007199254740992.0 {
            n /= 2; d /= 2
            x = Double(Int(x) >> 1)
        }
        return (n + x) / d
    }

    /// Math.seedrandom(seed): makes Math.random() repeatable for that seed.
    /// Math.seedrandom() with no seed goes back to unpredictable numbers.
    static func seedrandom(_ seed: String? = nil) {
        guard let seed = seed else { arc4 = nil; return }
        var key: [Int] = []
        mixkey(seed, &key)
        let gen = ARC4(key)
        // the library also mixes the generator's state into its entropy pool
        mixkey(String(gen.S.map { Character(UnicodeScalar(UInt8($0))) }), &pool)
        arc4 = gen
    }

    private static func mixkey(_ s: String, _ key: inout [Int]) {
        var smear = 0
        // charCodeAt works on UTF-16 code units
        let units = Array(s.utf16)
        var j = 0
        while j < units.count {
            let idx = 255 & j
            while key.count <= idx { key.append(0) }
            smear ^= key[idx] * 19
            key[idx] = 255 & (smear + Int(units[j]))
            j += 1
        }
    }
}

/// choose(arr): a random element, with Math.random (so it follows seedrandom).
func choose<T>(_ arr: [T]) -> T { arr[Int((JSMath.random() * Double(arr.count)).rounded(.down))] }
func rnd() -> Double { JSMath.random() }
func cap(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }
/// Date.now()
func nowMs() -> Double { (Date().timeIntervalSince1970 * 1000).rounded(.down) }

func romanize(_ num: Int) -> String {
    // lib/main.js romanize: the last 3 digits with the key table, then one "M" per thousand
    var digits = Array(String(num)).map { Int(String($0)) ?? 0 }
    let key = ["", "C", "CC", "CCC", "CD", "D", "DC", "DCC", "DCCC", "CM",
               "", "X", "XX", "XXX", "XL", "L", "LX", "LXX", "LXXX", "XC",
               "", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"]
    var roman = ""
    var i = 3
    while i > 0 {
        i -= 1
        let d = digits.popLast()
        roman = (d.map { key[$0 + i * 10] } ?? "") + roman
    }
    let rest = digits.isEmpty ? 0 : Int(digits.map(String.init).joined()) ?? 0
    return String(repeating: "M", count: rest) + roman
}
func randomFloor(_ x: Double) -> Double { x.truncatingRemainder(dividingBy: 1) < JSMath.random() ? x.rounded(.down) : x.rounded(.up) }
func shuffle<T>(_ arr: inout [T]) {
    var i = arr.count - 1
    while i > 0 {
        let j = Int((JSMath.random() * Double(i + 1)).rounded(.down))
        arr.swapAt(i, j)
        i -= 1
    }
}

// MARK: - Number formatting (Beautify / B)

enum Fmt {
    static let short: [String] = {
        var list = ["k", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No"]
        let prefixes = ["", "Un", "Do", "Tr", "Qa", "Qi", "Sx", "Sp", "Oc", "No"]
        let suffixes = ["D", "V", "T", "Qa", "Qi", "Sx", "Sp", "O", "N"]
        for s in suffixes { for p in prefixes { list.append(" " + p + s) } }
        list[10] = "Dc"
        return list
    }()
    static let long: [String] = {
        var list = [" thousand", " million", " billion", " trillion", " quadrillion", " quintillion", " sextillion", " septillion", " octillion", " nonillion"]
        let prefixes = ["", "un", "duo", "tre", "quattuor", "quin", "sex", "septen", "octo", "novem"]
        let suffixes = ["decillion", "vigintillion", "trigintillion", "quadragintillion", "quinquagintillion", "sexagintillion", "septuagintillion", "octogintillion", "nonagintillion"]
        for s in suffixes { for p in prefixes { list.append(" " + p + s) } }
        return list
    }()

    /// numberFormatter in use: 0 short, 1 long, 2 raw
    static var formatter = 0

    static func everyThirdPower(_ vIn: Double, _ notations: [String]) -> String {
        var val = vIn
        var base = 0
        var notation = ""
        if !val.isFinite { return "Inf." }
        if val >= 1_000_000 {
            val /= 1000
            while jsRound(val) >= 1000 { val /= 1000; base += 1 }
            if base >= notations.count { return "Inf." }
            notation = notations[base]
        }
        return jsString(jsRound(val * 10) / 10) + notation
    }
    static func raw(_ val: Double) -> String {
        jsString(val > 1_000_000_000_000 ? jsRound(val) : jsRound(val * 1000) / 1000)
    }
    /// The /\B(?=(\d{3})+(?!\d))/g comma insertion: commas in every run of 4+ digits.
    static func commas(_ s: String) -> String {
        var out = ""
        var run = ""
        func flush() {
            if run.count > 3 {
                for (i, c) in run.enumerated() {
                    if i > 0 && (run.count - i) % 3 == 0 { out.append(",") }
                    out.append(c)
                }
            } else { out += run }
            run = ""
        }
        for c in s {
            if c.isASCII && c.isNumber { run.append(c) } else { flush(); out.append(c) }
        }
        flush()
        return out
    }

    static func B(_ valIn: Double, _ floats: Int = 0, _ format: Int = 0) -> String {
        var val = valIn
        var negative = val < 0
        var decimal = ""
        let fixed = jsToFixed(val, floats)
        let fixedNum = Double(fixed) ?? val
        if floats > 0 && abs(val) < 1000 && fixedNum.rounded(.down) != fixedNum {
            decimal = "." + (fixed.split(separator: ".").count > 1 ? String(fixed.split(separator: ".")[1]) : "")
        }
        val = abs(val).rounded(.down)
        if floats > 0 && fixedNum == val + 1 { val += 1 }
        let f = format != 0 ? format : formatter
        var output: String
        if jsString(val).contains("e+") && format == 2 {
            output = jsToPrecision(val, 3)
        } else {
            let s: String
            switch f {
            case 1: s = everyThirdPower(val, long)
            case 2: s = raw(val)
            default: s = everyThirdPower(val, short)
            }
            output = commas(s)
        }
        if output == "0" { negative = false }
        return negative ? "-" + output : output + decimal
    }

    /// BeautifyTime (BT), value in seconds
    static func BT(_ valueIn: Double) -> String {
        var value = valueIn.rounded(.up)
        let years = (value / 31536000).rounded(.down); value -= years * 31536000
        let days = (value / 86400).rounded(.down); value -= days * 86400
        let hours = Int((value / 3600).rounded(.down)) % 24; value -= Double(hours) * 3600
        let minutes = Int((value / 60).rounded(.down)) % 60; value -= Double(minutes) * 60
        let seconds = Int(value.rounded(.down)) % 60
        var str = ""
        if years != 0 { str += B(years) + "Y" }
        if days != 0 || str != "" { str += B(days) + "d" }
        if hours != 0 || str != "" { str += "\(hours)h" }
        if minutes != 0 || str != "" { str += "\(minutes)m" }
        if seconds != 0 || str != "" { str += "\(seconds)s" }
        if str == "" { str += "0s" }
        return str
    }

    /// sayTime: time in milliseconds
    static func sayTime(_ timeIn: Double, _ detail: Int = 0, _ mini: Bool = false) -> String {
        if timeIn <= 0 { return "" }
        let time = timeIn.rounded(.down)
        let second = 1000.0
        if detail == -1 {
            var days = 0.0, hours = 0.0, minutes = 0.0, seconds = 0.0
            if time >= second * 60 * 60 * 24 { days = (time / (second * 60 * 60 * 24)).rounded(.down) }
            if time >= second * 60 * 60 { hours = (time / (second * 60 * 60)).rounded(.down) }
            if time >= second * 60 { minutes = (time / (second * 60)).rounded(.down) }
            if time >= second { seconds = (time / second).rounded(.down) }
            hours -= days * 24
            minutes -= hours * 60 + days * 24 * 60
            seconds -= minutes * 60 + hours * 60 * 60 + days * 24 * 60 * 60
            if days > 10 { hours = 0 }
            if days != 0 { minutes = 0; seconds = 0 }
            if hours != 0 { seconds = 0 }
            var bits: [String] = []
            if mini {
                if days > 0 { bits.append(B(days) + "d") }
                if hours > 0 { bits.append(B(hours) + "h") }
                if minutes > 0 { bits.append(B(minutes) + "m") }
                if seconds > 0 { bits.append(B(seconds) + "s") }
                return bits.isEmpty ? "<1s" : bits.joined()
            }
            if days > 0 { bits.append(B(days) + " day" + (days == 1 ? "" : "s")) }
            if hours > 0 { bits.append(B(hours) + " hour" + (hours == 1 ? "" : "s")) }
            if minutes > 0 { bits.append(B(minutes) + " minute" + (minutes == 1 ? "" : "s")) }
            if seconds > 0 { bits.append(B(seconds) + " second" + (seconds == 1 ? "" : "s")) }
            return bits.isEmpty ? "less than 1 second" : bits.joined(separator: ", ")
        }
        let d = second * 60 * 60 * 24, h = second * 60 * 60, m = second * 60
        if mini {
            if time >= d * 2 && detail < 2 { return B((time / d).rounded(.down)) + "d" }
            if time >= d && detail < 2 { return "1d" }
            if time >= h * 2 && detail < 3 { return B((time / h).rounded(.down)) + "h" }
            if time >= h && detail < 3 { return "1h" }
            if time >= m * 2 && detail < 4 { return B((time / m).rounded(.down)) + "m" }
            if time >= m && detail < 4 { return "1m" }
            if time >= second * 2 && detail < 5 { return B((time / second).rounded(.down)) + "s" }
            if time >= second && detail < 5 { return "1s" }
            return "<1s"
        }
        if time >= d * 2 && detail < 2 { return B((time / d).rounded(.down)) + " days" }
        if time >= d && detail < 2 { return "1 day" }
        if time >= h * 2 && detail < 3 { return B((time / h).rounded(.down)) + " hours" }
        if time >= h && detail < 3 { return "1 hour" }
        if time >= m * 2 && detail < 4 { return B((time / m).rounded(.down)) + " minutes" }
        if time >= m && detail < 4 { return "1 minute" }
        if time >= second * 2 && detail < 5 { return B((time / second).rounded(.down)) + " seconds" }
        if time >= second && detail < 5 { return "1 second" }
        return "less than 1 second"
    }
}

func B(_ v: Double, _ floats: Int = 0, _ format: Int = 0) -> String { Fmt.B(v, floats, format) }
func B(_ v: Int, _ floats: Int = 0) -> String { Fmt.B(Double(v), floats) }
func BT(_ v: Double) -> String { Fmt.BT(v) }
func sayTime(_ ms: Double, _ detail: Int = 0, _ mini: Bool = false) -> String { Fmt.sayTime(ms, detail, mini) }

// MARK: - JavaScript number behaviour

/// Math.round: rounds .5 up (towards +infinity), unlike Swift's default.
func jsRound(_ v: Double) -> Double { (v + 0.5).rounded(.down) }

/// Number.prototype.toString(): shortest round-trip representation, JS style exponent.
func jsString(_ v: Double) -> String {
    if v.isNaN { return "NaN" }
    if v.isInfinite { return v > 0 ? "Infinity" : "-Infinity" }
    if v == 0 { return "0" }
    let a = abs(v)
    if a >= 1e21 || a < 1e-6 {
        // JS: 1.234e+21 / 1e-7
        var s = "\(v)"            // Swift: 1.234e+21
        if !s.contains("e") { s = String(format: "%g", v) }
        if let r = s.range(of: "e") {
            var mant = String(s[s.startIndex..<r.lowerBound])
            var exp = String(s[r.upperBound...])
            if mant.hasSuffix(".0") { mant.removeLast(2) }
            if !exp.hasPrefix("-") && !exp.hasPrefix("+") { exp = "+" + exp }
            return mant + "e" + exp
        }
        return s
    }
    if v == v.rounded(.down) && a < 1e21 {
        return String(format: "%.0f", v)
    }
    var s = "\(v)"
    if s.contains("e") {
        // small numbers Swift prints in exponent form that JS prints in full (1e-5 .. 1e-6 handled above)
        s = String(format: "%.15f", v)
        while s.hasSuffix("0") { s.removeLast() }
    }
    return s
}

/// Number.prototype.toFixed
func jsToFixed(_ v: Double, _ digits: Int) -> String {
    if abs(v) >= 1e21 { return jsString(v) }
    return String(format: "%.\(max(0, digits))f", v)
}

/// Number.prototype.toPrecision
func jsToPrecision(_ v: Double, _ p: Int) -> String {
    let e = v == 0 ? 0 : Int(log10(abs(v)).rounded(.down))
    if e < -6 || e >= p {
        var s = String(format: "%.\(p - 1)e", v)  // 1.23e+21
        // Swift/printf pads exponent to 2 digits; JS doesn't
        if let r = s.range(of: "e") {
            let mant = String(s[s.startIndex..<r.lowerBound])
            var exp = String(s[r.upperBound...])
            let sign = exp.first == "-" ? "-" : "+"
            exp = String(exp.drop(while: { $0 == "+" || $0 == "-" || $0 == "0" }))
            if exp.isEmpty { exp = "0" }
            s = mant + "e" + sign + exp
        }
        return s
    }
    return String(format: "%.\(max(0, p - 1 - e))f", v)
}

/// parseInt-like for ids stored as strings
func jsInt(_ s: String) -> Int? { Int(s) }

/// x|0 in JS: ToInt32 (wraps around, NaN and infinities become 0)
func jsInt32(_ v: Double) -> Double {
    if !v.isFinite { return 0 }
    let t = v.rounded(.towardZero)
    let m = t.truncatingRemainder(dividingBy: 4294967296)
    var u = m < 0 ? m + 4294967296 : m
    if u >= 2147483648 { u -= 4294967296 }
    return u
}
