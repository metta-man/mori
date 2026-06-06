import SwiftUI

struct MoriForestBackground<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            MoriColors.forestPaper
                .ignoresSafeArea()

            MoriHillShape()
                .fill(MoriColors.forestSage.opacity(0.18))
                .frame(height: 220)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea()

            MoriRootPattern()
                .stroke(MoriColors.forestRoot.opacity(0.08), lineWidth: 1)
                .ignoresSafeArea()

            MoriSeedScatter()
                .fill(MoriColors.forestMoss.opacity(0.10))
                .ignoresSafeArea()

            content
        }
    }
}

struct MoriPageHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.4)
                .foregroundColor(MoriColors.forestMoss)

            Text(title)
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.forestCanopy)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(MoriColors.forestMuted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MoriSectionTitle: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.forestCanopy)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(MoriColors.forestMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MoriMetricTile: View {
    let title: String
    let value: String
    let detail: String
    var symbolName: String = "leaf.fill"
    var tint: Color = MoriColors.forestMoss

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbolName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.forestCanopy)
                    .minimumScaleFactor(0.75)

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MoriColors.forestMuted)

                Text(detail)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(MoriColors.forestMuted.opacity(0.82))
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .moriSanctuaryCard(cornerRadius: 18, padding: 15)
    }
}

struct MoriPill: View {
    let title: String
    var symbolName: String?
    var isSelected: Bool = false
    var tint: Color = MoriColors.forestMoss

    var body: some View {
        HStack(spacing: 6) {
            if let symbolName {
                Image(systemName: symbolName)
                    .font(.system(size: 12, weight: .semibold))
            }

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundColor(isSelected ? MoriColors.forestCard : tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? tint : tint.opacity(0.10))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(tint.opacity(isSelected ? 0 : 0.16), lineWidth: 1)
        )
    }
}

struct MoriForestProgressBar: View {
    let value: Double
    var tint: Color = MoriColors.forestMoss

    var body: some View {
        GeometryReader { proxy in
            let clamped = max(0, min(1, value))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(MoriColors.forestLine.opacity(0.55))

                Capsule()
                    .fill(tint)
                    .frame(width: max(8, proxy.size.width * clamped))
            }
        }
        .frame(height: 9)
    }
}

extension View {
    func moriSanctuaryCard(cornerRadius: CGFloat = 20, padding: CGFloat = 18) -> some View {
        modifier(MoriSanctuaryCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

private struct MoriSanctuaryCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(MoriColors.forestCard.opacity(0.96))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(MoriColors.forestHairline, lineWidth: 1)
            )
            .shadow(color: MoriColors.forestShadow.opacity(0.50), radius: 18, x: 0, y: 10)
    }
}

private struct MoriHillShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY + 42))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY + 16),
            control1: CGPoint(x: rect.width * 0.26, y: rect.midY - 22),
            control2: CGPoint(x: rect.width * 0.62, y: rect.midY + 90)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct MoriRootPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let startY = rect.maxY - 170

        for index in 0..<5 {
            let x = rect.minX + CGFloat(index) * rect.width / 4
            path.move(to: CGPoint(x: x, y: startY + CGFloat(index % 2) * 22))
            path.addCurve(
                to: CGPoint(x: x + rect.width * 0.22, y: rect.maxY + 20),
                control1: CGPoint(x: x + 28, y: startY + 38),
                control2: CGPoint(x: x - 18, y: rect.maxY - 70)
            )
        }

        return path
    }
}

private struct MoriSeedScatter: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let seeds: [(CGFloat, CGFloat, CGFloat)] = [
            (0.12, 0.18, 7),
            (0.72, 0.14, 5),
            (0.88, 0.34, 8),
            (0.18, 0.72, 6),
            (0.61, 0.82, 7)
        ]

        for seed in seeds {
            let seedRect = CGRect(
                x: rect.width * seed.0,
                y: rect.height * seed.1,
                width: seed.2,
                height: seed.2 * 1.6
            )
            path.addEllipse(in: seedRect)
        }

        return path
    }
}
