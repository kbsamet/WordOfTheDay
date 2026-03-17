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
    
    static func wordIndex(for date: Date, total: Int) -> Int {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        return day % total
    }
    
    static func loadWordOfTheDay(
        words: [String],
        language: WiktionaryLanguage,
        level: String
    ) async -> WordEntryData {
        
        let date = Date()
        let key = todayKey()
        
        if let cached = WordCache.shared.load(for: key){
            return cached
        }
        
        let index = wordIndex(for: date, total: words.count)
        let word = words[index]
        

        let defs = (try? await WiktionaryClient.shared.fetchDefinition(
            word: word,
            language: language
        )) ?? "No definition found."
        
        let entry = WordEntryData(
            word: word,
            definition: defs,
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
               
               let index = wordIndex(for: date, total: words.count)
               let word = words[index]
               
               let defs = (try? await WiktionaryClient.shared.fetchDefinition(
                   word: word,
                   language: language
               )) ?? "No definition found."
               
               let entry = WordEntryData(
                   word: word,
                   definition: defs,
                   language: language.rawValue,
                   level: level
               )
               
               WordCache.shared.save(entry, for: key)
           }
       }
    
}
