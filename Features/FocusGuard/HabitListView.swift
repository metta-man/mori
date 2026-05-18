import SwiftUI

// MARK: - Habit List View
/// Enhanced habit tracker with named habits and Focus Guard integration
struct HabitListView: View {
    @StateObject private var habitManager = HabitListManager.shared
    @StateObject private var focusGuard = FocusGuardManager.shared
    @State private var showAddHabit = false
    @State private var newHabitName = ""
    @State private var newHabitIcon = "circle"
    @State private var showFocusGuard = false
    
    // Icon picker options
    private let habitIcons = [
        "figure.run", "book.fill", "brain.head.profile",
        "drop.fill", "leaf.fill", "sunrise.fill",
        "moon.fill", "heart.fill", "dumbbell.fill",
        "pencil", "music.note", "person.fill",
        "bed.double.fill", "apple.logo", "star.fill"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Focus Guard Status Banner (if enabled)
                    if focusGuard.isFocusGuardEnabled {
                        focusGuardBanner
                    }
                    
                    // Progress Ring
                    progressSection
                    
                    // Habits List
                    habitsSection
                    
                    // Add Habit Button
                    addHabitButton
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
            .background(MoriColors.background.ignoresSafeArea())
            .navigationTitle("Daily Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFocusGuard = true
                    } label: {
                        Image(systemName: focusGuard.isFocusGuardEnabled ? "shield.fill" : "shield")
                            .foregroundColor(focusGuard.isFocusGuardEnabled ? MoriColors.accentAmber : MoriColors.secondary)
                    }
                }
            }
            .sheet(isPresented: $showAddHabit) {
                addHabitSheet
            }
            .sheet(isPresented: $showFocusGuard) {
                FocusGuardView()
            }
            .onAppear {
                habitManager.resetDaily()
            }
        }
    }
    
    // MARK: - Focus Guard Banner
    private var focusGuardBanner: some View {
        Button {
            showFocusGuard = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: focusGuard.shieldActive ? "shield.fill" : "lock.open")
                    .font(.system(size: 18))
                    .foregroundColor(focusGuard.shieldActive ? .white : Color(hex: "#788c5d"))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(focusGuard.shieldActive ? "Apps Locked" : "Apps Unlocked")
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundColor(focusGuard.shieldActive ? .white : Color(hex: "#788c5d"))
                    
                    Text(focusGuard.shieldActive
                         ? "\(habitManager.completedCount)/\(habitManager.totalHabits) habits done"
                         : "All habits complete — enjoy!"
                    )
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(focusGuard.shieldActive ? .white.opacity(0.8) : MoriColors.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(focusGuard.shieldActive ? .white.opacity(0.6) : MoriColors.secondary)
            }
            .padding(16)
            .background(focusGuard.shieldActive ? MoriColors.primary : Color(hex: "#F0F5EB"))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(MoriColors.warmGray.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: habitManager.progressFraction)
                    .stroke(
                        habitManager.allCompleted ? Color(hex: "#788c5d") : MoriColors.accentAmber,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: habitManager.progressFraction)
                
                // Center text
                VStack(spacing: 4) {
                    Text("\(habitManager.completedCount)")
                        .font(.custom("CormorantGaramond-SemiBold", size: 36))
                        .foregroundColor(MoriColors.text)
                    
                    Text("of \(habitManager.totalHabits)")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(MoriColors.secondary)
                }
            }
            
            if habitManager.allCompleted && habitManager.totalHabits > 0 {
                Text("All habits complete! 🎉")
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(Color(hex: "#788c5d"))
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Habits Section
    private var habitsSection: some View {
        VStack(spacing: 12) {
            if habitManager.habits.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "list.bullet.circle")
                        .font(.system(size: 40))
                        .foregroundColor(MoriColors.warmGray)
                    
                    Text("No habits yet")
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(MoriColors.secondary)
                    
                    Text("Add habits to start building your daily routine.\nComplete them to unlock your apps!")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(MoriColors.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 32)
            } else {
                ForEach(habitManager.habits) { habit in
                    HabitRow(
                        habit: habit,
                        isCompleted: habitManager.isHabitCompleted(habit),
                        onToggle: { habitManager.toggleHabit(habit) }
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
            }
        }
    }
    
    // MARK: - Add Habit Button
    private var addHabitButton: some View {
        Button {
            showAddHabit = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                
                Text("Add Habit")
                    .font(.custom("Poppins-Medium", size: 14))
            }
            .foregroundColor(MoriColors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(MoriColors.primary.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Add Habit Sheet
    private var addHabitSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose an icon")
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(MoriColors.text)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(habitIcons, id: \.self) { icon in
                            Button {
                                newHabitIcon = icon
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(newHabitIcon == icon ? MoriColors.primary : MoriColors.warmGray.opacity(0.3))
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(newHabitIcon == icon ? .white : MoriColors.secondary)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Habit name")
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(MoriColors.text)
                    
                    TextField("e.g., Meditate 10 minutes", text: $newHabitName)
                        .font(.custom("Poppins-Regular", size: 14))
                        .padding(16)
                        .background(MoriColors.warmGray.opacity(0.2))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                
                // Suggestions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick add")
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(MoriColors.secondary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(["Meditate", "Exercise", "Read", "Journal", "No phone 1hr", "Drink water", "Walk outside", "Gratitude"], id: \.self) { suggestion in
                            Button {
                                newHabitName = suggestion
                            } label: {
                                Text(suggestion)
                                    .font(.custom("Poppins-Regular", size: 12))
                                    .foregroundColor(MoriColors.secondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.white)
                                    .cornerRadius(20)
                                    .overlay(
                                        Capsule().stroke(MoriColors.warmGray.opacity(0.5), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showAddHabit = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        guard !newHabitName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        habitManager.addHabit(name: newHabitName, icon: newHabitIcon)
                        newHabitName = ""
                        newHabitIcon = "circle"
                        showAddHabit = false
                    }
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .disabled(newHabitName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Habit Row
struct HabitRow: View {
    let habit: DailyHabit
    let isCompleted: Bool
    let onToggle: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
            
            onToggle()
        }) {
            HStack(spacing: 16) {
                // Check circle
                ZStack {
                    Circle()
                        .stroke(isCompleted ? Color(hex: "#788c5d") : MoriColors.warmGray, lineWidth: 2)
                        .frame(width: 32, height: 32)
                    
                    if isCompleted {
                        Circle()
                            .fill(Color(hex: "#788c5d"))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                
                // Icon
                Image(systemName: habit.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isCompleted ? MoriColors.secondary : MoriColors.text)
                    .frame(width: 24)
                
                // Name
                Text(habit.name)
                    .font(.custom("Poppins-Medium", size: 15))
                    .foregroundColor(isCompleted ? MoriColors.secondary : MoriColors.text)
                    .strikethrough(isCompleted)
                
                Spacer()
                
                // Completed time
                if isCompleted {
                    Text("✓")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#788c5d"))
                }
            }
            .padding(16)
            .background(isCompleted ? MoriColors.warmGray.opacity(0.2) : Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(isCompleted ? 0 : 0.05), radius: 4, x: 0, y: 2)
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
    }
}

// MARK: - Flow Layout Helper
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        
        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

#Preview {
    HabitListView()
}
