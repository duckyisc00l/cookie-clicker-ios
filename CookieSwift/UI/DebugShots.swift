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
        case "gardenplay", "markettip", "pantheontip":
            open(["gardenplay": "garden", "markettip": "market", "pantheontip": "pantheon"][what]!)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if what == "gardenplay", let M = Minigames.garden {
                    for i in 0..<6 { M.plants[i].unlocked = true }
                    M.getUnlockedN()
                    M.plot[1][1] = [1, 40]; M.plot[1][2] = [2, 10]; M.plot[1][3] = [3, 30]; M.plot[2][1] = [4, 5]; M.plot[3][3] = [5, 60]
                    M.seedSelected = 2
                    M.computeBoostPlot(); M.computeEffs(); M.onRebuild?()
                    MinigameWindow.current?.relayoutContent()
                    MinigameWindow.current?.showTooltip { M.tileTooltip(1, 1) }
                }
                if what == "markettip", let M = Minigames.market { MinigameWindow.current?.showTooltip { M.goodTooltip(0) } }
                if what == "pantheontip", let M = Minigames.pantheon {
                    M.slotGod(M.gods[0], 0); M.slotGod(M.gods[3], 1); M.onSlotsChanged?()
                    MinigameWindow.current?.showTooltip { (M.slotTooltip(0), M.slotIcon(0)) }
                }
            }
        case "cookiepress":
            // hold a finger near the cookie's top-right edge
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                G.onX = G.w / 2 + 90; G.onY = G.h / 2 - 70
                if G.bigCookieState != 1 { G.clickBigCookie(x: G.onX, y: G.onY) }
            }
        case "toast": for i in 0..<12 { DispatchQueue.main.asyncAfter(deadline: .now() + 1 + Double(i) * 1.5) { G.toast("Welcome back!", "You were away for 46 minutes, and made 90 cookies.", [10, 0]) } }
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
