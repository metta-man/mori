// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MoriScheduledProtectionPrototype",
    products: [.library(name: "MoriProtection", targets: ["MoriProtection"])],
    targets: [
        .target(name: "MoriProtection"),
        .testTarget(name: "MoriProtectionTests", dependencies: ["MoriProtection"])
    ]
)
