import PackageDescription

let package = Package(
    name: "bazel-rest-cache",
    dependencies: [
        .Package(
            url: "https://github.com/IBM-Swift/Kitura.git",
            majorVersion: 1,
            minor: 7
        ),
        .Package(
            url: "https://github.com/IBM-Swift/Kitura-Compression.git",
            majorVersion: 1,
            minor: 7
        ),
        .Package(
            url: "https://github.com/IBM-Swift/Kitura-redis.git",
            majorVersion: 1,
            minor: 7
        ),
        .Package(
            url: "https://github.com/IBM-Swift/HeliumLogger.git",
            majorVersion: 1,
            minor: 7
        ),
        .Package(
            url: "https://github.com/IBM-Swift/SwiftyJSON.git", 
            majorVersion: 16
        ),
    ]
)
