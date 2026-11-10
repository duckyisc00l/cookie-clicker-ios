import SwiftUI

/// Wooden screen title ("Special", "Stats", "Misc"): Georgia bold small caps on the rolling-pin banner
struct ScreenTitle: View {
    let text: String
    let u: CGFloat
    var body: some View {
        HStack(spacing: 0) {
            Sprites.image("pinLeft.png").resizable().frame(width: 30 * u, height: 35.5 * u)
            HStack(spacing: 0) {
                Text(String(text.prefix(1)).uppercased()).font(.georgia(18 * u, bold: true))
                Text(String(text.dropFirst()).uppercased()).font(.georgia(13.5 * u, bold: true))
            }
            .kerning(2 * u)
            .foregroundColor(Color(white: 0.8))
            .shadow(color: .white, radius: 0, x: 0, y: -0.5 * u)
            .shadow(color: .black, radius: 1 * u, x: 0, y: 1 * u)
            .padding(.horizontal, 6 * u)
            .frame(height: 35.5 * u)
            .background(Tiled(name: "pinMid.png", scale: u * 0.5))
            Sprites.image("pinRight.png").resizable().frame(width: 22 * u, height: 35.5 * u)
        }
        .frame(height: 35.5 * u)
    }
}

/// the original's ".bumpy" box border: 1px black inset, light top edge, faint inner ring, 4px corners
struct BumpyBorder: View {
    let u: CGFloat
    var radius: CGFloat = 4
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius * u).strokeBorder(Color.black, lineWidth: 1 * u)
            RoundedRectangle(cornerRadius: radius * u).inset(by: 1 * u).strokeBorder(Color.white.opacity(0.1), lineWidth: 1 * u)
            VStack(spacing: 0) { Color.white.opacity(0.2).frame(height: 2 * u).padding(.horizontal, 2 * u).padding(.top, 1 * u); Spacer(minLength: 0) }
        }
        .allowsHitTesting(false)
    }
}

/// a "bumpy" section box with its black corner label (sliverHeader), like the Special screen
struct Panel<Content: View>: View {
    let title: String?
    var icon: [Int]? = nil
    let u: CGFloat
    @ViewBuilder var content: () -> Content
    var body: some View {
        ZStack(alignment: .topLeading) {
            content()
                .font(.body(11 * u))
                .foregroundColor(Color(white: 0.8))
                .padding(.horizontal, 8 * u).padding(.vertical, 4 * u)
                .padding(.top, title == nil ? 0 : 2 * u)
                .frame(maxWidth: .infinity)
                .shadow(color: .black, radius: 0, x: 1 * u, y: 1 * u)
            if let t = title {
                HStack(spacing: 0) {
                    Text(t).font(.body(9.9 * u, bold: true)).foregroundColor(Color(white: 0.8))
                }
                .padding(.leading, (icon == nil ? 6 : 24) * u).padding(.trailing, 6 * u)
                .frame(height: 16 * u)
                .background(UnevenRoundedRectangle(topLeadingRadius: 4 * u, bottomTrailingRadius: 4 * u).fill(Color.black))
                .overlay(alignment: .leading) { if let i = icon { IconView(icon: i, size: 24 * u).offset(x: 2 * u, y: -3 * u) } }
                .offset(x: 2 * u, y: 2 * u)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BumpyBorder(u: u))
    }
}

/// the original's ".bumpButton" (with the halfButton gradient)
struct GameButton: View {
    let text: String
    let u: CGFloat
    var size: CGFloat = 13
    var enabled = true
    var fancy = true
    let action: () -> Void
    var body: some View {
        Button(action: { if enabled { action() } else { Sound.play("snd/clickOff2.mp3", 0.5) } }) {
            RichText(html: text, size: size * u, color: Color(white: 0.8), font: fancy ? .fancy(size * u) : .body(size * u, bold: true), align: .center)
                .padding(.horizontal, 8 * u).padding(.vertical, 4 * u)
                .background(RoundedRectangle(cornerRadius: 4 * u).fill(LinearGradient(colors: [Color.white.opacity(0.1), Color.black.opacity(0.1)], startPoint: .top, endPoint: .bottom)))
                .background(BumpyBorder(u: u))
                .opacity(enabled ? 1 : 0.5)
                .shadow(color: .black, radius: 0, x: 1 * u, y: 1 * u)
        }
        .buttonStyle(PressStyle())
    }
}

struct SpecialScreen: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let u: CGFloat
    let m: Metrics
    var body: some View {
        let _ = game.frame
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ScreenTitle(text: "Special", u: u).padding(.top, 66 * u).padding(.bottom, -2 * u)
                legacy
                if game.Has("Bingo center/Research facility") { research }
                if game.elderWrath > 0 || game.pledges > 0 || game.Has("Elder Covenant") { grandmapocalypse }
                if game.Has("Golden switch") { goldenSwitch }
                season
                if game.Has("A festive hat") || game.Has("A crumbly egg") { pets }
                minigames
                if game.Has("Classic dairy selection") || game.Has("Basic wallpaper assortment") { customization }
            }
            .padding(.horizontal, 8 * u)
            .padding(.bottom, 12 * u)
        }
    }

    var legacy: some View {
        Panel(title: "Legacy", icon: [19, 7], u: u) {
            if game.resets > 0 || game.cookiesEarned >= 1e12 {
                let gain = (game.howMuchPrestige(game.cookiesReset + game.cookiesEarned) - game.prestige).rounded(.down)
                VStack(spacing: 4 * u) {
                    RichText(html: "Prestige level: <b>\(B(game.prestige))</b> at <b>\(B(game.heavenlyMultiplier() * 100, 1))%</b> of its potential<br><small>(CpS boost: <b>+\(B(game.prestige * game.heavenlyMultiplier(), 1))%</b>)</small><br>Heavenly chips: <b>\(B(game.heavenlyChips))</b>", size: 11 * u, align: .center)
                    RichText(html: "Ascending now will grant you <b>\(B(max(0, gain))) prestige level\(gain == 1 ? "" : "s")</b>.", size: 11 * u, align: .center)
                    GameButton(text: "Ascend", u: u, size: 15) { ui.popup = .ascend }
                }
                .frame(maxWidth: .infinity)
            } else {
                RichText(html: "This feature becomes available once you've baked <b>1 trillion cookies</b> in total.<br>(<b>\(B(1e12 - game.cookiesEarned))</b> more needed)", size: 11 * u, align: .center)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    var research: some View {
        Panel(title: "Bingo center/Research facility", icon: [11, 9], u: u) {
            Button { ui.popup = .research } label: {
                VStack(spacing: 2 * u) {
                    if let r = game.researchUpgrade {
                        HStack { IconView(icon: r.def.icon, size: 24 * u); Text(r.name).font(.system(size: 12 * u, weight: .bold)) }
                        let left = Research.left(game)
                        Text(left > 0 ? "Time left: " + sayTime(left + 1000) : "Research complete. Tap to unlock!").font(.system(size: 10 * u, weight: .bold))
                    } else {
                        Text("Current research: None").font(.system(size: 11 * u))
                        Text("Tap to research new technologies.").font(.system(size: 10 * u)).opacity(0.8)
                    }
                }
                .foregroundColor(.white).frame(maxWidth: .infinity).padding(6 * u)
            }.buttonStyle(.plain)
        }
    }

    var grandmapocalypse: some View {
        Panel(title: "Grandmapocalypse", icon: [8, 9], u: u) {
            VStack(spacing: 4 * u) {
                let stage = ["", "Awoken", "Displeased", "Angered"][min(3, game.elderWrath)]
                RichText(html: game.elderWrath > 0 ? "Grandmatriarchs status: <b>\(stage)</b>" : (game.pledgeT > now() ? "Pledge active for <b>\(sayTime(game.pledgeT - now()))</b>." : "The grandmatriarchs are quiet."), size: 11 * u, align: .center)
                HStack {
                    if game.HasUnlocked("Elder Covenant") { toggle("Elder Covenant", "Covenant") }
                    if game.HasUnlocked("Revoke Elder Covenant") { toggle("Revoke Elder Covenant", "Revoke<br>Covenant") }
                    if game.Has("Elder Pact") && !game.Has("Elder Covenant") && game.HasUnlocked("Elder Pledge") && game.pledgeT <= now() { toggle("Elder Pledge", "Pledge") }
                }
            }.frame(maxWidth: .infinity)
        }
    }

    func toggle(_ name: String, _ label: String) -> some View {
        let up = game.upgradesBN[name]!
        let cost = game.upgradeCost(up)
        return VStack(spacing: 2 * u) {
            Button { ui.popup = .upgrade(up.id) } label: { IconView(icon: up.def.icon, size: 40 * u) }.buttonStyle(.plain)
            GameButton(text: label, u: u, size: 11, enabled: game.cookies >= cost) { _ = game.buyUpgrade(up) }
            CostText(cost: cost, can: game.cookies >= cost, u: u)
        }
    }

    var goldenSwitch: some View {
        Panel(title: "Golden switch", icon: [21, 10], u: u) {
            HStack {
                if game.HasUnlocked("Golden switch [on]") { toggle("Golden switch [on]", "Turn off!") }
                if game.HasUnlocked("Golden switch [off]") { toggle("Golden switch [off]", "Turn on!") }
                RichText(html: (game.Has("Golden switch [off]") ? "Active." : "Inactive.") + "<br>Grants <b>+\(B((game.specialEff("Golden switch [off]", "cpsM", 1) - 1) * 100))%</b> CpS, but golden cookies stop appearing.", size: 10 * u)
            }
        }
    }

    var season: some View {
        Panel(title: "Season", icon: [16, 6], u: u) {
            HStack {
                if game.Has("Season switcher") {
                    GameButton(text: "Switch!", u: u, size: 12) { ui.popup = .seasons }
                }
                if let s = Seasons.info(game.season) {
                    RichText(html: "<b>\(s.name)</b>" + (game.seasonT > 0 ? "<br><small>\(sayTime(game.seasonT - now(), -1)) left</small>" : ""), size: 11 * u)
                } else {
                    Text("No seasonal event.").font(.system(size: 11 * u)).foregroundColor(.white)
                }
                Spacer()
            }
        }
    }

    var pets: some View {
        HStack(spacing: 6 * u) {
            if game.Has("A festive hat") {
                Button { ui.popup = .santa } label: {
                    VStack(spacing: 0) {
                        SheetCell(sheet: "santa.png", x: game.santaLevel, y: 0, w: 96, h: 96, width: 72 * u, height: 72 * u)
                        Text(Santa.levels[game.santaLevel]).font(.system(size: 10 * u, weight: .semibold)).foregroundColor(.white)
                    }.frame(maxWidth: .infinity).padding(4 * u)
                    .background(RoundedRectangle(cornerRadius: 4 * u).fill(Color.black.opacity(0.35)))
                }.buttonStyle(.plain)
            }
            if game.Has("A crumbly egg") {
                Button { ui.popup = .dragon } label: {
                    VStack(spacing: 0) {
                        SheetCell(sheet: "dragon.png", x: Dragon.levels[game.dragonLevel].pic, y: 0, w: 96, h: 96, width: 72 * u, height: 72 * u)
                        Text(Dragon.levels[game.dragonLevel].name).font(.system(size: 10 * u, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                    }.frame(maxWidth: .infinity).padding(4 * u)
                    .background(RoundedRectangle(cornerRadius: 4 * u).fill(Color.black.opacity(0.35)))
                }.buttonStyle(.plain)
            }
        }
    }

    var minigames: some View {
        let list: [(String, String, [Int])] = [("Farm", "Garden", [2, 18]), ("Bank", "Stock Market", [15, 18]), ("Temple", "Pantheon", [16, 18]), ("Wizard tower", "Grimoire", [17, 18])]
        let shown = list.filter { (game.buildingsBN[$0.0]?.amount ?? 0) > 0 || (game.buildingsBN[$0.0]?.level ?? 0) > 0 }
        return Group {
            if !shown.isEmpty && Lumps.canLumps(game) && game.lumpT > 0 {
                Panel(title: "Minigames", icon: [29, 14], u: u) {
                    VStack(spacing: 4 * u) {
                        ForEach(shown, id: \.1) { item in
                            let b = game.buildingsBN[item.0]!
                            HStack {
                                IconView(icon: b.def.icon, size: 32 * u)
                                VStack(alignment: .leading) {
                                    Text(item.1).font(.fancy(13 * u)).foregroundColor(.white)
                                    Text(b.level > 0 ? "\(item.0) level \(b.level)" : "Level up your \(b.def.plural) with a sugar lump to unlock it.").font(.system(size: 9 * u)).foregroundColor(Color(white: 0.8))
                                }
                                Spacer()
                                if b.level > 0 { GameButton(text: "Open", u: u, size: 12) { ui.minigame = item.1; Sound.play("snd/clickOn2.mp3", 0.5) } }
                                else { GameButton(text: "Level up", u: u, size: 11, enabled: game.lumps >= 1) { _ = Lumps.levelUp(game, b) } }
                            }
                        }
                    }
                }
            }
        }
    }

    var customization: some View {
        Panel(title: "Customization", icon: [29, 5], u: u) {
            HStack(spacing: 8 * u) {
                if game.Has("Classic dairy selection") {
                    Button { ui.popup = .message("milk", "") } label: { IconView(icon: [1, 8], size: 40 * u) }.buttonStyle(.plain)
                }
                if game.Has("Basic wallpaper assortment") {
                    Button { ui.popup = .message("bg", "") } label: { IconView(icon: [29, 5], size: 40 * u) }.buttonStyle(.plain)
                }
                Spacer()
            }
        }
    }
}
