//
//  WordOfTheDayWidgetLiveActivity.swift
//  WordOfTheDayWidget
//
//  Created by Koray Samet Kucukbayraktar on 13.01.2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WordOfTheDayWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct WordOfTheDayWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WordOfTheDayWidgetAttributes.self) { context in
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

extension WordOfTheDayWidgetAttributes {
    fileprivate static var preview: WordOfTheDayWidgetAttributes {
        WordOfTheDayWidgetAttributes(name: "World")
    }
}

extension WordOfTheDayWidgetAttributes.ContentState {
    fileprivate static var smiley: WordOfTheDayWidgetAttributes.ContentState {
        WordOfTheDayWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: WordOfTheDayWidgetAttributes.ContentState {
         WordOfTheDayWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: WordOfTheDayWidgetAttributes.preview) {
   WordOfTheDayWidgetLiveActivity()
} contentStates: {
    WordOfTheDayWidgetAttributes.ContentState.smiley
    WordOfTheDayWidgetAttributes.ContentState.starEyes
}
