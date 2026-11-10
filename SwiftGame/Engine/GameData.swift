import Foundation

/// The game's content (buildings, upgrades, achievements...), loaded from GameData.json,
/// which is exported straight from the original game so names, prices and numbers match.

enum Eff {
    case num(pool: String, v: Double, mult: Bool)
    case tier(pool: String, building: Int, tierUnshackle: Int?)   // "twice as efficient", more when unshackled
    case syn(pool: String, other: Int, rate: Double)              // synergy: +rate per other building
    case gma(pool: String, building: Int)                         // grandma type: +1% per (building id - 1) grandmas
    case special(pool: String, name: String)                      // hand-written in Effects.swift
    var pool: String {
        switch self {
        case .num(let p, _, _), .tier(let p, _, _), .syn(let p, _, _), .gma(let p, _), .special(let p, _): return p
        }
    }
}

enum SpecialCond {
    case stat(String, Double)
    case season(String)
    case made(Int, Double)
    case named(String)
}

struct Cond {
    var cookies = 0.0, cps = 0.0, milk = 0.0
    var buildings: [(Int, Int)] = []
    var upgrades: [Int] = []
    var achievs: [Int] = []
    var spe: SpecialCond? = nil
}

final class BuildingDef {
    let id: Int, name: String, single: String, plural: String, actionName: String
    let extraName: String, extraPlural: String, desc: String
    let foolName: String, foolPlural: String, foolDesc: String
    let pic: Int, icon: [Int], baseCost: Double, baseCps: Double, unshackle: Int?
    init(_ d: [String: Any]) {
        id = d["id"] as? Int ?? 0
        name = d["name"] as? String ?? ""
        single = d["single"] as? String ?? ""
        plural = d["plural"] as? String ?? ""
        actionName = d["actionName"] as? String ?? ""
        extraName = d["extraName"] as? String ?? ""
        extraPlural = d["extraPlural"] as? String ?? ""
        desc = d["desc"] as? String ?? ""
        foolName = d["foolName"] as? String ?? name
        foolPlural = d["foolPlural"] as? String ?? plural
        foolDesc = d["foolDesc"] as? String ?? desc
        pic = d["pic"] as? Int ?? id
        icon = d["icon"] as? [Int] ?? [0, 0]
        baseCost = (d["baseCost"] as? NSNumber)?.doubleValue ?? 0
        baseCps = (d["baseCps"] as? NSNumber)?.doubleValue ?? 0
        unshackle = d["unshackle"] as? Int
    }
}

final class UpgradeDef {
    let id: Int, name: String, desc: String, q: String, icon: [Int], pool: String, order: Double
    let cost: Double, power: Double, tier: String?, unimplemented: Bool
    let effs: [Eff], costKind: String?, unlock: Cond?
    init(_ d: [String: Any]) {
        id = d["id"] as? Int ?? 0
        name = d["name"] as? String ?? ""
        desc = d["desc"] as? String ?? ""
        q = d["q"] as? String ?? ""
        icon = d["icon"] as? [Int] ?? [0, 0]
        pool = d["pool"] as? String ?? ""
        order = (d["order"] as? NSNumber)?.doubleValue ?? 0
        cost = (d["cost"] as? NSNumber)?.doubleValue ?? 0
        power = (d["power"] as? NSNumber)?.doubleValue ?? 0
        tier = d["tier"] as? String
        unimplemented = d["unimplemented"] as? Bool ?? false
        effs = (d["effs"] as? [[String: Any]] ?? []).map(GameData.parseEff)
        costKind = d["costK"] as? String
        unlock = GameData.parseCond(d["unlock"])
    }
}

final class AchievDef {
    let id: Int, name: String, desc: String, q: String, icon: [Int], pool: String, order: Double
    let tier: Int?, unimplemented: Bool, unlock: Cond?
    init(_ d: [String: Any]) {
        id = d["id"] as? Int ?? 0
        name = d["name"] as? String ?? ""
        desc = d["desc"] as? String ?? ""
        q = d["q"] as? String ?? ""
        icon = d["icon"] as? [Int] ?? [0, 0]
        pool = d["pool"] as? String ?? ""
        order = (d["order"] as? NSNumber)?.doubleValue ?? 0
        tier = d["tier"] as? Int
        unimplemented = d["unimplemented"] as? Bool ?? false
        unlock = GameData.parseCond(d["unlock"])
    }
}

struct TierDef {
    let key: String, name: String, price: Double, achievUnlock: Int, unshackle: Int?, color: String
}

struct BuffTypeDef {
    let name: String, nameD: String, icon: [Int], t: Double, pow: Double, type: Int, stackT: Int, stackPow: Int, desc: String?
}

final class GameData {
    let buildings: [BuildingDef]
    let upgrades: [UpgradeDef]
    let achievs: [AchievDef]
    let tiers: [String: TierDef]
    let buffTypes: [BuffTypeDef]
    let pools: [String: [Int]]
    let heavenlyParents: [Int: [Int]]
    let extra: [String: Any]

    static func load() -> GameData {
        func json(_ name: String) -> [String: Any] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [:] }
            return obj
        }
        return GameData(json("GameData"), json("GameExtra"))
    }

    init(_ d: [String: Any], _ extra: [String: Any]) {
        buildings = (d["buildings"] as? [[String: Any]] ?? []).map(BuildingDef.init)
        upgrades = (d["upgrades"] as? [[String: Any]] ?? []).map(UpgradeDef.init)
        achievs = (d["achievs"] as? [[String: Any]] ?? []).map(AchievDef.init)
        var t: [String: TierDef] = [:]
        for (k, v) in d["tiers"] as? [String: [String: Any]] ?? [:] {
            t[k] = TierDef(key: k, name: v["name"] as? String ?? k,
                           price: (v["price"] as? NSNumber)?.doubleValue ?? 0,
                           achievUnlock: v["achievUnlock"] as? Int ?? 0,
                           unshackle: v["upgrade"] as? Int, color: v["color"] as? String ?? "#fff")
        }
        tiers = t
        buffTypes = (d["buffTypes"] as? [[String: Any]] ?? []).map { b in
            BuffTypeDef(name: b["name"] as? String ?? "", nameD: b["nameD"] as? String ?? "",
                        icon: b["icon"] as? [Int] ?? [0, 0], t: (b["t"] as? NSNumber)?.doubleValue ?? 10,
                        pow: (b["pow"] as? NSNumber)?.doubleValue ?? 1, type: b["type"] as? Int ?? 0,
                        stackT: b["stackT"] as? Int ?? 1, stackPow: b["stackPow"] as? Int ?? 2, desc: b["desc"] as? String)
        }
        pools = (d["pools"] as? [String: [Int]]) ?? [:]
        var hp: [Int: [Int]] = [:]
        for (k, v) in d["heavenlyParents"] as? [String: [Int]] ?? [:] { if let i = Int(k) { hp[i] = v } }
        heavenlyParents = hp
        self.extra = extra
    }

    static func parseEff(_ e: [String: Any]) -> Eff {
        let p = e["p"] as? String ?? ""
        switch e["k"] as? String {
        case "tier": return .tier(pool: p, building: e["b"] as? Int ?? 0, tierUnshackle: e["tu"] as? Int)
        case "syn": return .syn(pool: p, other: e["o"] as? Int ?? 0, rate: (e["r"] as? NSNumber)?.doubleValue ?? 0)
        case "gma": return .gma(pool: p, building: e["b"] as? Int ?? 2)
        case "sp": return .special(pool: p, name: e["n"] as? String ?? "")
        default: return .num(pool: p, v: (e["v"] as? NSNumber)?.doubleValue ?? 0, mult: (e["m"] as? Int ?? 0) != 0)
        }
    }

    static func parseCond(_ any: Any?) -> Cond? {
        guard let c = any as? [String: Any] else { return nil }
        var o = Cond()
        o.cookies = (c["cookies"] as? NSNumber)?.doubleValue ?? 0
        o.cps = (c["cps"] as? NSNumber)?.doubleValue ?? 0
        o.milk = (c["milk"] as? NSNumber)?.doubleValue ?? 0
        o.buildings = (c["b"] as? [[Int]] ?? []).map { ($0[0], $0.count > 1 ? $0[1] : 0) }
        o.upgrades = c["u"] as? [Int] ?? []
        o.achievs = c["a"] as? [Int] ?? []
        if let s = c["s"] as? [String: Any] {
            let k = s["k"] as? String ?? ""
            let n = (s["n"] as? NSNumber)?.doubleValue ?? 0
            switch k {
            case "stat": o.spe = .stat(s["v"] as? String ?? "", n)
            case "season": o.spe = .season(s["v"] as? String ?? "")
            case "made": o.spe = .made(s["b"] as? Int ?? 0, n)
            default: o.spe = .named(s["n"] as? String ?? "")
            }
        }
        return o
    }

    func extraStrings(_ key: String) -> [String] { extra[key] as? [String] ?? [] }
}
