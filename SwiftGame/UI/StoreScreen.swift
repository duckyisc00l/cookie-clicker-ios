import SwiftUI

extension Font {
    /// the original's body font (Tahoma, which iOS shows as Arial)
    static func body(_ size: CGFloat, bold: Bool = false) -> Font { .custom(bold ? "Arial-BoldMT" : "ArialMT", size: size) }
    static func georgia(_ size: CGFloat, bold: Bool = false, italic: Bool = false) -> Font {
        .custom(bold ? "Georgia-Bold" : italic ? "Georgia-Italic" : "Georgia", size: size)
    }
}

/// The Store screen, laid out exactly like the original: list from 56 units under the top, wooden panel (64) above the tabs.
struct StoreScreen: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let u: CGFloat
    let m: Metrics

    var body: some View {
        let _ = game.frame
        let h = m.tabsTop - m.T
        ZStack(alignment: .topLeading) {
            Group {
                if ui.storeTab == .buildings { BuildingList(u: u) } else { UpgradeList(u: u) }
            }
            .background(Tiled(name: "marbleSolid.jpg", scale: u * 346 / 692))
            .at(0, 56, 320, h - 56 - 64, u)
            StoreBottom(u: u).at(0, h - 64, 320, 64, u)
        }
    }
}

/// a row of the store: marble slab (they repeat every 4 rows), 48 tall + 1 gap
struct StoreBar<Content: View>: View {
    let u: CGFloat
    var dim = false
    var index = 0
    @ViewBuilder var content: () -> Content
    var body: some View {
        ZStack(alignment: .topLeading) {
            SheetCell(sheet: "marbleSlabs.png", x: 0, y: index % 4, w: 692, h: 98, width: 346 * u, height: 49 * u)
                .frame(width: 320 * u, height: 49 * u, alignment: .topLeading).clipped()
            if dim { Color(red: 50 / 255, green: 50 / 255, blue: 50 / 255).opacity(0.6).frame(width: 320 * u, height: 48 * u) }
            content().frame(width: 320 * u, height: 48 * u, alignment: .topLeading)
        }
        .frame(width: 320 * u, height: 49 * u, alignment: .topLeading)
    }
}

/// a cookie amount: tiny cookie + green (or red if you can't afford it) Fancy number
struct CostText: View {
    let cost: Double
    let can: Bool
    let u: CGFloat
    var size: CGFloat = 11
    var body: some View {
        HStack(spacing: 0) {
            Sprites.image("cookicon.png").resizable().frame(width: 11.2 * u, height: 11.2 * u).padding(.trailing, 0.5 * u)
            Text(B(cost)).font(.fancy(size * u)).foregroundColor(can ? .costGreen : .costRed)
                .shadow(color: can ? Color(hex: "0f4b35") : Color(hex: "49091e"), radius: 0, x: 1 * u, y: 1 * u)
                .shadow(color: .black, radius: 0.5 * u)
        }
        .lineLimit(1).fixedSize()
    }
}

struct IndentButton<Label: View>: View {
    let u: CGFloat
    var disabled = false
    let action: () -> Void
    @ViewBuilder var label: () -> Label
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                Sprites.image("barIndent.png").resizable().frame(width: 48 * u, height: 48 * u)
                label().frame(width: 48 * u, height: 48 * u, alignment: .topLeading)
            }
            .frame(width: 48 * u, height: 48 * u)
        }
        .buttonStyle(PressStyle())
        .disabled(disabled)
    }
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .brightness(configuration.isPressed ? -0.3 : 0)
    }
}

extension View {
    /// the store's text shadow: 0 0 1px #000, 1px 1px 0 rgba(0,0,0,.5)
    func barShadow(_ u: CGFloat) -> some View {
        self.shadow(color: .black, radius: 0.5 * u).shadow(color: .black.opacity(0.5), radius: 0, x: 1 * u, y: 1 * u)
    }
}

/// name + description columns of a store row (x 44..228, padding 4)
struct BarText: View {
    let name: String
    let desc: String
    let color: Color
    let u: CGFloat
    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(name).font(.fancy(14 * u)).foregroundColor(color).lineLimit(1).truncationMode(.tail)
                .frame(width: 176 * u, alignment: .leading).offset(x: 48 * u, y: 3 * u)
            RichText(html: desc, size: 10 * u, color: color, font: .body(10 * u), lineSpacing: -1.5 * u)
                .lineLimit(3)
                .frame(width: 172 * u, alignment: .topLeading).offset(x: 52 * u, y: 17 * u)
        }
        .barShadow(u)
        .allowsHitTesting(false)
    }
}

struct BuildingList: View {
    @EnvironmentObject var game: Game
    let u: CGFloat
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(Array(game.buildings.filter { $0.locked < 2 }.enumerated()), id: \.element.id) { i, b in
                    BuildingRow(b: b, index: i, u: u)
                }
            }
        }
    }
}

struct BuildingRow: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let b: Building
    let index: Int
    let u: CGFloat
    var body: some View {
        let mysterious = b.locked == 1
        let cost: Double = game.bulkMode == 1 ? game.sumCost(b, game.bulkBuy) : game.reverseSumCost(b, game.bulkBuy == 10000 ? 1000 : game.bulkBuy)
        let cant = mysterious || (game.bulkMode == 1 && (cost > game.cookies || cost == 0))
        let col: Color = cant ? Color(white: 187 / 255) : .white
        StoreBar(u: u, dim: cant, index: index) {
            ZStack(alignment: .topLeading) {
                BuildingIcon(b: b, mysterious: mysterious, u: u).frame(width: 48 * u, height: 48 * u).opacity(cant && !mysterious ? 0.65 : 1)
                if mysterious {
                    Text("???").font(.fancy(14 * u)).foregroundColor(col).barShadow(u).offset(x: 48 * u, y: 3 * u)
                    HStack(spacing: 0) {
                        Text("(Unlocks at ").font(.body(10 * u)).foregroundColor(col)
                        CostText(cost: b.def.baseCost, can: false, u: u)
                        Text(")").font(.body(10 * u)).foregroundColor(col)
                    }.barShadow(u).offset(x: 52 * u, y: 17 * u)
                } else {
                    BarText(name: "\(b.amount) \(cap(game.buildingName(b, b.amount)))", desc: game.buildingDesc(b), color: col, u: u)
                    IndentButton(u: u, disabled: cant) { game.buy(b) } label: {
                        let n = game.bulkBuy == 10000 ? (game.bulkMode == -1 ? b.amount : game.buyMax(b)) : game.bulkBuy
                        let str = (game.bulkMode == -1 ? "Sell " : "Buy ") + "\(n)"
                        ZStack {
                            Text(str).font(.fancy(CGFloat(17 - str.count) * u)).foregroundColor(col).barShadow(u).position(x: 24 * u, y: 19 * u)
                            CostText(cost: cost, can: !cant, u: u).position(x: 24 * u, y: 32 * u)
                        }
                    }.offset(x: 224 * u)
                    IndentButton(u: u) { ui.popup = .building(b.id) } label: {
                        Text("info").font(.fancy(13 * u)).foregroundColor(col).barShadow(u).position(x: 24 * u, y: 24 * u)
                    }.offset(x: 272 * u)
                }
            }
        }
    }
}

struct BuildingIcon: View {
    @EnvironmentObject var game: Game
    let b: Building
    let mysterious: Bool
    let u: CGFloat
    var size: CGFloat = 48
    var body: some View {
        // buildings.png: 64px cells; columns: normal, mysterious, fools, fools mysterious; one row per building
        var col = mysterious ? 1 : 0
        var row = b.def.pic
        if game.season == "fools" { col = mysterious ? 3 : 2 }
        if b.id == 1 && game.elderWrath > 0 && !mysterious && game.settings.notScary { col = 3; row = b.def.pic + 1 }
        return SheetCell(sheet: "buildings.png", x: col, y: row, w: 64, h: 64, width: size * u, height: size * u)
    }
}

struct UpgradeList: View {
    @EnvironmentObject var game: Game
    let u: CGFloat
    var body: some View {
        let list = game.upgrades.filter { $0.unlocked > 0 && $0.owned == 0 && !["science", "prestige", "toggle"].contains($0.pool) }
            .sorted { game.upgradeCost($0) < game.upgradeCost($1) }
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(Array(list.enumerated()), id: \.element.id) { i, up in UpgradeRow(up: up, index: i, u: u) }
            }
        }
        .onAppear { for x in list { x.ping = false } }
    }
}

struct UpgradeRow: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let up: Upgrade
    let index: Int
    let u: CGFloat
    var body: some View {
        let cost = game.upgradeCost(up)
        let cant = cost > game.cookies
        let col: Color = cant ? Color(white: 187 / 255) : .white
        StoreBar(u: u, dim: cant, index: index) {
            ZStack(alignment: .topLeading) {
                IconView(icon: up.def.icon, size: 48 * u).opacity(cant ? 0.65 : 1)
                BarText(name: up.name, desc: game.upgradeDesc(up), color: col, u: u)
                IndentButton(u: u, disabled: cant) {
                    if game.buyUpgrade(up) { Sound.play("snd/buy\(Int.random(in: 1...4)).mp3", 0.75) }
                } label: {
                    ZStack {
                        Text("Buy").font(.fancy(15 * u)).foregroundColor(col).barShadow(u).position(x: 24 * u, y: 19 * u)
                        CostText(cost: cost, can: !cant, u: u).position(x: 24 * u, y: 32 * u)
                    }
                }.offset(x: 224 * u)
                IndentButton(u: u) { ui.popup = .upgrade(up.id) } label: {
                    Text("info").font(.fancy(13 * u)).foregroundColor(col).barShadow(u).position(x: 24 * u, y: 24 * u)
                }.offset(x: 272 * u)
            }
        }
    }
}

/// a button on the wooden panel (the original's ".onWood .button")
struct WoodButton: View {
    let text: String
    let on: Bool
    let u: CGFloat
    let w: CGFloat, h: CGFloat
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(text).font(.fancy(11 * u)).bold().foregroundColor(on ? .white : Color(white: 0.8))
                .shadow(color: .black, radius: 0.5 * u, x: 1 * u, y: 1 * u)
                .frame(width: w * u, height: h * u)
                .background(WoodBox(on: on, u: u))
        }.buttonStyle(PressStyle())
    }
}

struct WoodBox: View {
    let on: Bool
    let u: CGFloat
    var body: some View {
        ZStack {
            Rectangle().fill(Color(red: 32 / 255, green: 16 / 255, blue: 9 / 255).opacity(0.5))
            if on { Rectangle().fill(Color.white.opacity(0.1)) }
            Rectangle().strokeBorder(Color(red: 32 / 255, green: 16 / 255, blue: 9 / 255), lineWidth: 1 * u)
            Rectangle().inset(by: 1 * u).stroke(LinearGradient(colors: [Color(red: 197 / 255, green: 157 / 255, blue: 121 / 255).opacity(0.75), Color(red: 32 / 255, green: 16 / 255, blue: 9 / 255).opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1 * u)
        }
    }
}

struct StoreBottom: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let u: CGFloat
    var body: some View {
        ZStack(alignment: .topLeading) {
            Tiled(name: "woodPanels.png", scale: u * 0.5)
            storeTab("Buildings", 5, .buildings).at(8, 5, 64, 46, u)
            storeTab("Upgrades", 6, .upgrades).at(72, 5, 64, 46, u)
            if ui.storeTab == .buildings {
                WoodButton(text: "Buying", on: game.bulkMode == 1, u: u, w: 96, h: 23) { game.bulkMode = 1; Sound.play("snd/tick.mp3", 0.5) }.at(148, 6, 96, 23, u)
                WoodButton(text: "Selling", on: game.bulkMode == -1, u: u, w: 96, h: 23) { game.bulkMode = -1; Sound.play("snd/tick.mp3", 0.5) }.at(148, 29, 96, 23, u)
                bulk(1, "1", 244, 6); bulk(10, "10", 276, 6); bulk(100, "100", 244, 29); bulk(10000, "Max", 276, 29)
            } else {
                WoodButton(text: "Buy all", on: false, u: u, w: 96, h: 23) { buyAll() }.at(212, 29, 96, 23, u)
            }
        }
        .frame(width: 320 * u, height: 64 * u)
        .clipped()
    }

    func bulk(_ n: Int, _ label: String, _ x: CGFloat, _ y: CGFloat) -> some View {
        WoodButton(text: label, on: game.bulkBuy == n, u: u, w: 32, h: 23) { game.bulkBuy = n; Sound.play("snd/tick.mp3", 0.5) }.at(x, y, 32, 23, u)
    }

    func storeTab(_ name: String, _ icon: Int, _ tab: UIState.StoreTab) -> some View {
        let on = ui.storeTab == tab
        return Button { ui.storeTab = tab; Sound.play("snd/press.mp3", 0.3) } label: {
            ZStack(alignment: .topLeading) {
                WoodBox(on: on, u: u)
                SheetCell(sheet: "tabIcons.png", x: icon, y: on ? 0 : 1, w: 128, h: 128, width: 32 * u, height: 32 * u).offset(x: 16 * u, y: 0)
                Text(name).font(.fancy(11 * u)).bold().foregroundColor(on ? .white : Color(white: 0.8))
                    .shadow(color: .black, radius: 0.5 * u, x: 1 * u, y: 1 * u)
                    .frame(width: 64 * u).offset(y: 31 * u)
                if tab == .upgrades && game.upgrades.contains(where: { $0.ping && $0.unlocked > 0 && $0.owned == 0 }) && !on {
                    Sprites.image("pingDot.png").resizable().frame(width: 16 * u, height: 16 * u).offset(x: 40 * u, y: -4 * u)
                }
            }
            .frame(width: 64 * u, height: 46 * u, alignment: .topLeading)
            .opacity(on ? 1 : 0.75)
        }
        .buttonStyle(.plain)
    }

    func buyAll() {
        Sound.play("snd/clickb2.mp3", 0.75)
        let list = game.upgrades.filter { !["toggle", "science", "prestige"].contains($0.pool) && $0.unlocked > 0 && $0.owned == 0 }
            .sorted { game.upgradeCost($0) < game.upgradeCost($1) }
        var bought = 0
        for x in list { if !game.buyUpgrade(x) { break }; bought += 1 }
        if bought > 0 {
            Sound.play("snd/buy\(Int.random(in: 1...4)).mp3", 0.65)
            game.toast("", "Bought \(B(Double(bought))) upgrade\(bought == 1 ? "" : "s").", nil, true)
        }
    }
}

extension Game {
    /// an upgrade's description, with its extra live info (unshackled, current boost...)
    func upgradeDesc(_ u: Upgrade) -> String {
        var pre = ""
        for e in u.def.effs {
            if case .tier(_, let b, let tu) = e, b != 0,
               let bu = data.buildings[b].unshackle.flatMap({ upgradesBID[$0] }), bu.owned > 0,
               let t = tu.flatMap({ upgradesBID[$0] }), t.owned > 0 {
                pre = "<small>Unshackled! <b>+\(Int((bu.def.power * 100).rounded()))%</b> extra production.</small><br>"
            }
        }
        if Seasons.heartDrops.contains(u.name) { return pre + "Cookie production multiplier <b>+\(2 + (Has("Starlove") ? 1 : 0))%</b>." }
        if u.name == "Century egg" {
            let boost = (specialEff("Century egg", "cpsM", 1) - 1) * 100
            return u.def.desc + "<br><small>Current boost: <b>+\(B(boost, 1))%</b></small>"
        }
        return pre + u.def.desc
    }
}
