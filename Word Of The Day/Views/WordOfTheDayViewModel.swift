//
//  WordOfTheDayViewModel.swift
//  Word Of The Day
//
//  Created by Koray Samet Kucukbayraktar on 18.03.2026.
//

import SwiftUI
import WidgetKit
import Combine


@MainActor
class WordOfTheDayViewModel: ObservableObject {

    @Published var currentWord: String = ""
    @Published var currentDefinition: String = ""
    @Published var isLoading: Bool = true
    @Published var showCopyConfirmation: Bool = false
    @Published var showTranslation: Bool = false
    @Published var translatedWord: String = ""
    @Published var wordStack: [String] = []

    // Prefetch cache: word -> definition (nil = no definition found)
    @Published private(set) var prefetchedWords: [String: String] = [:]
    @Published private(set) var isPrefetching: Bool = false
    @Published private(set) var currentWordlevel : LanguageLevel?
    private(set) var selectedLanguage: WiktionaryLanguage = .english
    private(set) var selectedLevel: LanguageLevel = .beginner
    let pronunciationPlayer = PronunciationPlayer()
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        pronunciationPlayer.$isLoading.receive(on:DispatchQueue.main).sink{
            _ in
            self.objectWillChange.send()
        }
        .store(in: &cancellables)
    }
    
    var definitions: [String] {
        currentDefinition
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var canGoBack: Bool { wordStack.count > 1 }

    func levelForWord(_ word: String) -> LanguageLevel? {
        WordPoolLoader.level(of: word, language: selectedLanguage)
    }
    
    func loadWord() {
        isLoading = true
        selectedLevel    = LanguageLevel(rawValue: UserDefaults.standard.string(forKey: "selectedLevel") ?? "") ?? .beginner
        selectedLanguage = WiktionaryLanguage(rawValue: UserDefaults.standard.string(forKey: "selectedLanguage") ?? "") ?? .english
        
        let words = WordPoolLoader.loadWords(language: selectedLanguage, level: selectedLevel)

        Task {
            let entry = await WordOfTheDayEngine.loadWordOfTheDay(
                words: words,
                language: selectedLanguage,
                level: selectedLevel.rawValue
            )
            wordStack.append(entry.word)
            currentWord       = entry.word.capitalized.components(separatedBy: "#")[0]
            currentDefinition = entry.definition
            isLoading         = false
            currentWordlevel  = levelForWord(entry.word)
            
            WidgetCenter.shared.reloadAllTimelines()

            // Prefetch links and generate weekly cache concurrently
            async let prefetch: () = prefetchLinks(in: entry.definition)
            async let weekly: ()   = WordOfTheDayEngine.generateWeeklyEntries(
                words: words,
                language: selectedLanguage,
                level: selectedLevel.rawValue
            )
            _ = await (prefetch, weekly)
        }
    }

    func pronounce() {
        Task {
            await pronunciationPlayer.play(word: currentWord, language: selectedLanguage)
        }
    }
    
    

    func pushWord(_ word: String) {
        wordStack.append(word)
        loadDefinition(for: word)
    }

    func goBack() {
        guard wordStack.count > 1 else { return }
        wordStack.removeLast()
        loadDefinition(for: wordStack.last!)
    }

    func copyToClipboard() {
        UIPasteboard.general.string = currentWord
        showCopyConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showCopyConfirmation = false
        }
    }

    private func loadDefinition(for word: String) {
        isLoading = true

        // Serve from prefetch cache instantly if available
        if let cached = prefetchedWords[word] {
            withAnimation {
                currentWord       = word.capitalized.components(separatedBy: "#")[0]
                currentDefinition = cached
                currentWordlevel  = levelForWord(word)
            }
            Task {
                await prefetchLinks(in: cached)
                withAnimation{
                    isLoading = false
                }
            }
            return
        }

        Task {
            let definition = try? await WiktionaryClient.shared.fetchDefinition(
                word: word,
                language: selectedLanguage
            )
            withAnimation {
                currentWord       = word.capitalized.components(separatedBy: "#")[0]
                currentDefinition = definition ?? ""
                currentWordlevel  = levelForWord(word)
            }
            if let definition {
                prefetchedWords[word] = definition
                await prefetchLinks(in: definition)
                withAnimation{
                    isLoading = false
                }
            }
        }
    }

    private func prefetchLinks(in definition: String) async {
        print("current prefetched words : \(prefetchedWords)")
        let links = extractLinks(from: definition)
        guard !links.isEmpty else { return }

        // Only fetch words we haven't seen yet
        let unfetched = links.filter { prefetchedWords[$0] == nil }
        guard !unfetched.isEmpty else { return }

        isPrefetching = true

        // Fetch all links concurrently
        await withTaskGroup(of: (String, String?).self) { group in
            for word in unfetched {
                group.addTask { [weak self] in
                    guard let self else { return (word, nil) }
                    let definition = try? await WiktionaryClient.shared.fetchDefinition(
                        word: word,
                        language: self.selectedLanguage
                    )
                    return (word, definition)
                }
            }

            var updates: [String: String] = [:]

            for await (word, definition) in group {
                updates[word] = definition ?? ""
            }
            prefetchedWords.merge(updates) { _, new in new }
            print("current prefetched words : \(prefetchedWords)")
        }

        isPrefetching = false
    }

    // Parses [[word]] and [[word|display]] patterns from definition text
    private func extractLinks(from text: String) -> [String] {
        var words: [String] = []
        let pattern = #"\[\[([^\]|]+)(?:\|[^\]]+)?\]\]"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)

        regex.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match,
                  let wordRange = Range(match.range(at: 1), in: text)
            else { return }
            words.append(String(text[wordRange]))
        }

        return words
    }
    
}
