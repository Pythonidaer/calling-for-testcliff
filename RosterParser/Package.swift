// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RosterParser",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "RosterParser", targets: ["RosterParser"]),
    ],
    targets: [
        .target(name: "RosterParser"),
        .testTarget(name: "RosterParserTests", dependencies: ["RosterParser"]),
    ]
)
