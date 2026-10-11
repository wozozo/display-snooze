// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "DisplaySnooze",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(name: "DisplaySnooze", targets: ["DisplaySnooze"])
    ],
    targets: [
        .executableTarget(
            name: "DisplaySnooze",
            dependencies: ["DisplaySnoozeCore"],
            resources: [.process("Resources")]
        ),
        .target(name: "DisplaySnoozeCore"),
        .testTarget(
            name: "DisplaySnoozeTests",
            dependencies: ["DisplaySnoozeCore"]
        )
    ]
)
