import SwiftUI

/// The game's popup window (the original's ".popup.framed"): dark noise panel 300 wide, fitted to its content,
/// with the bumpy "Close" button at the bottom.
struct PopupFrame<Content: View>: View {
    let u: CGFloat
    let insets: EdgeInsets
    var closeText = "Close"
    let close: () -> Void
    @ViewBuilder var content: () -> Content
    var body: some View {
        let inner = VStack(spacing: 2 * u) { content() }
            .foregroundColor(Color(white: 0.8))
            .padding(.horizontal, 11 * u).padding(.vertical, 8 * u)
            .frame(width: 284 * u)
            .frame(minHeight: 252 * u, alignment: .top)
            .background(RoundedRectangle(cornerRadius: 4 * u).fill(Color.black.opacity(0.25)))
            .background(BumpyBorder(u: u))
            .padding(.top, 8 * u).padding(.horizontal, 8 * u)
        ZStack {
            Color.black.opacity(0.001).ignoresSafeArea().onTapGesture(perform: close)
            VStack(spacing: 0) {
                ViewThatFits(in: .vertical) {
                    inner
                    ScrollView(showsIndicators: false) { inner }
                }
                Button(action: { Sound.play("snd/tickOff.mp3", 0.5); close() }) {
                    Text(closeText).font(.fancy(14 * u)).bold().foregroundColor(Color(white: 0.8))
                        .shadow(color: .black, radius: 0, x: 1 * u, y: 1 * u)
                        .frame(width: 290 * u, height: 30 * u)
                        .background(RoundedRectangle(cornerRadius: 4 * u).fill(LinearGradient(colors: [Color.white.opacity(0.1), Color.black.opacity(0.1)], startPoint: .top, endPoint: .bottom)))
                        .background(BumpyBorder(u: u))
                }
                .buttonStyle(PressStyle())
                .padding(5 * u)
            }
            .frame(width: 300 * u)
            .background(Tiled(name: "darkNoise.jpg", scale: u))
            .overlay(FrameBorder(u: u))
            .shadow(color: .black.opacity(0.5), radius: 2 * u)
            .padding(.top, insets.top + 60 * u)
            .padding(.bottom, insets.bottom + 44 * u + 40 * u)
        }
    }
}

/// the original's ".framed" 3px border (frameBorder.png)
struct FrameBorder: View {
    let u: CGFloat
    var body: some View {
        if let img = Sprites.ui("frameBorder.png") {
            Image(uiImage: img)
                .resizable(capInsets: EdgeInsets(top: 3, leading: 3, bottom: 3, trailing: 3), resizingMode: .tile)
                .mask(RoundedRectangle(cornerRadius: 2 * u).strokeBorder(lineWidth: 3 * u))
                .allowsHitTesting(false)
        }
    }
}

/// a popup heading (the original's h3): Fancy small caps on a dark horizontal fade with thin light lines
struct PopupTitle: View {
    let text: String
    var icon: [Int]? = nil
    let u: CGFloat
    var body: some View {
        let fade = LinearGradient(colors: [.clear, Color.black.opacity(0.75), .clear], startPoint: .leading, endPoint: .trailing)
        let line = LinearGradient(colors: [.clear, Color.white.opacity(0.25), .clear], startPoint: .leading, endPoint: .trailing)
        HStack(spacing: 2 * u) {
            if let i = icon { IconView(icon: i, size: 24 * u).padding(.vertical, -6 * u) }
            Text(RichText.plain(text)).font(.fancy(15 * u).lowercaseSmallCaps()).foregroundColor(Color(white: 0.8))
        }
        .padding(.horizontal, 8 * u).padding(.vertical, 4 * u)
        .frame(maxWidth: .infinity)
        .background(fade)
        .overlay(alignment: .top) { line.frame(height: 1).offset(y: -1) }
        .overlay(alignment: .bottom) { line.frame(height: 1).offset(y: 1) }
        .padding(.vertical, 4 * u)
        .padding(.horizontal, -8 * u)
        .shadow(color: .black, radius: 0, x: 1 * u, y: 1 * u)
    }
}


/// the original's <line>: a faint horizontal rule
struct Line: View {
    let u: CGFloat
    var body: some View {
        LinearGradient(colors: [.clear, Color.white.opacity(0.25), .clear], startPoint: .leading, endPoint: .trailing)
            .frame(height: 1).padding(.horizontal, 13 * u).padding(.vertical, 6 * u)
    }
}

/// icon + name header box (the original's ".framed.nameBox": marble, 70 tall, framed)
struct NameBox: View {
    let icon: [Int]?
    var building: Building? = nil
    let name: String
    var sub: String? = nil
    var tag: (String, Color)? = nil
    let u: CGFloat
    var body: some View {
        HStack(spacing: 0) {
            Group {
                if let b = building { BuildingIcon(b: b, mysterious: false, u: u, size: 64) }
                else if let i = icon { IconView(icon: i, size: 48 * u).frame(width: 64 * u, height: 64 * u) }
            }
            .shadow(color: .black.opacity(0.5), radius: 2 * u, x: 3 * u, y: 3 * u)
            VStack(spacing: 1 * u) {
                if let t = tag {
                    Text(t.0).font(.body(9 * u, bold: true)).foregroundColor(.white)
                        .padding(.horizontal, 4 * u).padding(.vertical, 1 * u)
                        .background(RoundedRectangle(cornerRadius: 2 * u).fill(t.1))
                }
                Text(name).font(.fancy(16 * u)).foregroundColor(Color(white: 0.8)).multilineTextAlignment(.center)
                if let s = sub { Text(s).font(.body(10 * u, bold: true)).foregroundColor(Color(white: 0.8)) }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(3 * u)
        .frame(width: 268 * u)
        .frame(minHeight: 70 * u)
        .background(ZStack { Tiled(name: "marbleSolid.jpg", scale: u * 300 / 692); LinearGradient(colors: [.black.opacity(0.1), .black.opacity(0.5)], startPoint: .top, endPoint: .bottom) })
        .overlay(FrameBorder(u: u))
        .shadow(color: .black, radius: 0.5 * u, x: 1 * u, y: 1 * u).shadow(color: .black, radius: 2 * u)
        .padding(.vertical, 4 * u)
    }
}

struct PopupHost: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let kind: PopupKind
    let u: CGFloat
    let insets: EdgeInsets

    func close() { ui.popup = nil }

    func iconGrid(_ items: [([Int], PopupKind, Bool)]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(44 * u), spacing: 0), count: 6), spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, it in
                Button { ui.popup = it.1 } label: { IconView(icon: it.0, size: 44 * u).opacity(it.2 ? 1 : 0.35) }.buttonStyle(.plain)
            }
        }
    }

    var body: some View {
        let _ = game.frame
        switch kind {
        case .building(let id): PopupFrame(u: u, insets: insets, close: close) { BuildingInfo(b: game.buildings[id], u: u) }
        case .upgrade(let id): PopupFrame(u: u, insets: insets, close: close) { UpgradeInfo(up: game.upgradesBID[id]!, u: u) }
        case .achievement(let id): PopupFrame(u: u, insets: insets, close: close) { AchievInfo(a: game.achievsBID[id]!, u: u) }
        case .buff(let id):
            PopupFrame(u: u, insets: insets, close: close) {
                if let b = game.buffs.first(where: { $0.id == id }) {
                    NameBox(icon: b.type.icon, name: b.type.nameD, tag: b.type.type == 2 ? ("Debuff", .red.opacity(0.7)) : ("Buff", .green.opacity(0.6)), u: u)
                    RichText(html: game.buffDesc(b), size: 13 * u, align: .center)
                    Text("\(sayTime(b.t * 1000 + 1000, -1)) left").font(.system(size: 12 * u, weight: .bold)).foregroundColor(.white)
                } else { Text("This buff has run out.").foregroundColor(.white) }
            }
        case .lumps: PopupFrame(u: u, insets: insets, close: close) { LumpsInfo(u: u) }
        case .dragon: PopupFrame(u: u, insets: insets, close: close) { DragonInfo(u: u) }
        case .dragonAura(let slot): PopupFrame(u: u, insets: insets, closeText: "Cancel", close: { ui.popup = .dragon }) { AuraPicker(slot: slot, u: u) }
        case .santa: PopupFrame(u: u, insets: insets, close: close) { SantaInfo(u: u) }
        case .seasons: PopupFrame(u: u, insets: insets, close: close) { SeasonPicker(u: u) }
        case .research: PopupFrame(u: u, insets: insets, close: close) { ResearchInfo(u: u) }
        case .ascend:
            PopupFrame(u: u, insets: insets, closeText: "Cancel", close: close) {
                PopupTitle(text: "Ascend", icon: [19, 7], u: u)
                RichText(html: "Do you REALLY want to ascend?<br><small>You will lose your progress and start over from scratch.<br>All your cookies will be converted into prestige and heavenly chips.<br>You will keep your achievements and heavenly upgrades.</small>", size: 13 * u, align: .center)
                GameButton(text: "Yes!", u: u, size: 16) { ui.popup = nil; ui.tab = .cookie; game.ascend() }
            }
        case .confirmWipe:
            PopupFrame(u: u, insets: insets, closeText: "Cancel", close: close) {
                PopupTitle(text: "Wipe save", u: u)
                RichText(html: "Do you REALLY want to wipe your save?<br><small>You will lose your progress, your achievements, and your heavenly chips!</small>", size: 13 * u, align: .center)
                GameButton(text: "<span style=\"color:#ff5134\">Yes, wipe it</span>", u: u, size: 15) {
                    ui.popup = nil; ui.tab = .cookie
                    game.reset(hard: true); game.save()
                    game.toast("Game reset", "Good luck!", [0, 7])
                }
            }
        case .settings: PopupFrame(u: u, insets: insets, closeText: "Confirm", close: close) { SettingsList(u: u) }
        case .news:
            PopupFrame(u: u, insets: insets, close: close) {
                PopupTitle(text: "News", icon: [27, 7], u: u).onAppear { game.win("Tabloid addiction") }
                if Ticker.shared.saved.isEmpty { Text("(no news on record.)").foregroundColor(.white) }
                ForEach(Array(Ticker.shared.saved.enumerated()), id: \.offset) { _, n in
                    VStack(alignment: .leading, spacing: 1 * u) {
                        Text(Date(timeIntervalSince1970: n.1 / 1000).formatted(date: .omitted, time: .shortened)).font(.system(size: 8 * u, weight: .bold)).foregroundColor(.white.opacity(0.5))
                        RichText(html: n.0, size: 12 * u, font: .fancy(12 * u))
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    Line(u: u)
                }
            }
        case .log:
            PopupFrame(u: u, insets: insets, close: close) {
                PopupTitle(text: "Log", icon: [15, 9], u: u)
                if game.toastLog.isEmpty { Text("(nothing logged yet.)").foregroundColor(.white) }
                ForEach(game.toastLog.reversed()) { t in
                    HStack(spacing: 6 * u) {
                        if let i = t.icon { IconView(icon: i, size: 32 * u) }
                        VStack(alignment: .leading, spacing: 1 * u) {
                            if !t.title.isEmpty { RichText(html: t.title, size: 12 * u, font: .fancy(12 * u)) }
                            if !t.text.isEmpty { RichText(html: t.text, size: 10 * u) }
                        }
                        Spacer()
                    }
                    Line(u: u)
                }
            }
        case .extras: PopupFrame(u: u, insets: insets, close: close) { EmptyView() }
        case .message(let what, _):
            PopupFrame(u: u, insets: insets, close: close) {
                if what == "about" {
                    PopupTitle(text: "About", u: u)
                    RichText(html: "<b>Cookie Clicker</b> is a game by <b>Orteil</b> and <b>Opti</b> (DashNet).<br><br>This version is the mobile game rewritten in Swift for iPhone, with sugar lumps, minigames and extra buildings added.<br><br>Thanks for playing!", size: 11 * u, color: Color(white: 0.8), align: .center)
                } else if what == "versions" {
                    PopupTitle(text: "Version history", u: u)
                    RichText(html: "<b>Swift version</b><br>&bull; the whole game rewritten in Swift<br>&bull; sugar lumps and building levels<br>&bull; Garden, Pantheon, Grimoire and Stock Market<br>&bull; Black hole, Galaxy, Multiverse mixer and Big bang<br>&bull; iCloud backups, QR save transfer, Live Activity, 120 Hz", size: 11 * u, color: Color(white: 0.8))
                } else {
                    CosmeticPicker(milk: what == "milk", u: u)
                }
            }
        case .upgradesList:
            PopupFrame(u: u, insets: insets, close: close) {
                let total = StatsScreen.upgradesTotal(game)
                PopupTitle(text: "Upgrades", u: u)
                Text("Owned: \(B(Double(game.upgradesN)))/\(B(Double(total))) (\(B(Double(game.upgradesN) / Double(max(1, total)) * 100, 1))% of total)").font(.body(11 * u)).opacity(0.75)
                Line(u: u)
                iconGrid(game.upgrades.filter { $0.owned > 0 && !["toggle", "prestige"].contains($0.pool) }.sorted { $0.def.order < $1.def.order }.map { ($0.def.icon, PopupKind.upgrade($0.id), true) })
                let heavenly = game.upgrades.filter { $0.owned > 0 && $0.pool == "prestige" }
                if !heavenly.isEmpty {
                    Line(u: u)
                    Text("Prestige upgrades").font(.body(11 * u, bold: true))
                    iconGrid(heavenly.sorted { $0.def.order < $1.def.order }.map { ($0.def.icon, PopupKind.upgrade($0.id), true) })
                }
            }
        case .achievsList:
            PopupFrame(u: u, insets: insets, close: close) {
                let total = StatsScreen.achievsTotal(game)
                PopupTitle(text: "Achievements", u: u)
                Text("Unlocked: \(B(Double(game.achievsN)))/\(B(Double(total))) (\(B(Double(game.achievsN) / Double(max(1, total)) * 100, 1))% of total)").font(.body(11 * u)).opacity(0.75)
                Line(u: u)
                iconGrid(game.achievs.filter { $0.def.pool != "shadow" }.sorted { $0.def.order < $1.def.order }.map { ($0.owned > 0 ? $0.def.icon : [0, 7], PopupKind.achievement($0.id), $0.owned > 0) })
                let shadow = game.achievs.filter { $0.def.pool == "shadow" && $0.owned > 0 }
                if !shadow.isEmpty {
                    Line(u: u)
                    RichText(html: "<b>Shadow achievements</b><br><small>(These are feats that are either unfair or difficult to attain. They do not give milk.)</small>", size: 11 * u, color: Color(white: 0.8), align: .center)
                    iconGrid(shadow.map { ($0.def.icon, PopupKind.achievement($0.id), true) })
                }
            }
        case .permanentSlot(let i):
            PopupFrame(u: u, insets: insets, close: { ui.popup = nil }) { PermanentSlotPicker(slot: i, u: u) }
        }
    }
}

// MARK: - info popups

struct BuildingInfo: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let b: Building
    let u: CGFloat
    var body: some View {
        let each = b.storedCps
        let all = each * Double(b.amount)
        PopupTitle(text: "Building info", u: u)
        NameBox(icon: b.def.icon, building: b, name: cap(game.buildingName(b, 1)), sub: "Owned: \(B(Double(b.amount)))", u: u)
        Line(u: u)
        VStack(alignment: .leading, spacing: 0) {
            bullet("each \(b.def.single) produces <b>\(B(each, 1))</b> cookie\(B(each, 1) == "1" ? "" : "s") per second")
            bullet("<b>\(B(Double(b.amount))) \(b.amount == 1 ? b.def.single : b.def.plural)</b> producing <b>\(B(all, 1))</b> cookie\(B(all, 1) == "1" ? "" : "s") per second")
            bullet("<b>\(B(b.cookiesMade))</b> cookie\(B(b.cookiesMade) == "1" ? "" : "s") \(b.def.actionName) so far")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        Line(u: u)
        Quote(text: game.buildingDesc(b), u: u)
        if Lumps.canLumps(game) && game.lumpT > 0 { LevelBox(b: b, u: u) }
    }
    func bullet(_ html: String) -> some View {
        RichText(html: "&bull; " + html, size: 11 * u, color: Color(white: 0.8))
            .shadow(color: .black, radius: 0, x: 1 * u, y: 1 * u)
            .frame(minHeight: 19 * u, alignment: .leading)
    }
}

/// the original's <q>: Georgia italic, right-aligned, faded, with big curly quotes
struct Quote: View {
    let text: String
    let u: CGFloat
    var body: some View {
        (Text("\u{201C}").font(.georgia(16 * u, bold: true)) + Text(RichText.plain(text)).font(.georgia(11 * u, italic: true)) + Text("\u{201D}").font(.georgia(16 * u, bold: true)))
            .foregroundColor(Color.white.opacity(0.65))
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .shadow(color: .black, radius: 0, x: 1 * u, y: 1 * u)
    }
}

struct LevelBox: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let b: Building
    let u: CGFloat
    var body: some View {
        let cost = Double(b.level + 1)
        let mg = Minigames.buildingFor[b.def.name]
        Line(u: u)
        VStack(spacing: 4 * u) {
            Text("Level \(b.level)").font(.merri(14 * u)).foregroundColor(.white)
            RichText(html: b.level > 0 ? (b.level == 1 ? b.def.extraName : b.def.extraPlural).replacingOccurrences(of: "[X]", with: B(Double(b.level))) + " granting <b>+\(b.level)% \(b.def.single) CpS</b>." : "Spend sugar lumps to level up this building. Each level gives <b>+1%</b> to its production.", size: 11 * u, align: .center)
            if let m = mg, b.level == 0 { RichText(html: "<b>Levelling up this building unlocks a minigame (\(m)).</b>", size: 11 * u, align: .center) }
            GameButton(text: "Level up for \(B(cost)) sugar lump\(cost == 1 ? "" : "s")", u: u, size: 12, enabled: game.lumps >= cost) {
                _ = Lumps.levelUp(game, b)
            }
            if let m = mg, b.level > 0 {
                GameButton(text: "Open \(m)", u: u, size: 13) { ui.popup = nil; ui.minigame = m; Sound.play("snd/clickOn2.mp3", 0.5) }
            }
            Text("You have \(B(game.lumps)) sugar lump\(game.lumps == 1 ? "" : "s").").font(.system(size: 10 * u)).foregroundColor(.white.opacity(0.6))
        }
    }
}

/// grey label pill (the original's ".tag")
struct TagPill: View {
    let text: String
    let u: CGFloat
    var color: Color = Color(white: 0.8)
    var body: some View {
        Text(text).font(.body(10 * u, bold: true)).foregroundColor(Color(white: 0.1))
            .padding(.horizontal, 3 * u).frame(height: 14 * u)
            .background(RoundedRectangle(cornerRadius: 2 * u).fill(color))
    }
}

struct UpgradeInfo: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let up: Upgrade
    let u: CGFloat
    var tag: String {
        switch up.pool {
        case "prestige": return "Heavenly"
        case "science": return "Research"
        case "cookie": return "Cookie"
        case "toggle": return "Switch"
        default: return "Upgrade"
        }
    }
    var body: some View {
        let cost = game.upgradeCost(up)
        PopupTitle(text: "Upgrade info", u: u)
        NameBox(icon: up.def.icon, name: up.name, u: u)
        Line(u: u)
        HStack(spacing: 2 * u) {
            TagPill(text: tag, u: u, color: up.pool == "prestige" ? Color(hex: "efa438") : Color(white: 0.8))
            TagPill(text: up.owned > 0 ? "Purchased" : (up.unlocked > 0 || up.pool == "prestige" ? "Not yet purchased" : "Locked"), u: u)
        }
        if up.owned == 0 {
            HStack(spacing: 2 * u) {
                Text("Cost:").font(.body(10 * u, bold: true))
                if up.pool == "prestige" {
                    Text("\(B(cost)) heavenly chip\(cost == 1 ? "" : "s")").font(.body(11 * u, bold: true)).foregroundColor(Color(hex: "efa438"))
                } else {
                    CostText(cost: cost, can: game.cookies >= cost, u: u)
                }
            }
            .shadow(color: .black, radius: 0, x: 1 * u, y: 1 * u)
        }
        Line(u: u)
        RichText(html: game.upgradeDesc(up), size: 11 * u, color: Color(white: 0.8))
            .shadow(color: .black, radius: 0, x: 1 * u, y: 1 * u)
            .frame(maxWidth: .infinity, alignment: .leading)
        if !up.def.q.isEmpty { Line(u: u); Quote(text: up.def.q, u: u) }
        if up.pool == "prestige" && up.owned == 0 && game.onAscend == 1 {
            let parentsOK = (game.data.heavenlyParents[up.id] ?? []).filter { $0 != -1 }.allSatisfy { game.upgradesBID[$0]?.owned ?? 0 > 0 }
            GameButton(text: "Buy", u: u, size: 15, enabled: game.heavenlyChips >= cost && parentsOK) { if game.buyUpgrade(up) { ui.popup = nil } }
        }
    }
}

struct AchievInfo: View {
    @EnvironmentObject var game: Game
    let a: Achiev
    let u: CGFloat
    var body: some View {
        let hidden = a.owned == 0 && a.def.pool == "shadow"
        PopupTitle(text: "Achievement info", u: u)
        NameBox(icon: a.owned > 0 ? a.def.icon : [0, 7], name: hidden ? "???" : a.name, u: u)
        Line(u: u)
        HStack(spacing: 2 * u) {
            TagPill(text: a.def.pool == "shadow" ? "Shadow achievement" : "Achievement", u: u, color: a.def.pool == "shadow" ? Color(hex: "9a7bff") : Color(white: 0.8))
            TagPill(text: a.owned > 0 ? "Unlocked" : "Locked", u: u)
        }
        Line(u: u)
        RichText(html: hidden ? "???" : a.def.desc, size: 11 * u, color: Color(white: 0.8))
            .shadow(color: .black, radius: 0, x: 1 * u, y: 1 * u)
            .frame(maxWidth: .infinity, alignment: .leading)
        if a.owned > 0 && !a.def.q.isEmpty { Line(u: u); Quote(text: a.def.q, u: u) }
    }
}

struct LumpsInfo: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let u: CGFloat
    var body: some View {
        let age = now() - game.lumpT
        let mature = age >= Lumps.matureAge, ripe = age >= Lumps.ripeAge
        let ic = Lumps.icons(game)
        PopupTitle(text: "Sugar lumps", u: u)
        IconView(icon: ic.b, size: 72 * u)
        RichText(html: "You have <b>\(B(game.lumps)) sugar lump\(game.lumps == 1 ? "" : "s")</b>.", size: 13 * u, align: .center)
        Group {
            if !mature { RichText(html: "This sugar lump is still growing and will be <b>mature</b> in <b>\(sayTime(Lumps.matureAge - age, -1))</b>, <b>ripe</b> in <b>\(sayTime(Lumps.ripeAge - age, -1))</b> and will <b>fall</b> in <b>\(sayTime(Lumps.overripeAge - age, -1))</b>.", size: 12 * u, align: .center) }
            else if !ripe { RichText(html: "This sugar lump is <b>mature</b> and will be <b>ripe</b> in <b>\(sayTime(Lumps.ripeAge - age, -1))</b>. Harvesting it now has a <b>50% chance</b> of working. It will fall on its own in <b>\(sayTime(Lumps.overripeAge - age, -1))</b>.", size: 12 * u, align: .center) }
            else { RichText(html: "This sugar lump is <b>ripe</b>! Harvest it now, or it will fall on its own in <b>\(sayTime(Lumps.overripeAge - age, -1))</b>.", size: 12 * u, align: .center) }
        }
        let typeText = ["", "This sugar lump grew to be <b>bifurcated</b>; harvesting it has a 50% chance of yielding two lumps.",
                        "This sugar lump grew to be <b>golden</b>; harvesting it will yield 2 to 7 lumps and double your cookies (up to a day's worth).",
                        "This sugar lump was affected by the elders and grew to be <b>meaty</b>; harvesting it will yield between 0 and 2 lumps.",
                        "This sugar lump is <b>caramelized</b>, its stickiness binding it to unexpected things; harvesting it will yield between 1 and 3 lumps."][safe: game.lumpCurrentType] ?? ""
        if !typeText.isEmpty { RichText(html: typeText, size: 12 * u, align: .center) }
        if mature { GameButton(text: "Harvest", u: u, size: 15) { ui.popup = nil; Lumps.harvestNow(game) } }
        Line(u: u)
        RichText(html: "&bull; Sugar lumps can be harvested when mature; left alone they ripen (harvest is then guaranteed) and eventually fall and are harvested automatically.<br>&bull; Spend them to <b>level up buildings</b> from each building's info screen in the Store: every level gives <b>+1%</b> to that building's production. Levelling up Farms, Banks, Temples and Wizard towers unlocks their <b>minigames</b>.<br>&bull; Sugar lumps keep growing while the game is closed.", size: 11 * u, color: .white.opacity(0.75))
    }
}

struct DragonInfo: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let u: CGFloat
    var body: some View {
        let lvl = Dragon.levels[game.dragonLevel]
        PopupTitle(text: "Krumblor", u: u)
        SheetCell(sheet: "dragon.png", x: lvl.pic, y: 0, w: 96, h: 96, width: 96 * u, height: 96 * u)
        Text(lvl.name).font(.fancy(15 * u)).foregroundColor(.white)
        if game.dragonLevel >= 5 {
            HStack(spacing: 12 * u) {
                auraSlot(0)
                if game.dragonLevel >= Dragon.levels.count - 1 { auraSlot(1) }
            }
        }
        if game.dragonLevel < Dragon.levels.count - 1 {
            Line(u: u)
            let c = Dragon.cost(game, game.dragonLevel)
            RichText(html: lvl.action, size: 12 * u, align: .center)
            RichText(html: "Cost: <b>\(c.0)</b>", size: 11 * u, align: .center)
            GameButton(text: "Do it", u: u, size: 14, enabled: c.1) { Dragon.upgrade(game) }
        }
    }
    func auraSlot(_ slot: Int) -> some View {
        let a = Dragon.auras[safe: slot == 0 ? game.dragonAura : game.dragonAura2] ?? Dragon.auras[0]
        return Button { ui.popup = .dragonAura(slot) } label: {
            VStack(spacing: 2 * u) {
                IconView(icon: a.pic, size: 48 * u)
                Text(a.name).font(.system(size: 10 * u, weight: .bold)).foregroundColor(.white)
                RichText(html: a.desc, size: 9 * u, color: .white.opacity(0.8), align: .center).frame(maxWidth: 130 * u)
            }
        }.buttonStyle(.plain)
    }
}

struct AuraPicker: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let slot: Int
    let u: CGFloat
    var body: some View {
        let current = slot == 0 ? game.dragonAura : game.dragonAura2
        let highest = game.buildings.last(where: { $0.amount > 0 })
        PopupTitle(text: slot == 0 ? "Set your dragon's aura" : "Set your dragon's secondary aura", u: u)
        RichText(html: "Select an aura from those your dragon knows.<br>" + (highest == nil ? "Switching your aura is <b>free</b> because you own no buildings." : "The cost of switching your aura is <b>1 \(highest!.def.single)</b>.<br><b>This will affect your CpS!</b>"), size: 11 * u, align: .center)
        ForEach(Dragon.choices(game, slot: slot), id: \.id) { a in
            Button { Dragon.select(game, slot: slot, aura: a.id); ui.popup = .dragon } label: {
                HStack(spacing: 6 * u) {
                    IconView(icon: a.pic, size: 40 * u)
                    VStack(alignment: .leading) {
                        Text(a.name).font(.fancy(13 * u)).foregroundColor(.white)
                        RichText(html: a.desc, size: 10 * u)
                    }
                    Spacer()
                }
                .padding(4 * u)
                .background(RoundedRectangle(cornerRadius: 4 * u).fill(a.id == current ? Color.purple.opacity(0.3) : Color.white.opacity(0.06)))
            }.buttonStyle(.plain)
        }
    }
}

struct SantaInfo: View {
    @EnvironmentObject var game: Game
    let u: CGFloat
    var body: some View {
        PopupTitle(text: "Santa", u: u)
        SheetCell(sheet: "santa.png", x: game.santaLevel, y: 0, w: 96, h: 96, width: 96 * u, height: 96 * u)
        Text(Santa.levels[game.santaLevel]).font(.fancy(15 * u)).foregroundColor(.white)
        if game.santaLevel < 14 {
            let c = Santa.cost(game)
            RichText(html: "Evolve for <b>\(B(c))</b> cookies.", size: 12 * u, align: .center)
            GameButton(text: "Evolve", u: u, size: 14, enabled: game.cookies >= c) { Santa.upgrade(game) }
        } else {
            Text("Santa is fully grown.").font(.system(size: 12 * u)).foregroundColor(.white)
        }
    }
}

struct SeasonPicker: View {
    @EnvironmentObject var game: Game
    let u: CGFloat
    var body: some View {
        PopupTitle(text: "Season switcher", icon: [16, 6], u: u)
        RichText(html: "Change seasons at any time... for a price!<br>Each triggered season lasts for 24 hours.<br>Cost scales with unbuffed CpS and increases with every season switch. " + (game.seasonUses == 0 ? "You haven't switched seasons this ascension yet." : "You've switched seasons <b>\(game.seasonUses == 1 ? "once" : game.seasonUses == 2 ? "twice" : "\(B(game.seasonUses)) times")</b> this ascension.") + " Cancelling out of a season is free.", size: 11 * u, align: .center)
        ForEach(Seasons.list, id: \.key) { s in
            let up = game.upgradesBN[s.trigger]
            let active = game.seasonT > 0 && game.season == s.key
            let cost = Seasons.triggerCost(game)
            Button {
                if active { Seasons.switchSeason(game, nil); Sound.play("snd/thud.mp3", 0.5) }
                else if cost <= game.cookies {
                    Seasons.switchSeason(game, nil)
                    Seasons.switchSeason(game, s.key)
                    game.seasonUses += 1
                    game.spend(cost)
                    Sound.play("snd/thud.mp3", 0.5)
                }
                game.refreshCps = true
                game.doUnlocks()
            } label: {
                HStack(spacing: 6 * u) {
                    IconView(icon: up?.def.icon ?? [0, 0], size: 40 * u)
                    VStack(alignment: .leading, spacing: 2 * u) {
                        Text(s.trigger).font(.fancy(13 * u)).foregroundColor(.white)
                        RichText(html: up?.def.desc ?? "", size: 10 * u)
                        if active { Text("Active! Tap to cancel.").font(.system(size: 10 * u, weight: .bold)).foregroundColor(.white) }
                        else { HStack(spacing: 2 * u) { Text("Trigger for").font(.system(size: 10 * u, weight: .bold)).foregroundColor(.white); CostText(cost: cost, can: cost <= game.cookies, u: u) } }
                    }
                    Spacer()
                }
                .padding(6 * u)
                .background(RoundedRectangle(cornerRadius: 4 * u).fill(active ? Color(red: 0.65, green: 0.04, blue: 0.98).opacity(0.25) : Color(red: 0.69, green: 0.43, blue: 0.29).opacity(0.18)))
            }.buttonStyle(.plain)
        }
    }
}

struct ResearchInfo: View {
    @EnvironmentObject var game: Game
    let u: CGFloat
    var body: some View {
        let pool = game.upgradePools["science"] ?? []
        let list = pool.filter { $0.unlocked > 0 && $0.owned == 0 && $0 !== game.researchUpgrade }.sorted { game.upgradeCost($0) < game.upgradeCost($1) }
        let owned = pool.filter { $0.owned > 0 }
        PopupTitle(text: "Bingo center/Research facility", icon: [11, 9], u: u)
        RichText(html: "Research technologies to boost your cookie production.", size: 11 * u, align: .center)
        Line(u: u)
        Text("Current research:" + (game.researchUpgrade == nil ? " None" : "")).font(.system(size: 11 * u, weight: .bold)).foregroundColor(.white)
        if let r = game.researchUpgrade { row(r, current: true) }
        Line(u: u)
        Text("Available to research:" + (list.isEmpty ? " None" : "")).font(.system(size: 11 * u, weight: .bold)).foregroundColor(.white)
        ForEach(list, id: \.id) { row($0, current: false) }
        Line(u: u)
        Text("Completed research:" + (owned.isEmpty ? " None" : "")).font(.system(size: 11 * u, weight: .bold)).foregroundColor(.white)
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(36 * u)), count: 7)) {
            ForEach(owned, id: \.id) { IconView(icon: $0.def.icon, size: 36 * u) }
        }
    }
    func row(_ r: Upgrade, current: Bool) -> some View {
        Button {
            if current { Research.complete(game) } else { Research.start(game, r) }
        } label: {
            HStack(spacing: 6 * u) {
                IconView(icon: r.def.icon, size: 40 * u)
                VStack(alignment: .leading, spacing: 2 * u) {
                    Text(r.name).font(.fancy(13 * u)).foregroundColor(.white)
                    RichText(html: r.def.desc, size: 10 * u)
                    if current {
                        let left = Research.left(game)
                        Text(left > 0 ? "Time left: " + sayTime(left + 1000) : "Research complete. Tap to unlock!").font(.system(size: 10 * u, weight: .bold)).foregroundColor(.white)
                    } else {
                        HStack(spacing: 2 * u) {
                            Text("Research cost:").font(.system(size: 10 * u)).foregroundColor(.white)
                            CostText(cost: game.upgradeCost(r), can: game.upgradeCost(r) <= game.cookies, u: u)
                        }
                        Text("Research time: " + sayTime(Research.time(game))).font(.system(size: 10 * u)).foregroundColor(.white)
                    }
                }
                Spacer()
            }
            .padding(6 * u)
            .background(RoundedRectangle(cornerRadius: 4 * u).fill(current ? Color.green.opacity(0.2) : Color.white.opacity(0.06)))
        }.buttonStyle(.plain)
    }
}

struct SettingsList: View {
    @EnvironmentObject var game: Game
    let u: CGFloat
    let items: [(String, String, String)] = [
        ("sound", "Sound", "Enable or disable all sound effects."),
        ("fancy", "Fancy graphics", "Animations and other visual effects.<br>Disabling may improve performance."),
        ("particles", "Particles", "Cookies falling down, numbers popping up..."),
        ("cookiepops", "Cookie pops", "Little cookie bits when you tap the big cookie."),
        ("cookiewobble", "Cookie wobble", "Makes the big cookie wobble at your touch.<br>Requires fancy graphics to be on."),
        ("cursors", "Cursors", "Show cursors circling the big cookie."),
        ("milk", "Milk", "Show the milk under the big cookie."),
        ("lowMotion", "Reduce motion", "Fewer moving things on screen."),
        ("notScary", "Scary stuff", "<b>ON</b> hides scary grandmas and wrinkler faces (\"not scary\" mode)."),
    ]
    var body: some View {
        PopupTitle(text: "Settings", icon: [16, 5], u: u)
        ForEach(items, id: \.0) { it in
            let on = game.settings[it.0]
            Button {
                game.settings[it.0] = !on
                Sound.play(on ? "snd/clickOff2.mp3" : "snd/clickOn2.mp3", 0.5)
                game.frame &+= 1
            } label: {
                VStack(spacing: 1 * u) {
                    HStack {
                        Text(it.1).font(.fancy(13 * u)).foregroundColor(.white)
                        Spacer()
                        Text(on ? "ON" : "OFF").font(.fancy(13 * u)).foregroundColor(on ? .costGreen : Color(white: 0.6))
                    }
                    RichText(html: it.2, size: 10 * u, color: .white.opacity(0.75), align: .center)
                }
                .padding(6 * u)
                .background(RoundedRectangle(cornerRadius: 4 * u).fill(Color(white: 0.3).opacity(0.6)))
            }.buttonStyle(.plain)
        }
        VStack(spacing: 4 * u) {
            Text("Volume: \(game.settings.volume)%").font(.system(size: 11 * u, weight: .bold)).foregroundColor(.white)
            Slider(value: Binding(get: { Double(game.settings.volume) }, set: { game.settings.volume = Int($0); game.frame &+= 1 }), in: 0...100, step: 5)
        }
        VStack(spacing: 4 * u) {
            Text("Number format").font(.system(size: 11 * u, weight: .bold)).foregroundColor(.white)
            Picker("", selection: Binding(get: { Fmt.format }, set: { Fmt.format = $0; UserDefaults.standard.set($0, forKey: "numberFormat"); game.frame &+= 1 })) {
                Text("Short (1.5M)").tag(0); Text("Long (1.5 million)").tag(1); Text("Full").tag(2)
            }.pickerStyle(.segmented)
        }
    }
}

struct CosmeticPicker: View {
    @EnvironmentObject var game: Game
    let milk: Bool
    let u: CGFloat
    var body: some View {
        PopupTitle(text: milk ? "Milk selector" : "Background selector", u: u)
        let items: [(Int, Cosmetic)] = milk
            ? Cosmetics.allMilks.enumerated().filter { $0.element.type != 1 || game.Has("Fanciful dairy selection") }.map { ($0.offset, $0.element) }
            : Cosmetics.bgs.enumerated().filter { $0.offset < 13 || game.Has("Distinguished wallpaper assortment") }.map { ($0.offset, $0.element) }
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(48 * u)), count: 5), spacing: 6 * u) {
            ForEach(items, id: \.0) { i, c in
                Button {
                    if milk { game.milkType = i } else { game.bgType = i }
                    Sound.play("snd/tick.mp3", 0.5)
                    game.frame &+= 1
                } label: {
                    IconView(icon: c.icon, size: 44 * u)
                        .overlay(RoundedRectangle(cornerRadius: 4 * u).stroke((milk ? game.milkType : game.bgType) == i ? Color.yellow : .clear, lineWidth: 2))
                }.buttonStyle(.plain)
            }
        }
        Text((milk ? Cosmetics.allMilks[safe: game.milkType]?.name : Cosmetics.bgs[safe: game.bgType]?.name) ?? "").font(.fancy(13 * u)).foregroundColor(.white)
    }
}

struct PermanentSlotPicker: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let slot: Int
    let u: CGFloat
    var body: some View {
        PopupTitle(text: "Permanent upgrade slot \(Cosmetics.romanize(slot + 1))", u: u)
        RichText(html: "Pick an upgrade you purchased this run. When you reincarnate, it will be active <b>permanently</b>, across every playthrough.", size: 11 * u, align: .center)
        let list = game.upgrades.filter { $0.owned > 0 && !["toggle", "prestige", "science"].contains($0.pool) && ($0.pool != "cookie" || slot >= 0) }
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(40 * u)), count: 7), spacing: 4 * u) {
            ForEach(list, id: \.id) { up in
                Button {
                    game.permanentUpgrades[slot] = up.id
                    Sound.play("snd/tick.mp3", 0.5)
                    ui.popup = nil
                } label: {
                    IconView(icon: up.def.icon, size: 40 * u)
                        .overlay(RoundedRectangle(cornerRadius: 4 * u).stroke(game.permanentUpgrades[slot] == up.id ? Color.yellow : .clear, lineWidth: 2))
                }.buttonStyle(.plain)
            }
        }
        GameButton(text: "Clear slot", u: u, size: 12) { game.permanentUpgrades[slot] = -1; ui.popup = nil }
    }
}
