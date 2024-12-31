// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "cfddns",
	platforms: [
        .macOS(.v12) 
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "cfddns",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
    ]
)
