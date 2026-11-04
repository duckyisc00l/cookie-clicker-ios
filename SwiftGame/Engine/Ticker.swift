import Foundation

func jsRound(_ x: Double) -> Double { (x + 0.5).rounded(.down) }
func + (l: String, r: Double) -> String { l + Fmt.jsNumber(r) }
func + (l: Double, r: String) -> String { Fmt.jsNumber(l) + r }
func + (l: String, r: Int) -> String { l + String(r) }

struct NewsItem: Equatable {
    var text: String
    var fortune: String? = nil   // "fortuneGC", "fortuneCPS" or an upgrade name
}

/// The news ticker at the top of the screen.
final class Ticker {
    static let shared = Ticker()
    var tickerN = 0
    var current = NewsItem(text: "")
    var x = 0.0            // scroll position of the current headline (points)
    var width = 0.0        // measured width of the current headline (set by the view)
    var screenW = 390.0
    var saved: [(String, Double)] = []

    private lazy var extra: (buildings: [String: [String]], general: [String]) = {
        guard let url = Bundle.main.url(forResource: "ExtraNews", withExtension: "json"),
              let d = try? Data(contentsOf: url),
              let o = try? JSONSerialization.jsonObject(with: d) as? [String: Any] else { return ([:], []) }
        return (o["BUILDING_NEWS"] as? [String: [String]] ?? [:], o["GENERAL_NEWS"] as? [String] ?? [])
    }()

    func getTicker(_ g: Game) -> NewsItem {
        var list = generatedNews(g).map { NewsItem(text: $0) }
        if Double(g.T) > Game.fps * 10 && g.Has("Fortune cookies") && rnd() < (g.HasAchiev("O Fortuna") ? 0.04 : 0.02) {
            var fortunes: [String] = (g.tierUpgrades["Fortune"] ?? []).filter { !g.HasUnlocked($0.name) }.map { $0.name }
            if g.fortuneGC == 0 { fortunes.append("fortuneGC") }
            if g.fortuneCPS == 0 { fortunes.append("fortuneCPS") }
            if !fortunes.isEmpty {
                let effect = choose(fortunes)
                var text: String
                if effect == "fortuneGC" { text = "Today is your lucky day!" }
                else if effect == "fortuneCPS" {
                    var r = SeededRandom(g.seed + "-fortune")
                    text = "Your lucky numbers are: \(Int(r.next() * 100)) \(Int(r.next() * 100)) \(Int(r.next() * 100)) \(Int(r.next() * 100))"
                } else if let u = g.upgradesBN[effect] {
                    let n = u.name
                    let idx = n.firstIndex(of: "#").map { String(n[$0...]) } ?? n
                    text = idx + " : " + u.def.q
                } else { text = "" }
                list = [NewsItem(text: text, fortune: effect)]
            }
        }
        guard !list.isEmpty else { return NewsItem(text: "...") }
        var pick = choose(list)
        // the app's extra headlines are mixed in with the game's own news
        if pick.fortune == nil && pick.text.hasPrefix("News :") && rnd() < 0.35 {
            var more: [String] = []
            for (name, items) in extra.buildings where g.buildingsBN[name] != nil && g.buildingN(name) > 0 { more += items }
            if g.cookiesEarned >= 100000 { more += extra.general }
            if !more.isEmpty { pick = NewsItem(text: choose(more)) }
        }
        return pick
    }

    func logic(_ g: Game, _ delta: Double) {
        let speed = 2 * delta
        if current.text.isEmpty || x < -width {
            current = getTicker(g)
            width = 0
            x = screenW + 48
            if let i = saved.firstIndex(where: { $0.0 == current.text }) { saved.remove(at: i) }
            saved.insert((current.text, now()), at: 0)
            if saved.count > 50 { saved.removeLast() }
            tickerN += 1
        }
        if width > 0 { x -= speed }
    }

    func tapped(_ g: Game) {
        guard let f = current.fortune else { return }
        current.fortune = nil
        Sound.play("snd/fortune.mp3", 1)
        if f == "fortuneGC" {
            g.toast("Fortune!", "A golden cookie has appeared.", [10, 32], true)
            g.fortuneGC = 1
            g.spawnShimmer(0) { $0.noWrath = true }
        } else if f == "fortuneCPS" {
            g.toast("Fortune!", "You gain <b>one hour</b> of your CpS (capped at double your bank).", [10, 32], true)
            g.fortuneCPS = 1
            g.earn(min(g.cookiesPs * 3600, g.cookies))
        } else if let u = g.upgradesBN[f], u.unlocked == 0 {
            g.toast(u.name, "You've unlocked a new upgrade.", u.def.icon, true)
            g.unlockUpgrade(u)
        }
        current.text = ""
    }
}
