//
//  LanguageSelectionView.swift
//  Word Of The Day
//
//  Created by Koray Samet Kucukbayraktar on 26.01.2026.
//

import SwiftUI

struct LanguageRow: View {
    let language: WiktionaryLanguage
    @Binding var selectedLanguage: WiktionaryLanguage?

    var body: some View {
        Button {
            selectedLanguage = language
        } label: {
            VStack(spacing: 0) {
                // Flag
                Image(language.flagAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(.bottom, 14)

                // Language name
                Text(language.displayName)
                    .font(.system(size: 15, weight: .semibold, design: .serif).italic())
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 12)
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

                    // Decorative circle — top right
                    Circle()
                        .stroke(.white.opacity(0.05), lineWidth: 0.5)
                        .frame(width: 80, height: 80)
                        .offset(x: 28, y: -28)
                        .clipped()
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.white.opacity(0.08), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}


struct LanguageSelectionView: View {
    @State private var selectedLanguage: WiktionaryLanguage?
    let levelSelected: () -> ()

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.color("oxfordBlue")
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    // ── Top bar
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Get Started")
                                .font(.system(size: 9, weight: .regular).monospaced())
                                .tracking(3)
                                .foregroundStyle(.white.opacity(0.3))
                                .textCase(.uppercase)

                            Text("Choose Language")
                                .font(.system(size: 26, weight: .semibold, design: .serif).italic())
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 68)
                    .padding(.bottom, 28)

                    // ── Grid
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(WiktionaryLanguage.allCases) { language in
                                LanguageRow(language: language, selectedLanguage: $selectedLanguage)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(item: $selectedLanguage) { language in
                LevelSelectionView(language: language, levelSelected: levelSelected)
            }
        }
    }
}

#Preview {
    LanguageSelectionView(levelSelected: {})
}
