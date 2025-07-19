// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "MetaAgentSystem",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-runtime.git", from: "1.0.0"),
        .package(url: "https://github.com/mattpolzin/OpenAPIKit.git", from: "3.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.0.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.0.0"),
	.package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "MetaAgentSystem",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIKit", package: "OpenAPIKit"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
                .product(name: "NIOExtras", package: "swift-nio-extras"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "SwiftyJSON", package: "SwiftyJSON")
            ]
        ),
        .executableTarget(
            name: "Bootstrap",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIKit", package: "OpenAPIKit"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
                .product(name: "NIOExtras", package: "swift-nio-extras"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "SwiftyJSON", package: "SwiftyJSON")
            ]
        ),
     .testTarget(
         name: "MetaAgentSystemTests",
         dependencies: ["MetaAgentSystem"]
      )
    ]
)
