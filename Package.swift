// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "ChannelSwap",
    platforms: [
        .macOS(.v26)
    ],
    targets: [
        .executableTarget(
            name: "ChannelSwap",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ]
        ),
        .testTarget(
            name: "ChannelSwapTests",
            dependencies: ["ChannelSwap"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ]
        ),
    ]
)
