import Foundation
#if canImport(ActivityKit)
import ActivityKit

/// What the Lock Screen / Dynamic Island Live Activity shows. Shared by the app and the widget extension.
@available(iOS 16.1, *)
struct CookieActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// e.g. "12.345 billion"
        var cookies: String
        /// e.g. "12.3B", for the small Dynamic Island
        var shortCookies: String
        /// e.g. "4,200"
        var perSecond: String
        /// when the numbers were taken from the game
        var updated: Date
    }
}
#endif
