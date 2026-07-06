import Foundation
import FamilyControls

struct AttentionShieldDisplayNameResolver {
    func immediateDisplayNames(
        for selection: FamilyActivitySelection,
        authorizationStatus: AuthorizationStatus
    ) -> [String] {
        guard AttentionShieldAuthorizationPolicy.canDisplaySelectionNames(for: authorizationStatus) else { return [] }

        var names: [String] = []
        names.append(contentsOf: selection.applications.compactMap(\.localizedDisplayName))
        names.append(contentsOf: selection.categories.compactMap(\.localizedDisplayName))
        names.append(contentsOf: selection.webDomains.compactMap(\.domain))
        return normalizedDisplayNames(names)
    }

    func displayNames(
        for selection: FamilyActivitySelection,
        authorizationStatus: AuthorizationStatus
    ) async -> [String] {
        guard AttentionShieldAuthorizationPolicy.canDisplaySelectionNames(for: authorizationStatus) else { return [] }

        var names = immediateDisplayNames(
            for: selection,
            authorizationStatus: authorizationStatus
        )

        if #available(iOS 26.4, *),
           AttentionShieldAuthorizationPolicy.hasFamilyActivityDataAccess(for: authorizationStatus) {
            do {
                let applications = try await FamilyActivityData.shared.installedApplications
                let categories = try await FamilyActivityData.shared.activityCategories
                let domains = try await FamilyActivityData.shared.visitedWebDomains

                names.append(contentsOf: applications.compactMap { application in
                    guard let token = application.token,
                          selection.applicationTokens.contains(token)
                    else {
                        return nil
                    }
                    return application.localizedDisplayName ?? application.bundleIdentifier
                })

                names.append(contentsOf: categories.compactMap { category in
                    guard let token = category.token,
                          selection.categoryTokens.contains(token)
                    else {
                        return nil
                    }
                    return category.localizedDisplayName
                })

                names.append(contentsOf: domains.compactMap { domain in
                    guard let token = domain.token,
                          selection.webDomainTokens.contains(token)
                    else {
                        return nil
                    }
                    return domain.domain
                })
            } catch {
                // Opaque counts remain available outside supported data-access regions.
            }
        }

        return normalizedDisplayNames(names)
    }

    private func normalizedDisplayNames(_ names: [String]) -> [String] {
        var seen = Set<String>()
        return names
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0).inserted }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}
