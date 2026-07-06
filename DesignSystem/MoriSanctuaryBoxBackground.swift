import SwiftUI

enum MoriSanctuaryBoxTone {
    case paper
    case mist
    case sage
    case sand
    case blue
    case root

    var fill: Color {
        switch self {
        case .paper:
            return MoriColors.sanctuarySurface.opacity(0.90)
        case .mist:
            return MoriColors.sanctuaryMist.opacity(0.28)
        case .sage:
            return MoriColors.sanctuaryFern.opacity(0.24)
        case .sand:
            return MoriColors.sanctuarySand.opacity(0.30)
        case .blue:
            return MoriColors.sanctuaryMist.opacity(0.34)
        case .root:
            return MoriColors.sanctuaryRoot.opacity(0.15)
        }
    }

    var accent: Color {
        switch self {
        case .paper:
            return MoriColors.sanctuaryInk
        case .mist:
            return MoriColors.sanctuaryMistDeep
        case .sage:
            return MoriColors.sanctuarySage
        case .sand:
            return MoriColors.sanctuaryRoot
        case .blue:
            return MoriColors.sanctuaryMistDeep
        case .root:
            return MoriColors.sanctuaryRoot
        }
    }

    var iconFill: Color {
        switch self {
        case .paper:
            return MoriColors.sanctuarySurface.opacity(0.74)
        case .mist:
            return MoriColors.sanctuaryMist.opacity(0.18)
        case .sage:
            return MoriColors.sanctuaryFern.opacity(0.18)
        case .sand:
            return MoriColors.sanctuarySand.opacity(0.18)
        case .blue:
            return MoriColors.sanctuaryMist.opacity(0.20)
        case .root:
            return MoriColors.sanctuaryPaperWarm.opacity(0.72)
        }
    }

    var waveOpacity: Double {
        switch self {
        case .paper:
            return 0.42
        case .mist, .blue:
            return 0.52
        case .sage:
            return 0.48
        case .sand, .root:
            return 0.40
        }
    }

    var textureOpacity: Double {
        switch self {
        case .paper:
            return 0.22
        case .mist, .blue:
            return 0.20
        case .sage, .sand, .root:
            return 0.18
        }
    }

    var paperWash: MoriGeneratedArt {
        switch self {
        case .paper:
            return .cardPaperWash
        case .mist, .blue:
            return .cardCoolWash
        case .sage:
            return .cardSageWash
        case .sand, .root:
            return .cardWarmWash
        }
    }
}

struct MoriSanctuaryBoxBackground: View {
    var cornerRadius: CGFloat = 22
    var tone: MoriSanctuaryBoxTone = .paper

    var body: some View {
        MoriPlainWatercolorCardBackground(
            cornerRadius: cornerRadius,
            fill: tone.fill,
            paperWash: tone.paperWash,
            paperOpacity: tone.textureOpacity * 0.22,
            edgeOpacity: tone.textureOpacity * 0.10
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.78), lineWidth: 1)
        )
        .compositingGroup()
    }
}
