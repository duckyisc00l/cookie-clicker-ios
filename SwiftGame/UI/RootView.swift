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

struct RootView: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState

    var body: some View {
        GeometryReader { geo in
            let u = geo.size.width / 320
            let insets = SafeArea.insets
            ZStack(alignment: .top) {
                Background(u: u)
                if game.onAscend == 1 {
                    AscendView(u: u, insets: insets)
                } else {
                    VStack(spacing: 0) {
                        TopStuff(u: u).padding(.top, insets.top)
                        ZStack {
                            switch ui.tab {
                            case .cookie: CookieScreen(u: u)
                            case .store: StoreScreen(u: u)
                            case .special: SpecialScreen(u: u)
                            case .stats: StatsScreen(u: u)
                            case .misc: MiscScreen(u: u)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        TabBar(u: u, bottom: insets.bottom)
                    }
                    ToastsView(u: u).padding(.bottom, insets.bottom + 48 * u)
                }
                if let p = ui.popup {
                    PopupHost(kind: p, u: u, insets: insets)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
                if let m = ui.minigame {
                    MinigameHost(name: m, u: u, insets: insets)
                        .transition(.move(edge: .bottom))
                }
            }
            .environment(\.scale320, Scale(u: u))
            .ignoresSafeArea()
            .onAppear { Ticker.shared.screenW = 320 }
        }
        .ignoresSafeArea()
        .animation(.easeOut(duration: 0.18), value: ui.popup?.id)
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

// MARK: - top: news, cookie count, CpS

struct TopStuff: View {
    @EnvironmentObject var game: Game
    let u: CGFloat
    var body: some View {
        let _ = game.frame
        VStack(spacing: 0) {
            TickerView(u: u).frame(height: 18 * u)
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { _ in
                VStack(spacing: 0) {
                    HStack(spacing: 4 * u) {
                        Text("\(B(game.cookiesD)) cookie\(B(game.cookiesD) == "1" ? "" : "s")")
                            .font(.fancy(20 * u)).foregroundColor(.white).gameShadow()
                    }
                    let buffed = game.cookiesPs != game.cookiesPsUnbuffed
                    Text("\(B(game.cookiesPs, 1))/s" + (game.cpsSucked > 0 ? " (\(B(game.cookiesPs * (1 - game.cpsSucked), 1)) after wrinklers)" : ""))
                        .font(.fancy(12 * u))
                        .foregroundColor(buffed ? (game.cookiesPs > game.cookiesPsUnbuffed ? Color(hex: "ffd861") : .costRed) : .white)
                        .gameShadow()
                }
            }
        }
        .padding(.bottom, 4 * u)
        .frame(maxWidth: .infinity)
        .background(LinearGradient(colors: [.black.opacity(0.55), .black.opacity(0)], startPoint: .top, endPoint: .bottom))
    }
}

struct TickerView: View {
    @EnvironmentObject var game: Game
    let u: CGFloat
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { _ in
            let t = Ticker.shared
            GeometryReader { geo in
                RichText(html: t.current.text, size: 13 * u, color: t.current.fortune != nil ? Color(hex: "ade000") : .white, font: .fancy(13 * u))
                    .lineLimit(1)
                    .fixedSize()
                    .background(GeometryReader { g in Color.clear.onAppear { t.width = g.size.width / u }.onChange(of: t.current.text) { _ in t.width = g.size.width / u } })
                    .offset(x: t.x * u)
                    .gameShadow()
                    .onTapGesture { t.tapped(game) }
            }
            .clipped()
        }
    }
}

// MARK: - bottom tabs

struct TabBar: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let u: CGFloat
    let bottom: CGFloat
    var body: some View {
        let _ = game.frame
        HStack(spacing: 0) {
            ForEach(Array(UIState.Tab.allCases.enumerated()), id: \.offset) { i, tab in
                let on = ui.tab == tab
                Button {
                    if ui.tab != tab { Sound.play("snd/press.mp3", 0.4) }
                    ui.tab = tab
                    game.pings.remove(tab.rawValue.lowercased())
                } label: {
                    ZStack {
                        if on { Sprites.image("shadedBackdrop.png").resizable() }
                        VStack(spacing: 0) {
                            SheetCell(sheet: "tabIcons.png", x: i, y: on ? 0 : 1, w: 128, h: 128, width: 32 * u, height: 32 * u)
                                .offset(y: on ? -1 * u : 2 * u)
                            Text(tab.rawValue).font(.fancy(12 * u)).foregroundColor(on ? .white : Color(white: 0.8)).gameShadow()
                                .padding(.top, -6 * u)
                        }
                        if game.pings.contains(tab.rawValue.lowercased()) && !on {
                            Sprites.image("pingDot.png").resizable().frame(width: 12 * u, height: 12 * u).offset(x: 12 * u, y: -14 * u)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44 * u)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, bottom)
        .background(Tiled(name: "bottomBar.jpg", scale: u).ignoresSafeArea())
        .overlay(alignment: .top) { Sprites.image("panelHorizontal.png").resizable().frame(height: 4 * u).offset(y: -2 * u) }
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
