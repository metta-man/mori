import SwiftUI

struct MoriPaperBackground<Content: View>: View {
    private let variant: MoriBotanicalScreenBackdrop.Variant
    private let content: Content

    init(
        variant: MoriBotanicalScreenBackdrop.Variant = .settings,
        @ViewBuilder content: () -> Content
    ) {
        self.variant = variant
        self.content = content()
    }

    var body: some View {
        ZStack {
            MoriWatercolorPaperBackground(variant: variant)
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct MoriWatercolorPaperBackground: View {
    let variant: MoriBotanicalScreenBackdrop.Variant

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                MoriColors.sanctuaryPaper

                MoriGeneratedArtImage(art: .paperWash, contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .opacity(0.74)
                    .blendMode(.multiply)

                softCanopyLayer(size: size, mirrored: true, opacity: 0.28)
                softCanopyLayer(size: size, mirrored: false, opacity: 0.13)

                edgeWashes(size: size)

                if variant != .none {
                    MoriGeneratedArtImage(art: .botanicalScreenWash, contentMode: .fill)
                        .frame(width: size.width, height: size.height)
                        .clipped()
                        .opacity(screenWashOpacity)
                        .blendMode(.multiply)
                        .saturation(0.92)
                        .contrast(1.02)
                }

                botanicalPainting
                    .frame(width: size.width, height: size.height)
                    .clipped()

                variantTintWash
                    .frame(width: size.width, height: size.height)

                Color.white
                    .opacity(0.055)
            }
            .frame(width: size.width, height: size.height)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func softCanopyLayer(size: CGSize, mirrored: Bool, opacity: Double) -> some View {
        Image("BotanicalBackdropSoftCanopy")
            .resizable()
            .renderingMode(.original)
            .interpolation(.high)
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .clipped()
            .scaleEffect(x: mirrored ? -1 : 1, y: 1, anchor: .center)
            .opacity(opacity)
            .saturation(0.82)
            .contrast(0.96)
            .blendMode(.multiply)
    }

    private func edgeWashes(size: CGSize) -> some View {
        ZStack {
            RadialGradient(
                colors: [
                    MoriColors.sanctuaryPaperWarm.opacity(0.34),
                    MoriColors.sanctuaryPaper.opacity(0.12),
                    .clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: max(size.width, size.height) * 0.58
            )

            RadialGradient(
                colors: [
                    MoriColors.sanctuarySand.opacity(0.20),
                    MoriColors.sanctuaryPaperWarm.opacity(0.12),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: max(size.width, size.height) * 0.56
            )

            LinearGradient(
                colors: [
                    .clear,
                    MoriColors.sanctuaryFern.opacity(0.055),
                    MoriColors.sanctuarySand.opacity(0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(width: size.width, height: size.height)
        .blendMode(.multiply)
    }

    @ViewBuilder
    private var botanicalPainting: some View {
        if variant != .none {
            MoriBotanicalScreenBackdrop(variant: variant)
                .opacity(botanicalOpacity)
                .saturation(0.78)
                .contrast(0.98)
                .blendMode(.multiply)
        }
    }

    @ViewBuilder
    private var variantTintWash: some View {
        if variant != .none {
            LinearGradient(
                colors: [
                    backdropTint.opacity(backdropOpacity),
                    MoriColors.sanctuaryPaper.opacity(0.03),
                    MoriColors.sanctuarySand.opacity(backdropOpacity * 0.58)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .blendMode(.multiply)
        }
    }

    private var screenWashOpacity: Double {
        switch variant {
        case .none:
            return 0
        case .onboarding:
            return 0.12
        case .appLimit, .homeHero:
            return 0.11
        case .bell, .roots, .breath, .focus:
            return 0.10
        case .bellTile, .rootsTile, .coolTile, .warmTile:
            return 0.08
        default:
            return 0.09
        }
    }

    private var botanicalOpacity: Double {
        switch variant {
        case .none:
            return 0
        case .onboarding:
            return 0.20
        case .appLimit, .homeHero:
            return 0.18
        case .bell, .roots, .breath, .focus:
            return 0.16
        case .bellTile, .rootsTile, .coolTile, .warmTile:
            return 0.12
        default:
            return 0.14
        }
    }

    private var backdropOpacity: Double {
        switch variant {
        case .none:
            return 0
        case .onboarding:
            return 0.14
        case .appLimit, .homeHero:
            return 0.13
        case .bell, .roots, .breath, .focus:
            return 0.12
        case .bellTile, .rootsTile, .coolTile, .warmTile:
            return 0.09
        default:
            return 0.10
        }
    }

    private var backdropTint: Color {
        switch variant {
        case .appLimit, .bell, .bellTile:
            return MoriColors.sanctuarySage
        case .practice, .breath, .coolTile:
            return MoriColors.sanctuaryMistDeep
        case .journal, .roots, .rootsTile:
            return MoriColors.sanctuaryRoot
        case .today, .focus, .settings, .homeHero, .onboarding, .waves, .deepWaves, .rings, .warmTile:
            return MoriColors.sanctuaryFern
        case .none:
            return .clear
        }
    }
}
