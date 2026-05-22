// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftGamesApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .executable(name: "SwiftGamesApp", targets: ["GamesApp"])
    ],
    targets: [
        .executableTarget(
            name: "GamesApp",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
