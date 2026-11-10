import UIKit

/// Opens a popup for test screenshots (CC_SHOT=popup-…)
enum DebugShots {
    static func open(_ what: String) {
        switch what {
        case "building": if let b = G.buildings.first(where: { $0.amount > 0 }) { G.setScreen("store"); BuildingUI.showInfo(b) }
        case "upgrade": if let u = G.upgrades.first(where: { $0.owned != 0 && $0.pool != "prestige" && $0.pool != "toggle" }) { UpgradeUI.showInfo(u) }
        case "achiev": if let a = G.achievs.first(where: { $0.owned != 0 }) { AchievUI.showInfo(a) }
        case "lump": LumpUI.popup()
        case "ascend": G.showAscend(2)
        case "grimoire", "garden", "market", "pantheon":
            for (n, l) in [("Farm", 5), ("Bank", 3), ("Temple", 3), ("Wizard tower", 3)] { if let b = G.buildingsBN[n], b.level < l { b.level = l } }
            Minigames.loadAll()
            Minigames.openWindow(["grimoire": "Wizard tower", "garden": "Farm", "market": "Bank", "pantheon": "Temple"][what]!)
        case "toast": G.toast("Test toast", "Something happened", [10, 0])
        default: break
        }
    }
}

/// a log file the test machine copies out next to the screenshots
enum DebugLog {
    static let enabled = ProcessInfo.processInfo.environment["CC_SHOT"] != nil
    static func log(_ s: String) {
        guard enabled else { return }
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("debug.txt")
        let line = "[\(ProcessInfo.processInfo.environment["CC_SHOT"] ?? "")] \(s)\n"
        if let h = try? FileHandle(forWritingTo: url) { h.seekToEndOfFile(); h.write(Data(line.utf8)); try? h.close() }
        else { try? Data(line.utf8).write(to: url) }
    }
}
