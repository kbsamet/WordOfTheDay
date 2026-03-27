//
//  WordPoolLoader.swift
//  Word Of The Day
//
//  Created by Koray Samet Kucukbayraktar on 14.01.2026.
//

import Foundation


final class WordPoolLoader {

    private static var wordLevelMap: [WiktionaryLanguage: [String: LanguageLevel]] = [:]
    
    static func buildWordLevelMap(for language: WiktionaryLanguage) -> [String: LanguageLevel] {
        if let cached = wordLevelMap[language] { return cached }

        guard let frequencyText = loadFrequencyFile(for: language) else { return [:] }

        let allWords = FrequencyListParser.parse(frequencyText, language: language)
        var map: [String: LanguageLevel] = [:]

        for word in allWords {
            let level = levelForRank(word.rank, language: language)
            map[word.word] = level
        }

        wordLevelMap[language] = map
        return map
    }
    
    static func level(of word: String, language: WiktionaryLanguage) -> LanguageLevel? {
        buildWordLevelMap(for: language)[word]
    }
    
    static func loadWords(
        language: WiktionaryLanguage,
        level: LanguageLevel
    ) -> [String] {
        
        guard let frequencyText = loadFrequencyFile(for: language) else {
            return []
        }
        
        let allWords = FrequencyListParser.parse(frequencyText,language: language)
        
        let levelFiltered = filterByLevel(allWords, level: level,language: language)
        
        
        
        let posFiltered = levelFiltered.filter {
            POSFilter.allowed(for: level).contains($0.pos)
        }
        
        return Array(
            Set(posFiltered.map { $0.word })
        ).sorted()
    }
    
    static func levelForRank(_ rank: Int, language: WiktionaryLanguage) -> LanguageLevel {
        switch language {
        case .english:
            if rank <= 2_000  { return .beginner }
            if rank <= 6_000  { return .intermediate }
            return .advanced

        case .german:
            if rank >= 100_000 { return .beginner }
            if rank >= 50_000  { return .intermediate }
            return .advanced

        case .turkish:
            if rank >= 300_000 { return .beginner }
            if rank >= 5_000   { return .intermediate }
            return .advanced
            
        case .french:
            if rank <= 10_000  { return .beginner }
            if rank <= 30_000  { return .intermediate }
            return .advanced
            
        case .spanish:
            if rank <= 10_000  { return .beginner }
            if rank <= 30_000  { return .intermediate }
            return .advanced
        case .japanese:
            if rank <= 5_000  { return .beginner }
            if rank <= 15_000  { return .intermediate }
            return .advanced
        case .korean:
            if rank <= 5_000  { return .beginner }
            if rank <= 10_000  { return .intermediate }
            return .advanced
        case .russian:
            if rank <= 10_000  { return .beginner }
            if rank <= 30_000  { return .intermediate }
            return .advanced
        }
        
    }
    
    private static func filterByLevel(
        _ words: [FrequencyWord],
        level: LanguageLevel,
        language : WiktionaryLanguage
    ) -> [FrequencyWord] {
        words.filter { levelForRank($0.rank, language: language) == level }
    }
    
    
    
    
    // MARK: - File Loader
    
    private static func loadFrequencyFile(
        for language: WiktionaryLanguage
    ) -> String? {
        
        
        let filename = "\(language.rawValue)"
        
        guard let url = Bundle.main.url(
            forResource: filename,
            withExtension: "txt"
        ) else {
            return nil
        }
        
        return try? String(contentsOf: url)
    }
    
    struct POSFilter {
        
        static func allowed(for level: LanguageLevel) -> Set<PartOfSpeech> {
            switch level {
                case .beginner:
                    return [.noun, .verb, .adjective]
                    
                case .intermediate:
                    return [.noun, .verb, .adjective, .adverb]
                    
                case .advanced:
                    return [.noun, .verb, .adjective, .adverb]
            }
        }
    }
    
    
}
