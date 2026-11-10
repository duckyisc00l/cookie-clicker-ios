import UIKit

// Port of mods/minigames/minigameMarket.js (the desktop game's Stock Market), with the phone layout
// from mods/minigames/mobile.css (one good per line, big buttons, the graph at the bottom).

final class Good {
    let key: String, name: String, symbol: String, company: String, desc: String
    var id = 0
    var hidden = false, active = false
    var last = 0       // 0: didn't buy or sell this tick; 1: bought this tick; 2: sold this tick
    var stock = 0.0
    var mode = 0
    var dur = 0.0
    var prev = 0.0
    var val = 1.0
    var vals: [Double] = [1]
    var d = 0.0
    let building: Building
    var icon: [Int] { [building.icon[0], 33] }
    init(_ key: String, _ name: String, _ symbol: String, _ company: String, _ desc: String) {
        self.key = key; self.name = name; self.symbol = symbol; self.company = company; self.desc = desc
        building = G.buildingsBN[key]!
    }
    var displayName: String { name.replacingOccurrences(of: "%1", with: "Your") }
    var displayCompany: String { company.replacingOccurrences(of: "%1", with: "Your") }
}

final class Market: Minigame {
    let parent: Building
    let name = "Stock Market"
    var goods: [Good] = []
    var officeLevel = 0
    var brokers = 0.0
    var profit = 0.0
    var ticks = 0
    var lastTickDrawn = 0
    let secondsPerTick = 60.0
    var tickT = 0.0
    var toRedraw = 0
    var hoverOnGood = -1
    var graphScale = 10.0
    var graphLines = 1
    var graphCols = 0
    /// the graph's canvas height (#bankGraph is 300 high inside a 200px box on the phone)
    let graphHeight = 300.0
    var graphWidth = 298.0

    struct Office { let name: String; let icon: [Int]; let cost: [Int]?; let desc: String }
    let offices: [Office] = [
        Office(name: "Credit garage", icon: [0, 33], cost: [100, 2], desc: "This is your starting office.<br>Upgrading will grant you:<br><b>&bull; +25 warehouse space for all goods</b>"),
        Office(name: "Tiny bank", icon: [9, 33], cost: [200, 4], desc: "This is your office.<br>Upgrading will grant you:<br><b>&bull; +1 loan slot<br>&bull; +50 warehouse space for all goods</b>"),
        Office(name: "Loaning company", icon: [10, 33], cost: [350, 8], desc: "This is your office.<br>Upgrading will grant you:<br>&bull; +75 warehouse space for all goods</b>"),
        Office(name: "Finance headquarters", icon: [11, 33], cost: [500, 10], desc: "This is your office.<br>Upgrading will grant you:<br><b>&bull; +1 loan slot<br>&bull; +100 warehouse space for all goods</b>"),
        Office(name: "International exchange", icon: [12, 33], cost: [700, 12], desc: "This is your office.<br>Upgrading will grant you:<br><b>&bull; +1 loan slot<br>&bull; +50% base warehouse space for all goods</b>"),
        Office(name: "Palace of Greed", icon: [18, 33], cost: nil, desc: "This is your office.<br>It is fully upgraded. Its lavish interiors, spanning across innumerable floors, are host to many a decadent party, owing to your nigh-unfathomable wealth."),
    ]
    //name, mult, duration, payback mult, duration, downpayment (as % of bank), quote
    let loanTypes: [(String, Double, Double, Double, Double, Double, String)] = [
        ("a modest loan", 1.5, 60 * 2, 0.25, 60 * 4, 0.2, "Buy that vintage car you've always wanted. Just pay us back."),
        ("a pawnshop loan", 2, 0.67, 0.1, 40, 0.4, "Bad credit? No problem. It's your money, and you need it now."),
        ("a retirement loan", 1.2, 60 * 24 * 2, 0.8, 60 * 24 * 5, 0.5, "Finance your next house, boat, spouse, etc. You've earned it."),
    ]
    struct Cols { let bg: UIColor, line1: UIColor, line2: UIColor, low: UIColor, high: UIColor, highlight: UIColor }
    let colBases = [
        Cols(bg: UIColor(css: "#fff"), line1: UIColor(css: "#eee"), line2: UIColor(css: "#ccc"), low: UIColor(css: "#ce2549"), high: UIColor(css: "#79c600"), highlight: UIColor(css: "#000")),
        Cols(bg: UIColor(css: "#1f2836"), line1: UIColor(css: "#273545"), line2: UIColor(css: "#384b61"), low: UIColor(css: "#3153a3"), high: UIColor(css: "#c4971a"), highlight: UIColor(css: "#a6abad")),
    ]
    var cols: Cols { colBases[graphCols < colBases.count && graphCols >= 0 ? graphCols : 0] }
    /// the screen redraws the parts that changed
    var onStyleChanged: (() -> Void)?

    init(_ b: Building) {
        parent = b
        let list: [(String, String, String, String, String)] = [
            ("Farm", "Cereals", "CRL", "Old Mills", "<b>Old Mills</b> is a trusted staple of the grain industry. Finding their roots in humble pioneer farms centuries ago and honing their know-how ever since, the Old Mills organic crops have reached a standard of quality that even yours struggle to equal."),
            ("Mine", "Chocolate", "CHC", "Cocoa Excavations", "<b>Cocoa Excavations</b> is an international chocolate mining venture whose extraction sites always seem, somehow, to pop up in war-torn countries. Their high-grade chocolate is renowned the world over and has even been marketed, to some success, as suitable gems for engagement rings."),
            ("Factory", "Butter", "BTR", "Bovine Industries", "<b>Bovine Industries</b> is a formerly-agricultural conglomerate that now deals in mechanized dairy mass production. Whistleblowers have drawn attention to the way the milk cows employed by this company are treated, describing it as \"not quite cruel or anything, but definitely unusual\"."),
            ("Bank", "Sugar", "SUG", "Candy Trust", "The <b>Candy Trust</b> is a corporate banking group backed by, and specialized in, the trade of high-grade sugar. The origin of said sugar is legally protected by an armada of lawyers, though some suspect they secretly scrape it off of the bank bills coming in before processing it."),
            ("Temple", "Nuts", "NUT", "Hazel Monastery", "Hidden between hills and fog somewhere, the secretive <b>Hazel Monastery</b> has, for centuries, maintained nut crops of the highest quality. The monastery nuts are carefully tended to, harvested and shelled by its monks, who are all required to take a vow of nut allergy as a lifelong test of piety."),
            ("Wizard tower", "Salt", "SLT", "Wacky Reagants", "Salt is a versatile substance, with properties both mundane and mystical. This is why the bearded crackpots at <b>Wacky Reagants</b> have perfected the art of turning magic powder into salt, which is then sold to anyone promising to put it to good use - whether it be warding off banshees and ghouls or seasoning a Sunday roast."),
            ("Shipment", "Vanilla", "VNL", "Cosmic Exports", "After the news broke of vanilla not being native to Earth, <b>Cosmic Exports</b> was the first company to discover its true origin planet - and has struck an exclusive deal with its tentacled inhabitants to ship its valuable, unadulterated beans all over the local quadrant."),
            ("Alchemy lab", "Eggs", "EGG", "Organic Gnostics", "At <b>Organic Gnostics</b>, an egg is seen as a promise. A promise of life and nourishment, of infinite potential, of calcium and protein. An egg can become many things... especially when you're properly funded and don't believe there's room in science for rules or ethics."),
            ("Portal", "Cinnamon", "CNM", "Dimensional Exchange", "The <b>Dimensional Exchange</b> employs a vast team of ragtag daredevils to dive into dangerous underworlds in search of strange native spices. Chief among those is cinnamon, a powder so delicious its true nature can only be unspeakably abominable."),
            ("Time machine", "Cream", "CRM", "Precision Aging", "Once specialized in cosmetics for the elderly, the eggheads at <b>Precision Aging</b> have repurposed their timeshift technology and developed a process allowing them to accelerate, slow down, and even reverse the various phase changes of milk. Their flagship offering, whole cream, is said to be within 0.002% of theoretical ripening optimums."),
            ("Antimatter condenser", "Jam", "JAM", "Pectin Research", "<b>Pectin Research</b> is a military-backed laboratory initially created with the aim of enhancing and miniaturizing army rations, but now open for public bulk trading. It has recently made forays in the field of highly-concentrated fruit jams, available in a variety of flavors."),
            ("Prism", "White chocolate", "WCH", "Dazzle Corp Ltd.", "What was once two college kids messing around with mirrors in their dad's garage is now a world-famous megacorporation. <b>Dazzle Corp</b>'s groundbreaking experiments in photonic annealing have led to the creation years ago of a new kind of matter, once derided as impossible by physicists and cooks alike: white chocolate."),
            ("Chancemaker", "Honey", "HNY", "Prosperity Hive", "The folks at <b>Prosperity Hive</b> deal in honey, and it's always worked for them. With a work culture so relaxed you're almost tempted to ditch the cookie business and join them, these people have little in common with the proverbial busy bee - though their rates do sting quite a bit."),
            ("Fractal engine", "Cookies", "CKI", "Selfmade Bakeries", "Interesting. It appears there's still a company out there trying to sell cookies even with your stranglehold on the market. No matter - you figure <b>Selfmade Bakeries</b>' largely inferior product will make decent fodder for the mouse traps in your factories."),
            ("Javascript console", "Recipes", "RCP", "Figments Associated", "In a post-material world, the market of ideas is where value is created. <b>Figments Associated</b> understands that, and is the prime designer (and patenter) of baking recipes, ingredient nomenclature, custom cooking procedures, and other kitchen processes."),
            ("Idleverse", "Subsidiaries", "SBD", "Polyvalent Acquisitions", "Avoid the uncouth nastiness of mass layoffs and hostile takeovers by delegating the purchase, management, and eventual dissolution of other companies to the boys at <b>Polyvalent Acquisitions</b>. Let 'em deal with it!"),
            ("Cortex baker", "Publicists", "PBL", "Great Minds", "Get those juices flowing: from market research to advertising, the think tanks at <b>Great Minds</b> will lend their talents to the highest bidder. It's intellectual property on tap."),
            ("You", "%1", "YOU", "%1's Bakery", "That's right! Your transcendental business skills are so influential, so universally resounding, that you've become a publicly traded good yourself - you're the best <b>%1's Bakery</b> has to offer. Don't disappoint your shareholders, there's a price on your head! Invest in yourself NOW!"),
        ]
        for (k, n, s, c, d) in list where G.buildingsBN[k] != nil {
            let g = Good(k, n, s, c, d)
            g.id = goods.count
            goods.append(g)
        }
    }

    // MARK: rules
    var rawHighest: Double { G.cookiesPsRawHighest > 0 ? G.cookiesPsRawHighest : G.cookiesPs }
    static func highest(_ b: Building) -> Double { Double(b.amountMax > 0 ? b.amountMax : b.amount) }
    func goodDelta(_ id: Int, _ back: Int = 0) -> Double {
        let me = goods[id]
        var val = 0.0
        if me.vals.count >= 2 + back { val = me.vals[back] / me.vals[1 + back] - 1 }
        return (val * 10000).rounded(.down) / 100
    }
    /// "1.5" → "1.50%" like the page writes it
    func deltaString(_ v: Double) -> String {
        jsString(v) + (v == v.rounded(.down) ? ".00" : (v * 10) == (v * 10).rounded(.down) ? "0" : "") + "%"
    }
    func getGoodMaxStock(_ good: Good) -> Double {
        var bonus = 0.0
        if officeLevel > 0 { bonus += 25 }
        if officeLevel > 1 { bonus += 50 }
        if officeLevel > 2 { bonus += 75 }
        if officeLevel > 3 { bonus += 100 }
        return (Market.highest(good.building) * (officeLevel > 4 ? 1.5 : 1) + bonus + Double(good.building.level) * 10).rounded(.up)
    }
    func getGoodPrice(_ good: Good) -> Double { good.val }
    var overhead: Double { 1 + 0.01 * (20 * pow(0.95, brokers)) }
    @discardableResult
    func buyGood(_ id: Int, _ nIn: Double) -> Bool {
        let me = goods[id]
        let costInS = getGoodPrice(me)
        let cost = rawHighest * costInS * overhead
        var n = nIn
        if n == 10000 { n = (G.cookies / cost).rounded(.down) }
        n = min(n, getGoodMaxStock(me) - me.stock)
        if n > 0 && me.last != 2 && G.cookies >= cost * n && me.stock + n <= getGoodMaxStock(me) {
            if costInS * overhead * n >= 86400 { G.win("Buy buy buy") }
            profit -= costInS * overhead * n
            G.spend(cost * n)
            me.stock += n
            var mn = 10000.0
            for it in goods {
                mn = min(mn, it.stock)
                if it.stock >= 1000 { G.win("Full warehouses") }
            }
            if mn >= 100 { G.win("Rookie numbers") }
            if mn >= 500 { G.win("No nobility in poverty") }
            me.last = 1
            me.prev = costInS
            PlaySound("snd/cashOut.mp3", 0.4)
            return true
        }
        return false
    }
    @discardableResult
    func sellGood(_ id: Int, _ nIn: Double) -> Bool {
        let me = goods[id]
        var n = nIn
        if n == 10000 { n = me.stock }
        n = min(n, me.stock)
        if n > 0 && me.last != 1 && me.stock > 0 {
            let costInS = getGoodPrice(me)
            if costInS * n >= 86400 { G.win("Make my day") }
            profit += costInS * n
            if profit > 0 { G.win("Initial public offering") }
            if profit >= 10000000 { G.win("Liquid assets") }
            if profit >= 31536000 { G.win("Gaseous assets") }
            G.cookies += rawHighest * costInS * n
            G.cookiesEarned = max(G.cookies, G.cookiesEarned)
            me.stock -= n
            me.last = 2
            PlaySound("snd/cashIn.mp3", 0.4)
            return true
        }
        return false
    }
    func getRestingVal(_ id: Int) -> Double { 10 + 10 * Double(id) + Double((G.buildingsBN["Bank"]?.level ?? 1) - 1) }
    func getMaxBrokers() -> Double {
        let g = G.buildingsBN["Grandma"]!
        return (Market.highest(g) / 10 + Double(g.level)).rounded(.up)
    }
    func getBrokerPrice() -> Double { rawHighest * 60 * 20 }
    var canUpgradeOffice: Bool {
        guard let c = offices[officeLevel].cost, let cur = G.buildingsBN["Cursor"] else { return false }
        return cur.amount >= c[0] && cur.level >= c[1]
    }
    func upgradeOffice() -> Bool {
        guard canUpgradeOffice, let c = offices[officeLevel].cost else { return false }
        G.buildingsBN["Cursor"]!.sacrifice(c[0])
        officeLevel += 1
        if officeLevel >= offices.count - 1 { G.win("Pyramid scheme") }
        PlaySound("snd/cashIn2.mp3", 0.6)
        return true
    }
    var canHire: Bool { brokers < getMaxBrokers() && G.cookies >= getBrokerPrice() }
    func hireBroker() -> Bool {
        guard canHire else { return false }
        G.spend(getBrokerPrice())
        brokers += 1
        PlaySound("snd/cashIn2.mp3", 0.6)
        return true
    }
    static func hasBuffNamed(_ name: String) -> Bool {
        let low = name.lowercased()
        return G.buffs.contains { $0.type.name == name || $0.type.nameD.lowercased() == low }
    }
    func loanTaken(_ id: Int) -> Bool { Market.hasBuffNamed("Loan \(id)") || Market.hasBuffNamed("Loan \(id) (interest)") }
    @discardableResult
    func takeLoan(_ id: Int, interest: Bool = false) -> Bool {
        let loan = loanTypes[id - 1]
        if !interest {
            if loanTaken(id) { return false }
            G.spend(G.cookies * loan.5)
            if G.buffTypesBN["loan \(id)"] != nil { Minigames.toastBuff(G.addBuff("loan \(id)", t: loan.2 * 60, pow: loan.1)) }
        } else {
            if G.buffTypesBN["loan \(id) interest"] != nil { Minigames.toastBuff(G.addBuff("loan \(id) interest", t: loan.4 * 60, pow: loan.3)) }
            G.toast("Loan over", "Your loan has expired, and you must now repay the interest.", [1, 33])
        }
        return true
    }

    func tick() {
        let dragonBoost = G.auraMult("Supreme Intellect")
        let R = JSMath.random
        var globD = 0.0
        let globP = R()
        if R() < 0.1 + 0.1 * dragonBoost { globD = (R() - 0.5) * 2 }
        for me in goods {
            me.last = 0
            me.d *= 0.97 + 0.01 * dragonBoost
            if me.mode == 0 { me.d *= 0.95; me.d += 0.05 * (R() - 0.5) }
            else if me.mode == 1 { me.d *= 0.99; me.d += 0.05 * (R() - 0.1) }
            else if me.mode == 2 { me.d *= 0.99; me.d -= 0.05 * (R() - 0.1) }
            else if me.mode == 3 { me.d += 0.15 * (R() - 0.1); me.val += R() * 5 }
            else if me.mode == 4 { me.d -= 0.15 * (R() - 0.1); me.val -= R() * 5 }
            else if me.mode == 5 { me.d += 0.3 * (R() - 0.5) }

            me.val += (getRestingVal(me.id) - me.val) * 0.01

            if globD != 0 && R() < globP {
                me.val -= (1 + me.d * pow(R(), 3) * 7) * globD
                me.val -= globD * (1 + pow(R(), 3) * 7)
                me.d += globD * (1 + R() * 4)
                me.dur = 0
            }
            me.val += pow((R() - 0.5) * 2, 11) * 3
            me.d += 0.1 * (R() - 0.5)
            if R() < 0.15 { me.val += (R() - 0.5) * 3 }
            if R() < 0.03 { me.val += (R() - 0.5) * (10 + 10 * dragonBoost) }
            if R() < 0.1 { me.d += (R() - 0.5) * (0.3 + 0.2 * dragonBoost) }
            if me.mode == 5 {
                if R() < 0.5 { me.val += (R() - 0.5) * 10 }
                if R() < 0.2 { me.d = (R() - 0.5) * (2 + 6 * dragonBoost) }
            }
            if me.mode == 3 && R() < 0.3 { me.d += (R() - 0.5) * 0.1; me.val += (R() - 0.7) * 10 }
            if me.mode == 3 && R() < 0.03 { me.mode = 4 }
            if me.mode == 4 && R() < 0.3 { me.d += (R() - 0.5) * 0.1; me.val += (R() - 0.3) * 10 }

            if me.val > (100 + Double((G.buildingsBN["Bank"]?.level ?? 1) - 1) * 3) && me.d > 0 { me.d *= 0.9 }

            me.val += me.d
            if me.val < 5 { me.val += (5 - me.val) * 0.5 }
            if me.val < 5 && me.d < 0 { me.d *= 0.95 }
            me.val = max(me.val, 1)

            me.vals.insert(me.val, at: 0)
            if me.vals.count > 65 { me.vals.removeLast() }

            me.dur -= 1
            if me.dur <= 0 {
                me.dur = (10 + R() * (690 - 200 * dragonBoost)).rounded(.down)
                if R() < dragonBoost && R() < 0.5 { me.mode = 5 }
                else if R() < 0.7 && (me.mode == 3 || me.mode == 4) { me.mode = 5 }
                else { me.mode = choose([0, 1, 1, 2, 2, 3, 4, 5]) }
            }
        }
        checkGraphScale()
        toRedraw = max(toRedraw, 1)
        ticks += 1
    }
    func checkGraphScale() {
        let currentSize = graphHeight
        var maxVal = 0.0
        for me in goods where !me.hidden { for v in me.vals { maxVal = max(maxVal, v) } }
        let neededSize = max(maxVal, 10) + 10
        let newScale = max(1, currentSize / neededSize)
        let dif = (currentSize / graphScale) - neededSize
        if graphScale != newScale && dif > 5 || dif < -5 {
            graphScale = newScale
            toRedraw = 2
        }
    }
    func toggleHidden(_ i: Int) {
        goods[i].hidden.toggle()
        checkGraphScale()
        toRedraw = 2
        PlaySound("snd/tick.mp3", 1)
        onStyleChanged?()
    }

    // MARK: tooltips
    private func inlineIcon(_ icon: [Int]) -> String {
        "<span class=\"tinyIcon\" style=\"background-position:\(-icon[0] * 48)px \(-icon[1] * 48)px;\"></span> "
    }
    private func header(_ name: String) -> String {
        "<div style=\"font-size:15px;font-weight:bold;color:#fff;margin:2px 0px;\">\(name)</div>"
    }
    func symbolNum(_ delta: Double) -> String {
        "<span style=\"color:\(delta >= 0 ? "#73f21e" : "#f21e3c");\">\(deltaString(delta))\(delta >= 0 ? "\u{25b2}" : "\u{25bc}")</span>"
    }
    func goodTooltip(_ id: Int) -> (String, [Int]?) {
        let me = goods[id]
        let delta = goodDelta(id)
        let val = getGoodPrice(me)
        let name = me.displayName
        let ic = inlineIcon(me.icon)
        var s = "<div style=\"font-size:15px;font-weight:bold;color:#fff;margin:2px 0px;\">\(name) <span style=\"font-size:12px;opacity:0.8;\">(from <span style=\"font-variant:small-caps;\">\(me.displayCompany)</span>)</span> <span style=\"font-weight:bold;font-size:10px;background:#333;\">&nbsp;\(me.symbol) \(symbolNum(delta).replacingOccurrences(of: "<span style=\"", with: "<span style=\"font-weight:normal;"))&nbsp;</span></div>"
        s += "<line></line><q>\(me.desc.replacingOccurrences(of: "%1", with: "Your"))</q><line></line>"
        s += "<div style=\"font-size:11px;\">&bull; \(ic)\(name): currently worth <b>$\(B(val, 2))</b> per unit.<br>"
        s += "&bull; You currently own \(ic)<b>\(B(me.stock))</b>x \(name) (worth <b>$\(B(val * me.stock, 2))</b>).<br>"
        s += "&bull; Your warehouses can store up to \(ic)<b>\(B(getGoodMaxStock(me)))</b>x \(name).<br>"
        s += "&bull; You may increase your storage space by upgrading your offices and by buying more \(inlineIcon([me.building.icon[0], 0]))\(me.building.plural). You also get 10 extra storage space per \(me.building.single) level (currently: <b>+\(me.building.level * 10)</b>).<br>"
        s += "&bull; The average worth of this stock and how high it can peak depends on the building it is tied to, along with the level of your \(inlineIcon([15, 0]))\(G.buildingsBN["Bank"]!.plural).</div> + "<div style=\"font-size:11px;opacity:0.5;margin-top:3px;\">Shift-click the hide button to toggle all other stocks.</div>"
        return (s, me.icon)
    }
    func tradeTooltip(_ id: Int, _ nIn: Double) -> (String, [Int]?) {
        let me = goods[id]
        let val = getGoodPrice(me)
        var cost = rawHighest * val
        let buyOrSell = nIn > 0
        var oh = 1.0
        let stock = me.stock
        let maxStock = getGoodMaxStock(me)
        if buyOrSell { oh *= overhead }
        cost *= oh
        var n = nIn
        if n == 10000 { n = (G.cookies / cost).rounded(.down) } else if n == -10000 { n = me.stock }
        n = abs(n)
        if buyOrSell { n = min(n, maxStock - stock) } else { n = min(n, stock) }
        var s = "<div style=\"text-align:center;font-size:11px;\">"
        s += "<div style=\"font-size:9px;opacity:0.6;\">Stock: <b\((!buyOrSell && stock == 0) ? " class=\"red\"" : "")>\(B(stock))</b>/<b\((buyOrSell && stock >= maxStock) ? " class=\"red\"" : "")>\(B(maxStock))</b></div>"
        if me.prev != 0 { s += "<line></line><div style=\"font-size:9px;opacity:0.6;font-weight:bold;\">last bought at<br>$\(B(me.prev, 2)) each</div>" }
        s += "<line></line><div>\(buyOrSell ? "Buy" : "Sell") <b>\(B(n))</b>x \(inlineIcon(me.icon))\(me.displayName)</div>"
        s += "<div>for $\(B(val, 2)) each</div>"
        if oh > 1 { s += "<div style=\"font-size:9px;opacity:0.6;\">(+<b>\(B((oh - 1) * 100, 2))%</b> overhead)</div>" }
        s += "<line></line><div style=\"font-size:9px;opacity:0.6;font-weight:bold;\">\(buyOrSell ? "you spend:" : "you earn:")</div>"
        let cls = n <= 0 ? "gray" : (G.cookies >= cost * n || !buyOrSell) ? "green" : "red"
        s += "<div><b class=\"\(cls)\"><span class=\"tinyCookie\"></span>\(B(cost * n))</b></div>"
        if n > 0 {
            s += "<div style=\"font-size:9px;opacity:0.6;font-weight:bold;\">($\(B(val * oh * n, 2)))</div>"
            s += "<div style=\"font-size:9px;opacity:0.6;font-weight:bold;\">(\(Loc.sayTime(val * oh * n * G.fps, -1)) of CpS)</div>"
        }
        if (me.last == 1 && !buyOrSell) || (me.last == 2 && buyOrSell) { s += "<line></line><div class=\"red\">You cannot buy and sell this stock in the same tick.</div>" }
        s += "</div>"
        return (s, nil)
    }
    func officeTooltip() -> (String, [Int]?) {
        let me = offices[officeLevel]
        var s = header("\(me.name) <span style=\"font-size:11px;opacity:0.6;\">[Level \(officeLevel + 1) offices]</span>")
        s += "<line></line><div style=\"font-size:11px;\">\(me.desc)</div>"
        if let c = me.cost, let cur = G.buildingsBN["Cursor"] {
            s += "<line></line><div style=\"font-size:11px;\">\(inlineIcon([11, 0]))Upgrading will cost you <b class=\"\(cur.amount >= c[0] ? "green" : "red")\">\(c[0]) \(cur.plural)</b>.<br>"
            s += "Upgrading requires <b class=\"\(cur.level >= c[1] ? "green" : "red")\">Level \(c[1]) \(cur.plural)</b>.</div>"
        }
        return (s, me.icon)
    }
    func brokersTooltip() -> (String, [Int]?) {
        let ok = G.cookies >= getBrokerPrice()
        var s = header("Stockbrokers <span style=\"font-size:11px;opacity:0.6;\">(you have \(B(brokers)))</span>")
        s += "<line></line><div style=\"font-size:11px;\">A nice broker to trade more cookies.<br>"
        s += "&bull; Buying goods normally incurs overhead costs of <b>20% extra</b>. Each broker you hire reduces that cost by <b>5%</b>.<br>"
        s += "&bull; Current overhead costs thanks to your brokers: <b>+\(B(20 * pow(0.95, brokers), 2))%</b><br>"
        s += "&bull; Buying a broker costs <b class=\"\(ok ? "green" : "red")\"><span class=\"tinyCookie\"></span>20 minutes</b> of CpS (that's $1200).<br>"
        s += "&bull; Maximum number of brokers you can own: <b class=\"\(brokers < getMaxBrokers() ? "green" : "red")\">\(B(getMaxBrokers()))</b> (the highest amount of grandmas you've owned this run, divided by 10, plus your grandma level)<br>"
        s += "<q>Brokers are Wall Street-class grandmas versed in the ways of finance. Stockbroker grandmas work hard and play hard, and will fight telephone in hand to get your clients the best possible deals - with a sizeable profit margin for you, of course.</q>"
        s += "<line></line><div style=\"text-align:center;\">Hiring a new broker will cost you <b class=\"\(ok ? "green" : "red")\"><span class=\"tinyCookie\"></span>\(Loc.cookies(getBrokerPrice()))</b>.</div></div>"
        return (s, [1, 33])
    }
    func loanTooltip(_ id: Int) -> (String, [Int]?) {
        let loan = loanTypes[id - 1]
        var s = "<div style=\"font-size:15px;font-weight:bold;color:#fff;\">Take out \(loan.0)</div>"
        s += "<line></line><div style=\"font-size:11px;\">By taking this loan, you will get <b class=\"green\">+\(jsString(((loan.1 - 1) * 100).rounded()))%</b> CpS for the next <b>\(Loc.sayTime(60 * loan.2 * G.fps))</b>.<br>"
        s += "However, you will get <b class=\"red\">\(jsString(((loan.3 - 1) * 100).rounded()))%</b> CpS for the next <b>\(Loc.sayTime(60 * loan.4 * G.fps))</b> after that."
        s += "You must also pay an immediate downpayment of <b class=\"red\"><span class=\"tinyCookie\"></span>\(B(G.cookies * loan.5))</b> (<b>\(jsString(loan.5 * 100))%</b> of your current bank).<q>\(loan.6)</q></div>"
        return (s, nil)
    }
    func lineTooltip(_ id: Int, _ iR: Int) -> (String, [Int]?) {
        let me = goods[id]
        return ("<div style=\"font-size:10px;text-align:center;\">\(inlineIcon(me.icon))<b>\(me.displayName)</b><br>valued at <b>$\(B(me.vals[iR], 2))</b><br>\(Loc.sayTime(Double(iR + 1) * secondsPerTick * G.fps)) ago</div>", nil)
    }

    // MARK: Minigame
    func save() -> String {
        var s = "\(officeLevel):\(Int(brokers)):\(graphLines):\(jsString(profit)):\(graphCols): "
        for it in goods {
            s += "\(Int(it.val * 100)):\(it.mode):\(Int(it.d * 100)):\(Int(it.dur)):\(Int(it.stock)):\(it.hidden ? 1 : 0):\(it.last):\(Int(it.prev * 100))!"
        }
        s += " 1"
        return s
    }
    private func pInt(_ s: String?) -> Int? {
        guard let s = s, !s.isEmpty else { return nil }
        let v = jsParseFloat(s)
        return v.isFinite ? Int(v) : nil
    }
    func load(_ str: String) {
        if str.isEmpty { return }
        let spl = str.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        let spl2 = spl[0].split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        func at(_ i: Int) -> String? { i < spl2.count ? spl2[i] : nil }
        officeLevel = max(0, min(pInt(at(0)) ?? officeLevel, offices.count - 1))
        brokers = Double(pInt(at(1)) ?? Int(brokers))
        graphLines = pInt(at(2)) ?? graphLines
        let pf = at(3).map { jsParseFloat($0) } ?? 0
        profit = pf.isFinite ? pf : 0
        graphCols = pInt(at(4)) ?? graphCols
        if graphCols < 0 || graphCols >= colBases.count { graphCols = 0 }
        tickT = 0
        let goodsS = spl.count > 1 ? spl[1].split(separator: "!", omittingEmptySubsequences: false).map(String.init) : []
        for it in goods {
            guard it.id < goodsS.count, !goodsS[it.id].isEmpty else { continue }
            let d = goodsS[it.id].split(separator: ":", omittingEmptySubsequences: false).map(String.init)
            func f(_ i: Int) -> Double { Double(pInt(i < d.count ? d[i] : nil) ?? 0) }
            it.val = f(0) / 100
            it.mode = Int(f(1))
            it.d = f(2) / 100
            it.vals = [it.val, it.val - it.d]
            it.dur = f(3)
            it.stock = f(4)
            it.hidden = f(5) != 0
            it.active = Market.highest(it.building) > 0
            it.last = Int(f(6))
            it.prev = f(7) / 100
        }
        checkGraphScale()
        toRedraw = 2
        onStyleChanged?()
    }
    func reset(_ hard: Bool) {
        tickT = 0
        toRedraw = 0
        officeLevel = 0
        brokers = 0
        if hard { graphLines = 1; graphCols = 0 }
        hoverOnGood = -1
        ticks = 0
        lastTickDrawn = 0
        profit = 0
        for it in goods {
            it.stock = 0
            it.mode = choose([0, 1, 1, 2, 2, 3, 4, 5])
            it.dur = (10 + JSMath.random() * 690).rounded(.down)
            it.val = getRestingVal(it.id)
            it.d = JSMath.random() * 0.2 - 0.1
            it.vals = [it.val, it.val - it.d]
            it.hidden = true
            it.active = false
            it.last = 0
            it.prev = 0
        }
        checkGraphScale()
        toRedraw = 2
        for _ in 0..<15 { tick() }
        onStyleChanged?()
    }
    func logic() {
        tickT += 1
        if tickT >= G.fps * secondsPerTick {
            tickT = 0
            tick()
        }
        if G.T % 10 == 0 {
            var changed = false
            for me in goods where !me.active && Market.highest(me.building) > 0 {
                me.active = true; me.hidden = false; toRedraw = 2; changed = true
            }
            if changed { checkGraphScale(); onStyleChanged?() }
        }
    }
}

// MARK: - the screen

/// .bankButton: a bordered text button (bankButtonBuy / bankButtonSell / bankButtonOff)
final class BankButton: TapView {
    enum Kind { case buy, sell }
    let label = RichLabel()
    var kind: Kind { didSet { setNeedsDisplay(); restyle() } }
    var off = false { didSet { if off != oldValue { setNeedsDisplay(); restyle() } } }
    private var down = false { didSet { restyle() } }
    let lineHeight: Double
    var minContent = 0.0
    var text: String { didSet { label.html = text } }
    init(_ text: String, _ kind: Kind, lineHeight: Double = 13) {
        self.text = text; self.kind = kind; self.lineHeight = lineHeight
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
        alpha = 0.95
        var st = TextStyle.base(13); st.bold = true; st.align = .center; st.nowrap = true
        label.style = st
        label.html = text
        addSubview(label)
        restyle()
        onDown = { [weak self] _, _ in self?.down = true }
        onUp = { [weak self] _ in self?.down = false }
    }
    required init?(coder: NSCoder) { fatalError() }
    private var colors: (UIColor, UIColor) {
        if off { return (UIColor(css: "#999"), UIColor(css: "#666")) }
        return kind == .buy ? (UIColor(css: "#a358ff"), UIColor(css: "#3a52bc")) : (UIColor(css: "#94cd50"), UIColor(css: "#1b7a2f"))
    }
    private func restyle() {
        var st = label.style
        st.color = down ? .white : colors.0
        label.style = st
    }
    /// border 1 + padding 9 on each side
    var width: Double { max(minContent, Double(RichText.size(RichText.render(text, style: label.style, width: nil), width: nil).width)) + 20 }
    var height: Double { lineHeight + 12 + 2 }
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = CGRect(x: px(10), y: px(7 + (lineHeight - 13) / 2), width: bounds.width - px(20), height: px(13))
    }
    override func draw(_ rect: CGRect) {
        guard let c = UIGraphicsGetCurrentContext() else { return }
        let r = bounds.insetBy(dx: px(0.5), dy: px(0.5))
        let path = UIBezierPath(roundedRect: r, cornerRadius: px(3))
        c.setLineWidth(px(1))
        colors.1.setStroke()
        path.stroke()
        // the top and left borders in the light colour (cut along the corner diagonals like CSS)
        c.saveGState()
        let h = bounds.height, w = bounds.width
        let cut = UIBezierPath()
        cut.move(to: .zero); cut.addLine(to: CGPoint(x: w, y: 0)); cut.addLine(to: CGPoint(x: w - h / 2, y: h / 2))
        cut.addLine(to: CGPoint(x: h / 2, y: h / 2)); cut.addLine(to: CGPoint(x: 0, y: h)); cut.close()
        cut.addClip()
        colors.0.setStroke()
        path.stroke()
        c.restoreGState()
    }
}

/// .bankSymbol: a dark strip with bold text
final class SymbolStrip: UIView {
    let label = RichLabel()
    private let grad: GradientView?
    init(gradient: Bool, size: Double = 12) {
        grad = gradient ? GradientView([UIColor(css: "#333").withAlphaComponent(0), UIColor(css: "#333"), UIColor(css: "#333"), UIColor(css: "#333").withAlphaComponent(0)], vertical: false) : nil
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        if let g = grad { addSubview(g) } else { backgroundColor = UIColor(css: "#333") }
        var st = TextStyle.base(size, color: UIColor(white: 1, alpha: 0.7)); st.bold = true; st.align = .center; st.nowrap = true
        st.shadow = Shadows.make(0, 1, 0)
        label.style = st
        addSubview(label)
        clipsToBounds = true
    }
    required init?(coder: NSCoder) { fatalError() }
    var textInset: (Double, Double) = (6, 3)
    override func layoutSubviews() {
        super.layoutSubviews()
        grad?.frame = bounds
        label.frame = CGRect(x: px(textInset.0), y: px(textInset.1), width: bounds.width - px(textInset.0 * 2), height: bounds.height - px(textInset.1 * 2))
    }
}

/// one .bankGood card
final class GoodCard: UIView {
    let box = TapView()
    let icon: IconView
    let sym = SymbolStrip(gradient: false)
    let valS = SymbolStrip(gradient: true)
    let stockS = SymbolStrip(gradient: true)
    let eye = TapView()
    let eyeImg = PicView("mgimg/tinyEyeOn.png")
    let buyL = SymbolStrip(gradient: false)
    let sellL = SymbolStrip(gradient: false)
    var buys: [BankButton] = []
    var sells: [BankButton] = []
    init(_ g: Good) {
        icon = IconView(g.icon)
        super.init(frame: .zero)
        box.backgroundColor = UIColor(white: 0, alpha: 0.9)
        box.layer.borderColor = UIColor(white: 1, alpha: 0.1).cgColor
        box.layer.borderWidth = px(1)
        addSubview(box)
        for v in [sym, valS, stockS] { addSubview(v) }
        eye.addSubview(eyeImg)
        eyeImg.alpha = 0.8
        addSubview(eye)
        buyL.label.html = "Buy"; sellL.label.html = "Sell"
        buyL.textInset = (6, 3); sellL.textInset = (6, 3)
        addSubview(buyL); addSubview(sellL)
        for (t, k) in [("1", 1.0), ("10", 10), ("100", 100), ("Max", 10000)] { let b = BankButton(t, .buy); b.tag = Int(k); if k == 10000 { b.minContent = 28 }; buys.append(b); addSubview(b) }
        for (t, k) in [("1", 1.0), ("10", 10), ("100", 100), ("All", 10000)] { let b = BankButton(t, .sell); b.tag = Int(k); if k == 10000 { b.minContent = 28 }; sells.append(b); addSubview(b) }
        icon.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        addSubview(icon)
    }
    required init?(coder: NSCoder) { fatalError() }
    func setHidden(_ h: Bool) {
        alpha = h ? 0.75 : 1
        box.backgroundColor = h ? .clear : UIColor(white: 0, alpha: 0.9)
        box.layer.borderWidth = h ? 0 : px(1)
        eyeImg.path = h ? "mgimg/tinyEyeOff.png" : "mgimg/tinyEyeOn.png"
    }
    /// measured from the page: the card is 304x132, strips at +7/+26/+45, the buttons at +66/+97
    func layout() {
        box.frame = CGRect(x: 0, y: 0, width: px(304), height: px(132))
        sym.frame = CGRect(x: px(4), y: px(7), width: px(308), height: px(18))
        valS.frame = CGRect(x: px(4), y: px(26), width: px(308), height: px(18))
        stockS.frame = CGRect(x: px(4), y: px(45), width: px(308), height: px(18))
        eye.frame = CGRect(x: px(278), y: px(4), width: px(20), height: px(20))
        eyeImg.frame = eye.bounds
        icon.center = CGPoint(x: px(8), y: px(8))
        for (row, (lab, bs)) in [(buyL, buys), (sellL, sells)].enumerated() {
            let total = 34 + bs.reduce(0) { $0 + $1.width + 2 }
            var x = 4 + (296 - total) / 2
            let y = 66.0 + Double(row) * 31
            lab.frame = CGRect(x: px(x), y: px(y + 5), width: px(34), height: px(18))
            x += 34 + 1
            for b in bs {
                b.frame = CGRect(x: px(x), y: px(y), width: px(b.width), height: px(27))
                x += b.width + 2
            }
        }
    }
}

/// the price graph (#bankGraph)
final class MarketGraph: UIView {
    weak var M: Market?
    override init(frame: CGRect) { super.init(frame: frame); isOpaque = true; contentMode = .redraw }
    required init?(coder: NSCoder) { fatalError() }
    override func draw(_ rect: CGRect) {
        guard let M = M, let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.scaleBy(x: K, y: K)
        let width = M.graphWidth, height = M.graphHeight
        let span = max(4, (width / 65).rounded(.up))
        let cols = M.cols
        func fill(_ c: UIColor, _ x: Double, _ y: Double, _ w: Double, _ h: Double) { c.setFill(); ctx.fill(CGRect(x: x, y: y, width: w, height: h)) }
        fill(cols.bg, 0, 0, width, height)
        let rows = Int((width / span).rounded(.up))
        var i = 0.0
        while i < height / M.graphScale {
            fill(Int(i) % 10 != 0 ? cols.line1 : cols.line2, width - span * Double(rows), height - (i * M.graphScale).rounded(.down), span * Double(rows), 1)
            i += 2
        }
        for iR in 0..<rows {
            if (iR - M.ticks) % 10 != 0 { continue }
            fill((iR - M.ticks) % 60 != 0 ? cols.line1 : cols.line2, width - span * Double(iR) - 1, 0, 1, height)
        }
        ctx.setLineWidth(2)
        ctx.setLineCap(.butt)
        for gi in 0..<(M.goods.count + 1) {
            var id = gi
            if gi == M.goods.count { id = M.hoverOnGood } else if gi == M.hoverOnGood { continue }
            if id == -1 { continue }
            let me = M.goods[id]
            if me.hidden || !me.active { continue }
            for iR in 0..<rows where me.vals.count >= 2 + iR {
                let delta = M.goodDelta(me.id, iR)
                let x0 = width - span * Double(iR)
                if M.graphLines == 0 {
                    let mn = max(me.vals[iR], me.vals[1 + iR])
                    let mx = abs(me.vals[iR] - me.vals[1 + iR])
                    let min2 = abs(sin(Double(M.ticks - iR) * 11 + Double(id) * 137)) * mx * 2
                    let max2 = min2 + abs(sin(Double(M.ticks - iR) * 13 + Double(id) * 139)) * mx * 2
                    if M.hoverOnGood == id {
                        fill(cols.highlight, x0 - span - 1, (height - mn * M.graphScale).rounded(.down) - 1, span + 1, max(3, (mx * M.graphScale).rounded(.up)) + 2)
                    }
                    let c = delta > 0 ? cols.high : cols.low
                    fill(c, x0 - span, (height - mn * M.graphScale).rounded(.down), span - 1, max(3, (mx * M.graphScale).rounded(.up)))
                    fill(c, x0 - span / 2 - 1, (height - (mn + min2) * M.graphScale).rounded(.down), 1, max(3, ((mx + max2) * M.graphScale).rounded(.up)))
                } else {
                    let a = CGPoint(x: x0 - span - 1, y: (height - me.vals[1 + iR] * M.graphScale).rounded(.down) + 0.5)
                    let b = CGPoint(x: x0 - 1, y: (height - me.vals[iR] * M.graphScale).rounded(.down) + 0.5)
                    if M.hoverOnGood == id {
                        ctx.setLineWidth(4)
                        ctx.setStrokeColor(cols.highlight.cgColor)
                        ctx.move(to: a); ctx.addLine(to: b); ctx.strokePath()
                        ctx.setLineWidth(2)
                    }
                    ctx.setStrokeColor((delta > 0 ? cols.high : cols.low).cgColor)
                    ctx.move(to: a); ctx.addLine(to: b); ctx.strokePath()
                }
            }
        }
    }
    /// which line a point (in CSS px of the graph) is on (the page's mousemove)
    func lineAt(_ x: Double, _ y: Double) -> (Int, Int)? {
        guard let M = M else { return nil }
        let width = M.graphWidth, height = M.graphHeight
        let span = max(4, (width / 65).rounded(.up))
        let rows = Int((width / span).rounded(.up))
        for i in stride(from: M.goods.count - 1, through: 0, by: -1) {
            let me = M.goods[i]
            if me.hidden || !me.active { continue }
            for iR in 0..<rows where me.vals.count >= 2 + iR {
                let mn = max(me.vals[iR], me.vals[1 + iR])
                let mx = abs(me.vals[iR] - me.vals[1 + iR])
                // a finger is less precise than a mouse: 6px more each way
                if x >= width - span * Double(iR) - span - 8 && x <= width - span * Double(iR) + 8 && y >= height - mn * M.graphScale - 12 && y <= height - mn * M.graphScale + max(3, mx * M.graphScale) + 12 {
                    return (i, iR)
                }
            }
        }
        return nil
    }
}

final class MarketScreen: UIView, MinigameScreen {
    let M: Market
    private let bg = PatternView("mgimg/BGmarket.jpg")
    private let borders = PicView("mgimg/shadedBorders.png")
    private let headText = RichLabel()
    private let officeTap = TapView()
    private let officeIcon = IconView([0, 33])
    private let officeName = SymbolStrip(gradient: false, size: 10)
    private let officeUpgrade = BankButton("-", .buy, lineHeight: 19.5)
    private let brokersTap = TapView()
    private let brokersIcon = IconView([1, 33])
    private let brokersText = SymbolStrip(gradient: false, size: 10)
    private let brokersBuy = BankButton("Hire", .buy, lineHeight: 19.5)
    private var loans: [BankButton] = []
    private var cards: [GoodCard] = []
    private let graphBox = TapView()
    private let graph = MarketGraph()
    private let linesB = RichLabel()
    private let colsB = RichLabel()
    private let linesT = TapView(), colsT = TapView()
    private let dough = RichLabel()
    private var graphIcons: [IconView] = []
    private var drawT = 0
    private var width = 320.0
    private var graphY = 0.0

    init(_ m: Market) {
        M = m
        super.init(frame: .zero)
        addSubview(bg); addSubview(borders)
        var ht = TextStyle.base(10, color: UIColor(white: 1, alpha: 0.5)); ht.align = .center; ht.lineHeight = 1.5
        headText.style = ht
        addSubview(headText)
        // office
        officeIcon.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        officeName.textInset = (4, 2)
        brokersText.textInset = (4, 2)
        for v in [officeName, brokersText] { var s = v.label.style; s.color = .white; s.lineHeight = 1.5; v.label.style = s }
        officeTap.onTap = { [weak self] _ in self?.tip { $0.M.officeTooltip() } }
        addSubview(officeTap)
        officeTap.addSubview(officeName); officeTap.addSubview(officeIcon)
        officeUpgrade.onTap = { [weak self] b in
            guard let self = self else { return }
            _ = self.M.upgradeOffice()
            self.tip { $0.M.officeTooltip() }
            self.refreshHeader(); self.relayout()
        }
        addSubview(officeUpgrade)
        brokersIcon.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        brokersTap.onTap = { [weak self] _ in self?.tip { $0.M.brokersTooltip() } }
        addSubview(brokersTap)
        brokersTap.addSubview(brokersText); brokersTap.addSubview(brokersIcon)
        brokersBuy.onTap = { [weak self] _ in
            guard let self = self else { return }
            _ = self.M.hireBroker()
            self.tip { $0.M.brokersTooltip() }
            self.refreshHeader()
        }
        addSubview(brokersBuy)
        for (i, t) in ["1st loan", "2nd loan", "3rd loan"].enumerated() {
            let b = BankButton(t, .sell, lineHeight: 19.5)
            b.onTap = { [weak self] _ in
                guard let self = self else { return }
                if self.M.takeLoan(i + 1) { PlaySound("snd/cashIn2.mp3", 0.6) }
                self.tip { $0.M.loanTooltip(i + 1) }
                self.refreshHeader()
            }
            loans.append(b)
            addSubview(b)
        }
        // goods
        for g in m.goods {
            let c = GoodCard(g)
            let id = g.id
            c.box.onTap = { [weak self] _ in
                guard let self = self else { return }
                if self.M.hoverOnGood != id { self.M.hoverOnGood = id; self.M.toRedraw = 2 }
                self.tip { $0.M.goodTooltip(id) }
            }
            c.eye.onTap = { [weak self] _ in self?.M.toggleHidden(id) }
            for b in c.buys {
                b.onTap = { [weak self] _ in
                    guard let self = self else { return }
                    self.M.buyGood(id, Double(b.tag))
                    self.tip { $0.M.tradeTooltip(id, Double(b.tag)) }
                    self.refreshGoods(force: true)
                }
            }
            for b in c.sells {
                b.onTap = { [weak self] _ in
                    guard let self = self else { return }
                    self.M.sellGood(id, Double(b.tag))
                    self.tip { $0.M.tradeTooltip(id, -Double(b.tag)) }
                    self.refreshGoods(force: true)
                }
            }
            cards.append(c)
            addSubview(c)
        }
        // the graph
        graphBox.clipsToBounds = true
        graphBox.layer.cornerRadius = px(4)
        graph.M = m
        graphBox.addSubview(graph)
        for g in m.goods {
            let ic = IconView(g.icon)
            ic.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            ic.isUserInteractionEnabled = false
            graphIcons.append(ic)
            graphBox.addSubview(ic)
        }
        var bs = TextStyle.base(10, color: UIColor(white: 1, alpha: 0.9)); bs.bold = true; bs.align = .center; bs.nowrap = true; bs.shadow = Shadows.make(0, 1, 0)
        for (t, l, s) in [(linesT, linesB, "Line style"), (colsT, colsB, "Color mode")] {
            l.style = bs
            l.html = "<span style=\"text-decoration:underline;\">\(s)</span>"
            t.backgroundColor = UIColor(white: 0, alpha: 0.5)
            t.layer.cornerRadius = px(4)
            t.addSubview(l)
            graphBox.addSubview(t)
        }
        linesT.onTap = { [weak self] _ in
            guard let self = self else { return }
            self.M.graphLines = self.M.graphLines == 0 ? 1 : 0
            self.M.toRedraw = 2
            PlaySound("snd/tick.mp3", 1)
        }
        colsT.onTap = { [weak self] _ in
            guard let self = self else { return }
            self.M.graphCols = self.M.graphCols == 0 ? 1 : 0
            self.M.toRedraw = 2
            self.applyCols()
            PlaySound("snd/tick.mp3", 1)
        }
        var ds = TextStyle.base(12); ds.bold = true; ds.letterSpacing = 2; ds.nowrap = true
        dough.style = ds
        dough.html = "DOUGH JONES INDEX"
        dough.alpha = 0.15
        dough.isUserInteractionEnabled = false
        graphBox.addSubview(dough)
        graphBox.onTap = { [weak self] _ in
            guard let self = self, let p = self.lastGraphTouch else { return }
            let gx = Double(p.x / K) + 2, gy = Double(p.y / K)
            if let (id, iR) = self.graph.lineAt(gx, gy) {
                if self.M.hoverOnGood != id { self.M.hoverOnGood = id; self.M.toRedraw = 2 }
                self.tip { $0.M.lineTooltip(id, iR) }
            } else if self.M.hoverOnGood != -1 { self.M.hoverOnGood = -1; self.M.toRedraw = 2 }
        }
        graphBox.onDown = { [weak self] v, p in self?.lastGraphTouch = v.convert(p, from: nil) }
        addSubview(graphBox)
        applyCols()
        m.onStyleChanged = { [weak self] in self?.relayout() }
        refreshHeader()
        refreshGoods(force: true)
    }
    required init?(coder: NSCoder) { fatalError() }
    private var lastGraphTouch: CGPoint?

    private func tip(_ f: @escaping (MarketScreen) -> (String, [Int]?)) {
        MinigameWindow.current?.showTooltip { [weak self] in self.map(f) ?? ("", nil) }
    }
    private func applyCols() {
        graphBox.backgroundColor = M.cols.bg
        var s = dough.style; s.color = M.cols.highlight; dough.style = s
    }
    private func relayout() { MinigameWindow.current?.relayoutContent() }
    private func textWidth(_ html: String, _ st: TextStyle) -> Double {
        Double(RichText.size(RichText.render(html, style: st, width: nil), width: nil).width)
    }

    // the header's numbers (M.draw every 10 frames)
    private func refreshHeader() {
        let p = M.profit
        let bal = "<span style=\"\(p > 0 ? "color:#73f21e;" : p < 0 ? "color:#f21e3c;" : "")\">\(p < 0 ? "-" : "")$\(B(abs(p), 2))\(p > 0 ? "\u{25b2}" : p < 0 ? "\u{25bc}" : "")</span>"
        let next = Loc.sayTime((G.fps * M.secondsPerTick) - M.tickT + 30, -1)
        headText.html = "Profits: \(bal). All prices are in <b style=\"color:#fff;\">$</b>econds of your highest raw cookies per second. Next tick in \(next)."
        let office = M.offices[M.officeLevel]
        officeIcon.icon = office.icon
        officeName.label.html = office.name
        if let c = office.cost {
            officeUpgrade.isHidden = false
            officeUpgrade.text = "Upgrade (\(c[0]) cursors)"
            officeUpgrade.off = !M.canUpgradeOffice
        } else { officeUpgrade.isHidden = true }
        brokersText.label.html = M.brokers == 0 ? "no brokers" : M.brokers == 1 ? "1 broker" : "\(jsString(M.brokers)) brokers"
        brokersBuy.off = !M.canHire
        for (i, b) in loans.enumerated() {
            b.isHidden = M.officeLevel <= [1, 3, 4][i]
            b.off = M.loanTaken(i + 1)
        }
    }
    private var lastVals: [String] = []
    private func refreshGoods(force: Bool) {
        for (i, c) in cards.enumerated() {
            let me = M.goods[i]
            let delta = M.goodDelta(i)
            c.sym.label.html = "\(me.symbol) <span style=\"font-weight:normal;color:\(delta >= 0 ? "#73f21e" : "#f21e3c");\">\(M.deltaString(delta))\(delta >= 0 ? "\u{25b2}" : "\u{25bc}")</span>"
            c.valS.label.html = "value: <span style=\"color:#fff;\">$\(B(me.val, 2))</span>"
            c.stockS.label.html = "stock: \(B(me.stock))/\(B(M.getGoodMaxStock(me)))"
            var st = c.stockS.label.style
            st.color = me.stock > 0 ? UIColor(css: "#3f0") : UIColor(white: 1, alpha: 0.7)
            c.stockS.label.style = st
            c.setHidden(me.hidden)
        }
        placeGraphIcons()
    }
    private func placeGraphIcons() {
        for (i, ic) in graphIcons.enumerated() {
            let me = M.goods[i]
            ic.isHidden = !me.active || me.hidden
            // right:-24px; top:-24px; translate(-8px, H - val*scale) scale(0.5): a 24px picture
            let y = M.graphHeight - me.vals[0] * M.graphScale
            ic.center = CGPoint(x: px(308 + 24 - 24 - 8), y: px(-24 + 24 + y.rounded(.down)))
        }
    }

    func layoutContent(width w: Double, minHeight: Double) -> Double {
        width = w
        // measured from the page (#bankContent padding 4px 6px 16px)
        headText.frame = CGRect(x: px(10), y: px(5), width: px(w - 20), height: px(30))
        // office: the icon and name, then the upgrade button on its own line
        let nameW = 136.0
        let line1 = 16 + nameW
        var x = (w - 12 - 8 - line1) / 2 + 10
        officeTap.frame = CGRect(x: px(x - 14), y: px(32), width: px(line1 + 14), height: px(26))
        officeIcon.center = CGPoint(x: px(12), y: px(12))
        officeName.frame = CGRect(x: px(18), y: px(5.2), width: px(nameW), height: px(19))
        var y = 36.0
        if !officeUpgrade.isHidden {
            let bw = officeUpgrade.width
            officeUpgrade.frame = CGRect(x: px((w - bw) / 2), y: px(58.2), width: px(bw), height: px(33.5))
            y = 93.7
        } else { y = 36 + 21.7 }
        // brokers (+ the loans block on the same line when it fits)
        let hireW = brokersBuy.width
        let brokersW = 2 + 16 + 104 + 1 + hireW + 1 + 8
        let shownLoans = loans.filter { !$0.isHidden }
        let loansW = 8 + shownLoans.reduce(0) { $0 + $1.width + 2 }
        let sameLine = brokersW + loansW <= w - 12
        let lineW = sameLine ? brokersW + loansW : brokersW
        x = (w - lineW) / 2
        brokersTap.frame = CGRect(x: px(x), y: px(y + 2), width: px(16 + 104 + 4), height: px(33.5))
        brokersIcon.center = CGPoint(x: px(14), y: px(17.8))
        brokersText.frame = CGRect(x: px(20), y: px(9), width: px(104), height: px(19))
        brokersBuy.frame = CGRect(x: px(x + 125), y: px(y + 2), width: px(hireW), height: px(33.5))
        var lx = sameLine ? x + brokersW + 4 : (w - loansW) / 2 + 4
        var ly = y + 2
        if !sameLine && !shownLoans.isEmpty { y += 37.5; ly = y + 2 }
        for b in shownLoans {
            b.frame = CGRect(x: px(lx + 1), y: px(ly), width: px(b.width), height: px(33.5))
            lx += b.width + 2
        }
        y += 37.5 + 3
        // goods
        for (i, c) in cards.enumerated() {
            let me = M.goods[i]
            c.isHidden = !me.active
            if !me.active { continue }
            c.frame = CGRect(x: px(8), y: px(y), width: px(304), height: px(132))
            c.layout()
            y += 138
        }
        y += 3 - 4 + 6
        // the graph (#bankGraphBox 200px high, the canvas 300px high under it)
        graphY = y
        M.graphWidth = w - 22
        graphBox.frame = CGRect(x: px(6), y: px(y), width: px(w - 12), height: px(200))
        graph.frame = CGRect(x: px(-2), y: 0, width: px(M.graphWidth), height: px(M.graphHeight))
        let lw = max(textWidth("Line style", linesB.style), textWidth("Color mode", colsB.style)) + 4
        linesT.frame = CGRect(x: px(2), y: px(2), width: px(lw), height: px(14))
        colsT.frame = CGRect(x: px(2), y: px(16), width: px(lw), height: px(14))
        linesB.frame = CGRect(x: 0, y: px(2), width: linesT.bounds.width, height: px(10))
        colsB.frame = linesB.frame
        dough.frame = CGRect(x: px(6), y: px(200 - 6 - 12), width: px(220), height: px(12))
        placeGraphIcons()
        M.toRedraw = 2
        graph.setNeedsDisplay()
        y += 200 + 6 + 16
        let h = max(y, minHeight)
        bg.frame = CGRect(x: 0, y: 0, width: px(w), height: px(h))
        borders.frame = bg.frame
        return h
    }

    func drawFrame() {
        drawT += 1
        if drawT % 2 == 0 && M.toRedraw > 0 {
            M.lastTickDrawn = M.ticks
            graph.setNeedsDisplay()
            refreshGoods(force: false)
            M.toRedraw = 0
        }
        if drawT % 10 == 0 {
            let before = (officeUpgrade.isHidden, loans.map { $0.isHidden })
            refreshHeader()
            if before.0 != officeUpgrade.isHidden || before.1 != loans.map({ $0.isHidden }) { relayout() }
        }
    }
}
