import Foundation

// G.updateBG (www/main.js): which wallpaper is shown, blending towards the grandmapocalypse ones.

struct BGState: Equatable {
    var pic1 = "bgBlue"
    var pic2 = "bgBlue"
    var ratio = 0.0
}

extension Game {
    @discardableResult
    func updateBG(_ reset: Bool) -> Bool {
        if reset {
            elderWrathD = Double(elderWrath)
        } else {
            if bgType != 0 { return false }
            if elderWrathD < Double(elderWrath) { elderWrathD += 0.02 }
            else if elderWrathD > Double(elderWrath) { elderWrathD -= 0.02 }
            else { return false }
            elderWrathD = jsRound(elderWrathD * 1000) / 1000
        }
        var bgPic = "bgBlue"
        if bgType != 0 && bgType < Game.AllBGs.count { bgPic = Game.AllBGs[bgType].pic }
        var pic1 = bgPic, pic2 = bgPic, ratio = 0.0
        if bgType == 0 {
            if season == "fools" { pic1 = "bgMoney"; pic2 = pic1; ratio = 0 }
            if elderWrathD > 0 && getSet("notScary") == 0 {
                if elderWrathD < 1 { pic2 = "grandmas1"; ratio = elderWrathD.truncatingRemainder(dividingBy: 1) }
                else if elderWrathD < 2 { pic1 = "grandmas1"; pic2 = "grandmas2"; ratio = elderWrathD.truncatingRemainder(dividingBy: 1) }
                else if elderWrathD < 3 { pic1 = "grandmas2"; pic2 = "grandmas3"; ratio = elderWrathD.truncatingRemainder(dividingBy: 1) }
                else { pic1 = "grandmas3"; pic2 = "grandmas3"; ratio = 0 }
            }
        }
        bg = BGState(pic1: pic1, pic2: pic2, ratio: ratio)
        return true
    }
    /// the milk picture (G.Draw)
    var milkPic: String {
        var pic = milks[min(milks.count - 1, achievsN / 25)].pic
        if milkType != 0 && milkType < AllMilks.count { pic = AllMilks[milkType].pic }
        return pic
    }
}
