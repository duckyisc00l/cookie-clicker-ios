import SwiftUI
import UIKit

/// The app's iPhone extras (iCloud backup, QR save transfer, Live Activity, keep awake, 120 Hz),
/// connected to the Swift game.
enum Extras {
    static let host = SwiftGameHost()
    static var highRefresh: Bool { AppSettings.shared.highRefresh }
    private static var lastBackup = Date()
    private static var lastStats = Date.distantPast

    static func setup(_ g: Game) {
        g.onSave = { _ in
            if Date().timeIntervalSince(lastBackup) >= 600 { lastBackup = Date(); host.backUpNow(nil) }
        }
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in pushStats() }
    }

    static func applySettings() {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = AppSettings.shared.keepAwake
            GameLoop.shared.start()
            if AppSettings.shared.liveActivity { pushStats() } else { LiveActivityManager.shared.endAll() }
        }
    }

    static func backgroundSave() {
        lastBackup = Date()
        host.backUpNow(nil)
        pushStats()
    }

    static func pushStats() {
        guard AppSettings.shared.liveActivity else { return }
        let g = Game.shared
        LiveActivityManager.shared.gameStats(cookies: B(g.cookies), short: shortNumber(g.cookies), perSecond: B(g.cookiesPs, 1))
    }

    static func shortNumber(_ n: Double) -> String {
        let suffix = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
        guard n.isFinite else { return "\(n)" }
        if n < 1000 { return String(Int(n)) }
        let tier = Int(log10(n) / 3)
        if tier >= suffix.count { return String(format: "%.1e", n).replacingOccurrences(of: "+", with: "") }
        let v = n / pow(1000, Double(tier))
        return (v >= 100 ? String(Int(v)) : Fmt.jsNumber((v * 10).rounded(.down) / 10)) + suffix[tier]
    }

    // MARK: compact saves (the same packing as the original app, so QR codes work both ways)

    /// upgrade/achievement lists are packed into bits: lossless, and much smaller
    static func packSave(_ save: [String: Any]) -> [String: Any] {
        var out: [String: Any] = [:]
        for (k, v) in save {
            guard let dict = v as? [String: Any], dict.count > 16,
                  dict.allSatisfy({ key, x in Int(key) != nil && key.allSatisfy(\.isNumber) && ((x as? NSNumber).map { n in n.doubleValue == Double(n.intValue) && n.intValue >= 0 && n.intValue <= 3 } ?? false) })
            else { out[k] = v; continue }
            let ids = dict.keys.compactMap { Int($0) }.sorted()
            let n = (ids.last ?? 0) + 1
            let base = (n + 7) / 8
            var bytes = [UInt8](repeating: 0, count: base + (ids.count + 3) / 4)
            for (i, id) in ids.enumerated() {
                bytes[id >> 3] |= UInt8(1 << (id & 7))
                let val = (dict[String(id)] as? NSNumber)?.intValue ?? 0
                bytes[base + (i >> 2)] |= UInt8(val << ((i & 3) * 2))
            }
            out[k] = ["#p": Data(bytes).base64EncodedString(), "n": n, "c": ids.count]
        }
        return out
    }
    static func unpackSave(_ save: [String: Any]) -> [String: Any] {
        var out: [String: Any] = [:]
        for (k, v) in save {
            guard let d = v as? [String: Any], let p = d["#p"] as? String, let bytes = Data(base64Encoded: p).map(Array.init),
                  let n = (d["n"] as? NSNumber)?.intValue else { out[k] = v; continue }
            let base = (n + 7) / 8
            var obj: [String: Any] = [:]
            var i = 0
            for id in 0..<n where id >> 3 < bytes.count {
                if (bytes[id >> 3] >> (id & 7)) & 1 == 1 {
                    let idx = base + (i >> 2)
                    obj[String(id)] = idx < bytes.count ? Int((bytes[idx] >> ((i & 3) * 2)) & 3) : 0
                    i += 1
                }
            }
            out[k] = obj
        }
        return out
    }
    static func readSave(_ textIn: String) -> [String: Any]? {
        var text = textIn.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.hasPrefix("{"), let d = Data(base64Encoded: text), let s = String(data: d, encoding: .utf8) { text = s }
        guard let data = text.data(using: .utf8), let o = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return unpackSave(o)
    }
}

final class SwiftGameHost: GameHost {
    func currentSave(_ completion: @escaping (String?, String?, String?) -> Void) {
        let g = Game.shared
        let o = g.saveObject()
        let json = (try? JSONSerialization.data(withJSONObject: o)).flatMap { String(data: $0, encoding: .utf8) }
        let compact = (try? JSONSerialization.data(withJSONObject: Extras.packSave(o))).flatMap { String(data: $0, encoding: .utf8) }
        completion(json, compact, B(g.cookies))
    }

    func backUpNow(_ completion: ((Bool) -> Void)?) {
        currentSave { json, _, _ in
            guard let json = json else { completion?(false); return }
            BackupManager.shared.backUp(exportText: Data(json.utf8).base64EncodedString(), completion: completion)
        }
    }

    func receiveSave(_ text: String) {
        guard let d = Extras.readSave(text), d["cookies"] != nil, d["buildings"] != nil, d["upgrades"] != nil, d["achievs"] != nil else {
            alert("Can't load this save", "That isn't a Cookie Clicker save.", nil); return
        }
        let cookies = B((d["cookies"] as? NSNumber)?.doubleValue ?? 0)
        let played = sayTime(now() - ((d["time"] as? NSNumber)?.doubleValue ?? now()))
        alert("Load this save?", "\(cookies) cookies, last played \(played.isEmpty ? "just now" : played + " ago").\n\nThis replaces the game on this phone.") {
            let g = Game.shared
            UIState.shared.popup = nil
            UIState.shared.minigame = nil
            g.reset(hard: true)
            g.load(from: d)
            g.save()
        }
    }

    func applySettings() { Extras.applySettings() }

    private func alert(_ title: String, _ msg: String, _ ok: (() -> Void)?) {
        DispatchQueue.main.async {
            guard var top = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first?.rootViewController else { return }
            while let p = top.presentedViewController { top = p }
            let a = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            if let ok = ok {
                a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                a.addAction(UIAlertAction(title: "Load", style: .destructive) { _ in ok() })
            } else {
                a.addAction(UIAlertAction(title: "OK", style: .default))
            }
            top.present(a, animated: true)
        }
    }
}
