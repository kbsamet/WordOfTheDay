//
//  WordOfTheDayView.swift
//  Word Of The Day
//
//  Created by Koray Samet Kucukbayraktar on 26.01.2026.
//
//
//  WordOfTheDayView.swift
//  Word Of The Day
//

import SwiftUI
import Translation

struct WordOfTheDayView: View {

    @StateObject private var vm = WordOfTheDayViewModel()
    var resetSettings: () -> ()

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.color("oxfordBlue").ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar
                    wordCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    definitionsCard
                        .padding(.horizontal, 16)
                    Spacer()
                }
            }
            .onAppear { vm.loadWord() }
            .translationPresentation(isPresented: $vm.showTranslation, text: vm.currentWord)
        }
    }

    private var topBar: some View {
        HStack {
            if vm.canGoBack {
                Button(action: vm.goBack) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.07))
                            .frame(width: 32, height: 32)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
            } else {
                Spacer().frame(width: 32)
            }

            Spacer()

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
    }

    @ViewBuilder
    private var wordCard: some View {
        if vm.isLoading {
            loadingWordCard
        } else {
            loadedWordCard
        }
    }

    private var loadingWordCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(
                    colors: [AppColor.color("cardBlueDark"), AppColor.color("cardBlue")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.12)).frame(width: 60, height: 9).padding(.bottom, 10)
                RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.12)).frame(width: 200, height: 50).padding(.bottom, 12)
                RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.12)).frame(width: 80, height: 24)
            }
            .padding(.vertical, 36)
        }
    }

    private var loadedWordCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(
                    colors: [AppColor.color("cardBlueDark"), AppColor.color("cardBlue")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))

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

                Text(vm.currentWord)
                    .font(.system(size: 50, weight: .semibold, design: .serif).italic())
                    .foregroundStyle(.white)
                    .tracking(-0.8)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.bottom, 12)

                Text(vm.selectedLanguage.displayName)
                    .font(.system(size: 9, weight: .regular).monospaced())
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.07))
                    .clipShape(Capsule())

                Spacer().frame(height: 30)

                HStack(spacing: 12) {
                    Button(action: vm.copyToClipboard) {
                        ZStack {
                            Circle().fill(.white.opacity(0.07)).frame(width: 48, height: 48)
                            Image(systemName: vm.showCopyConfirmation ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                    }

                    Button { vm.showTranslation = true } label: {
                        ZStack {
                            Circle().fill(.white.opacity(0.07)).frame(width: 48, height: 48)
                            Image(systemName: "translate")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                    }
                }
                .padding(.top, 12)
            }
            .padding(.vertical, 36)
        }
    }

    @ViewBuilder
    private var definitionsCard: some View {
        if vm.isLoading {
            loadingDefinitionsCard
        } else {
            loadedDefinitionsCard
        }
    }

    private var loadingDefinitionsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.12)).frame(width: 80, height: 9).padding(.bottom, 16)
            ForEach(0..<2, id: \.self) { index in
                if index > 0 { Divider().overlay(.white.opacity(0.07)).padding(.vertical, 12) }
                HStack(alignment: .top, spacing: 12) {
                    Circle().fill(.white.opacity(0.08)).frame(width: 20, height: 20).padding(.top, 1)
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.12)).frame(height: 12)
                        RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.12)).frame(height: 12)
                        RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.08)).frame(width: 150, height: 12)
                    }
                    Spacer()
                }
            }
            Spacer().frame(height: 20)
        }
        .padding(20)
        .background(.white.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var loadedDefinitionsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Definitions")
                .font(.system(size: 9, weight: .regular).monospaced())
                .tracking(3)
                .foregroundStyle(.white.opacity(0.28))
                .textCase(.uppercase)
                .padding(.bottom, 16)

            Spacer().frame(height: 20)

            ForEach(Array(vm.definitions.prefix(5).enumerated()), id: \.offset) { index, line in
                if index > 0 {
                    Divider().overlay(.white.opacity(0.07)).padding(.vertical, 12)
                }
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle().fill(.white.opacity(0.08)).frame(width: 20, height: 20)
                        Text("\(index + 1)")
                            .font(.system(size: 9, weight: .regular).monospaced())
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.top, 1)

                    DefinitionSegmentView(
                        line: line,
                        onLinkTap: { linkedWord in vm.pushWord(linkedWord) },
                        prefetchedWords: vm.prefetchedWords
                    )

                    Spacer()
                }
            }

            Spacer().frame(height: 20)
        }
        .padding(20)
        .background(.white.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    WordOfTheDayView(resetSettings: {})
}
