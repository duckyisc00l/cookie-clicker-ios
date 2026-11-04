import Foundation

struct DragonLevel { let name: String, action: String, pic: Int, drop: Bool }
struct DragonAura { let id: Int, name: String, pic: [Int], desc: String, drop: Bool }

enum Dragon {
    static let levels: [DragonLevel] = {
        var l: [DragonLevel] = [
            DragonLevel(name: "Dragon egg", action: "Chip it", pic: 0, drop: false),
            DragonLevel(name: "Dragon egg", action: "Chip it", pic: 1, drop: false),
            DragonLevel(name: "Dragon egg", action: "Chip it", pic: 2, drop: false),
            DragonLevel(name: "Shivering dragon egg", action: "Hatch it", pic: 3, drop: false),
            DragonLevel(name: "Krumblor, cookie hatchling", action: "Train Breath of Milk<br><small>Aura: kittens are 5% more effective</small>", pic: 4, drop: false),
        ]
        let rest: [(String, String, Int, Bool)] = [
            ("Krumblor, cookie hatchling", "Train Dragon Cursor<br><small>Aura: enhanced power clicks; clicking is 5% more effective</small>", 4, false),
            ("Krumblor, cookie hatchling", "Train Elder Battalion<br><small>Aura: grandmas gain +1% CpS for every non-grandma building</small>", 4, false),
            ("Krumblor, cookie hatchling", "Train Reaper of Fields<br><small>Aura: golden cookies may trigger a Dragon Harvest</small>", 4, false),
            ("Krumblor, cookie dragon", "Train Earth Shatterer<br><small>Aura: buildings sell back for 50% instead of 25%</small>", 5, false),
            ("Krumblor, cookie dragon", "Train Master of the Armory<br><small>Aura: all upgrades are 2% cheaper</small>", 5, false),
            ("Krumblor, cookie dragon", "Train Fierce Hoarder<br><small>Aura: all buildings are 2% cheaper</small>", 5, false),
            ("Krumblor, cookie dragon", "Train Dragon God<br><small>Aura: prestige CpS bonus +5%</small>", 5, false),
            ("Krumblor, cookie dragon", "Train Arcane Aura<br><small>Aura: golden cookies appear 5% more often</small>", 5, false),
            ("Krumblor, cookie dragon", "Train Dragonflight<br><small>Aura: golden cookies may trigger a Dragonflight</small>", 5, false),
            ("Krumblor, cookie dragon", "Train Ancestral Metamorphosis<br><small>Aura: golden cookies give 10% more cookies</small>", 5, false),
            ("Krumblor, cookie dragon", "Train Unholy Dominion<br><small>Aura: wrath cookies give 10% more cookies</small>", 5, false),
            ("Krumblor, cookie dragon", "Train Epoch Manipulator<br><small>Aura: golden cookie effects last 5% longer</small>", 5, false),
            ("Krumblor, cookie dragon", "Train Mind Over Matter<br><small>Aura: +25% random drops</small>", 5, false),
            ("Krumblor, cookie dragon", "Train Radiant Appetite<br><small>Aura: all cookie production multiplied by 2</small>", 5, false),
            ("Krumblor, cookie dragon", "Train Dragon's Fortune<br><small>Aura: +123% CpS per golden cookie on-screen</small>", 5, false),
            ("Krumblor, cookie dragon", "Train Dragon's Curve<br><small>Unlocks 2 dragon upgrades</small>", 5, true),
            ("Krumblor, cookie dragon", "Train Reality Bending<br><small>Aura: 10% of every other aura, combined</small>", 5, false),
            ("Krumblor, cookie dragon", "Train Dragon Orbs<br><small>Aura: selling your best building may grant a wish</small>", 5, false),
            ("Krumblor, cookie dragon", "Train Supreme Intellect<br><small>Unlocks 2 dragon upgrades</small>", 5, true),
            ("Krumblor, cookie dragon", "Train Dragon Guts<br><small>Aura: enhanced wrinklers</small>", 5, false),
            ("Krumblor, cookie dragon", "Bake dragon cookie<br><small>Delicious!</small>", 6, false),
            ("Krumblor, cookie dragon", "Train secondary aura<br><small>Lets you use two dragon auras simultaneously</small>", 7, false),
            ("Krumblor, cookie dragon", "Your dragon is fully trained.", 8, false),
        ]
        for r in rest { l.append(DragonLevel(name: r.0, action: r.1, pic: r.2, drop: r.3)) }
        return l
    }()

    static let auras: [DragonAura] = [
        DragonAura(id: 0, name: "No aura", pic: [0, 7], desc: "", drop: false),
        DragonAura(id: 1, name: "Breath of Milk", pic: [18, 25], desc: "Kittens are <b>5%</b> more effective.", drop: false),
        DragonAura(id: 2, name: "Dragon Cursor", pic: [0, 25], desc: "Clicking is <b>5%</b> more powerful.<br><b>+5</b> max power clicks.<br>Power click effects <b>+5%</b>.", drop: false),
        DragonAura(id: 3, name: "Elder Battalion", pic: [1, 25], desc: "Grandmas gain <b>+1% CpS</b> for each non-grandma building.", drop: false),
        DragonAura(id: 4, name: "Reaper of Fields", pic: [2, 25], desc: "Golden cookies may trigger a <b>Dragon Harvest</b>.", drop: false),
        DragonAura(id: 5, name: "Earth Shatterer", pic: [3, 25], desc: "Buildings sell back for <b>50%</b> instead of 25%.", drop: false),
        DragonAura(id: 6, name: "Master of the Armory", pic: [4, 25], desc: "All upgrades are <b>2% cheaper</b>.", drop: false),
        DragonAura(id: 7, name: "Fierce Hoarder", pic: [15, 25], desc: "All buildings are <b>2% cheaper</b>.", drop: false),
        DragonAura(id: 8, name: "Dragon God", pic: [16, 25], desc: "<b>+5%</b> prestige level effect on CpS.", drop: false),
        DragonAura(id: 9, name: "Arcane Aura", pic: [17, 25], desc: "Golden cookies appear <b>5%</b> more often.", drop: false),
        DragonAura(id: 10, name: "Dragonflight", pic: [5, 25], desc: "Golden cookies may trigger a <b>Dragonflight</b>.", drop: false),
        DragonAura(id: 11, name: "Ancestral Metamorphosis", pic: [6, 25], desc: "Golden cookies give <b>10%</b> more cookies.", drop: false),
        DragonAura(id: 12, name: "Unholy Dominion", pic: [7, 25], desc: "Wrath cookies give <b>10%</b> more cookies.", drop: false),
        DragonAura(id: 13, name: "Epoch Manipulator", pic: [8, 25], desc: "Golden cookies stay <b>5%</b> longer.", drop: false),
        DragonAura(id: 14, name: "Mind Over Matter", pic: [13, 25], desc: "Random drops are <b>25% more common</b>.", drop: false),
        DragonAura(id: 15, name: "Radiant Appetite", pic: [14, 25], desc: "All cookie production <b>multiplied by 2</b>.", drop: false),
        DragonAura(id: 16, name: "Dragon's Fortune", pic: [19, 25], desc: "<b>+123% CpS</b> per golden cookie on-screen, multiplicative.", drop: false),
        DragonAura(id: 17, name: "Dragon's Curve", pic: [20, 25], desc: "<b>+5%</b> sugar lump growth. Sugar lumps are <b>twice as likely</b> to be unusual.", drop: true),
        DragonAura(id: 18, name: "Reality Bending", pic: [32, 25], desc: "<b>One tenth</b> of every other dragon aura, <b>combined</b>.", drop: false),
        DragonAura(id: 19, name: "Dragon Orbs", pic: [33, 25], desc: "With no buffs and no golden cookies on screen, selling your most powerful building has <b>10% chance to summon one</b>.", drop: false),
        DragonAura(id: 20, name: "Supreme Intellect", pic: [34, 25], desc: "Confers various powers to your minigames while active.<br>See the bottom of each minigame for more details.", drop: true),
        DragonAura(id: 21, name: "Dragon Guts", pic: [35, 25], desc: "You can attract <b>2 more wrinklers</b>.<br>Wrinklers digest <b>20% more cookies</b>.<br>Wrinklers explode into <b>20% more cookies</b>.", drop: false),
    ]
    static func aura(_ name: String) -> DragonAura? { auras.first { $0.name == name } }

    /// cost text and whether the player can pay for the next level
    static func cost(_ g: Game, _ lvl: Int) -> (String, Bool) {
        if lvl < 5 { let c = 1_000_000 * pow(2, Double(lvl)); return (B(c) + " cookies", g.cookies >= c) }
        if lvl < levels.count - 3 {
            let b = g.buildings[lvl - 5]
            return ("100 " + b.def.plural, b.amount >= 100)
        }
        if lvl == levels.count - 3 { return ("50 of every building", g.buildings.allSatisfy { $0.amount >= 50 }) }
        if lvl == levels.count - 2 { return ("200 of every building", g.buildings.allSatisfy { $0.amount >= 200 }) }
        return ("", false)
    }

    @discardableResult
    static func upgrade(_ g: Game) -> Bool {
        let lvl = g.dragonLevel
        if lvl >= levels.count - 1 { return false }
        guard cost(g, lvl).1 else { return false }
        if lvl < 5 { g.spend(1_000_000 * pow(2, Double(lvl))) }
        else if lvl < levels.count - 3 { g.forceSell(g.buildings[lvl - 5], 100) }
        else if lvl == levels.count - 3 { for b in g.buildings { g.forceSell(b, 50) }; g.unlock("Dragon cookie") }
        else { for b in g.buildings { g.forceSell(b, 200) } }
        Sound.play("snd/shimmerClick.mp3")
        g.dragonLevel = (g.dragonLevel + 1) % levels.count
        if g.dragonLevel == levels.count - 1 { g.win("Here be dragon") }
        if levels[lvl].drop {
            let all = ["Dragon scale", "Dragon claw", "Dragon fang", "Dragon teddy bear"]
            for _ in 0..<2 {
                let drops = all.filter { !g.HasUnlocked($0) }
                if drops.isEmpty { break }
                let d = choose(drops)
                g.unlock(d)
                g.toast("<b>\(d)</b>!", "The dragon gives you:", g.upgradesBN[d]?.def.icon)
            }
        }
        g.refreshCps = true
        g.doUnlocks()
        return true
    }

    /// auras you can pick for a slot (0 or 1)
    static func choices(_ g: Game, slot: Int) -> [DragonAura] {
        let other = slot == 0 ? g.dragonAura2 : g.dragonAura
        return auras.filter { !$0.drop && g.dragonLevel >= $0.id + 4 && !($0.id != 0 && $0.id == other) }
    }
    static func select(_ g: Game, slot: Int, aura: Int) {
        let current = slot == 0 ? g.dragonAura : g.dragonAura2
        if current == aura { return }
        if slot == 0 { g.dragonAura = aura } else { g.dragonAura2 = aura }
        if let highest = g.buildings.last(where: { $0.amount > 0 }) { g.forceSell(highest, 1) }
        g.refreshCps = true
        Sound.play("snd/thud.mp3", 0.5); Sound.play("snd/tick.mp3", 0.5)
    }
}

enum Santa {
    static let levels = ["Festive test tube", "Festive ornament", "Festive wreath", "Festive tree", "Festive present", "Festive elf fetus", "Elf toddler", "Elfling", "Young elf", "Bulky elf", "Nick", "Santa Claus", "Elder Santa", "True Santa", "Final Claus"]
    static func cost(_ g: Game) -> Double { pow(Double(g.santaLevel + 1), Double(g.santaLevel + 1)) * (1 + 0.01 * g.prestige) }
    @discardableResult
    static func upgrade(_ g: Game) -> Bool {
        if g.santaLevel >= 14 { return false }
        let c = cost(g)
        if g.cookies < c { return false }
        Sound.play("snd/shimmerClick.mp3")
        g.spend(c)
        g.santaLevel = (g.santaLevel + 1) % 15
        if g.santaLevel == 14 {
            g.unlock("Santa's dominion")
            g.toast("You are granted Santa's dominion.", "", g.upgradesBN["Santa's dominion"]?.def.icon)
        }
        Seasons.dropSanta(g)
        if g.santaLevel >= 6 { g.win("Coming to town") }
        if g.santaLevel >= 14 { g.win("All hail Santa") }
        g.refreshCps = true
        g.doUnlocks()
        return true
    }
}

extension Game {
    func hasAura(_ what: String) -> Bool {
        Dragon.auras[safe: dragonAura]?.name == what || Dragon.auras[safe: dragonAura2]?.name == what
    }
    func auraMult(_ what: String) -> Double {
        var n = hasAura(what) ? 1.0 : 0
        if hasAura("Reality Bending"), let a = Dragon.aura(what), dragonLevel >= a.id + 4 { n += 0.1 }
        return n
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { i >= 0 && i < count ? self[i] : nil }
}
