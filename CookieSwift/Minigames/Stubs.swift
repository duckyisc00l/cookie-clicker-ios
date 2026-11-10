import UIKit
// Temporary: replaced by the full ports of the desktop minigames.
final class Garden: Minigame {
    let parent: Building; let name = "Garden"
    var effs: [String: Double] = [:]
    init(_ b: Building) { parent = b }
    func reset(_ hard: Bool) {}
    func save() -> String { parent.minigameSave }
    func load(_ str: String) {}
    func logic() {}
}
final class Market: Minigame {
    let parent: Building; let name = "Stock Market"
    init(_ b: Building) { parent = b }
    func reset(_ hard: Bool) {}
    func save() -> String { parent.minigameSave }
    func load(_ str: String) {}
    func logic() {}
    func takeLoan(_ n: Int, interest: Bool) {}
}
final class Pantheon: Minigame {
    let parent: Building; let name = "Pantheon"
    init(_ b: Building) { parent = b }
    func reset(_ hard: Bool) {}
    func save() -> String { parent.minigameSave }
    func load(_ str: String) {}
    func logic() {}
    func hasGod(_ what: String) -> Int { 0 }
    func forceUnslotGod(_ what: String) -> Bool { false }
    func useSwap(_ n: Double) {}
}

/// placeholder screens until each minigame is ported
class PlaceholderScreen: UIView, MinigameScreen {
    func layoutContent(width: Double, minHeight: Double) -> Double { minHeight }
    func drawFrame() {}
}
final class GardenScreen: PlaceholderScreen { init(_ m: Garden) { super.init(frame: .zero) }; required init?(coder: NSCoder) { fatalError() } }
final class MarketScreen: PlaceholderScreen { init(_ m: Market) { super.init(frame: .zero) }; required init?(coder: NSCoder) { fatalError() } }
final class PantheonScreen: PlaceholderScreen { init(_ m: Pantheon) { super.init(frame: .zero) }; required init?(coder: NSCoder) { fatalError() } }
