import Foundation
import UIKit

@MainActor
struct MoriSystemURLOpener {
    static let shared = MoriSystemURLOpener()

    func open(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
