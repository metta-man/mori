import SwiftUI
import Combine
import UserNotifications

// MARK: - Clock Countdown View
/// Real-time countdown to end of life based on user's birthdate and life expectancy
/// Design spec: warm dark theme with gold accents
struct ClockView: View {
    @EnvironmentObject var settings: UserSettings
    @State private var countdown = CountdownResult(days: 0, hours: 0, minutes: 0, seconds: 0)
    @State private var showReminder = false
    @State private var currentMessageIndex = 0
    @State private var showSettings = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let motivationalMessages = [
        "去创造有意义的回忆",
        "让每一天都有价值",
        "每一周都是礼物",
        "活在当下",
        "珍惜此刻",
        "今天很珍贵"
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
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // "你还有" header
                    Text("你还有")
                        .font(.custom("CrimsonPro", size: 20))
                        .foregroundColor(MoriColors.moriCream.opacity(0.6))
                        .tracking(0.1)
                    
                    // Main countdown number - DM Mono style, gold, per design spec
                    VStack(spacing: 8) {
                        Text("\(countdown.days)")
                            .font(.system(size: 64, weight: .light, design: .monospaced))
                            .foregroundColor(MoriColors.moriGold)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.3), value: countdown.days)
                        
                        Text("天")
                            .font(.custom("CrimsonPro", size: 24))
                            .foregroundColor(MoriColors.moriCream)
                    }
                    .padding(.bottom, 16)
                    
                    // Time breakdown - hours, minutes, seconds
                    HStack(spacing: 20) {
                        TimeUnitViewDark(value: countdown.hours, label: "小时")
                        Text(":")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(MoriColors.moriCream.opacity(0.4))
                            .opacity(countdown.seconds % 2 == 0 ? 1 : 0.3)
                        TimeUnitViewDark(value: countdown.minutes, label: "分")
                        Text(":")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(MoriColors.moriCream.opacity(0.4))
                            .opacity(countdown.seconds % 2 == 0 ? 1 : 0.3)
                        TimeUnitViewDark(value: countdown.seconds, label: "秒")
                    }
                    .padding(.top, 32)
                    
                    // Motivational message - Crimson Pro Italic per design spec
                    Text(motivationalMessages[currentMessageIndex])
                        .font(.custom("CrimsonPro-Italic", size: 18))
                        .foregroundColor(MoriColors.moriCream.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                        .padding(.top, 48)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.5), value: currentMessageIndex)
                    
                    Spacer()
                    
                    // Reminder toggle card
                    ReminderToggleCardDark(isOn: $showReminder)
                        .padding(.bottom, 48)
                }
                .padding(.horizontal, 24)
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
                ClockSettingsSheetDark(isPresented: $showSettings)
                    .environmentObject(settings)
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
                .tracking(1)
        }
        .frame(minWidth: 60)
    }
}

// MARK: - Reminder Toggle Card (Dark Theme)
struct ReminderToggleCardDark: View {
    @Binding var isOn: Bool
    @State private var showToast = false
    
    var body: some View {
        HStack {
            Image(systemName: "bell")
                .font(.system(size: 20))
                .foregroundColor(MoriColors.moriGold)
            
            Text("每天早上 8:00 提醒我")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(MoriColors.moriCream)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(MoriColors.moriGold)
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
        .background(MoriColors.moriDark.opacity(0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MoriColors.moriGold.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(16)
        .overlay(alignment: .bottom) {
            if showToast {
                Text("每日提醒已设置: 早上 8:00")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.moriDark)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(MoriColors.moriGold)
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
        content.body = "今天你想创造什么有意义的回忆?"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Clock Settings Sheet (Dark Theme)
struct ClockSettingsSheetDark: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var settings: UserSettings
    @State private var showCountdown = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("显示") {
                    Toggle("显示倒计时", isOn: $showCountdown)
                        .tint(MoriColors.moriGold)
                    
                    Picker("预期寿命", selection: $settings.lifeExpectancy) {
                        ForEach(60...120, id: \.self) { age in
                            Text("\(age) 年").tag(age)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(MoriColors.moriDark)
            .navigationTitle("时钟设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MoriColors.moriDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        isPresented = false
                    }
                    .foregroundColor(MoriColors.moriGold)
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
