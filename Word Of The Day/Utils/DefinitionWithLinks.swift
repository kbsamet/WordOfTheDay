//
//  DefinitionWithLinks.swift
//  Word Of The Day
//
//  Created by Koray Samet Kucukbayraktar on 18.03.2026.
//
//
//  DefinitionWithLinks.swift
//  Word Of The Day
//
//  Created by Koray Samet Kucukbayraktar on 18.03.2026.
//

enum DefinitionSegment {
    case text(String, hasTrailingSpace: Bool)
    case link(word: String, displayText: String, hasTrailingSpace: Bool)

    var hasTrailingSpace: Bool {
        switch self {
        case .text(_, let space):               return space
        case .link(_, _, let space):            return space
        }
    }

    var displayText: String {
        switch self {
        case .text(let t, _):                   return t
        case .link(_, let d, _):               return d
        }
    }
}

struct DefinitionWithLinks {
    let segments: [DefinitionSegment]

    init(from text: String) {
        self.segments = DefinitionWithLinks.parseDefinition(text)
    }

    var plainText: String {
        segments.map { segment in
            let space = segment.hasTrailingSpace ? " " : ""
            return segment.displayText + space
        }.joined()
    }

    private static func parseDefinition(_ text: String) -> [DefinitionSegment] {
        var segments: [DefinitionSegment] = []
        var currentPosition = text.startIndex

        while currentPosition < text.endIndex {
            if let linkStart = text[currentPosition...].range(of: "[[") {

                // ── Plain text before the link ────────────────────────────
                if currentPosition < linkStart.lowerBound {
                    let textBefore = String(text[currentPosition..<linkStart.lowerBound])
                    segments.append(contentsOf: plainSegments(from: textBefore))
                }

                // ── Parse the link ────────────────────────────────────────
                if let linkEnd = text[linkStart.upperBound...].range(of: "]]") {
                    let linkContent = String(text[linkStart.upperBound..<linkEnd.lowerBound])

                    let afterLink     = linkEnd.upperBound
                    let hasSpace      = afterLink < text.endIndex && text[afterLink] == " "
                    // Consume the space so it doesn't appear again in plain text
                    currentPosition   = hasSpace ? text.index(after: afterLink) : afterLink

                    if let pipeIndex = linkContent.firstIndex(of: "|") {
                        let word        = String(linkContent[..<pipeIndex])
                        let displayText = String(linkContent[linkContent.index(after: pipeIndex)...])
                        segments.append(.link(word: word, displayText: displayText, hasTrailingSpace: hasSpace))
                    } else {
                        segments.append(.link(word: linkContent, displayText: linkContent, hasTrailingSpace: hasSpace))
                    }

                } else {
                    // Malformed — treat as plain text
                    let raw = String(text[currentPosition..<linkStart.upperBound])
                    segments.append(contentsOf: plainSegments(from: raw))
                    currentPosition = linkStart.upperBound
                }

            } else {
                // No more links — consume remaining text
                let remaining = String(text[currentPosition...])
                if !remaining.isEmpty {
                    segments.append(contentsOf: plainSegments(from: remaining))
                }
                break
            }
        }

        if segments.isEmpty && !text.isEmpty {
            segments.append(.text(text, hasTrailingSpace: false))
        }

        return segments
    }

    // Splits a plain text run into per-word segments with correct trailing space
    private static func plainSegments(from text: String) -> [DefinitionSegment] {
        let words = text.components(separatedBy: " ")
        var result: [DefinitionSegment] = []

        for (i, word) in words.enumerated() {
            guard !word.isEmpty else { continue }
            let isLast      = i == words.count - 1
            let hasSpace    = !isLast || text.hasSuffix(" ")
            result.append(.text(word, hasTrailingSpace: hasSpace))
        }

        return result
    }
}
