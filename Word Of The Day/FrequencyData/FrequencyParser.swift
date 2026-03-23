//
//  FrequencyParser.swift
//  Word Of The Day
//
//  Created by Koray Samet Kucukbayraktar on 13.01.2026.
//

import Foundation

enum PartOfSpeech: String {
    case noun = "n"
    case verb = "v"
    case adjective = "a"
    case adverb = "r"
    
    case preposition = "i"
    case pronoun = "p"
    case conjunction = "c"
    case determiner = "d"
    case existential = "e"
    case numeral = "m"
}

struct FrequencyWord {
    let rank: Int
    let word: String
    let pos: PartOfSpeech
}

class FrequencyListParser {
    
    
    static func parse(_ text: String,language : WiktionaryLanguage) -> [FrequencyWord] {
        switch language {
        case .english:
            return parseEnglish(text)
        case .german:
            return parseGerman(text)
        case .turkish:
            return parseTurkish(text)
        default:
            return []
        }
    }
    
    private static func parseEnglish(_ text : String)  -> [FrequencyWord]{
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map(String.init)
        
        var results: [FrequencyWord] = []
        
        for line in lines {
            if line.hasPrefix("rank") || line.isEmpty {
                continue
            }
            
            let columns = line.split(separator: "\t")
            guard columns.count >= 3 else { continue }
            
            guard let rank = Int(columns[0]) else { continue }
            
            let word = String(columns[1])
            let posRaw = String(columns[2])
            
            guard let pos = PartOfSpeech(rawValue: posRaw) else {
                continue
            }
            
            results.append(
                FrequencyWord(rank: rank, word: word, pos: pos)
            )
        }
        
        return results
    }
    private static func parseGerman(_ text: String) -> [FrequencyWord] {
        let allowedGermanPOS: Set<String> = ["NN", "VVINF", "VAFIN", "ADJ", "ADV"]

        let posMap: [String: PartOfSpeech] = [
            "NN":    .noun,
            "VVINF": .verb,
            "VAFIN": .verb,
            "ADJ":   .adjective,
            "ADV":   .adverb
        ]

        // Group by lemma, keep highest frequency (max rank) per lemma
        var best: [String: FrequencyWord] = [:]

        for line in text.split(separator: "\n") {
            let parts = line.split(separator: "\t")
            guard parts.count == 4,
                  let pos = posMap[String(parts[2])],
                  let frequency = Double(String(parts[3]))
            else { continue }

            let lemma = String(parts[1])

            guard lemma.count > 1,
                  lemma.range(of: #"^[a-zA-ZäöüÄÖÜß]+$"#, options: .regularExpression) != nil
            else { continue }

            let rank = Int(frequency)
            let candidate = FrequencyWord(rank: rank, word: lemma, pos: pos)

            // For German, higher rank = more frequent (beginner threshold is >= 100_000)
            // so keep the entry with the highest rank number
            if let existing = best[lemma] {
                if rank > existing.rank { best[lemma] = candidate }
            } else {
                best[lemma] = candidate
            }
        }

        return Array(best.values)
    }
    
    private static func parseTurkish(_ text: String) -> [FrequencyWord] {
        return text
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .compactMap { line -> FrequencyWord? in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return nil }
                
                let parts = trimmed.split(separator: " ", maxSplits: 1)
                guard parts.count == 2 else { return nil }
                
                let word = String(parts[0])
                let frequency = Int(String(parts[1])) ?? 0
                
                // Word validation (skip empty strings and punctuation)
                guard !word.isEmpty,
                      word.range(
                        of: #"^[a-zA-Zçğıöşüa-zÇĞİÖŞÜ]+$"#,
                        options: .regularExpression
                      ) != nil
                else {
                    return nil
                }
                
                return FrequencyWord(
                    rank: frequency, word: word, pos: .noun
                )
            }
    }
}
