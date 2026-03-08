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
                .font(.custom("Poppins", size: 13))
                .foregroundColor(isSelected ? .white : Color(hex: "666666"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected 
                        ? Color(hex: "788c5d") 
                        : Color(hex: "F5F5F5")
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected 
                                ? Color(hex: "788c5d") 
                                : Color(hex: "E0E0E0"),
                            lineWidth: 1
                        )
                )
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibility(label: Text("Prompt: \(prompt.displayText)"))
    }
}

// MARK: - Prompt Selection Section
struct PromptSelectionSection: View {
    @Binding var selectedPrompt: GratitudePrompt?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("💡")
                    .font(.system(size: 18))
                
                Text("Choose a prompt")
                    .font(.custom("Poppins", size: 14))
                    .foregroundColor(Color(hex: "666666"))
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
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "E8E8E8"), lineWidth: 1)
        )
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
    .background(Color(hex: "FDF5E6"))
}
