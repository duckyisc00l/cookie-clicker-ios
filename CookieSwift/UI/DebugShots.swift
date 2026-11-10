import UIKit

/// Opens a popup for test screenshots (CC_SHOT=popup-…)
enum DebugShots {
    static func open(_ what: String) {
        switch what {
        case "building": if let b = G.buildings.first(where: { $0.amount > 0 }) { G.setScreen("store"); BuildingUI.showInfo(b) }
        case "upgrade": if let u = G.upgrades.first(where: { $0.owned != 0 && $0.pool != "prestige" && $0.pool != "toggle" }) { UpgradeUI.showInfo(u) }
        case "achiev": if let a = G.achievs.first(where: { $0.owned != 0 }) { AchievUI.showInfo(a) }
        case "lump": LumpUI.popup()
        case "toast": G.toast("Test toast", "Something happened", [10, 0])
        default: break
        }
    }
}
