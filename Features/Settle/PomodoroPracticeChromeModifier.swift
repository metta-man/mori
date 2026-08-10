import SwiftUI

extension View {
    func pomodoroPracticeChrome(
        isDarkRoomActive: Bool,
        hidesNavigationChrome: Bool = false,
        onBack: @escaping () -> Void
    ) -> some View {
        modifier(
            PomodoroPracticeChromeModifier(
                isDarkRoomActive: isDarkRoomActive,
                hidesNavigationChrome: hidesNavigationChrome,
                onBack: onBack
            )
        )
    }
}

private struct PomodoroPracticeChromeModifier: ViewModifier {
    let isDarkRoomActive: Bool
    let hidesNavigationChrome: Bool
    let onBack: () -> Void

    func body(content: Content) -> some View {
        content
            .navigationTitle("")
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
            .toolbarBackground(Color.clear, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(isDarkRoomActive ? .dark : .light, for: .navigationBar)
            .toolbar(isDarkRoomActive || hidesNavigationChrome ? .hidden : .visible, for: .navigationBar)
            .moriHidesMainTabBar()
    }
}
