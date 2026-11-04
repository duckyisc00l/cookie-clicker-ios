import SwiftUI

/// The ascension screen: the heavenly upgrade tree, drag to look around, tap to buy.
struct AscendView: View {
    @EnvironmentObject var game: Game
    @EnvironmentObject var ui: UIState
    let u: CGFloat
    let insets: EdgeInsets
    @State private var offset = CGSize.zero
    @State private var drag = CGSize.zero
    @State private var zoom: CGFloat = 1
    @State private var pinch: CGFloat = 1

    var positions: [Int: (Double, Double)] {
        var out: [Int: (Double, Double)] = [:]
        for (k, v) in game.data.extra["positions"] as? [String: [NSNumber]] ?? [:] {
            if let id = Int(k), v.count >= 2 { out[id] = (v[0].doubleValue, v[1].doubleValue) }
        }
        return out
    }

    func status(_ up: Upgrade) -> Int {
        if up.owned > 0 { return 3 }
        let parents = (game.data.heavenlyParents[up.id] ?? []).filter { $0 != -1 }
        if parents.allSatisfy({ game.upgradesBID[$0]?.owned ?? 0 > 0 }) { return 2 }
        return 0
    }

    var body: some View {
        let _ = game.frame
        let pos = positions
        let pool = game.upgradePools["prestige"] ?? []
        var st: [Int: Int] = [:]
        for up in pool { st[up.id] = status(up) }
        for up in pool where st[up.id] == 0 {
            if (game.data.heavenlyParents[up.id] ?? []).contains(where: { st[$0] == 2 || st[$0] == 3 }) { st[up.id] = 1 }
        }
        let shown = pool.filter { (st[$0.id] ?? 0) > 0 && pos[$0.id] != nil }
        let z = zoom * pinch
        return ZStack {
            Tiled(name: "starbg.jpg", scale: u * 0.5).ignoresSafeArea()
            Sprites.image("heavenRing1.jpg").resizable().frame(width: 300 * u, height: 300 * u).blendMode(.screen).opacity(0.4)
            GeometryReader { geo in
                let cx = geo.size.width / 2 + offset.width + drag.width
                let cy = geo.size.height / 2 + offset.height + drag.height
                ZStack(alignment: .topLeading) {
                    Canvas { ctx, _ in
                        for up in shown {
                            guard let p = pos[up.id] else { continue }
                            for parent in game.data.heavenlyParents[up.id] ?? [] {
                                guard let q = pos[parent], (st[parent] ?? 0) > 0 else { continue }
                                var path = Path()
                                path.move(to: CGPoint(x: cx + (q.0 + 28) * u * z, y: cy + (q.1 + 28) * u * z))
                                path.addLine(to: CGPoint(x: cx + (p.0 + 28) * u * z, y: cy + (p.1 + 28) * u * z))
                                let lit = up.owned > 0
                                ctx.stroke(path, with: .color(lit ? Color(red: 1, green: 0.9, blue: 0.6).opacity(0.8) : Color.white.opacity(0.25)), lineWidth: (lit ? 3 : 2) * u * z)
                            }
                        }
                    }
                    ForEach(shown, id: \.id) { up in
                        let p = pos[up.id]!
                        let s = st[up.id] ?? 0
                        Button { ui.popup = .upgrade(up.id) } label: {
                            ZStack {
                                if s == 3 { Circle().fill(Color.yellow.opacity(0.25)).frame(width: 56 * u * z, height: 56 * u * z).blur(radius: 6 * u) }
                                IconView(icon: up.def.icon, size: 48 * u * z)
                                    .saturation(s == 3 ? 1 : (s == 2 ? 0.6 : 0))
                                    .opacity(s == 1 ? 0.35 : 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .position(x: cx + (p.0 + 28) * u * z, y: cy + (p.1 + 28) * u * z)
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture().onChanged { drag = $0.translation }.onEnded { v in
                offset.width += v.translation.width; offset.height += v.translation.height; drag = .zero
            })
            .simultaneousGesture(MagnificationGesture().onChanged { pinch = $0 }.onEnded { v in zoom = max(0.4, min(2, zoom * v)); pinch = 1 })

            VStack {
                VStack(spacing: 2 * u) {
                    Text("Heavenly chips: \(B(game.heavenlyChips))").font(.fancy(17 * u)).foregroundColor(.white).gameShadow()
                    Text("Prestige level: \(B(game.prestige))").font(.fancy(12 * u)).foregroundColor(.white.opacity(0.85)).gameShadow()
                }
                .padding(.top, insets.top + 8 * u)
                Spacer()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4 * u) {
                        ForEach(0..<5, id: \.self) { i in
                            if game.Has("Permanent upgrade slot " + Cosmetics.romanize(i + 1)) {
                                Button { ui.popup = .permanentSlot(i) } label: {
                                    HStack(spacing: 4 * u) {
                                        IconView(icon: game.upgradesBID[game.permanentUpgrades[i]]?.def.icon ?? [i, 10], size: 32 * u)
                                        Text("Slot \(Cosmetics.romanize(i + 1))").font(.fancy(10 * u)).foregroundColor(.white)
                                    }
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                    Spacer()
                    Button {
                        Sound.play("snd/clickb2.mp3", 0.75)
                        game.reincarnate()
                        ui.tab = .cookie
                    } label: {
                        VStack(spacing: 0) {
                            Text("Reincarnate").font(.fancy(15 * u)).foregroundColor(.white)
                            Text("(when you're ready)").font(.system(size: 8 * u)).foregroundColor(.white.opacity(0.75))
                        }
                        .padding(.horizontal, 18 * u).padding(.vertical, 10 * u)
                        .background(RoundedRectangle(cornerRadius: 8 * u).fill(LinearGradient(colors: [Color(hex: "6b8cff"), Color(hex: "3355cc")], startPoint: .top, endPoint: .bottom)))
                        .shadow(color: Color(hex: "36f"), radius: 4 * u)
                        .gameShadow()
                    }.buttonStyle(PressStyle())
                }
                .padding(.horizontal, 10 * u)
                .padding(.bottom, insets.bottom + 10 * u)
            }
            ToastsView(u: u).padding(.bottom, insets.bottom + 80 * u)
        }
    }
}
