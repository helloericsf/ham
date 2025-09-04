// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Ham",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // Add any external dependencies here if needed
    ],
    targets: [
        .executableTarget(
            name: "Ham",
            dependencies: []
        ),
        .testTarget(
            name: "HamTests",
            dependencies: ["Ham"]
        )
    ]
)
