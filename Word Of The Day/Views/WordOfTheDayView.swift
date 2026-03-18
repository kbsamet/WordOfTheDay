//
//  WordOfTheDayView.swift
//  Word Of The Day
//
//  Created by Koray Samet Kucukbayraktar on 26.01.2026.
//

import SwiftUI
import WidgetKit
import Translation


struct WordOfTheDayView: View {

    @State var currentWord: String = "Anleihe"
    @State var currentDefinition: String = "An interest-bearing security; a company borrows from the public.\nA sum of money that is borrowed."
    @State var isLoading: Bool = true
    @State var showCopyConfirmation: Bool = false
    @State var resetSettings: () -> ()
    @State var showTranslation: Bool = false
    @State var wordStack : [String] = []
    @State var selectedLanguage : WiktionaryLanguage = .english
    @State var selectedLevel : LanguageLevel = .beginner
    
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
                        if wordStack.count <= 1 {
                            Spacer().frame(width: 32)
                        }else{
                            Button(action: goBack) {
                                ZStack {
                                    Circle()
                                        .fill(.white.opacity(0.07))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundStyle(.white.opacity(0.45))
                                }
                            }
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

                    // ── Word card
                    if isLoading {
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

                          

                            VStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.white.opacity(0.12))
                                    .frame(width: 60, height: 9)
                                    .padding(.bottom, 10)

                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.white.opacity(0.12))
                                    .frame(width: 200, height: 50)
                                    .padding(.bottom, 12)

                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.white.opacity(0.12))
                                    .frame(width: 80, height: 24)
                            }
                            .padding(.vertical, 36)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .shimmering()
                    } else {
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
                                
                                Spacer().frame(height: 30)
                                // ── Action buttons
                                HStack(spacing: 12) {
                                    Button(action: copyToClipboard) {
                                        ZStack {
                                            Circle()
                                                .fill(.white.opacity(0.07))
                                                .frame(width: 48, height: 48)
                                            Image(systemName: showCopyConfirmation ? "checkmark" : "doc.on.doc")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundStyle(.white.opacity(0.45))
                                        }
                                    }
                                    
                                    Button(action: {
                                        showTranslation = true
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(.white.opacity(0.07))
                                                .frame(width: 48, height: 48)
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
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }

                    // ── Definitions card
                    if isLoading {
                        VStack(alignment: .leading, spacing: 0) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white.opacity(0.12))
                                .frame(width: 80, height: 9)
                                .padding(.bottom, 16)

                            ForEach(0..<2, id: \.self) { index in
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
                                    }
                                    .padding(.top, 1)

                                    VStack(alignment: .leading, spacing: 8) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(.white.opacity(0.12))
                                            .frame(height: 12)

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(.white.opacity(0.12))
                                            .frame(height: 12)

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(.white.opacity(0.08))
                                            .frame(width: 150, height: 12)
                                    }
                                    Spacer()
                                }
                            }
                            Spacer().frame(height: 20)
                        }
                        .padding(20)
                        .background(.white.opacity(0.045))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal, 16)
                        .shimmering()
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Definitions")
                                .font(.system(size: 9, weight: .regular).monospaced())
                                .tracking(3)
                                .foregroundStyle(.white.opacity(0.28))
                                .textCase(.uppercase)
                                .padding(.bottom, 16)
                            Spacer().frame(height: 20)
                            ForEach(Array(definitions[..<min(definitions.count,5)].enumerated()), id: \.offset) { index, line in
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

                                    DefinitionSegmentView(
                                        line: line,
                                        onLinkTap: { linkedWord in
                                            wordStack.append(linkedWord)
                                            navigateToWord(word: linkedWord)
                                        }
                                    )
                                    Spacer()
                                }
                            }
                            Spacer().frame(height: 20)
                        }
                        .padding(20)
                        .background(.white.opacity(0.045))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal, 16)
                    }

                    

                    Spacer()
                }
            }
            .onAppear { getWord() }
            .translationPresentation(isPresented: $showTranslation,
                                            text: currentWord)
        }
    }

    func getWord() {
        isLoading = true
        selectedLevel = LanguageLevel(rawValue: UserDefaults.standard.string(forKey: "selectedLevel") ?? "") ?? .beginner
        selectedLanguage = WiktionaryLanguage(rawValue: UserDefaults.standard.string(forKey: "selectedLanguage") ?? "") ?? .english

        let words = WordPoolLoader.loadWords(language: selectedLanguage, level: selectedLevel)

        Task {
            let entry = await WordOfTheDayEngine.loadWordOfTheDay(words: words, language: selectedLanguage, level: selectedLevel.rawValue)
            wordStack.append(entry.word)
            currentWord = entry.word.capitalized
            currentDefinition = entry.definition
            isLoading = false
            WidgetCenter.shared.reloadAllTimelines()
            await WordOfTheDayEngine.generateWeeklyEntries(words: words, language: selectedLanguage, level: selectedLevel.rawValue)
        }
    }
    
    func navigateToWord(word : String) {
        isLoading = true
        Task{
            let definition = try? await WiktionaryClient.shared.fetchDefinition(word: word, language: selectedLanguage)
            withAnimation{
                currentWord = word.capitalized
                currentDefinition = definition ?? ""
                isLoading = false
            }
    
        }
    }
    
    func goBack(){
        if wordStack.count <= 1{
            return
        }
        let _ = wordStack.popLast()
        navigateToWord(word: wordStack.last!)
        
    }
    func copyToClipboard() {
        UIPasteboard.general.string = currentWord
        showCopyConfirmation = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showCopyConfirmation = false
        }
    }
    

}

extension View {
    func shimmering() -> some View {
        modifier(ShimmeringModifier())
    }
}

struct ShimmeringModifier: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.6 : 1)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    WordOfTheDayView(
        currentWord: "Anleihe",
        currentDefinition: "An interest-bearing security; a company or state borrows money from the public against interest payments.\nA sum of money that is borrowed.",
        isLoading: false,
        resetSettings: {}
    )
}
