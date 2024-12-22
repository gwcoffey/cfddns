// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "cfddns",
	platforms: [
        .macOS(.v12) 
    ],
    targets: [
        .executableTarget(
            name: "cfddns"),
    ]
)
