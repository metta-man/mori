import SwiftUI

struct BotanicalPanel<Content: View>: View {
    let fill: Color
    let radius: CGFloat
    let padding: CGFloat
    let content: Content

    init(
        fill: Color = MoriColors.sanctuarySurface.opacity(0.82),
        radius: CGFloat = 22,
        padding: CGFloat = 18,
        @ViewBuilder content: () -> Content
    ) {
        self.fill = fill
        self.radius = radius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                MoriPlainWatercolorCardBackground(
                    cornerRadius: radius,
                    fill: fill,
                    paperOpacity: 0.07,
                    edgeOpacity: 0.04
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(0.78), lineWidth: 1)
            )
            .shadow(color: MoriColors.sanctuaryShadow.opacity(0.22), radius: 10, x: 0, y: 5)
    }
}

struct OrganicCard<Content: View>: View {
    let fill: Color
    let radius: CGFloat
    let padding: CGFloat
    let content: Content

    init(
        fill: Color = MoriColors.sanctuarySurface.opacity(0.82),
        radius: CGFloat = 22,
        padding: CGFloat = 18,
        @ViewBuilder content: () -> Content
    ) {
        self.fill = fill
        self.radius = radius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        BotanicalPanel(
            fill: fill,
            radius: radius,
            padding: padding
        ) {
            content
        }
    }
}

struct MetricHeroCard<Visual: View, TextBlock: View>: View {
    enum VisualSide {
        case leading
        case trailing
    }

    let fill: Color
    let visualSide: VisualSide
    let spacing: CGFloat
    let visual: Visual
    let textBlock: TextBlock

    init(
        fill: Color = MoriColors.sanctuarySurface.opacity(0.82),
        visualSide: VisualSide = .leading,
        spacing: CGFloat = 18,
        @ViewBuilder visual: () -> Visual,
        @ViewBuilder textBlock: () -> TextBlock
    ) {
        self.fill = fill
        self.visualSide = visualSide
        self.spacing = spacing
        self.visual = visual()
        self.textBlock = textBlock()
    }

    var body: some View {
        OrganicCard(fill: fill, radius: 24, padding: 18) {
            HStack(alignment: .center, spacing: spacing) {
                if visualSide == .leading {
                    visual
                    textBlock.frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    textBlock.frame(maxWidth: .infinity, alignment: .leading)
                    visual
                }
            }
        }
    }
}

extension View {
    func moriSanctuaryCard(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 16
    ) -> some View {
        moriSanctuaryBox(
            cornerRadius: cornerRadius,
            padding: padding,
            tone: .paper,
            castsShadow: true
        )
    }

    func moriSanctuaryBox(
        cornerRadius: CGFloat = 22,
        padding: CGFloat = 18,
        tone: MoriSanctuaryBoxTone = .paper,
        castsShadow: Bool = true
    ) -> some View {
        modifier(MoriSanctuaryBoxModifier(
            cornerRadius: cornerRadius,
            padding: padding,
            tone: tone,
            castsShadow: castsShadow
        ))
    }
}

private struct MoriSanctuaryBoxModifier: ViewModifier {
    let cornerRadius: CGFloat
    let padding: CGFloat
    let tone: MoriSanctuaryBoxTone
    let castsShadow: Bool

    func body(content: Content) -> some View {
        let compactPadding = min(padding, 16)

        content
            .padding(compactPadding)
            .background(MoriSanctuaryBoxBackground(
                cornerRadius: cornerRadius,
                tone: tone
            ))
            .shadow(
                color: castsShadow ? MoriColors.sanctuaryShadow.opacity(0.24) : .clear,
                radius: castsShadow ? 10 : 0,
                x: 0,
                y: castsShadow ? 5 : 0
            )
    }
}
