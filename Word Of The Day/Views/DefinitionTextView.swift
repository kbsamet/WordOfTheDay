//
//  DefinitionTextView.swift
//  Word Of The Day
//
//  Created by OpenCode on 2026-03-18.
//

import SwiftUI

struct DefinitionSegmentView: View {
    let line: String
    let onLinkTap: (String) -> Void
    let prefetchedWords: [String:String?]
    
    private var definition: DefinitionWithLinks {
        DefinitionWithLinks(from: line)
    }
    
    private func isValidLink(_ word: String) -> Bool {
        guard let entry = prefetchedWords[word] else { return true } // optimistic while absent
        return entry != nil && entry?.trimmingCharacters(in: .whitespacesAndNewlines) != ""
    }
    
    
    var body: some View {
        FlowLayout(spacing: 0) {
            ForEach(Array(definition.segments.enumerated()), id: \.offset) { _, segment in
                let display = segment.displayText + (segment.hasTrailingSpace ? " " : "")
                
                switch segment {
                case .link(let word, _, _) where isValidLink(word):
                    Text(display)
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundStyle(AppColor.color("skyBlue"))
                        .onTapGesture { onLinkTap(word) }
                default:
                    Text(display)
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    struct FlowLayout: Layout {
        var spacing: CGFloat = 4
        
        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let result = arrange(proposal: proposal, subviews: subviews)
            return result.size
        }
        
        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            let result = arrange(proposal: proposal, subviews: subviews)
            for (index, frame) in result.frames.enumerated() {
                subviews[index].place(
                    at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                    proposal: ProposedViewSize(frame.size)
                )
            }
        }
        
        private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
            var frames: [CGRect] = []
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            let maxWidth = proposal.width ?? .infinity
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            
            let totalHeight = currentY + lineHeight
            let totalWidth = proposal.width ?? currentX
            return (CGSize(width: totalWidth, height: totalHeight), frames)
        }
    }
    
    
}
