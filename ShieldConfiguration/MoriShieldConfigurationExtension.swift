import ManagedSettings
import ManagedSettingsUI
import UIKit

final class MoriShieldConfigurationExtension: ShieldConfigurationDataSource {
    private let shieldStateStore = AttentionShieldStateStore()

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        moriConfiguration
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        moriConfiguration
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        moriConfiguration
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        moriConfiguration
    }

    private var moriConfiguration: ShieldConfiguration {
        let copy = shieldCopy
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialLight,
            backgroundColor: MoriShieldPalette.paper,
            icon: UIImage(named: copy.iconAssetName),
            title: ShieldConfiguration.Label(
                text: MoriL10n.display(copy.title),
                color: MoriShieldPalette.canopy
            ),
            subtitle: ShieldConfiguration.Label(
                text: MoriL10n.display(copy.subtitle),
                color: MoriShieldPalette.muted
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: MoriL10n.display(copy.primaryButtonTitle),
                color: MoriShieldPalette.surface
            ),
            primaryButtonBackgroundColor: MoriShieldPalette.canopy,
            secondaryButtonLabel: copy.secondaryButtonTitle.map {
                ShieldConfiguration.Label(
                    text: MoriL10n.display($0),
                    color: MoriShieldPalette.canopy
                )
            }
        )
    }

    private var shieldCopy: MoriShieldCopy {
        guard let feature = shieldStateStore.loadCurrentFeature() else {
            return .practice
        }

        switch feature {
        case .morningGate:
            return .morning
        case .beforeFeed:
            return .beforeFeed
        default:
            return .practice
        }
    }
}

private struct MoriShieldCopy {
    let iconAssetName: String
    let title: String
    let subtitle: String
    let primaryButtonTitle: String
    let secondaryButtonTitle: String?

    static let beforeFeed = MoriShieldCopy(
        iconAssetName: "moriIconBeforeFeedReset",
        title: "Reset before the feed",
        subtitle: "Prepare reset, then open Mori. This app will close and Mori will be ready when you arrive.",
        primaryButtonTitle: "Prepare reset",
        secondaryButtonTitle: "Not now"
    )

    static let morning = MoriShieldCopy(
        iconAssetName: "moriIconBreathe",
        title: "Morning App Limit active",
        subtitle: "Open Mori and complete Morning Reset, or wait for the morning gate to end.",
        primaryButtonTitle: "Close app",
        secondaryButtonTitle: "Prepare Morning Reset"
    )

    static let practice = MoriShieldCopy(
        iconAssetName: "moriIconLockShield",
        title: "Reset App Limit active",
        subtitle: "Return to Mori to finish the app-limited session.",
        primaryButtonTitle: "Close app",
        secondaryButtonTitle: nil
    )
}

private enum MoriShieldPalette {
    static let paper = UIColor(red: 251.0 / 255.0, green: 247.0 / 255.0, blue: 239.0 / 255.0, alpha: 1.0)
    static let surface = UIColor(red: 255.0 / 255.0, green: 253.0 / 255.0, blue: 248.0 / 255.0, alpha: 1.0)
    static let canopy = UIColor(red: 20.0 / 255.0, green: 57.0 / 255.0, blue: 47.0 / 255.0, alpha: 1.0)
    static let muted = UIColor(red: 95.0 / 255.0, green: 109.0 / 255.0, blue: 100.0 / 255.0, alpha: 1.0)
}
