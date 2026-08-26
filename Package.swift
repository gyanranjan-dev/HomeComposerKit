// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HomeComposerKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "HomeComposerKit",
            targets: ["HomeComposerKit"]
        ),
    ],
    targets: [
        .target(
            name: "HomeComposerKit"
        ),
        .testTarget(
            name: "HomeComposerKitTests",
            dependencies: ["HomeComposerKit"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
