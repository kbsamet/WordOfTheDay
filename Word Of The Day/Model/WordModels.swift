//
//  WordModels.swift
//  Word Of The Day
//
//  Created by Koray Samet Kucukbayraktar on 13.01.2026.
//

import WidgetKit
import SwiftUI

struct WiktionaryParseResponse: Decodable {
    let parse: Parse
}

struct Parse: Decodable {
    let wikitext: WikiText
}

struct WikiText: Decodable {
    let text: String

    private enum CodingKeys: String, CodingKey {
        case text = "*"
    }
}
struct WordWithDefinition {
    let word: String
    let definition: String
    let language: WiktionaryLanguage
    let level: LanguageLevel
}

struct WordEntry: Codable, TimelineEntry {
    let date: Date
    let data: WordEntryData?
}

struct CachedWord: Codable {
    let dateKey: String
    let data: WordEntryData?
}


struct WordEntryData: Codable {
    let word: String
    let definition: String
    let language: String
    let level: String
}


enum WiktionaryError: Error {
    case definitionNotFound
    case invalidResponse
}

enum WordSelectionError: Error {
    case emptyWordPool
    case definitionNotFound
}
enum LanguageLevel : String,CaseIterable,Identifiable {
    var id: String { rawValue }
    case beginner = "Common"
    case intermediate = "Uncommon"
    case advanced = "Rare"
    
    var color : Color{
        switch self {
        case .beginner:
            return AppColor.color("skyBlue")
        case .intermediate:
            return AppColor.color("lavender")
        case .advanced:
            return AppColor.color("gold")
        }
    }
}

enum WiktionaryLanguage: String,CaseIterable,Identifiable {
    var id: String { rawValue }
    
    case english = "en"
    case turkish = "tr"
    case german = "de"
    case french = "fr"

    var domain: String {
        "\(rawValue).wiktionary.org"
    }

    var sectionHeader: String {
        switch self {
        case .english: return "English"
        case .turkish: return "Türkçe"
        case .german: return "Deutsch"
        case .french: return "Français"
        }
    }
    
    var displayName : String{
        switch self {
        case .english:
            return "English"
        case .french:
            return "French"
        case .german:
            return "German"
        case .turkish:
            return "Turkish"
        }
    }
    
    var flagAssetName: String {
        switch self {
        case .english: return "flag_uk"
        case .german:  return "flag_de"
        case .french:  return "flag_fr"
        case .turkish:  return "flag_tr"
        }
    }
}
