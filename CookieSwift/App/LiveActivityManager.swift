import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Keeps the Lock Screen / Dynamic Island Live Activity in step with the game.
/// iOS only lets the app start or update it while the app is running, so the numbers shown are from
/// the last time you played, with an "updated ... ago" time.
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var latest: (cookies: String, short: String, perSecond: String)?
    private var lastPush = Date.distantPast

    var isAvailable: Bool {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) { return ActivityAuthorizationInfo().areActivitiesEnabled }
        #endif
        return false
    }

    /// Called with fresh numbers from the game every few seconds.
    func gameStats(cookies: String, short: String, perSecond: String) {
        latest = (cookies, short, perSecond)
        if Date().timeIntervalSince(lastPush) >= 15 { push() }
    }

    /// Sends the latest numbers now (used when leaving the app).
    func push() {
        #if canImport(ActivityKit)
        guard #available(iOS 16.2, *), let latest = latest else { return }
        guard AppSettings.shared.liveActivity, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        lastPush = Date()
        let state = CookieActivityAttributes.ContentState(
            cookies: latest.cookies, shortCookies: latest.short, perSecond: latest.perSecond, updated: Date())
        let content = ActivityContent(state: state, staleDate: nil)
        let running = Activity<CookieActivityAttributes>.activities
        if let activity = running.first {
            Task { await activity.update(content) }
            for extra in running.dropFirst() { Task { await extra.end(nil, dismissalPolicy: .immediate) } }
        } else {
            _ = try? Activity<CookieActivityAttributes>.request(
                attributes: CookieActivityAttributes(), content: content, pushType: nil)
        }
        #endif
    }

    func endAll() {
        #if canImport(ActivityKit)
        guard #available(iOS 16.2, *) else { return }
        for activity in Activity<CookieActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
        #endif
    }
}
