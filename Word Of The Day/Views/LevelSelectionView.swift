//
//  LevelSelectionView.swift
//  Word Of The Day
//
//  Created by Koray Samet Kucukbayraktar on 26.01.2026.
//

import SwiftUI

struct LevelSelectionView: View {
    let language: WiktionaryLanguage?
    @State private var selectedLevel: LanguageLevel?
    let levelSelected: () -> ()


    func description(for level: LanguageLevel) -> String {
        switch level {
        case .beginner:     return "Top 1,000 common words"
        case .intermediate: return "Daily vocabulary"
        case .advanced:     return "Rare & academic words"
        }
    }

    func savePreferences() {
        guard let language, let selectedLevel else { return }
        UserDefaults.standard.set(language.rawValue, forKey: "selectedLanguage")
        UserDefaults.standard.set(selectedLevel.rawValue, forKey: "selectedLevel")
        WordCache.shared.reset()
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColor.color("oxfordBlue")
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Top bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Almost there")
                            .font(.system(size: 9, weight: .regular).monospaced())
                            .tracking(3)
                            .foregroundStyle(.white.opacity(0.3))
                            .textCase(.uppercase)

                        Text("Select Level")
                            .font(.system(size: 26, weight: .semibold, design: .serif).italic())
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.top, 68)
                .padding(.bottom, 32)

                // ── Level cards
                VStack(spacing: 14) {
                    ForEach(LanguageLevel.allCases) { level in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedLevel = level
                            }
                        } label: {
                            HStack(spacing: 16) {

                                Circle()
                                    .fill(level.color.opacity(selectedLevel == level ? 1 : 0.25))
                                    .frame(width: 8, height: 8)

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(level.rawValue)
                                        .font(.system(size: 22, weight: .semibold, design: .serif).italic())
                                        .foregroundStyle(.white.opacity(0.92))
                                }

                                Spacer()

                                if selectedLevel == level {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(level.color)
                                        .padding(8)
                                        .background(level.color.opacity(0.12))
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundStyle(.white.opacity(0.2))
                                }
                            }
                            .padding(.horizontal, 22)
                            .padding(.vertical, 22)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 18)
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

                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(
                                        selectedLevel == level
                                        ? level.color.opacity(0.45)
                                            : .white.opacity(0.07),
                                        lineWidth: selectedLevel == level ? 1 : 0.5
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)

                // Reserve space so cards don't hide behind the button
                Spacer()
            }

            // ── Continue button
            if selectedLevel != nil {
                VStack(spacing: 0) {
                    // Fade out the content above
                    LinearGradient(
                        colors: [
                            AppColor.color("oxfordBlue").opacity(0),
                            AppColor.color("oxfordBlue")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)

                    Button {
                        savePreferences()
                        levelSelected()
                    } label: {
                        HStack(spacing: 10) {
                            Text("Continue")
                                .font(.system(size: 16, weight: .semibold, design: .serif).italic())
                                .foregroundStyle(AppColor.color("oxfordBlue"))

                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppColor.color("oxfordBlue"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(
                            selectedLevel.map { $0.color } ?? .white
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 36)
                    .background(AppColor.color("oxfordBlue"))
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: selectedLevel)
            }
        }
        .navigationBarHidden(true)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: selectedLevel)
    }
}

#Preview {
    LevelSelectionView(language: .english, levelSelected: {})
}
