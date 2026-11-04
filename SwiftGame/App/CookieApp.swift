import SwiftUI
import UIKit

@main
struct CookieApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var phase
    @StateObject private var game = Game.shared
    @StateObject private var ui = UIState.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(game)
                .environmentObject(ui)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
        }
        .onChange(of: phase) { p in
            switch p {
            case .active: GameLoop.shared.resume()
            case .background, .inactive: GameLoop.shared.pause(); Game.shared.save(); Extras.backgroundSave()
            @unknown default: break
            }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ app: UIApplication, didFinishLaunchingWithOptions opts: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let g = Game.shared
        g.reset(hard: true)
        if !g.loadFromDisk() { g.reset(hard: true) }
        GameLoop.shared.start()
        Extras.applySettings()
        return true
    }
}

/// Runs the game 30 times a second, and catches up for time spent away.
final class GameLoop {
    static let shared = GameLoop()
    private var link: CADisplayLink?
    private var last = CACurrentMediaTime()
    private var acc = 0.0
    private var drawCounter = 0
    private var pausedAt: Double? = nil

    func start() {
        link?.invalidate()
        last = CACurrentMediaTime()
        let l = CADisplayLink(target: self, selector: #selector(tick))
        if #available(iOS 15.0, *) { l.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 120, preferred: Extras.highRefresh ? 120 : 60) }
        l.add(to: .main, forMode: .common)
        link = l
    }
    func pause() { if pausedAt == nil { pausedAt = Date().timeIntervalSince1970 } ; link?.isPaused = true }
    func resume() {
        if let p = pausedAt {
            let away = Date().timeIntervalSince1970 - p
            pausedAt = nil
            if away > 1 { Game.shared.logic(away * Game.fps) }   // earn cookies for the time away, like the original
        }
        last = CACurrentMediaTime()
        link?.isPaused = false
    }

    @objc private func tick() {
        let t = CACurrentMediaTime()
        var dt = t - last
        last = t
        if dt > 5 { Game.shared.logic(dt * Game.fps); dt = 0 }
        acc += dt * Game.fps
        var steps = 0
        while acc >= 1 && steps < 6 { Game.shared.logic(1); acc -= 1; steps += 1 }
        if steps == 6 { acc = 0 }
        Effects.shared.logic(dt * 60)
        drawCounter += 1
        if drawCounter % 4 == 0 { Game.shared.frame &+= 1 }
    }
}

/// Which screen and popup is showing.
final class UIState: ObservableObject {
    static let shared = UIState()
    @Published var tab: Tab = .cookie
    @Published var storeTab: StoreTab = .buildings
    @Published var popup: PopupKind? = nil
    @Published var minigame: String? = nil
    enum Tab: String, CaseIterable { case cookie = "Cookie", store = "Store", special = "Special", stats = "Stats", misc = "Misc" }
    enum StoreTab { case buildings, upgrades }
}

enum PopupKind: Identifiable {
    case building(Int), upgrade(Int), achievement(Int), lumps, dragon, santa, seasons, research, dragonAura(Int)
    case ascend, confirmWipe, settings, news, log, extras, buff(UUID), message(String, String)
    case permanentSlot(Int), upgradesList, achievsList
    var id: String { String(describing: self) }
}
