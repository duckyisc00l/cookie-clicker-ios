import UIKit
import SwiftUI

/// The app around the game: the "iPhone extras" screen, backups, the Live Activity, notifications,
/// keeping the screen awake. (In the previous version this lived in the web view's controller.)
final class ExtrasHost: GameHost {
    static let shared = ExtrasHost()
    private var backupTimer: Timer?
    private var statsTimer: Timer?
    private weak var extrasController: UIViewController?

    func start() {
        applySettings()
        let center = NotificationCenter.default
        center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.applySettings()
            GameNotifications.shared.clear()
        }
        center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.leaving()
        }
        // regular backups while playing
        backupTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in self?.autoBackup() }
        // numbers for the Live Activity
        statsTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            LiveActivityManager.shared.gameStats(cookies: B(G.cookies), short: ExtrasHost.shortNumber(G.cookies), perSecond: B(G.cookiesPs, 1))
        }
    }

    static func open() { shared.openExtras() }

    private func openExtras() {
        guard extrasController == nil, let vc = SaveFiles.presenter else { return }
        let view = ExtrasView(host: self, close: { [weak vc] in vc?.dismiss(animated: true) })
        let controller = UIHostingController(rootView: view)
        extrasController = controller
        vc.present(controller, animated: true)
    }

    /// Leaving the app: save, back up, send the latest numbers to the Live Activity, and set the sugar lump reminder.
    private func leaving() {
        G.Save()
        LiveActivityManager.shared.gameStats(cookies: B(G.cookies), short: ExtrasHost.shortNumber(G.cookies), perSecond: B(G.cookiesPs, 1))
        LiveActivityManager.shared.push()
        if Lumps.canLumps() && G.lumpT > 0 {
            GameNotifications.shared.scheduleLump(ripeAt: G.lumpT + Lumps.ripeAge, now: nowMs(), autoHarvest: AppSettings.shared.autoHarvest)
        }
        let task = UIApplication.shared.beginBackgroundTask(withName: "backup", expirationHandler: nil)
        autoBackup { _ in UIApplication.shared.endBackgroundTask(task) }
    }

    private func autoBackup(_ completion: ((Bool) -> Void)? = nil) {
        guard AppSettings.shared.autoBackup, BackupManager.shared.hasFolder else { completion?(false); return }
        backUpNow(completion)
    }

    // MARK: GameHost
    func applySettings() {
        let s = AppSettings.shared
        UIApplication.shared.isIdleTimerDisabled = s.keepAwake
        GameLoop.highRefresh = s.highRefresh
        if !s.liveActivity { LiveActivityManager.shared.endAll() }
        if !DebugLog.enabled { GameNotifications.shared.askPermissionIfNeeded() }
    }

    func currentSave(_ completion: @escaping (String?, String?, String?) -> Void) {
        let save = G.Save(toObj: true)
        let json = ExtrasHost.json(save)
        let compact = ExtrasHost.json(ExtrasHost.packSave(save))
        completion(json, compact, B(G.cookies))
    }

    func backUpNow(_ completion: ((Bool) -> Void)?) {
        currentSave { json, _, _ in
            guard let json = json else { completion?(false); return }
            // same format as "Export save file..."
            BackupManager.shared.backUp(exportText: Data(json.utf8).base64EncodedString(), completion: completion)
        }
    }

    func receiveSave(_ text: String) {
        let ask = {
            guard let vc = SaveFiles.presenter else { return }
            guard let d = ExtrasHost.readSave(text) else {
                ExtrasHost.message(vc, "Can't load this save", "Couldn't read that save.")
                return
            }
            if d["cookies"] == nil || d["buildings"] == nil || d["upgrades"] == nil || d["achievs"] == nil {
                ExtrasHost.message(vc, "Can't load this save", "That isn't a Cookie Clicker save."); return
            }
            if ((d["lastVersion"] as? Double) ?? 0) > Game.version {
                ExtrasHost.message(vc, "Can't load this save", "That save is from a newer version of the game."); return
            }
            let cookies = B((d["cookies"] as? Double) ?? 0)
            let played = sayTime(nowMs() - ((d["time"] as? Double) ?? nowMs()))
            let alert = UIAlertController(title: "Load this save?", message: "\(cookies) cookies, last played \(played) ago.\n\nThis replaces the game on this phone.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Load", style: .destructive) { _ in
                Popup.close()
                G.Reset(true)
                _ = G.LoadFromObject(d)
            })
            vc.present(alert, animated: true)
        }
        if let c = extrasController { c.dismiss(animated: true, completion: ask) } else { ask() }
    }

    private static func message(_ vc: UIViewController, _ title: String, _ msg: String) {
        let a = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(a, animated: true)
    }

    // MARK: save packing (for QR codes): owned/unlocked flags of upgrades and achievements packed into bits
    static func json(_ o: Any) -> String {
        String(data: (try? JSONSerialization.data(withJSONObject: o)) ?? Data(), encoding: .utf8) ?? "{}"
    }
    static func packSave(_ save: [String: Any]) -> [String: Any] {
        var out: [String: Any] = [:]
        for (k, v) in save {
            guard let obj = v as? [String: Any], obj.count > 16,
                  obj.allSatisfy({ key, x in
                      guard Int(key) != nil, key.allSatisfy(\.isNumber), let n = x as? NSNumber, CFGetTypeID(n) != CFBooleanGetTypeID() else { return false }
                      let d = n.doubleValue
                      return d == d.rounded() && d >= 0 && d <= 3
                  }) else { out[k] = v; continue }
            let ids = obj.keys.compactMap { Int($0) }.sorted()
            let n = ids.last! + 1
            let base = (n + 7) / 8
            var bytes = [UInt8](repeating: 0, count: base + (ids.count + 3) / 4)
            for (i, id) in ids.enumerated() {
                bytes[id >> 3] |= UInt8(1 << (id & 7))
                let val = (obj[String(id)] as! NSNumber).intValue
                bytes[base + (i >> 2)] |= UInt8(val << ((i & 3) * 2))
            }
            out[k] = ["#p": Data(bytes).base64EncodedString(), "n": n, "c": ids.count]
        }
        return out
    }
    static func unpackSave(_ save: [String: Any]) -> [String: Any] {
        var out: [String: Any] = [:]
        for (k, v) in save {
            guard let o = v as? [String: Any], let p = o["#p"] as? String, let n = (o["n"] as? NSNumber)?.intValue,
                  let data = Data(base64Encoded: p) else { out[k] = v; continue }
            let bytes = [UInt8](data)
            let base = (n + 7) / 8
            var obj: [String: Any] = [:]
            var i = 0
            for id in 0..<n {
                if (id >> 3) < bytes.count, (bytes[id >> 3] >> (id & 7)) & 1 == 1 {
                    let b = base + (i >> 2)
                    obj[String(id)] = b < bytes.count ? Int((bytes[b] >> ((i & 3) * 2)) & 3) : 0
                    i += 1
                }
            }
            out[k] = obj
        }
        return out
    }
    static func readSave(_ text: String) -> [String: Any]? {
        guard let o = SaveStore.importString(text) else { return nil }
        return unpackSave(o)
    }

    static func shortNumber(_ n: Double) -> String {
        let suffix = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
        if !n.isFinite { return jsString(n) }
        if n < 1000 { return String(Int(n.rounded(.down))) }
        let tier = Int((log10(n) / 3).rounded(.down))
        if tier >= suffix.count { return String(format: "%.1e", n).replacingOccurrences(of: "+", with: "") }
        let v = n / pow(1000, Double(tier))
        let s = v >= 100 ? String(Int(v.rounded(.down))) : String(format: v >= 10 ? "%.1f" : "%.2f", (v * (v >= 10 ? 10 : 100)).rounded(.down) / (v >= 10 ? 10 : 100))
        return s.replacingOccurrences(of: #"\.?0+$"#, with: "", options: .regularExpression) + suffix[tier]
    }
}

/// what the loop needs to know about the screen's refresh rate
enum GameLoop {
    static var highRefresh = true
}

extension SaveStore {
    /// the alpha version keeps its own save slot (www/main.js savePathTest)
    static var isTest: Bool { UserDefaults.standard.string(forKey: "isTest") == "1" }
    static func switchSlot(test: Bool) {
        G.Save()
        UserDefaults.standard.set(test ? "1" : "0", forKey: "isTest")
        G.reloadFromSave()
    }
}
