//
//  WikiService.swift
//  Word Of The Day
//
//  Created by Koray Samet Kucukbayraktar on 13.01.2026.
//

import Foundation



class WiktionaryClient {
    
    
    static let shared = WiktionaryClient()
    private init() {}
    
    // MARK: - Public API
    
    func fetchDefinition(
        word: String,
        language: WiktionaryLanguage
    ) async throws -> String {
        
        let url = buildURL(word: word, language: language)
        print(url)
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoded = try JSONDecoder().decode(WiktionaryParseResponse.self, from: data)
        let wikitext = decoded.parse.wikitext.text
        
        guard let definition = parseDefinition(
            from: wikitext,
            languageHeader: language.sectionHeader,
            language: language
        ) else {
            throw WiktionaryError.definitionNotFound
        }
        
        return definition
    }
    
    // MARK: - URL Builder
    
    private func buildURL(
        word: String,
        language: WiktionaryLanguage
    ) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = language.domain
        components.path = "/w/api.php"
        components.queryItems = [
            .init(name: "action", value: "parse"),
            .init(name: "page", value: word),
            .init(name: "prop", value: "wikitext"),
            .init(name: "format", value: "json"),
            .init(name: "origin", value: "*")
        ]
        
        
        return components.url!
    }
}


extension WiktionaryClient {
    
    func isLanguageHeader(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("==")
        && trimmed.hasSuffix("==")
        && !trimmed.hasPrefix("===")
    }
    
    func parseDefinition(from text: String, languageHeader: String, language : WiktionaryLanguage) -> String?{
        switch language {
        case .english:
            return parseDefinitionEnglish(from: text, languageHeader: languageHeader)
        case .german:
            return parseDefinitionGerman(from: text)
        case .turkish:
            return parseDefinitionTurkish(from: text)
        default:
            return nil
        }
    }
    
    
    func parseDefinitionGerman(from text: String) -> String? {
        let lines = text.components(separatedBy: "\n")

        var collecting = false
        var result: [String] = []

        for line in lines {
            if line.contains("{{Sprache|Deutsch}}") {
                collecting = true
                continue
            }

            // Stop when another language starts
            if collecting && line.hasPrefix("== ") && !line.contains("Deutsch") {
                break
            }

            if collecting {
                result.append(line)
            }
        }
        let definitions = extractDefinitionsGerman(from: result)
        
        let formatted = formatDefinitions(definitions)
        return formatted
    }

    
    func parseDefinitionEnglish(
        from wikitext: String,
        languageHeader: String
    ) -> String? {
        
        guard let langRange = wikitext.range(
            of: "==\(languageHeader)=="
        ) else { return nil }
        
        let section = wikitext[langRange.upperBound...]
        
        let lines = section
            .split(separator: "\n")
            .map(String.init)
        let definitions = extractDefinitionsEnglish(
            lines: lines
        )
        
        let formatted = formatDefinitions(definitions)
        return formatted
    }
    
    func parseDefinitionTurkish(from text: String) -> String? {
        let lines = text.components(separatedBy: "\n")
        var collecting = false
        var result: [String] = []
        
        for line in lines {
            if line.contains("==Türkçe==") {
                collecting = true
                continue
            }
            
            // Stop when another main language section starts (==...== but not ===...===)
            if collecting && line.hasPrefix("==") && !line.hasPrefix("===") {
                break
            }
            
            if collecting {
                result.append(line)
            }
        }
        
        let definitions = extractDefinitionsTurkish(from: result)
        let formatted = formatDefinitions(definitions)
        return formatted
    }
    
    func formatDefinitions(_ definitions: [String]) -> String {
        definitions.enumerated()
            .map { "\($0.element)" }
            .joined(separator: "\n")
    }
    
    
    private func extractDefinitionsEnglish(
        lines: [String]
    ) -> [String] {
        var definitions: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("===") {
                continue
            }
            
            // Definition lines
            if trimmed.hasPrefix("# "),
               !trimmed.hasPrefix("#*"),
               !trimmed.hasPrefix("#:") {
                
                let cleaned = cleanWiktionaryMarkup(
                    trimmed.dropFirst(2).trimmingCharacters(in: .whitespaces)
                )
                definitions.append(cleaned)
                
            }
            if definitions.count > 2 {
                break
            }
        }
        
        return definitions
    }
    
    private func extractDefinitionsGerman(from lines: [String]) -> [String] {
        var definitions: [String] = []
        var collecting = false
        for line in lines {
            if line.contains("{{Bedeutungen}}") {
                collecting = true
                continue
            }

            if collecting {
                // Stop at next section
                if line.hasPrefix("{{") {
                    break
                }

                if line.trimmingCharacters(in: .whitespaces).hasPrefix(":") {
                    let cleaned = cleanWiktionaryMarkup(line)
                    definitions.append(cleaned)
                }
            }
        }

        return definitions
    }
    
    private func extractDefinitionsTurkish(from lines: [String]) -> [String] {
        var definitions: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Extract definition lines (those starting with #)
            if trimmed.hasPrefix("#")  && !trimmed.hasPrefix("#:") {
                let cleaned = cleanWiktionaryMarkup(
                    trimmed.dropFirst(2).trimmingCharacters(in: .whitespaces)
                )
                definitions.append(cleaned)
                
                if definitions.count >= 2 {
                    break
                }
            }
        }
        
        return definitions
    }

    
    
    func cleanWiktionaryMarkup(_ text: String) -> String {
        var result = text
        
        // Remove templates {{...}}
        result = result.replacingOccurrences(
            of: "\\{\\{.*?\\}\\}",
            with: "",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "\\{.*?\\}\\}",
            with: "",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "\\[\\d+\\]",
            with: "",
            options: .regularExpression
        )
        
        result = result.replacingOccurrences(of: "<[^>]+>.*?</[^>]+>", with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: "<[^>]+/>", with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        result = result.replacingOccurrences(
            of: ":",
            with: ""
        )
        
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    func countDefinitions(in text: String) -> Int {
        text.split(separator: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
    }
    
    func randomWordWithDefinition(
        language: WiktionaryLanguage,
        level: LanguageLevel,
        maxRetries: Int = 5
    ) async throws -> WordWithDefinition {
        
        let words = WordPoolLoader.loadWords(
            language: language,
            level: level
        )
        
        guard !words.isEmpty else {
            throw WordSelectionError.emptyWordPool
        }
        
        var attempts = 0
        var remainingWords = words.shuffled()
        
        while attempts < maxRetries, !remainingWords.isEmpty {
            let word = remainingWords.removeFirst()
            
            do {
                let definition = try await WiktionaryClient.shared.fetchDefinition(
                    word: word,
                    language: language
                )
                
                // Validate: at least 2 definitions
                let definitionCount = countDefinitions(in: definition)
                guard definitionCount >= 2 else {
                    attempts += 1
                    continue
                }
                
                return WordWithDefinition(
                    word: word,
                    definition: definition,
                    language: language,
                    level: level
                )
                
            } catch {
                attempts += 1
                continue // try next word
            }
        }
        
        throw WordSelectionError.definitionNotFound
    }
    
}
