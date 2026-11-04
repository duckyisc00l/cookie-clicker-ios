import SwiftUI
import UniformTypeIdentifiers

struct StatsScreen: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let u: CGFloat
    @State private var showUpgrades = false
    @State private var showAchievs = false

    var upgradesTotal: Int { game.upgrades.filter { !["toggle", "prestige"].contains($0.pool) && !$0.def.unimplemented }.count }
    var achievsTotal: Int { game.achievs.filter { $0.def.pool != "shadow" && !$0.def.unimplemented }.count }

    var body: some View {
        let _ = game.frame
        ScrollView {
            VStack(spacing: 6 * u) {
                ScreenTitle(text: "Stats", u: u)
                HStack(alignment: .top, spacing: 6 * u) {
                    VStack(alignment: .leading, spacing: 2 * u) { stats }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    VStack(spacing: 6 * u) {
                        sideButton([15, 9], "Log") { ui.popup = .log }
                        sideButton([27, 7], "News") { ui.popup = .news }
                    }
                }
                .padding(8 * u)
                .background(RoundedRectangle(cornerRadius: 4 * u).fill(Color.black.opacity(0.35)))

                header("Upgrades owned: <b>\(B(Double(game.upgradesN)))/\(B(Double(upgradesTotal)))</b> (\(B(Double(game.upgradesN) / Double(max(1, upgradesTotal)) * 100, 1))%)")
                iconGrid(game.upgrades.filter { $0.owned > 0 && !["toggle", "prestige"].contains($0.pool) }.sorted { $0.def.order < $1.def.order }.map { ($0.def.icon, PopupKind.upgrade($0.id)) })
                let prestigeOwned = game.upgrades.filter { $0.owned > 0 && $0.pool == "prestige" }
                if !prestigeOwned.isEmpty {
                    header("Heavenly upgrades: <b>\(prestigeOwned.count)</b>")
                    iconGrid(prestigeOwned.sorted { $0.def.order < $1.def.order }.map { ($0.def.icon, PopupKind.upgrade($0.id)) })
                }
                header("Achievements unlocked: <b>\(B(Double(game.achievsN)))/\(B(Double(achievsTotal)))</b> (\(B(Double(game.achievsN) / Double(max(1, achievsTotal)) * 100, 1))%)")
                let rank = min(Cosmetics.milks.count - 1, game.achievsN / 25)
                HStack(spacing: 4 * u) {
                    IconView(icon: Cosmetics.milks[rank].icon, size: 24 * u)
                    RichText(html: "Milk: <b>\(Cosmetics.milkRankName(rank))</b> (\(B(Double(game.achievsN) * 4))% kitten power)", size: 11 * u)
                }
                achievGrid
            }
            .padding(.horizontal, 6 * u)
            .padding(.bottom, 12 * u)
        }
    }

    @ViewBuilder var stats: some View {
        let g = game
        line(g.resets > 0 ? "Legacy started: <b>\(sayTime(now() - g.gameStart)) ago</b><br><small>with \(B(g.resets)) ascension\(g.resets == 1 ? "" : "s")</small>" : nil)
        line("Run started: <b>\(sayTime(now() - g.runStart)) ago</b>")
        line("Cookies in bank: <b>\(Fmt.B(g.cookies, 0, 2))</b>")
        if g.cookies >= 1000 { sub("...or <b>\(Fmt.B(g.cookies, 0, 1))</b>") }
        line("Cookies baked: <b>\(Fmt.B(g.cookiesEarned, 0, 2))</b>")
        if g.cookiesEarned >= 1000 { sub("...or <b>\(Fmt.B(g.cookiesEarned, 0, 1))</b>") }
        if g.resets > 0 { line("Cookies baked (all time): <b>\(Fmt.B(g.cookiesEarned + g.cookiesReset, 0, 1))</b>") }
        line("Cookies per second (CpS): <b>\(Fmt.B(g.cookiesPs, 1, 2))</b>")
        if g.cookiesPs >= 1000 { sub("...or <b>\(Fmt.B(g.cookiesPs, 1, 1))</b>/s") }
        let m = g.p("cpsM") * 100 - 100
        line("CpS multiplier: <b>\(m >= 0 ? "+" : "")\(Fmt.B(m, 1, 1))%</b>")
        if g.p("cpsBuffM") != 1 { let b = g.p("cpsBuffM") * 100 - 100; sub("...plus from buffs: <b>\(b >= 0 ? "+" : "")\(Fmt.B(b, 1, 1))%</b>") }
        if g.prestige > 0 { sub("...plus from prestige: <b>+\(B(g.prestige * g.heavenlyMultiplier(), 1))%</b>") }
        if g.cpsSucked > 0 { line("<span style=\"color:#ff5134\">CpS withered by wrinklers: <b>\(Fmt.B(g.cpsSucked * 100, 1, 1))%</b> of total</span>") }
        if g.wrinklersPopped > 0 { line("Wrinklers popped: <b>\(B(g.wrinklersPopped))</b>") }
        line("Cookie taps: <b>\(Fmt.B(g.cookieClicks, 0, 1))</b>")
        line("Cookies per tap: <b>\(Fmt.B(g.cookiesPc, 0, 1))</b>")
        line("Hand-made cookies: <b>\(Fmt.B(g.cookiesHandmade, 0, 1))</b>")
        line("Golden cookie clicks: <b>\(Fmt.B(g.gcClicksTotal, 0, 1))</b>")
        if g.reindeerClicks > 0 { line("Reindeer clicks: <b>\(Fmt.B(g.reindeerClicks, 0, 1))</b>") }
        line("Buildings owned: <b>\(B(Double(g.buildingsN)))</b>")
        if g.lumpsTotal > 0 { line("Sugar lumps harvested: <b>\(B(g.lumpsTotal))</b>") }
    }

    @ViewBuilder func line(_ s: String?) -> some View { if let s = s { RichText(html: s, size: 12 * u) } }
    func sub(_ s: String) -> some View { RichText(html: s, size: 9.5 * u, color: .white.opacity(0.75)).padding(.leading, 14 * u) }

    func sideButton(_ icon: [Int], _ text: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2 * u) {
                IconView(icon: icon, size: 40 * u)
                Text(text).font(.fancy(11 * u)).foregroundColor(.white).gameShadow()
            }
            .frame(width: 64 * u).padding(.vertical, 6 * u)
            .background(RoundedRectangle(cornerRadius: 4 * u).fill(LinearGradient(colors: [Color.white.opacity(0.12), .black.opacity(0.2)], startPoint: .top, endPoint: .bottom)))
            .overlay(RoundedRectangle(cornerRadius: 4 * u).stroke(Color.black, lineWidth: 1))
        }.buttonStyle(PressStyle())
    }

    func header(_ s: String) -> some View {
        RichText(html: s, size: 12 * u, font: .fancy(12 * u), align: .center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4 * u)
            .background(Tiled(name: "woodPanels.png", scale: u).opacity(0.9))
            .gameShadow()
    }

    func iconGrid(_ items: [([Int], PopupKind)]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(36 * u), spacing: 2 * u), count: 8), spacing: 2 * u) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Button { ui.popup = item.1 } label: { IconView(icon: item.0, size: 36 * u) }.buttonStyle(.plain)
            }
        }
    }

    var achievGrid: some View {
        let normal = game.achievs.filter { $0.def.pool != "shadow" }.sorted { $0.def.order < $1.def.order }
        let shadow = game.achievs.filter { $0.def.pool == "shadow" && $0.owned > 0 }
        return VStack(spacing: 4 * u) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(36 * u), spacing: 2 * u), count: 8), spacing: 2 * u) {
                ForEach(normal, id: \.id) { a in
                    Button { ui.popup = .achievement(a.id) } label: {
                        Group {
                            if a.owned > 0 { IconView(icon: a.def.icon, size: 36 * u) }
                            else { IconView(icon: [0, 7], size: 36 * u).opacity(0.35) }
                        }
                    }.buttonStyle(.plain)
                }
            }
            if !shadow.isEmpty {
                RichText(html: "<b>Shadow achievements</b><br><small>(These are feats that are either unfair or difficult to attain. They do not give milk.)</small>", size: 11 * u, align: .center)
                iconGrid(shadow.map { ($0.def.icon, PopupKind.achievement($0.id)) })
            }
        }
    }
}

struct MiscScreen: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let u: CGFloat
    @State private var showExtras = false
    @State private var exporting: URL? = nil
    @State private var importing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 6 * u) {
                ScreenTitle(text: "Misc", u: u)
                HStack(alignment: .top, spacing: 6 * u) {
                    Sprites.image("orteil.png").resizable().scaledToFit().frame(width: 60 * u)
                    RichText(html: "<b>Cookie Clicker</b>, rewritten in Swift for iPhone.<br><small>Original game by Orteil &amp; Opti (DashNet).</small>", size: 11 * u)
                        .padding(8 * u)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 4 * u).fill(Color(hex: "4a1d14").opacity(0.9)))
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 4 * u), GridItem(.flexible())], spacing: 4 * u) {
                    bigButton("Settings", [16, 5]) { ui.popup = .settings }
                    bigButton("iPhone extras", [19, 3]) { showExtras = true }
                    bigButton("Export save", [21, 6]) { exportSave() }
                    bigButton("Import save", [22, 6]) { importing = true }
                }
                if !game.HasAchiev("Olden days") {
                    HStack { Spacer(); Button { game.win("Olden days"); Sound.play("snd/tick.mp3", 1); Sound.play("snd/shimmerClick.mp3", 1) } label: { IconView(icon: [12, 3], size: 20 * u) }.buttonStyle(.plain) }
                }
                Panel(title: nil, u: u) {
                    VStack(spacing: 6 * u) {
                        RichText(html: "Your game saves by itself every few seconds. You can also back it up as a file, or send it to another phone with a QR code in <b>iPhone extras</b>.", size: 11 * u, align: .center)
                        GameButton(text: "<span style=\"color:#ff5134\">Wipe save</span><br><small>(will ask for confirmation)</small>", u: u, size: 13) { ui.popup = .confirmWipe }
                    }.frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 6 * u)
            .padding(.bottom, 12 * u)
        }
        .sheet(isPresented: $showExtras) { ExtrasView(host: Extras.host) { showExtras = false } }
        .sheet(item: $exporting) { url in ShareSheet(items: [url]) }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.plainText, .data, .json]) { result in
            guard case .success(let url) = result else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            if let text = try? String(contentsOf: url) { Extras.host.receiveSave(text) }
        }
    }

    func bigButton(_ text: String, _ icon: [Int], _ action: @escaping () -> Void) -> some View {
        Button(action: { Sound.play("snd/press.mp3", 0.3); action() }) {
            HStack(spacing: 4 * u) {
                IconView(icon: icon, size: 36 * u)
                Text(text).font(.fancy(14 * u)).foregroundColor(.white).gameShadow().minimumScaleFactor(0.6).lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(6 * u)
            .frame(height: 56 * u)
            .background(RoundedRectangle(cornerRadius: 4 * u).fill(Color(white: 0.25).opacity(0.85)))
            .overlay(RoundedRectangle(cornerRadius: 4 * u).stroke(Color.white.opacity(0.15), lineWidth: 1))
        }.buttonStyle(PressStyle())
    }

    func exportSave() {
        Extras.host.currentSave { json, _, _ in
            guard let json = json else { return }
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("CookieClickerSave.txt")
            try? Data(json.utf8).base64EncodedString().write(to: url, atomically: true, encoding: .utf8)
            exporting = url
        }
    }
}

extension URL: Identifiable { public var id: String { absoluteString } }

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ c: UIActivityViewController, context: Context) {}
}
