// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "Stash",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Stash", targets: ["Stash"]), .library(name: "StashCore", targets: ["StashCore"])],
    targets: [
        .target(name: "StashCore"),
        .executableTarget(name: "Stash", dependencies: ["StashCore"]),
        .executableTarget(name: "StashChecks", dependencies: ["StashCore"], path: "Tests/StashCoreTests")
    ],
    swiftLanguageModes: [.v5]
)
