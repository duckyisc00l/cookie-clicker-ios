import Foundation

/// The save files (FS in www/lib/main.js). They're the same JSON text files the previous version of the app
/// kept in Application Support/Saves, so your current save carries over.
enum SaveStore {
    static let savePath = "CookieClickerSave.txt"
    static let savePathPrev = "CookieClickerSavePrev.txt"

    enum Result { case loaded([String: Any]), none, error }

    static var dir: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let d = base.appendingPathComponent("Saves", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }
    static func url(_ name: String) -> URL { dir.appendingPathComponent(name) }

    static func load(_ name: String) -> Result {
        guard let data = try? Data(contentsOf: url(name)), !data.isEmpty else { return .none }
        guard let o = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // FS.read: an unreadable file reads as false, which G.Load treats as "no save"
            return .none
        }
        return .loaded(o)
    }

    /// FS.clone(savePath, savePathPrev) then FS.write(savePath, o)
    static func write(_ o: [String: Any]) {
        let fm = FileManager.default
        let cur = url(savePath), prev = url(savePathPrev)
        if let d = try? Data(contentsOf: cur) { try? d.write(to: prev, options: .atomic) }
        if let d = try? JSONSerialization.data(withJSONObject: o) { try? d.write(to: cur, options: .atomic) }
        _ = fm
        SaveStore.didSave?(o)
    }
    /// the app hooks this for iCloud backups
    static var didSave: (([String: Any]) -> Void)? = nil

    /// Export: btoa(btoa(JSON)) like the original's "Export save file"
    static func exportString() -> String {
        let o = G.Save(toObj: true)
        let json = String(data: (try? JSONSerialization.data(withJSONObject: o)) ?? Data(), encoding: .utf8) ?? "{}"
        return Data(Data(json.utf8).base64EncodedString().utf8).base64EncodedString()
    }
    /// Import: accepts plain JSON, base64 JSON, or double base64 (like the original)
    static func importString(_ sIn: String) -> [String: Any]? {
        var s = sIn.trimmingCharacters(in: .whitespacesAndNewlines)
        for _ in 0..<3 {
            if s.first == "{" { break }
            guard let d = Data(base64Encoded: s), let t = String(data: d, encoding: .utf8) else { return nil }
            s = t.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let data = s.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}
