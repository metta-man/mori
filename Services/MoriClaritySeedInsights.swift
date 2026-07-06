import Foundation

extension MoriClarityStore {
    func nourishedDomains(for date: Date = Date()) -> [LifeDomain: Int] {
        var scores = Dictionary(uniqueKeysWithValues: LifeDomain.allCases.map { ($0, 0) })
        let dateActions = actions(for: date)

        for action in dateActions {
            let weight = max(1, action.seeds)
            for domain in MoriPractice.domains(for: action) {
                scores[domain, default: 0] += weight
            }
        }

        if Calendar.current.isDateInToday(date),
           DailySparkStore.shared.todayEntry != nil,
           !dateActions.contains(where: { $0.kind == .dailySpark }) {
            scores[.mind, default: 0] += 1
            scores[.craft, default: 0] += 1
        }

        if Calendar.current.isDateInToday(date),
           HabitDataManager.shared.getTodayEntry() != nil,
           !dateActions.contains(where: MoriClarityStatsCalculator.isDailyCheckInAction) {
            scores[.body, default: 0] += 1
            scores[.rest, default: 0] += 1
        }

        return scores
    }

    func seedDomainSummaries(for date: Date = Date(), limitPerDomain: Int = 3) -> [MoriSeedDomainSummary] {
        let scores = nourishedDomains(for: date)
        let dateActions = actions(for: date)

        return LifeDomain.allCases.map { domain in
            MoriSeedDomainSummary(
                domain: domain,
                score: scores[domain, default: 0],
                recentSeeds: recentSeeds(in: dateActions, for: domain, limit: limitPerDomain)
            )
        }
    }

    func recentSeeds(for domain: LifeDomain? = nil, limit: Int = 8) -> [MoriMindfulAction] {
        let matchingActions = actions.filter { action in
            guard action.seeds > 0 else { return false }
            guard let domain else { return true }
            return MoriPractice.domains(for: action).contains(domain)
        }

        return Array(matchingActions.prefix(max(0, limit)))
    }

    func recentSeedsByDomain(limitPerDomain: Int = 3) -> [MoriSeedDomainSummary] {
        LifeDomain.allCases.map { domain in
            let recent = recentSeeds(for: domain, limit: limitPerDomain)
            let score = recent.reduce(0) { $0 + $1.seeds }
            return MoriSeedDomainSummary(domain: domain, score: score, recentSeeds: recent)
        }
    }

    func seedRecommendationReason(for practice: MoriPractice) -> String {
        let scores = nourishedDomains()
        let lowestDomain = LifeDomain.allCases.min { lhs, rhs in
            scores[lhs, default: 0] < scores[rhs, default: 0]
        }

        if let domain = lowestDomain, practice.domains.contains(domain) {
            return MoriL10n.string(
                "clarity.recommendation.lowest_domain",
                defaultValue: "%@ has had the least nourishment today.",
                arguments: [domain.title]
            )
        }

        if actions().isEmpty {
            return MoriL10n.string(
                "clarity.recommendation.first_seed",
                defaultValue: "A small first Seed makes the day easier to enter."
            )
        }

        return MoriL10n.string(
            "clarity.recommendation.balance_bloom",
            defaultValue: "This Seed balances today's Bloom without adding noise."
        )
    }

    func suggestedPracticeForToday(date: Date = Date()) -> MoriPractice {
        let scores = nourishedDomains()
        let total = scores.values.reduce(0, +)
        guard total > 0 else { return .dailyCheckIn }

        let lowestDomain = LifeDomain.allCases.min { lhs, rhs in
            scores[lhs, default: 0] < scores[rhs, default: 0]
        } ?? .rest

        let suggestion = MoriPractice.suggested(for: lowestDomain)
        guard shouldDeferReflectionSeeds(at: date),
              isReflectionSeed(suggestion)
        else {
            return suggestion
        }

        return nextNonReflectionSeed(for: lowestDomain) ?? .quietPause
    }

    private func recentSeeds(
        in sourceActions: [MoriMindfulAction],
        for domain: LifeDomain,
        limit: Int
    ) -> [MoriMindfulAction] {
        let matchingActions = sourceActions.filter { action in
            action.seeds > 0 && MoriPractice.domains(for: action).contains(domain)
        }

        return Array(matchingActions.prefix(max(0, limit)))
    }

    private func shouldDeferReflectionSeeds(at date: Date) -> Bool {
        Calendar.current.component(.hour, from: date) < 17
    }

    private func isReflectionSeed(_ practice: MoriPractice) -> Bool {
        practice.route == .dailyCheckIn || practice.route == .journal
    }

    private func nextNonReflectionSeed(for domain: LifeDomain) -> MoriPractice? {
        MoriPractice.suggestedSeeds(for: domain, limit: MoriPractice.practiceGarden.count)
            .first { !isReflectionSeed($0) }
    }
}
