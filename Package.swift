// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "TinyJSON",
    products: [
        .library(name: "TinyJSON", targets: ["TinyJSON"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Nimble", from: "8.0.0")
    ],
    targets: [
        .target(name: "TinyJSON"),
        .testTarget(name: "TinyJSONTests", dependencies: ["TinyJSON", "Nimble"]),
    ]
)
