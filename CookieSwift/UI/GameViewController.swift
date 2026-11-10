import UIKit

/// The whole game screen. Runs the game's loop like www/lib/main.js does: logic 30 times a second
/// (delta = time passed in frames), then draws.
final class GameViewController: UIViewController {
    private var timer: Timer?
    private var lastTime = 0.0
    private(set) var started = false
    private var lastLayoutKey = ""
    let root = RootView()

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .bottom }

    override func loadView() { view = root }

    override func viewDidLoad() {
        super.viewDidLoad()
        UIEvents.shared.ui = root
        root.host = self
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizeGame()
        if !started {
            started = true
            G.Init()
            root.build()
            ExtrasHost.shared.start()
            // screenshots on the test machine: open a given screen
            if let shot = ProcessInfo.processInfo.environment["CC_SHOT"] {
                if shot == "upgrades" { G.onStoreSection = "upgrades"; G.setScreen("store", force: true) }
                else if shot.hasPrefix("popup-") { DebugShots.open(String(shot.dropFirst(6))) }
                else { G.setScreen(shot, force: true) }
            }
            lastTime = nowMs()
            startLoop()
        }
    }

    /// G.resize: the page is 320 px wide, as tall as the screen allows
    func resizeGame() {
        let b = view.bounds
        guard b.width > 0 else { return }
        // only when the size or the safe area really changed (this runs on every layout pass)
        let key = "\(b.size)|\(view.safeAreaInsets)"
        if key == lastLayoutKey { return }
        lastLayoutKey = key
        K = b.width / 320
        G.w = 320
        Layout.sat = Double(view.safeAreaInsets.top / K)
        Layout.sab = Double(view.safeAreaInsets.bottom / K)
        // the game's own area sits between the notch and the home bar (like the original on a phone without them)
        G.fullH = Double(b.height / K)
        G.h = G.fullH - Layout.sat - Layout.sab
        if started { root.relayout() }
    }

    private func startLoop() {
        timer?.invalidate()
        let t = Timer(timeInterval: 1.0 / G.fps, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        let now = nowMs()
        let delta = 1 + ((now - lastTime) - 1000 / G.fps) * G.fps / 1000
        lastTime = now
        G._Logic(delta)
        root.draw()
    }
}
