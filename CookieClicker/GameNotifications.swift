import UIKit
import UserNotifications

/// Notifications sent while the game is closed: "your sugar lump is ripe".
/// The garden only grows while the game is open, so garden messages are shown in the game instead.
final class GameNotifications {
    static let shared = GameNotifications()
    private let center = UNUserNotificationCenter.current()
    private let lumpID = "sugarLumpRipe"

    func askPermissionIfNeeded() {
        guard AppSettings.shared.lumpNotify else { return }
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            self.center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    /// Back in the game: clear the reminder and any delivered ones.
    func clear() {
        center.removePendingNotificationRequests(withIdentifiers: [lumpID])
        center.removeDeliveredNotifications(withIdentifiers: [lumpID])
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    /// Leaving the game: remind when the sugar lump becomes ripe.
    /// `ripeAt` and `now` are times from the game, in milliseconds.
    func scheduleLump(ripeAt: Double, now: Double, autoHarvest: Bool) {
        center.removePendingNotificationRequests(withIdentifiers: [lumpID])
        guard AppSettings.shared.lumpNotify else { return }
        let seconds = (ripeAt - now) / 1000
        guard seconds > 30 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Your sugar lump is ripe! 🍬"
        content.body = autoHarvest
            ? "Open Cookie Clicker and it will be harvested for you."
            : "Open Cookie Clicker to harvest it before it falls."
        content.sound = .default
        content.badge = 1
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        center.add(UNNotificationRequest(identifier: lumpID, content: content, trigger: trigger))
    }
}
