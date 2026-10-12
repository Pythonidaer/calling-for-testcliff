// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Hangman",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "Hangman", targets: ["Hangman"]),
    ],
    targets: [
        .target(name: "Hangman"),
        .testTarget(name: "HangmanTests", dependencies: ["Hangman"]),
    ]
)
