// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "bazel-rest-cache",
    products: [
        .executable(
            name: "bazel-rest-cache",
            targets: [
                "bazel-rest-cache"
            ]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/IBM-Swift/Kitura.git",
            Version(0,0,0)..<Version(.max,.max,.max)
        ),
        .package(
            url: "https://github.com/IBM-Swift/Kitura-Compression.git",
            Version(0,0,0)..<Version(.max,.max,.max)
        ),
        .package(
            url: "https://github.com/IBM-Swift/Kitura-redis.git",
            Version(0,0,0)..<Version(.max,.max,.max)
        ),
        .package(
            url: "https://github.com/IBM-Swift/HeliumLogger.git",
            Version(0,0,0)..<Version(.max,.max,.max)
        ),
    ],
    targets: [
        .target(
            name: "bazel-rest-cache",
            dependencies: [
                "HeliumLogger",
                "Kitura",
                "KituraCompression",
                "SwiftRedis",
            ]
        )
    ]
)
