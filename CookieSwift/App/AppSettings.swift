import Foundation
import Combine

/// The app's own settings (shown on the "iPhone extras" screen), saved on the phone.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    private let defaults = UserDefaults.standard

    @Published var keepAwake: Bool { didSet { defaults.set(keepAwake, forKey: "keepAwake") } }
    @Published var highRefresh: Bool { didSet { defaults.set(highRefresh, forKey: "highRefresh") } }
    @Published var liveActivity: Bool { didSet { defaults.set(liveActivity, forKey: "liveActivity") } }
    @Published var autoBackup: Bool { didSet { defaults.set(autoBackup, forKey: "autoBackup") } }
    @Published var autoHarvest: Bool { didSet { defaults.set(autoHarvest, forKey: "autoHarvest") } }
    @Published var lumpNotify: Bool { didSet { defaults.set(lumpNotify, forKey: "lumpNotify") } }
    @Published var gardenAlerts: Bool { didSet { defaults.set(gardenAlerts, forKey: "gardenAlerts") } }

    private init() {
        defaults.register(defaults: [
            "keepAwake": true,
            "highRefresh": true,
            "liveActivity": true,
            "autoBackup": true,
            "autoHarvest": true,
            "lumpNotify": true,
            "gardenAlerts": true,
        ])
        keepAwake = defaults.bool(forKey: "keepAwake")
        highRefresh = defaults.bool(forKey: "highRefresh")
        liveActivity = defaults.bool(forKey: "liveActivity")
        autoBackup = defaults.bool(forKey: "autoBackup")
        autoHarvest = defaults.bool(forKey: "autoHarvest")
        lumpNotify = defaults.bool(forKey: "lumpNotify")
        gardenAlerts = defaults.bool(forKey: "gardenAlerts")
    }
}
