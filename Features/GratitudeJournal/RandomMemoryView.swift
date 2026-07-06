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
                MoriBitmapIconImage(icon: .refresh, size: 28, opacity: 0.88)
                    .rotationEffect(.degrees(isPressed ? 360 : 0))
                    .animation(.easeInOut(duration: 0.6), value: isPressed)
                
                Text("Random Memory")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.botanicalInk)
                
                Text("Rediscover a past moment")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(MoriColors.botanicalSurface.opacity(0.96))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .foregroundColor(MoriColors.botanicalMoss.opacity(0.45))
            )
            .shadow(color: MoriColors.botanicalShadow.opacity(0.28), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibility(label: Text("Show a random past log entry"))
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
                .fill(MoriColors.botanicalMuted.opacity(0.34))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            if let entry = entry {
                // Date
                Text(formatDate(entry.date))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalMoss)
                    .padding(.top, 24)
                
                HStack(spacing: 6) {
                    MoriBitmapIconImage(icon: entry.sourceIcon, size: 15, opacity: 0.82)

                    Text(entry.sourceLabel)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(sourceColor(for: entry))
                .padding(.top, 4)
                
                // Content
                ScrollView {
                    Text(entry.displayContent)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(MoriColors.botanicalInk)
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
                        .foregroundColor(MoriColors.botanicalInk)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 32)
                        .background(MoriColors.botanicalInk.opacity(0.08))
                        .cornerRadius(8)
                }
                .padding(.top, 24)
                .padding(.bottom, 32)
            } else {
                // Empty state
                VStack(spacing: 16) {
                    MoriBitmapIconBadge(
                        icon: .journal,
                        size: 58,
                        iconScale: 0.58,
                        fill: MoriColors.sanctuarySurface.opacity(0.76),
                        stroke: Color.white.opacity(0.88),
                        shadow: MoriColors.sanctuaryShadow.opacity(0.16)
                    )
                    
                    Text("No memories yet")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.botanicalInk)
                    
                    Text("Start writing to build your collection!")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted)
                }
                .frame(height: 300)
                
                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalInk)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 32)
                        .background(MoriColors.botanicalInk.opacity(0.08))
                        .cornerRadius(8)
                }
                .padding(.bottom, 32)
            }
        }
        .background(MoriColors.botanicalSurface)
        .cornerRadius(20, corners: [.topLeft, .topRight])
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func sourceColor(for entry: GratitudeEntry) -> Color {
        switch entry.sourceKind {
        case .journal: return MoriColors.botanicalMuted
        case .dayLog: return MoriColors.botanicalClay
        case .dailySpark: return MoriColors.botanicalSeed
        case .weeklyIntention: return MoriColors.botanicalMoss
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
    .background(MoriColors.botanicalPaper)
}
