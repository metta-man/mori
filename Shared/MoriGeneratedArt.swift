import SwiftUI

enum MoriGeneratedArt: String, CaseIterable {
    case paperWash = "moriPaperWash"
    case cardPaperWash = "moriCardPaperWash"
    case cardSageWash = "moriCardSageWash"
    case cardWarmWash = "moriCardWarmWash"
    case cardCoolWash = "moriCardCoolWash"
    case botanicalScreenWash = "moriBotanicalScreenWash"
    case breathInkBloom = "moriBreathInkBloom"
    case breathLandscapeWash = "moriBreathLandscapeWash"
    case resetRingWash = "moriResetRingWash"
    case widgetPaperWash = "moriWidgetPaperWash"
    case widgetBotanicalWash = "moriWidgetBotanicalWash"
    case buttonWash = "moriButtonWash"
}

enum MoriBitmapIcon: String, CaseIterable, Codable {
    case home = "moriIconHome"
    case breathe = "moriIconBreathe"
    case focus = "moriIconFocus"
    case bell = "moriIconBell"
    case roots = "moriIconRoots"
    case pulse = "moriIconPulse"
    case journal = "moriIconJournal"
    case quiet = "moriIconQuiet"
    case settings = "moriIconSettings"
    case chevron = "moriIconChevron"
    case plus = "moriIconPlus"
    case minus = "moriIconMinus"
    case play = "moriIconPlay"
    case pause = "moriIconPause"
    case stop = "moriIconStop"
    case refresh = "moriIconRefresh"
    case sound = "moriIconSound"
    case haptics = "moriIconHaptics"
    case leaf = "moriIconLeaf"
    case lockShield = "moriIconLockShield"
    case timer = "moriIconTimer"
    case heart = "moriIconHeart"

    static func fromLegacySymbolName(_ symbolName: String) -> MoriBitmapIcon {
        let lowered = symbolName.lowercased()
        if lowered.contains("bell") { return .bell }
        if lowered.contains("wind") || lowered.contains("wave") { return .breathe }
        if lowered.contains("timer") || lowered.contains("clock") || lowered.contains("circle") { return .focus }
        if lowered.contains("grid") || lowered.contains("rings") || lowered.contains("root") { return .roots }
        if lowered.contains("spark") || lowered.contains("pulse") { return .pulse }
        if lowered.contains("book") || lowered.contains("pencil") { return .journal }
        if lowered.contains("moon") { return .quiet }
        if lowered.contains("app") || lowered.contains("iphone") { return .lockShield }
        if lowered.contains("gear") || lowered.contains("slider") { return .settings }
        if lowered.contains("chevron") { return .chevron }
        if lowered.contains("plus") { return .plus }
        if lowered.contains("checkmark") || lowered.contains("seal") { return .leaf }
        if lowered.contains("minus") { return .minus }
        if lowered.contains("play") { return .play }
        if lowered.contains("pause") { return .pause }
        if lowered.contains("stop") { return .stop }
        if lowered.contains("refresh") || lowered.contains("arrow.triangle") || lowered.contains("arrow.counter") { return .refresh }
        if lowered.contains("wifi") || lowered.contains("keyboard") { return .refresh }
        if lowered.contains("speaker") || lowered.contains("music") { return .sound }
        if lowered.contains("haptic") || lowered.contains("hand.tap") { return .haptics }
        if lowered.contains("lock") || lowered.contains("shield") { return .lockShield }
        if lowered.contains("heart") { return .heart }
        return .leaf
    }

    var legacySystemName: String {
        switch self {
        case .home:
            return "house"
        case .breathe:
            return "wind"
        case .focus:
            return "timer"
        case .bell:
            return "bell"
        case .roots:
            return "circle.hexagongrid.fill"
        case .pulse:
            return "waveform.path.ecg"
        case .journal:
            return "book.closed"
        case .quiet:
            return "moon"
        case .settings:
            return "gearshape"
        case .chevron:
            return "chevron.right"
        case .plus:
            return "plus"
        case .minus:
            return "minus"
        case .play:
            return "play.fill"
        case .pause:
            return "pause.fill"
        case .stop:
            return "stop.fill"
        case .refresh:
            return "arrow.triangle.2.circlepath"
        case .sound:
            return "speaker.wave.2.fill"
        case .haptics:
            return "hand.tap"
        case .leaf:
            return "leaf.fill"
        case .lockShield:
            return "lock.shield"
        case .timer:
            return "timer"
        case .heart:
            return "heart"
        }
    }
}

struct MoriGeneratedArtImage: View {
    let art: MoriGeneratedArt
    var contentMode: ContentMode = .fit

    var body: some View {
        Image(art.rawValue)
            .resizable()
            .renderingMode(.original)
            .aspectRatio(contentMode: contentMode)
            .accessibilityHidden(true)
    }
}

struct MoriPlainWatercolorCardBackground: View {
    var cornerRadius: CGFloat = 20
    var fill: Color = Color(red: 0.99, green: 0.97, blue: 0.91).opacity(0.82)
    var paperWash: MoriGeneratedArt = .cardPaperWash
    var paperOpacity: Double = 0.08
    var edgeOpacity: Double = 0.05

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color(red: 1.0, green: 0.984, blue: 0.941).opacity(0.96))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill)
            }
            .overlay {
                paperWashImage
                    .opacity(paperOpacity)
                    .blendMode(.multiply)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .overlay {
                LinearGradient(
                    colors: [
                        Color(red: 0.82, green: 0.77, blue: 0.62).opacity(edgeOpacity),
                        .clear,
                        Color(red: 0.43, green: 0.54, blue: 0.40).opacity(edgeOpacity * 0.72)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(.multiply)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var paperWashImage: some View {
        if paperWash == .cardPaperWash {
            MoriGeneratedArtImage(art: .cardPaperWash, contentMode: .fill)
        } else {
            MoriGeneratedArtImage(art: paperWash, contentMode: .fill)
        }
    }
}

struct MoriGeneratedHeroArt: View {
    let art: MoriGeneratedArt
    var opacity: Double = 0.86
    var fadeRadius: CGFloat = 0.66

    var body: some View {
        GeometryReader { proxy in
            let radius = min(proxy.size.width, proxy.size.height) * fadeRadius

            MoriGeneratedArtImage(art: art)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .opacity(opacity)
                .blendMode(.multiply)
                .mask(
                    RadialGradient(
                        colors: [
                            .white,
                            .white,
                            .white.opacity(0.88),
                            .clear
                        ],
                        center: .center,
                        startRadius: radius * 0.48,
                        endRadius: radius
                    )
                )
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

struct MoriBitmapIconImage: View {
    let icon: MoriBitmapIcon
    var size: CGFloat = 24
    var opacity: Double = 1

    var body: some View {
        Image(icon.rawValue)
            .resizable()
            .renderingMode(.original)
            .scaledToFit()
            .frame(width: size, height: size)
            .opacity(opacity)
            .accessibilityHidden(true)
    }
}

struct MoriBitmapIconBadge: View {
    let icon: MoriBitmapIcon
    var size: CGFloat = 42
    var iconScale: CGFloat = 0.62
    var fill: Color = Color.white.opacity(0.62)
    var stroke: Color = Color.white.opacity(0.88)
    var shadow: Color = Color(red: 0.078, green: 0.224, blue: 0.184).opacity(0.08)

    var body: some View {
        MoriBitmapIconImage(icon: icon, size: size * iconScale)
            .frame(width: size, height: size)
            .background(fill)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(stroke, lineWidth: 1)
            )
            .shadow(color: shadow, radius: 8, x: 0, y: 5)
            .accessibilityHidden(true)
    }
}

enum MoriProductSymbol: String, CaseIterable {
    case beforeFeedReset
    case morningReset
    case attentionStreak
    case appLimit
    case weekArchive
    case dailyLog
    case focusPoint
    case neutralDay
    case settings
}

extension MoriProductSymbol {
    var bitmapIcon: MoriBitmapIcon {
        switch self {
        case .beforeFeedReset:
            return .leaf
        case .morningReset:
            return .leaf
        case .attentionStreak:
            return .pulse
        case .appLimit:
            return .lockShield
        case .weekArchive:
            return .roots
        case .dailyLog:
            return .journal
        case .focusPoint:
            return .focus
        case .neutralDay:
            return .focus
        case .settings:
            return .settings
        }
    }
}

struct MoriProductSymbolView: View {
    let symbol: MoriProductSymbol
    var size: CGFloat = 24
    var tint: Color = Color(red: 0.078, green: 0.224, blue: 0.184)
    var opacity: Double = 1

    var body: some View {
        symbolContent
            .frame(width: size, height: size)
            .opacity(opacity)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var symbolContent: some View {
        switch symbol {
        case .beforeFeedReset:
            MoriBeforeFeedResetSymbol(tint: tint)
        case .morningReset:
            MoriMorningResetSymbol(tint: tint)
        case .attentionStreak:
            MoriAttentionStreakSymbol(tint: tint)
        case .appLimit:
            MoriAppLimitSymbol(tint: tint)
        case .weekArchive:
            MoriWeekArchiveSymbol(tint: tint)
        case .dailyLog:
            MoriDailyLogSymbol(tint: tint)
        case .focusPoint:
            MoriFocusPointSymbol(tint: tint)
        case .neutralDay:
            MoriNeutralDaySymbol(tint: tint)
        case .settings:
            MoriSettingsSymbol(tint: tint)
        }
    }
}

struct MoriProductSymbolBadge: View {
    let symbol: MoriProductSymbol
    var size: CGFloat = 42
    var symbolScale: CGFloat = 0.64
    var tint: Color = Color(red: 0.078, green: 0.224, blue: 0.184)
    var fill: Color = Color.white.opacity(0.62)
    var stroke: Color = Color.white.opacity(0.88)
    var shadow: Color = Color(red: 0.078, green: 0.224, blue: 0.184).opacity(0.08)

    var body: some View {
        MoriProductSymbolView(symbol: symbol, size: size * symbolScale, tint: tint)
            .frame(width: size, height: size)
            .background(fill)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(stroke, lineWidth: 1)
            )
            .shadow(color: shadow, radius: 8, x: 0, y: 5)
            .accessibilityHidden(true)
    }
}

private struct MoriBeforeFeedResetSymbol: View {
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let strokeWidth = max(CGFloat(1.6), side * 0.07)

            ZStack {
                Circle()
                    .trim(from: 0.09, to: 0.83)
                    .stroke(
                        tint.opacity(0.42),
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                    )
                    .frame(width: side * 0.74, height: side * 0.74)
                    .rotationEffect(.degrees(-108))
                    .position(x: side * 0.5, y: side * 0.5)

                Circle()
                    .fill(tint.opacity(0.10))
                    .frame(width: side * 0.54, height: side * 0.54)
                    .position(x: side * 0.5, y: side * 0.5)

                Capsule()
                    .fill(tint)
                    .frame(width: max(CGFloat(2), side * 0.10), height: side * 0.38)
                    .position(x: side * 0.43, y: side * 0.50)

                Capsule()
                    .fill(tint)
                    .frame(width: max(CGFloat(2), side * 0.10), height: side * 0.38)
                    .position(x: side * 0.57, y: side * 0.50)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct MoriAttentionStreakSymbol: View {
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: side * 0.25, y: side * 0.66))
                    path.addLine(to: CGPoint(x: side * 0.47, y: side * 0.52))
                    path.addLine(to: CGPoint(x: side * 0.72, y: side * 0.38))
                }
                .stroke(
                    tint.opacity(0.42),
                    style: StrokeStyle(lineWidth: max(CGFloat(2), side * 0.095), lineCap: .round, lineJoin: .round)
                )

                Circle()
                    .fill(tint.opacity(0.28))
                    .frame(width: side * 0.22, height: side * 0.22)
                    .position(x: side * 0.25, y: side * 0.66)

                Circle()
                    .fill(tint.opacity(0.60))
                    .frame(width: side * 0.26, height: side * 0.26)
                    .position(x: side * 0.47, y: side * 0.52)

                Circle()
                    .fill(tint)
                    .frame(width: side * 0.30, height: side * 0.30)
                    .position(x: side * 0.72, y: side * 0.38)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct MoriMorningResetSymbol: View {
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let strokeWidth = max(CGFloat(1.5), side * 0.065)

            ZStack {
                Circle()
                    .trim(from: 0.12, to: 0.86)
                    .stroke(
                        tint.opacity(0.44),
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                    )
                    .frame(width: side * 0.76, height: side * 0.76)
                    .rotationEffect(.degrees(32))
                    .position(x: side * 0.5, y: side * 0.5)

                Circle()
                    .fill(tint.opacity(0.14))
                    .frame(width: side * 0.52, height: side * 0.52)
                    .position(x: side * 0.5, y: side * 0.52)

                Path { path in
                    path.move(to: CGPoint(x: side * 0.32, y: side * 0.55))
                    path.addQuadCurve(
                        to: CGPoint(x: side * 0.68, y: side * 0.55),
                        control: CGPoint(x: side * 0.50, y: side * 0.22)
                    )
                }
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: max(CGFloat(1.8), side * 0.075), lineCap: .round)
                )

                Capsule()
                    .fill(tint)
                    .frame(width: side * 0.58, height: max(CGFloat(1.8), side * 0.07))
                    .position(x: side * 0.5, y: side * 0.62)

                Capsule()
                    .fill(tint.opacity(0.36))
                    .frame(width: side * 0.40, height: max(CGFloat(1.4), side * 0.05))
                    .position(x: side * 0.5, y: side * 0.75)

                Circle()
                    .fill(tint)
                    .frame(width: side * 0.12, height: side * 0.12)
                    .position(x: side * 0.72, y: side * 0.30)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct MoriAppLimitSymbol: View {
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                RoundedRectangle(cornerRadius: side * 0.17, style: .continuous)
                    .fill(tint.opacity(0.10))
                    .frame(width: side * 0.64, height: side * 0.72)
                    .position(x: side * 0.5, y: side * 0.5)

                RoundedRectangle(cornerRadius: side * 0.17, style: .continuous)
                    .stroke(tint.opacity(0.90), lineWidth: max(CGFloat(1.5), side * 0.055))
                    .frame(width: side * 0.64, height: side * 0.72)
                    .position(x: side * 0.5, y: side * 0.5)

                Capsule()
                    .fill(tint.opacity(0.38))
                    .frame(width: side * 0.30, height: max(CGFloat(1.5), side * 0.055))
                    .position(x: side * 0.5, y: side * 0.28)

                Circle()
                    .fill(tint)
                    .frame(width: side * 0.20, height: side * 0.20)
                    .position(x: side * 0.5, y: side * 0.52)

                Capsule()
                    .fill(tint)
                    .frame(width: side * 0.34, height: max(CGFloat(2), side * 0.08))
                    .position(x: side * 0.5, y: side * 0.70)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct MoriWeekArchiveSymbol: View {
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                RoundedRectangle(cornerRadius: side * 0.16, style: .continuous)
                    .fill(tint.opacity(0.10))
                    .frame(width: side * 0.78, height: side * 0.72)
                    .position(x: side * 0.5, y: side * 0.54)

                RoundedRectangle(cornerRadius: side * 0.16, style: .continuous)
                    .stroke(tint.opacity(0.92), lineWidth: max(CGFloat(1.5), side * 0.055))
                    .frame(width: side * 0.78, height: side * 0.72)
                    .position(x: side * 0.5, y: side * 0.54)

                Capsule()
                    .fill(tint)
                    .frame(width: side * 0.48, height: max(CGFloat(2), side * 0.08))
                    .position(x: side * 0.5, y: side * 0.28)

                ForEach(0..<3, id: \.self) { row in
                    ForEach(0..<3, id: \.self) { column in
                        RoundedRectangle(cornerRadius: side * 0.025, style: .continuous)
                            .fill(tint.opacity(row == 2 && column == 1 ? 0.96 : 0.34))
                            .frame(width: side * 0.105, height: side * 0.105)
                            .position(
                                x: side * (0.32 + CGFloat(column) * 0.18),
                                y: side * (0.46 + CGFloat(row) * 0.15)
                            )
                    }
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct MoriDailyLogSymbol: View {
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                RoundedRectangle(cornerRadius: side * 0.14, style: .continuous)
                    .fill(tint.opacity(0.10))
                    .frame(width: side * 0.62, height: side * 0.72)
                    .position(x: side * 0.5, y: side * 0.5)

                RoundedRectangle(cornerRadius: side * 0.14, style: .continuous)
                    .stroke(tint.opacity(0.86), lineWidth: max(CGFloat(1.5), side * 0.055))
                    .frame(width: side * 0.62, height: side * 0.72)
                    .position(x: side * 0.5, y: side * 0.5)

                Capsule()
                    .fill(tint)
                    .frame(width: max(CGFloat(1.5), side * 0.06), height: side * 0.46)
                    .position(x: side * 0.34, y: side * 0.50)

                Circle()
                    .fill(tint)
                    .frame(width: side * 0.12, height: side * 0.12)
                    .position(x: side * 0.50, y: side * 0.38)

                Capsule()
                    .fill(tint.opacity(0.72))
                    .frame(width: side * 0.24, height: max(CGFloat(1.5), side * 0.055))
                    .position(x: side * 0.55, y: side * 0.54)

                Capsule()
                    .fill(tint.opacity(0.36))
                    .frame(width: side * 0.18, height: max(CGFloat(1.5), side * 0.05))
                    .position(x: side * 0.52, y: side * 0.66)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct MoriFocusPointSymbol: View {
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                RoundedRectangle(cornerRadius: side * 0.14, style: .continuous)
                    .fill(tint.opacity(0.10))
                    .frame(width: side * 0.76, height: side * 0.62)
                    .position(x: side * 0.5, y: side * 0.5)

                RoundedRectangle(cornerRadius: side * 0.14, style: .continuous)
                    .stroke(tint.opacity(0.52), lineWidth: max(CGFloat(1.4), side * 0.045))
                    .frame(width: side * 0.76, height: side * 0.62)
                    .position(x: side * 0.5, y: side * 0.5)

                Circle()
                    .fill(tint)
                    .frame(width: side * 0.18, height: side * 0.18)
                    .position(x: side * 0.34, y: side * 0.44)

                Capsule()
                    .fill(tint)
                    .frame(width: side * 0.34, height: max(CGFloat(2), side * 0.08))
                    .position(x: side * 0.58, y: side * 0.44)

                Capsule()
                    .fill(tint.opacity(0.32))
                    .frame(width: side * 0.44, height: max(CGFloat(1.5), side * 0.055))
                    .position(x: side * 0.54, y: side * 0.62)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct MoriNeutralDaySymbol: View {
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                Circle()
                    .stroke(tint.opacity(0.46), lineWidth: max(CGFloat(1.5), side * 0.065))
                    .frame(width: side * 0.74, height: side * 0.74)
                    .position(x: side * 0.5, y: side * 0.5)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct MoriSettingsSymbol: View {
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(tint.opacity(0.34))
                        .frame(width: side * 0.76, height: max(CGFloat(1.7), side * 0.065))
                        .position(x: side * 0.5, y: rowY(index, side: side))

                    Circle()
                        .fill(tint)
                        .frame(width: side * 0.18, height: side * 0.18)
                        .position(x: knobX(index, side: side), y: rowY(index, side: side))
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func rowY(_ index: Int, side: CGFloat) -> CGFloat {
        switch index {
        case 0:
            return side * 0.28
        case 1:
            return side * 0.50
        default:
            return side * 0.72
        }
    }

    private func knobX(_ index: Int, side: CGFloat) -> CGFloat {
        switch index {
        case 0:
            return side * 0.34
        case 1:
            return side * 0.66
        default:
            return side * 0.46
        }
    }
}

extension View {
    func moriGeneratedPaperBackground() -> some View {
        background(
            MoriGeneratedArtImage(art: .paperWash, contentMode: .fill)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        )
    }
}
