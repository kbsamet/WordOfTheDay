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
    case spanish = "es"
    case japanese = "ja"
    case korean = "ko"
    case russian = "ru"
    
    var domain: String {
        "\(rawValue).wiktionary.org"
    }
    
    var localeCode: String {
        switch self {
            case .english:  return "en-US"
            case .german:   return "de-DE"
            case .turkish:  return "tr-TR"
            case .french:   return "fr-FR"
            case .spanish:  return "es-ES"
            case .japanese: return "ja-JP"
            case .korean:   return "ko-KR"
            case .russian:  return "ru-RU"
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
        case .spanish:
            return "Spanish"
        case .japanese:
            return "Japanese"
        case .korean:
            return "Korean"
        case .russian:
            return "Russian"
        }
    }
    
    var flagAssetName: String {
        switch self {
        case .english: return "flag_uk"
        case .german:  return "flag_de"
        case .french:  return "flag_fr"
        case .turkish: return "flag_tr"
        case .spanish: return "flag_es"
        case .japanese:return "flag_ja"
        case .korean:  return "flag_kr"
        case .russian: return "flag_ru"
        }
    }
}
