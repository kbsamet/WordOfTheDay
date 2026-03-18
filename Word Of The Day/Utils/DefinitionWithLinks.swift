//
//  DefinitionWithLinks.swift
//  Word Of The Day
//
//  Created by Koray Samet Kucukbayraktar on 18.03.2026.
//

struct DefinitionWithLinks {
    let segments: [DefinitionSegment]
    
    /// Create from raw definition text containing [[word]] markup
    init(from text: String) {
        self.segments = DefinitionWithLinks.parseDefinition(text)
    }
    
    /// Extract plain text from all segments
    var plainText: String {
        segments.map { segment in
            switch segment {
            case .text(let text):
                return text
            case .link(_, let displayText):
                return displayText
            }
        }.joined()
    }
    
    private static func parseDefinition(_ text: String) -> [DefinitionSegment] {
        var segments: [DefinitionSegment] = []
        var currentPosition = text.startIndex
        
        while currentPosition < text.endIndex {
            // Look for [[...]] pattern
            if let linkStart = text[currentPosition...].range(of: "[[") {
                // Add text before the link
                if currentPosition < linkStart.lowerBound {
                    let textBefore = String(text[currentPosition..<linkStart.lowerBound])
                    segments.append(.text(textBefore))
                }
                
                // Find the end of the link
                if let linkEnd = text[linkStart.upperBound...].range(of: "]]") {
                    let linkContent = String(text[linkStart.upperBound..<linkEnd.lowerBound])
                    
                    // Parse [[word|displayText]] or [[word]]
                    if let pipeIndex = linkContent.firstIndex(of: "|") {
                        let word = String(linkContent[..<pipeIndex])
                        let displayText = String(linkContent[linkContent.index(after: pipeIndex)...])
                        segments.append(.link(word: word, displayText: displayText))
                    } else {
                        segments.append(.link(word: linkContent, displayText: linkContent))
                    }
                    
                    currentPosition = linkEnd.upperBound
                } else {
                    // Malformed link, treat as text
                    let textBefore = String(text[currentPosition..<linkStart.upperBound])
                    segments.append(.text(textBefore))
                    currentPosition = linkStart.upperBound
                }
            } else {
                // No more links, add remaining text
                let remaining = String(text[currentPosition...])
                if !remaining.isEmpty {
                    segments.append(.text(remaining))
                }
                break
            }
        }
        
        // If no segments were created, return the original text
        if segments.isEmpty && !text.isEmpty {
            segments.append(.text(text))
        }
        
        return segments
    }
}
