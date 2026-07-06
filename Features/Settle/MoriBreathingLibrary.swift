import SwiftUI

enum MoriBreathingTechniqueID: String, CaseIterable, Identifiable, Codable {
    case longExhale = "Long Exhale (4-6)"
    case nadiShodhana = "Nadi Shodhana (4s in - 6s out)"
    case coherent5 = "Coherent (1min 5x)"
    case coherent55 = "Coherent (5.5s in - 5.5s out)"
    case coherent6 = "Coherent (1min 6x)"
    case coherent4 = "Coherent (1min 4x)"
    case coherent3 = "Coherent (1min 3x)"
    case box4 = "Box Breathing (4-4-4-4)"
    case box6 = "Box Breathing (6-6-6-6)"
    case box8 = "Box Breathing (8-8-8-8)"
    case box10 = "Box Breathing (10-10-10-10)"
    case fourSevenEight = "4-7-8 Breathing"
    case custom = "Custom Breathing"

    var id: String { rawValue }
}

enum MoriBreathingDifficulty: String, Codable, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var id: String { rawValue }

    var tint: Color {
        switch self {
        case .beginner: return MoriColors.botanicalMoss
        case .intermediate: return MoriColors.botanicalClay
        case .advanced: return Color(hex: "#B85C54")
        }
    }

    var stars: Int {
        switch self {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        }
    }

    var icon: MoriBitmapIcon {
        switch self {
        case .beginner:
            return .leaf
        case .intermediate:
            return .focus
        case .advanced:
            return .roots
        }
    }
}

struct MoriBreathPattern: Codable, Equatable {
    let inhale: Double
    let inhaleHold: Double?
    let exhale: Double
    let exhaleHold: Double?

    var totalCycleDuration: Double {
        inhale + (inhaleHold ?? 0) + exhale + (exhaleHold ?? 0)
    }

    var breathsPerMinute: Double {
        guard totalCycleDuration > 0 else { return 0 }
        return 60.0 / totalCycleDuration
    }

    var segments: [MoriBreathingCycleSegment] {
        MoriBreathingCycle.segments(
            inhale: max(0.1, inhale),
            inhaleHold: inhaleHold,
            exhale: max(0.1, exhale),
            exhaleHold: exhaleHold
        )
    }
}

struct MoriBreathingTechnique: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let shortDescription: String
    let longDescription: String
    let difficulty: MoriBreathingDifficulty
    let benefits: [String]
    let scienceExplanation: String
    let howToSteps: [String]
    let bestFor: [String]
    let breathPattern: MoriBreathPattern
    let category: String
    let iconName: String
    let gradientColors: [String]

    var icon: MoriBitmapIcon {
        .fromLegacySymbolName(iconName)
    }

    var techniqueID: MoriBreathingTechniqueID? {
        MoriBreathingTechniqueID(rawValue: id)
    }

    var durationDisplay: String {
        if id == MoriBreathingTechniqueID.custom.rawValue {
            return MoriL10n.display("Varies by settings")
        }
        return MoriL10n.string("breath.frequency.value", defaultValue: "%.1f breaths/min", arguments: [breathPattern.breathsPerMinute])
    }

    var patternDisplay: String {
        if id == MoriBreathingTechniqueID.custom.rawValue {
            return MoriL10n.display("Set in settings")
        }

        return Self.patternDisplay(for: breathPattern)
    }

    static func patternDisplay(for pattern: MoriBreathPattern) -> String {
        var parts: [String] = []
        parts.append(MoriL10n.string("breath.pattern.in", defaultValue: "%@ in", arguments: [formatSeconds(pattern.inhale)]))
        if let hold = pattern.inhaleHold, hold > 0 {
            parts.append(MoriL10n.string("breath.pattern.hold", defaultValue: "%@ hold", arguments: [formatSeconds(hold)]))
        }
        parts.append(MoriL10n.string("breath.pattern.out", defaultValue: "%@ out", arguments: [formatSeconds(pattern.exhale)]))
        if let hold = pattern.exhaleHold, hold > 0 {
            parts.append(MoriL10n.string("breath.pattern.hold", defaultValue: "%@ hold", arguments: [formatSeconds(hold)]))
        }
        return parts.joined(separator: ", ")
    }

    static func formatSeconds(_ seconds: Double) -> String {
        if seconds.rounded() == seconds {
            return String(format: "%.0fs", seconds)
        }
        return String(format: "%.1fs", seconds)
    }
}

enum MoriBreathingTechniqueRepository {
    static let techniques: [MoriBreathingTechnique] = [
        MoriBreathingTechnique(
            id: MoriBreathingTechniqueID.longExhale.rawValue,
            name: "Long Exhale (4-6)",
            shortDescription: "A simple longer-exhale reset before opening a feed",
            longDescription: "Long Exhale is a plain, accessible rhythm for quick state shifts: breathe in for 4 seconds, then breathe out for 6 seconds. It keeps the reset lightweight while gently biasing attention toward the exhale.",
            difficulty: .beginner,
            benefits: ["Creates a quick pause", "Supports calmer transitions", "Keeps the rhythm easy to follow", "Avoids breath holds", "Fits short resets"],
            scienceExplanation: "Longer exhales can make slow breathing feel more settling without adding breath retention. The 10-second cycle stays simple enough for short interruption moments.",
            howToSteps: ["Sit or stand comfortably", "Inhale gently through your nose for 4 seconds", "Exhale slowly for 6 seconds", "Keep the breath quiet and unforced", "Continue until the reset timer completes"],
            bestFor: ["Before-feed resets", "Short urges", "Beginner breathing", "Gentle calming", "Fast transitions"],
            breathPattern: MoriBreathPattern(inhale: 4, inhaleHold: nil, exhale: 6, exhaleHold: nil),
            category: "Reset",
            iconName: "leaf.arrow.circlepath",
            gradientColors: ["#687E5E", "#8FA77A", "#D8C690"]
        ),
        MoriBreathingTechnique(
            id: MoriBreathingTechniqueID.nadiShodhana.rawValue,
            name: "Nadi Shodhana (4-6)",
            shortDescription: "Alternate nostril breathing for balance",
            longDescription: "Nadi Shodhana, often called alternate nostril breathing, is a yogic pranayama reset where you breathe through one nostril at a time. This gentle 4-second inhale and 6-second exhale version supports calm focus without breath retention.",
            difficulty: .beginner,
            benefits: ["Helps relieve stress", "Supports calm concentration", "Encourages slower nasal breathing", "May support healthy blood pressure", "Builds steady breath awareness"],
            scienceExplanation: "Alternate nostril breathing has been studied as a way to influence autonomic regulation. The longer 6-second exhale gently biases the rhythm toward relaxation while keeping the reset approachable.",
            howToSteps: ["Sit upright and relax your shoulders", "Use your right thumb to close your right nostril", "Inhale through your left nostril for 4 seconds", "Close your left nostril and exhale through your right nostril for 6 seconds", "Inhale through your right nostril for 4 seconds, then exhale through your left for 6 seconds", "Continue alternating sides, keeping the breath smooth and quiet"],
            bestFor: ["Pre-meditation settling", "Stress resets", "Focused breathing reset", "Balancing energy", "Gentle daytime calm"],
            breathPattern: MoriBreathPattern(inhale: 4, inhaleHold: nil, exhale: 6, exhaleHold: nil),
            category: "Balance",
            iconName: "arrow.left.arrow.right",
            gradientColors: ["#0F766E", "#14B8A6", "#A3E635"]
        ),
        MoriBreathingTechnique(
            id: MoriBreathingTechniqueID.coherent5.rawValue,
            name: "Coherent Breathing (5-5)",
            shortDescription: "Classic resonant frequency breathing",
            longDescription: "The most researched coherent breathing pattern, breathing at exactly 5 breaths per minute. This rhythm helps many people settle into resonance between heart rate and breathing.",
            difficulty: .beginner,
            benefits: ["Maximizes heart rate variability", "Deeply calming effect", "Improves emotional regulation", "Reduces blood pressure", "Enhances mental clarity"],
            scienceExplanation: "Five breaths per minute is close to the resonant frequency for many adults, creating larger oscillations in heart rate variability and supporting autonomic balance.",
            howToSteps: ["Sit comfortably with a straight spine", "Inhale gently for 5 seconds", "Exhale smoothly for 5 seconds", "Maintain a relaxed, natural rhythm", "Reset for 10-20 minutes daily"],
            bestFor: ["Stress management", "Anxiety reduction", "Improving HRV", "Daily meditation reset", "Emotional balance"],
            breathPattern: MoriBreathPattern(inhale: 5, inhaleHold: nil, exhale: 5, exhaleHold: nil),
            category: "Coherent",
            iconName: "wind",
            gradientColors: ["#3B82F6", "#6366F1", "#8B5CF6"]
        ),
        MoriBreathingTechnique(
            id: MoriBreathingTechniqueID.coherent55.rawValue,
            name: "Coherent Breathing (5.5-5.5)",
            shortDescription: "Gentle resonance at a smooth pace",
            longDescription: "A slightly slower coherent breathing pattern with equal 5.5-second inhales and exhales. It sits near the commonly used resonant breathing range and can feel softer than a strict 5-second rhythm.",
            difficulty: .beginner,
            benefits: ["Supports steady relaxation", "Encourages smooth, even breathing", "Helps settle stress responses", "Promotes heart-breath synchronization", "Good for daily nervous system reset"],
            scienceExplanation: "Coherent breathing near 5 to 6 breaths per minute is often used to support heart rate variability and autonomic balance. The 11-second cycle gives roughly 5.5 breaths per minute.",
            howToSteps: ["Sit comfortably and soften your shoulders", "Inhale gently for 5.5 seconds", "Exhale smoothly for 5.5 seconds", "Keep the breath quiet and continuous", "Return to natural breathing if strain appears"],
            bestFor: ["Daily regulation", "Midday reset", "Anxiety support", "Resonance breathing reset", "Gentle focus"],
            breathPattern: MoriBreathPattern(inhale: 5.5, inhaleHold: nil, exhale: 5.5, exhaleHold: nil),
            category: "Coherent",
            iconName: "wind",
            gradientColors: ["#2563EB", "#0EA5E9", "#14B8A6"]
        ),
        MoriBreathingTechnique(
            id: MoriBreathingTechniqueID.coherent6.rawValue,
            name: "Coherent Breathing (6-6)",
            shortDescription: "Balanced calm for daily reset",
            longDescription: "Coherent breathing is a balanced breathing technique that helps synchronize heart rate and breath. It acts like a reset button for the nervous system.",
            difficulty: .beginner,
            benefits: ["Reduces stress and anxiety", "Improves heart rate variability", "Promotes emotional balance", "Enhances focus and clarity", "Lowers blood pressure"],
            scienceExplanation: "Research around slow breathing suggests 5-6 breaths per minute can optimize heart rate variability and support parasympathetic activation.",
            howToSteps: ["Find a comfortable seated position", "Breathe in slowly through your nose for 6 seconds", "Breathe out slowly through your nose for 6 seconds", "Continue for 5-10 minutes", "Focus on smooth, effortless breathing"],
            bestFor: ["Daily mindfulness reset", "Managing anxiety", "General wellness", "First-time users", "Improving sleep quality"],
            breathPattern: MoriBreathPattern(inhale: 6, inhaleHold: nil, exhale: 6, exhaleHold: nil),
            category: "Coherent",
            iconName: "wind",
            gradientColors: ["#4F46E5", "#7C3AED", "#A855F7"]
        ),
        MoriBreathingTechnique(
            id: MoriBreathingTechniqueID.coherent4.rawValue,
            name: "Coherent Breathing (7.5-7.5)",
            shortDescription: "Slower, deeper coherent breathing",
            longDescription: "A slower variation of coherent breathing at 4 breaths per minute. This deeper pattern is suited to a more meditative, calming experience.",
            difficulty: .intermediate,
            benefits: ["Very deep relaxation", "Enhanced meditation depth", "Improved lung capacity", "Profound stress relief", "Better sleep preparation"],
            scienceExplanation: "Slower breathing rates increase tidal volume and can deepen parasympathetic activation. This pattern is especially useful for an evening reset.",
            howToSteps: ["Find a quiet, comfortable space", "Inhale deeply for 7.5 seconds", "Exhale fully for 7.5 seconds", "Allow breathing to be effortless", "Reset for 10-15 minutes"],
            bestFor: ["Evening relaxation", "Sleep preparation", "Deep meditation", "Stress recovery", "Experienced practitioners"],
            breathPattern: MoriBreathPattern(inhale: 7.5, inhaleHold: nil, exhale: 7.5, exhaleHold: nil),
            category: "Coherent",
            iconName: "wind",
            gradientColors: ["#6366F1", "#8B5CF6", "#A855F7"]
        ),
        MoriBreathingTechnique(
            id: MoriBreathingTechniqueID.coherent3.rawValue,
            name: "Coherent Breathing (10-10)",
            shortDescription: "Very slow, meditative breathing",
            longDescription: "The slowest coherent breathing pattern at 3 breaths per minute. This advanced technique takes time and can create a very deep meditative state.",
            difficulty: .advanced,
            benefits: ["Deepest relaxation state", "Enhanced meditative awareness", "Maximum lung expansion", "Profound nervous system reset", "Improved respiratory efficiency"],
            scienceExplanation: "Very slow breathing can strongly emphasize respiratory sinus arrhythmia and parasympathetic dominance, but it should remain comfortable and unforced.",
            howToSteps: ["Sit in a comfortable meditation posture", "Inhale very slowly for 10 seconds", "Exhale completely for 10 seconds", "Maintain smooth, continuous breath", "Begin with 5-10 minutes"],
            bestFor: ["Advanced meditation", "Deep relaxation", "Experienced users", "Breath awareness training", "Spiritual reset"],
            breathPattern: MoriBreathPattern(inhale: 10, inhaleHold: nil, exhale: 10, exhaleHold: nil),
            category: "Coherent",
            iconName: "wind",
            gradientColors: ["#8B5CF6", "#A855F7", "#C084FC"]
        ),
        MoriBreathingTechnique(
            id: MoriBreathingTechniqueID.box4.rawValue,
            name: "Box Breathing (4-4-4-4)",
            shortDescription: "Mental clarity and focus",
            longDescription: "Box breathing, also known as square breathing, is used by athletes and high-pressure teams to improve concentration. Equal timing across all four phases creates a balanced, grounding rhythm.",
            difficulty: .intermediate,
            benefits: ["Heightens performance and concentration", "Relieves stress quickly", "Improves focus and mental clarity", "Regulates nervous system", "Enhances emotional control"],
            scienceExplanation: "The breath holds in box breathing can support calm alertness, increase CO2 tolerance, and improve perceived control under pressure.",
            howToSteps: ["Sit upright with good posture", "Inhale through your nose for 4 seconds", "Hold your breath for 4 seconds", "Exhale through your nose for 4 seconds", "Hold empty for 4 seconds, then repeat"],
            bestFor: ["Pre-performance preparation", "Stress management", "Focus enhancement", "Anxiety relief", "Mental clarity"],
            breathPattern: MoriBreathPattern(inhale: 4, inhaleHold: 4, exhale: 4, exhaleHold: 4),
            category: "Box",
            iconName: "square",
            gradientColors: ["#EC4899", "#F43F5E", "#FB7185"]
        ),
        MoriBreathingTechnique(
            id: MoriBreathingTechniqueID.box6.rawValue,
            name: "Box Breathing (6-6-6-6)",
            shortDescription: "Extended box for deeper calm",
            longDescription: "A longer variation of box breathing that keeps the balanced square pattern while offering deeper relaxation for people comfortable with breath retention.",
            difficulty: .intermediate,
            benefits: ["Deeper relaxation than 4-4-4-4", "Enhanced CO2 tolerance", "Improved breath control", "Greater mental stillness", "Stronger parasympathetic activation"],
            scienceExplanation: "Longer breath holds increase CO2 levels and train respiratory control. This can feel deeply settling when done without strain.",
            howToSteps: ["Establish a comfortable seated position", "Inhale smoothly for 6 seconds", "Hold comfortably for 6 seconds", "Exhale steadily for 6 seconds", "Hold empty for 6 seconds, then continue"],
            bestFor: ["Intermediate practitioners", "Deeper meditation", "Breath control training", "Stress resilience", "Performance enhancement"],
            breathPattern: MoriBreathPattern(inhale: 6, inhaleHold: 6, exhale: 6, exhaleHold: 6),
            category: "Box",
            iconName: "square",
            gradientColors: ["#F43F5E", "#FB7185", "#FDA4AF"]
        ),
        MoriBreathingTechnique(
            id: MoriBreathingTechniqueID.box8.rawValue,
            name: "Box Breathing (8-8-8-8)",
            shortDescription: "Advanced box breathing",
            longDescription: "An advanced box breathing pattern with extended holds. It requires good breath control and provides a strong calming effect.",
            difficulty: .advanced,
            benefits: ["Maximum CO2 tolerance", "Deep meditative states", "Advanced breath control", "Profound nervous system regulation", "Enhanced respiratory capacity"],
            scienceExplanation: "Eight-second holds significantly increase the demand of the pattern. Use it only when shorter box patterns feel easy and stable.",
            howToSteps: ["Master shorter patterns first", "Inhale deeply for 8 seconds", "Hold with ease for 8 seconds", "Exhale completely for 8 seconds", "Hold empty comfortably for 8 seconds"],
            bestFor: ["Advanced practitioners", "Breath retention training", "Deep meditation", "Performance optimization", "Stress mastery"],
            breathPattern: MoriBreathPattern(inhale: 8, inhaleHold: 8, exhale: 8, exhaleHold: 8),
            category: "Box",
            iconName: "square",
            gradientColors: ["#FB7185", "#FDA4AF", "#FECDD3"]
        ),
        MoriBreathingTechnique(
            id: MoriBreathingTechniqueID.box10.rawValue,
            name: "Box Breathing (10-10-10-10)",
            shortDescription: "Expert-level box breathing",
            longDescription: "The most advanced box breathing pattern in the library, with 10-second phases. It is best reserved for experienced practitioners.",
            difficulty: .advanced,
            benefits: ["Mastery-level breath control", "Deepest parasympathetic activation", "Maximum respiratory efficiency", "Profound mental stillness", "Peak performance states"],
            scienceExplanation: "Ten-second breath holds represent advanced respiratory control. The pattern should feel steady, not forced.",
            howToSteps: ["Only attempt after mastering shorter patterns", "Inhale fully and smoothly for 10 seconds", "Hold with complete ease for 10 seconds", "Exhale slowly and completely for 10 seconds", "Hold empty without strain for 10 seconds"],
            bestFor: ["Expert practitioners", "Elite performance training", "Advanced meditation", "Breath mastery", "Peak states"],
            breathPattern: MoriBreathPattern(inhale: 10, inhaleHold: 10, exhale: 10, exhaleHold: 10),
            category: "Box",
            iconName: "square",
            gradientColors: ["#FDA4AF", "#FECDD3", "#FFE4E6"]
        ),
        MoriBreathingTechnique(
            id: MoriBreathingTechniqueID.fourSevenEight.rawValue,
            name: "4-7-8 Breathing",
            shortDescription: "Sleep and deep relaxation",
            longDescription: "Popularized by Dr. Andrew Weil, 4-7-8 breathing is a powerful pattern for evening downshifting. The long exhale and hold emphasize relaxation.",
            difficulty: .intermediate,
            benefits: ["Promotes deep relaxation", "Improves sleep quality", "Reduces anxiety quickly", "Lowers blood pressure", "Calms racing thoughts"],
            scienceExplanation: "The 4-7-8 pattern emphasizes a long exhale, which stimulates vagal tone and supports parasympathetic activation. The hold raises CO2 slightly and can amplify the relaxation response.",
            howToSteps: ["Place the tip of your tongue behind your upper front teeth", "Exhale completely through your mouth", "Inhale quietly through your nose for 4 seconds", "Hold your breath for 7 seconds", "Exhale completely through your mouth for 8 seconds"],
            bestFor: ["Falling asleep", "Evening relaxation", "Anxiety relief", "Stress reduction", "Calming racing thoughts"],
            breathPattern: MoriBreathPattern(inhale: 4, inhaleHold: 7, exhale: 8, exhaleHold: nil),
            category: "Relaxation",
            iconName: "moon.stars",
            gradientColors: ["#F59E0B", "#F97316", "#FB923C"]
        ),
        MoriBreathingTechnique(
            id: MoriBreathingTechniqueID.custom.rawValue,
            name: "Custom Breathing",
            shortDescription: "Start with 4s in, 6s out, then tune it",
            longDescription: "Custom Breathing starts with a gentle 4-second inhale and 6-second exhale because that 10-second cycle is easy to follow and gives the exhale a little extra time. From there, you can choose inhale, optional hold, and exhale durations.",
            difficulty: .beginner,
            benefits: ["Personalizes the breathing rhythm", "Supports gradual breath training", "Allows longer calming exhales", "Can include or skip breath holds", "Adapts to different energy levels"],
            scienceExplanation: "Breathing rate, inhale-to-exhale ratio, and breath holds all change how demanding or calming a pattern feels. Keep every setting comfortable and reduce any duration that feels strained.",
            howToSteps: ["Open Breathing Settings", "Choose Custom Breathing", "Set your breathe-in duration", "Turn on Hold if you want a pause after the inhale", "Set your breathe-out duration", "Watch the pattern and frequency update", "Start gently and reduce any strained setting"],
            bestFor: ["Personal reset", "Gentle experimentation", "Long-exhale calming rhythms", "Breath awareness training", "Adapting day by day"],
            breathPattern: MoriBreathPattern(inhale: 4, inhaleHold: nil, exhale: 6, exhaleHold: nil),
            category: "Custom",
            iconName: "slider.horizontal.3",
            gradientColors: ["#64748B", "#22C55E", "#38BDF8"]
        )
    ]

    static func getTechnique(id: String) -> MoriBreathingTechnique? {
        techniques.first { $0.id == id }
    }

    static func search(query: String, mood: MoriBreathMood = .all) -> [MoriBreathingTechnique] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return techniques
            .filter { mood.matches($0) }
            .filter { technique in
                guard !trimmed.isEmpty else { return true }
                let haystack = ([technique.name, technique.shortDescription, technique.longDescription, technique.category] + technique.benefits + technique.bestFor)
                    .joined(separator: " ")
                    .lowercased()
                return haystack.contains(trimmed.lowercased())
            }
            .sorted { displayOrder(for: $0.id) < displayOrder(for: $1.id) }
    }

    private static func displayOrder(for id: String) -> Int {
        MoriBreathingTechniqueID.allCases.firstIndex { $0.rawValue == id } ?? Int.max
    }
}

enum MoriBreathMood: String, CaseIterable, Identifiable {
    case all = "All"
    case calm = "Calm"
    case sleep = "Sleep"
    case focus = "Focus"
    case anxiety = "Anxiety"
    case beginner = "Beginner"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .all: return "sparkles"
        case .calm: return "leaf.fill"
        case .sleep: return "moon.stars.fill"
        case .focus: return "scope"
        case .anxiety: return "heart.fill"
        case .beginner: return "figure.wave"
        }
    }

    var icon: MoriBitmapIcon {
        switch self {
        case .all:
            return .pulse
        case .calm:
            return .leaf
        case .sleep:
            return .quiet
        case .focus:
            return .focus
        case .anxiety:
            return .heart
        case .beginner:
            return .breathe
        }
    }

    func matches(_ technique: MoriBreathingTechnique) -> Bool {
        switch self {
        case .all:
            return true
        case .calm:
            return containsAny(technique, terms: ["calm", "relax", "stress", "balance", "regulation", "daily"])
        case .sleep:
            return containsAny(technique, terms: ["sleep", "evening", "night", "deep relaxation"])
        case .focus:
            return containsAny(technique, terms: ["focus", "clarity", "concentration", "performance", "alert"])
        case .anxiety:
            return containsAny(technique, terms: ["anxiety", "stress", "racing thoughts", "nervous system"])
        case .beginner:
            return technique.difficulty == .beginner
        }
    }

    private func containsAny(_ technique: MoriBreathingTechnique, terms: [String]) -> Bool {
        let searchable = ([technique.name, technique.shortDescription, technique.longDescription, technique.category] + technique.benefits + technique.bestFor)
            .joined(separator: " ")
            .lowercased()
        return terms.contains { searchable.contains($0) }
    }
}
