import SwiftUI

/// The main screen: big cookie, milk, golden cookies, wrinklers, buffs and the sugar lump.
struct CookieScreen: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let u: CGFloat
    @State private var pressed = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width / u, h = geo.size.height / u
            TimelineView(.animation(minimumInterval: 1.0 / 60)) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                ZStack(alignment: .topLeading) {
                    // falling cookies
                    if game.settings["particles"] { CookieRain(u: u, w: w, h: h, t: t, cps: game.cookiesPs) }
                    // milk
                    if game.settings["milk"] { Milk(u: u, w: w, h: h, t: t) }
                    // wrinklers behind the cookie
                    WrinklersLayer(u: u, cx: w / 2, cy: h / 2, t: t)
                    // cursors circling the cookie
                    if game.settings["cursors"] { CursorRing(u: u, cx: w / 2, cy: h / 2, t: t, n: min(350, game.buildings[0].amount)) }
                    // the big cookie
                    BigCookie(u: u, pressed: pressed, t: t)
                        .position(x: w / 2 * u, y: h / 2 * u)
                        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged { v in
                                if !pressed {
                                    pressed = true
                                    let (n, mult) = game.clickCookie()
                                    let lx = (w / 2) + (v.location.x / u - 120), ly = (h / 2) + (v.location.y / u - 120)
                                    Effects.shared.floatText("+" + B(n, 1) + (mult > 1 ? " (x\(Fmt.jsNumber((mult * 1000).rounded() / 1000)))" : ""), lx, ly - 10)
                                    Effects.shared.cookiePop(lx, ly)
                                    Sound.play("snd/clickb\(Int.random(in: 1...7)).mp3", 0.5)
                                }
                            }
                            .onEnded { _ in pressed = false })
                    // particles (floating numbers, crumbs)
                    ParticlesLayer(u: u)
                    // golden cookies and reindeer
                    ShimmersLayer(u: u, t: t)
                    // buffs
                    BuffsColumn(u: u)
                    // sugar lump
                    if Lumps.canLumps(game) && game.lumpT > 0 { LumpView(u: u).position(x: 28 * u, y: 40 * u) }
                    // power clicks
                    if game.Has("Power clicks") { PowerClickButton(u: u).position(x: (w - 30) * u, y: (h - 34) * u) }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .onAppear { game.playW = w; game.playH = h }
            .onChange(of: geo.size) { s in game.playW = s.width / u; game.playH = s.height / u }
        }
    }
}

struct BigCookie: View {
    @EnvironmentObject var game: Game
    let u: CGFloat
    let pressed: Bool
    let t: Double
    var body: some View {
        let wobble = game.settings["cookiewobble"] && game.settings["fancy"]
        let s: CGFloat = pressed ? 0.95 : (wobble ? 1 + 0.01 * sin(t * 1.5) : 1)
        ZStack {
            if game.settings["fancy"] {
                Sprites.image("shine.png").resizable().frame(width: 420 * u, height: 420 * u)
                    .rotationEffect(.degrees(t * 6)).opacity(0.5).blendMode(.screen).allowsHitTesting(false)
                Sprites.image("cookieShadow.png").resizable().frame(width: 240 * u, height: 240 * u).offset(y: 8 * u).opacity(0.5)
            }
            Sprites.image(game.season == "fools" ? "brokenCookie.png" : "perfectCookie.png").resizable()
                .frame(width: 240 * u, height: 240 * u)
                .scaleEffect(s)
                .animation(.easeOut(duration: 0.08), value: pressed)
        }
        .frame(width: 240 * u, height: 240 * u)
        .contentShape(Circle())
    }
}

struct CursorRing: View {
    let u: CGFloat
    let cx: Double, cy: Double, t: Double
    let n: Int
    var body: some View {
        Canvas { ctx, _ in
            guard n > 0, let img = Sprites.ui("cursor.png") else { return }
            let pic = Image(uiImage: img)
            let base = t * (360.0 / 180) // one turn every 180s
            for i in 0..<n {
                let ring = i / 50
                let a = (Double(i % 50) * 7.2 + (ring % 2 == 1 ? 3.6 : 0) + base) * .pi / 180
                let d = Double(140 + ring * 16 - 24 + 16)
                let pulse = (i % 50 == Int(t * 2) % 50) ? 4.0 : 0
                var c = ctx
                c.opacity = 1 - Double(ring) / 8
                c.translateBy(x: cx * u, y: cy * u)
                c.rotate(by: .radians(a))
                c.translateBy(x: 0, y: (d - pulse) * u)
                c.draw(pic, in: CGRect(x: -8 * u, y: -8 * u, width: 16 * u, height: 16 * u))
            }
        }
        .allowsHitTesting(false)
    }
}

struct Milk: View {
    @EnvironmentObject var game: Game
    let u: CGFloat
    let w: Double, h: Double, t: Double
    var body: some View {
        let pic = Cosmetics.milkPic(game)
        let level = min(1, h / 640) * 0.9
        let mh = 240.0 * level
        ZStack(alignment: .bottomLeading) {
            if let img = Sprites.ui(pic + ".png") {
                Canvas { ctx, size in
                    let tile = 240 * u
                    let off = CGFloat((t * 30).truncatingRemainder(dividingBy: 240)) * u
                    var x = -off
                    while x < size.width {
                        ctx.draw(Image(uiImage: img), in: CGRect(x: x, y: size.height - tile, width: tile, height: tile))
                        x += tile
                    }
                }
                .frame(width: w * u, height: mh * u)
                .opacity(0.8)
            }
        }
        .frame(width: w * u, height: h * u, alignment: .bottomLeading)
        .allowsHitTesting(false)
    }
}

struct CookieRain: View {
    let u: CGFloat
    let w: Double, h: Double, t: Double, cps: Double
    var body: some View {
        let n = cps <= 0 ? 0 : min(30, Int(log10(cps + 1) * 3))
        Canvas { ctx, size in
            guard n > 0, let img = Sprites.ui("smallCookies.png"), let cg = img.cgImage else { return }
            let cw = cg.width / 8
            for i in 0..<n {
                let seed = Double(i) * 12.9898
                let speed = 40 + (sin(seed) + 1) * 30
                let x = (sin(seed * 3.3) + 1) / 2 * w
                let y = ((t * speed + Double(i) * 97).truncatingRemainder(dividingBy: h + 64)) - 32
                let frame = i % 8
                if let c = cg.cropping(to: CGRect(x: frame * cw, y: 0, width: cw, height: cg.height)) {
                    var cc = ctx
                    cc.opacity = 0.6
                    cc.translateBy(x: x * u, y: y * u)
                    cc.rotate(by: .degrees(t * 30 + Double(i) * 40))
                    cc.draw(Image(decorative: c, scale: 1), in: CGRect(x: -16 * u, y: -16 * u, width: 32 * u, height: 32 * u))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct ParticlesLayer: View {
    let u: CGFloat
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Effects.shared.particles) { p in
                let a = max(0, 1 - p.t / p.life)
                Group {
                    if let text = p.text {
                        Text(text).font(.fancy(14 * u)).foregroundColor(.white).gameShadow().fixedSize()
                    } else if p.pic == "cookieBit" {
                        SheetCell(sheet: "smallCookies.png", x: abs(p.id.hashValue) % 8, y: 0, w: 64, h: 64, width: 24 * u * p.s, height: 24 * u * p.s)
                    } else if p.pic == "sparkle" {
                        Sprites.image("glint.jpg").resizable().blendMode(.screen).frame(width: 64 * u, height: 64 * u)
                    } else if let pic = p.pic {
                        SheetCell(sheet: pic + ".png", x: abs(p.id.hashValue) % 8, y: 0, w: 100, h: 200, width: 30 * u, height: 60 * u)
                    }
                }
                .rotationEffect(.degrees(p.text == nil ? p.r : 0))
                .opacity(a)
                .position(x: p.x * u, y: p.y * u)
            }
        }
        .allowsHitTesting(false)
    }
}

struct ShimmersLayer: View {
    @EnvironmentObject var game: Game
    let u: CGFloat
    let t: Double
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(game.shimmers) { sh in
                if sh.type.name == "golden" { GoldenCookieView(sh: sh, u: u, t: t) }
                else { ReindeerView(sh: sh, u: u, t: t) }
            }
        }
    }
}

struct GoldenCookieView: View {
    @EnvironmentObject var game: Game
    let sh: Shimmer
    let u: CGFloat
    let t: Double
    var body: some View {
        let life = Game.fps * sh.dur
        let curve = 1 - pow((sh.t / max(1, life)) * 2 - 1, 4)
        let s = sh.s
        Group {
            switch game.season {
            case "easter": SheetCell(sheet: "bunnies.png", x: sh.pic % 4, y: sh.wrath ? 1 : 0, w: 96, h: 96, width: s * u, height: s * u)
            case "halloween": SheetCell(sheet: "familiars.png", x: sh.pic % 4, y: sh.wrath ? 1 : 0, w: 96, h: 96, width: s * u, height: s * u)
            case "valentines": SheetCell(sheet: "hearts.png", x: sh.pic % 8, y: sh.wrath ? 1 : 0, w: 96, h: 96, width: s * u, height: s * u)
            case "christmas": Sprites.image(sh.wrath ? "wrathCookieWreath.png" : "goldCookieWreath.png").resizable().frame(width: s * u, height: s * u)
            default: Sprites.image(sh.wrath ? "wrathCookie.png" : "goldCookie.png").resizable().frame(width: s * u, height: s * u)
            }
        }
        .rotationEffect(.degrees(game.season == "fools" ? 0 : sh.r + sin(t * 7.5 + Double(sh.seq)) * 8))
        .opacity(sh.force == "cookie storm drop" ? 1 : curve)
        .position(x: sh.x * u, y: sh.y * u)
        .onTapGesture { game.clickShimmer(sh) }
    }
}

struct ReindeerView: View {
    @EnvironmentObject var game: Game
    let sh: Shimmer
    let u: CGFloat
    let t: Double
    var body: some View {
        let r = 1 - sh.t / (Game.fps * sh.dur)
        let x = (game.playW + 167) * r + sin(t * 3 + Double(sh.seq)) * 32 - 167 / 2
        let y = (game.playH + 212) * r - abs(cos(t * 3 + Double(sh.seq)) * 16) - 212 / 2
        Sprites.image("frostedReindeer.png").resizable().frame(width: 167 * 0.6 * u, height: 212 * 0.6 * u)
            .rotationEffect(.degrees(sin(t * 3 + Double(sh.seq) + .pi * 0.2) * 16 + 8))
            .position(x: x * u, y: y * u)
            .onTapGesture { game.clickShimmer(sh) }
    }
}

struct WrinklersLayer: View {
    @EnvironmentObject var game: Game
    let u: CGFloat
    let cx: Double, cy: Double, t: Double
    func place(_ w: Wrinkler) -> (Double, Double, Double) {
        let i = Double(w.id)
        var d = 110.0
        var r = (i / 11 + 0.25) * 0.35
        if game.settings["fancy"] {
            d += sin(w.seed * 741 + 37 + t * 30 * (0.02 + sin(w.seed * 4.17) * 0.01)) * 5 + 100 * (1 - w.close)
            r += 0.005 * sin(w.seed * 3.7 + 0.3 + t * 30 * (0.03 + sin(w.seed * 0.91) * 0.02))
        } else { d += 100 * (1 - w.close) }
        let ang = r * .pi * 2
        w.x = cx + sin(ang) * d; w.y = cy + cos(ang) * d - 30
        return (w.x, w.y, ang)
    }
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Wrinklers.shared.list.filter { $0.phase > 0 && $0.hp > 0 }) { w in
                let pos = place(w)
                let ang = pos.2, x = pos.0, y = pos.1
                let s = 0.25 + 0.1 * sin(w.seed)
                let pic = w.type == 1 ? "shinyWrinkler.png" : (game.season == "christmas" ? "winterWrinkler.png" : "wrinkler.png")
                Sprites.image(pic).resizable()
                    .frame(width: 100 * u * (s / 0.3), height: 200 * u * (s / 0.3))
                    .rotationEffect(.radians(-ang + Double.pi) + .degrees(w.hurt * sin(t * 30 + w.seed * 97) * 18), anchor: .top)
                    .position(x: x * u, y: (y + 100 * s / 0.3 * 0.5) * u)
                    .onTapGesture {
                        Wrinklers.shared.click(game, w)
                        Effects.shared.cookiePop(x, y)
                    }
            }
        }
    }
}

struct BuffsColumn: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let u: CGFloat
    var body: some View {
        VStack(spacing: -4 * u) {
            ForEach(game.buffs) { b in
                ZStack(alignment: .bottom) {
                    IconView(icon: b.type.icon, size: 48 * u)
                    Text(sayTime(b.t * 1000 + 1000, 0, true)).font(.fancy(11 * u)).foregroundColor(.white).gameShadow()
                }
                .onTapGesture { ui.popup = .buff(b.id) }
            }
        }
        .padding(.top, 70 * u)
        .padding(.leading, 4 * u)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

struct LumpView: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let u: CGFloat
    var body: some View {
        let ic = Lumps.icons(game)
        let ripe = now() - game.lumpT >= Lumps.matureAge
        VStack(spacing: -4 * u) {
            ZStack {
                IconView(icon: ic.a, size: 48 * u)
                IconView(icon: ic.b, size: 48 * u).opacity(ic.opacity)
            }
            .shadow(color: ripe ? Color(red: 1, green: 1, blue: 0.8).opacity(0.9) : .clear, radius: ripe ? 6 * u : 0)
            Text(B(game.lumps)).font(.fancy(13 * u)).foregroundColor(.white).gameShadow()
        }
        .onTapGesture { Sound.play("snd/press.mp3", 0.15); ui.popup = .lumps }
    }
}

struct PowerClickButton: View {
    @EnvironmentObject var game: Game
    let u: CGFloat
    var body: some View {
        Button {
            game.powerClicksOn.toggle()
            Sound.play(game.powerClicksOn ? "snd/clickOn2.mp3" : "snd/clickOff2.mp3", 0.6)
        } label: {
            VStack(spacing: 0) {
                IconView(icon: [30, 36], size: 40 * u).opacity(game.powerClicksOn ? 1 : 0.6)
                Text("\(Int(game.powerClicks))/\(Int(game.powerClickCapacity()))").font(.fancy(10 * u)).foregroundColor(.white).gameShadow()
            }
            .padding(4 * u)
            .background(Circle().fill(game.powerClicksOn ? Color.orange.opacity(0.35) : Color.black.opacity(0.35)))
        }
        .buttonStyle(.plain)
    }
}
