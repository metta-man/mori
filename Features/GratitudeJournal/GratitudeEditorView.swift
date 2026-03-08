//
//  GratitudeEditorView.swift
//  Mori
//
//  Text input editor for gratitude entries with validation
//

import SwiftUI

// MARK: - Gratitude Editor View
struct GratitudeEditorView: View {
    @Binding var content: String
    let selectedPrompt: GratitudePrompt?
    var onSave: () -> Void
    
    @State private var charCountStatus: CharacterCountStatus = .normal
    
    private var isValid: Bool {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 10 && trimmed.count <= 500
    }
    
    private var placeholder: String {
        selectedPrompt?.displayText ?? "What are you grateful for today?"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Text Editor
            ZStack(alignment: .topLeading) {
                if content.isEmpty {
                    Text(placeholder)
                        .font(.custom("Poppins", size: 15))
                        .foregroundColor(Color(hex: "AAAAAA"))
                        .italic()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                }
                
                TextEditor(text: $content)
                    .font(.custom("Poppins", size: 15))
                    .foregroundColor(Color(hex: "333333"))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .onChange(of: content) { newValue in
                        charCountStatus = CharacterCountStatus.status(for: newValue.count)
                    }
            }
            .frame(minHeight: 120)
            
            Divider()
                .background(Color(hex: "E8E8E8"))
            
            // Footer
            HStack {
                // Character count
                Text("\(content.count)/500")
                    .font(.custom("Poppins", size: 12))
                    .foregroundColor(Color(hex: charCountStatus.color))
                
                Spacer()
                
                // Save button
                Button(action: onSave) {
                    Text("Save")
                        .font(.custom("Poppins", size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(isValid ? Color(hex: "788c5d") : Color.gray)
                        .cornerRadius(8)
                }
                .disabled(!isValid)
                .accessibility(label: Text("Save gratitude entry"))
            }
            .padding(20)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "E8E8E8"), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        GratitudeEditorView(
            content: .constant(""),
            selectedPrompt: .today,
            onSave: {}
        )
        
        GratitudeEditorView(
            content: .constant("Today I'm grateful for the warm sunshine that greeted me this morning."),
            selectedPrompt: .today,
            onSave: {}
        )
    }
    .padding()
    .background(Color(hex: "FDF5E6"))
}
