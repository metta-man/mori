enum MoriBeforeFeedShieldRecoveryPolicy {
    static func shouldRelease(
        isInOpenWindow: Bool,
        currentFeature: MoriScreenTimeFeature?
    ) -> Bool {
        isInOpenWindow && (currentFeature == nil || currentFeature == .beforeFeed)
    }
}
