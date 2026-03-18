//
//  WordOfTheDayEngine.swift
//  Word Of The Day
//
//  Created by Koray Samet Kucukbayraktar on 27.01.2026.
//

import Foundation


struct WordOfTheDayEngine {
    static func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    static func wordIndex(for date: Date, total: Int, attemptNumber: Int = 0) -> Int {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let seed = day + (attemptNumber * 366) // deterministic but doesn't collide with following days
        return seed % total
    }
    
    static func isValidPOS(_ pos: PartOfSpeech) -> Bool {
        [.noun, .verb, .adjective, .adverb].contains(pos)
    }
    
    static func extractPOSFromDefinition(
        _ definition: String,
        language: WiktionaryLanguage
    ) -> PartOfSpeech? {
        switch language {
        case .english:
            return extractPOSEnglish(definition)
        case .german:
            return extractPOSGerman(definition)
        case .turkish:
            return extractPOSTurkish(definition)
        default:
            return nil
        }
    }
    
    private static func extractPOSEnglish(_ text: String) -> PartOfSpeech? {
        let lowercased = text.lowercased()
        
        if lowercased.contains("noun") {
            return .noun
        } else if lowercased.contains("verb") {
            return .verb
        } else if lowercased.contains("adjective") {
            return .adjective
        } else if lowercased.contains("adverb") {
            return .adverb
        }
        
        return nil
    }
    
    private static func extractPOSGerman(_ text: String) -> PartOfSpeech? {
        // German entries have {{Wortart|...}} templates
        if text.contains("{{Wortart|Substantiv") {
            return .noun
        } else if text.contains("{{Wortart|Verb") {
            return .verb
        } else if text.contains("{{Wortart|Adjektiv") {
            return .adjective
        } else if text.contains("{{Wortart|Adverb") {
            return .adverb
        }
        
        return nil
    }
    
    private static func extractPOSTurkish(_ text: String) -> PartOfSpeech? {
        // Turkish entries have {{tr-ad}}, {{tr-fiil}}, etc.
        if text.contains("{{tr-ad}}") {
            return .noun
        } else if text.contains("{{tr-fiil}}") {
            return .verb
        } else if text.contains("{{tr-sıfat}}") {
            return .adjective
        } else if text.contains("{{tr-zarf}}") {
            return .adverb
        }
        
        return nil
    }
    
    static func isValidWord(
        definition: String,
        language: WiktionaryLanguage
    ) -> Bool {
        let definitionCount = definition.split(separator: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
        guard definitionCount >= 2 else {
            return false
        }
        return true
    }
    
    
    static func loadWordOfTheDay(
        words: [String],
        language: WiktionaryLanguage,
        level: String
    ) async -> WordEntryData {
        
        let date = Date()
        let key = todayKey()
        
        if let cached = WordCache.shared.load(for: key) {
            return cached
        }
        
        var attemptNumber = 0
        var maxAttempts = min(words.count, 20)
        
        while attemptNumber < maxAttempts {
            let index = wordIndex(for: date, total: words.count, attemptNumber: attemptNumber)
            let word = words[index]
            
            guard let defs = try? await WiktionaryClient.shared.fetchDefinition(
                word: word,
                language: language
            ) else {
                attemptNumber += 1
                continue
            }
            
            // Validate word
            if isValidWord(definition: defs, language: language) {
                let entry = WordEntryData(
                    word: word,
                    definition: defs,
                    language: language.rawValue,
                    level: level
                )
                
                WordCache.shared.save(entry, for: key)
                return entry
            }
            
            attemptNumber += 1
        }
        
        // Fallback if no valid word found
        let fallbackIndex = wordIndex(for: date, total: words.count, attemptNumber: 0)
        let fallbackWord = words[fallbackIndex]
        let fallbackDefs = (try? await WiktionaryClient.shared.fetchDefinition(
            word: fallbackWord,
            language: language
        )) ?? "No definition found."
        
        let entry = WordEntryData(
            word: fallbackWord,
            definition: fallbackDefs,
            language: language.rawValue,
            level: level
        )
        
        WordCache.shared.save(entry, for: key)
        return entry
    }
    
    
    static func generateWeeklyEntries(
           words: [String],
           language: WiktionaryLanguage,
           level: String
       ) async -> Void {
           
           let calendar = Calendar.current
           
           for offset in 0..<7 {
               guard let date = calendar.date(byAdding: .day, value: offset, to: Date()) else { continue }
               
               let key = dayKey(for: date)
               
               if let cached = WordCache.shared.load(for: key) {
                   continue
               }
               
               var attemptNumber = 0
               var maxAttempts = min(words.count, 20)
               
               while attemptNumber < maxAttempts {
                   let index = wordIndex(for: date, total: words.count, attemptNumber: attemptNumber)
                   let word = words[index]
                   
                   guard let defs = try? await WiktionaryClient.shared.fetchDefinition(
                       word: word,
                       language: language
                   ) else {
                       attemptNumber += 1
                       continue
                   }
                   
                   // Validate word
                   if isValidWord(definition: defs, language: language) {
                       let entry = WordEntryData(
                           word: word,
                           definition: defs,
                           language: language.rawValue,
                           level: level
                       )
                       
                       WordCache.shared.save(entry, for: key)
                       break
                   }
                   
                   attemptNumber += 1
               }
           }
       }
    
}
