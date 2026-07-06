import SwiftUI

extension View {
    func pomodoroPracticeChrome(
        isDarkRoomActive: Bool,
        onBack: @escaping () -> Void
    ) -> some View {
        modifier(
            PomodoroPracticeChromeModifier(
                isDarkRoomActive: isDarkRoomActive,
                onBack: onBack
            )
        )
    }
}

private struct PomodoroPracticeChromeModifier: ViewModifier {
    let isDarkRoomActive: Bool
    let onBack: () -> Void

    func body(content: Content) -> some View {
        content
            .navigationTitle("Pomodoro")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onBack) {
                        MoriBitmapIconImage(
                            icon: .chevron,
                            size: 15,
                            opacity: isDarkRoomActive ? 0.72 : 0.88
                        )
                        .rotationEffect(.degrees(180))
                    }
                    .accessibilityLabel("Back")
                }
            }
            .toolbarBackground(isDarkRoomActive ? .black : MoriColors.botanicalPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(isDarkRoomActive ? .dark : .light, for: .navigationBar)
            .toolbar(isDarkRoomActive ? .hidden : .visible, for: .navigationBar)
            .moriHidesMainTabBar()
    }
}
