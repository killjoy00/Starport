// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Starport",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "StarportCore", targets: ["StarportCore"])
    ],
    targets: [
        .target(
            name: "StarportCore",
            path: "Starport",
            exclude: ["App", "UI"],
            sources: ["Core"],
            resources: [.process("Content")]
        ),
        .testTarget(
            name: "StarportCoreTests",
            dependencies: ["StarportCore"],
            path: "StarportTests"
        )
    ]
)
