//
//  ContentView.swift
//  Word Of The Day
//
//  Created by Koray Samet Kucukbayraktar on 13.01.2026.
//

import SwiftUI

struct ContentView: View {
    @State var showWordOfTheDay = false
    @State private var isTransitioning = false

    var body: some View {
        ZStack {
            AppColor.color("oxfordBlue")
                .ignoresSafeArea()

            if showWordOfTheDay {
                WordOfTheDayView(resetSettings: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isTransitioning = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        UserDefaults.standard.removeObject(forKey: "selectedLanguage")
                        UserDefaults.standard.removeObject(forKey: "selectedLevel")
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                            showWordOfTheDay = false
                            isTransitioning = false
                        }
                    }
                })
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    )
                )
                .zIndex(1)

            } else {
                LanguageSelectionView(levelSelected: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isTransitioning = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                            showWordOfTheDay = true
                            isTransitioning = false
                        }
                    }
                })
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    )
                )
                .zIndex(0)
            }

            // Flash overlay on transition
            if isTransitioning {
                AppColor.color("oxfordBlue")
                    .ignoresSafeArea()
                    .opacity(isTransitioning ? 0.6 : 0)
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .onAppear {
            showWordOfTheDay = UserDefaults.standard.string(forKey: "selectedLanguage") != nil
        }
    }
}
