//
//  RandomMemoryView.swift
//  Mori
//
//  Random recall modal for past gratitude entries
//

import SwiftUI

// MARK: - Random Memory Button
struct RandomMemoryButton: View {
    var onTap: (() -> Void)?
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isPressed = false
                onTap?()
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: "dice.fill")
                    .font(.system(size: 28))
                    .rotationEffect(.degrees(isPressed ? 360 : 0))
                    .animation(.easeInOut(duration: 0.6), value: isPressed)
                
                Text("Random Memory")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.forestCanopy)
                
                Text("Rediscover a past moment")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.forestMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(MoriColors.forestCard.opacity(0.96))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .foregroundColor(MoriColors.forestMoss.opacity(0.45))
            )
            .shadow(color: MoriColors.forestShadow.opacity(0.28), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibility(label: Text("Show a random past gratitude entry"))
    }
}

// MARK: - Random Memory Modal
struct RandomMemoryModal: View {
    let entry: GratitudeEntry?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(MoriColors.forestMuted.opacity(0.34))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            if let entry = entry {
                // Date
                Text(formatDate(entry.date))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.forestMoss)
                    .padding(.top, 24)
                
                Label(entry.sourceLabel, systemImage: entry.sourceSymbolName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(sourceColor(for: entry))
                    .padding(.top, 4)
                
                // Content
                ScrollView {
                    Text(entry.displayContent)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(MoriColors.forestCanopy)
                        .lineSpacing(1.6)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                }
                .frame(maxHeight: 300)
                
                // Close button
                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MoriColors.forestCanopy)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 32)
                        .background(MoriColors.forestCanopy.opacity(0.08))
                        .cornerRadius(8)
                }
                .padding(.top, 24)
                .padding(.bottom, 32)
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(MoriColors.forestMuted.opacity(0.62))
                    
                    Text("No memories yet")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestCanopy)
                    
                    Text("Start writing to build your collection!")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(MoriColors.forestMuted)
                }
                .frame(height: 300)
                
                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MoriColors.forestCanopy)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 32)
                        .background(MoriColors.forestCanopy.opacity(0.08))
                        .cornerRadius(8)
                }
                .padding(.bottom, 32)
            }
        }
        .background(MoriColors.forestCard)
        .cornerRadius(20, corners: [.topLeft, .topRight])
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func sourceColor(for entry: GratitudeEntry) -> Color {
        switch entry.sourceKind {
        case .journal: return MoriColors.forestMuted
        case .dayLog: return MoriColors.forestClay
        case .dailySpark: return MoriColors.forestSeed
        case .weeklyIntention: return MoriColors.forestMoss
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
#Preview {
    VStack {
        RandomMemoryButton(onTap: {})
    }
    .padding()
    .background(MoriColors.forestPaper)
}
