import SwiftUI

struct MoriBotanicalScreenBackdrop: View {
    enum Variant: Equatable {
        case appLimit
        case today
        case practice
        case journal
        case settings
        case onboarding
        case homeHero
        case waves
        case deepWaves
        case rings
        case focus
        case bell
        case bellTile
        case roots
        case rootsTile
        case breath
        case coolTile
        case warmTile
        case none

        var assetName: String? {
            switch self {
            case .appLimit:
                return "BotanicalBackdropAppLimit"
            case .today:
                return "BotanicalBackdropToday"
            case .practice:
                return "BotanicalBackdropPractice"
            case .journal:
                return "BotanicalBackdropJournal"
            case .settings:
                return "BotanicalBackdropSettings"
            case .onboarding:
                return "BotanicalBackdropOnboarding"
            case .homeHero:
                return "BotanicalBackdropHomeHero"
            case .waves, .deepWaves:
                return "BotanicalBackdropToday"
            case .focus:
                return "BotanicalBackdropFocus"
            case .rings, .warmTile:
                return "BotanicalBackdropWarmTile"
            case .bell:
                return "BotanicalBackdropBell"
            case .bellTile:
                return "BotanicalBackdropBellTile"
            case .roots:
                return "BotanicalBackdropRoots"
            case .rootsTile:
                return "BotanicalBackdropRootsTile"
            case .breath, .coolTile:
                return "BotanicalBackdropBreathe"
            case .none:
                return nil
            }
        }
    }

    let variant: Variant

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                if let assetName = variant.assetName {
                    Image(assetName)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        .clipped()
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct MoriWatercolorHeroWash: View {
    enum Placement {
        case corner
        case bottomBand
    }

    let variant: MoriBotanicalScreenBackdrop.Variant
    var placement: Placement = .corner

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack(alignment: alignment) {
                Color.clear

                accentArt(size: size)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var alignment: Alignment {
        switch placement {
        case .corner:
            return .topTrailing
        case .bottomBand:
            return .bottomTrailing
        }
    }

    @ViewBuilder
    private func accentArt(size: CGSize) -> some View {
        switch variant {
        case .none:
            EmptyView()
        default:
            ZStack(alignment: alignment) {
                MoriGeneratedArtImage(art: .paperWash, contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .opacity(placement == .corner ? 0.22 : 0.18)
                    .blendMode(.multiply)

                LinearGradient(
                    colors: accentColors,
                    startPoint: placement == .corner ? .topTrailing : .bottomTrailing,
                    endPoint: placement == .corner ? .bottomLeading : .topLeading
                )
                .frame(width: size.width, height: size.height)
                .opacity(placement == .corner ? 0.10 : 0.08)
                .blendMode(.multiply)
            }
        }
    }

    private var accentColors: [Color] {
        let tint: Color
        switch variant {
        case .appLimit, .bell, .bellTile:
            tint = MoriColors.sanctuarySage
        case .practice, .breath, .coolTile:
            tint = MoriColors.sanctuaryMistDeep
        case .journal, .roots, .rootsTile:
            tint = MoriColors.sanctuaryRoot
        case .today, .focus, .settings, .homeHero, .onboarding, .waves, .deepWaves, .rings, .warmTile:
            tint = MoriColors.sanctuaryFern
        case .none:
            tint = .clear
        }

        return [
            tint.opacity(0.16),
            MoriColors.sanctuarySand.opacity(0.10),
            .clear
        ]
    }
}
