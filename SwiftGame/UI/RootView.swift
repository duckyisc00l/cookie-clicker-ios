import SwiftUI

/// Layout scale: the game is designed 320 units wide, like the original.
struct Scale { let u: CGFloat }
private struct ScaleKey: EnvironmentKey { static let defaultValue = Scale(u: 1) }
extension EnvironmentValues { var scale320: Scale { get { self[ScaleKey.self] } set { self[ScaleKey.self] = newValue } } }

enum SafeArea {
    static var insets: EdgeInsets {
        let w = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first
        let i = w?.safeAreaInsets ?? .zero
        return EdgeInsets(top: i.top, leading: i.left, bottom: i.bottom, trailing: i.right)
    }
}

/// Screen metrics in the original's 320-wide units (1 unit = 1 CSS px of the original game).
struct Metrics {
    let u: CGFloat        // points per unit
    let H: CGFloat        // screen height in units
    let T: CGFloat        // top safe area in units
    let B: CGFloat        // bottom safe area in units
    var tabsTop: CGFloat { H - B - 40 }
}

extension View {
    /// place a view at x, y (units, from the screen's top-left) with size w×h (units)
    func at(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ u: CGFloat) -> some View {
        self.frame(width: w * u, height: h * u).position(x: (x + w / 2) * u, y: (y + h / 2) * u)
    }
}

struct RootView: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState

    var body: some View {
        GeometryReader { geo in
            let u = geo.size.width / 320
            let insets = SafeArea.insets
            let m = Metrics(u: u, H: geo.size.height / u, T: insets.top / u, B: insets.bottom / u)
            ZStack(alignment: .topLeading) {
                Background(u: u)
                if game.onAscend == 1 {
                    AscendView(u: u, insets: insets)
                } else {
                    if ui.tab == .cookie && game.settings["milk"] {
                        TimelineView(.animation(minimumInterval: 1.0 / 30)) { tl in
                            Milk(u: u, w: 320, h: 240, t: tl.date.timeIntervalSinceReferenceDate)
                        }
                        .at(0, m.H - 240, 320, 240, u)
                        .allowsHitTesting(false)
                    }
                    // the current screen fills the space between the top safe area and the tabs
                    Group {
                        switch ui.tab {
                        case .cookie: CookieScreen(u: u)
                        case .store: StoreScreen(u: u, m: m)
                        case .special: SpecialScreen(u: u, m: m)
                        case .stats: StatsScreen(u: u, m: m)
                        case .misc: MiscScreen(u: u, m: m)
                        }
                    }
                    .at(0, m.T, 320, m.tabsTop - m.T, u)
                    .clipped()
                    TopStuff(u: u, m: m)
                    TabBar(u: u, m: m)
                    ToastsView(u: u).at(0, m.T, 320, m.tabsTop - m.T - 8, u)
                }
                if let p = ui.popup {
                    PopupHost(kind: p, u: u, insets: insets)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .transition(.opacity)
                }
                if let mg = ui.minigame {
                    MinigameHost(name: mg, u: u, insets: insets)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .transition(.move(edge: .bottom))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .environment(\.scale320, Scale(u: u))
            .onAppear { Ticker.shared.screenW = 320 }
        }
        .ignoresSafeArea()
        .animation(.easeOut(duration: 0.15), value: ui.popup?.id)
        .animation(.easeOut(duration: 0.25), value: ui.minigame)
    }
}

struct Background: View {
    @EnvironmentObject var game: Game
    let u: CGFloat
    @State private var wrathD = 0.0
    var body: some View {
        let _ = game.frame
        let bg = Cosmetics.background(game, wrathD: wrathD)
        ZStack {
            Tiled(name: bg.0, scale: u)
            if bg.2 > 0 { Tiled(name: bg.1, scale: u).opacity(bg.2) }
            Sprites.image("shadedEdges.png").resizable()
        }
        .ignoresSafeArea()
        .onChange(of: game.frame) { _ in
            let w = Double(game.elderWrath)
            if wrathD < w { wrathD = min(w, wrathD + 0.02 * 4) } else if wrathD > w { wrathD = max(w, wrathD - 0.02 * 4) }
        }
    }
}

// MARK: - top: news, cookie count, CpS (positions from the original: ticker at +2, count at +20, CpS at +40)

struct TopStuff: View {
    @EnvironmentObject var game: Game
    let u: CGFloat
    let m: Metrics
    var body: some View {
        ZStack(alignment: .topLeading) {
            TickerView(u: u).at(0, m.T + 2, 320, 14, u)
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { _ in
                let buffed = game.cookiesPs != game.cookiesPsUnbuffed
                VStack(spacing: 0) {
                    Text("\(B(game.cookiesD)) cookie\(B(game.cookiesD) == "1" ? "" : "s")")
                        .font(.fancy(20 * u)).foregroundColor(.white).frame(height: 20 * u)
                    Text("\(B(game.cookiesPs, 1))/s")
                        .font(.fancy(12 * u)).frame(height: 12 * u)
                        .foregroundColor(buffed ? (game.cookiesPs > game.cookiesPsUnbuffed ? Color(hex: "ffd861") : .costRed) : .white)
                }
                .lineLimit(1)
                .topShadow(u)
            }
            .at(0, m.T + 20, 320, 32, u)
            Text("v.8 ADLESS").font(.custom("ArialMT", size: 8 * u)).foregroundColor(Color(white: 0.8).opacity(0.6)).at(273, m.T + 16, 43, 8, u)
        }
        .allowsHitTesting(true)
    }
}

extension View {
    /// the original's top text shadow: 0 0 2px #000, 1px 1px 1px #000
    func topShadow(_ u: CGFloat) -> some View {
        self.shadow(color: .black, radius: 1 * u).shadow(color: .black, radius: 0.5 * u, x: 1 * u, y: 1 * u)
    }
}

struct TickerView: View {
    @EnvironmentObject var game: Game
    let u: CGFloat
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { _ in
            let t = Ticker.shared
            GeometryReader { _ in
                RichText(html: t.current.text, size: 14 * u, color: t.current.fortune != nil ? Color(hex: "ade000") : .white, font: .fancy(14 * u))
                    .lineLimit(1)
                    .fixedSize()
                    .background(GeometryReader { g in Color.clear.onAppear { t.width = g.size.width / u }.onChange(of: t.current.text) { _ in t.width = g.size.width / u } })
                    .offset(x: t.x * u)
                    .topShadow(u)
                    .onTapGesture { t.tapped(game) }
            }
        }
    }
}

// MARK: - bottom tabs (bottomShelf.png behind 5 tabs of 64×40)

struct TabBar: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let u: CGFloat
    let m: Metrics
    static let iconCol: [UIState.Tab: Int] = [.cookie: 0, .store: 2, .special: 1, .stats: 3, .misc: 4]
    var body: some View {
        let _ = game.frame
        ZStack(alignment: .topLeading) {
            Sprites.image("bottomShelf.png").resizable().at(0, m.tabsTop - 5, 320, m.H - m.tabsTop + 8, u)
            ForEach(Array(UIState.Tab.allCases.enumerated()), id: \.offset) { i, tab in
                let on = ui.tab == tab
                let x = CGFloat(i) * 64
                ZStack(alignment: .topLeading) {
                    if on { Sprites.image("shadedBackdrop.png").resizable().at(0, -3, 64, 40, u) }
                    SheetCell(sheet: "tabIcons.png", x: TabBar.iconCol[tab] ?? 0, y: on ? 0 : 1, w: 128, h: 128, width: 32 * u, height: 32 * u)
                        .at(16, on ? -10 : -4, 32, 32, u)
                    Text(tab.rawValue).font(.fancy(12 * u)).foregroundColor(on ? .white : Color(white: 0.8))
                        .shadow(color: .black, radius: 1 * u, x: 1 * u, y: 1 * u)
                        .fixedSize().at(0, on ? 21 : 24, 64, 12, u)
                    if game.pings.contains(tab.rawValue.lowercased()) && !on {
                        Sprites.image("pingDot.png").resizable().at(40, -4, 16, 16, u)
                    }
                }
                .frame(width: 64 * u, height: 40 * u, alignment: .topLeading)
                .contentShape(Rectangle())
                .onTapGesture {
                    if ui.tab != tab { Sound.play("snd/press.mp3", 0.4) }
                    ui.tab = tab
                    game.pings.remove(tab.rawValue.lowercased())
                }
                .position(x: (x + 32) * u, y: (m.tabsTop + 20) * u)
            }
        }
    }
}

// MARK: - toasts

struct ToastsView: View {
    @EnvironmentObject var game: Game
    let u: CGFloat
    var body: some View {
        VStack(spacing: 6 * u) {
            Spacer()
            ForEach(game.toasts.suffix(3)) { t in
                ToastRow(toast: t, u: u)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                            withAnimation { game.toasts.removeAll { $0.id == t.id } }
                        }
                    }
                    .onTapGesture { withAnimation { game.toasts.removeAll { $0.id == t.id } } }
            }
        }
        .padding(.horizontal, 16 * u)
        .animation(.easeOut(duration: 0.25), value: game.toasts.map(\.id))
        .allowsHitTesting(!game.toasts.isEmpty)
    }
}

struct ToastRow: View {
    let toast: Toast
    let u: CGFloat
    var body: some View {
        HStack(spacing: 6 * u) {
            if let icon = toast.icon { IconView(icon: icon, size: 40 * u) }
            VStack(spacing: 1 * u) {
                if toast.text == "Achievement unlocked" || toast.text == "Upgrade unlocked" {
                    Text(toast.text).font(.system(size: 11 * u, weight: .semibold)).foregroundColor(.white.opacity(0.9))
                    RichText(html: toast.title, size: 15 * u, font: .fancy(16 * u), align: .center)
                } else {
                    if !toast.title.isEmpty { RichText(html: toast.title, size: 15 * u, font: .fancy(15 * u), align: .center) }
                    if !toast.text.isEmpty { RichText(html: toast.text, size: 11 * u, align: .center) }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 14 * u).padding(.vertical, 6 * u)
        .background(Capsule().fill(Color.black.opacity(0.6)).shadow(color: .black.opacity(0.6), radius: 8 * u))
        .gameShadow()
    }
}
