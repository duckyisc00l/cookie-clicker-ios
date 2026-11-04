import Foundation
import ObjectiveC
import WebKit

/// 120 Hz on ProMotion iPhones.
/// The app itself is allowed above 60 Hz by `CADisableMinimumFrameDurationOnPhone` in Info.plist.
/// WebKit additionally keeps page animations near 60 fps through an internal setting; this turns that off.
/// The setting isn't public, so every step checks that it exists first and quietly does nothing if not.
enum HighRefresh {
    private static let featureKey = "PreferPageRenderingUpdatesNear60FPSEnabled"

    static func apply(_ enabled: Bool, to prefs: WKPreferences) {
        let capAt60 = !enabled

        // 1) direct setter, if this WebKit has it
        let setter = NSSelectorFromString("_setPreferPageRenderingUpdatesNear60FPSEnabled:")
        if let method = class_getInstanceMethod(type(of: prefs), setter) {
            typealias SetBool = @convention(c) (AnyObject, Selector, Bool) -> Void
            let fn = unsafeBitCast(method_getImplementation(method), to: SetBool.self)
            fn(prefs, setter, capAt60)
        }

        // 2) WebKit's feature list, the newer way the same setting is exposed
        let featuresSel = NSSelectorFromString("_features")
        let enableSel = NSSelectorFromString("_setEnabled:forFeature:")
        guard WKPreferences.responds(to: featuresSel),
              let enableMethod = class_getInstanceMethod(type(of: prefs), enableSel),
              let list = WKPreferences.perform(featuresSel)?.takeUnretainedValue() as? [NSObject]
        else { return }
        typealias SetFeature = @convention(c) (AnyObject, Selector, Bool, AnyObject) -> Void
        let setFeature = unsafeBitCast(method_getImplementation(enableMethod), to: SetFeature.self)
        let keySel = NSSelectorFromString("key")
        for feature in list where feature.responds(to: keySel) {
            if (feature.perform(keySel)?.takeUnretainedValue() as? String) == featureKey {
                setFeature(prefs, enableSel, capAt60, feature)
            }
        }
    }
}
