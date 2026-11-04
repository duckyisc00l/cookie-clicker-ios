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

    private init() {
        defaults.register(defaults: [
            "keepAwake": true,
            "highRefresh": true,
            "liveActivity": true,
            "autoBackup": true,
        ])
        keepAwake = defaults.bool(forKey: "keepAwake")
        highRefresh = defaults.bool(forKey: "highRefresh")
        liveActivity = defaults.bool(forKey: "liveActivity")
        autoBackup = defaults.bool(forKey: "autoBackup")
    }
}
