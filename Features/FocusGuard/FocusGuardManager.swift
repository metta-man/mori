import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

// MARK: - Focus Guard Manager
/// Manages app blocking until daily habits are completed.
/// Uses Apple's Screen Time API (FamilyControls + ManagedSettings).
@MainActor
class FocusGuardManager: ObservableObject {
    
    static let shared = FocusGuardManager()
    
    // MARK: - Published State
    @Published var isFocusGuardEnabled: Bool = false
    @Published var selectedApps: Set<ApplicationToken> = []
    @Published var selectedCategories: Set<ActivityCategoryToken> = []
    @Published var allHabitsCompleted: Bool = false
    @Published var shieldActive: Bool = false
    
    // MARK: - Private
    private let store = ManagedSettingsStore()
    private let userDefaults = UserDefaults.standard
    
    private let kFocusGuardEnabled = "focus_guard_enabled"
    private let kHasSelectedApps = "focus_guard_has_selected_apps"
    
    private init() {
        loadSettings()
    }
    
    // MARK: - Public API
    
    /// Called when habit completion state changes
    func updateShieldState(completedHabits: Int, totalHabits: Int) {
        let allDone = totalHabits > 0 && completedHabits >= totalHabits
        allHabitsCompleted = allDone
        
        guard isFocusGuardEnabled else {
            clearShield()
            return
        }
        
        if allDone {
            // All habits done → unlock apps
            clearShield()
        } else {
            // Habits remain → enforce shield
            applyShield()
        }
    }
    
    /// Toggle focus guard on/off
    func setFocusGuardEnabled(_ enabled: Bool) {
        isFocusGuardEnabled = enabled
        userDefaults.set(enabled, forKey: kFocusGuardEnabled)
        
        if !enabled {
            clearShield()
        }
    }
    
    /// Save the user's selected apps after FamilyActivityPicker
    func setSelectedApps(_ selection: FamilyActivitySelection) {
        selectedApps = selection.applicationTokens
        selectedCategories = selection.categoryTokens
        
        // Persist the selection
        do {
            let data = try JSONEncoder().encode(selection)
            userDefaults.set(data, forKey: "focus_guard_app_selection")
            userDefaults.set(true, forKey: kHasSelectedApps)
        } catch {
            print("Failed to save app selection: \(error)")
        }
    }
    
    var hasSelectedApps: Bool {
        userDefaults.bool(forKey: kHasSelectedApps)
    }
    
    /// Get count of blocked apps/categories
    var blockedCount: Int {
        selectedApps.count + selectedCategories.count
    }
    
    // MARK: - Shield Management
    
    private func applyShield() {
        guard isFocusGuardEnabled, !selectedApps.isEmpty || !selectedCategories.isEmpty else {
            return
        }
        
        // Apply app-level shield
        store.shield.applications = selectedApps
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(
            selectedCategories,
            except: Set<ApplicationToken>()
        )
        
        // Block notifications from shielded apps
        store.applications.blockedApplications = selectedApps
        
        shieldActive = true
        print("🛡️ Focus Guard: Shield ACTIVATED — \(blockedCount) items blocked")
    }
    
    private func clearShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.applications.blockedApplications = nil
        store.clearAllSettings()
        
        shieldActive = false
        print("✅ Focus Guard: Shield CLEARED — apps unlocked")
    }
    
    // MARK: - Persistence
    
    private func loadSettings() {
        isFocusGuardEnabled = userDefaults.bool(forKey: kFocusGuardEnabled)
        
        if let data = userDefaults.data(forKey: "focus_guard_app_selection") {
            do {
                let selection = try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
                selectedApps = selection.applicationTokens
                selectedCategories = selection.categoryTokens
            } catch {
                print("Failed to load app selection: \(error)")
            }
        }
    }
}
