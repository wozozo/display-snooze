// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DisplaySnooze",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "DisplaySnooze", targets: ["DisplaySnooze"])
    ],
    targets: [
        .executableTarget(
            name: "DisplaySnooze",
            dependencies: ["DisplaySnoozeCore"]
        ),
        .target(name: "DisplaySnoozeCore"),
        .testTarget(
            name: "DisplaySnoozeTests",
            dependencies: ["DisplaySnoozeCore"]
        )
    ]
)
