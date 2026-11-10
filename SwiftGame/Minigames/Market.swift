import Foundation

final class Good {
    let id: Int, name: String, symbol: String, company: String
    let building: Building
    var val = 1.0, d = 0.0, mode = 0, dur = 0, stock = 0
    var hidden = true, active = false, last = 0, prev = 0.0
    var vals: [Double] = [1]
    init(id: Int, name: String, symbol: String, company: String, building: Building) {
        self.id = id; self.name = name; self.symbol = symbol; self.company = company; self.building = building
    }
}

/// Stock Market (Bank minigame): buy and sell goods as their prices move. Rules from the desktop game.
final class Market: Minigame {
    let building: Building
    let name = "Stock Market"
    var goods: [Good] = []
    var officeLevel = 0, brokers = 0, profit = 0.0, ticks = 0
    var tickT = 0.0, secondsPerTick = 60.0
    var graphLines = 1, graphCols = 0

    static let goodDefs: [(String, String, String, String)] = [
        ("Farm", "Cereals", "CRL", "Old Mills"), ("Mine", "Chocolate", "CHC", "Cocoa Excavations"), ("Factory", "Butter", "BTR", "Bovine Industries"),
        ("Bank", "Sugar", "SUG", "Candy Trust"), ("Temple", "Nuts", "NUT", "Hazel Monastery"), ("Wizard tower", "Salt", "SLT", "Wacky Reagants"),
        ("Shipment", "Vanilla", "VNL", "Cosmic Exports"), ("Alchemy lab", "Eggs", "EGG", "Organic Gnostics"), ("Portal", "Cinnamon", "CNM", "Dimensional Exchange"),
        ("Time machine", "Cream", "CRM", "Precision Aging"), ("Antimatter condenser", "Jam", "JAM", "Pectin Research"), ("Prism", "White chocolate", "WCH", "Dazzle Corp Ltd."),
        ("Chancemaker", "Honey", "HNY", "Prosperity Hive"), ("Fractal engine", "Cookies", "CKI", "Selfmade Bakeries"), ("Javascript console", "Recipes", "RCP", "Figments Associated"),
        ("Idleverse", "Subsidiaries", "SBD", "Polyvalent Acquisitions"), ("Cortex baker", "Publicists", "PBL", "Great Minds"), ("You", "Bakers", "YOU", "Your Bakery"),
    ]

    struct Office { let name: String, icon: [Int], cost: (Int, Int)?, desc: String }
    static let offices: [Office] = [
        Office(name: "Credit garage", icon: [0, 33], cost: (100, 2), desc: "This is your starting office.<br>Upgrading will grant you:<br><b>&bull; +1 loan slot<br>&bull; +25 warehouse space for all goods</b>"),
        Office(name: "Tiny bank", icon: [9, 33], cost: (200, 4), desc: "This is your office.<br>Upgrading will grant you:<br><b>&bull; +1 loan slot<br>&bull; +50 warehouse space for all goods</b>"),
        Office(name: "Loaning company", icon: [10, 33], cost: (350, 8), desc: "This is your office.<br>Upgrading will grant you:<br><b>&bull; +75 warehouse space for all goods</b>"),
        Office(name: "Finance headquarters", icon: [11, 33], cost: (500, 10), desc: "This is your office.<br>Upgrading will grant you:<br><b>&bull; +1 loan slot<br>&bull; +100 warehouse space for all goods</b>"),
        Office(name: "International exchange", icon: [12, 33], cost: (700, 12), desc: "This is your office.<br>Upgrading will grant you:<br><b>&bull; +1 loan slot<br>&bull; +50% base warehouse space for all goods</b>"),
        Office(name: "Palace of Greed", icon: [18, 33], cost: nil, desc: "This is your office.<br>It is fully upgraded. Its lavish interiors, spanning across innumerable floors, are host to many a decadent party, owing to your unrivaled success in the stock market."),
    ]

    /// name, CpS mult, duration (min), interest mult, interest duration (min), downpayment (share of bank), quote
    static let loanTypes: [(String, Double, Double, Double, Double, Double, String)] = [
        ("a modest loan", 1.5, 60 * 2, 0.25, 60 * 4, 0.2, "Buy that vintage car you've always wanted. Just pay us back."),
        ("a pawnshop loan", 2, 0.67, 0.1, 40, 0.4, "Bad credit? No problem. It's your money, and you need it now."),
        ("a retirement loan", 1.2, 60 * 24 * 2, 0.8, 60 * 24 * 5, 0.5, "Finance your next house, boat, spouse, etc. You've earned it."),
    ]

    init(_ b: Building) {
        building = b
        let g = Game.shared
        for (i, d) in Market.goodDefs.enumerated() {
            if let bl = g.buildingsBN[d.0] { goods.append(Good(id: i, name: d.1, symbol: d.2, company: d.3, building: bl)) }
        }
        reset(hard: true)
    }

    func restingVal(_ id: Int) -> Double { 10 + 10 * Double(id) + Double(building.level - 1) }
    func maxStock(_ good: Good) -> Int {
        var bonus = 0
        if officeLevel > 0 { bonus += 25 }
        if officeLevel > 1 { bonus += 50 }
        if officeLevel > 2 { bonus += 75 }
        if officeLevel > 3 { bonus += 100 }
        return Int((Double(good.building.amountMax) * (officeLevel > 4 ? 1.5 : 1) + Double(bonus) + Double(good.building.level * 10)).rounded(.up))
    }
    func overhead() -> Double { 1 + 0.01 * (20 * pow(0.95, Double(brokers))) }
    func delta(_ good: Good, back: Int = 0) -> Double {
        var v = 0.0
        if good.vals.count >= 2 + back { v = good.vals[back] / good.vals[1 + back] - 1 }
        return (v * 10000).rounded(.down) / 100
    }
    func maxBrokers() -> Int {
        let gr = Game.shared.buildings[1]
        return Int((Double(gr.amountMax) / 10 + Double(gr.level)).rounded(.up))
    }
    func brokerPrice() -> Double { Game.shared.cookiesPsRawHighest * 60 * 20 }
    func loanSlots() -> Int { officeLevel >= 4 ? 3 : officeLevel >= 2 ? 2 : officeLevel >= 1 ? 1 : 0 }

    @discardableResult
    func buy(_ id: Int, _ nIn: Int) -> Bool {
        let g = Game.shared
        let me = goods[id]
        let costInS = me.val
        let cost = g.cookiesPsRawHighest * costInS * overhead()
        var n = nIn
        if n == 10000 { n = cost > 0 ? Int((g.cookies / cost).rounded(.down)) : 0 }
        n = min(n, maxStock(me) - me.stock)
        guard n > 0, me.last != 2, g.cookies >= cost * Double(n), me.stock + n <= maxStock(me) else { return false }
        if costInS * overhead() * Double(n) >= 86400 { g.win("Buy buy buy") }
        profit -= costInS * overhead() * Double(n)
        g.spend(cost * Double(n))
        me.stock += n
        var mn = 10000
        for it in goods { mn = min(mn, it.stock); if it.stock >= 1000 { g.win("Full warehouses") } }
        if mn >= 100 { g.win("Rookie numbers") }
        if mn >= 500 { g.win("No nobility in poverty") }
        me.last = 1
        me.prev = costInS
        Sound.play("snd/cashOut.mp3", 0.4)
        return true
    }

    @discardableResult
    func sell(_ id: Int, _ nIn: Int) -> Bool {
        let g = Game.shared
        let me = goods[id]
        var n = nIn
        if n == 10000 { n = me.stock }
        n = min(n, me.stock)
        guard n > 0, me.last != 1, me.stock > 0 else { return false }
        let costInS = me.val
        if costInS * Double(n) >= 86400 { g.win("Make my day") }
        profit += costInS * Double(n)
        if profit > 0 { g.win("Initial public offering") }
        if profit >= 10_000_000 { g.win("Liquid assets") }
        if profit >= 31_536_000 { g.win("Gaseous assets") }
        g.cookies += g.cookiesPsRawHighest * costInS * Double(n)
        g.cookiesEarned = max(g.cookies, g.cookiesEarned)
        me.stock -= n
        me.last = 2
        Sound.play("snd/cashIn.mp3", 0.4)
        return true
    }

    func upgradeOffice() {
        let g = Game.shared
        guard let c = Market.offices[officeLevel].cost, g.buildings[0].amount >= c.0, g.buildings[0].level >= c.1 else { Sound.play("snd/clickOff2.mp3", 0.5); return }
        g.forceSell(g.buildings[0], c.0)
        officeLevel += 1
        if officeLevel >= Market.offices.count - 1 { g.win("Pyramid scheme") }
        Sound.play("snd/cashIn2.mp3", 0.6)
    }
    func hireBroker() {
        let g = Game.shared
        guard brokers < maxBrokers(), g.cookies >= brokerPrice() else { Sound.play("snd/clickOff2.mp3", 0.5); return }
        g.spend(brokerPrice())
        brokers += 1
        Sound.play("snd/cashIn2.mp3", 0.6)
    }

    @discardableResult
    func takeLoan(_ id: Int, interest: Bool = false) -> Bool {
        let g = Game.shared
        let loan = Market.loanTypes[id - 1]
        if !interest {
            if g.hasBuff("loan \(id)") != nil || g.hasBuff("loan \(id) interest") != nil { return false }
            g.spend(g.cookies * loan.5)
            g.addBuff("loan \(id)", t: loan.2 * 60, pow: loan.1)
            Sound.play("snd/cashIn2.mp3", 0.6)
        } else {
            g.addBuff("loan \(id) interest", t: loan.4 * 60, pow: loan.3)
            g.toast("Loan over", "Your loan has expired, and you must now repay the interest.", [1, 33])
        }
        return true
    }

    func tick() {
        let boost = Game.shared.auraMult("Supreme Intellect")
        var globD = 0.0
        let globP = rnd()
        if rnd() < 0.1 + 0.1 * boost { globD = (rnd() - 0.5) * 2 }
        let bankLevel = Double(building.level)
        for me in goods {
            me.last = 0
            me.d *= 0.97 + 0.01 * boost
            switch me.mode {
            case 0: me.d *= 0.95; me.d += 0.05 * (rnd() - 0.5)
            case 1: me.d *= 0.99; me.d += 0.05 * (rnd() - 0.1)
            case 2: me.d *= 0.99; me.d -= 0.05 * (rnd() - 0.1)
            case 3: me.d += 0.15 * (rnd() - 0.1); me.val += rnd() * 5
            case 4: me.d -= 0.15 * (rnd() - 0.1); me.val -= rnd() * 5
            case 5: me.d += 0.3 * (rnd() - 0.5)
            default: break
            }
            me.val += (restingVal(me.id) - me.val) * 0.01
            if globD != 0 && rnd() < globP {
                me.val -= (1 + me.d * pow(rnd(), 3) * 7) * globD
                me.val -= globD * (1 + pow(rnd(), 3) * 7)
                me.d += globD * (1 + rnd() * 4)
                me.dur = 0
            }
            me.val += pow((rnd() - 0.5) * 2, 11) * 3
            me.d += 0.1 * (rnd() - 0.5)
            if rnd() < 0.15 { me.val += (rnd() - 0.5) * 3 }
            if rnd() < 0.03 { me.val += (rnd() - 0.5) * (10 + 10 * boost) }
            if rnd() < 0.1 { me.d += (rnd() - 0.5) * (0.3 + 0.2 * boost) }
            if me.mode == 5 {
                if rnd() < 0.5 { me.val += (rnd() - 0.5) * 10 }
                if rnd() < 0.2 { me.d = (rnd() - 0.5) * (2 + 6 * boost) }
            }
            if me.mode == 3 && rnd() < 0.3 { me.d += (rnd() - 0.5) * 0.1; me.val += (rnd() - 0.7) * 10 }
            if me.mode == 3 && rnd() < 0.03 { me.mode = 4 }
            if me.mode == 4 && rnd() < 0.3 { me.d += (rnd() - 0.5) * 0.1; me.val += (rnd() - 0.3) * 10 }
            if me.val > (100 + (bankLevel - 1) * 3) && me.d > 0 { me.d *= 0.9 }
            me.val += me.d
            if me.val < 5 { me.val += (5 - me.val) * 0.5 }
            if me.val < 5 && me.d < 0 { me.d *= 0.95 }
            me.val = max(me.val, 1)
            me.vals.insert(me.val, at: 0)
            if me.vals.count > 65 { me.vals.removeLast() }
            me.dur -= 1
            if me.dur <= 0 {
                me.dur = Int(10 + rnd() * (690 - 200 * boost))
                if rnd() < boost && rnd() < 0.5 { me.mode = 5 }
                else if rnd() < 0.7 && (me.mode == 3 || me.mode == 4) { me.mode = 5 }
                else { me.mode = choose([0, 1, 1, 2, 2, 3, 4, 5]) }
            }
        }
        ticks += 1
    }

    func logic(_ g: Game) {
        tickT += 1
        if tickT >= Game.fps * secondsPerTick { tickT = 0; tick() }
        if g.T % 10 == 0 {
            for me in goods where !me.active && me.building.amountMax > 0 { me.active = true; me.hidden = false }
        }
    }

    func refill(_ g: Game) {
        LumpRefill.refill(g, 1) {
            self.tickT = Game.fps * self.secondsPerTick
            Sound.play("snd/pop\(Int.random(in: 1...3)).mp3", 0.75)
        }
    }

    func reset(hard: Bool) {
        tickT = 0; officeLevel = 0; brokers = 0; profit = 0; ticks = 0
        if hard { graphLines = 1; graphCols = 0 }
        for it in goods {
            it.stock = 0
            it.mode = choose([0, 1, 1, 2, 2, 3, 4, 5])
            it.dur = Int(10 + rnd() * 690)
            it.val = restingVal(it.id)
            it.d = rnd() * 0.2 - 0.1
            it.vals = [it.val, it.val - it.d]
            it.hidden = true; it.active = false; it.last = 0; it.prev = 0
        }
        for _ in 0..<15 { tick() }
    }

    func save() -> String {
        var s = "\(officeLevel):\(brokers):\(graphLines):\(Fmt.jsNumber(profit)):\(graphCols): "
        for it in goods {
            s += "\(Int(it.val * 100)):\(it.mode):\(Int(it.d * 100)):\(it.dur):\(it.stock):\(it.hidden ? 1 : 0):\(it.last):\(Int(it.prev * 100))!"
        }
        return s + " 0"
    }
    func load(_ str: String) {
        let spl = str.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        guard spl.count >= 2 else { return }
        let a = spl[0].split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        officeLevel = max(0, min(Int(a[safe: 0] ?? "") ?? officeLevel, Market.offices.count - 1))
        brokers = Int(a[safe: 1] ?? "") ?? brokers
        graphLines = Int(a[safe: 2] ?? "") ?? graphLines
        profit = Double(a[safe: 3] ?? "") ?? 0
        graphCols = Int(a[safe: 4] ?? "") ?? graphCols
        tickT = 0
        let gs = spl[1].split(separator: "!", omittingEmptySubsequences: false).map(String.init)
        for (i, it) in goods.enumerated() {
            guard let raw = gs[safe: i], !raw.isEmpty else { continue }
            let d = raw.split(separator: ":", omittingEmptySubsequences: false).map { Double($0) ?? 0 }
            it.val = (d[safe: 0] ?? 100) / 100
            it.mode = Int(d[safe: 1] ?? 0)
            it.d = (d[safe: 2] ?? 0) / 100
            it.vals = [it.val, it.val - it.d]
            it.dur = Int(d[safe: 3] ?? 0)
            it.stock = Int(d[safe: 4] ?? 0)
            it.hidden = (d[safe: 5] ?? 0) != 0
            it.active = it.building.amountMax > 0
            it.last = Int(d[safe: 6] ?? 0)
            it.prev = (d[safe: 7] ?? 0) / 100
        }
    }
}
