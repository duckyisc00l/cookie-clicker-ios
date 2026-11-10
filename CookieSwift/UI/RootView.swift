import UIKit

/// #game: everything on screen. The pieces are added by the screen files.
final class RootView: UIView, GameUI {
    weak var host: GameViewController?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        clipsToBounds = true
        TextMeasure.tickerWidth = { html in
            let s = RichText.render(html, style: .ticker)
            return Double(RichText.size(s, width: nil).width)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func build() {}
    func relayout() {}
    func draw() {}

    // MARK: GameUI
    func toast(title: String, top: String, icon: [Int]?, reverse: Bool) {}
    func plopBuff(_ name: String) {}
    func plopQuickButton(_ name: String, heavy: Bool) {}
    func settingChanged(_ name: String) {}
    func closeAllPopups() {}
    func closeAllToasts() {}
    func showAscend(_ mode: Int) {}
    func screenChanged(from: String, to: String) {}
}
