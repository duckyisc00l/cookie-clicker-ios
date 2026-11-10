import Foundation
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
final class Grimoire: Minigame {
    let parent: Building; let name = "Grimoire"
    init(_ b: Building) { parent = b }
    func reset(_ hard: Bool) {}
    func save() -> String { parent.minigameSave }
    func load(_ str: String) {}
    func logic() {}
}
