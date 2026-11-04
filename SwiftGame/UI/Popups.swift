import SwiftUI

/// The game's popup window: dark textured panel with a close button at the bottom.
struct PopupFrame<Content: View>: View {
    let u: CGFloat
    let insets: EdgeInsets
    var closeText = "Close"
    let close: () -> Void
    @ViewBuilder var content: () -> Content
    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea().onTapGesture(perform: close)
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 6 * u) { content() }
                        .padding(.horizontal, 12 * u).padding(.vertical, 10 * u)
                        .frame(maxWidth: .infinity)
                }
                Button(action: { Sound.play("snd/tickOff.mp3", 0.5); close() }) {
                    Text(closeText).font(.fancy(14 * u)).foregroundColor(.white).gameShadow()
                        .frame(maxWidth: .infinity).padding(8 * u)
                        .background(LinearGradient(colors: [Color.white.opacity(0.1), Color.black.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                }.buttonStyle(PressStyle())
            }
            .background(Tiled(name: "darkNoise.jpg", scale: u))
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color(hex: "a07b4e"), lineWidth: 2 * u))
            .shadow(color: .black.opacity(0.7), radius: 6 * u)
            .padding(.top, insets.top + 60 * u)
            .padding(.bottom, insets.bottom + 44 * u)
            .padding(.horizontal, 10 * u)
        }
    }
}

struct PopupTitle: View {
    let text: String
    var icon: [Int]? = nil
    let u: CGFloat
    var body: some View {
        HStack(spacing: 4 * u) {
            if let i = icon { IconView(icon: i, size: 24 * u) }
            RichText(html: text, size: 16 * u, font: .merri(15 * u), align: .center)
        }
        .frame(maxWidth: .infinity)
        .gameShadow()
    }
}

struct Line: View {
    let u: CGFloat
    var body: some View { Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1).padding(.vertical, 2 * u) }
}

/// icon + name header box (marble), like the original's info popups
struct NameBox: View {
    let icon: [Int]?
    var building: Building? = nil
    let name: String
    var tag: (String, Color)? = nil
    let u: CGFloat
    var body: some View {
        HStack(spacing: 6 * u) {
            if let b = building { BuildingIcon(b: b, mysterious: false, u: u) }
            else if let i = icon { IconView(icon: i, size: 48 * u) }
            VStack(alignment: .leading, spacing: 2 * u) {
                Text(name).font(.fancy(17 * u)).foregroundColor(.white).gameShadow()
                if let t = tag {
                    Text(t.0).font(.system(size: 10 * u, weight: .bold)).foregroundColor(.white)
                        .padding(.horizontal, 5 * u).padding(.vertical, 1 * u)
                        .background(RoundedRectangle(cornerRadius: 3 * u).fill(t.1))
                }
            }
            Spacer()
        }
        .padding(8 * u)
        .frame(minHeight: 64 * u)
        .background(ZStack { Tiled(name: "marbleSolid.jpg", scale: u); LinearGradient(colors: [.black.opacity(0.1), .black.opacity(0.5)], startPoint: .top, endPoint: .bottom) })
        .overlay(Rectangle().stroke(Color(hex: "a07b4e"), lineWidth: 2 * u))
    }
}

struct PopupHost: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let kind: PopupKind
    let u: CGFloat
    let insets: EdgeInsets

    func close() { ui.popup = nil }

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
            PopupFrame(u: u, insets: insets, close: close) { CosmeticPicker(milk: what == "milk", u: u) }
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
        let total = game.cookiesPs
        let each = b.storedCps
        let all = each * Double(b.amount)
        PopupTitle(text: "Building info", u: u)
        NameBox(icon: b.def.icon, building: b, name: "\(b.amount) \(cap(game.buildingName(b, b.amount)))", u: u)
        RichText(html: game.buildingDesc(b), size: 12 * u, align: .center)
        Line(u: u)
        VStack(alignment: .leading, spacing: 3 * u) {
            RichText(html: "&bull; Each \(b.def.single) produces <b>\(B(each, 1))</b> cookie\(B(each, 1) == "1" ? "" : "s") per second", size: 11 * u)
            RichText(html: "&bull; \(b.amount) \(b.amount == 1 ? b.def.single : b.def.plural) producing <b>\(B(all, 1))</b> cookie\(B(all, 1) == "1" ? "" : "s") per second (<b>\(B(total > 0 ? all / total * 100 : 0, 1))%</b> of total CpS)", size: 11 * u)
            RichText(html: "&bull; <b>\(B(b.cookiesMade))</b> cookie\(B(b.cookiesMade) == "1" ? "" : "s") \(b.def.actionName) so far", size: 11 * u)
            RichText(html: "&bull; Next one costs <b>\(B(game.cost(b)))</b>", size: 11 * u)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        if Lumps.canLumps(game) && game.lumpT > 0 { LevelBox(b: b, u: u) }
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

struct UpgradeInfo: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let up: Upgrade
    let u: CGFloat
    var tag: (String, Color) {
        switch up.pool {
        case "prestige": return ("Heavenly", Color(hex: "efa438"))
        case "science": return ("Tech", Color(hex: "36a4ff"))
        case "cookie": return ("Cookie", Color(white: 0.4))
        case "toggle": return ("Switch", Color(white: 0.4))
        default: return ("Upgrade", Color(white: 0.4))
        }
    }
    var body: some View {
        PopupTitle(text: "Upgrade info", u: u)
        NameBox(icon: up.def.icon, name: up.name, tag: tag, u: u)
        RichText(html: game.upgradeDesc(up), size: 12 * u, align: .center)
        if !up.def.q.isEmpty { RichText(html: "<q>" + up.def.q + "</q>", size: 11 * u, align: .center) }
        Line(u: u)
        if up.owned > 0 {
            Text(up.pool == "toggle" ? "Active." : "Purchased.").font(.system(size: 12 * u, weight: .bold)).foregroundColor(.costGreen)
        } else if up.pool == "prestige" {
            let can = game.heavenlyChips >= game.upgradeCost(up)
            RichText(html: "Costs <b>\(B(game.upgradeCost(up)))</b> heavenly chip\(game.upgradeCost(up) == 1 ? "" : "s").", size: 12 * u, align: .center)
            if game.onAscend == 1 {
                let parentsOK = (game.data.heavenlyParents[up.id] ?? []).allSatisfy { game.upgradesBID[$0]?.owned ?? 0 > 0 }
                GameButton(text: "Buy", u: u, size: 15, enabled: can && parentsOK) { if game.buyUpgrade(up) { ui.popup = nil } }
            }
        } else if up.unlocked > 0 && !["science"].contains(up.pool) {
            let cost = game.upgradeCost(up)
            CostText(cost: cost, can: game.cookies >= cost, u: u).scaleEffect(1.3)
            GameButton(text: "Buy", u: u, size: 15, enabled: game.cookies >= cost) { if game.buyUpgrade(up) { Sound.play("snd/buy\(Int.random(in: 1...4)).mp3", 0.75); ui.popup = nil } }
        } else {
            Text("Locked.").font(.system(size: 12 * u, weight: .bold)).foregroundColor(.white.opacity(0.6))
        }
    }
}

struct AchievInfo: View {
    @EnvironmentObject var game: Game
    let a: Achiev
    let u: CGFloat
    var body: some View {
        PopupTitle(text: "Achievement info", u: u)
        NameBox(icon: a.owned > 0 ? a.def.icon : [0, 7], name: a.owned > 0 || a.def.pool != "shadow" ? a.name : "???", tag: a.def.pool == "shadow" ? ("Shadow achievement", .purple.opacity(0.7)) : nil, u: u)
        RichText(html: a.def.desc, size: 12 * u, align: .center)
        if a.owned > 0 && !a.def.q.isEmpty { RichText(html: "<q>" + a.def.q + "</q>", size: 11 * u, align: .center) }
        Line(u: u)
        Text(a.owned > 0 ? "Unlocked." : "Locked.").font(.system(size: 12 * u, weight: .bold)).foregroundColor(a.owned > 0 ? .costGreen : .white.opacity(0.6))
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
