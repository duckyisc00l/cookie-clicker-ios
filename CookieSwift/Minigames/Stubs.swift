import UIKit
// Temporary: replaced by the full ports of the desktop minigames.
/// placeholder screens until each minigame is ported
class PlaceholderScreen: UIView, MinigameScreen {
    func layoutContent(width: Double, minHeight: Double) -> Double { minHeight }
    func drawFrame() {}
}
