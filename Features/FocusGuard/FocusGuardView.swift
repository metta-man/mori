import SwiftUI
import FamilyControls

// MARK: - Focus Guard Main View
struct FocusGuardView: View {
    @StateObject private var manager = FocusGuardManager.shared
    @State private var showAppPicker = false
    @State private var showSetupFlow = false
    
    var body: some View {
        NavigationStack {
            MoriForestBackground {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
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
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Focus Guard")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(MoriColors.forestPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
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
                        ? MoriColors.forestSeed.opacity(0.15)
                        : MoriColors.forestLine.opacity(0.45)
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: manager.shieldActive ? "shield.fill" : "shield")
                    .font(.system(size: 36))
                    .foregroundColor(manager.shieldActive ? MoriColors.forestSeed : MoriColors.forestMuted)
            }
            
            Text(manager.shieldActive ? "Apps Locked" : manager.allHabitsCompleted ? "All Clear" : "Focus Guard")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.forestCanopy)
            
            Text(manager.shieldActive
                 ? "Complete your daily habits to unlock"
                 : "Block distracting apps until you finish your habits"
            )
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(MoriColors.forestMuted)
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
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestCanopy)
                    
                    Text("Lock selected apps until habits are done")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(MoriColors.forestMuted)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { manager.isFocusGuardEnabled },
                    set: { manager.setFocusGuardEnabled($0) }
                ))
                .tint(MoriColors.forestMoss)
                .labelsHidden()
            }
            .moriSanctuaryCard(cornerRadius: 22, padding: 18)
        }
    }
    
    // MARK: - App Selection Section
    private var appSelectionSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Blocked Apps")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.forestCanopy)
                
                Spacer()
                
                if manager.hasSelectedApps {
                    Text("\(manager.blockedCount) selected")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(MoriColors.forestMuted)
                }
            }
            
            Button {
                showAppPicker = true
            } label: {
                HStack {
                    Image(systemName: manager.hasSelectedApps ? "pencil.circle" : "plus.circle")
                        .font(.system(size: 20))
                    
                    Text(manager.hasSelectedApps ? "Edit Blocked Apps" : "Select Apps to Block")
                    .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(MoriColors.forestCard)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(MoriColors.forestCanopy)
                .cornerRadius(12)
            }
            
            // Show hint of what's blocked (privacy: no app names shown)
            if manager.hasSelectedApps {
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 12))
                    Text("App names hidden for privacy")
                        .font(.system(size: 11, weight: .regular))
                }
                .foregroundColor(MoriColors.forestMuted)
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
    
    // MARK: - Status Card
    private var statusCard: some View {
        VStack(spacing: 16) {
            HStack {
                Circle()
                    .fill(manager.shieldActive ? MoriColors.forestClay : MoriColors.forestMoss)
                    .frame(width: 12, height: 12)
                
                Text(manager.shieldActive ? "Shield Active" : "Shield Off — Habits Complete")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.forestCanopy)
                
                Spacer()
            }
            
            if manager.shieldActive {
                Text("Your selected apps are locked. Complete all daily habits to regain access.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(MoriColors.forestMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if manager.isFocusGuardEnabled {
                Text("Great work! All habits completed — your apps are unlocked for today.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(MoriColors.forestMoss)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
    
    // MARK: - How It Works
    private var howItWorksSection: some View {
        VStack(spacing: 20) {
            Text("How It Works")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.forestCanopy)
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
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
    
    // MARK: - Preview (when disabled)
    private var previewSection: some View {
        VStack(spacing: 16) {
            Text("When enabled, Focus Guard will:")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(MoriColors.forestMuted)
            
            VStack(alignment: .leading, spacing: 12) {
                BenefitRow(icon: "shield.fill", text: "Block apps you choose (social media, games, etc.)")
                BenefitRow(icon: "list.checkmark", text: "Keep them locked until daily habits are complete")
                BenefitRow(icon: "lock.open", text: "Auto-unlock once you've earned your screen time")
                BenefitRow(icon: "brain.head.profile", text: "Build intentional phone habits over time")
            }
            .padding(16)
            .background(MoriColors.forestPaperDeep.opacity(0.58))
            .cornerRadius(12)
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
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
                    .fill(MoriColors.forestMoss.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(MoriColors.forestMoss)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.forestCanopy)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.forestMuted)
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
                .foregroundColor(MoriColors.forestMoss)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(MoriColors.forestCanopy)
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
