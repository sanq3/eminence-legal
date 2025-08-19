//
//  EminenceWidgetLiveActivity.swift
//  EminenceWidget
//
//  Created by san san on 2025/08/18.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct EminenceWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct EminenceWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EminenceWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension EminenceWidgetAttributes {
    fileprivate static var preview: EminenceWidgetAttributes {
        EminenceWidgetAttributes(name: "World")
    }
}

extension EminenceWidgetAttributes.ContentState {
    fileprivate static var smiley: EminenceWidgetAttributes.ContentState {
        EminenceWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: EminenceWidgetAttributes.ContentState {
         EminenceWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: EminenceWidgetAttributes.preview) {
   EminenceWidgetLiveActivity()
} contentStates: {
    EminenceWidgetAttributes.ContentState.smiley
    EminenceWidgetAttributes.ContentState.starEyes
}
