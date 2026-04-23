// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let isRunningInXcode = ProcessInfo.processInfo.environment["__CFBundleIdentifier"] == "com.apple.dt.Xcode"

let package = Package(
    name: "Nexa",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Nexa",
            targets: ["Nexa"]
        ),
    ],
    dependencies: isRunningInXcode
        ? [
            .package(
                url: "https://github.com/SimplyDanny/SwiftLintPlugins.git",
                exact: "0.63.2"
            ),
        ]
        : [],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Nexa",
            plugins: isRunningInXcode
                ? [
                    .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
                ]
                : []
        ),
        .testTarget(
            name: "NexaTests",
            dependencies: ["Nexa"],
            plugins: isRunningInXcode
                ? [
                    .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
                ]
                : []
        ),
    ],
    swiftLanguageModes: [.v6]
)
