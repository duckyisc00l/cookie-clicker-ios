import UIKit

/// What the game engine asks the screen to do (the places where the original touches the page directly).
protocol GameUI: AnyObject {
    func toast(title: String, top: String, icon: [Int]?, reverse: Bool)
    func plopBuff(_ name: String)
    func plopQuickButton(_ name: String, heavy: Bool)
    func settingChanged(_ name: String)
    func closeAllPopups()
    func closeAllToasts()
    func showAscend(_ mode: Int)
    func screenChanged(from: String, to: String)
}

final class UIEvents {
    static let shared = UIEvents()
    weak var ui: GameUI?
    func toast(title: String, top: String, icon: [Int]?, reverse: Bool) { ui?.toast(title: title, top: top, icon: icon, reverse: reverse) }
    func plopBuff(_ name: String) { ui?.plopBuff(name) }
    func plopQuickButton(_ name: String, heavy: Bool) { ui?.plopQuickButton(name, heavy: heavy) }
    func settingChanged(_ name: String) { ui?.settingChanged(name) }
    func closeAllPopups() { ui?.closeAllPopups() }
    func closeAllToasts() { ui?.closeAllToasts() }
    func showAscend(_ mode: Int) { ui?.showAscend(mode) }
    func screenChanged(from: String, to: String) { ui?.screenChanged(from: from, to: to) }
}

