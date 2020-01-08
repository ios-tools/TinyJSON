// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "MiniJSON",
    products: [
        .library(name: "MiniJSON", targets: ["MiniJSON"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Nimble", from: "8.0.0")
    ],
    targets: [
        .target(name: "MiniJSON"),
        .testTarget(name: "MiniJSONTests", dependencies: ["MiniJSON", "Nimble"]),
    ]
)
