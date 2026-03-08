import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: UserSettings
    @State private var showingDatePicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Birth Date",
                        selection: $settings.birthDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    
                    Stepper(
                        "Life Expectancy: \(settings.lifeExpectancy) years",
                        value: $settings.lifeExpectancy,
                        in: 60...100
                    )
                } header: {
                    Text("Your Life")
                }
                
                Section {
                    LabeledContent("Total Weeks", value: "\(settings.totalWeeks)")
                    LabeledContent("Weeks Lived", value: "\(settings.weeksLived)")
                    LabeledContent("Weeks Remaining", value: "\(settings.weeksRemaining)")
                } header: {
                    Text("Statistics")
                }
                
                Section {
                    Text("Mori reminds us that time is precious. Use this grid to visualize your life and make each week count.")
                        .font(.footnote)
                        .foregroundColor(MoriColors.secondary)
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(UserSettings())
}
