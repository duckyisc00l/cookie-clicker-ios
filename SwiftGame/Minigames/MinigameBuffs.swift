import Foundation

/// Buffs that come from the minigames (desktop rules).
enum MinigameBuffs {
    static let types: [BuffTypeDef] = [
        BuffTypeDef(name: "haggler luck", nameD: "Haggler's luck", icon: [25, 11], t: 60, pow: 2, type: 1, stackT: 2, stackPow: 2, desc: nil),
        BuffTypeDef(name: "haggler misery", nameD: "Haggler's misery", icon: [25, 11], t: 3600, pow: 2, type: 2, stackT: 2, stackPow: 2, desc: nil),
        BuffTypeDef(name: "pixie luck", nameD: "Crafty pixies", icon: [26, 11], t: 60, pow: 2, type: 1, stackT: 2, stackPow: 2, desc: nil),
        BuffTypeDef(name: "pixie misery", nameD: "Nasty goblins", icon: [26, 11], t: 3600, pow: 2, type: 2, stackT: 2, stackPow: 2, desc: nil),
        BuffTypeDef(name: "magic adept", nameD: "Magic adept", icon: [29, 11], t: 300, pow: 10, type: 1, stackT: 2, stackPow: 2, desc: nil),
        BuffTypeDef(name: "magic inept", nameD: "Magic inept", icon: [29, 11], t: 600, pow: 5, type: 2, stackT: 2, stackPow: 2, desc: nil),
        BuffTypeDef(name: "devastation", nameD: "Devastation", icon: [23, 18], t: 10, pow: 1, type: 1, stackT: 2, stackPow: 2, desc: nil),
        BuffTypeDef(name: "sugar blessing", nameD: "Sugar blessing", icon: [29, 16], t: 86400, pow: 1, type: 1, stackT: 2, stackPow: 2, desc: nil),
        BuffTypeDef(name: "loan 1", nameD: "Loan 1", icon: [1, 33], t: 60, pow: 1.5, type: 1, stackT: 2, stackPow: 2, desc: nil),
        BuffTypeDef(name: "loan 1 interest", nameD: "Loan 1 (interest)", icon: [1, 33], t: 60, pow: 0.25, type: 2, stackT: 2, stackPow: 2, desc: nil),
        BuffTypeDef(name: "loan 2", nameD: "Loan 2", icon: [1, 33], t: 60, pow: 2, type: 1, stackT: 2, stackPow: 2, desc: nil),
        BuffTypeDef(name: "loan 2 interest", nameD: "Loan 2 (interest)", icon: [1, 33], t: 60, pow: 0.1, type: 2, stackT: 2, stackPow: 2, desc: nil),
        BuffTypeDef(name: "loan 3", nameD: "Loan 3", icon: [1, 33], t: 60, pow: 3, type: 1, stackT: 2, stackPow: 2, desc: nil),
        BuffTypeDef(name: "loan 3 interest", nameD: "Loan 3 (interest)", icon: [1, 33], t: 60, pow: 0.05, type: 2, stackT: 2, stackPow: 2, desc: nil),
    ]

    static func effs(_ b: Buff) -> [(String, Double, Int)] {
        switch b.type.name {
        case "haggler luck": return [("upgradeCostM", 1 - b.pow / 100, 1)]
        case "haggler misery": return [("upgradeCostM", 1 + b.pow / 100, 1)]
        case "pixie luck": return [("buildingCostM", 1 - b.pow / 100, 1)]
        case "pixie misery": return [("buildingCostM", 1 + b.pow / 100, 1)]
        case "devastation": return [("clickM", b.pow, 1)]
        case "sugar blessing": return [("gcFreqM", 1.1, 1)]
        case let n where n.hasPrefix("loan"): return [("cpsBuffM", b.pow, 1)]
        default: return []
        }
    }

    static func desc(_ b: Buff) -> String {
        let t = sayTime(b.tm * 1000, -1)
        switch b.type.name {
        case "haggler luck": return "All upgrades are \(B(b.pow))% cheaper for \(t)!"
        case "haggler misery": return "All upgrades are \(B(b.pow))% pricier for \(t)!"
        case "pixie luck": return "All buildings are \(B(b.pow))% cheaper for \(t)!"
        case "pixie misery": return "All buildings are \(B(b.pow))% pricier for \(t)!"
        case "magic adept": return "Spells backfire \(B(b.pow)) times less for \(t)."
        case "magic inept": return "Spells backfire \(B(b.pow)) times more for \(t)."
        case "devastation": return "Clicking power +\(Int((b.pow * 100 - 100).rounded(.down)))% for \(t)!"
        case "sugar blessing": return "You find 10% more golden cookies for the next \(t)."
        case let n where n.hasPrefix("loan"): return "Cookie production x\(B(b.pow, 2)) for \(t)!"
        default: return ""
        }
    }
}
