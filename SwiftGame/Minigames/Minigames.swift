import Foundation

/// A building's minigame (Garden, Pantheon, Grimoire, Stock Market).
protocol Minigame: AnyObject {
    var building: Building { get }
    var name: String { get }
    func reset(hard: Bool)
    func save() -> String
    func load(_ s: String)
    func logic(_ g: Game)
    func onLevel(_ level: Int)
}

extension Minigame {
    func onLevel(_ level: Int) {}
}

/// Connects the minigames to the rest of the game.
final class Minigames {
    static let shared = Minigames()
    var garden: Garden?
    var pantheon: Pantheon?
    var grimoire: Grimoire?
    var market: Market?
    var all: [Minigame] { let list: [Minigame?] = [garden, market, pantheon, grimoire]; return list.compactMap { $0 } }

    /// which building has which minigame
    static let buildingFor = ["Farm": "Garden", "Bank": "Stock Market", "Temple": "Pantheon", "Wizard tower": "Grimoire"]

    func setup(_ g: Game) {
        if garden == nil, let b = g.buildingsBN["Farm"] { garden = Garden(b) }
        if market == nil, let b = g.buildingsBN["Bank"] { market = Market(b) }
        if pantheon == nil, let b = g.buildingsBN["Temple"] { pantheon = Pantheon(b) }
        if grimoire == nil, let b = g.buildingsBN["Wizard tower"] { grimoire = Grimoire(b) }
    }
    func minigame(for b: Building) -> Minigame? { all.first { $0.building === b } }
    func isReady(_ m: Minigame) -> Bool { m.building.level > 0 }

    // MARK: hooks used by the game
    func logic(_ g: Game, _ delta: Double) {
        setup(g)
        for m in all where isReady(m) { m.logic(g) }
    }
    func saveAll(_ g: Game) {
        setup(g)
        for m in all where isReady(m) { m.building.minigameSave = m.save() }
    }
    func loadAll(_ g: Game) {
        setup(g)
        for m in all { m.reset(hard: true); if !m.building.minigameSave.isEmpty { m.load(m.building.minigameSave) } }
    }
    func reset(_ g: Game, hard: Bool) {
        setup(g)
        for m in all { m.reset(hard: hard) }
    }
    func onLevel(_ b: Building) { minigame(for: b)?.onLevel(b.level) }
    func onBuy(_ b: Building) { if b.def.name == "Farm" { garden?.computeStepT() } }
    func onSell(_ b: Building, _ sold: Int) {
        guard let p = pantheon, isReady(p) else { return }
        p.onSell(Game.shared, sold)
    }
    func onGoldenClick(_ g: Game) { if let p = pantheon, isReady(p) { p.onGoldenClick(g) } }
    func heavenlyMult() -> Double { if let p = pantheon, isReady(p) { return p.heavenlyMult() }; return 1 }
    func onBuffDie(_ name: String) {
        if name.hasPrefix("loan ") && !name.hasSuffix("interest"), let id = Int(name.dropFirst(5)) { market?.takeLoan(id, interest: true) }
    }

    func hasGod(_ name: String) -> Int {
        guard let p = pantheon, isReady(p) else { return 0 }
        return p.hasGod(name)
    }

    /// minigame effects on the game's numbers (garden plants, gods), applied while computing CpS
    func applyEffects(_ g: Game) {
        if let gd = garden, isReady(gd) { gd.applyEffects(g) }
        if let p = pantheon, isReady(p) { p.applyEffects(g) }
    }
    func goldenEffectDurMod(_ g: Game) -> Double {
        var m = 1.0
        let lvl = hasGod("decadence")
        if lvl == 1 { m *= 1.07 } else if lvl == 2 { m *= 1.05 } else if lvl == 3 { m *= 1.02 }
        return m
    }
    func goldenGainMod(_ g: Game, wrath: Bool) -> Double {
        guard let gd = garden, isReady(gd) else { return 1 }
        return gd.eff(wrath ? "wrathCookieGain" : "goldenCookieGain")
    }
    func buffEffs(_ b: Buff) -> [(String, Double, Int)] { MinigameBuffs.effs(b) }
    func buffDesc(_ b: Buff) -> String { MinigameBuffs.desc(b) }
}
