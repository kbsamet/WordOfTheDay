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
        case .french:
            return parseFrench(text)
        case .spanish:
            return parseFrench(text)
        case .japanese:
            return parseJapanese(text)
        case .korean:
            return parseKorean(text)
        case .russian:
            return parseRussian(text)
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
    
    private static func parseFrench(_ text: String) -> [FrequencyWord] {
        return text
            .split(whereSeparator: \.isNewline)
            .enumerated()
            .compactMap { index, line -> FrequencyWord? in
                let parts = line.split(separator: " ")
                guard parts.count >= 2 else { return nil }

                let word = String(parts[0])
                let frequency = Int(parts[1]) ?? 0
                let pattern = #"^[a-zA-ZàâäéèêëîïôùûüÿçœæÀÂÄÉÈÊËÎÏÔÙÛÜŸÇŒÆ]+$"#
                
                guard word.range(of: pattern, options: .regularExpression) != nil else { return nil }

                return FrequencyWord(rank: index + 1, word: word, pos: .noun)
            }
    }
    private static func parseJapanese(_ text: String) -> [FrequencyWord] {
        return text
            .split(whereSeparator: \.isNewline)
            .enumerated()
            .compactMap { index, line -> FrequencyWord? in
                let parts = line.split(separator: " ")
                guard parts.count >= 2 else { return nil }

                let word = String(parts[0])
                
                let pattern = #"^[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF\u3400-\u4DBF]+$"#
                guard word.range(of: pattern, options: .regularExpression) != nil else { return nil }
                
                return FrequencyWord(rank: index + 1, word: word, pos: .noun)
            }
    }
    private static func parseKorean(_ text: String) -> [FrequencyWord] {
        return text
            .split(whereSeparator: \.isNewline)
            .compactMap { line -> FrequencyWord? in
                let trimmed = String(line).trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return nil }

                // Format: "1. 것 - create한 - A"
                let parts = trimmed.components(separatedBy: " - ")
                guard parts.count >= 3 else { return nil }

                // Extract rank from "1. 것"
                let rankWord = parts[0].trimmingCharacters(in: .whitespaces)
                let rankWordParts = rankWord.components(separatedBy: ". ")
                guard rankWordParts.count >= 2,
                      let rank = Int(rankWordParts[0])
                else { return nil }

                let word = rankWordParts[1].trimmingCharacters(in: .whitespaces)
                let grade = parts[2].trimmingCharacters(in: .whitespaces)

                // Map grade to rank range for levelForRank
                let adjustedRank: Int
                switch grade {
                case "A": adjustedRank = rank
                case "B": adjustedRank = 3000 + rank
                case "C": adjustedRank = 7000 + rank
                default:  adjustedRank = rank
                }

                return FrequencyWord(rank: adjustedRank, word: word, pos: .noun)
            }
    }
    private static func parseRussian(_ text: String) -> [FrequencyWord] {
        return text
            .split(whereSeparator: \.isNewline)
            .enumerated()
            .compactMap { index, line -> FrequencyWord? in
                let parts = line.split(separator: " ")
                guard parts.count >= 2 else { return nil }
                let word = String(parts[0]) 
                let pattern = #"^[\u0400-\u04FF]+$"#
                
                guard word.range(of: pattern, options: .regularExpression) != nil && word.count > 1 else { return nil }
                return FrequencyWord(rank: index + 1, word: word, pos: .noun)
            }
    }

}
