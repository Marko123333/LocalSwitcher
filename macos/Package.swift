// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LocalSwitcher",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "SwitcherCore",
            path: "Sources/SwitcherCore",
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "LocalSwitcher",
            dependencies: ["SwitcherCore"],
            path: "Sources/LocalSwitcher",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ServiceManagement"),
            ]
        ),
        .testTarget(
            name: "SwitcherCoreTests",
            dependencies: ["SwitcherCore"],
            path: "Tests/SwitcherCoreTests"
        ),
        .testTarget(
            name: "LocalSwitcherTests",
            dependencies: ["LocalSwitcher"],
            path: "Tests/LocalSwitcherTests"
        ),
    ]
)
