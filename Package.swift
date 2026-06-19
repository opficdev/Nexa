// swift-tools-version: 6.1

import Foundation
import PackageDescription

let package = Package(
    name: "Nexa",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "Nexa",
            targets: ["Nexa"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(name: "Nexa"),
        .testTarget(
            name: "NexaTests",
            dependencies: ["Nexa"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
