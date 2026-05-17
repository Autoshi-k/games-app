// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftGamesApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SwiftGamesApp", targets: ["GamesApp"])
    ],
    targets: [
        .executableTarget(
            name: "GamesApp"
        )
    ]
)
