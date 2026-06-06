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
            MoriForestBackground {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        MoriPageHeader(
                            eyebrow: "Clock",
                            title: "Time",
                            subtitle: "Hold the day in view, then spend the next hour deliberately."
                        )

                        VStack(alignment: .leading, spacing: 18) {
                            Text("You have")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(MoriColors.forestMuted)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(primaryCountdownValue)")
                                    .font(.system(size: 64, weight: .semibold, design: .rounded))
                                    .foregroundColor(MoriColors.forestCanopy)
                                    .monospacedDigit()
                                    .contentTransition(.numericText())
                                    .animation(.easeInOut(duration: 0.3), value: primaryCountdownValue)

                                Text(primaryCountdownLabel)
                                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                                    .foregroundColor(MoriColors.forestMoss)
                            }

                            HStack(spacing: 14) {
                                TimeUnitViewDark(value: countdown.hours, label: "hours")
                                TimeUnitViewDark(value: countdown.minutes, label: "min")
                                TimeUnitViewDark(value: countdown.seconds, label: "sec")
                            }

                            Text(motivationalMessages[currentMessageIndex])
                                .font(.system(size: 16, weight: .regular, design: .serif))
                                .foregroundColor(MoriColors.forestMuted)
                                .lineSpacing(2)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.5), value: currentMessageIndex)
                        }
                        .moriSanctuaryCard(cornerRadius: 24, padding: 18)

                        DailySparkCard(store: dailySparkStore, onSaved: { _ in
                            showSparkSavedToast()
                        })
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Mori")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(MoriColors.forestPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(MoriColors.forestCanopy.opacity(0.82))
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
                        .foregroundColor(MoriColors.forestCard)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(MoriColors.forestCanopy)
                        .cornerRadius(10)
                        .padding(.bottom, 24)
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

// MARK: - Time Unit View
struct TimeUnitViewDark: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%02d", value))
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.forestCanopy)
                .monospacedDigit()

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(MoriColors.forestMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(MoriColors.forestCanopy.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Preview
#Preview {
    ClockView()
        .environmentObject(UserSettings())
}
