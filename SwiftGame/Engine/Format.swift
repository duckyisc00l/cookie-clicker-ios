import Foundation

/// Number and time formatting, the same as the original game's Beautify (B) and sayTime.
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

    /// 0 = short (default), 1 = long, 2 = raw
    static var format = 0

    private static func everyThird(_ v: Double, _ notations: [String]) -> String {
        guard v.isFinite else { return "Inf." }
        var val = v
        var base = 0
        var notation = ""
        if val >= 1_000_000 {
            val /= 1000
            while (val).rounded() >= 1000 { val /= 1000; base += 1 }
            if base >= notations.count { return "Inf." }
            notation = notations[base]
        }
        return jsNumber((val * 10).rounded() / 10) + notation
    }

    /// Prints a number the way JavaScript's toString does for the values we use.
    static func jsNumber(_ v: Double) -> String {
        if v.isNaN { return "NaN" }
        if !v.isFinite { return v > 0 ? "Infinity" : "-Infinity" }
        if v == v.rounded() && abs(v) < 1e21 { return String(format: "%.0f", v) }
        var s = String(v)
        if s.hasSuffix(".0") { s.removeLast(2) }
        return s
    }

    private static func commas(_ s: String) -> String {
        // add thousands separators to the leading integer digits (like the game's regex)
        var intPart = ""
        var rest = Substring(s)
        while let c = rest.first, c.isNumber { intPart.append(c); rest = rest.dropFirst() }
        guard intPart.count > 3 else { return s }
        var out = ""
        for (i, c) in intPart.enumerated() {
            if i > 0 && (intPart.count - i) % 3 == 0 { out.append(",") }
            out.append(c)
        }
        return out + rest
    }

    static func B(_ value: Double, _ floats: Int = 0, _ fmt: Int? = nil) -> String {
        guard value.isFinite else { return value.isNaN ? "NaN" : "Inf." }
        let negative = value < 0
        var decimal = ""
        let fixed = String(format: "%.\(max(0, floats))f", value)
        let fixedVal = Double(fixed) ?? value
        if floats > 0 && abs(value) < 1000 && fixedVal.rounded(.down) != fixedVal {
            decimal = "." + (fixed.split(separator: ".").last.map(String.init) ?? "")
        }
        var val = abs(value).rounded(.down)
        if floats > 0 && fixedVal == val + 1 { val += 1 }
        let f = fmt ?? format
        var output: String
        if f == 2 {
            output = val >= 1e21 ? String(format: "%.2e", val) : commas(jsNumber(val > 1e12 ? val.rounded() : (val * 1000).rounded() / 1000))
        } else {
            output = commas(everyThird(val, f == 1 ? long : short))
        }
        var neg = negative
        if output == "0" { neg = false }
        return neg ? "-" + output : output + decimal
    }

    /// time in milliseconds; detail -1 gives "3 hours, 9 minutes"; mini gives "3h9m"
    static func sayTime(_ timeMs: Double, _ detail: Int = 0, _ mini: Bool = false) -> String {
        if timeMs <= 0 { return "" }
        let time = timeMs.rounded(.down)
        let second = 1000.0
        if detail == -1 {
            var days = 0.0, hours = 0.0, minutes = 0.0, seconds = 0.0
            if time >= second * 86400 { days = (time / (second * 86400)).rounded(.down) }
            if time >= second * 3600 { hours = (time / (second * 3600)).rounded(.down) }
            if time >= second * 60 { minutes = (time / (second * 60)).rounded(.down) }
            if time >= second { seconds = (time / second).rounded(.down) }
            hours -= days * 24
            minutes -= hours * 60 + days * 24 * 60
            seconds -= minutes * 60 + hours * 3600 + days * 86400
            if days > 10 { hours = 0 }
            if days > 0 { minutes = 0; seconds = 0 }
            if hours > 0 { seconds = 0 }
            var bits: [String] = []
            if mini {
                if days > 0 { bits.append(B(days) + "d") }
                if hours > 0 { bits.append(B(hours) + "h") }
                if minutes > 0 { bits.append(B(minutes) + "m") }
                if seconds > 0 { bits.append(B(seconds) + "s") }
                return bits.isEmpty ? "<1s" : bits.joined()
            }
            func unit(_ n: Double, _ name: String) -> String { B(n) + " " + name + (n == 1 ? "" : "s") }
            if days > 0 { bits.append(unit(days, "day")) }
            if hours > 0 { bits.append(unit(hours, "hour")) }
            if minutes > 0 { bits.append(unit(minutes, "minute")) }
            if seconds > 0 { bits.append(unit(seconds, "second")) }
            return bits.isEmpty ? "less than 1 second" : bits.joined(separator: ", ")
        }
        let d = second * 86400, h = second * 3600, m = second * 60
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

func B(_ v: Double, _ floats: Int = 0) -> String { Fmt.B(v, floats) }
func sayTime(_ ms: Double, _ detail: Int = 0, _ mini: Bool = false) -> String { Fmt.sayTime(ms, detail, mini) }
func cap(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }

extension Array {
    func randomPick() -> Element { self[Int.random(in: 0..<count)] }
}
func choose<T>(_ arr: [T]) -> T { arr[Int(Double.random(in: 0..<1) * Double(arr.count))] }
func rnd() -> Double { Double.random(in: 0..<1) }
func now() -> Double { Date().timeIntervalSince1970 * 1000 }

/// Seeded random numbers, used where the game uses Math.seedrandom (deterministic per save seed).
struct SeededRandom {
    private var state: UInt64
    init(_ seed: String) {
        var h: UInt64 = 1469598103934665603
        for b in seed.utf8 { h ^= UInt64(b); h = h &* 1099511628211 }
        state = h == 0 ? 0x9E3779B97F4A7C15 : h
    }
    mutating func next() -> Double {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17
        return Double(state >> 11) / Double(1 << 53)
    }
}
