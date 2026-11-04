import Foundation

struct Cosmetic { let pic: String, name: String, icon: [Int], type: Int }

/// Backgrounds and milk flavors you can pick (Background selector / Milk selector).
enum Cosmetics {
    static let bgs: [Cosmetic] = [
        ("bgBlue", "Automatic", [0, 7]), ("bgBlue", "Blue", [21, 21]), ("bgRed", "Red", [22, 21]), ("bgWhite", "White", [23, 21]),
        ("bgBlack", "Black", [24, 21]), ("bgGold", "Gold", [25, 21]), ("grandmas1", "Grandmas", [26, 21]), ("grandmas2", "Displeased grandmas", [27, 21]),
        ("grandmas3", "Angered grandmas", [28, 21]), ("bgMoney", "Money", [29, 21]), ("bgPurple", "Purple", [21, 22]), ("bgPink", "Pink", [24, 22]),
        ("bgMint", "Mint", [22, 22]), ("bgSilver", "Silver", [25, 22]), ("bgBW", "Black & White", [23, 22]), ("bgSpectrum", "Spectrum", [28, 22]),
        ("bgCandy", "Candy", [26, 22]), ("bgYellowBlue", "Biscuit store", [27, 22]), ("bgChoco", "Chocolate", [30, 21]), ("bgChocoDark", "Dark Chocolate", [31, 21]),
        ("bgPaint", "Painter", [24, 34]), ("bgSnowy", "Snow", [30, 22]), ("bgSky", "Sky", [29, 22]), ("bgStars", "Night", [31, 22]), ("bgFoil", "Foil", [25, 34]),
    ].map { Cosmetic(pic: $0.0, name: $0.1, icon: $0.2, type: 0) }

    static let allMilks: [Cosmetic] = [
        ("milkPlain", "Automatic", [0, 7], -1), ("milkPlain", "Plain milk", [1, 8], 0), ("milkChocolate", "Chocolate milk", [2, 8], 0),
        ("milkRaspberry", "Raspberry milk", [3, 8], 0), ("milkOrange", "Orange milk", [4, 8], 0), ("milkCaramel", "Caramel milk", [5, 8], 0),
        ("milkBanana", "Banana milk", [6, 8], 0), ("milkLime", "Lime milk", [7, 8], 0), ("milkBlueberry", "Blueberry milk", [8, 8], 0),
        ("milkStrawberry", "Strawberry milk", [9, 8], 0), ("milkVanilla", "Vanilla milk", [10, 8], 0), ("milkZebra", "Zebra milk", [10, 7], 1),
        ("milkStars", "Cosmic milk", [9, 7], 1), ("milkFire", "Flaming milk", [8, 7], 1), ("milkBlood", "Sanguine milk", [7, 7], 1),
        ("milkGold", "Midas milk", [6, 7], 1), ("milkBlack", "Midnight milk", [5, 7], 1), ("milkGreenFire", "Green inferno milk", [4, 7], 1),
        ("milkBlueFire", "Frostfire milk", [3, 7], 1), ("milkHoney", "Honey milk", [21, 23], 0), ("milkCoffee", "Coffee milk", [22, 23], 0),
        ("milkTea", "Tea milk", [23, 23], 0), ("milkCoconut", "Coconut milk", [24, 23], 0), ("milkCherry", "Cherry milk", [25, 23], 0),
        ("milkSoy", "Soy milk", [27, 23], 1), ("milkSpiced", "Spiced milk", [26, 23], 0), ("milkMaple", "Maple milk", [28, 23], 0),
        ("milkMint", "Mint milk", [29, 23], 0), ("milkLicorice", "Licorice milk", [30, 23], 0), ("milkRose", "Rose milk", [31, 23], 0),
        ("milkDragonfruit", "Dragonfruit milk", [21, 24], 0), ("milkMelon", "Melon milk", [22, 24], 0), ("milkBlackcurrant", "Blackcurrant milk", [23, 24], 0),
        ("milkPeach", "Peach milk", [24, 24], 0), ("milkHazelnut", "Hazelnut milk", [25, 24], 0),
    ].map { Cosmetic(pic: $0.0, name: $0.1, icon: $0.2, type: $0.3) }

    static let milks: [Cosmetic] = allMilks.filter { $0.type == 0 }

    static func romanize(_ n: Int) -> String {
        let vals = [(1000, "M"), (900, "CM"), (500, "D"), (400, "CD"), (100, "C"), (90, "XC"), (50, "L"), (40, "XL"), (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
        var n = n, s = ""
        for (v, r) in vals { while n >= v { s += r; n -= v } }
        return s
    }
    static func milkRankName(_ i: Int) -> String { "Rank \(romanize(i + 1)) - \(milks[i].name)" }

    /// the milk shown: chosen flavor, or the one for your achievement count
    static func milkPic(_ g: Game) -> String {
        if g.milkType > 0, let m = allMilks[safe: g.milkType] { return m.pic }
        let rank = min(g.achievsN / 25, milks.count - 1)
        return milks[max(0, rank)].pic
    }

    /// background(s) to show and how much of the second one (grandmapocalypse fades in)
    static func background(_ g: Game, wrathD: Double) -> (String, String, Double) {
        var pic = "bgBlue"
        if g.bgType != 0, let b = bgs[safe: g.bgType] { pic = b.pic }
        var p1 = pic, p2 = pic, ratio = 0.0
        if g.bgType == 0 {
            if g.season == "fools" { p1 = "bgMoney"; p2 = p1 }
            if wrathD > 0 && !g.settings.notScary {
                if wrathD < 1 { p2 = "grandmas1"; ratio = wrathD.truncatingRemainder(dividingBy: 1) }
                else if wrathD < 2 { p1 = "grandmas1"; p2 = "grandmas2"; ratio = wrathD.truncatingRemainder(dividingBy: 1) }
                else if wrathD < 3 { p1 = "grandmas2"; p2 = "grandmas3"; ratio = wrathD.truncatingRemainder(dividingBy: 1) }
                else { p1 = "grandmas3"; p2 = p1 }
            }
        }
        return (p1 + ".jpg", p2 + ".jpg", ratio)
    }
}
