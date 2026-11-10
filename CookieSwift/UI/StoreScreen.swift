import UIKit

// The store screen (www/main.js "STORE SCREEN"): buildings and upgrades on marble slabs, the wooden shelf
// with the section tabs and the buy/sell amount buttons.

final class StoreScreen: GameScreen {
    static weak var shared: StoreScreen?
    private var section: UIView?
    private var list: StoreList?
    private var buildingRows: [BuildingRow] = []
    private var tabs: [String: StoreTabButton] = [:]
    private var options = UIView()
    private var bulkButtons: [String: CCButton] = [:]
    private var upgradeRows: [Int: UpgradeRow] = [:]
    private var upgradeData: [Int] = []
    private var lastUpgradeRefresh = 0.0
    private var redrawI = 0
    private var buildingRedrawI = 0

    init() { super.init(name: "store") }

    override func build() {
        StoreScreen.shared = self
        let W = view.bounds.width, H = view.bounds.height
        // #storeBG: wood, 64px at the bottom (background-size:cover of woodPanels, from the top)
        let wood = UIView(frame: CGRect(x: 0, y: H - px(64), width: W, height: px(64)))
        wood.clipsToBounds = true
        wood.isUserInteractionEnabled = false
        let woodPic = PicView("img/woodPanels.png")
        woodPic.frame = CGRect(x: 0, y: 0, width: px(320), height: px(160))
        wood.addSubview(woodPic)
        view.addSubview(wood)
        // .storeSection: top 56px, bottom 64px
        let sec = UIView(frame: CGRect(x: 0, y: px(56), width: W, height: H - px(56 + 64)))
        sec.clipsToBounds = true
        view.addSubview(sec)
        section = sec
        // #storeTabs: bottom 12px, left 8px
        let tabBox = UIView(frame: CGRect(x: px(8), y: H - px(12 + 46), width: px(128), height: px(46)))
        view.addSubview(tabBox)
        for (i, (id, name, icon)) in [("buildings", "Buildings", 5), ("upgrades", "Upgrades", 6)].enumerated() {
            let t = StoreTabButton(name: name, icon: icon)
            t.frame = CGRect(x: px(Double(i) * 64), y: 0, width: px(64), height: px(46))
            t.onTap = { [weak self] v in
                if !G.panning {
                    Anim.trigger(v, "plop")
                    PlaySound("snd/clickb2.mp3", 0.75)
                    self?.setSection(id)
                }
            }
            tabBox.addSubview(t)
            tabs[id] = t
        }
        // #storeOptions: bottom right, padding 12px
        options = UIView(frame: CGRect(x: W - px(12 + 172), y: H - px(12 + 46), width: px(172), height: px(46)))
        view.addSubview(options)
        // .sectionTrimOverlay.noLeft: the gilded trim over the list's top and bottom edges
        let trimTop = PicView("img/trimTopNoLeft.png")
        trimTop.frame = CGRect(x: 0, y: px(56 - 16), width: px(320), height: px(59))
        let trimBottom = PicView("img/trimBottom.png")
        trimBottom.frame = CGRect(x: 0, y: H - px(8) + px(16) - px(59), width: px(320), height: px(59))
        view.addSubview(trimTop); view.addSubview(trimBottom)
        setSection(G.onStoreSection)
    }

    override func clean() {
        buildingRows = []
        upgradeRows = [:]
        list = nil
        tabs = [:]
        bulkButtons = [:]
        if StoreScreen.shared === self { StoreScreen.shared = nil }
    }

    // MARK: G.setStoreSection
    private var currentSection = ""
    func setSection(_ id: String) {
        G.onStoreSection = id
        currentSection = id
        for (k, t) in tabs { t.setOn(k == id) }
        section?.subviews.forEach { $0.removeFromSuperview() }
        options.subviews.forEach { $0.removeFromSuperview() }
        buildingRows = []; upgradeRows = [:]; upgradeData = []
        guard let sec = section else { return }
        let l = StoreList(frame: sec.bounds)
        sec.addSubview(l)
        // .shadeUpInner: a soft shadow along the bottom of the section
        let shade = PatternView("img/shadedGradUp.png")
        shade.frame = CGRect(x: 0, y: sec.bounds.height - px(20), width: sec.bounds.width, height: px(20))
        sec.addSubview(shade)
        list = l
        if id == "buildings" { buildBuildings(l) } else { buildUpgrades(l) }
        Anim.switchAnim(sec, "switchTopIn", duration: 0.0001)
    }

    // MARK: buildings section
    private func buildBuildings(_ l: StoreList) {
        for b in G.buildings {
            let row = BuildingRow(b)
            row.onInfo = { BuildingUI.showInfo(b) }
            l.content.addSubview(row)
            buildingRows.append(row)
        }
        layoutBuildings()
        for r in buildingRows { r.redraw() }
        // the buy/sell amount buttons
        func bulk(_ text: String, _ key: String, _ width: Double, _ x: Double, _ y: Double, _ act: @escaping () -> Void) {
            let b = CCButton(text, look: .wood, font: bulkFont(), padding: UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8))
            b.frame = CGRect(x: px(x + 2), y: px(y + 2), width: px(width), height: px(19))
            b.onTap = { v in act(); Anim.trigger(v, "plop"); PlaySound("snd/clickb2.mp3", 0.75) }
            options.addSubview(b)
            bulkButtons[key] = b
        }
        bulk("Buying", "Buy", 96, 0, 0) { [weak self] in self?.setBulk(G.bulkBuy, 1) }
        bulk("1", "1", 32, 100, 0) { [weak self] in self?.setBulk(1, G.bulkMode) }
        bulk("10", "10", 32, 136, 0) { [weak self] in self?.setBulk(10, G.bulkMode) }
        bulk("Selling", "Sell", 96, 0, 23) { [weak self] in self?.setBulk(G.bulkBuy, -1) }
        bulk("100", "100", 32, 100, 23) { [weak self] in self?.setBulk(100, G.bulkMode) }
        bulk("Max", "Max", 32, 136, 23) { [weak self] in self?.setBulk(10000, G.bulkMode) }
        setBulk(G.bulkBuy, G.bulkMode)
    }
    private func bulkFont() -> TextStyle {
        var f = TextStyle.fancy(11, color: .ccText)
        f.bold = true
        f.nowrap = true
        f.shadow = Shadows.button
        return f
    }
    private func setBulk(_ n: Int, _ mode: Int) {
        let changed = G.bulkBuy != n || G.bulkMode != mode
        G.bulkBuy = n; G.bulkMode = mode
        for (k, b) in bulkButtons {
            b.on = (mode == 1 && k == "Buy") || (mode == -1 && k == "Sell") || (n == 1 && k == "1") || (n == 10 && k == "10") || (n == 100 && k == "100") || (n == 10000 && k == "Max")
        }
        if changed { for r in buildingRows { r.redraw() } }
    }
    /// locked buildings take no room (display:none)
    private func layoutBuildings() {
        guard let l = list else { return }
        var y = 0.0
        for r in buildingRows {
            if r.isHidden { continue }
            r.frame = CGRect(x: 0, y: px(y), width: l.bounds.width, height: px(48))
            y += 49
        }
        l.setContentHeight(px(y))
    }

    /// G.Draw redraws 3 buildings every 5 frames
    static func redrawSome() {
        guard let s = shared else { return }
        if s.buildingRows.isEmpty { return }
        var relayout = false
        for _ in 0..<3 {
            if s.buildingRedrawI >= s.buildingRows.count { s.buildingRedrawI = 0 }
            let r = s.buildingRows[s.buildingRedrawI]
            let was = r.isHidden
            r.redraw()
            if r.isHidden != was { relayout = true }
            s.buildingRedrawI += 1
        }
        if relayout { s.layoutBuildings() }
    }

    // MARK: upgrades section (G.scrollableList, rows of 49px)
    private func buildUpgrades(_ l: StoreList) {
        G.doUnlocks()
        refreshUpgrades(force: true)
        let b = CCButton("Buy all", look: .wood, font: bulkFont())
        b.frame = CGRect(x: px(172 - 96 - 2 + 2 - 2), y: px(23 + 2), width: px(96), height: px(19))
        b.onTap = { v in
            Anim.trigger(v, "plop")
            PlaySound("snd/clickb2.mp3", 0.75)
            var list = G.upgrades.filter { $0.pool != "toggle" && $0.pool != "science" && $0.pool != "prestige" && $0.unlocked != 0 && $0.owned == 0 }
            list.sort { $0.getCost() < $1.getCost() }
            var bought = 0
            for u in list { if !u.buy() { break } else { bought += 1 } }
            if bought > 0 {
                PlaySound("snd/buy\(choose([1, 2, 3, 4])).mp3", 0.65)
                G.toast("", "Bought \(B(Double(bought))) upgrade\(bought == 1 ? "" : "s").", nil, true)
            }
        }
        options.addSubview(b)
    }
    /// dataFunc: unlocked, unowned upgrades by price (or a "no upgrades" row)
    private func upgradeList() -> [Int] {
        var list = G.upgrades.filter { $0.unlocked != 0 && $0.owned == 0 && $0.pool != "science" && $0.pool != "prestige" && $0.pool != "toggle" }
        list.sort { $0.getCost() < $1.getCost() }
        return list.isEmpty ? [-1] : list.map { $0.id }
    }
    func refreshUpgrades(force: Bool = false) {
        guard let l = list, currentSection == "upgrades" else { return }
        let data = upgradeList()
        if !force && data == upgradeData {
            // redrawFunc: two rows at a time
            let rows = Array(upgradeRows.values)
            if !rows.isEmpty {
                for _ in 0..<2 { if redrawI >= rows.count { redrawI = 0 }; rows[redrawI].redraw(); redrawI += 1 }
            }
            return
        }
        let old = Set(upgradeData)
        upgradeData = data
        var keep: [Int: UpgradeRow] = [:]
        for (i, id) in data.enumerated() {
            let row: UpgradeRow
            if let r = upgradeRows[id] { row = r } else {
                row = UpgradeRow(id < 0 ? nil : G.upgradesBID[id])
                row.onBought = { [weak self] in self?.refreshUpgrades(force: true) }
                l.content.addSubview(row)
                if !force && !old.contains(id) {
                    // .scrollableListItemNew: fade in
                    row.alpha = 0
                    UIView.animate(withDuration: 0.35) { row.alpha = 1 }
                }
            }
            row.frame = CGRect(x: 0, y: px(Double(i) * 49), width: l.bounds.width, height: px(48))
            row.redraw()
            keep[id] = row
        }
        for (id, r) in upgradeRows where keep[id] == nil { r.removeFromSuperview() }
        upgradeRows = keep
        l.setContentHeight(px(Double(data.count) * 49))
    }

    override func draw() {
        // the list refreshes 4 times a second
        if currentSection == "upgrades" && nowMs() - lastUpgradeRefresh >= 250 {
            lastUpgradeRefresh = nowMs()
            refreshUpgrades()
        }
    }
}

/// .storeList: marble slabs scrolling with the rows
final class StoreList: ScrollArea {
    private let marble = PatternView("img/marbleSolid.jpg", tileSize: CGSize(width: 346, height: 346))
    private let slabs = PatternView("img/marbleSlabs.png", tileSize: CGSize(width: 346, height: 196))
    override init(frame: CGRect) {
        super.init(frame: frame)
        content.addSubview(marble)
        content.addSubview(slabs)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func setContentHeight(_ h: CGFloat) {
        let full = max(h, bounds.height)
        super.setContentHeight(h)
        content.frame.size.height = full
        marble.frame = CGRect(x: 0, y: 0, width: bounds.width, height: full)
        slabs.frame = marble.frame
        marble.setNeedsDisplay(); slabs.setNeedsDisplay()
    }
}

/// .button.bumpButton.storeTab on wood
final class StoreTabButton: TapView {
    private let bevel = BevelView(.wood)
    private let icon = UIImageView()
    private let label = RichLabel()
    private let iconIndex: Int
    private var on = false
    init(name: String, icon: Int) {
        iconIndex = icon
        super.init(frame: .zero)
        brightensWhenPressed = true
        layer.cornerRadius = px(4)
        addSubview(bevel)
        self.icon.isUserInteractionEnabled = false
        addSubview(self.icon)
        var st = TextStyle.fancy(11, color: .ccText)
        st.bold = true; st.align = .center; st.shadow = Shadows.button
        label.style = st
        label.html = name
        addSubview(label)
        layer.shadowColor = UIColor(red: 32 / 255, green: 16 / 255, blue: 9 / 255, alpha: 1).cgColor
        layer.shadowOpacity = 1; layer.shadowRadius = px(1); layer.shadowOffset = .zero
        setOn(false)
    }
    required init?(coder: NSCoder) { fatalError() }
    func setOn(_ v: Bool) {
        on = v
        alpha = v ? 1 : 0.75
        backgroundColor = v ? UIColor(white: 1, alpha: 0.1) : UIColor(red: 32 / 255, green: 16 / 255, blue: 9 / 255, alpha: 0.5)
        label.style.color = v ? .white : .ccText
        icon.image = Res.sprite("img/tabIcons.png", x: Double(iconIndex * 128), y: v ? 0 : 128, w: 128, h: 128)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        bevel.frame = bounds
        icon.frame = CGRect(x: px(18), y: 0, width: px(32), height: px(32))
        label.frame = CGRect(x: 0, y: bounds.height - px(4 + 11), width: bounds.width, height: px(13))
    }
}

// MARK: - rows

/// pieces shared by building and upgrade rows (.bar)
class StoreRow: UIView {
    let nameL = RichLabel()
    let descL = RichLabel()
    let infoButton = TapView()
    let buyButton = TapView()
    let buyText = RichLabel()
    let costL = RichLabel()
    let dim = UIView()
    private let infoIndent = PicView("img/barIndent.png")
    private let buyIndent = PicView("img/barIndent.png")
    private let infoText = RichLabel()
    var cantAfford = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        // .bar.cantAfford / .mysterious: background rgba(50,50,50,0.6)
        dim.backgroundColor = UIColor(red: 50 / 255, green: 50 / 255, blue: 50 / 255, alpha: 0.6)
        dim.isHidden = true
        dim.isUserInteractionEnabled = false
        addSubview(dim)
        var ns = TextStyle.fancy(14)
        ns.nowrap = true; ns.shadow = Shadows.bar
        nameL.style = ns
        var ds = TextStyle.base(10, color: .white)
        ds.textIndent = 4; ds.shadow = Shadows.bar; ds.lineHeight = 0.85
        descL.style = ds
        descL.clipsToBounds = true
        addSubview(nameL); addSubview(descL)
        for (b, ind) in [(infoButton, infoIndent), (buyButton, buyIndent)] {
            b.brightensWhenPressed = true
            ind.frame = CGRect(x: 0, y: 0, width: px(48), height: px(48))
            b.addSubview(ind)
            addSubview(b)
        }
        var it = TextStyle.fancy(13)
        it.align = .center; it.shadow = Shadows.bar; it.nowrap = true
        infoText.style = it
        infoText.html = "info"
        infoButton.addSubview(infoText)
        var bt = TextStyle.fancy(13)
        bt.align = .center; bt.shadow = Shadows.bar; bt.nowrap = true
        buyText.style = bt
        buyButton.addSubview(buyText)
        var cs = TextStyle.fancy(11, color: UIColor(css: "#9fff38"))
        cs.align = .center; cs.shadow = Shadows.cost; cs.nowrap = true
        costL.style = cs
        buyButton.addSubview(costL)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        let W = bounds.width
        dim.frame = bounds
        // .name: left 44 right 92, padding 4, 14px Fancy; .desc: top 14, 10px, line-height 85%
        nameL.frame = CGRect(x: px(48), y: px(4), width: W - px(44 + 92 + 8), height: px(18))
        descL.frame = CGRect(x: px(48), y: px(18), width: W - px(44 + 92 + 8), height: px(26))
        infoButton.frame = CGRect(x: W - px(48), y: 0, width: px(48), height: px(48))
        buyButton.frame = CGRect(x: W - px(96), y: 0, width: px(48), height: px(48))
        // info: line-height 48px
        infoText.frame = CGRect(x: -px(20), y: px(24 - 7.5), width: px(88), height: px(17))
        // buy text centred in a 38px line; the cost 26px higher than the next line (so centred at 31px)
        buyText.frame = CGRect(x: -px(20), y: px(19) - CGFloat(buyTextSize / 2) * K - px(1), width: px(88), height: px(buyTextSize + 4))
        costL.frame = CGRect(x: -px(40), y: px(31 - 6.5), width: px(128), height: px(14))
    }
    var buyTextSize = 13.0
    func setCost(_ s: String, red: Bool) {
        cantAfford = red
        var cs = costL.style
        cs.color = red ? UIColor(css: "#ff5134") : UIColor(css: "#9fff38")
        cs.shadow = red ? Shadows.costRed : Shadows.cost
        costL.style = cs
        // .cost:before: the little cookie (16px at 70%, margins -2px)
        costL.html = "<span class=\"tinyCookie\"></span>" + s
    }
}

/// .bar.building
final class BuildingRow: StoreRow {
    let b: Building
    let iconL = UIImageView()
    var onInfo: (() -> Void)?
    init(_ b: Building) {
        self.b = b
        super.init(frame: .zero)
        iconL.frame = CGRect(x: 0, y: 0, width: px(48), height: px(48))
        insertSubview(iconL, aboveSubview: dim)
        if let s = b.style, G.season != "fools" { nameL.html = "<span style=\"\(s)\">\(b.getName())</span>" }
        infoButton.onTap = { [weak self] v in Anim.trigger(v, "plop"); self?.onInfo?() }
        buyButton.onTap = { [weak self] v in self?.b.buy(); self?.redraw(); Anim.trigger(v, "plop") }
    }
    required init?(coder: NSCoder) { fatalError() }
    private var lastPic: (Double, Double) = (1, 1)
    /// G.Building.prototype.redraw
    func redraw() {
        if b.locked == 2 { isHidden = true; return }
        isHidden = false
        let pic = b.getPic()
        if pic != lastPic {
            lastPic = pic
            iconL.image = Res.sprite("img/buildings.png", x: -pic.0, y: -pic.1, w: 64, h: 64)
        }
        if b.locked == 1 {
            nameL.html = "???"
            descL.html = "(Unlocks at <span class=\"cost\" style=\"font-family:Fancy;\">\(B(b.baseCost))</span>)"
            dim.isHidden = false
            infoButton.isHidden = true; buyButton.isHidden = true
            iconL.alpha = 0.65
            descL.style.color = UIColor(css: "#bbb"); nameL.style.color = UIColor(css: "#bbb")
            return
        }
        infoButton.isHidden = false; buyButton.isHidden = false
        descL.html = b.getDesc()
        var cost = 0.0
        if G.bulkMode == 1 { cost = b.getSumCost(G.bulkBuy) }
        else if G.bulkMode == -1 && G.bulkBuy == 10000 { cost = b.getReverseSumCost(1000) }
        else if G.bulkMode == -1 { cost = b.getReverseSumCost(G.bulkBuy) }
        let red = G.bulkMode == 1 && (cost > G.cookies || cost == 0)
        dim.isHidden = !red
        buyButton.isUserInteractionEnabled = !red
        iconL.alpha = 1
        let c = red ? UIColor(css: "#bbb") : .white
        if descL.style.color != c { descL.style.color = c; nameL.style.color = c }
        let name = "\(b.amount) " + cap(b.getName(b.amount))
        if let s = b.style, G.season != "fools" { nameL.html = "<span style=\"\(s)\">\(name)</span>" } else { nameL.html = name }
        var str = G.bulkMode == -1 ? "Sell" : "Buy"
        str += " " + (G.bulkBuy == 10000 ? String(G.bulkMode == -1 ? b.amount : b.getBuyMax()) : String(G.bulkBuy))
        buyTextSize = Double(17 - str.count)
        buyText.html = "<span style=\"font-size:\(17 - str.count)px;\">\(str)</span>"
        setNeedsLayout()
        setCost(B(cost), red: red)
    }
}

/// .bar.upgrade
final class UpgradeRow: StoreRow {
    let u: Upgrade?
    let iconV = IconView()
    var onBought: (() -> Void)?
    init(_ u: Upgrade?) {
        self.u = u
        super.init(frame: .zero)
        if let u = u {
            iconV.icon = u.iconFunc?() ?? u.icon
            iconV.frame = CGRect(x: 0, y: 0, width: px(48), height: px(48))
            insertSubview(iconV, aboveSubview: dim)
            nameL.html = u.style.map { "<span style=\"\($0)\">\(u.name)</span>" } ?? u.name
            descL.html = UpgradeRow.barDesc(u.descFunc?(u) ?? u.desc)
            buyTextSize = 15
            var bt = buyText.style; bt.size = 15; buyText.style = bt
            buyText.html = "Buy"
            infoButton.onTap = { v in Anim.trigger(v, "plop"); UpgradeUI.showInfo(u) }
            buyButton.onTap = { [weak self] _ in
                if u.buy() {
                    PlaySound("snd/buy\(choose([1, 2, 3, 4])).mp3", 0.65)
                    self?.onBought?()
                }
            }
        } else {
            // "(No upgrades available! Check back later!)"
            infoButton.isHidden = true; buyButton.isHidden = true
            nameL.isHidden = true; descL.isHidden = true
            backgroundColor = UIColor(white: 0, alpha: 0.5)
            let l = RichLabel(TextStyle.base(11, color: .white))
            l.style.bold = true; l.style.align = .center; l.style.shadow = Shadows.bar
            l.html = "(No upgrades available!<br>Check back later!)"
            l.tag = 7
            addSubview(l)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        if let l = viewWithTag(7) { l.frame = CGRect(x: 0, y: px(13), width: bounds.width, height: px(24)) }
    }
    /// inside a bar: no quotes, no indents or lines in paragraphs, bold text in white
    static func barDesc(_ s: String) -> String {
        var t = s
        while let r = t.range(of: "<q>"), let e = t.range(of: "</q>", range: r.upperBound..<t.endIndex) { t.removeSubrange(r.lowerBound..<e.upperBound) }
        t = t.replacingOccurrences(of: "<line></line>", with: "")
        t = t.replacingOccurrences(of: "<p>", with: "<p style=\"text-indent:0px;\">")
        t = t.replacingOccurrences(of: "<b>", with: "<b style=\"color:#fff;\">")
        return t
    }
    /// G.Upgrade.prototype.redraw
    func redraw() {
        guard let u = u, u.owned == 0 else { return }
        let cost = u.getCost()
        let red = cost > G.cookies
        dim.isHidden = !red
        iconV.alpha = red ? 0.65 : 1
        buyButton.isUserInteractionEnabled = !red
        let c = red ? UIColor(css: "#bbb") : .white
        if descL.style.color != c { descL.style.color = c; nameL.style.color = c }
        setCost(B(cost), red: red)
    }
}
