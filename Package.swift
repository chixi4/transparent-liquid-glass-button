// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "transparent-liquid-glass-button",
    platforms: [
        .macOS(.v26)
    ],
    targets: [
        .executableTarget(
            name: "TransparentLiquidGlassButton",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ]
        ),
        .testTarget(
            name: "TransparentLiquidGlassButtonTests",
            dependencies: ["TransparentLiquidGlassButton"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ]
        ),
    ]
)
