import SwiftUI

/// Full-screen minigame panel, opened from a building (Store → info, or the Special tab).
struct MinigameHost: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let name: String
    let u: CGFloat
    let insets: EdgeInsets
    @State private var info: String? = nil

    var bg: String {
        switch name { case "Garden": return "BGgarden.jpg"; case "Stock Market": return "BGmarket.jpg"; case "Pantheon": return "BGpantheon.jpg"; default: return "BGgrimoire.jpg" }
    }

    var body: some View {
        let _ = game.frame
        let mg = Minigames.shared
        ZStack(alignment: .top) {
            Tiled(name: bg, scale: u).ignoresSafeArea()
            Sprites.image("shadedBorders.png").resizable().ignoresSafeArea().allowsHitTesting(false)
            VStack(spacing: 0) {
                HStack {
                    Text(name).font(.fancy(20 * u)).foregroundColor(.white).gameShadow()
                    Spacer()
                    Button { ui.minigame = nil; Sound.play("snd/clickOff2.mp3", 0.5) } label: {
                        Text("Close").font(.fancy(14 * u)).foregroundColor(.white).gameShadow()
                            .padding(.horizontal, 12 * u).padding(.vertical, 6 * u)
                            .background(RoundedRectangle(cornerRadius: 4 * u).fill(Color.black.opacity(0.45)))
                    }.buttonStyle(PressStyle())
                }
                .padding(.horizontal, 10 * u)
                .padding(.top, insets.top + 6 * u)
                .padding(.bottom, 6 * u)
                .background(LinearGradient(colors: [.black.opacity(0.7), .black.opacity(0)], startPoint: .top, endPoint: .bottom))
                ScrollView {
                    Group {
                        switch name {
                        case "Garden": if let gd = mg.garden { GardenView(m: gd, u: u, info: $info) }
                        case "Stock Market": if let mk = mg.market { MarketView(m: mk, u: u, info: $info) }
                        case "Pantheon": if let p = mg.pantheon { PantheonView(m: p, u: u, info: $info) }
                        default: if let gr = mg.grimoire { GrimoireView(m: gr, u: u, info: $info) }
                        }
                    }
                    .padding(.horizontal, 8 * u)
                    .padding(.bottom, insets.bottom + 16 * u)
                }
            }
            ToastsView(u: u).padding(.bottom, insets.bottom + 8 * u)
            if let i = info {
                ZStack {
                    Color.black.opacity(0.45).ignoresSafeArea().onTapGesture { info = nil }
                    VStack(spacing: 6 * u) {
                        RichText(html: i, size: 12 * u, align: .center)
                        GameButton(text: "OK", u: u, size: 13) { info = nil }
                    }
                    .padding(12 * u)
                    .background(Tiled(name: "darkNoise.jpg", scale: u))
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color(hex: "a07b4e"), lineWidth: 2 * u))
                    .padding(20 * u)
                }
            }
        }
    }
}

/// "Refill with a sugar lump" button used by every minigame
struct RefillButton: View {
    @EnvironmentObject var game: Game
    let u: CGFloat
    let text: String
    let action: () -> Void
    var body: some View {
        let can = LumpRefill.canRefill(game) && game.lumps >= 1
        Button(action: action) {
            HStack(spacing: 4 * u) {
                IconView(icon: [29, 14], size: 28 * u)
                VStack(alignment: .leading, spacing: 0) {
                    Text(text).font(.system(size: 10 * u, weight: .bold)).foregroundColor(.white)
                    Text(LumpRefill.canRefill(game) ? "for 1 sugar lump (once every 15 minutes)" : "usable again in \(sayTime(game.lumpRefill / Game.fps * 1000 + 1000, -1))")
                        .font(.system(size: 9 * u)).foregroundColor(LumpRefill.canRefill(game) ? .white.opacity(0.7) : .costRed)
                }
            }
            .padding(4 * u)
            .background(RoundedRectangle(cornerRadius: 4 * u).fill(Color.black.opacity(0.4)))
            .opacity(can ? 1 : 0.6)
        }.buttonStyle(PressStyle())
    }
}

// MARK: - Garden

struct GardenView: View {
    @EnvironmentObject var game: Game
    let m: Garden
    let u: CGFloat
    @Binding var info: String?

    var body: some View {
        VStack(spacing: 8 * u) {
            // tools
            HStack(spacing: 6 * u) {
                tool(3, "Info") { info = gardenInfo() }
                tool(0, "Harvest all") { Sound.play("snd/toneTick.mp3"); m.harvestAll() }
                tool(1, m.freeze == 1 ? "Unfreeze" : "Freeze", on: m.freeze == 1) { m.toggleFreeze() }
                if m.unlockedN >= m.plants.count { tool(2, "Sacrifice") { info = "<b>Sacrifice garden</b><br>Tap the sacrifice tool again within a few seconds to confirm."; sacrificeArmed() } }
                Spacer()
            }
            // plot
            let size = min(48 * u, (320 * u - 32 * u) / 6)
            VStack(spacing: 2 * u) {
                ForEach(0..<6, id: \.self) { y in
                    HStack(spacing: 2 * u) {
                        ForEach(0..<6, id: \.self) { x in tileView(x, y, size) }
                    }
                }
            }
            .padding(6 * u)
            .background(RoundedRectangle(cornerRadius: 6 * u).fill(Color.black.opacity(0.3)))
            RichText(html: "Garden level \(m.building.level) &bull; plot \(gardenSize()) &bull; next tick in <b>\(m.freeze == 1 ? "(frozen)" : sayTime(m.nextStep - now() + 1000, -1))</b><br>Harvests this run: \(m.harvests) (total \(m.harvestsTotal))", size: 10 * u, align: .center)
            RefillButton(u: u, text: "Refill: instantly grow 3 ticks") { m.refill(game) }
            // seeds
            Text("Seeds (\(m.unlockedN)/\(m.plants.count)) — tap one, then tap a tile").font(.fancy(12 * u)).foregroundColor(.white).gameShadow()
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(40 * u), spacing: 4 * u), count: 7), spacing: 4 * u) {
                ForEach(m.plants.filter { $0.plantable }, id: \.id) { p in
                    Button {
                        if p.unlocked == 0 { info = "<b>???</b><br>You haven't unlocked this seed yet."; return }
                        if m.seedSelected == p.id { info = seedInfo(p) }
                        m.seedSelected = m.seedSelected == p.id ? -1 : p.id
                        Sound.play("snd/toneTick.mp3", 0.5)
                        game.frame &+= 1
                    } label: {
                        ZStack {
                            if p.unlocked > 0 { SheetCell(sheet: "gardenPlants.png", x: 0, y: p.icon, w: 48, h: 48, width: 40 * u, height: 40 * u) }
                            else { IconView(icon: [0, 7], size: 40 * u).opacity(0.35) }
                        }
                        .background(RoundedRectangle(cornerRadius: 4 * u).fill(m.seedSelected == p.id ? Color.yellow.opacity(0.35) : Color.black.opacity(0.3)))
                        .opacity(p.unlocked > 0 && game.cookies < m.cost(p) ? 0.5 : 1)
                    }.buttonStyle(.plain)
                }
            }
            if m.seedSelected >= 0, let p = m.plants[safe: m.seedSelected] {
                HStack(spacing: 4 * u) {
                    Text(p.name).font(.fancy(12 * u)).foregroundColor(.white)
                    CostText(cost: m.cost(p), can: game.cookies >= m.cost(p), u: u)
                    Button { info = seedInfo(p) } label: { Image(systemName: "info.circle").foregroundColor(.white) }
                }
            }
            // soils
            Text("Soil").font(.fancy(12 * u)).foregroundColor(.white).gameShadow()
            HStack(spacing: 6 * u) {
                ForEach(Array(Garden.soils.enumerated()), id: \.offset) { i, s in
                    Button {
                        if m.soil == i { info = soilInfo(s) } else { m.setSoil(i) }
                    } label: {
                        VStack(spacing: 0) {
                            IconView(icon: [s.icon, 34], size: 40 * u)
                            Text(s.name).font(.system(size: 8 * u, weight: .bold)).foregroundColor(.white)
                        }
                        .padding(2 * u)
                        .background(RoundedRectangle(cornerRadius: 4 * u).fill(m.soil == i ? Color.green.opacity(0.35) : Color.black.opacity(0.3)))
                        .opacity(m.building.amount >= s.req ? 1 : 0.4)
                    }.buttonStyle(.plain)
                }
            }
            if now() < m.nextSoil { Text("Soil can be changed again in \(sayTime(m.nextSoil - now() + 1000, -1)).").font(.system(size: 9 * u)).foregroundColor(.white.opacity(0.7)) }
        }
    }

    @State private var armedAt = 0.0
    func sacrificeArmed() {
        if now() - armedAt < 4000 { m.convert(); info = nil; armedAt = 0 } else { armedAt = now() }
    }

    func gardenSize() -> String {
        let l = Garden.plotLimits[max(1, min(Garden.plotLimits.count, m.building.level)) - 1]
        return "\(l[2] - l[0])x\(l[3] - l[1])"
    }

    func tool(_ icon: Int, _ text: String, on: Bool = false, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                IconView(icon: [icon, 35], size: 36 * u)
                Text(text).font(.system(size: 8 * u, weight: .bold)).foregroundColor(.white)
            }
            .padding(2 * u)
            .background(RoundedRectangle(cornerRadius: 4 * u).fill(on ? Color.cyan.opacity(0.35) : Color.black.opacity(0.35)))
        }.buttonStyle(PressStyle())
    }

    func tileView(_ x: Int, _ y: Int, _ size: CGFloat) -> some View {
        let unlocked = m.isTileUnlocked(x, y)
        let t = m.plot[y][x]
        return ZStack {
            SheetCell(sheet: "gardenPlots.png", x: unlocked ? 0 : 1, y: 0, w: 40, h: 40, width: size, height: size).opacity(unlocked ? 1 : 0.25)
            if unlocked, let p = m.plant(t) {
                let st = m.stage(p, t.1)
                SheetCell(sheet: "gardenPlants.png", x: st, y: p.icon, w: 48, h: 48, width: size, height: size)
                if t.1 >= p.mature && !p.immortal { Circle().fill(Color.yellow).frame(width: 5 * u, height: 5 * u).offset(x: size * 0.38, y: -size * 0.38) }
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture {
            guard unlocked else { return }
            if m.plot[y][x].0 > 0 && m.seedSelected < 0 { info = tileInfo(x, y) } else { m.clickTile(x, y); game.frame &+= 1 }
        }
        .onLongPressGesture { if m.plot[y][x].0 > 0 { m.clickTile(x, y); game.frame &+= 1 } }
    }

    func seedInfo(_ p: Plant) -> String {
        let boost = 1 / (1 + 0.05 * game.auraMult("Supreme Intellect"))
        var s = "<b>\(p.name) seed</b><br><small>Planting costs \(B(m.cost(p))) cookies</small><br>"
        if !p.immortal { s += "Average lifespan: \(sayTime((100 / (p.ageTick + p.ageTickR / 2)) * boost * m.stepT * 1000, -1))<br>" }
        s += "Average maturation: \(sayTime((100 / (p.ageTick + p.ageTickR / 2)) * (p.mature / 100) * boost * m.stepT * 1000, -1))<br>"
        if p.weed { s += "<b>Is a weed</b><br>" }
        if p.fungus { s += "<b>Is a fungus</b><br>" }
        if !p.details.isEmpty { s += "<b>Details:</b> \(p.details)<br>" }
        let kids = p.children.compactMap { m.plantsBN[$0] }.map { $0.unlocked > 0 ? $0.name : "???" }
        if !kids.isEmpty { s += "<b>Possible mutations:</b> " + kids.joined(separator: ", ") + "<br>" }
        s += "<b>Effects:</b> <small>(while plant is alive; scales with plant growth)</small>" + p.effs
        if !p.q.isEmpty { s += "<q>\(p.q)</q>" }
        return s
    }
    func tileInfo(_ x: Int, _ y: Int) -> String {
        let t = m.plot[y][x]
        guard let p = m.plant(t) else { return "Empty tile." }
        let st = ["", "Bud", "Sprout", "Bloom", "Mature"][m.stage(p, t.1)]
        let boost = 1 / (1 + 0.05 * game.auraMult("Supreme Intellect"))
        let speed = m.plotBoost[y][x][0] * (p.ageTick + p.ageTickR / 2)
        var s = "<b>\(p.name)</b><br>Stage: <b>\(st)</b> (age \(Int(t.1)))<br>"
        if t.1 < p.mature { s += "Mature in about \(sayTime((100 / speed) * ((p.mature - t.1) / 100) * boost * m.stepT * 1000, -1))<br>" }
        else if !p.immortal { s += "Decays in about \(sayTime((100 / speed) * ((100 - t.1) / 100) * boost * m.stepT * 1000, -1))<br>" }
        else { s += "<b>Immortal</b><br>" }
        s += p.effs
        s += "<br><small>Tap and hold the tile to harvest it" + (t.1 >= p.mature ? " (mature: you'll get its seed and bonus)." : ".") + "</small>"
        return s
    }
    func soilInfo(_ s: Soil) -> String { "<b>\(s.name)</b><br>" + s.effs + "<q>\(s.q)</q>" + (s.req > 0 ? "<br><small>Requires \(s.req) farms.</small>" : "") }
    func gardenInfo() -> String {
        if m.freeze == 1 { return "Your garden is frozen, providing no effects." }
        let names: [(String, String, Bool)] = [("cps", "CpS", false), ("click", "cookies/click", false), ("cursorCps", "cursor CpS", false), ("grandmaCps", "grandma CpS", false),
            ("goldenCookieGain", "golden cookie gains", false), ("goldenCookieFreq", "golden cookie frequency", false), ("goldenCookieDur", "golden cookie duration", false),
            ("goldenCookieEffDur", "golden cookie effect duration", false), ("wrathCookieGain", "wrath cookie gains", false), ("wrathCookieFreq", "wrath cookie frequency", false),
            ("wrathCookieDur", "wrath cookie duration", false), ("wrathCookieEffDur", "wrath cookie effect duration", false), ("reindeerGain", "reindeer gains", false),
            ("reindeerFreq", "reindeer frequency", false), ("reindeerDur", "reindeer duration", false), ("itemDrops", "random drops", false), ("milk", "milk effects", false),
            ("wrinklerSpawn", "wrinkler spawn rate", false), ("wrinklerEat", "wrinkler appetite", false), ("upgradeCost", "upgrade costs", true), ("buildingCost", "building costs", true)]
        var s = "<b>Garden information</b><br>Combined effects of all your plants:<br>"
        var any = false
        for (k, n, rev) in names {
            let v = m.eff(k)
            if v != 1 {
                any = true
                let amt = (v - 1) * 100
                s += "&bull; \(n) <span class=\"\((amt * (rev ? -1 : 1)) > 0 ? "green" : "red")\">\(amt > 0 ? "+" : "-")\(B(abs(amt), 2))%</span><br>"
            }
        }
        if !any { s += "None." }
        return s
    }
}

// MARK: - Pantheon

struct PantheonView: View {
    @EnvironmentObject var game: Game
    let m: Pantheon
    let u: CGFloat
    @Binding var info: String?
    @State private var picked: Int? = nil

    var body: some View {
        VStack(spacing: 8 * u) {
            RichText(html: "Tap a spirit, then tap a slot to worship it. <small>Diamond = strongest effect, Jade = weakest.</small>", size: 11 * u, align: .center)
            HStack(spacing: 10 * u) {
                ForEach(0..<3, id: \.self) { i in
                    Button {
                        if let g = picked { m.place(g, into: i); picked = nil }
                        else if m.slot[i] >= 0 { info = godInfo(m.slot[i]) }
                        game.frame &+= 1
                    } label: {
                        VStack(spacing: 2 * u) {
                            ZStack {
                                Circle().fill([Color(hex: "bfefff"), Color(hex: "ff6a6a"), Color(hex: "6fe07a")][i].opacity(0.25)).frame(width: 64 * u, height: 64 * u)
                                if m.slot[i] >= 0 { IconView(icon: m.gods[m.slot[i]].icon, size: 48 * u) }
                                else { Text("empty").font(.system(size: 9 * u)).foregroundColor(.white.opacity(0.6)) }
                            }
                            Text(Pantheon.slotNames[i]).font(.fancy(11 * u)).foregroundColor(.white).gameShadow()
                        }
                    }.buttonStyle(.plain)
                }
            }
            let wait = m.swapT + m.swapWait() - now()
            RichText(html: "Worship swaps: <b>\(Int(m.swaps))/3</b>" + (m.swaps < 3 ? " (next in \(sayTime(wait + 1000, -1)))" : ""), size: 12 * u, align: .center)
            RefillButton(u: u, text: "Refill all worship swaps") { m.refill(game) }
            if let g = picked {
                HStack {
                    RichText(html: "Picked <b>\(m.gods[g].name)</b>. Tap a slot.", size: 11 * u)
                    if m.godSlot(g) >= 0 { GameButton(text: "Unslot", u: u, size: 11) { m.place(g, into: -1); picked = nil } }
                    GameButton(text: "Cancel", u: u, size: 11) { picked = nil }
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(64 * u), spacing: 6 * u), count: 4), spacing: 6 * u) {
                ForEach(0..<m.gods.count, id: \.self) { i in
                    let god = m.gods[i]
                    Button {
                        if picked == i { info = godInfo(i) }
                        picked = picked == i ? nil : i
                        Sound.play("snd/tick.mp3", 0.5)
                    } label: {
                        VStack(spacing: 0) {
                            IconView(icon: god.icon, size: 44 * u)
                            Text(god.name.components(separatedBy: ",").first ?? god.name).font(.system(size: 8 * u, weight: .bold)).foregroundColor(.white).lineLimit(1)
                        }
                        .frame(width: 64 * u, height: 62 * u)
                        .background(RoundedRectangle(cornerRadius: 4 * u).fill(picked == i ? Color.yellow.opacity(0.35) : Color.black.opacity(0.35)))
                        .opacity(m.godSlot(i) >= 0 ? 0.45 : 1)
                    }.buttonStyle(.plain)
                }
            }
            RichText(html: "<small>Tap a spirit twice to read about it.</small>", size: 10 * u, align: .center)
        }
    }

    func godInfo(_ i: Int) -> String {
        let g = m.gods[i]
        let slot = m.godSlot(i)
        var s = "<b>\(g.name)</b><br>"
        if let b = g.descBefore { s += b + "<br>" }
        for (n, d) in g.desc.enumerated() {
            let gem = Pantheon.slotNames[n]
            s += (slot == n ? "<b>" : "") + "\(gem): " + d + (slot == n ? "</b>" : "") + "<br>"
        }
        if let a = g.descAfter { s += a + "<br>" }
        if g.key == "ages" && m.hasGod("ages") > 0 {
            let per = [0.0, 3, 12, 24][m.hasGod("ages")]
            let v = 0.15 * sin((now() / 1000 / (3600 * per)) * .pi * 2)
            s += "Current bonus: \(v < 0 ? "-" : "+")\(B(abs(v) * 100, 2))%<br>"
        }
        if g.key == "order" { s += "Buildings owned: \(B(Double(game.buildingsN)))<br>Effect is \(game.buildingsN % 10 == 0 ? "active" : "inactive").<br>" }
        return s + "<q>\(g.quote)</q>"
    }
}

// MARK: - Grimoire

struct GrimoireView: View {
    @EnvironmentObject var game: Game
    let m: Grimoire
    let u: CGFloat
    @Binding var info: String?

    var body: some View {
        VStack(spacing: 8 * u) {
            // magic meter
            VStack(spacing: 2 * u) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3 * u).fill(Color.black.opacity(0.5))
                        RoundedRectangle(cornerRadius: 3 * u).fill(LinearGradient(colors: [Color(hex: "7a5cff"), Color(hex: "c45cff")], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(m.magicM > 0 ? m.magic / m.magicM : 0))
                        Text("\(Int(m.magic))/\(B(m.magicM))" + (m.magic < m.magicM ? " (+\(B(m.magicPS * Game.fps, 2))/s)" : ""))
                            .font(.fancy(11 * u)).foregroundColor(.white).gameShadow().frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 18 * u)
                Text("Spells cast: \(B(Double(m.spellsCast))) (total: \(B(Double(m.spellsCastTotal))))").font(.system(size: 10 * u)).foregroundColor(.white.opacity(0.8))
            }
            RefillButton(u: u, text: "Refill 100 magic") { m.refill(game) }
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(68 * u), spacing: 6 * u), count: 4), spacing: 8 * u) {
                ForEach(Array(m.spells.enumerated()), id: \.offset) { i, s in
                    let cost = m.cost(s)
                    let ready = m.magic >= cost
                    Button {
                        if ready { m.cast(s); game.frame &+= 1 } else { info = spellInfo(s) }
                    } label: {
                        VStack(spacing: 0) {
                            IconView(icon: s.icon, size: 44 * u)
                            Text(B(cost)).font(.fancy(12 * u)).foregroundColor(ready ? .white : .costRed)
                        }
                        .frame(width: 60 * u, height: 74 * u)
                        .background(SheetCell(sheet: "spellBG.png", x: i % 4, y: 0, w: 60, h: 74, width: 60 * u, height: 74 * u))
                        .opacity(ready ? 1 : 0.75)
                    }
                    .buttonStyle(PressStyle())
                    .simultaneousGesture(LongPressGesture().onEnded { _ in info = spellInfo(s) })
                }
            }
            RichText(html: "<small>Tap a spell to cast it. Press and hold to read what it does.</small>", size: 10 * u, align: .center)
        }
    }

    func spellInfo(_ s: Spell) -> String {
        var str = "<b>\(s.name)</b><br>Magic cost: <b>\(B(m.cost(s)))</b><br>" + "<span class=\"green\">Effect: \(s.desc)</span>"
        if let f = s.failDesc { str += "<br><span class=\"red\">Backfire: \(f)</span><br><small>Chance to backfire: \(B(m.failChance(s) * 100, 1))%</small>" }
        return str
    }
}

// MARK: - Stock Market

struct MarketView: View {
    @EnvironmentObject var game: Game
    let m: Market
    let u: CGFloat
    @Binding var info: String?
    @State private var selected: Int? = nil

    var body: some View {
        VStack(spacing: 8 * u) {
            // office, brokers, loans, profit
            VStack(spacing: 4 * u) {
                let office = Market.offices[m.officeLevel]
                HStack(spacing: 4 * u) {
                    IconView(icon: office.icon, size: 28 * u)
                    Text(office.name).font(.fancy(12 * u)).foregroundColor(.white)
                    Spacer()
                    if let c = office.cost {
                        GameButton(text: "Upgrade (\(c.0) cursors)", u: u, size: 10, enabled: game.buildings[0].amount >= c.0 && game.buildings[0].level >= c.1) { m.upgradeOffice() }
                    }
                    Button { info = office.desc + (office.cost.map { "<br>Upgrading costs <b>\($0.0) cursors</b> and requires <b>level \($0.1) cursors</b>." } ?? "") } label: { Image(systemName: "info.circle").foregroundColor(.white) }
                }
                HStack(spacing: 4 * u) {
                    IconView(icon: [1, 33], size: 28 * u)
                    Text(m.brokers == 0 ? "no brokers" : "\(m.brokers) broker\(m.brokers == 1 ? "" : "s")").font(.fancy(12 * u)).foregroundColor(.white)
                    Spacer()
                    GameButton(text: "Hire", u: u, size: 10, enabled: m.brokers < m.maxBrokers() && game.cookies >= m.brokerPrice()) { m.hireBroker() }
                    Button { info = "A nice broker to trade more cookies.<br>&bull; Buying goods normally incurs overhead costs of <b>20% extra</b>. Each broker you hire reduces that overhead by <b>5%</b>.<br>&bull; Current overhead: <b>+\(B((m.overhead() - 1) * 100, 2))%</b><br>&bull; Buying a broker costs 20 minutes of CpS (<b>\(B(m.brokerPrice()))</b> cookies).<br>&bull; You can hire up to <b>\(m.maxBrokers())</b> brokers (grandmas owned / 10 + grandma level)." } label: { Image(systemName: "info.circle").foregroundColor(.white) }
                }
                if m.loanSlots() > 0 {
                    HStack(spacing: 4 * u) {
                        ForEach(1...m.loanSlots(), id: \.self) { id in
                            let busy = game.hasBuff("loan \(id)") != nil || game.hasBuff("loan \(id) interest") != nil
                            GameButton(text: "Loan \(id)", u: u, size: 10, enabled: !busy) {
                                let l = Market.loanTypes[id - 1]
                                info = "By taking <b>\(l.0)</b>, you will get <span class=\"green\">+\(Int(((l.1 - 1) * 100).rounded()))%</span> CpS for the next <b>\(sayTime(l.2 * 60000, -1))</b>.<br>However, you will get <span class=\"red\">\(Int(((l.3 - 1) * 100).rounded()))%</span> CpS for the next <b>\(sayTime(l.4 * 60000, -1))</b> after that.<br>You must also pay an immediate downpayment of <b>\(B(game.cookies * l.5))</b> (\(Int(l.5 * 100))% of your bank).<q>\(l.6)</q><br>Press and hold to take the loan."
                            }
                            .simultaneousGesture(LongPressGesture().onEnded { _ in if !busy { m.takeLoan(id); info = nil } })
                        }
                        Spacer()
                    }
                }
                HStack {
                    Text("Profits: ").font(.fancy(12 * u)).foregroundColor(.white)
                    Text((m.profit < 0 ? "-" : "") + "$" + B(abs(m.profit), 2)).font(.fancy(12 * u)).foregroundColor(m.profit > 0 ? .costGreen : m.profit < 0 ? .costRed : .white)
                    Spacer()
                    Text("Next tick in \(sayTime((Game.fps * m.secondsPerTick - m.tickT) / Game.fps * 1000 + 1000, -1))").font(.system(size: 9 * u)).foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(6 * u)
            .background(RoundedRectangle(cornerRadius: 4 * u).fill(Color.black.opacity(0.45)))
            RefillButton(u: u, text: "Refill: next tick happens right away") { m.refill(game) }
            ForEach(m.goods.filter { $0.active }, id: \.id) { good in goodRow(good) }
            if m.goods.allSatisfy({ !$0.active }) { Text("Buy some farms to start trading.").font(.system(size: 11 * u)).foregroundColor(.white) }
        }
    }

    func goodRow(_ g: Good) -> some View {
        let d = m.delta(g)
        let maxS = m.maxStock(g)
        return VStack(spacing: 3 * u) {
            HStack(spacing: 4 * u) {
                IconView(icon: g.building.def.icon, size: 26 * u)
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(g.name) (\(g.symbol))").font(.fancy(11 * u)).foregroundColor(.white)
                    Text("$\(B(g.val, 2))  " + (d >= 0 ? "+" : "") + "\(Fmt.jsNumber(d))%").font(.system(size: 10 * u, weight: .bold)).foregroundColor(d > 0 ? .costGreen : d < 0 ? .costRed : .white)
                }
                Spacer()
                Sparkline(vals: g.vals).stroke(d >= 0 ? Color.costGreen : Color.costRed, lineWidth: 1.5).frame(width: 70 * u, height: 22 * u)
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(g.stock)/\(maxS)").font(.system(size: 10 * u, weight: .bold)).foregroundColor(.white)
                    if g.stock > 0 && g.prev > 0 { Text("bought at $\(B(g.prev, 2))").font(.system(size: 8 * u)).foregroundColor(.white.opacity(0.7)) }
                }
            }
            if selected == g.id {
                HStack(spacing: 3 * u) {
                    Text("Buy").font(.system(size: 9 * u, weight: .bold)).foregroundColor(.costGreen)
                    ForEach([1, 10, 100, 10000], id: \.self) { n in
                        GameButton(text: n == 10000 ? "Max" : "\(n)", u: u, size: 9) { if m.buy(g.id, n) { game.frame &+= 1 } }
                    }
                    Spacer()
                    Text("Sell").font(.system(size: 9 * u, weight: .bold)).foregroundColor(.costRed)
                    ForEach([1, 10, 100, 10000], id: \.self) { n in
                        GameButton(text: n == 10000 ? "All" : "\(n)", u: u, size: 9) { if m.sell(g.id, n) { game.frame &+= 1 } }
                    }
                }
                let price = game.cookiesPsRawHighest * g.val * m.overhead()
                RichText(html: "<small>One \(g.name.lowercased()) costs <b>\(B(price))</b> cookies (\(g.company)).</small>", size: 9 * u)
            }
        }
        .padding(5 * u)
        .background(RoundedRectangle(cornerRadius: 4 * u).fill(Color.black.opacity(selected == g.id ? 0.55 : 0.35)))
        .onTapGesture { selected = selected == g.id ? nil : g.id }
    }
}

struct Sparkline: Shape {
    let vals: [Double]
    func path(in r: CGRect) -> Path {
        var p = Path()
        let v = Array(vals.prefix(30).reversed())
        guard v.count > 1, let mn = v.min(), let mx = v.max() else { return p }
        let span = max(0.01, mx - mn)
        for (i, x) in v.enumerated() {
            let pt = CGPoint(x: r.minX + r.width * CGFloat(i) / CGFloat(v.count - 1), y: r.maxY - r.height * CGFloat((x - mn) / span))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        return p
    }
}
