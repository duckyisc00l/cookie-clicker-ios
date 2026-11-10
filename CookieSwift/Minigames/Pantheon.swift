import UIKit

// Port of mods/minigames/minigamePantheon.js (the desktop game's Pantheon), with the phone layout
// (spirits are dragged onto the slots with a finger).

final class God {
    let key: String, name: String, icon: [Int], quote: String
    var descBefore: String?, desc1: String?, desc2: String?, desc3: String?, descAfter: String?
    var activeDescFunc: (() -> String)?
    var id = 0
    var slot = -1
    init(_ key: String, _ name: String, _ icon: [Int], quote: String) { self.key = key; self.name = name; self.icon = icon; self.quote = quote }
}

final class Pantheon: Minigame {
    let parent: Building
    let name = "Pantheon"
    var gods: [God] = []
    var godsBN: [String: God] = [:]
    var slot = [-1, -1, -1]
    let slotNames = ["Diamond", "Ruby", "Jade"]
    var swaps = 3.0
    var swapT = nowMs()
    var lastSwapT = 0
    var dragging: God?
    var slotHovered = -1
    /// the screen moves the god pictures around
    var onSlotsChanged: (() -> Void)?

    init(_ b: Building) {
        parent = b
        buildGods()
    }

    private func g(_ s: String) -> String { "<span style=\"color:#3f0;\">\(s)</span>" }
    private func r(_ s: String) -> String { "<span style=\"color:#f30;\">\(s)</span>" }
    private func buildGods() {
        func add(_ god: God) { god.id = gods.count; gods.append(god); godsBN[god.key] = god }
        var x = God("asceticism", "Holobore, Spirit of Asceticism", [21, 18], quote: "An immortal life spent focusing on the inner self, away from the distractions of material wealth.")
        x.desc1 = g("+15% base CpS."); x.desc2 = g("+10% base CpS."); x.desc3 = g("+5% base CpS.")
        x.descAfter = r("If a golden cookie is clicked, this spirit is unslotted and all worship swaps will be used up.")
        add(x)
        x = God("decadence", "Vomitrax, Spirit of Decadence", [22, 18], quote: "This sleazy spirit revels in the lust for quick easy gain and contempt for the value of steady work.")
        x.desc1 = g("Golden and wrath cookie effect duration +7%.") + " " + r("Buildings grant -7% CpS.")
        x.desc2 = g("Golden and wrath cookie effect duration +5%.") + " " + r("Buildings grant -5% CpS.")
        x.desc3 = g("Golden and wrath cookie effect duration +2%.") + " " + r("Buildings grant -2% CpS.")
        add(x)
        x = God("ruin", "Godzamok, Spirit of Ruin", [23, 18], quote: "The embodiment of natural disasters. An impenetrable motive drives the devastation caused by this spirit.")
        x.descBefore = g("Selling buildings triggers a buff boosted by how many buildings were sold.")
        x.desc1 = g("Buff boosts clicks by +1% for every building sold for 10 seconds.")
        x.desc2 = g("Buff boosts clicks by +0.5% for every building sold for 10 seconds.")
        x.desc3 = g("Buff boosts clicks by +0.25% for every building sold for 10 seconds.")
        add(x)
        x = God("ages", "Cyclius, Spirit of Ages", [24, 18], quote: "This spirit knows about everything you'll ever do, and enjoys dispensing a harsh judgment.")
        x.activeDescFunc = {
            let lvl = G.hasGod("ages")
            var mult = 1.0
            if lvl == 1 { mult *= 0.15 * sin((nowMs() / 1000 / (60 * 60 * 3)) * Double.pi * 2) }
            else if lvl == 2 { mult *= 0.15 * sin((nowMs() / 1000 / (60 * 60 * 12)) * Double.pi * 2) }
            else if lvl == 3 { mult *= 0.15 * sin((nowMs() / 1000 / (60 * 60 * 24)) * Double.pi * 2) }
            return "Current bonus: \(mult < 0 ? "-" : "+")\(B(abs(mult) * 100, 2))%"
        }
        x.descBefore = "CpS bonus fluctuating between \(g("+15%")) and \(r("-15%")) over time."
        x.desc1 = "Effect cycles over 3 hours."; x.desc2 = "Effect cycles over 12 hours."; x.desc3 = "Effect cycles over 24 hours."
        add(x)
        x = God("seasons", "Selebrak, Spirit of Festivities", [25, 18], quote: "This is the spirit of merry getaways and regretful Monday mornings.")
        x.descBefore = g("Some seasonal effects are boosted.")
        x.desc1 = g("Large boost.") + " " + r("Switching seasons is 100% pricier.")
        x.desc2 = g("Medium boost.") + " " + r("Switching seasons is 50% pricier.")
        x.desc3 = g("Small boost.") + " " + r("Switching seasons is 25% pricier.")
        add(x)
        x = God("creation", "Dotjeiess, Spirit of Creation", [26, 18], quote: "All things that be and ever will be were scripted long ago by this spirit's inscrutable tendrils.")
        x.desc1 = g("All buildings are <b>7% cheaper</b>.") + " " + r("Heavenly chips have 30% less effect.")
        x.desc2 = g("All buildings are <b>5% cheaper</b>.") + " " + r("Heavenly chips have 20% less effect.")
        x.desc3 = g("All buildings are <b>2% cheaper</b>.") + " " + r("Heavenly chips have 10% less effect.")
        add(x)
        x = God("labor", "Muridal, Spirit of Labor", [27, 18], quote: "This spirit enjoys a good cheese after a day of hard work.")
        x.desc1 = g("Clicking is <b>15%</b> more powerful.") + " " + r("Buildings produce 3% less.")
        x.desc2 = g("Clicking is <b>10%</b> more powerful.") + " " + r("Buildings produce 2% less.")
        x.desc3 = g("Clicking is <b>5%</b> more powerful.") + " " + r("Buildings produce 1% less.")
        add(x)
        x = God("industry", "Jeremy, Spirit of Industry", [28, 18], quote: "While this spirit has many regrets, helping you rule the world through constant industrialization is not one of them.")
        x.desc1 = g("Buildings produce 10% more.") + " " + r("Golden and wrath cookies appear 10% less.")
        x.desc2 = g("Buildings produce 6% more.") + " " + r("Golden and wrath cookies appear 6% less.")
        x.desc3 = g("Buildings produce 3% more.") + " " + r("Golden and wrath cookies appear 3% less.")
        add(x)
        x = God("mother", "Mokalsium, Mother Spirit", [29, 18], quote: "A caring spirit said to contain itself, inwards infinitely.")
        x.desc1 = g("Milk is <b>10% more powerful</b>.") + " " + r("Golden and wrath cookies appear 15% less.")
        x.desc2 = g("Milk is <b>5% more powerful</b>.") + " " + r("Golden and wrath cookies appear 10% less.")
        x.desc3 = g("Milk is <b>3% more powerful</b>.") + " " + r("Golden and wrath cookies appear 5% less.")
        add(x)
        x = God("scorn", "Skruuia, Spirit of Scorn", [21, 19], quote: "This spirit enjoys poking foul beasts and watching them squirm, but has no love for its own family.")
        x.descBefore = r("All golden cookies are wrath cookies with a greater chance of a negative effect.")
        x.desc1 = g("Wrinklers appear 150% faster and digest 15% more cookies.")
        x.desc2 = g("Wrinklers appear 100% faster and digest 10% more cookies.")
        x.desc3 = g("Wrinklers appear 50% faster and digest 5% more cookies.")
        add(x)
        x = God("order", "Rigidel, Spirit of Order", [22, 19], quote: "You will find that life gets just a little bit sweeter if you can motivate this spirit with tidy numbers and properly-filled tax returns.")
        x.activeDescFunc = {
            "Buildings owned: \(B(Double(G.buildingsN)))<br>" + (G.buildingsN % 10 == 0 ? "Effect is active." : "Effect is inactive.")
        }
        x.desc1 = g("Sugar lumps ripen <b>\(Loc.sayTime(60 * 60 * G.fps))</b> sooner.")
        x.desc2 = g("Sugar lumps ripen <b>\(Loc.sayTime(60 * 40 * G.fps))</b> sooner.")
        x.desc3 = g("Sugar lumps ripen <b>\(Loc.sayTime(60 * 20 * G.fps))</b> sooner.")
        x.descAfter = r("Effect is only active when your total amount of buildings ends with 0.")
        add(x)
    }

    // MARK: rules
    func useSwap(_ n: Double) {
        swapT = nowMs()
        swaps -= n
        if swaps < 0 { swaps = 0 }
    }
    func slotGod(_ god: God, _ s: Int) {
        if s == god.slot { return }
        if s != -1 && slot[s] != -1 {
            gods[slot[s]].slot = god.slot
            if god.slot != -1 { slot[god.slot] = slot[s] }
        } else if god.slot != -1 { slot[god.slot] = -1 }
        if s != -1 { slot[s] = god.id }
        god.slot = s
        G.refreshCps = true
    }
    /// Game.hasGod: 1 (diamond) to 3 (jade); Supreme Intellect moves each slot up one
    func hasGod(_ what: String) -> Int {
        guard let god = godsBN[what] else { return 0 }
        for i in 0..<3 where slot[i] == god.id {
            return G.hasAura("Supreme Intellect") ? max(1, i) : i + 1
        }
        return 0
    }
    func forceUnslotGod(_ what: String) -> Bool {
        guard let god = godsBN[what], god.slot != -1 else { return false }
        slotGod(god, -1)
        onSlotsChanged?()
        return true
    }
    func dragGod(_ g: God) {
        dragging = g
        PlaySound("snd/tick.mp3", 1)
    }
    func hoverSlot(_ s: Int) {
        slotHovered = s
        if dragging != nil { PlaySound("snd/clickb\(Int(JSMath.random() * 7 + 1)).mp3", 0.75) }
    }
    func dropGod() {
        guard let d = dragging else { return }
        if slotHovered != -1 && (swaps == 0 || d.slot == slotHovered) {
            PlaySound("snd/sell1.mp3", 0.75)
        } else if slotHovered != -1 {
            useSwap(1)
            lastSwapT = 0
            slotGod(d, slotHovered)
            PlaySound("snd/tick.mp3", 1)
            PlaySound("snd/spirit.mp3", 0.5)
        } else {
            slotGod(d, -1)
            PlaySound("snd/sell1.mp3", 0.75)
        }
        dragging = nil
        onSlotsChanged?()
    }

    // MARK: text
    /// the desktop's tooltip markup (.templeEffect strips with gems)
    private func eff(_ html: String, gem: Int = 0, on: Bool = false, extra: String = "") -> String {
        let g = gem > 0 ? "<div class=\"usesIcon templeGem templeGem\(gem)\"></div>" : ""
        return "<div class=\"templeEffect\(gem > 0 ? " templeEffect\(gem)" : "")\(on ? " templeEffectOn" : "")\"\(extra)>\(g)\(html)</div>"
    }
    func godTooltip(_ me: God, slotForOn: Int? = nil) -> String {
        var s = "<div style=\"font-size:15px;font-weight:bold;color:#fff;margin:2px 0px;\">\(me.name)</div><line></line><div class=\"description\"><div style=\"margin:6px 0px;font-weight:bold;\">Effects:</div>"
        if slotForOn != nil, let f = me.activeDescFunc { s += eff(f(), on: true, extra: " style=\"padding:8px 4px;text-align:center;\"") }
        if let d = me.descBefore { s += eff(d) }
        if let d = me.desc1 { s += eff(d, gem: 1, on: slotForOn == 0) }
        if let d = me.desc2 { s += eff(d, gem: 2, on: slotForOn == 1) }
        if let d = me.desc3 { s += eff(d, gem: 3, on: slotForOn == 2) }
        if let d = me.descAfter { s += eff(d) }
        s += "<q>\(me.quote)</q></div>"
        return s
    }
    func slotTooltip(_ id: Int) -> String {
        let head = "<div class=\"templeEffect\" style=\"font-size:15px;color:#fff;margin-bottom:12px;\"><div class=\"usesIcon templeGem templeGem\(id + 1)\"></div>"
        if slot[id] != -1 {
            let me = gods[slot[id]]
            var sl = me.slot
            if G.hasAura("Supreme Intellect") { sl = max(0, sl - 1) }
            return head + "\(slotNames[id]) slot</div>" + godTooltip(me, slotForOn: sl)
        }
        let what = (slotHovered == id && dragging != nil) ? "Release to assign <b>\(dragging!.name)</b> to this slot." : "Drag a spirit onto this slot to assign it."
        return head.replacingOccurrences(of: "margin-bottom:12px;", with: "") + "\(slotNames[id]) slot (empty)</div><line></line><div class=\"description\">\(what)</div>"
    }
    /// the spirit's picture floats under the slot's name
    func slotIcon(_ id: Int) -> [Int]? {
        guard slot[id] != -1 else { return nil }
        let ic = gods[slot[id]].icon
        return [ic[0], ic[1], 0, 35]
    }
    func swapsTooltip() -> String {
        "<div style=\"font-size:11px;text-align:center;\">Each time you slot a spirit, you use up one worship swap.<line></line>If you have 2 swaps left, the next one will refill after \(Loc.sayTime(60 * 60 * 1 * G.fps)).<br>If you have 1 swap left, the next one will refill after \(Loc.sayTime(60 * 60 * 4 * G.fps)).<br>If you have 0 swaps left, you will get one after \(Loc.sayTime(60 * 60 * 16 * G.fps)).<line></line>Unslotting a spirit costs no swaps.</div>"
    }
    func refillTooltip() -> String {
        "<div style=\"text-align:center;font-size:11px;\">Click to refill all your worship swaps for <span style=\"color:#6f6;font-weight:bold;\"><span class=\"tinyIcon\" style=\"background-position:\(-29 * 48)px \(-14 * 48)px;\"></span>\(Loc.lumps(1))</span>." +
            (G.lumpRefill <= 0 ? "<br><small>(can be done once every \(Loc.sayTime(G.fps * 60 * 15, -1)))</small>" : "<br><small style=\"color:#f30;\">(usable again in \(Loc.sayTime(G.lumpRefill + G.fps, -1)))</small>") + "</div>"
    }
    func refill() {
        guard swaps < 3, G.lumps >= 1, G.lumpRefill <= 0 else { return }
        Minigames.spendLump(1, "refill") { [weak self] in
            G.lumpRefill = G.fps * 60 * 15
            self?.swaps = 3
            self?.swapT = nowMs()
            PlaySound("snd/pop\(Int(JSMath.random() * 3 + 1)).mp3", 0.75)
        }
    }
    var swapWait: Double {
        var t = 1000.0 * 60 * 60
        if swaps == 0 { t = 1000 * 60 * 60 * 16 } else if swaps == 1 { t = 1000 * 60 * 60 * 4 }
        return swapT + t - nowMs()
    }

    // MARK: Minigame
    func save() -> String {
        slot.map { jsString(Double($0)) }.joined(separator: "/") + " \(jsString(swaps)) \(jsString(swapT)) 0"
    }
    func load(_ str: String) {
        if str.isEmpty { return }
        let spl = str.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        let bits = (spl.first ?? "").split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        for ii in 0..<3 {
            let v = ii < bits.count ? jsParseFloat(bits[ii]) : .nan
            if v.isFinite, v != -1, Int(v) >= 0, Int(v) < gods.count { slotGod(gods[Int(v)], ii) }
        }
        let sw = spl.count > 1 ? jsParseFloat(spl[1]) : .nan
        swaps = sw.isFinite ? sw : 3
        let st = spl.count > 2 ? jsParseFloat(spl[2]) : .nan
        swapT = st.isFinite ? st : nowMs()
        onSlotsChanged?()
    }
    func reset(_ hard: Bool) {
        swaps = 3
        swapT = nowMs()
        slot = [-1, -1, -1]
        for g in gods { g.slot = -1 }
        onSlotsChanged?()
    }
    func logic() {
        if swapWait <= 0 && swaps < 3 { swaps += 1; swapT = nowMs() }
        lastSwapT += 1
    }
}

/// the Pantheon's screen
final class PantheonScreen: UIView, MinigameScreen {
    let M: Pantheon
    private let bg = PatternView("mgimg/BGpantheon.jpg")
    private let borders = PicView("mgimg/shadedBorders.png")
    private var slotViews: [TapView] = []
    private var godViews: [GodView] = []
    private var rosterFrames: [CGRect] = []
    private var slotFrames: [CGRect] = []
    private let info = TapView()
    private let infoText = RichLabel()
    private let refillB = TapView()
    private var drawT = 0
    private var dragStart: CGPoint = .zero

    init(_ m: Pantheon) {
        M = m
        super.init(frame: .zero)
        addSubview(bg); addSubview(borders)
        for i in 0..<3 {
            let s = TapView()
            let f = UIImageView(image: Res.sprite("mgimg/spellBG.png", x: [0.0, 60, 120][i], y: 0, w: 60, h: 74))
            f.tag = 1
            s.addSubview(f)
            let gem = UIImageView(image: Res.sprite("img/icons.png", x: [1104.0, 1128, 1104][i], y: [720.0, 720, 744][i], w: 24, h: 24))
            gem.tag = 2
            s.addSubview(gem)
            s.layer.shadowColor = UIColor.black.cgColor; s.layer.shadowOpacity = 1; s.layer.shadowRadius = px(2); s.layer.shadowOffset = CGSize(width: px(4), height: px(4))
            s.onTap = { [weak self] _ in MinigameWindow.current?.showTooltip { [weak self] in (self?.M.slotTooltip(i) ?? "", self?.M.slotIcon(i)) } }
            addSubview(s)
            slotViews.append(s)
        }
        info.backgroundColor = UIColor(white: 0, alpha: 0.75)
        var st = TextStyle.base(12, color: UIColor(white: 1, alpha: 0.75)); st.align = .center; st.shadow = Shadows.make(-1, 1, 0)
        infoText.style = st
        info.addSubview(infoText)
        info.onTap = { [weak self] _ in MinigameWindow.current?.showTooltip { [weak self] in (self?.M.swapsTooltip() ?? "", nil) } }
        addSubview(info)
        let lump = IconView([29, 14])
        lump.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        refillB.addSubview(lump)
        refillB.onTap = { [weak self] _ in
            MinigameWindow.current?.showTooltip { [weak self] in (self?.M.refillTooltip() ?? "", nil) }
            self?.M.refill()
        }
        addSubview(refillB)
        for g in m.gods {
            let v = GodView(g, frame: g.id % 4)
            v.screen = self
            addSubview(v)
            godViews.append(v)
        }
        m.onSlotsChanged = { [weak self] in self?.placeGods(animated: false) }
    }
    required init?(coder: NSCoder) { fatalError() }

    func layoutContent(width w: Double, minHeight: Double) -> Double {
        // measured from the page: slots at y 15 (-4/0/+4), the info pill at 106, the roster from 145 every 82
        let sx = (w - 3 * 66) / 2
        slotFrames = []
        for (i, s) in slotViews.enumerated() {
            let f = CGRect(x: px(sx + Double(i) * 66 + 3), y: px(15 + [-4.0, 0, 4][i]), width: px(60), height: px(74))
            s.frame = f
            s.viewWithTag(1)?.frame = s.bounds
            s.viewWithTag(2)?.frame = CGRect(x: px(18), y: px(74 - 8 - 24), width: px(24), height: px(24))
            slotFrames.append(f)
        }
        let iw = 154.7
        info.frame = CGRect(x: px((w - iw) / 2), y: px(106), width: px(iw), height: px(28))
        info.layer.cornerRadius = px(14)
        infoText.frame = CGRect(x: px(32), y: px(8), width: px(iw - 48), height: px(12))
        refillB.frame = CGRect(x: info.frame.minX - px(6), y: info.frame.minY - px(10), width: px(48), height: px(48))
        refillB.subviews.first?.center = CGPoint(x: px(24), y: px(24))
        let perRow = max(1, Int((w - 8) / 66))
        let n = godViews.count
        rosterFrames = []
        for i in 0..<n {
            let row = i / perRow
            let inRow = min(perRow, n - row * perRow)
            let x0 = (w - Double(inRow) * 66) / 2
            rosterFrames.append(CGRect(x: px(x0 + Double(i % perRow) * 66 + 3), y: px(145 + Double(row) * 82), width: px(60), height: px(74)))
        }
        let y = 134 + 8 + Double((n + perRow - 1) / perRow) * 82 + 8 + 16
        let h = max(y, minHeight)
        bg.frame = CGRect(x: 0, y: 0, width: px(w), height: px(h))
        borders.frame = bg.frame
        placeGods(animated: false)
        return h
    }
    /// gods go in their slot or in their place in the roster (placeholders keep the roster's order)
    func placeGods(animated: Bool) {
        guard rosterFrames.count == godViews.count else { return }
        for (i, v) in godViews.enumerated() where M.dragging !== v.god {
            let f = v.god.slot >= 0 ? slotFrames[v.god.slot] : rosterFrames[i]
            v.inSlot = v.god.slot >= 0
            if animated { UIView.animate(withDuration: 0.1) { v.frame = f } } else { v.frame = f }
        }
    }

    // dragging (shim.js: touchstart on a spirit starts a drag, the slot under the finger is hovered, touchend drops)
    func begin(_ v: GodView, _ p: CGPoint) {
        M.dragGod(v.god)
        bringSubviewToFront(v)
        v.dragged = true
        dragStart = p
        MinigameWindow.current?.showTooltip { [weak self, weak v] in
            guard let self = self, let v = v else { return ("", nil) }
            return (self.M.godTooltip(v.god), v.god.icon)
        }
    }
    func move(_ v: GodView, _ p: CGPoint) {
        var s = -1
        for (i, f) in slotFrames.enumerated() where f.insetBy(dx: -px(8), dy: -px(8)).contains(p) { s = i }
        if s != M.slotHovered { M.hoverSlot(s) }
        // M.draw: follow the finger, snap to a hovered slot
        if M.slotHovered != -1 { v.frame = slotFrames[M.slotHovered] }
        else { v.frame = CGRect(x: p.x - px(30), y: p.y - px(32), width: px(60), height: px(74)) }
    }
    func end(_ v: GodView, _ p: CGPoint) {
        move(v, p)
        M.dropGod()
        v.dragged = false
        placeGods(animated: true)
    }

    func drawFrame() {
        drawT += 1
        if drawT % 5 == 0 {
            let t2 = M.swapWait
            let s = "Worship swaps: <span style=\"font-family:Georgia;font-weight:bold;color:\(M.swaps > 0 ? "#fff" : "#c00");\">\(jsString(M.swaps))/3</span>" + (M.swaps < 3 ? " (next in \(Loc.sayTime((t2 / 1000 + 1) * G.fps, -1)))" : "")
            if s != infoText.html {
                infoText.html = s
                let tw = Double(RichText.size(RichText.render(s, style: infoText.style, width: 280), width: 280).width) + 2
                let th = infoText.fittingHeight(tw)
                let iw = tw + 48
                let W = Double(bounds.width / K)
                info.frame = CGRect(x: px((W - iw) / 2), y: info.frame.minY, width: px(iw), height: px(th + 16))
                info.layer.cornerRadius = px(min(16, (th + 16) / 2))
                _ = W
                infoText.frame = CGRect(x: px(32), y: px(8), width: px(tw), height: px(th))
                refillB.frame.origin = CGPoint(x: info.frame.minX - px(6), y: info.frame.minY - px(10))
            }
        }
    }
}

/// a spirit card (.templeGod)
final class GodView: UIView {
    let god: God
    weak var screen: PantheonScreen?
    private let card = UIImageView()
    private let icon: IconView
    private let col: Int
    var dragged = false { didSet { updateLook() } }
    var inSlot = false { didSet { updateLook() } }
    init(_ g: God, frame f: Int) {
        god = g
        col = f
        icon = IconView(g.icon)
        super.init(frame: .zero)
        addSubview(card)
        addSubview(icon)
        layer.shadowColor = UIColor.black.cgColor; layer.shadowOpacity = 1; layer.shadowRadius = px(2); layer.shadowOffset = CGSize(width: px(4), height: px(4))
        updateLook()
    }
    required init?(coder: NSCoder) { fatalError() }
    private func updateLook() {
        // in a slot the card has no background of its own; dragged cards use the "hover" frame
        card.isHidden = inSlot && !dragged
        card.image = Res.sprite("mgimg/spellBG.png", x: Double(col % 4) * 60, y: dragged ? 74 : 0, w: 60, h: 74)
        layer.shadowRadius = dragged ? px(3) : px(2)
        layer.shadowOffset = dragged ? CGSize(width: px(6), height: px(6)) : CGSize(width: px(4), height: px(4))
        setNeedsLayout()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        card.frame = bounds
        icon.frame = CGRect(x: px(6), y: px(inSlot && !dragged ? 2 : 12), width: px(48), height: px(48))
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let s = screen, let t = touches.first else { return }
        s.begin(self, t.location(in: s))
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let s = screen, let t = touches.first else { return }
        s.move(self, t.location(in: s))
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let s = screen, let t = touches.first else { return }
        s.end(self, t.location(in: s))
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let s = screen, let t = touches.first else { return }
        s.end(self, t.location(in: s))
    }
}
