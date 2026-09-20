// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FeverLogEngine",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "FeverLogEngine", targets: ["FeverLogEngine"])
    ],
    targets: [
        .target(name: "FeverLogEngine", resources: [.process("Resources")]),
        .testTarget(name: "FeverLogEngineTests", dependencies: ["FeverLogEngine"])
    ]
)
