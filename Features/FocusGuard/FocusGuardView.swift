import SwiftUI
import FamilyControls

// MARK: - Focus Guard Main View
struct FocusGuardView: View {
    @StateObject private var manager = FocusGuardManager.shared
    @State private var showAppPicker = false
    @State private var showSetupFlow = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Hero Section
                    heroSection
                    
                    // Main Toggle
                    toggleSection
                    
                    // App Selection
                    if manager.isFocusGuardEnabled {
                        appSelectionSection
                        
                        // Status Card
                        statusCard
                        
                        // How It Works
                        howItWorksSection
                    } else {
                        // Preview when disabled
                        previewSection
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
            .background(MoriColors.background.ignoresSafeArea())
            .navigationTitle("Focus Guard")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAppPicker) {
                FamilyActivityPickerWrapper { selection in
                    manager.setSelectedApps(selection)
                }
            }
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        manager.shieldActive
                        ? MoriColors.accentAmber.opacity(0.15)
                        : MoriColors.warmGray.opacity(0.3)
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: manager.shieldActive ? "shield.fill" : "shield")
                    .font(.system(size: 36))
                    .foregroundColor(manager.shieldActive ? MoriColors.accentAmber : MoriColors.secondary)
            }
            
            Text(manager.shieldActive ? "Apps Locked" : manager.allHabitsCompleted ? "All Clear" : "Focus Guard")
                .font(.custom("CormorantGaramond-SemiBold", size: 28))
                .foregroundColor(MoriColors.text)
            
            Text(manager.shieldActive
                 ? "Complete your daily habits to unlock"
                 : "Block distracting apps until you finish your habits"
            )
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(MoriColors.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
    }
    
    // MARK: - Toggle Section
    private var toggleSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable Focus Guard")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(MoriColors.text)
                    
                    Text("Lock selected apps until habits are done")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(MoriColors.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { manager.isFocusGuardEnabled },
                    set: { manager.setFocusGuardEnabled($0) }
                ))
                .tint(MoriColors.accentAmber)
                .labelsHidden()
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - App Selection Section
    private var appSelectionSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Blocked Apps")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(MoriColors.text)
                
                Spacer()
                
                if manager.hasSelectedApps {
                    Text("\(manager.blockedCount) selected")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(MoriColors.secondary)
                }
            }
            
            Button {
                showAppPicker = true
            } label: {
                HStack {
                    Image(systemName: manager.hasSelectedApps ? "pencil.circle" : "plus.circle")
                        .font(.system(size: 20))
                    
                    Text(manager.hasSelectedApps ? "Edit Blocked Apps" : "Select Apps to Block")
                        .font(.custom("Poppins-Medium", size: 14))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(MoriColors.primary)
                .cornerRadius(12)
            }
            
            // Show hint of what's blocked (privacy: no app names shown)
            if manager.hasSelectedApps {
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 12))
                    Text("App names hidden for privacy")
                        .font(.custom("Poppins-Regular", size: 11))
                }
                .foregroundColor(MoriColors.secondary)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Status Card
    private var statusCard: some View {
        VStack(spacing: 16) {
            HStack {
                Circle()
                    .fill(manager.shieldActive ? Color(hex: "#FF6B35") : Color(hex: "#788c5d"))
                    .frame(width: 12, height: 12)
                
                Text(manager.shieldActive ? "Shield Active" : "Shield Off — Habits Complete")
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(MoriColors.text)
                
                Spacer()
            }
            
            if manager.shieldActive {
                Text("Your selected apps are locked. Complete all daily habits to regain access.")
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(MoriColors.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if manager.isFocusGuardEnabled {
                Text("Great work! All habits completed — your apps are unlocked for today.")
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(Color(hex: "#788c5d"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - How It Works
    private var howItWorksSection: some View {
        VStack(spacing: 20) {
            Text("How It Works")
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(MoriColors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            StepRow(
                number: 1,
                title: "Choose apps to block",
                subtitle: "Select social media, games, or any distracting apps",
                icon: "app.badge"
            )
            
            StepRow(
                number: 2,
                title: "Complete your daily habits",
                subtitle: "Mark all habits as done in the Habit tracker",
                icon: "checkmark.circle"
            )
            
            StepRow(
                number: 3,
                title: "Apps unlock automatically",
                subtitle: "Once all habits are done, blocked apps become available",
                icon: "lock.open"
            )
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Preview (when disabled)
    private var previewSection: some View {
        VStack(spacing: 16) {
            Text("When enabled, Focus Guard will:")
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(MoriColors.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                BenefitRow(icon: "shield.fill", text: "Block apps you choose (social media, games, etc.)")
                BenefitRow(icon: "list.checkmark", text: "Keep them locked until daily habits are complete")
                BenefitRow(icon: "lock.open", text: "Auto-unlock once you've earned your screen time")
                BenefitRow(icon: "brain.head.profile", text: "Build intentional phone habits over time")
            }
            .padding(16)
            .background(MoriColors.warmGray.opacity(0.3))
            .cornerRadius(12)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Supporting Views

struct StepRow: View {
    let number: Int
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(MoriColors.accentAmber.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(MoriColors.accentAmber)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(MoriColors.text)
                
                Text(subtitle)
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(MoriColors.secondary)
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(MoriColors.accentAmber)
                .frame(width: 20)
            
            Text(text)
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(MoriColors.text)
        }
    }
}

// MARK: - Family Activity Picker Wrapper
struct FamilyActivityPickerWrapper: View {
    let onSelect: (FamilyActivitySelection) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            FamilyActivityPicker { selection in
                onSelect(selection)
                dismiss()
            }
            .navigationTitle("Select Apps to Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    FocusGuardView()
}
