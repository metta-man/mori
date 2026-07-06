import SwiftUI

struct MoriPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(MoriTypography.body.weight(.semibold))
            .foregroundColor(MoriColors.sanctuarySurface)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    MoriColors.sanctuaryInk
                    MoriGeneratedArtImage(art: .buttonWash, contentMode: .fill)
                        .opacity(0.18)
                        .blendMode(.screen)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
