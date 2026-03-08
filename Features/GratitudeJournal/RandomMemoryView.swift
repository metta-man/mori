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
                    .font(.custom("Poppins", size: 16))
                    .foregroundColor(Color(hex: "D4AF37"))
                
                Text("Rediscover a past moment")
                    .font(.custom("Poppins", size: 12))
                    .foregroundColor(Color(hex: "888888"))
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Color(hex: "FDF5E6"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .foregroundColor(Color(hex: "D4AF37"))
            )
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
                .fill(Color.gray.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            if let entry = entry {
                // Date
                Text(formatDate(entry.date))
                    .font(.custom("Poppins", size: 14))
                    .foregroundColor(Color(hex: "788c5d"))
                    .padding(.top, 24)
                
                // Prompt (if any)
                if let prompt = entry.promptType {
                    HStack {
                        Text("💡")
                        Text(prompt.displayText)
                    }
                    .font(.custom("Poppins", size: 14))
                    .foregroundColor(Color(hex: "666666"))
                    .padding(.top, 4)
                }
                
                // Content
                ScrollView {
                    Text(entry.content)
                        .font(.custom("Poppins", size: 15))
                        .foregroundColor(Color(hex: "333333"))
                        .lineSpacing(1.6)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                }
                .frame(maxHeight: 300)
                
                // Close button
                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.custom("Poppins", size: 14))
                        .foregroundColor(Color(hex: "788c5d"))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 32)
                        .background(Color(hex: "F5F5F5"))
                        .cornerRadius(8)
                }
                .padding(.top, 24)
                .padding(.bottom, 32)
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(Color(hex: "CCCCCC"))
                    
                    Text("No memories yet")
                        .font(.custom("Poppins", size: 16))
                        .foregroundColor(Color(hex: "666666"))
                    
                    Text("Start writing to build your collection!")
                        .font(.custom("Poppins", size: 14))
                        .foregroundColor(Color(hex: "888888"))
                }
                .frame(height: 300)
                
                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.custom("Poppins", size: 14))
                        .foregroundColor(Color(hex: "788c5d"))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 32)
                        .background(Color(hex: "F5F5F5"))
                        .cornerRadius(8)
                }
                .padding(.bottom, 32)
            }
        }
        .background(Color.white)
        .cornerRadius(20, corners: [.topLeft, .topRight])
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
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
    .background(Color(hex: "FDF5E6"))
}
