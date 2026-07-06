//
//  PromptChipView.swift
//  Mori
//
//  Writing prompt chips for gratitude journal
//

import SwiftUI

// MARK: - Prompt Chip View
struct PromptChipView: View {
    let prompt: GratitudePrompt
    let isSelected: Bool
    var onTap: (() -> Void)?
    
    var body: some View {
        Button(action: { onTap?() }) {
            Text(prompt.shortName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? MoriColors.botanicalSurface : MoriColors.botanicalInk)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected 
                        ? MoriColors.botanicalInk
                        : MoriColors.botanicalInk.opacity(0.08)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected 
                                ? MoriColors.botanicalInk
                                : MoriColors.botanicalLine.opacity(0.48),
                            lineWidth: 1
                        )
                )
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibility(label: Text(MoriL10n.string("journal.prompt.accessibility", defaultValue: "Prompt: %@", arguments: [prompt.displayText])))
    }
}

// MARK: - Prompt Selection Section
struct PromptSelectionSection: View {
    @Binding var selectedPrompt: GratitudePrompt?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                MoriBitmapIconImage(icon: .leaf, size: 17, opacity: 0.82)
                
                Text("Choose a prompt")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.botanicalInk)
            }
            
            // Chips
            FlowLayout(spacing: 8) {
                ForEach(GratitudePrompt.allCases, id: \.self) { prompt in
                    PromptChipView(
                        prompt: prompt,
                        isSelected: selectedPrompt == prompt
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPrompt = prompt
                        }
                    }
                }
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

// MARK: - Flow Layout for Chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        PromptSelectionSection(selectedPrompt: .constant(.today))
        
        HStack {
            PromptChipView(prompt: .today, isSelected: true)
            PromptChipView(prompt: .smallJoy, isSelected: false)
            PromptChipView(prompt: .moment, isSelected: false)
        }
    }
    .padding()
    .background(MoriColors.botanicalPaper)
}
