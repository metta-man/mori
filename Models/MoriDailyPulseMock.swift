import Foundation

extension MoriDailyPulse {
    static func mock(
        topics: [String] = MoriLocalePreference.load().defaultPulseTopics,
        date: Date = Date()
    ) -> MoriDailyPulse {
        let activeTopics = Array((topics.isEmpty ? MoriLocalePreference.load().defaultPulseTopics : topics).prefix(5))
        let topicPulses = activeTopics.map { topic in
            MoriTopicPulse(
                topic: topic,
                cards: [
                    MoriPulseCard(
                        kind: .worthKnowing,
                        headline: MoriL10n.string(
                            "pulse.mock.worth_knowing.headline",
                            defaultValue: "%@: choose one useful signal",
                            arguments: [topic]
                        ),
                        body: MoriL10n.string(
                            "pulse.mock.worth_knowing.body",
                            defaultValue: "The useful signal today is the update that changes a real decision. Let Mori hold the rest outside your day so this topic stays a lens, not a feed."
                        ),
                        actionLabel: MoriL10n.string("pulse.action.mark_useful", defaultValue: "Mark useful"),
                        followUpPrompts: [
                            MoriL10n.string("pulse.prompt.what_matters", defaultValue: "What matters most here?"),
                            MoriL10n.string("pulse.prompt.next", defaultValue: "What should I do next?")
                        ]
                    ),
                    MoriPulseCard(
                        kind: .worthIgnoring,
                        headline: MoriL10n.string(
                            "pulse.mock.worth_ignoring.headline",
                            defaultValue: "%@: repeated commentary can wait",
                            arguments: [topic]
                        ),
                        body: MoriL10n.string(
                            "pulse.mock.worth_ignoring.body",
                            defaultValue: "Skip loops that turn ordinary updates into another reason to check. If it does not change your next action, it can remain outside the room for now."
                        ),
                        actionLabel: MoriL10n.string("pulse.action.let_pass", defaultValue: "Let it pass"),
                        followUpPrompts: [
                            MoriL10n.string("pulse.prompt.why_wait", defaultValue: "Why can this wait?"),
                            MoriL10n.string("pulse.prompt.ignore", defaultValue: "What is worth ignoring?")
                        ]
                    ),
                    MoriPulseCard(
                        kind: .attentionTrap,
                        headline: MoriL10n.string(
                            "pulse.mock.attention_trap.headline",
                            defaultValue: "%@: the sticky part is the refresh",
                            arguments: [topic]
                        ),
                        body: MoriL10n.string(
                            "pulse.mock.attention_trap.body",
                            defaultValue: "The next refresh may not answer the real need. If the urge is boredom, tension, or avoidance, name that before opening another source."
                        ),
                        actionLabel: MoriL10n.string("pulse.action.name_trap", defaultValue: "Name trap"),
                        followUpPrompts: [
                            MoriL10n.string("pulse.prompt.trap", defaultValue: "What is the trap?"),
                            MoriL10n.string("pulse.prompt.step_away", defaultValue: "How do I step away?")
                        ]
                    )
                ]
            )
        }

        let sharedCards = [
            MoriPulseCard(
                kind: .resetAction,
                headline: MoriL10n.string("pulse.mock.reset.headline", defaultValue: "Start one reset"),
                body: MoriL10n.string(
                    "pulse.mock.reset.body",
                    defaultValue: "Take one minute of breathing, write a quiet note, or step outside before returning to the day."
                ),
                actionLabel: MoriL10n.string("pulse.action.choose_practice", defaultValue: "Choose practice"),
                followUpPrompts: [
                    MoriL10n.string("pulse.prompt.practice", defaultValue: "Which reset fits now?"),
                    MoriL10n.string("pulse.prompt.smaller", defaultValue: "Make this smaller")
                ]
            ),
            MoriPulseCard(
                kind: .reclaimedTime,
                headline: MoriL10n.string("pulse.mock.reclaimed.headline", defaultValue: "About 28 minutes reclaimed"),
                body: MoriL10n.string(
                    "pulse.mock.reclaimed.body",
                    defaultValue: "Reading the Pulse instead of scanning feeds keeps the signal and leaves the afternoon softer."
                ),
                minutes: 28,
                followUpPrompts: [
                    MoriL10n.string("pulse.prompt.protect_time", defaultValue: "How do I protect it?"),
                    MoriL10n.string("pulse.prompt.time_source", defaultValue: "Where did this time come from?")
                ]
            )
        ]

        return MoriDailyPulse(
            dateKey: MoriDateKey.value(for: date),
            generatedAt: date,
            topics: activeTopics,
            topicPulses: topicPulses,
            sharedCards: sharedCards,
            reclaimedMinutes: 28,
            isMock: true
        )
    }
}
