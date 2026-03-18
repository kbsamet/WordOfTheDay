//
//  WordPoolLoader.swift
//  Word Of The Day
//
//  Created by Koray Samet Kucukbayraktar on 14.01.2026.
//

import Foundation


final class WordPoolLoader {

    
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
    
    private static func filterByLevel(
        _ words: [FrequencyWord],
        level: LanguageLevel,
        language : WiktionaryLanguage
    ) -> [FrequencyWord] {
        switch language {
        case .english:
            return filterEnglish(words, level: level)
        case .german:
            return filterGerman(words, level: level)
        case .turkish:
            return filterTurkish(words, level: level)
        default:
            return words
        }
        
    }
    
    
    private static func filterEnglish(_ words: [FrequencyWord],level: LanguageLevel) -> [FrequencyWord]{
        
        switch level {
        case .beginner:
            return words.filter { $0.rank <= 2_000 }
            
        case .intermediate:
            return words.filter { $0.rank > 2_000 && $0.rank <= 6_000 }
            
        case .advanced:
            return words.filter { $0.rank > 6_000 && $0.rank <= 20_000 }
        }
    }
    
    private static func filterGerman(_ words: [FrequencyWord],level: LanguageLevel) -> [FrequencyWord]{
        
        switch level {
        case .beginner:
            return words.filter { $0.rank >= 100_000 }
            
        case .intermediate:
            return words.filter { $0.rank > 50_000 && $0.rank <= 100_000 }
            
        case .advanced:
            return words.filter { $0.rank <= 50_000 }
        }
    }
    
    private static func filterTurkish(_ words: [FrequencyWord], level: LanguageLevel) -> [FrequencyWord] {
        switch level {
        case .beginner:
            return words.filter { $0.rank >= 300_000 }
            
        case .intermediate:
            return words.filter { $0.rank < 300_000 && $0.rank >= 5_000 }
            
        case .advanced:
            return words.filter { $0.rank < 5_000 }
        }
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
