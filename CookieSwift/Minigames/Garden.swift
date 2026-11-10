import UIKit

// Port of mods/minigames/minigameGarden.js (the desktop game's Garden), with the phone layout from
// mods/minigames/mobile.css and shim.js (only the unlocked part of the plot, tiles as big as the screen allows).

final class Plant {
    let key: String, name: String, icon: Int, cost: Double, costM: Double, ageTick: Double, ageTickR: Double
    let matureBase: Double
    var mature: Double
    let children: [String]
    let contam: Double
    let immortal: Bool, noContam: Bool, weed: Bool, fungus: Bool, plantable: Bool
    let detailsStr: String?, effsStr: String, q: String
    var id = 0
    var unlocked = false
    var onHarvest: ((Int, Int, Double) -> Void)?
    var onDie: ((Int, Int) -> Void)?
    var onKill: ((Int, Int, Double) -> Void)?
    init(_ key: String, _ name: String, icon: Int, cost: Double, costM: Double, ageTick: Double, ageTickR: Double, mature: Double, children: [String], contam: Double, flags: [String], details: String?, effs: String, q: String) {
        self.key = key; self.name = name; self.icon = icon; self.cost = cost; self.costM = costM; self.ageTick = ageTick; self.ageTickR = ageTickR
        self.mature = mature; matureBase = mature; self.children = children; self.contam = contam
        immortal = flags.contains("immortal"); noContam = flags.contains("noContam"); weed = flags.contains("weed"); fungus = flags.contains("fungus")
        plantable = !flags.contains("unplantable")
        detailsStr = details; effsStr = effs; self.q = q
    }
}

struct Soil { let key: String, name: String, icon: Int, tick: Double, effMult: Double, weedMult: Double, req: Int, effsStr: String, q: String }

final class Garden: Minigame {
    let parent: Building
    let name = "Garden"
    var plants: [Plant] = []
    var plantsBN: [String: Plant] = [:]
    var plantContam: [(String, Double)] = []
    var plantsUnlockedN = 0
    var plot: [[[Double]]] = Array(repeating: Array(repeating: [0, 0], count: 6), count: 6)
    var plotBoost: [[[Double]]] = Array(repeating: Array(repeating: [1, 1, 1], count: 6), count: 6)
    var seedSelected = -1
    var soil = 0
    var nextSoil = 0.0
    var stepT = 1.0
    var nextStep = 0.0
    var harvests = 0.0, harvestsTotal = 0.0
    var loopsMult = 1.0
    var toRebuild = false, toCompute = false
    var freeze = 0
    var nextFreeze = 0.0
    var convertTimes = 0.0
    var effs: [String: Double] = [:]
    /// the screen redraws the plot and the seeds
    var onRebuild: (() -> Void)?

    let soils: [Soil] = [
        Soil(key: "dirt", name: "Dirt", icon: 0, tick: 5, effMult: 1, weedMult: 1, req: 0, effsStr: "<div class=\"gray\">&bull; tick every <b>5 minutes</b></div>", q: "Simple, regular old dirt that you'd find in nature."),
        Soil(key: "fertilizer", name: "Fertilizer", icon: 1, tick: 3, effMult: 0.75, weedMult: 1.2, req: 50, effsStr: "<div class=\"gray\">&bull; tick every <b>3 minutes</b></div><div class=\"red\">&bull; passive plant effects <b>-25%</b></div><div class=\"red\">&bull; weed growth <b>+20%</b></div>", q: "Soil with a healthy helping of fresh manure. Plants grow faster but are less efficient."),
        Soil(key: "clay", name: "Clay", icon: 2, tick: 15, effMult: 1.25, weedMult: 1, req: 100, effsStr: "<div class=\"gray\">&bull; tick every <b>15 minutes</b></div><div class=\"green\">&bull; passive plant effects <b>+25%</b></div>", q: "Rich soil with very good water retention. Plants grow slower but are more efficient."),
        Soil(key: "pebbles", name: "Pebbles", icon: 3, tick: 5, effMult: 0.25, weedMult: 0.1, req: 200, effsStr: "<div class=\"gray\">&bull; tick every <b>5 minutes</b></div><div class=\"red\">&bull; passive plant effects <b>-75%</b></div><div class=\"green\">&bull; <b>35% chance</b> of collecting seeds automatically when plants expire</div><div class=\"green\">&bull; weed growth <b>-90%</b></div>", q: "Dry soil made of small rocks tightly packed together. Not very conducive to plant health, but whatever falls off your crops will be easy to retrieve.<br>Useful if you're one of those farmers who just want to find new seeds without having to tend their garden too much."),
        Soil(key: "woodchips", name: "Wood chips", icon: 4, tick: 5, effMult: 0.25, weedMult: 0.1, req: 300, effsStr: "<div class=\"gray\">&bull; tick every <b>5 minutes</b></div><div class=\"red\">&bull; passive plant effects <b>-75%</b></div><div class=\"green\">&bull; plants spread and mutate <b>3 times more</b></div><div class=\"green\">&bull; weed growth <b>-90%</b></div>", q: "Soil made of bits and pieces of bark and sawdust. Helpful for young sprouts to develop, not so much for mature plants."),
    ]
    struct Tool { let key: String, name: String, icon: Int }
    let tools = [Tool(key: "info", name: "Garden information", icon: 3), Tool(key: "harvestAll", name: "Harvest all", icon: 0),
                 Tool(key: "freeze", name: "Freeze", icon: 1), Tool(key: "convert", name: "Sacrifice garden", icon: 2)]
    let plotLimits: [[Int]] = [[2, 2, 4, 4], [2, 2, 5, 4], [2, 2, 5, 5], [1, 2, 5, 5], [1, 1, 5, 5], [1, 1, 6, 5], [1, 1, 6, 6], [0, 1, 6, 6], [0, 0, 6, 6]]

    init(_ b: Building) {
        parent = b
        buildPlants()
        for p in plants where p.contam > 0 { plantContam.append((p.key, p.contam)) }
    }

    private func pop(_ s: String) { Minigames.popup(s) }
    private func moneyHarvest(_ name: String, _ bank: Double, _ cps: Double) -> (Int, Int, Double) -> Void {
        return { [weak self] _, _, age in
            guard let self = self, let me = self.plantsBN[self.keyFor(name)], age >= me.mature else { return }
            let moni = min(G.cookies * bank, G.cookiesPs * cps)
            if moni != 0 { G.earn(moni); self.pop("(\(name))<br>+\(B(moni)) cookies!") }
        }
    }
    private func keyFor(_ name: String) -> String { plants.first { $0.name == name }?.key ?? "" }
    private func buildPlants() {
        func add(_ p: Plant) { p.id = plants.count; plants.append(p); plantsBN[p.key] = p }
        add(Plant("bakerWheat", "Baker's wheat", icon: 0, cost: 1, costM: 30, ageTick: 7, ageTickR: 2, mature: 35, children: ["bakerWheat","thumbcorn","cronerice","bakeberry","clover","goldenClover","chocoroot","tidygrass"], contam: 0, flags: [], details: nil, effs: "<div class=\"green\">&bull; CpS +1%</div>", q: "A plentiful crop whose hardy grain is used to make flour for pastries."))
        add(Plant("thumbcorn", "Thumbcorn", icon: 1, cost: 5, costM: 100, ageTick: 6, ageTickR: 2, mature: 20, children: ["bakerWheat","thumbcorn","cronerice","gildmillet","glovemorel"], contam: 0, flags: [], details: nil, effs: "<div class=\"green\">&bull; cookies/click +2%</div>", q: "A strangely-shaped variant of corn. The amount of strands that can sprout from one seed is usually in the single digits."))
        add(Plant("cronerice", "Cronerice", icon: 2, cost: 15, costM: 250, ageTick: 0.4, ageTickR: 0.7, mature: 55, children: ["thumbcorn","gildmillet","elderwort","wardlichen"], contam: 0, flags: [], details: nil, effs: "<div class=\"green\">&bull; grandma CpS +3%</div>", q: "Not only does this wrinkly bulb look nothing like rice, it's not even related to it either; its closest extant relative is the weeping willow."))
        add(Plant("gildmillet", "Gildmillet", icon: 3, cost: 15, costM: 1500, ageTick: 2, ageTickR: 1.5, mature: 40, children: ["clover","goldenClover","shimmerlily"], contam: 0, flags: [], details: nil, effs: "<div class=\"green\">&bull; golden cookie gains +1%</div><div class=\"green\">&bull; golden cookie effect duration +0.1%</div>", q: "An ancient staple crop, famed for its golden sheen. Was once used to bake birthday cakes for kings and queens of old."))
        add(Plant("clover", "Ordinary clover", icon: 4, cost: 25, costM: 77777, ageTick: 1, ageTickR: 1.5, mature: 35, children: ["goldenClover","greenRot","shimmerlily"], contam: 0, flags: [], details: nil, effs: "<div class=\"green\">&bull; golden cookie frequency +1%</div>", q: "<i>Trifolium repens</i>, a fairly mundane variety of clover with a tendency to produce four leaves. Such instances are considered lucky by some."))
        add(Plant("goldenClover", "Golden clover", icon: 5, cost: 125, costM: 777777777777, ageTick: 4, ageTickR: 12, mature: 50, children: [], contam: 0, flags: [], details: nil, effs: "<div class=\"green\">&bull; golden cookie frequency +3%</div>", q: "A variant of the ordinary clover that traded its chlorophyll for pure organic gold. Tragically short-lived, this herb is an evolutionary dead-end - but at least it looks pretty."))
        add(Plant("shimmerlily", "Shimmerlily", icon: 6, cost: 60, costM: 777777, ageTick: 5, ageTickR: 6, mature: 70, children: ["elderwort","whiskerbloom","chimerose","cheapcap"], contam: 0, flags: [], details: nil, effs: "<div class=\"green\">&bull; golden cookie gains +1%</div><div class=\"green\">&bull; golden cookie frequency +1%</div><div class=\"green\">&bull; random drops +1%</div>", q: "These little flowers are easiest to find at dawn, as the sunlight refracting in dew drops draws attention to their pure-white petals."))
        add(Plant("elderwort", "Elderwort", icon: 7, cost: 180, costM: 100000000, ageTick: 0.3, ageTickR: 0.5, mature: 90, children: ["everdaisy","ichorpuff","shriekbulb"], contam: 0, flags: ["immortal","noContam"], details: "Immortal", effs: "<div class=\"green\">&bull; wrath cookie gains +1%</div><div class=\"green\">&bull; wrath cookie frequency +1%</div><div class=\"green\">&bull; grandma CpS +1%</div><div class=\"green\">&bull; immortal</div><div class=\"gray\">&bull; surrounding plants (3x3) age 3% faster</div>", q: "A very old, long-forgotten subspecies of edelweiss that emits a strange, heady scent. There is some anecdotal evidence that these do not undergo molecular aging."))
        add(Plant("bakeberry", "Bakeberry", icon: 8, cost: 45, costM: 100000000, ageTick: 1, ageTickR: 1, mature: 50, children: ["queenbeet"], contam: 0, flags: [], details: nil, effs: "<div class=\"green\">&bull; CpS +1%</div><div class=\"green\">&bull; harvest when mature for +30 minutes of CpS (max. 3% of bank)</div>", q: "A favorite among cooks, this large berry has a crunchy brown exterior and a creamy red center. Excellent in pies or chicken stews."))
        add(Plant("chocoroot", "Chocoroot", icon: 9, cost: 15, costM: 100000, ageTick: 4, ageTickR: 0, mature: 25, children: ["whiteChocoroot","drowsyfern","queenbeet"], contam: 0, flags: [], details: "Predictable growth", effs: "<div class=\"green\">&bull; CpS +1%</div><div class=\"green\">&bull; harvest when mature for +3 minutes of CpS (max. 3% of bank)</div><div class=\"green\">&bull; predictable growth</div>", q: "A tangly bramble coated in a sticky, sweet substance. Unknown genetic ancestry. Children often pick these from fields as-is as a snack."))
        add(Plant("whiteChocoroot", "White chocoroot", icon: 10, cost: 15, costM: 100000, ageTick: 4, ageTickR: 0, mature: 25, children: ["whiskerbloom","tidygrass"], contam: 0, flags: [], details: "Predictable growth", effs: "<div class=\"green\">&bull; golden cookie gains +1%</div><div class=\"green\">&bull; harvest when mature for +3 minutes of CpS (max. 3% of bank)</div><div class=\"green\">&bull; predictable growth</div>", q: "A pale, even sweeter variant of the chocoroot. Often impedes travelers with its twisty branches."))
        add(Plant("whiteMildew", "White mildew", icon: 26, cost: 20, costM: 9999, ageTick: 8, ageTickR: 12, mature: 70, children: ["brownMold","whiteChocoroot","wardlichen","greenRot"], contam: 0, flags: ["fungus"], details: "Spreads easily", effs: "<div class=\"green\">&bull; CpS +1%</div><div class=\"gray\">&bull; may spread as Brown mold</div>", q: "A common rot that infests shady plots of earth. Grows in little creamy capsules. Smells sweet, but sadly wilts quickly."))
        add(Plant("brownMold", "Brown mold", icon: 27, cost: 20, costM: 9999, ageTick: 8, ageTickR: 12, mature: 70, children: ["whiteMildew","chocoroot","keenmoss","wrinklegill"], contam: 0, flags: ["fungus"], details: "Spreads easily", effs: "<div class=\"red\">&bull; CpS -1%</div><div class=\"gray\">&bull; may spread as White mildew</div>", q: "A common rot that infests shady plots of earth. Grows in odd reddish clumps. Smells bitter, but thankfully wilts quickly."))
        add(Plant("meddleweed", "Meddleweed", icon: 29, cost: 1, costM: 10, ageTick: 10, ageTickR: 6, mature: 50, children: ["meddleweed","brownMold","crumbspore"], contam: 0.05, flags: ["weed"], details: "Grows in empty tiles, spreads easily", effs: "<div class=\"red\">&bull; useless</div><div class=\"red\">&bull; may overtake nearby plants</div><div class=\"gray\">&bull; may sometimes drop spores when uprooted</div>", q: "The sign of a neglected farmland, this annoying weed spawns from unused dirt and may sometimes spread to other plants, killing them in the process."))
        add(Plant("whiskerbloom", "Whiskerbloom", icon: 11, cost: 20, costM: 1000000, ageTick: 2, ageTickR: 2, mature: 60, children: ["chimerose","nursetulip"], contam: 0, flags: [], details: nil, effs: "<div class=\"green\">&bull; milk effects +0.2%</div>", q: "Squeezing the translucent pods makes them excrete a milky liquid, while producing a faint squeak akin to a cat's meow."))
        add(Plant("chimerose", "Chimerose", icon: 12, cost: 15, costM: 242424, ageTick: 1, ageTickR: 1.5, mature: 30, children: ["chimerose"], contam: 0, flags: [], details: nil, effs: "<div class=\"green\">&bull; reindeer gains +1%</div><div class=\"green\">&bull; reindeer frequency +1%</div>", q: "Originating in the greener flanks of polar mountains, this beautiful flower with golden accents is fragrant enough to make any room feel a little bit more festive."))
        add(Plant("nursetulip", "Nursetulip", icon: 13, cost: 40, costM: 1000000000, ageTick: 0.5, ageTickR: 2, mature: 60, children: [], contam: 0, flags: [], details: nil, effs: "<div class=\"green\">&bull; surrounding plants (3x3) are 20% more efficient</div><div class=\"red\">&bull; CpS -2%</div>", q: "This flower grows an intricate root network that distributes nutrients throughout the surrounding soil. The reason for this seemingly altruistic behavior is still unknown."))
        add(Plant("drowsyfern", "Drowsyfern", icon: 14, cost: 90, costM: 100000, ageTick: 0.05, ageTickR: 0.1, mature: 30, children: [], contam: 0, flags: [], details: nil, effs: "<div class=\"green\">&bull; CpS +3%</div><div class=\"red\">&bull; cookies/click -5%</div><div class=\"red\">&bull; golden cookie frequency -10%</div>", q: "Traditionally used to brew a tea that guarantees a good night of sleep."))
        add(Plant("wardlichen", "Wardlichen", icon: 15, cost: 10, costM: 10000, ageTick: 5, ageTickR: 4, mature: 65, children: ["wardlichen"], contam: 0, flags: [], details: nil, effs: "<div class=\"gray\">&bull; wrath cookie frequency -2%</div><div class=\"gray\">&bull; wrinkler spawn rate -15%</div>", q: "The metallic stench that emanates from this organism has been known to keep insects and slugs away."))
        add(Plant("keenmoss", "Keenmoss", icon: 16, cost: 50, costM: 1000000, ageTick: 4, ageTickR: 5, mature: 65, children: ["drowsyfern","wardlichen","keenmoss"], contam: 0, flags: [], details: nil, effs: "<div class=\"green\">&bull; random drops +3%</div>", q: "Fuzzy to the touch and of a vibrant green. In plant symbolism, keenmoss is associated with good luck for finding lost objects."))
        add(Plant("queenbeet", "Queenbeet", icon: 17, cost: 90, costM: 1000000000, ageTick: 1, ageTickR: 0.4, mature: 80, children: ["duketater","queenbeetLump","shriekbulb"], contam: 0, flags: ["noContam"], details: nil, effs: "<div class=\"green\">&bull; golden cookie effect duration +0.3%</div><div class=\"red\">&bull; CpS -2%</div><div class=\"green\">&bull; harvest when mature for +1 hour of CpS (max. 4% of bank)</div>", q: "A delicious taproot used to prepare high-grade white sugar. Entire countries once went to war over these."))
        add(Plant("queenbeetLump", "Juicy queenbeet", icon: 18, cost: 120, costM: 1000000000000, ageTick: 0.04, ageTickR: 0.08, mature: 85, children: [], contam: 0, flags: ["noContam","unplantable"], details: nil, effs: "<div class=\"red\">&bull; CpS -10%</div><div class=\"red\">&bull; surrounding plants (3x3) are 20% less efficient</div><div class=\"green\">&bull; harvest when mature for a sugar lump</div>", q: "A delicious taproot used to prepare high-grade white sugar. Entire countries once went to war over these.<br>It looks like this one has grown especially sweeter and juicier from growing in close proximity to other queenbeets."))
        add(Plant("duketater", "Duketater", icon: 19, cost: 480, costM: 1000000000000, ageTick: 0.4, ageTickR: 0.1, mature: 95, children: ["shriekbulb"], contam: 0, flags: ["noContam"], details: nil, effs: "<div class=\"green\">&bull; harvest when mature for +2 hours of CpS (max. 8% of bank)</div>", q: "A rare, rich-tasting tuber fit for a whole meal, as long as its strict harvesting schedule is respected. Its starch has fascinating baking properties."))
        add(Plant("crumbspore", "Crumbspore", icon: 20, cost: 10, costM: 999, ageTick: 3, ageTickR: 3, mature: 65, children: ["crumbspore","glovemorel","cheapcap","doughshroom","wrinklegill","ichorpuff"], contam: 0.03, flags: ["noContam","fungus"], details: "Spreads easily", effs: "<div class=\"green\">&bull; explodes into up to 1 minute of CpS at the end of its lifecycle (max. 1% of bank)</div><div class=\"red\">&bull; may overtake nearby plants</div>", q: "An archaic mold that spreads its spores to the surrounding dirt through simple pod explosion."))
        add(Plant("doughshroom", "Doughshroom", icon: 24, cost: 100, costM: 100000000, ageTick: 1, ageTickR: 2, mature: 85, children: ["crumbspore","doughshroom","foolBolete","shriekbulb"], contam: 0.03, flags: ["noContam","fungus"], details: "Spreads easily", effs: "<div class=\"green\">&bull; explodes into up to 5 minutes of CpS at the end of its lifecycle (max. 3% of bank)</div><div class=\"red\">&bull; may overtake nearby plants</div>", q: "Jammed full of warm spores; some forest walkers often describe the smell as similar to passing by a bakery."))
        add(Plant("glovemorel", "Glovemorel", icon: 21, cost: 30, costM: 10000, ageTick: 3, ageTickR: 18, mature: 80, children: [], contam: 0, flags: ["fungus"], details: nil, effs: "<div class=\"green\">&bull; cookies/click +4%</div><div class=\"green\">&bull; cursor CpS +1%</div><div class=\"red\">&bull; CpS -1%</div>", q: "Touching its waxy skin reveals that the interior is hollow and uncomfortably squishy."))
        add(Plant("cheapcap", "Cheapcap", icon: 22, cost: 40, costM: 100000, ageTick: 6, ageTickR: 16, mature: 40, children: [], contam: 0, flags: ["fungus"], details: nil, effs: "<div class=\"green\">&bull; buildings and upgrades are 0.2% cheaper</div><div class=\"red\">&bull; cannot handle cold climates; 15% chance to die when frozen</div>", q: "Small, tough, and good in omelettes. Some historians propose that the heads of dried cheapcaps were once used as currency in some bronze age societies."))
        add(Plant("foolBolete", "Fool's bolete", icon: 23, cost: 15, costM: 10000, ageTick: 5, ageTickR: 25, mature: 50, children: [], contam: 0, flags: ["fungus"], details: nil, effs: "<div class=\"green\">&bull; golden cookie frequency +2%</div><div class=\"red\">&bull; golden cookie gains -5%</div><div class=\"red\">&bull; golden cookie duration -2%</div><div class=\"red\">&bull; golden cookie effect duration -2%</div>", q: "Named for its ability to fool mushroom pickers. The fool's bolete is not actually poisonous, it's just extremely bland."))
        add(Plant("wrinklegill", "Wrinklegill", icon: 25, cost: 20, costM: 1000000, ageTick: 1, ageTickR: 3, mature: 65, children: ["elderwort","shriekbulb"], contam: 0, flags: ["fungus"], details: nil, effs: "<div class=\"gray\">&bull; wrinkler spawn rate +2%</div><div class=\"gray\">&bull; wrinkler appetite +1%</div>", q: "This mushroom's odor resembles that of a well-done steak, and is said to whet the appetite - making one's stomach start gurgling within seconds."))
        add(Plant("greenRot", "Green rot", icon: 28, cost: 60, costM: 1000000, ageTick: 12, ageTickR: 13, mature: 65, children: ["keenmoss","foolBolete"], contam: 0, flags: ["fungus"], details: nil, effs: "<div class=\"green\">&bull; golden cookie duration +0.5%</div><div class=\"green\">&bull; golden cookie frequency +1%</div><div class=\"green\">&bull; random drops +1%</div>", q: "This short-lived mold is also known as \"emerald pebbles\", and is considered by some as a pseudo-gem that symbolizes good fortune."))
        add(Plant("shriekbulb", "Shriekbulb", icon: 30, cost: 60, costM: 4444444444444, ageTick: 3, ageTickR: 1, mature: 60, children: ["shriekbulb"], contam: 0, flags: ["noContam"], details: "The unfortunate result of some plant combinations", effs: "<div class=\"red\">&bull; CpS -2%</div><div class=\"red\">&bull; surrounding plants (3x3) are 5% less efficient</div>", q: "A nasty vegetable with a dreadful quirk : its flesh resonates with a high-pitched howl whenever it is hit at the right angle by sunlight, moonlight, or even a slight breeze."))
        add(Plant("tidygrass", "Tidygrass", icon: 31, cost: 90, costM: 100000000000000, ageTick: 0.5, ageTickR: 0, mature: 40, children: ["everdaisy"], contam: 0, flags: [], details: nil, effs: "<div class=\"green\">&bull; surrounding tiles (5x5) develop no weeds or fungus</div>", q: "The molecules this grass emits are a natural weedkiller. Its stems grow following a predictable pattern, making it an interesting -if expensive- choice for a lawn grass."))
        add(Plant("everdaisy", "Everdaisy", icon: 32, cost: 180, costM: 100000000000000000000, ageTick: 0.3, ageTickR: 0, mature: 75, children: [], contam: 0, flags: ["immortal","noContam"], details: "Immortal", effs: "<div class=\"green\">&bull; surrounding tiles (3x3) develop no weeds or fungus</div><div class=\"green\">&bull; immortal</div>", q: "While promoted by some as a superfood owing to its association with longevity and intriguing geometry, this elusive flower is actually mildly toxic."))
        add(Plant("ichorpuff", "Ichorpuff", icon: 33, cost: 120, costM: 987654321, ageTick: 1, ageTickR: 1.5, mature: 35, children: [], contam: 0, flags: ["fungus"], details: nil, effs: "<div class=\"green\">&bull; surrounding plants (3x3) age 50% slower</div><div class=\"red\">&bull; surrounding plants (3x3) are 50% less efficient</div>", q: "This puffball mushroom contains sugary spores, but it never seems to mature to bursting on its own. Surrounding plants under its influence have a very slow metabolism, reducing their effects but lengthening their lifespan."))
        func drop(_ key: String, _ up: String, _ rate: Double) {
            plantsBN[key]?.onHarvest = { [weak self] _, _, age in
                guard let self = self, let me = self.plantsBN[key], age >= me.mature else { return }
                self.dropUpgrade(up, rate)
            }
        }
        drop("bakerWheat", "Wheat slims", 0.001)
        drop("elderwort", "Elderwort biscuits", 0.01)
        drop("drowsyfern", "Fern tea", 0.01)
        drop("greenRot", "Green yeast digestives", 0.005)
        drop("ichorpuff", "Ichor syrup", 0.005)
        let bake = moneyHarvest("Bakeberry", 0.03, 60 * 30)
        plantsBN["bakeberry"]?.onHarvest = { [weak self] x, y, age in
            bake(x, y, age)
            if let self = self, age >= self.plantsBN["bakeberry"]!.mature { self.dropUpgrade("Bakeberry cookies", 0.015) }
        }
        plantsBN["chocoroot"]?.onHarvest = moneyHarvest("Chocoroot", 0.03, 60 * 3)
        plantsBN["whiteChocoroot"]?.onHarvest = moneyHarvest("White chocoroot", 0.03, 60 * 3)
        plantsBN["queenbeet"]?.onHarvest = moneyHarvest("Queenbeet", 0.04, 60 * 60)
        let duke = moneyHarvest("Duketater", 0.08, 60 * 60 * 2)
        plantsBN["duketater"]?.onHarvest = { [weak self] x, y, age in
            duke(x, y, age)
            if let self = self, age >= self.plantsBN["duketater"]!.mature { self.dropUpgrade("Duketater cookies", 0.005) }
        }
        plantsBN["queenbeetLump"]?.onHarvest = { [weak self] _, _, age in
            guard let self = self, age >= self.plantsBN["queenbeetLump"]!.mature else { return }
            Lumps.gainLumps(1)
            self.pop("(Juicy queenbeet)<br>Sweet!<div style=\"font-size:65%;\">Found 1 sugar lump!</div>")
        }
        plantsBN["meddleweed"]?.onKill = { [weak self] x, y, age in
            guard let self = self else { return }
            if JSMath.random() < 0.2 * (age / 100) { self.plot[y][x] = [Double(self.plantsBN[choose(["brownMold", "crumbspore"])]!.id + 1), 0] }
        }
        plantsBN["crumbspore"]?.onDie = { [weak self] _, _ in
            let moni = min(G.cookies * 0.01, G.cookiesPs * 60) * JSMath.random()
            if moni != 0 { G.earn(moni); self?.pop("(Crumbspore)<br>+\(B(moni)) cookies!") }
        }
        plantsBN["doughshroom"]?.onDie = { [weak self] _, _ in
            let moni = min(G.cookies * 0.03, G.cookiesPs * 60 * 5) * JSMath.random()
            if moni != 0 { G.earn(moni); self?.pop("(Doughshroom)<br>+\(B(moni)) cookies!") }
        }
    }

    // MARK: rules
    var plantsN: Int { plants.count }
    @discardableResult
    func getUnlockedN() -> Int {
        plantsUnlockedN = plants.filter { $0.unlocked }.count
        if plantsUnlockedN >= plantsN { G.win("Keeper of the conservatory") }
        return plantsUnlockedN
    }
    func dropUpgrade(_ upgrade: String, _ rate: Double) {
        if G.upgradesBN[upgrade] != nil && !G.Has(upgrade) && JSMath.random() <= rate * G.dropRateMult() * (G.HasAchiev("Seedless to nay") ? 1.05 : 1) {
            G.unlock(upgrade)
        }
    }
    func computeMatures() {
        let mult = G.HasAchiev("Seedless to nay") ? 0.95 : 1
        for p in plants { p.mature = p.matureBase * mult }
    }
    func stage(_ tile: [Double], _ me: Plant) -> Int {
        if tile[1] >= me.mature { return 4 }
        if tile[1] >= me.mature * 0.666 { return 3 }
        if tile[1] >= me.mature * 0.333 { return 2 }
        return 1
    }
    func getMuts(_ neighs: [String: Int], _ neighsM: [String: Int]) -> [(String, Double)] {
        func n(_ k: String) -> Int { neighs[k] ?? 0 }
        func m(_ k: String) -> Int { neighsM[k] ?? 0 }
        var muts: [(String, Double)] = []
        if m("bakerWheat") >= 2 { muts += [("bakerWheat", 0.2), ("thumbcorn", 0.05), ("bakeberry", 0.001)] }
        if m("bakerWheat") >= 1 && m("thumbcorn") >= 1 { muts.append(("cronerice", 0.01)) }
        if m("thumbcorn") >= 2 { muts += [("thumbcorn", 0.1), ("bakerWheat", 0.05)] }
        if m("cronerice") >= 1 && m("thumbcorn") >= 1 { muts.append(("gildmillet", 0.03)) }
        if m("cronerice") >= 2 { muts.append(("thumbcorn", 0.02)) }
        if m("bakerWheat") >= 1 && m("gildmillet") >= 1 { muts += [("clover", 0.03), ("goldenClover", 0.0007)] }
        if m("clover") >= 1 && m("gildmillet") >= 1 { muts.append(("shimmerlily", 0.02)) }
        if m("clover") >= 2 && n("clover") < 5 { muts += [("clover", 0.007), ("goldenClover", 0.0001)] }
        if m("clover") >= 4 { muts.append(("goldenClover", 0.0007)) }
        if m("shimmerlily") >= 1 && m("cronerice") >= 1 { muts.append(("elderwort", 0.01)) }
        if m("wrinklegill") >= 1 && m("cronerice") >= 1 { muts.append(("elderwort", 0.002)) }
        if m("bakerWheat") >= 1 && n("brownMold") >= 1 { muts.append(("chocoroot", 0.1)) }
        if m("chocoroot") >= 1 && n("whiteMildew") >= 1 { muts.append(("whiteChocoroot", 0.1)) }
        if m("whiteMildew") >= 1 && n("brownMold") <= 1 { muts.append(("brownMold", 0.5)) }
        if m("brownMold") >= 1 && n("whiteMildew") <= 1 { muts.append(("whiteMildew", 0.5)) }
        if m("meddleweed") >= 1 && n("meddleweed") <= 3 { muts.append(("meddleweed", 0.15)) }

        if m("shimmerlily") >= 1 && m("whiteChocoroot") >= 1 { muts.append(("whiskerbloom", 0.01)) }
        if m("shimmerlily") >= 1 && m("whiskerbloom") >= 1 { muts.append(("chimerose", 0.05)) }
        if m("chimerose") >= 2 { muts.append(("chimerose", 0.005)) }
        if m("whiskerbloom") >= 2 { muts.append(("nursetulip", 0.05)) }
        if m("chocoroot") >= 1 && m("keenmoss") >= 1 { muts.append(("drowsyfern", 0.005)) }
        if (m("cronerice") >= 1 && m("keenmoss") >= 1) || (m("cronerice") >= 1 && m("whiteMildew") >= 1) { muts.append(("wardlichen", 0.005)) }
        if m("wardlichen") >= 1 && n("wardlichen") < 2 { muts.append(("wardlichen", 0.05)) }
        if m("greenRot") >= 1 && m("brownMold") >= 1 { muts.append(("keenmoss", 0.1)) }
        if m("keenmoss") >= 1 && n("keenmoss") < 2 { muts.append(("keenmoss", 0.05)) }
        if m("chocoroot") >= 1 && m("bakeberry") >= 1 { muts.append(("queenbeet", 0.01)) }
        if m("queenbeet") >= 8 { muts.append(("queenbeetLump", 0.001)) }
        if m("queenbeet") >= 2 { muts.append(("duketater", 0.001)) }

        if m("crumbspore") >= 1 && n("crumbspore") <= 1 { muts.append(("crumbspore", 0.07)) }
        if m("crumbspore") >= 1 && m("thumbcorn") >= 1 { muts.append(("glovemorel", 0.02)) }
        if m("crumbspore") >= 1 && m("shimmerlily") >= 1 { muts.append(("cheapcap", 0.04)) }
        if m("doughshroom") >= 1 && m("greenRot") >= 1 { muts.append(("foolBolete", 0.04)) }
        if m("crumbspore") >= 2 { muts.append(("doughshroom", 0.005)) }
        if m("doughshroom") >= 1 && n("doughshroom") <= 1 { muts.append(("doughshroom", 0.07)) }
        if m("doughshroom") >= 2 { muts.append(("crumbspore", 0.005)) }
        if m("crumbspore") >= 1 && m("brownMold") >= 1 { muts.append(("wrinklegill", 0.06)) }
        if m("whiteMildew") >= 1 && m("clover") >= 1 { muts.append(("greenRot", 0.05)) }

        if m("wrinklegill") >= 1 && m("elderwort") >= 1 { muts.append(("shriekbulb", 0.001)) }
        if m("elderwort") >= 5 { muts.append(("shriekbulb", 0.001)) }
        if n("duketater") >= 3 { muts.append(("shriekbulb", 0.005)) }
        if n("doughshroom") >= 4 { muts.append(("shriekbulb", 0.002)) }
        if m("queenbeet") >= 5 { muts.append(("shriekbulb", 0.001)) }
        if n("shriekbulb") >= 1 && n("shriekbulb") < 2 { muts.append(("shriekbulb", 0.005)) }

        if m("bakerWheat") >= 1 && m("whiteChocoroot") >= 1 { muts.append(("tidygrass", 0.002)) }
        if m("tidygrass") >= 3 && m("elderwort") >= 3 { muts.append(("everdaisy", 0.002)) }
        if m("elderwort") >= 1 && m("crumbspore") >= 1 { muts.append(("ichorpuff", 0.002)) }
        return muts
    }
    func computeBoostPlot() {
        for y in 0..<6 { for x in 0..<6 { plotBoost[y][x] = [1, 1, 1] } }
        func effectOn(_ X: Int, _ Y: Int, _ s: Int, _ mult: [Double]) {
            for y in max(0, Y - s)..<min(6, Y + s + 1) {
                for x in max(0, X - s)..<min(6, X + s + 1) where !(X == x && Y == y) {
                    for i in 0..<mult.count { plotBoost[y][x][i] *= mult[i] }
                }
            }
        }
        for y in 0..<6 {
            for x in 0..<6 {
                let tile = plot[y][x]
                guard tile[0] > 0 else { continue }
                let me = plants[Int(tile[0]) - 1]
                let st = stage(tile, me)
                var mult = soils[soil].effMult
                mult *= [0, 0.1, 0.25, 0.5, 1][st]
                var ageMult = 1.0, powerMult = 1.0, weedMult = 1.0
                var range = 0
                switch me.key {
                case "elderwort": ageMult = 1.03; range = 1
                case "queenbeetLump": powerMult = 0.8; range = 1
                case "nursetulip": powerMult = 1.2; range = 1
                case "shriekbulb": powerMult = 0.95; range = 1
                case "tidygrass": weedMult = 0; range = 2
                case "everdaisy": weedMult = 0; range = 1
                case "ichorpuff": ageMult = 0.5; powerMult = 0.5; range = 1
                default: break
                }
                if ageMult >= 1 { ageMult = (ageMult - 1) * mult + 1 } else if mult >= 1 { ageMult = 1 / ((1 / ageMult) * mult) } else { ageMult = 1 - (1 - ageMult) * mult }
                if powerMult >= 1 { powerMult = (powerMult - 1) * mult + 1 } else if mult >= 1 { powerMult = 1 / ((1 / powerMult) * mult) } else { powerMult = 1 - (1 - powerMult) * mult }
                if range > 0 { effectOn(x, y, range, [ageMult, powerMult, weedMult]) }
            }
        }
    }
    static let effKeys = ["cps", "click", "cursorCps", "grandmaCps", "goldenCookieGain", "goldenCookieFreq", "goldenCookieDur", "goldenCookieEffDur",
                          "wrathCookieGain", "wrathCookieFreq", "wrathCookieDur", "wrathCookieEffDur", "reindeerGain", "reindeerFreq", "reindeerDur",
                          "itemDrops", "milk", "wrinklerSpawn", "wrinklerEat", "upgradeCost", "buildingCost"]
    func computeEffs() {
        toCompute = false
        var e: [String: Double] = [:]
        for k in Garden.effKeys { e[k] = 1 }
        if freeze == 0 {
            let soilMult = soils[soil].effMult
            for y in 0..<6 {
                for x in 0..<6 {
                    let tile = plot[y][x]
                    guard tile[0] > 0 else { continue }
                    let me = plants[Int(tile[0]) - 1]
                    var mult = soilMult * [0, 0.1, 0.25, 0.5, 1][stage(tile, me)]
                    mult *= plotBoost[y][x][1]
                    func add(_ k: String, _ v: Double) { e[k]! += v * mult }
                    func mul(_ k: String, _ v: Double) { e[k]! *= 1 - v * mult }
                    switch me.key {
                    case "bakerWheat": add("cps", 0.01)
                    case "thumbcorn": add("click", 0.02)
                    case "cronerice": add("grandmaCps", 0.03)
                    case "gildmillet": add("goldenCookieGain", 0.01); add("goldenCookieEffDur", 0.001)
                    case "clover": add("goldenCookieFreq", 0.01)
                    case "goldenClover": add("goldenCookieFreq", 0.03)
                    case "shimmerlily": add("goldenCookieGain", 0.01); add("goldenCookieFreq", 0.01); add("itemDrops", 0.01)
                    case "elderwort": add("wrathCookieGain", 0.01); add("wrathCookieFreq", 0.01); add("grandmaCps", 0.01)
                    case "bakeberry": add("cps", 0.01)
                    case "chocoroot": add("cps", 0.01)
                    case "whiteChocoroot": add("goldenCookieGain", 0.01)
                    case "whiteMildew": add("cps", 0.01)
                    case "brownMold": mul("cps", 0.01)
                    case "meddleweed": break
                    case "whiskerbloom": add("milk", 0.002)
                    case "chimerose": add("reindeerGain", 0.01); add("reindeerFreq", 0.01)
                    case "nursetulip": mul("cps", 0.02)
                    case "drowsyfern": add("cps", 0.03); mul("click", 0.05); mul("goldenCookieFreq", 0.1)
                    case "wardlichen": mul("wrinklerSpawn", 0.15); mul("wrathCookieFreq", 0.02)
                    case "keenmoss": add("itemDrops", 0.03)
                    case "queenbeet": add("goldenCookieEffDur", 0.003); mul("cps", 0.02)
                    case "queenbeetLump": mul("cps", 0.1)
                    case "glovemorel": add("click", 0.04); add("cursorCps", 0.01); mul("cps", 0.01)
                    case "cheapcap": mul("upgradeCost", 0.002); mul("buildingCost", 0.002)
                    case "foolBolete": add("goldenCookieFreq", 0.02); mul("goldenCookieGain", 0.05); mul("goldenCookieDur", 0.02); mul("goldenCookieEffDur", 0.02)
                    case "wrinklegill": add("wrinklerSpawn", 0.02); add("wrinklerEat", 0.01)
                    case "greenRot": add("goldenCookieDur", 0.005); add("goldenCookieFreq", 0.01); add("itemDrops", 0.01)
                    case "shriekbulb": mul("cps", 0.02)
                    default: break
                    }
                }
            }
        }
        effs = e
        G.refreshCps = true
    }
    var turbo: Bool { G.Has("Turbo-charged soil") }
    func getCost(_ me: Plant) -> Double {
        if turbo { return 0 }
        return max(me.costM, G.cookiesPs * me.cost * 60) * (G.HasAchiev("Seedless to nay") ? 0.95 : 1)
    }
    func canPlant(_ me: Plant) -> Bool { G.cookies >= getCost(me) }
    var level: Int { max(1, min(plotLimits.count, parent.level)) - 1 }
    func isTileUnlocked(_ x: Int, _ y: Int) -> Bool {
        let l = plotLimits[level]
        return x >= l[0] && x < l[2] && y >= l[1] && y < l[3]
    }
    func getTile(_ x: Int, _ y: Int) -> [Double] {
        if x < 0 || x > 5 || y < 0 || y > 5 || !isTileUnlocked(x, y) { return [0, 0] }
        return plot[y][x]
    }
    func computeStepT() { stepT = turbo ? 1 : soils[soil].tick * 60 }

    func clickTile(_ x: Int, _ y: Int) {
        let outcome = useTool(seedSelected, x, y)
        toCompute = true
        if outcome { seedSelected = -1 }
        onRebuild?()
    }
    func useTool(_ what: Int, _ x: Int, _ y: Int) -> Bool {
        if harvest(x, y, manual: true) {
            PlaySound("snd/harvest\(choose(["1", "2", "3"])).mp3", 1)
        } else if what >= 0 && canPlant(plants[what]) {
            plot[y][x] = [Double(what + 1), 0]
            toRebuild = true
            G.spend(getCost(plants[what]))
            PlaySound("snd/tillb\(choose(["1", "2", "3"])).mp3", 1)
            return true
        }
        return false
    }
    @discardableResult
    func harvest(_ x: Int, _ y: Int, manual: Bool = false) -> Bool {
        let tile = plot[y][x]
        guard tile[0] >= 1 else { return false }
        toCompute = true
        let me = plants[Int(tile[0]) - 1]
        let age = tile[1]
        me.onHarvest?(x, y, age)
        if tile[1] >= me.mature {
            if unlockSeed(me) { pop("(\(me.name))<br>Unlocked \(me.name) seed.") }
            harvests += 1
            harvestsTotal += 1
            if harvestsTotal >= 100 { G.win("Botany enthusiast") }
            if harvestsTotal >= 1000 { G.win("Green, aching thumb") }
        }
        plot[y][x] = [0, 0]
        me.onKill?(x, y, age)
        toRebuild = true
        return true
    }
    func harvestAll(_ type: Plant? = nil, mature: Bool = false, mortal: Bool = false) {
        var harvested = 0
        for _ in 0..<2 {
            for y in 0..<6 {
                for x in 0..<6 where plot[y][x][0] >= 1 {
                    let tile = plot[y][x]
                    let me = plants[Int(tile[0]) - 1]
                    var doIt = true
                    if let t = type, t !== me { doIt = false }
                    if mortal && me.immortal { doIt = false }
                    if mature && tile[1] < me.mature { doIt = false }
                    if doIt && harvest(x, y) { harvested += 1 }
                }
            }
        }
        if harvested > 0 { DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { PlaySound("snd/harvest1.mp3", 1) } }
        if harvested > 2 { DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { PlaySound("snd/harvest2.mp3", 1) } }
        if harvested > 6 { DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { PlaySound("snd/harvest3.mp3", 1) } }
        onRebuild?()
    }
    @discardableResult
    func unlockSeed(_ me: Plant) -> Bool {
        if me.unlocked { return false }
        me.unlocked = true
        getUnlockedN()
        onRebuild?()
        return true
    }
    func lockSeed(_ me: Plant) {
        me.unlocked = false
        getUnlockedN()
    }
    func toggleFreeze() {
        PlaySound("snd/toneTick.mp3", 1)
        freeze = freeze != 0 ? 0 : 1
        computeEffs()
        if freeze != 0 {
            PlaySound("snd/freezeGarden.mp3", 1)
            for y in 0..<6 {
                for x in 0..<6 {
                    let tile = plot[y][x]
                    guard tile[0] > 0 else { continue }
                    let me = plants[Int(tile[0]) - 1]
                    if me.key == "cheapcap" && JSMath.random() < 0.15 {
                        plot[y][x] = [0, 0]
                        me.onKill?(x, y, tile[1])
                        toRebuild = true
                    }
                }
            }
        }
        onRebuild?()
    }
    func setSoil(_ id: Int) {
        if freeze != 0 || soil == id || nextSoil > nowMs() || parent.amount < soils[id].req { return }
        PlaySound("snd/toneTick.mp3", 1)
        nextSoil = nowMs() + (turbo ? 1 : 1000 * 60 * 10)
        toCompute = true
        soil = id
        computeStepT()
        onRebuild?()
    }
    func askConvert() {
        if plantsUnlockedN < plantsN { return }
        MinigameWindow.current?.prompt("<h3>Sacrifice garden</h3><div class=\"block\">Do you REALLY want to sacrifice your garden to the sugar hornets?<br><small>You will be left with an empty plot and only the Baker's wheat seed unlocked.<br>In return, you will gain <b>10 sugar lumps</b>.</small></div>",
                                       options: [("Yes", { [weak self] in self?.convert() }), ("No", nil)])
    }
    func convert() {
        if plantsUnlockedN < plantsN { return }
        harvestAll()
        for p in plants { lockSeed(p) }
        unlockSeed(plantsBN["bakerWheat"]!)
        Lumps.gainLumps(10)
        G.toast("Sacrifice!", "You've sacrificed your garden to the sugar hornets, destroying your crops and your knowledge of seeds.<br>In the remains, you find <b>10 sugar lumps</b>.", [29, 14])
        seedSelected = -1
        G.win("Seedless to nay")
        convertTimes += 1
        computeMatures()
        PlaySound("snd/spellFail.mp3", 0.75)
        onRebuild?()
    }
    func refill() {
        guard G.lumps >= 1, G.lumpRefill <= 0 else { return }
        Minigames.spendLump(1, "refill") { [weak self] in
            guard let self = self else { return }
            G.lumpRefill = G.fps * 60 * 15
            self.loopsMult = 3
            self.nextSoil = nowMs()
            self.nextStep = nowMs()
            PlaySound("snd/pop\(Int(JSMath.random() * 3 + 1)).mp3", 0.75)
        }
    }

    // MARK: tooltips
    private func gardenIcon(_ x: Int, _ y: Int) -> String {
        "<span class=\"tinyIcon\" style=\"background:url(mgimg/gardenPlants.png);background-position:\(-x * 48)px \(-y * 48)px;\"></span>"
    }
    func getPlantDesc(_ me: Plant) -> String {
        var children = ""
        for c in me.children {
            guard let it = plantsBN[c] else { continue }
            children += it.unlocked ? gardenIcon(0, it.icon) + " " : "<span class=\"tinyIcon\" style=\"background-position:0px \(-7 * 48)px;opacity:0.35;\"></span> "
        }
        let dragonBoost = 1 / (1 + 0.05 * G.auraMult("Supreme Intellect"))
        let avg = me.ageTick + me.ageTickR / 2
        var s = ""
        if !me.immortal {
            s += "<div style=\"margin:6px 0px;font-size:11px;\"><b>Average lifespan:</b> \(Loc.sayTime(((100 / avg) * dragonBoost * stepT) * 30, -1)) <small>(\(Loc.n((100 / (avg / dragonBoost)).rounded(.up), "tick", "ticks")))</small></div>"
        }
        s += "<div style=\"margin:6px 0px;font-size:11px;\"><b>Average maturation:</b> \(Loc.sayTime(((100 / avg) * (me.mature / 100) * dragonBoost * stepT) * 30, -1)) <small>(\(Loc.n(((100 / (avg / dragonBoost)) * (me.mature / 100)).rounded(.up), "tick", "ticks")))</small></div>"
        if me.weed { s += "<div style=\"margin:6px 0px;font-size:11px;\"><b>Is a weed</b></div>" }
        if me.fungus { s += "<div style=\"margin:6px 0px;font-size:11px;\"><b>Is a fungus</b></div>" }
        if let d = me.detailsStr { s += "<div style=\"margin:6px 0px;font-size:11px;\"><b>Details:</b> \(d)</div>" }
        if !children.isEmpty { s += "<div style=\"margin:6px 0px;font-size:11px;\"><b>Possible mutations:</b> \(children)</div>" }
        s += "<line></line><div style=\"margin:6px 0px;\"><b>Effects:</b> <span style=\"font-size:11px;\">(while plant is alive; scales with plant growth)</span></div>"
        s += "<div style=\"font-size:11px;font-weight:bold;\">\(me.effsStr)</div>"
        s += "<q>\(me.q)</q>"
        return s
    }
    private func name(_ s: String) -> String { "<div style=\"padding-left:44px;font-size:15px;font-weight:bold;color:#fff;\">\(s)</div>" }
    private func small(_ s: String) -> String { "<div style=\"padding-left:44px;\"><small>\(s)</small></div>" }
    func seedTooltip(_ id: Int) -> (String, [Int]?) {
        let me = plants[id]
        var s = name("\(me.name) seed")
        s += small((me.plantable ? "Click to select this seed for planting." : "<span class=\"red\">This seed cannot be planted.</span>"))
        if me.plantable {
            s += "<div style=\"padding-left:44px;\"><small>Planting cost:</small> <b style=\"color:\(canPlant(me) ? "#fff" : "#f66");\"><span class=\"tinyCookie\"></span>\(B(getCost(me).rounded()))</b> <small>(\(Loc.sayTime(me.cost * 60 * 30, -1)) of CpS, minimum \(Loc.cookies(me.costM)))</small></div>"
        }
        s += "<line></line>" + getPlantDesc(me)
        return (s, [0, me.icon, 1])
    }
    func soilTooltip(_ id: Int) -> (String, [Int]?) {
        let me = soils[id]
        if parent.amount < me.req { return ("<div style=\"text-align:center;\">Soil unlocked at \(me.req) farms.</div>", nil) }
        let state = soil == id ? "Your field is currently using this soil." : nextSoil > nowMs() ? "You will be able to change your soil again in \(Loc.sayTime((nextSoil - nowMs()) / 1000 * 30 + 30, -1))." : "Click to use this type of soil for your whole field."
        let s = name(me.name) + small(state) + "<line></line><div style=\"margin:6px 0px;\"><b>Effects:</b></div><div style=\"font-size:11px;font-weight:bold;\">\(me.effsStr)</div><q>\(me.q)</q>"
        return (s, [me.icon, 34, 1])
    }
    func toolTooltip(_ id: Int) -> (String, [Int]?) {
        let me = tools[id]
        var d = ""
        switch me.key {
        case "info":
            if freeze != 0 { d = "Your garden is frozen, providing no effects." } else {
                let names: [String: (String, Bool)] = ["cps": ("CpS", false), "click": ("cookies/click", false), "cursorCps": ("cursor CpS", false), "grandmaCps": ("grandma CpS", false),
                    "goldenCookieGain": ("golden cookie gains", false), "goldenCookieFreq": ("golden cookie frequency", false), "goldenCookieDur": ("golden cookie duration", false),
                    "goldenCookieEffDur": ("golden cookie effect duration", false), "wrathCookieGain": ("wrath cookie gains", false), "wrathCookieFreq": ("wrath cookie frequency", false),
                    "wrathCookieDur": ("wrath cookie duration", false), "wrathCookieEffDur": ("wrath cookie effect duration", false), "reindeerGain": ("reindeer gains", false),
                    "reindeerFreq": ("reindeer frequency", false), "reindeerDur": ("reindeer duration", false), "itemDrops": ("random drops", false), "milk": ("milk effects", false),
                    "wrinklerSpawn": ("wrinkler spawn rate", false), "wrinklerEat": ("wrinkler appetite", false), "upgradeCost": ("upgrade costs", true), "buildingCost": ("building costs", true)]
                var effStr = ""
                for k in Garden.effKeys {
                    guard let v = effs[k], v != 1, let n = names[k] else { continue }
                    let amount = (v - 1) * 100
                    effStr += "<div style=\"font-size:10px;margin-left:64px;\"><b>&bull; \(n.0)</b> <span class=\"\((amount * (n.1 ? -1 : 1)) > 0 ? "green" : "red")\">\(amount > 0 ? "+" : "-")\(B(abs(v - 1) * 100, 2))%</span></div>"
                }
                if effStr.isEmpty { effStr = "<div style=\"font-size:10px;margin-left:64px;\"><b>None.</b></div>" }
                d = "<div>Combined effects of all your plants:</div>" + effStr
            }
            d += "<line></line><small>&bull; You can cross-breed plants by planting them close to each other; new plants will grow in the empty tiles next to them.<br>&bull; Unlock new seeds by harvesting mature plants.<br>&bull; When you ascend, your garden plants are reset, but you keep all the seeds you've unlocked.<br>&bull; Your garden has no effect and does not grow while the game is closed.</small>"
        case "harvestAll": d = "Instantly harvest all plants in your garden."
        case "freeze": d = "Cryogenically preserve your garden.<br>Plants no longer grow, spread or die; they provide no benefits.<br>Soil cannot be changed.<line></line>Using this will effectively pause your garden."
        default: d = "A swarm of sugar hornets comes down on your garden, <span class=\"red\">destroying every plant as well as every seed you've unlocked</span> - leaving only a Baker's wheat seed.<br>In exchange, they will grant you <span class=\"green\">10 sugar lumps</span>.<br>This action is only available with a complete seed log."
        }
        return (name(me.name) + "<div style=\"height:20px;\"></div><line></line>" + d, [me.icon, 35, 1])
    }
    private func boostLines(_ x: Int, _ y: Int) -> String {
        var s = ""
        if plotBoost[y][x][0] != 1 { s += "<br><small>Aging multiplier: \(B(plotBoost[y][x][0] * 100))%</small>" }
        if plotBoost[y][x][1] != 1 { s += "<br><small>Effect multiplier: \(B(plotBoost[y][x][1] * 100))%</small>" }
        if plotBoost[y][x][2] != 1 { s += "<br><small>Weeds/fungus repellent: \(B(100 - plotBoost[y][x][2] * 100))%</small>" }
        return s
    }
    func tileTooltip(_ x: Int, _ y: Int) -> (String, [Int]?) {
        let tile = plot[y][x]
        if tile[0] == 0 {
            var s = "<div style=\"text-align:center;\"><div style=\"font-size:15px;font-weight:bold;color:#fff;\">Empty tile</div><line></line>This tile of soil is empty.<br>Pick a seed and plant something!"
            if seedSelected >= 0 {
                let me = plants[seedSelected]
                s += "<line></line>Click to plant <b>\(me.name)</b> for <b style=\"color:\(canPlant(me) ? "#fff" : "#f66");\"><span class=\"tinyCookie\"></span>\(B(getCost(me).rounded()))</b>."
            }
            s += boostLines(x, y) + "</div>"
            return (s, nil)
        }
        let me = plants[Int(tile[0]) - 1]
        let st = stage(tile, me)
        let dragonBoost = 1 / (1 + 0.05 * G.auraMult("Supreme Intellect"))
        let pb = plotBoost[y][x][0]
        let avg = me.ageTick + me.ageTickR / 2
        var s = name(me.name) + small("This plant is growing here.") + "<line></line><div style=\"text-align:center;\">"
        s += "<b>Stage:</b> \(["bud", "sprout", "bloom", "mature"][st - 1])<br>"
        s += "<small>Plant effects: " + (st == 1 ? "10%" : st == 2 ? "25%" : st == 3 ? "50%" : "100%; may reproduce, will drop seed when harvested") + "</small><br><small>"
        if st < 4 {
            s += "Mature in about \(Loc.sayTime(((100 / (pb * avg)) * ((me.mature - tile[1]) / 100) * dragonBoost * stepT) * 30, -1)) (\(Loc.n(((100 / (pb * avg / dragonBoost)) * ((me.mature - tile[1]) / 100)).rounded(.up), "tick", "ticks")))"
        } else if !me.immortal {
            s += "Decays in about \(Loc.sayTime(((100 / (pb * avg)) * ((100 - tile[1]) / 100) * dragonBoost * stepT) * 30, -1)) (\(Loc.n(((100 / (pb * avg / dragonBoost)) * ((100 - tile[1]) / 100)).rounded(.up), "tick", "ticks")))"
        } else { s += "Does not decay" }
        s += "</small>" + boostLines(x, y) + "</div><line></line><div style=\"text-align:center;\">\(st == 4 ? "Click to harvest." : "Click to unearth.")</div><line></line>" + getPlantDesc(me)
        return (s, [st, me.icon, 1])
    }
    func refillTooltip() -> (String, [Int]?) {
        ("<div style=\"text-align:center;font-size:11px;\">Click to refill your soil timer and trigger <b>1</b> plant growth tick with <b>x3</b> spread and mutation rate for <span style=\"color:#6f6;font-weight:bold;\"><span class=\"tinyIcon\" style=\"background-position:\(-29 * 48)px \(-14 * 48)px;\"></span>\(Loc.lumps(1))</span>." +
            (G.lumpRefill <= 0 ? "<br><small>(can be done once every \(Loc.sayTime(G.fps * 60 * 15, -1)))</small>" : "<br><small style=\"color:#f30;\">(usable again in \(Loc.sayTime(G.lumpRefill + G.fps, -1)))</small>") + "</div>", nil)
    }

    // MARK: Minigame
    func save() -> String {
        var s = "\(jsString(nextStep)):\(soil):\(jsString(nextSoil)):\(freeze):\(Int(harvests)):\(Int(harvestsTotal)):1:\(jsString(convertTimes)):\(jsString(nextFreeze)): "
        for p in plants { s += p.unlocked ? "1" : "0" }
        s += " "
        for y in 0..<6 { for x in 0..<6 { s += "\(Int(plot[y][x][0])):\(Int(plot[y][x][1])):" } }
        return s
    }
    func load(_ str: String) {
        if str.isEmpty { return }
        let spl = str.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        let spl2 = spl[0].split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        func num(_ i: Int, _ def: Double) -> Double {
            guard i < spl2.count, !spl2[i].isEmpty else { return def }
            let v = jsParseFloat(spl2[i]); return v.isFinite ? v : def
        }
        nextStep = num(0, nextStep)
        soil = max(0, min(soils.count - 1, Int(num(1, Double(soil)))))
        nextSoil = num(2, nextSoil)
        freeze = Int(num(3, Double(freeze))) != 0 ? 1 : 0
        harvests = Double(Int(num(4, 0)))
        harvestsTotal = Double(Int(num(5, 0)))
        convertTimes = num(7, convertTimes)
        nextFreeze = num(8, nextFreeze)
        let seeds = spl.count > 1 ? Array(spl[1]) : []
        if !seeds.isEmpty { for (n, p) in plants.enumerated() { p.unlocked = n < seeds.count && seeds[n] == "1" } }
        plantsBN["bakerWheat"]!.unlocked = true
        if spl.count > 2, !spl[2].isEmpty {
            let pl = spl[2].split(separator: ":", omittingEmptySubsequences: false).map(String.init)
            var n = 0
            for y in 0..<6 {
                for x in 0..<6 {
                    func v(_ i: Int) -> Double { i < pl.count ? Double(Int(jsParseFloat(pl[i]).isFinite ? jsParseFloat(pl[i]) : 0)) : 0 }
                    var id = v(n)
                    if id < 0 || Int(id) > plants.count { id = 0 }
                    plot[y][x] = [id, v(n + 1)]
                    n += 2
                }
            }
        }
        getUnlockedN()
        computeStepT()
        computeBoostPlot()
        toCompute = true
        onRebuild?()
    }
    func reset(_ hard: Bool) {
        soil = 0
        seedSelected = -1
        nextStep = nowMs(); nextSoil = nowMs(); nextFreeze = nowMs()
        for y in 0..<6 { for x in 0..<6 { plot[y][x] = [0, 0] } }
        harvests = 0
        if hard {
            convertTimes = 0
            harvestsTotal = 0
            for p in plants { p.unlocked = false }
        }
        plantsBN["bakerWheat"]!.unlocked = true
        loopsMult = 1
        getUnlockedN()
        computeStepT()
        computeMatures()
        computeEffs()
        toCompute = true
        onRebuild?()
    }
    func logic() {
        let now = nowMs()
        if freeze == 0 {
            nextStep = min(nextStep, now + stepT * 1000)
            if now >= nextStep {
                computeStepT()
                nextStep = now + stepT * 1000
                computeBoostPlot()
                computeMatures()
                let weedMult = soils[soil].weedMult
                let dragonBoost = 1 + 0.05 * G.auraMult("Supreme Intellect")
                var loops = soils[soil].key == "woodchips" ? 3.0 : 1
                loops = randomFloor(loops * dragonBoost)
                loops *= loopsMult
                loopsMult = 1
                let R = JSMath.random
                for y in 0..<6 {
                    for x in 0..<6 where isTileUnlocked(x, y) {
                        var tile = plot[y][x]
                        if tile[0] > 0 {
                            let me = plants[Int(tile[0]) - 1]
                            tile[1] += randomFloor((me.ageTick + me.ageTickR * R()) * plotBoost[y][x][0] * dragonBoost)
                            tile[1] = max(tile[1], 0)
                            plot[y][x] = tile
                            if me.immortal { plot[y][x][1] = min(me.mature + 1, tile[1]) }
                            else if tile[1] >= 100 {
                                plot[y][x] = [0, 0]
                                me.onDie?(x, y)
                                if soils[soil].key == "pebbles" && R() < 0.35 {
                                    if unlockSeed(me) { pop("Unlocked \(me.name) seed.") }
                                }
                            } else if !me.noContam {
                                var list: [String] = []
                                for (k, c) in plantContam where R() < c && (!plantsBN[k]!.weed || R() < weedMult) { list.append(k) }
                                if let contam = chooseOpt(list), me.key != contam {
                                    let cp = plantsBN[contam]!
                                    if (!cp.weed && !cp.fungus) || R() < plotBoost[y][x][2] {
                                        let (_, neighsM) = neighbors(x, y, diagonals: false)
                                        if (neighsM[contam] ?? 0) >= 1 { plot[y][x] = [Double(cp.id + 1), 0] }
                                    }
                                }
                            }
                        } else {
                            var loop = 0
                            while Double(loop) < loops {
                                let (neighs, neighsM, any) = neighborsAny(x, y)
                                if any > 0 {
                                    let muts = getMuts(neighs, neighsM)
                                    var list: [String] = []
                                    for (k, c) in muts {
                                        let p = plantsBN[k]!
                                        if R() < c && (!p.weed || R() < weedMult) && ((!p.weed && !p.fungus) || R() < plotBoost[y][x][2]) { list.append(k) }
                                    }
                                    if !list.isEmpty { plot[y][x] = [Double(plantsBN[choose(list)]!.id + 1), 0] }
                                } else if loop == 0 {
                                    let chance = 0.002 * weedMult * plotBoost[y][x][2]
                                    if R() < chance { plot[y][x] = [Double(plantsBN["meddleweed"]!.id + 1), 0] }
                                }
                                loop += 1
                            }
                        }
                    }
                }
                toRebuild = true
                toCompute = true
            }
        }
        if toRebuild { toRebuild = false; buildPlotChecks(); onRebuild?() }
        if toCompute { computeEffs() }
    }
    private func neighbors(_ x: Int, _ y: Int, diagonals: Bool) -> ([String: Int], [String: Int]) {
        let r = neighborsAny(x, y, diagonals: diagonals)
        return (r.0, r.1)
    }
    private func neighborsAny(_ x: Int, _ y: Int, diagonals: Bool = true) -> ([String: Int], [String: Int], Int) {
        var neighs: [String: Int] = [:], neighsM: [String: Int] = [:]
        var any = 0
        var offs = [(0, -1), (0, 1), (-1, 0), (1, 0)]
        if diagonals { offs += [(-1, -1), (-1, 1), (1, -1), (1, 1)] }
        for (dx, dy) in offs {
            let n = getTile(x + dx, y + dy)
            if n[0] > 0 {
                let p = plants[Int(n[0]) - 1]
                any += 1
                neighs[p.key, default: 0] += 1
                if n[1] >= p.mature { neighsM[p.key, default: 0] += 1 }
            }
        }
        return (neighs, neighsM, any)
    }
    /// buildPlot's achievement check
    func buildPlotChecks() {
        var n = 0
        for y in 0..<6 { for x in 0..<6 where plot[y][x][0] > 0 { n += 1 } }
        if n >= 36 { G.win("In the garden of Eden (baby)") }
    }
}

// MARK: - garden alerts (mods/reminders.js): a message when plants become mature or are about to wither away

enum GardenAlerts {
    private static var known: [String: String]? = nil
    static func check() {
        guard let M = Minigames.garden else { known = nil; return }
        var now: [String: String] = [:]
        var matured: [String] = [], dying: [String] = []
        for y in 0..<6 {
            for x in 0..<6 {
                let tile = M.plot[y][x]
                guard tile[0] >= 1, Int(tile[0]) <= M.plants.count else { continue }
                let me = M.plants[Int(tile[0]) - 1]
                var state = tile[1] >= me.mature ? 1 : 0
                if !me.immortal && state == 1 && 100 - tile[1] <= (me.ageTick + me.ageTickR) * M.plotBoost[y][x][0] * 2 { state = 2 }
                let key = "\(x),\(y)"
                now[key] = "\(Int(tile[0])):\(state)"
                if let k = known, k[key] != now[key] {
                    let before = k[key]
                    let parts = before?.split(separator: ":").map(String.init) ?? []
                    let same = parts.first == String(Int(tile[0]))
                    let prev = same ? Int(parts[1]) ?? 0 : 0
                    if state == 1 && prev < 1 && !me.weed { matured.append(me.name) }
                    if state == 2 && prev < 2 && !me.weed && !me.fungus { dying.append(me.name) }
                }
            }
        }
        func list(_ a: [String]) -> String {
            var order: [String] = [], c: [String: Int] = [:]
            for n in a { if c[n] == nil { order.append(n) }; c[n, default: 0] += 1 }
            return order.map { c[$0]! > 1 ? "\(c[$0]!)× \($0)" : $0 }.joined(separator: ", ")
        }
        if known != nil && AppSettings.shared.gardenAlerts {
            if !matured.isEmpty { G.toast("Garden: ready!", "<b>\(list(matured))</b> \(matured.count > 1 ? "are" : "is") now mature.", [15, 9]) }
            if !dying.isEmpty { G.toast("Garden: harvest soon!", "<b>\(list(dying))</b> will wither away very soon.", G.buildingsBN["Farm"]!.icon) }
        }
        known = now
    }
}

// MARK: - the screen

/// a seed, tool or soil button (.gardenSeed): the picture, the "selected" frame
final class GardenSeedView: TapView {
    let icon = IconView()
    private let target = PicView("mgimg/selectTarget.png")
    var on = false { didSet { target.isHidden = !on } }
    var iconOrigin = CGPoint.zero
    init(_ ic: [Int]) {
        super.init(frame: .zero)
        icon.sheet = "mgimg/gardenPlants.png"
        icon.icon = ic
        icon.isUserInteractionEnabled = false
        icon.layer.shadowColor = UIColor.black.cgColor; icon.layer.shadowOpacity = 0.6; icon.layer.shadowRadius = px(2); icon.layer.shadowOffset = .zero
        addSubview(icon)
        target.isHidden = true
        addSubview(target)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        icon.frame = CGRect(x: iconOrigin.x, y: iconOrigin.y, width: px(48), height: px(48))
        target.frame = CGRect(x: -px(10), y: -px(10), width: px(60), height: px(60))
    }
}

final class GardenScreen: UIView, MinigameScreen {
    let M: Garden
    private let bg = PatternView("mgimg/BGgarden.jpg")
    private let borders = PicView("mgimg/shadedBorders.png")
    private let frozenGlow = UIView()
    private let plotSize = RichLabel()
    private let plotView = UIView()
    private var tiles: [TapView] = []        // 36, by y*6+x
    private var tileBG: [UIImageView] = []
    private var tileIcons: [UIImageView] = []
    private var soilViews: [GardenSeedView] = []
    private let info = UIView()
    private let infoText = RichLabel()
    private let refillB = TapView()
    private let panel = UIView()
    private let panelNoise = PatternView("img/darkNoise.jpg")
    private let panelShade = PicView("mgimg/shadedBordersSoft.png")
    private let panelBorder = BorderImageView(image: "img/frameBorder.png", slice: 3, width: 3)
    private let toolsLabel = RichLabel(), seedsLabel = RichLabel()
    private let line1 = LineView(), line2 = LineView()
    private var toolViews: [GardenSeedView] = []
    private var seedViews: [GardenSeedView] = []
    private var drawT = 0
    private var lastW = 320.0

    init(_ m: Garden) {
        M = m
        super.init(frame: .zero)
        addSubview(bg); addSubview(borders)
        frozenGlow.isUserInteractionEnabled = false
        frozenGlow.layer.borderColor = UIColor(red: 200 / 255, green: 1, blue: 225 / 255, alpha: 0.35).cgColor
        frozenGlow.layer.shadowColor = UIColor.white.cgColor
        addSubview(frozenGlow)
        var ps = TextStyle.base(11 / 1.2, color: UIColor(white: 1, alpha: 0.75)); ps.align = .center; ps.lineHeight = 1.2
        plotSize.style = ps
        plotSize.isUserInteractionEnabled = false
        addSubview(plotSize)
        plotView.layer.shadowColor = UIColor.black.cgColor; plotView.layer.shadowOpacity = 0.5; plotView.layer.shadowRadius = px(2); plotView.layer.shadowOffset = .zero
        addSubview(plotView)
        for i in 0..<36 {
            let x = i % 6, y = i / 6
            let t = TapView()
            let b = UIImageView()
            // .gardenTile:nth-child(4n+k):before background positions 40/80/120/0 (the 160px strip repeats)
            let c = (i + 1) % 4
            let sx = [0.0, 120, 80, 40][c]
            b.image = Res.sprite("mgimg/gardenPlots.png", x: sx, y: 0, w: 40, h: 40)
            b.alpha = 0.65
            t.addSubview(b)
            let ic = UIImageView()
            t.addSubview(ic)
            t.onTap = { [weak self] _ in
                guard let self = self else { return }
                self.M.clickTile(x, y)
                MinigameWindow.current?.showTooltip { [weak self] in self?.M.tileTooltip(x, y) ?? ("", nil) }
                self.rebuild()
            }
            t.onDown = { [weak b] _, _ in b?.alpha = 1 }
            t.onUp = { [weak b] _ in b?.alpha = 0.65 }
            plotView.addSubview(t)
            tiles.append(t); tileBG.append(b); tileIcons.append(ic)
        }
        for (i, s) in m.soils.enumerated() {
            let v = GardenSeedView([s.icon, 34])
            v.onTap = { [weak self] _ in
                guard let self = self else { return }
                self.M.setSoil(i)
                MinigameWindow.current?.showTooltip { [weak self] in self?.M.soilTooltip(i) ?? ("", nil) }
                self.rebuild()
            }
            soilViews.append(v)
            addSubview(v)
        }
        info.backgroundColor = UIColor(white: 0, alpha: 0.75)
        info.layer.cornerRadius = px(16)
        var it = TextStyle.base(11, color: UIColor(white: 1, alpha: 0.75)); it.shadow = Shadows.make(-1, 1, 0); it.nowrap = true
        infoText.style = it
        info.addSubview(infoText)
        addSubview(info)
        let lump = IconView([29, 14])
        lump.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        refillB.addSubview(lump)
        refillB.onTap = { [weak self] _ in
            MinigameWindow.current?.showTooltip { [weak self] in self?.M.refillTooltip() ?? ("", nil) }
            self?.M.refill()
        }
        addSubview(refillB)
        // the panel (.framed)
        panel.backgroundColor = .black
        panel.layer.shadowColor = UIColor.black.cgColor; panel.layer.shadowOpacity = 0.5; panel.layer.shadowRadius = px(4); panel.layer.shadowOffset = CGSize(width: 0, height: px(2))
        let inner = UIView(); inner.clipsToBounds = true; inner.tag = 5
        inner.addSubview(panelNoise); inner.addSubview(panelShade)
        panel.addSubview(inner)
        panel.addSubview(panelBorder)
        addSubview(panel)
        var ls = TextStyle(); ls.family = .merriweather; ls.size = 14; ls.color = .white; ls.align = .center; ls.shadow = Shadows.make(0, 1, 4); ls.nowrap = true
        toolsLabel.style = ls; seedsLabel.style = ls
        toolsLabel.html = "Tools"
        panel.addSubview(toolsLabel); panel.addSubview(seedsLabel)
        panel.addSubview(line1); panel.addSubview(line2)
        for (i, t) in m.tools.enumerated() {
            let v = GardenSeedView([t.icon, 35])
            v.iconOrigin = CGPoint(x: px(2), y: px(2))
            v.onTap = { [weak self] _ in
                guard let self = self else { return }
                switch t.key {
                case "harvestAll": PlaySound("snd/toneTick.mp3", 1); self.M.harvestAll()
                case "freeze": self.M.toggleFreeze()
                case "convert": PlaySound("snd/toneTick.mp3", 1); self.M.askConvert()
                default: break
                }
                MinigameWindow.current?.showTooltip { [weak self] in self?.M.toolTooltip(i) ?? ("", nil) }
                self.rebuild()
            }
            toolViews.append(v)
            panel.addSubview(v)
        }
        for p in m.plants {
            let v = GardenSeedView([0, p.icon])
            let id = p.id
            v.onTap = { [weak self] _ in
                guard let self = self else { return }
                let me = self.M.plants[id]
                if me.plantable {
                    if self.M.seedSelected == id { self.M.seedSelected = -1 } else { self.M.seedSelected = id; PlaySound("snd/toneTick.mp3", 1) }
                }
                MinigameWindow.current?.showTooltip { [weak self] in self?.M.seedTooltip(id) ?? ("", nil) }
                self.rebuild()
            }
            seedViews.append(v)
            panel.addSubview(v)
        }
        m.onRebuild = { [weak self] in self?.rebuild() }
        rebuild()
    }
    required init?(coder: NSCoder) { fatalError() }

    private var lastLayoutKey = ""
    /// buildPlot + the panel's on/locked classes
    func rebuild() {
        for i in 0..<36 {
            let x = i % 6, y = i / 6
            let tile = M.plot[y][x]
            tiles[i].isHidden = !M.isTileUnlocked(x, y)
            if tile[0] > 0, Int(tile[0]) <= M.plants.count {
                let me = M.plants[Int(tile[0]) - 1]
                let st = M.stage(tile, me)
                let dying = tile[1] + (me.ageTick + me.ageTickR).rounded(.up) >= 100
                tileIcons[i].image = Res.sprite("mgimg/gardenPlants.png", x: Double(st * 48), y: Double(me.icon * 48), w: 48, h: 48)
                tileIcons[i].alpha = dying ? 0.5 : 1
                tileIcons[i].isHidden = false
            } else { tileIcons[i].isHidden = true }
        }
        for (i, v) in soilViews.enumerated() {
            v.on = M.soil == i
            v.dim(M.parent.amount < M.soils[i].req)
        }
        toolViews[2].on = M.freeze != 0
        toolViews[3].isHidden = M.plantsUnlockedN < M.plantsN
        for (i, v) in seedViews.enumerated() {
            v.isHidden = !M.plants[i].unlocked
            v.on = M.seedSelected == i
        }
        frozenGlow.isHidden = M.freeze == 0
        let key = "\(M.level)-\(M.plantsUnlockedN)-\(toolViews[3].isHidden)"
        if key != lastLayoutKey && !lastLayoutKey.isEmpty { MinigameWindow.current?.relayoutContent() }
        lastLayoutKey = key
        updateInfo()
    }
    private func updateInfo() {
        let next = M.freeze != 0 ? "Garden is frozen. Unfreeze to resume." : "Next tick in \(Loc.sayTime((M.nextStep - nowMs()) / 1000 * 30 + 30, -1))."
        infoText.html = "\(next)<br>Mature plants harvested: \(B(M.harvests)) (total: \(B(M.harvestsTotal)))"
        plotSize.html = M.parent.level < M.plotLimits.count ? "Plot size: \(max(1, min(M.plotLimits.count, M.parent.level)))/\(M.plotLimits.count)<br>(Upgrades with farm level)" : ""
        seedsLabel.html = "Seeds<span style=\"font-size:83%;\"> (\(M.plantsUnlockedN)/\(M.plantsN))</span>"
        layoutInfo()
    }
    private func layoutInfo() {
        let tw = Double(RichText.size(RichText.render(infoText.html, style: infoText.style, width: nil), width: nil).width) + 1
        let iw = tw + 48
        info.frame = CGRect(x: px((lastW - iw) / 2), y: info.frame.minY, width: px(iw), height: px(38))
        infoText.frame = CGRect(x: px(32), y: px(8), width: px(tw), height: px(22))
        refillB.frame = CGRect(x: info.frame.minX - px(8), y: info.frame.minY - px(6), width: px(48), height: px(48))
        refillB.subviews.first?.center = CGPoint(x: px(24), y: px(24))
    }

    func layoutContent(width w: Double, minHeight: Double) -> Double {
        lastW = w
        // #gardenField: 6px in, the plot size note at +2, the plot at +22 (zoomed to fit, at most 1.75x)
        let lim = M.plotLimits[M.level]
        let cols = lim[2] - lim[0], rows = lim[3] - lim[1]
        let fieldW = w - 12
        let avail = max(200, fieldW - 12)
        let z = min(1.75, avail / Double(cols * 40))
        let ts = 40 * z
        plotSize.frame = CGRect(x: px(6), y: px(8), width: px(fieldW), height: px(22))
        let pw = Double(cols) * ts, ph = Double(rows) * ts
        let plotY = 6 + 22 + 4 * z
        plotView.frame = CGRect(x: px((w - pw) / 2), y: px(plotY), width: px(pw), height: px(ph))
        for i in 0..<36 {
            let x = i % 6, y = i / 6
            let f = CGRect(x: px(Double(x - lim[0]) * ts), y: px(Double(y - lim[1]) * ts), width: px(ts), height: px(ts))
            tiles[i].frame = f
            tileBG[i].frame = tiles[i].bounds
            // .gardenTileIcon: 48px, left -4px, top -12px (zoomed)
            tileIcons[i].frame = CGRect(x: px(-4 * z), y: px(-12 * z), width: px(48 * z), height: px(48 * z))
        }
        var y = plotY + ph + max(4 * z, 6)
        // soils: 48px each, 3px margins
        let sx = 6 + (fieldW - 5 * 54) / 2 + 3
        for (i, v) in soilViews.enumerated() {
            v.frame = CGRect(x: px(sx + Double(i) * 54), y: px(y), width: px(48), height: px(48))
        }
        y += 50 + 12
        info.frame = CGRect(x: info.frame.minX, y: px(y), width: info.frame.width, height: px(38))
        layoutInfo()
        y += 38 + 8
        // the panel
        let panelY = y
        let innerX = 7.0   // border 3 + padding 4
        let cw = fieldW - 14
        var py = 3 + 4 + 6.0
        toolsLabel.frame = CGRect(x: px(innerX), y: px(py + 2), width: px(cw), height: px(14))
        line1.frame = CGRect(x: px(innerX), y: px(py + 18), width: px(cw), height: px(3))
        py += 25
        let shownTools = toolViews.filter { !$0.isHidden }
        let tx = innerX + (cw - Double(shownTools.count) * 68) / 2 + 8
        for (i, v) in shownTools.enumerated() {
            v.frame = CGRect(x: px(tx + Double(i) * 68), y: px(py + 8), width: px(52), height: px(52))
        }
        py += 70 + 6
        seedsLabel.frame = CGRect(x: px(innerX), y: px(py + 2), width: px(cw), height: px(15))
        line2.frame = CGRect(x: px(innerX), y: px(py + 19), width: px(cw), height: px(3))
        py += 26
        // #gardenSeeds: a 6-column grid, gap 2px, padding 4px 2px
        let colW = (cw - 4 - 10) / 6
        let shownSeeds = seedViews.filter { !$0.isHidden }
        for (i, v) in shownSeeds.enumerated() {
            let r = i / 6, c = i % 6
            v.frame = CGRect(x: px(innerX + 2 + Double(c) * (colW + 2)), y: px(py + 4 + Double(r) * 50), width: px(colW), height: px(48))
            v.iconOrigin = CGPoint(x: px(colW / 2 - 24), y: 0)
            v.setNeedsLayout()
        }
        let seedRows = max(1, (shownSeeds.count + 5) / 6)
        py += 8 + Double(seedRows) * 48 + Double(seedRows - 1) * 2
        py += 4 + 3 + 4
        panel.frame = CGRect(x: px(6), y: px(panelY), width: px(fieldW), height: px(py))
        if let inner = panel.viewWithTag(5) { inner.frame = panel.bounds; panelNoise.frame = inner.bounds; panelShade.frame = inner.bounds }
        panelBorder.frame = panel.bounds
        y = panelY + py + 4 + 16
        let h = max(y, minHeight)
        bg.frame = CGRect(x: 0, y: 0, width: px(w), height: px(h))
        borders.frame = bg.frame
        frozenGlow.frame = bg.frame
        frozenGlow.layer.borderWidth = px(16)
        return h
    }

    func drawFrame() {
        drawT += 1
        if drawT % 10 == 0 {
            updateInfo()
            for (i, v) in soilViews.enumerated() { v.dim(M.parent.amount < M.soils[i].req) }
        }
    }
}

extension GardenSeedView {
    /// .gardenSoil.disabled{filter:brightness(10%)}
    func dim(_ d: Bool) {
        if d {
            let m = (viewWithTag(77) as? UIImageView) ?? { let m = UIImageView(); m.tag = 77; m.isUserInteractionEnabled = false; addSubview(m); return m }()
            if m.image == nil, let src = Res.sprite(icon.sheet, x: Double(icon.icon[0] * 48), y: Double(icon.icon[1] * 48), w: 48, h: 48) {
                m.image = UIGraphicsImageRenderer(size: src.size).image { c in
                    src.draw(at: .zero)
                    UIColor(white: 0, alpha: 0.9).setFill()
                    c.fill(CGRect(origin: .zero, size: src.size), blendMode: .sourceAtop)
                }
            }
            m.frame = CGRect(x: iconOrigin.x, y: iconOrigin.y, width: px(48), height: px(48))
            icon.isHidden = true
        } else { viewWithTag(77)?.removeFromSuperview(); icon.isHidden = false }
    }
}
