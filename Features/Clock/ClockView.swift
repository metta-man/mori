import SwiftUI
import Combine
import UserNotifications

// MARK: - Clock Countdown View
/// Real-time countdown to end of life based on user's birthdate and life expectancy
struct ClockView: View {
    @EnvironmentObject var settings: UserSettings
    @State private var countdown = CountdownResult(days: 0, hours: 0, minutes: 0, seconds: 0)
    @State private var showReminder = false
    @State private var currentMessageIndex = 0
    @State private var showSettings = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let motivationalMessages = [
        "You have time to create memories",
        "Make them count",
        "Every week is a gift",
        "Live intentionally",
        "Your time is now",
        "Cherish each moment",
        "Today is precious"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(hex: "#FDF5E6")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Main countdown number
                    VStack(spacing: 8) {
                        Text("\(countdown.days)")
                            .font(.system(size: 64, weight: .light, design: .rounded))
                            .foregroundColor(Color(hex: "#333333"))
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.3), value: countdown.days)
                        
                        Text("days")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "#888888"))
                            .textCase(.uppercase)
                            .tracking(2)
                    }
                    .padding(.bottom, 16)
                    
                    // Time breakdown
                    HStack(spacing: 20) {
                        TimeUnitView(value: countdown.hours, label: "hours")
                        Text(":")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(Color(hex: "#E8E8E8"))
                            .opacity(countdown.seconds % 2 == 0 ? 1 : 0.3)
                        TimeUnitView(value: countdown.minutes, label: "min")
                        Text(":")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(Color(hex: "#E8E8E8"))
                            .opacity(countdown.seconds % 2 == 0 ? 1 : 0.3)
                        TimeUnitView(value: countdown.seconds, label: "sec")
                    }
                    .padding(.top, 32)
                    
                    // Motivational message
                    Text(motivationalMessages[currentMessageIndex])
                        .font(.custom("CrimsonPro-Italic", size: 18))
                        .foregroundColor(Color(hex: "#666666"))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                        .padding(.top, 48)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.5), value: currentMessageIndex)
                    
                    Spacer()
                    
                    // Reminder toggle card
                    ReminderToggleCard(isOn: $showReminder)
                        .padding(.bottom, 48)
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Mori")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(Color(hex: "#8B7355"))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                ClockSettingsSheet(isPresented: $showSettings)
            }
            .onReceive(timer) { _ in
                updateCountdown()
            }
            .onAppear {
                updateCountdown()
                startMessageRotation()
            }
        }
    }
    
    private func updateCountdown() {
        countdown = calculateCountdown()
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
        let hours = max(0, components.hour ?? 0)
        let minutes = max(0, components.minute ?? 0)
        let seconds = max(0, components.second ?? 0)
        
        return CountdownResult(days: days, hours: hours, minutes: minutes, seconds: seconds)
    }
    
    private func startMessageRotation() {
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            withAnimation {
                currentMessageIndex = (currentMessageIndex + 1) % motivationalMessages.count
            }
        }
    }
}

// MARK: - Countdown Result
struct CountdownResult {
    let days: Int
    let hours: Int
    let minutes: Int
    let seconds: Int
}

// MARK: - Time Unit View
struct TimeUnitView: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%02d", value))
                .font(.system(size: 36, weight: .light))
                .foregroundColor(Color(hex: "#333333"))
                .monospacedDigit()
            
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(hex: "#AAAAAA"))
                .textCase(.uppercase)
                .tracking(1)
        }
        .frame(minWidth: 60)
    }
}

// MARK: - Reminder Toggle Card
struct ReminderToggleCard: View {
    @Binding var isOn: Bool
    @State private var showToast = false
    
    var body: some View {
        HStack {
            Image(systemName: "bell")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "#D4AF37"))
            
            Text("Remind me daily at 8:00 AM")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#333333"))
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(hex: "#D4AF37"))
                .onChange(of: isOn) { newValue in
                    if newValue {
                        showToast = true
                        // Request notification permission
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                            if granted {
                                scheduleDailyReminder()
                            }
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showToast = false
                        }
                    }
                }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(alignment: .bottom) {
            if showToast {
                Text("Daily reminder set for 8:00 AM")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#333333"))
                    .cornerRadius(8)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    private func scheduleDailyReminder() {
        // Schedule daily notification at 8:00 AM
        let content = UNMutableNotificationContent()
        content.title = "Mori"
        content.body = "How will you make today meaningful?"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Clock Settings Sheet
struct ClockSettingsSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var settings: UserSettings
    @State private var showCountdown = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Display") {
                    Toggle("Show Countdown", isOn: $showCountdown)
                        .tint(Color(hex: "#D4AF37"))
                    
                    Picker("Life Expectancy", selection: $settings.lifeExpectancy) {
                        ForEach(60...120, id: \.self) { age in
                            Text("\(age) years").tag(age)
                        }
                    }
                }
            }
            .navigationTitle("Clock Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ClockView()
        .environmentObject(UserSettings())
}
