import SwiftUI
import UniformTypeIdentifiers

/// Stats screen, laid out like the original (title at +66, stats list, Log/News buttons, upgrades and achievements sections).
struct StatsScreen: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let u: CGFloat
    let m: Metrics

    static func upgradesTotal(_ g: Game) -> Int { g.upgrades.filter { !["toggle", "prestige"].contains($0.pool) && !$0.def.unimplemented }.count }
    static func achievsTotal(_ g: Game) -> Int { g.achievs.filter { $0.def.pool != "shadow" && !$0.def.unimplemented }.count }

    var body: some View {
        let _ = game.frame
        let ut = StatsScreen.upgradesTotal(game), at = StatsScreen.achievsTotal(game)
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ScreenTitle(text: "Stats", u: u).padding(.top, 66 * u)
                ZStack(alignment: .topTrailing) {
                    VStack(alignment: .leading, spacing: 0) { stats }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 6 * u)
                    VStack(spacing: 4 * u) {
                        sideButton([15, 9], "Log") { ui.popup = .log }
                        sideButton([27, 7], "News") { ui.popup = .news }
                    }
                    .padding(.top, 3 * u).padding(.trailing, 2 * u)
                }
                SmallHeader(html: "Upgrades owned: <b>\(B(Double(game.upgradesN)))/\(B(Double(ut)))</b> (\(B(Double(game.upgradesN) / Double(max(1, ut)) * 100, 1))%)", u: u)
                    .padding(.top, 8 * u)
                DoilyBox(u: u) {
                    VStack(spacing: 4 * u) {
                        recent(game.recentUpgrades.map { ($0.def.icon, PopupKind.upgrade($0.id)) })
                        FullButton(icon: [29, 30], text: "View upgrades", u: u) { ui.popup = .upgradesList }
                    }
                }
                SmallHeader(html: "Achievements unlocked: <b>\(B(Double(game.achievsN)))/\(B(Double(at)))</b> (\(B(Double(game.achievsN) / Double(max(1, at)) * 100, 1))%)", u: u)
                    .padding(.top, 6 * u)
                DoilyBox(u: u) {
                    VStack(spacing: 4 * u) {
                        let milk = Cosmetics.milks[min(Cosmetics.milks.count - 1, game.achievsN / 25)]
                        let rank = min(Cosmetics.milks.count - 1, game.achievsN / 25)
                        HStack(spacing: 2 * u) {
                            Text("Milk:").font(.body(11 * u))
                            IconView(icon: milk.icon, size: 24 * u)
                            Text(Cosmetics.milkRankName(rank)).font(.body(11 * u, bold: true))
                            Spacer()
                        }
                        Text("(Milk is gained with each achievement. May unlock unique upgrades over time.)").font(.body(7.7 * u)).opacity(0.75).multilineTextAlignment(.center)
                        recent(game.recentAchievs.map { ($0.def.icon, PopupKind.achievement($0.id)) })
                        FullButton(icon: [29, 7], text: "View achievements", u: u) { ui.popup = .achievsList }
                    }
                }
            }
            .foregroundColor(Color(white: 0.8))
            .padding(.horizontal, 8 * u)
            .padding(.bottom, 12 * u)
        }
    }

    @ViewBuilder var stats: some View {
        let g = game
        if g.resets > 0 {
            line("Legacy started: <b>\(sayTime(now() - g.gameStart)) ago</b>")
            sub("with \(B(g.resets)) ascension\(g.resets == 1 ? "" : "s")")
        }
        line("Run started: <b>\(sayTime(now() - g.runStart)) ago</b>")
        line("Cookies in bank: \(cookie)<b>\(Fmt.B(g.cookies, 0, 2))</b>")
        if g.cookies >= 1000 { sub("...or \(cookie)<b>\(Fmt.B(g.cookies, 0, 1))</b>") }
        line("Cookies baked: \(cookie)<b>\(Fmt.B(g.cookiesEarned, 0, 2))</b>")
        if g.cookiesEarned >= 1000 { sub("...or \(cookie)<b>\(Fmt.B(g.cookiesEarned, 0, 1))</b>") }
        if g.resets > 0 { line("Cookies baked (all time): \(cookie)<b>\(Fmt.B(g.cookiesEarned + g.cookiesReset, 0, 1))</b>") }
        line("Cookies per second (CpS): \(cookie)<b>\(Fmt.B(g.cookiesPs, 1, 2))</b>")
        if g.cookiesPs >= 1000 { sub("...or \(cookie)<b>\(Fmt.B(g.cookiesPs, 1, 1))</b>/s") }
        let mm = g.p("cpsM") * 100 - 100
        line("CpS multiplier: <b>\(mm >= 0 ? "+" : "")\(Fmt.B(mm, 1, 1))%</b>")
        if g.p("cpsBuffM") != 1 { let b = g.p("cpsBuffM") * 100 - 100; sub("...plus from buffs: <b>\(b >= 0 ? "+" : "")\(Fmt.B(b, 1, 1))%</b>") }
        if g.prestige > 0 { sub("...plus from prestige: <b>+\(B(g.prestige * g.heavenlyMultiplier(), 1))%</b>") }
        if g.cpsSucked > 0 { line("<span style=\"color:#ff5134\">CpS withered by wrinklers: <b>\(Fmt.B(g.cpsSucked * 100, 1, 1))%</b> of total</span>") }
        if g.wrinklersPopped > 0 { line("Wrinklers popped: <b>\(B(g.wrinklersPopped))</b>") }
        line("Cookie taps: <b>\(Fmt.B(g.cookieClicks, 0, 1))</b>")
        line("Cookies per tap: \(cookie)<b>\(Fmt.B(g.cookiesPc, 0, 1))</b>")
        line("Hand-made cookies: \(cookie)<b>\(Fmt.B(g.cookiesHandmade, 0, 1))</b>")
        line("Golden cookie clicks: <b>\(Fmt.B(g.gcClicksTotal, 0, 1))</b>")
        if g.reindeerClicks > 0 { line("Reindeer clicks: <b>\(Fmt.B(g.reindeerClicks, 0, 1))</b>") }
        line("Buildings owned: <b>\(B(Double(g.buildingsN)))</b>")
    }

    /// little cookie in front of amounts (the original's .tinyCookie)
    var cookie: String { "\u{1F36A}" }

    @ViewBuilder func line(_ s: String) -> some View { StatLine(html: s, size: 11, u: u).frame(height: 15.5 * u, alignment: .leading) }
    func sub(_ s: String) -> some View { StatLine(html: s, size: 8.8, u: u).opacity(0.75).padding(.leading, 16 * u).frame(height: 13 * u, alignment: .leading).padding(.top, -3 * u) }

    func sideButton(_ icon: [Int], _ text: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack(alignment: .top) {
                IconView(icon: icon, size: 48 * u).offset(y: -2 * u)
                Text(text).font(.georgia(11 * u, bold: true)).foregroundColor(Color(white: 0.8))
                    .shadow(color: .white, radius: 0, x: 0, y: -0.5 * u).shadow(color: .black, radius: 1 * u, x: 0, y: 1 * u)
                    .offset(y: 39 * u)
            }
            .frame(width: 56 * u, height: 56 * u)
            .background(RoundedRectangle(cornerRadius: 4 * u).fill(LinearGradient(colors: [Color.white.opacity(0.1), Color.black.opacity(0.1)], startPoint: .top, endPoint: .bottom)))
            .background(BumpyBorder(u: u))
        }.buttonStyle(PressStyle())
    }

    func recent(_ items: [([Int], PopupKind)]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, it in
                Button { ui.popup = it.1 } label: { IconView(icon: it.0, size: 48 * u) }.buttonStyle(.plain)
            }
        }
    }
}

/// a stats line: Arial with bold amounts; the 🍪 marker becomes the game's tiny cookie icon
struct StatLine: View {
    let html: String
    let size: CGFloat
    let u: CGFloat
    var body: some View {
        let parts = html.components(separatedBy: "\u{1F36A}")
        HStack(spacing: 0) {
            ForEach(Array(parts.enumerated()), id: \.offset) { i, p in
                if i > 0 { Sprites.image("cookicon.png").resizable().frame(width: 11.2 * u, height: 11.2 * u) }
                RichText(html: p, size: size * u, color: Color(white: 0.8)).fixedSize()
            }
        }
        .shadow(color: .black, radius: 0, x: 1 * u, y: 1 * u)
    }
}

/// the original's ".smallHeader": Georgia bold on the barH.png strip
struct SmallHeader: View {
    let html: String
    let u: CGFloat
    var body: some View {
        RichText(html: html, size: 11 * u, color: Color(white: 0.8), font: .georgia(11 * u, bold: true), align: .center)
            .shadow(color: .white, radius: 0, x: 0, y: -0.5 * u).shadow(color: .black, radius: 1 * u, x: 0, y: 1 * u)
            .frame(width: 320 * u, height: 16 * u)
            .background(Sprites.image("barH.png").resizable().frame(width: 320 * u, height: 28 * u).offset(y: 2 * u))
    }
}

/// box with the doily border (the original's ".doilyTrim")
struct DoilyBox<Content: View>: View {
    let u: CGFloat
    @ViewBuilder var content: () -> Content
    var body: some View {
        content()
            .padding(.horizontal, 8 * u).padding(.vertical, 8 * u)
            .frame(maxWidth: .infinity)
            .background(DoilyBorder(u: u).padding(1 * u))
            .padding(.vertical, 4 * u)
    }
}

struct DoilyBorder: View {
    let u: CGFloat
    var body: some View {
        if let img = Sprites.ui("doilyBorder.png") {
            Image(uiImage: img.resizableImage(withCapInsets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16), resizingMode: .tile))
                .resizable(capInsets: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16), resizingMode: .tile)
                .opacity(0.3)
        }
    }
}

/// a wide button with an icon on the left (the original's ".fullButton")
struct FullButton: View {
    let icon: [Int]
    let text: String
    let u: CGFloat
    let action: () -> Void
    var body: some View {
        Button(action: { Sound.play("snd/press.mp3", 0.3); action() }) {
            HStack(spacing: 4 * u) {
                IconView(icon: icon, size: 48 * u)
                Text(text).font(.fancy(16 * u)).bold().foregroundColor(Color(white: 0.8))
            }
            .frame(width: 288 * u, height: 56 * u)
            .background(RoundedRectangle(cornerRadius: 4 * u).fill(LinearGradient(colors: [Color.white.opacity(0.1), Color.black.opacity(0.1)], startPoint: .top, endPoint: .bottom)))
            .background(BumpyBorder(u: u))
            .shadow(color: .black, radius: 0, x: 1 * u, y: 1 * u)
        }.buttonStyle(PressStyle())
    }
}

/// Misc screen, laid out like the original: Orteil, 4 big buttons, save tools, version.
struct MiscScreen: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let u: CGFloat
    let m: Metrics
    @State private var showExtras = false
    @State private var exporting: URL? = nil
    @State private var importing = false
    @State private var bubble = 0

    static let greetings = ["oh hey! nice to meet you.", "thanks for playing!", "don't forget to take breaks!", "have you tried the minigames?", "cookies are a sometimes food.", "hello again!"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ScreenTitle(text: "Misc", u: u).padding(.top, 66 * u)
                // Orteil and his speech bubble
                Button { bubble = (bubble + 1) % MiscScreen.greetings.count; Sound.play("snd/tick.mp3", 0.5) } label: {
                    ZStack(alignment: .topLeading) {
                        LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom).frame(width: 320 * u, height: 32 * u).offset(x: -8 * u, y: 43 * u)
                        SheetCell(sheet: "orteil.png", x: 0, y: 0, w: 62, h: 74, width: 62 * u, height: 74 * u).offset(x: -2 * u, y: 4 * u)
                        ZStack {
                            Sprites.image("orteilBubble.png").resizable()
                            Text(MiscScreen.greetings[bubble]).font(.fancy(10 * u)).foregroundColor(Color(white: 0.8)).padding(.leading, 12 * u)
                        }
                        .frame(width: 240 * u, height: 64 * u).offset(x: 62 * u, y: 2 * u)
                    }
                    .frame(width: 304 * u, height: 74 * u, alignment: .topLeading)
                }
                .buttonStyle(.plain)
                .padding(.top, 2 * u)
                // four big buttons
                VStack(spacing: 2 * u) {
                    HStack(spacing: 0) {
                        halfButton("Settings", [16, 5]) { ui.popup = .settings }
                        halfButton("About", [0, 7]) { ui.popup = .message("about", "") }
                    }
                    HStack(spacing: 0) {
                        halfButton("Version history", [23, 11]) { ui.popup = .message("versions", "") }
                        halfButton("Wipe save", [29, 6], red: true) { ui.popup = .confirmWipe }
                    }
                }
                .padding(.top, 4 * u)
                // saves
                VStack(spacing: 4 * u) {
                    RichText(html: "You can backup your save by <b>exporting it</b>.", size: 10 * u, color: Color(white: 0.8), align: .center)
                    HStack(spacing: 4 * u) {
                        smallButton("Export save file...") { exportSave() }
                        smallButton("Import save file...") { importing = true }
                    }
                    smallButton("iPhone extras...") { showExtras = true }
                }
                .padding(.vertical, 8 * u)
                .frame(maxWidth: .infinity)
                .background(BumpyBorder(u: u))
                .padding(.top, 10 * u)
                VStack(spacing: 4 * u) {
                    RichText(html: "You are playing the <span style=\"color:#99ff00\">Swift</span> version.", size: 11 * u, color: Color(white: 0.8), font: .body(11 * u, bold: true), align: .center)
                    Text("The whole game rewritten in Swift for iPhone. Your save works with the original app too (QR codes and save files).")
                        .font(.body(9 * u)).foregroundColor(Color(white: 0.8)).multilineTextAlignment(.center)
                }
                .padding(.vertical, 8 * u)
                .frame(maxWidth: .infinity)
                .background(BumpyBorder(u: u))
                .padding(.top, 6 * u)
                if !game.HasAchiev("Olden days") {
                    HStack { Spacer(); Button { game.win("Olden days"); Sound.play("snd/tick.mp3", 1); Sound.play("snd/shimmerClick.mp3", 1) } label: { IconView(icon: [12, 3], size: 24 * u) }.buttonStyle(.plain) }
                }
            }
            .shadow(color: .black, radius: 0, x: 1 * u, y: 1 * u)
            .padding(.horizontal, 8 * u)
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

    /// 152×56 button with a big icon behind the label (the original's ".halfButton")
    func halfButton(_ text: String, _ icon: [Int], red: Bool = false, _ action: @escaping () -> Void) -> some View {
        Button(action: { Sound.play("snd/press.mp3", 0.3); action() }) {
            ZStack {
                IconView(icon: icon, size: 72 * u).offset(x: -40 * u)
                VStack(spacing: 0) {
                    Text(text).font(.fancy(16 * u)).bold().kerning(text.count > 10 ? -0.8 * u : 0)
                        .foregroundColor(red ? Color(hex: "cc0000") : Color(white: 0.8))
                        .shadow(color: red ? Color(hex: "990000") : .clear, radius: 2 * u)
                    if red { Text("(will ask for confirmation)").font(.fancy(8 * u)).bold().foregroundColor(Color(hex: "cc0000")) }
                }
            }
            .frame(width: 152 * u, height: 56 * u)
            .clipped()
            .background(RoundedRectangle(cornerRadius: 4 * u).fill(LinearGradient(colors: [Color.white.opacity(0.1), Color.black.opacity(0.1)], startPoint: .top, endPoint: .bottom)))
            .background(BumpyBorder(u: u))
        }.buttonStyle(PressStyle())
    }

    func smallButton(_ text: String, _ action: @escaping () -> Void) -> some View {
        Button(action: { Sound.play("snd/press.mp3", 0.3); action() }) {
            Text(text).font(.body(10 * u, bold: true)).foregroundColor(Color(white: 0.8))
                .padding(.horizontal, 8 * u).frame(height: 18 * u)
                .background(BumpyBorder(u: u))
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
