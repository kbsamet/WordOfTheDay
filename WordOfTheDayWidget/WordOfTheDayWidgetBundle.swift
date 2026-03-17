//
//  WordOfTheDayWidgetBundle.swift
//  WordOfTheDayWidget
//
//  Created by Koray Samet Kucukbayraktar on 13.01.2026.
//

import WidgetKit
import SwiftUI

@main
struct WordOfTheDayWidgetBundle: WidgetBundle {
    var body: some Widget {
        WordOfTheDayWidget()
        WordOfTheDayWidgetControl()
        WordOfTheDayWidgetLiveActivity()
    }
}
