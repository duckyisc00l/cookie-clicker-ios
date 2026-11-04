import WidgetKit
import SwiftUI
import ActivityKit

@main
struct CookieWidgetsBundle: WidgetBundle {
    var body: some Widget {
        CookieLiveActivity()
    }
}

struct CookieLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CookieActivityAttributes.self) { context in
            LockScreenView(state: context.state)
                .activityBackgroundTint(Color(red: 0.10, green: 0.17, blue: 0.27))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image("cookie").resizable().scaledToFit().frame(width: 46, height: 46)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.perSecond).font(.headline).monospacedDigit()
                        Text("per second").font(.caption2).foregroundColor(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.state.shortCookies).font(.title2.bold()).monospacedDigit()
                        Text("cookies").font(.caption).foregroundColor(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    UpdatedText(date: context.state.updated)
                }
            } compactLeading: {
                Image("cookie").resizable().scaledToFit().frame(width: 22, height: 22)
            } compactTrailing: {
                Text(context.state.shortCookies).font(.caption.bold()).monospacedDigit()
            } minimal: {
                Image("cookie").resizable().scaledToFit().frame(width: 22, height: 22)
            }
        }
    }
}

private struct LockScreenView: View {
    let state: CookieActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 14) {
            Image("cookie").resizable().scaledToFit().frame(width: 58, height: 58)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(state.cookies) cookies")
                    .font(.headline).foregroundColor(.white).lineLimit(1).minimumScaleFactor(0.6)
                Text("\(state.perSecond) per second")
                    .font(.subheadline).foregroundColor(.white.opacity(0.8)).lineLimit(1)
                UpdatedText(date: state.updated)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
    }
}

private struct UpdatedText: View {
    let date: Date
    var body: some View {
        (Text("Updated ") + Text(date, style: .relative) + Text(" ago"))
            .font(.caption).foregroundColor(.white.opacity(0.6))
    }
}
