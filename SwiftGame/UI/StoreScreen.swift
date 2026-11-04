import SwiftUI

struct StoreScreen: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let u: CGFloat

    var body: some View {
        let _ = game.frame
        VStack(spacing: 0) {
            ZStack {
                Tiled(name: "marbleSolid.jpg", scale: u * 0.6)
                if ui.storeTab == .buildings { BuildingList(u: u) } else { UpgradeList(u: u) }
            }
            StoreBottom(u: u)
        }
    }
}

/// a row of the store, like the original's marble bars
struct StoreBar<Content: View>: View {
    let u: CGFloat
    var dim = false
    var index = 0
    @ViewBuilder var content: () -> Content
    var body: some View {
        ZStack(alignment: .leading) {
            SheetCell(sheet: "marbleSlabs.png", x: 0, y: index % 4, w: 692, h: 98, width: 346 * u, height: 49 * u)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).clipped()
            if dim { Color(white: 0.2).opacity(0.6) }
            content()
        }
        .frame(height: 48 * u)
        .padding(.bottom, 1 * u)
    }
}

struct CostText: View {
    let cost: Double
    let can: Bool
    let u: CGFloat
    var body: some View {
        HStack(spacing: 1 * u) {
            Sprites.image("cookicon.png").resizable().frame(width: 11 * u, height: 11 * u)
            Text(B(cost)).font(.fancy(11 * u)).foregroundColor(can ? .costGreen : .costRed)
                .shadow(color: can ? Color(hex: "0f4b35") : Color(hex: "49091e"), radius: 0, x: 1 * u, y: 1 * u)
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
            ZStack {
                Sprites.image("barIndent.png").resizable()
                label()
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

struct BuildingList: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let u: CGFloat
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(game.buildings.filter { $0.locked < 2 }, id: \.id) { b in
                    BuildingRow(b: b, u: u)
                }
                Color.clear.frame(height: 8 * u)
            }
        }
    }
}

struct BuildingRow: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let b: Building
    let u: CGFloat
    var body: some View {
        let mysterious = b.locked == 1
        let cost: Double = game.bulkMode == 1 ? game.sumCost(b, game.bulkBuy) : game.reverseSumCost(b, game.bulkBuy == 10000 ? 1000 : game.bulkBuy)
        let cant = game.bulkMode == 1 && (cost > game.cookies || cost == 0)
        StoreBar(u: u, dim: cant || mysterious, index: b.id) {
            HStack(spacing: 0) {
                BuildingIcon(b: b, mysterious: mysterious, u: u).frame(width: 64 * u, height: 48 * u).opacity(cant ? 0.65 : 1)
                VStack(alignment: .leading, spacing: 0) {
                    Text(mysterious ? "???" : "\(b.amount) \(cap(game.buildingName(b, b.amount)))")
                        .font(.fancy(14 * u)).foregroundColor(.white).lineLimit(1)
                    if mysterious {
                        HStack(spacing: 2 * u) { Text("(Unlocks at").font(.system(size: 10 * u)); CostText(cost: b.def.baseCost, can: true, u: u); Text(")").font(.system(size: 10 * u)) }
                            .foregroundColor(Color(white: 0.75))
                    } else {
                        RichText(html: game.buildingDesc(b), size: 9.5 * u, color: Color(white: cant ? 0.75 : 0.95))
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .gameShadow()
                if !mysterious {
                    IndentButton(u: u, disabled: cant) {
                        game.buy(b)
                    } label: {
                        VStack(spacing: 0) {
                            let n = game.bulkBuy == 10000 ? (game.bulkMode == -1 ? b.amount : game.buyMax(b)) : game.bulkBuy
                            let str = (game.bulkMode == -1 ? "Sell " : "Buy ") + "\(n)"
                            Text(str).font(.fancy(max(8, 17 - CGFloat(str.count)) * u)).foregroundColor(.white).gameShadow()
                            CostText(cost: cost, can: !cant, u: u).scaleEffect(0.9)
                        }
                    }
                    IndentButton(u: u) { ui.popup = .building(b.id) } label: {
                        Text("info").font(.fancy(14 * u)).foregroundColor(.white).gameShadow()
                    }
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
    var body: some View {
        // buildings.png: 4 columns of 64px (normal, mysterious, fools, fools mysterious); one row per building
        var col = mysterious ? 1 : 0
        var row = b.def.pic
        if game.season == "fools" { col = mysterious ? 3 : 2 }
        if b.id == 1 && game.elderWrath > 0 && !mysterious && !game.settings.notScary { col = 3; row = b.def.pic + 1 }
        return SheetCell(sheet: "buildings.png", x: col, y: row, w: 64, h: 64, width: 48 * u, height: 48 * u)
    }
}

struct UpgradeList: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let u: CGFloat
    var body: some View {
        let list = game.upgrades.filter { $0.unlocked > 0 && $0.owned == 0 && !["science", "prestige", "toggle"].contains($0.pool) }
            .sorted { game.upgradeCost($0) < game.upgradeCost($1) }
        ScrollView {
            LazyVStack(spacing: 0) {
                if list.isEmpty {
                    Text("No upgrades available yet.").font(.fancy(13 * u)).foregroundColor(Color(white: 0.7)).padding(24 * u)
                }
                ForEach(list, id: \.id) { up in UpgradeRow(up: up, u: u) }
                Color.clear.frame(height: 8 * u)
            }
        }
        .onAppear { for x in list { x.ping = false } }
    }
}

struct UpgradeRow: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let up: Upgrade
    let u: CGFloat
    var body: some View {
        let cost = game.upgradeCost(up)
        let cant = cost > game.cookies
        StoreBar(u: u, dim: cant, index: up.id) {
            HStack(spacing: 0) {
                IconView(icon: up.def.icon, size: 48 * u).opacity(cant ? 0.65 : 1).padding(.leading, 4 * u)
                VStack(alignment: .leading, spacing: 0) {
                    Text(up.name).font(.fancy(14 * u)).foregroundColor(.white).lineLimit(1)
                    RichText(html: game.upgradeDesc(up), size: 9.5 * u, color: Color(white: cant ? 0.75 : 0.95)).lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6 * u)
                .gameShadow()
                IndentButton(u: u, disabled: cant) {
                    if game.buyUpgrade(up) { Sound.play("snd/buy\(Int.random(in: 1...4)).mp3", 0.75) }
                } label: {
                    VStack(spacing: 0) {
                        Text("Buy").font(.fancy(15 * u)).foregroundColor(.white).gameShadow()
                        CostText(cost: cost, can: !cant, u: u).scaleEffect(0.9)
                    }
                }
                IndentButton(u: u) { ui.popup = .upgrade(up.id) } label: {
                    Text("info").font(.fancy(14 * u)).foregroundColor(.white).gameShadow()
                }
            }
        }
    }
}

struct StoreBottom: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let u: CGFloat
    var body: some View {
        HStack(spacing: 4 * u) {
            storeTab("Buildings", 5, .buildings)
            storeTab("Upgrades", 6, .upgrades)
            Spacer()
            if ui.storeTab == .buildings {
                VStack(spacing: 2 * u) {
                    HStack(spacing: 2 * u) {
                        small(game.bulkMode == 1 ? "Buying" : "Selling", on: true) { game.bulkMode *= -1; Sound.play("snd/tick.mp3", 0.5) }
                    }
                    HStack(spacing: 2 * u) {
                        ForEach([1, 10, 100, 10000], id: \.self) { n in
                            small(n == 10000 ? "max" : "\(n)", on: game.bulkBuy == n) { game.bulkBuy = n; Sound.play("snd/tick.mp3", 0.5) }
                        }
                    }
                }
            } else {
                small("Buy all", on: true, width: 80) { buyAll() }
            }
        }
        .padding(.horizontal, 8 * u)
        .frame(height: 56 * u)
        .background(Tiled(name: "woodPanels.png", scale: u * 0.5))
        .overlay(alignment: .top) { Sprites.image("panelHorizontal.png").resizable().frame(height: 4 * u) }
    }

    func storeTab(_ name: String, _ icon: Int, _ tab: UIState.StoreTab) -> some View {
        let on = ui.storeTab == tab
        return Button { ui.storeTab = tab; Sound.play("snd/press.mp3", 0.3) } label: {
            VStack(spacing: -4 * u) {
                SheetCell(sheet: "tabIcons.png", x: icon, y: on ? 0 : 1, w: 128, h: 128, width: 34 * u, height: 34 * u)
                Text(name).font(.fancy(11 * u)).foregroundColor(on ? .white : Color(white: 0.7)).gameShadow()
            }
            .padding(.horizontal, 4 * u)
            .background(on ? AnyView(Sprites.image("shadedBackdrop.png").resizable()) : AnyView(Color.clear))
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            if tab == .upgrades && game.upgrades.contains(where: { $0.ping && $0.unlocked > 0 && $0.owned == 0 }) && !on {
                Sprites.image("pingDot.png").resizable().frame(width: 10 * u, height: 10 * u)
            }
        }
    }

    func small(_ text: String, on: Bool, width: CGFloat = 34, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text).font(.fancy(11 * u)).foregroundColor(on ? .white : Color(white: 0.6))
                .frame(width: width * u, height: 20 * u)
                .background(RoundedRectangle(cornerRadius: 3 * u).fill(Color.black.opacity(on ? 0.45 : 0.25)))
                .overlay(RoundedRectangle(cornerRadius: 3 * u).stroke(Color.white.opacity(0.15), lineWidth: 1))
                .gameShadow()
        }
        .buttonStyle(PressStyle())
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
