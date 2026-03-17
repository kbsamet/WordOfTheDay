//
//  WordOfTheDayView.swift
//  Word Of The Day
//
//  Created by Koray Samet Kucukbayraktar on 26.01.2026.
//

import SwiftUI
import WidgetKit

struct WordOfTheDayView: View {

    @State var currentWord: String = "Anleihe"
    @State var currentDefinition: String = "An interest-bearing security; a company borrows from the public.\nA sum of money that is borrowed."
    @State var resetSettings: () -> ()

    var definitions: [String] {
        currentDefinition
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // ── Background
                AppColor.color("oxfordBlue")
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    // ── Top bar
                    HStack {
                        Text("Word of the Day")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.white.opacity(0.38))
                            .tracking(0.4)

                        Spacer()

                        Button(action: resetSettings) {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.07))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "gearshape")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.45))
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 16)

                    // ── Word card
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColor.color("cardBlueDark"),
                                        AppColor.color("cardBlue")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        // Decorative circle
                        Circle()
                            .stroke(.white.opacity(0.05), lineWidth: 0.5)
                            .frame(width: 160, height: 160)
                            .offset(x: 70, y: -52)

                        VStack(spacing: 0) {
                            Text("noun")
                                .font(.system(size: 9, weight: .regular).monospaced())
                                .tracking(3)
                                .foregroundStyle(.white.opacity(0.3))
                                .textCase(.uppercase)
                                .padding(.bottom, 10)

                            Text(currentWord)
                                .font(.system(size: 50, weight: .semibold, design: .serif).italic())
                                .foregroundStyle(.white)
                                .tracking(-0.8)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .padding(.bottom, 12)

                            Text((WiktionaryLanguage(rawValue: UserDefaults.standard.string(forKey: "selectedLanguage") ?? "") ?? .english).displayName)
                                .font(.system(size: 9, weight: .regular).monospaced())
                                .tracking(1)
                                .foregroundStyle(.white.opacity(0.45))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(.white.opacity(0.07))
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 36)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                    // ── Definitions card
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Definitions")
                            .font(.system(size: 9, weight: .regular).monospaced())
                            .tracking(3)
                            .foregroundStyle(.white.opacity(0.28))
                            .textCase(.uppercase)
                            .padding(.bottom, 16)
                        Spacer().frame(height: 20)
                        ForEach(Array(definitions.enumerated()), id: \.offset) { index, line in
                            if index > 0 {
                                Divider()
                                    .overlay(.white.opacity(0.07))
                                    .padding(.vertical, 12)
                            }

                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(.white.opacity(0.08))
                                        .frame(width: 20, height: 20)
                                    Text("\(index + 1)")
                                        .font(.system(size: 9, weight: .regular).monospaced())
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                .padding(.top, 1)

                                Text(line)
                                    .font(.system(size: 14, weight: .regular, design: .serif))
                                    .foregroundStyle(.white.opacity(0.72))
                                    .lineSpacing(5)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Spacer().frame(height: 20)
                    }
                    .padding(20)
                    .background(.white.opacity(0.045))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal, 16)

                    

                    Spacer()
                }
            }
            .onAppear { getWord() }
        }
    }

    func getWord() {
        let selectedLevel: LanguageLevel = LanguageLevel(rawValue: UserDefaults.standard.string(forKey: "selectedLevel") ?? "") ?? .beginner
        let selectedLanguage: WiktionaryLanguage = WiktionaryLanguage(rawValue: UserDefaults.standard.string(forKey: "selectedLanguage") ?? "") ?? .english

        let words = WordPoolLoader.loadWords(language: selectedLanguage, level: selectedLevel)

        Task {
            let entry = await WordOfTheDayEngine.loadWordOfTheDay(words: words, language: selectedLanguage, level: selectedLevel.rawValue)
            currentWord = entry.word.capitalized
            currentDefinition = entry.definition
            WidgetCenter.shared.reloadAllTimelines()
            await WordOfTheDayEngine.generateWeeklyEntries(words: words, language: selectedLanguage, level: selectedLevel.rawValue)
        }
    }
}

#Preview {
    WordOfTheDayView(
        currentWord: "Anleihe",
        currentDefinition: "An interest-bearing security; a company or state borrows money from the public against interest payments.\nA sum of money that is borrowed.",
        resetSettings: {}
    )
}
