import SwiftUI
import Combine

// MARK: - Clock Countdown View
/// Real-time countdown to end of life based on user's birthdate and life expectancy
/// Design spec: warm dark theme with gold accents
struct ClockView: View {
    @EnvironmentObject var settings: UserSettings
    @StateObject private var dailySparkStore = DailySparkStore.shared
    @State private var countdown = CountdownResult(days: 0, weeks: 0, months: 0, years: 0, hours: 0, minutes: 0, seconds: 0)
    @State private var currentMessageIndex = 0
    @State private var showSettings = false
    @State private var messageTimer: Timer?
    @State private var showSparkSaved = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let motivationalMessages = [
        "Make a memory worth keeping",
        "Let today carry weight",
        "Every week is a gift",
        "Be here while you are here",
        "Spend the hour deliberately",
        "Today is not a rehearsal",
        "Choose one thing that matters",
        "Leave the room a little warmer",
        "Give your attention somewhere worthy",
        "The small moment is still your life",
        "Do less, but mean it",
        "Call back what you love",
        "Let the next hour be honest",
        "Notice what is still here",
        "Make space for the person beside you",
        "You are alive in this exact minute",
        "Spend your breath with care",
        "Keep one promise to yourself",
        "Turn urgency into presence",
        "Let enough be enough for now",
        "Return to what you can touch",
        "Carry the day gently",
        "Make ordinary time sacred",
        "Stay close to what is real",
        "Begin again without ceremony"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background with subtle radial gradient per design spec
                MoriColors.moriDark
                    .ignoresSafeArea()
                
                // Subtle radial gradient overlay
                RadialGradient(
                    colors: [
                        MoriColors.moriGold.opacity(0.03),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Text("You have")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(MoriColors.moriCream.opacity(0.6))
                            .tracking(0.1)
                        
                        // Main countdown number - DM Mono style, gold, per design spec
                        VStack(spacing: 8) {
                            Text("\(primaryCountdownValue)")
                                .font(.system(size: 64, weight: .light, design: .monospaced))
                                .foregroundColor(MoriColors.moriGold)
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.3), value: primaryCountdownValue)
                            
                            Text(primaryCountdownLabel)
                                .font(.system(size: 24, weight: .medium, design: .rounded))
                                .foregroundColor(MoriColors.moriCream)
                        }
                        .padding(.bottom, 16)
                        
                        // Time breakdown - hours, minutes, seconds
                        HStack(spacing: 20) {
                            TimeUnitViewDark(value: countdown.hours, label: "hours")
                            Text(":")
                                .font(.system(size: 36, weight: .light))
                                .foregroundColor(MoriColors.moriCream.opacity(0.4))
                                .opacity(countdown.seconds % 2 == 0 ? 1 : 0.3)
                            TimeUnitViewDark(value: countdown.minutes, label: "min")
                            Text(":")
                                .font(.system(size: 36, weight: .light))
                                .foregroundColor(MoriColors.moriCream.opacity(0.4))
                                .opacity(countdown.seconds % 2 == 0 ? 1 : 0.3)
                            TimeUnitViewDark(value: countdown.seconds, label: "sec")
                        }
                        .padding(.top, 32)
                        
                        // Motivational message - Crimson Pro Italic per design spec
                        Text(motivationalMessages[currentMessageIndex])
                            .font(.system(size: 18, weight: .regular, design: .serif))
                            .foregroundColor(MoriColors.moriCream.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                            .padding(.top, 48)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.5), value: currentMessageIndex)

                        DailySparkCard(store: dailySparkStore, onSaved: { _ in
                            showSparkSavedToast()
                        })
                        .padding(.top, 28)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 42)
                    .padding(.bottom, 132)
                }
            }
            .navigationTitle("Mori")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(MoriColors.moriDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(MoriColors.moriGold.opacity(0.8))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(settings)
            }
            .onReceive(timer) { _ in
                updateCountdown()
            }
            .onAppear {
                updateCountdown()
                startMessageRotation()
            }
            .onDisappear {
                stopMessageRotation()
            }
            .overlay(alignment: .bottom) {
                if showSparkSaved {
                    Text("Saved to Journal")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(MoriColors.moriDark)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(MoriColors.moriGold)
                        .cornerRadius(10)
                        .padding(.bottom, 124)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
    
    private func updateCountdown() {
        countdown = calculateCountdown()
    }

    private var primaryCountdownValue: Int {
        switch settings.clockTimeUnit {
        case .days:
            return countdown.days
        case .weeks:
            return countdown.weeks
        case .months:
            return countdown.months
        case .years:
            return countdown.years
        }
    }

    private var primaryCountdownLabel: String {
        primaryCountdownValue == 1 ? settings.clockTimeUnit.singularLabel : settings.clockTimeUnit.pluralLabel
    }
    
    private func calculateCountdown() -> CountdownResult {
        let now = Date()
        let calendar = Calendar.current
        
        // Calculate expected end date based on birthdate + life expectancy
        let birthDate = settings.birthDate
        let lifeExpectancy = settings.lifeExpectancy
        let endDate = calendar.date(byAdding: .year, value: lifeExpectancy, to: birthDate) ?? birthDate
        
        // Calculate difference
        let components = calendar.dateComponents([.day, .hour, .minute, .second], from: now, to: endDate)
        
        let days = max(0, components.day ?? 0)
        let weeks = max(0, days / 7)
        let months = max(0, calendar.dateComponents([.month], from: now, to: endDate).month ?? 0)
        let years = max(0, calendar.dateComponents([.year], from: now, to: endDate).year ?? 0)
        let hours = max(0, components.hour ?? 0)
        let minutes = max(0, components.minute ?? 0)
        let seconds = max(0, components.second ?? 0)
        
        return CountdownResult(days: days, weeks: weeks, months: months, years: years, hours: hours, minutes: minutes, seconds: seconds)
    }
    
    private func startMessageRotation() {
        stopMessageRotation()

        messageTimer = Timer.scheduledTimer(withTimeInterval: 18, repeats: true) { _ in
            withAnimation {
                currentMessageIndex = (currentMessageIndex + 1) % motivationalMessages.count
            }
        }
    }

    private func stopMessageRotation() {
        messageTimer?.invalidate()
        messageTimer = nil
    }

    private func showSparkSavedToast() {
        withAnimation {
            showSparkSaved = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSparkSaved = false
            }
        }
    }
}

// MARK: - Countdown Result
struct CountdownResult {
    let days: Int
    let weeks: Int
    let months: Int
    let years: Int
    let hours: Int
    let minutes: Int
    let seconds: Int
}

// MARK: - Time Unit View (Dark Theme)
struct TimeUnitViewDark: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%02d", value))
                .font(.system(size: 36, weight: .light, design: .monospaced))
                .foregroundColor(MoriColors.moriCream)
                .monospacedDigit()
            
            Text(label)
                .font(.custom("CrimsonPro", size: 12))
                .foregroundColor(MoriColors.moriCream.opacity(0.5))
        }
        .frame(minWidth: 60)
    }
}

// MARK: - Preview
#Preview {
    ClockView()
        .environmentObject(UserSettings())
}
