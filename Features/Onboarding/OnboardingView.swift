//
//  OnboardingView.swift
//  Mori
//
//  Onboarding flow for new users
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userSettings: UserSettings
    @State private var currentPage = 0
    @State private var selectedBirthDate = Date()
    @State private var selectedLifeExpectancy = 80
    
    let lifeExpectancyOptions = Array(60...100)
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index <= currentPage ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 40)
            
            TabView(selection: $currentPage) {
                // Page 1: Welcome
                welcomePage
                    .tag(0)
                
                // Page 2: Birth Date
                birthDatePage
                    .tag(1)
                
                // Page 3: Life Expectancy
                lifeExpectancyPage
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            // Next/Get Started button
            Button(action: nextAction) {
                Text(currentPage == 2 ? "Get Started" : "Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Pages
    
    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "leaf.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("Welcome to Mori")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Memento mori — remember that you will die. But instead of fear, let it inspire you to live fully.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    private var birthDatePage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "calendar")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("When were you born?")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("This helps us calculate your life remaining")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            DatePicker(
                "Birth Date",
                selection: $selectedBirthDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding(.horizontal, 16)
            
            Spacer()
        }
    }
    
    private var lifeExpectancyPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("How long do you expect to live?")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("This is just an estimate — update it anytime")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Picker("Life Expectancy", selection: $selectedLifeExpectancy) {
                ForEach(lifeExpectancyOptions, id: \.self) { age in
                    Text("\(age) years").tag(age)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
            
            Text("You have approximately \((80 - yearsAlive) * 52) weeks remaining")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    private var yearsAlive: Int {
        Calendar.current.dateComponents([.year], from: selectedBirthDate, to: Date()).year ?? 30
    }
    
    // MARK: - Actions
    
    private func nextAction() {
        if currentPage < 2 {
            withAnimation {
                currentPage += 1
            }
        } else {
            // Complete onboarding
            userSettings.birthDate = selectedBirthDate
            userSettings.lifeExpectancy = selectedLifeExpectancy
            userSettings.hasCompletedOnboarding = true
            AnalyticsManager.shared.trackOnboardingCompleted()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(UserSettings())
}
