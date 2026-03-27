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
        language: WiktionaryLanguage,
        isRedirect: Bool = false,
        redirectedFrom : String = ""
    ) async throws -> String {
        
        let url = buildURL(word: word, language: language)
        print(url)
        if isRedirect{
            print("redirected from \(redirectedFrom)")
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoded = try JSONDecoder().decode(WiktionaryParseResponse.self, from: data)
        let wikitext = decoded.parse.wikitext.text
        
        guard let definition = parseDefinition(
            from: wikitext,
            language: language
        ) else {
            throw WiktionaryError.definitionNotFound
        }
        
        switch language{
        case .japanese:
            if definition.hasPrefix("[[ja-redirect:") {
                if isRedirect{
                    return ""
                }
                let hiragana = definition.replacingOccurrences(of: "[[ja-redirect:", with: "").replacingOccurrences(of: "]]", with: "")
                return try await fetchDefinition(word: hiragana, language: .japanese,isRedirect: true,redirectedFrom: word)
            }
        default:
            break
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
    
    func parseDefinition(from text: String, language : WiktionaryLanguage) -> String?{
        switch language {
        case .english:
            return parseDefinitionEnglish(from: text)
        case .german:
            return parseDefinitionGerman(from: text)
        case .turkish:
            return parseDefinitionTurkish(from: text)
        case .french:
            return parseDefinitionFrench(from: text)
        case .spanish:
            return parseDefinitionSpanish(from: text)
        case .japanese:
            return parseDefinitionJapanese(from: text)
        case .korean:
            return parseDefinitionKorean(from: text)
        case .russian:
            return parseDefinitionRussian(from: text)
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
        from wikitext: String
    ) -> String? {
        
        guard let langRange = wikitext.range(
            of: "==English=="
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
    
    func parseDefinitionFrench(from text: String) -> String? {
        let lines = text.components(separatedBy: "\n")
        var collecting = false
        var result: [String] = []

        for line in lines {
            if line.contains("== {{langue|fr}} ==") || line.contains("==français==") {
                collecting = true
                continue
            }

            // Stop when another main language section starts
            if collecting && line.hasPrefix("==") && !line.hasPrefix("===") {
                break
            }

            if collecting {
                result.append(line)
            }
        }

        let definitions = extractDefinitionsFrench(from: result)
        let formatted = formatDefinitions(definitions)
        return formatted
    }
    
    func parseDefinitionSpanish(from text: String) -> String? {
        let lines = text.components(separatedBy: "\n")
        var collecting = false
        var result: [String] = []

        for line in lines {
            if line.contains("== {{lengua|es}} ==") || line.contains("==español==") {
                collecting = true
                continue
            }
            if collecting && line.hasPrefix("==") && !line.hasPrefix("===") { break }
            if collecting { result.append(line) }
        }

        let definitions = extractDefinitionsSpanish(from: result)
        let formatted = formatDefinitions(definitions)
        return formatted
    }
    
    func parseDefinitionJapanese(from text: String) -> String? {
        // Detect kanji stub — redirects to hiragana form
        // e.g. {{wagokanji of|たべる}} or {{ja-kanjitab}}
        if let redirect = extractJapaneseRedirect(from: text) {
            // Return a special marker so the client can re-fetch
            return "[[ja-redirect:\(redirect)]]"
        }

        let lines = text.components(separatedBy: "\n")
        var collecting = false
        var result: [String] = []

        for line in lines {
            if line.contains("==Japanese==") || line.contains("=={{L|ja}}==") {
                collecting = true
                continue
            }
            if collecting && line.hasPrefix("==") && !line.hasPrefix("===") { break }
            if collecting { result.append(line) }
        }

        let definitions = extractDefinitionsJapanese(from: result)
        let formatted = formatDefinitions(definitions)
        return formatted.isEmpty ? nil : formatted
    }

    private func extractJapaneseRedirect(from text: String) -> String? {
        // {{wagokanji of|たべる}} or {{ja-see|たべる}}
        let pattern = #"\{\{(?:wagokanji of|ja-see|ja-see-kango|ja-kana-map)\|([^\}|]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text)
        else { return nil }
        return String(text[range])
    }
    
    func parseDefinitionKorean(from text: String) -> String? {
        let lines = text.components(separatedBy: "\n")
        var collecting = false
        var result: [String] = []

        for line in lines {
            if line.contains("== 한국어 ==") || line.contains("==한국어==") {
                collecting = true
                continue
            }
            if collecting && line.hasPrefix("==") && !line.hasPrefix("===") { break }
            if collecting { result.append(line) }
        }

        let definitions = extractDefinitionsKorean(from: result)
        let formatted = formatDefinitions(definitions)
        return formatted.isEmpty ? nil : formatted
    }
    
    func parseDefinitionRussian(from text: String) -> String? {
        let lines = text.components(separatedBy: "\n")
        var collecting = false
        var result: [String] = []

        for line in lines {
            // Russian Wiktionary uses = {{-ru-}} =
            if line.contains("{{-ru-}}") {
                collecting = true
                continue
            }
            // Stop at next language section
            if collecting && line.hasPrefix("= {{-") && !line.contains("-ru-") { break }
            if collecting { result.append(line) }
        }

        let definitions = extractDefinitionsRussian(from: result)
        let formatted = formatDefinitions(definitions)
        return formatted.isEmpty ? nil : formatted
    }

    private func extractDefinitionsRussian(from lines: [String]) -> [String] {
        var definitions: [String] = []
        var inMeaningsSection = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Only collect definitions under ==== Значение ====
            if trimmed.contains("Значение") {
                inMeaningsSection = true
                continue
            }

            // Stop collecting when another ==== section starts
            if inMeaningsSection && trimmed.hasPrefix("====") {
                break
            }

            guard inMeaningsSection,
                  trimmed.hasPrefix("# "),
                  !trimmed.hasPrefix("#:"),
                  !trimmed.hasPrefix("#*"),
                  !trimmed.hasPrefix("##")
            else { continue }

            // Detect inflected form redirect
            let inflectionPattern = #"\{\{inflection of\|ru\|([^|}\s]+)"#
            if let regex = try? NSRegularExpression(pattern: inflectionPattern),
               let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
               let lemmaRange = Range(match.range(at: 1), in: trimmed) {
                return ["[[ru-redirect:\(String(trimmed[lemmaRange]))]]"]
            }

            // Strip {{п.|ru}} labels like {{п.|ru}}, {{безл.|ru}}
            let definition = String(trimmed.dropFirst(2))
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "\\{\\{[^}]+\\}\\} ?", with: "", options: .regularExpression)

            var cleaned = cleanWiktionaryMarkup(definition)
            
            while let closeRange = cleaned.range(of: "}}") {
                // Search backwards from the position of "}}" to find "[["
                let searchArea = cleaned[cleaned.startIndex..<closeRange.lowerBound]
                
                guard let openRange = searchArea.range(of: "[[", options: .backwards) else {
                    break // No matching "[[" found, stop processing
                }
                
                // Remove everything from "[[" to "}}" (inclusive)
                cleaned.removeSubrange(openRange.lowerBound..<closeRange.upperBound)
            }
            
            
            if !cleaned.isEmpty && cleaned.count > 1 {
                definitions.append(cleaned)
            }

        }

        return definitions
    }

    
    private func extractDefinitionsKorean(from lines: [String]) -> [String] {
        var definitions: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            guard trimmed.hasPrefix("# "),
                  !trimmed.hasPrefix("#:"),
                  !trimmed.hasPrefix("#*"),
                  !trimmed.hasPrefix("##")
            else { continue }

            let definition = String(trimmed.dropFirst(2))
                .trimmingCharacters(in: .whitespaces)

            let referencePattern = #"'\[\[([^\]]+)\]\]'\s*의\s*(준말|활용형|변형|본말)"#
            if let regex = try? NSRegularExpression(pattern: referencePattern),
               let match = regex.firstMatch(in: definition, range: NSRange(definition.startIndex..., in: definition)),
               let wordRange = Range(match.range(at: 1), in: definition) {
                let baseWord = String(definition[wordRange])
                return ["[[ko-redirect:\(baseWord)]]"]
            }

            let cleaned = cleanWiktionaryMarkup(definition)
            if !cleaned.isEmpty {
                definitions.append(cleaned)
            }
        }

        return definitions
    }
    

    private func extractDefinitionsJapanese(from lines: [String]) -> [String] {
        var definitions: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            guard trimmed.hasPrefix("# "),
                  !trimmed.hasPrefix("#:"),
                  !trimmed.hasPrefix("#*"),
                  !trimmed.hasPrefix("##")
            else { continue }

            let cleaned = cleanWiktionaryMarkup(
                trimmed.dropFirst(2).trimmingCharacters(in: .whitespaces)
            )

            if !cleaned.isEmpty {
                definitions.append(cleaned)
            }
        }

        return definitions
    }
    private func extractDefinitionsSpanish(from lines: [String]) -> [String] {
        var definitions: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            guard trimmed.hasPrefix(";") else { continue }

            guard let colonIndex = trimmed.lastIndex(of: ":") else { continue }

            let afterColon = String(trimmed[trimmed.index(after: colonIndex)...])
                .trimmingCharacters(in: .whitespaces)

            guard !afterColon.isEmpty,
                  !afterColon.contains("forma verbo"),
                  !afterColon.contains("forma adjetivo"),
                  !afterColon.contains("forma sustantivo")
            else { continue }

            let cleaned = cleanWiktionaryMarkup(afterColon)

            if !cleaned.isEmpty && cleaned != "." {
                definitions.append(cleaned)
            }

        }

        return definitions
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
                
            }
        }
        
        return definitions
    }

    
    private func extractDefinitionsFrench(from lines: [String]) -> [String] {
        var definitions: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            guard trimmed.hasPrefix("#"),
                  !trimmed.hasPrefix("#:"),
                  !trimmed.hasPrefix("#*"),
                  !trimmed.hasPrefix("##")
            else { continue }

            let cleaned = cleanWiktionaryMarkup(
                trimmed.dropFirst(2).trimmingCharacters(in: .whitespaces)
            )

            if !cleaned.isEmpty {
                definitions.append(cleaned)
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

        result = result.replacingOccurrences(of: ":", with: "")
        
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
