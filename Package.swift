// swift-tools-version:5.3
import PackageDescription
let package = Package(
    name: "MetaAgentSystem",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "MetaAgentSystem",
            targets: ["MetaAgentSystem"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MetaAgentSystem",
            dependencies: []
        ),
        .testTarget(
            name: "MetaAgentSystemTests",
            dependencies: ["MetaAgentSystem"]
        )
    ]
)