// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacWhip",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MacWhipCore",
            targets: ["MacWhipCore"]
        ),
        .executable(
            name: "MacWhip",
            targets: ["MacWhipApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-testing.git", from: "0.6.0")
    ],
    targets: [
        .target(
            name: "MacWhipCore",
            path: "Sources/MacWhip"
        ),
        .executableTarget(
            name: "MacWhipApp",
            dependencies: ["MacWhipCore"],
            path: "Sources/MacWhipApp"
        ),
        .testTarget(
            name: "MacWhipTests",
            dependencies: [
                "MacWhipCore",
                .product(name: "Testing", package: "swift-testing")
            ]
        )
    ]
)
