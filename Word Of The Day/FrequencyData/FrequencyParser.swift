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
        let allowedGermanPOS: Set<String> = [
            "NN",       // noun
            "VVINF",    // verb infinitive
            "VAFIN",    // auxiliary verb
            "ADJ",
            "ADV"
        ]
        
       return text
            .split(separator: "\n")
            .compactMap { line -> FrequencyWord? in
                let parts = line.split(separator: "\t")
                guard parts.count == 4 else { return nil }
                
                let lemma = String(parts[1])
                let pos_str = String(parts[2])
                
                let frequency = Double(String(parts[3])) ?? 0
                
                // POS filtering
                guard allowedGermanPOS.contains(pos_str) else {
                    return nil
                }
                var pos : PartOfSpeech = .noun
                switch pos_str{
                case "NN":
                    pos = .noun
                case "VVINF":
                    pos = .verb
                case "VAFIN":
                    pos = .verb
                case "ADJ":
                    pos = .adjective
                case "ADV":
                    pos = .adverb
                    
                default:
                    pos = .noun
                }
                
                // Word validation (skip punctuation & junk)
                guard lemma.count > 1,
                      lemma.range(
                        of: #"^[a-zA-ZäöüÄÖÜß]+$"#,
                        options: .regularExpression
                      ) != nil
                else {
                    return nil
                }
                return FrequencyWord(
                    rank: Int(frequency), word: lemma, pos: pos
                )
            }
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
