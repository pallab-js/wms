// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "WMSData",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "WMSData", targets: ["WMSData"])
    ],
    dependencies: [
        .package(path: "../WMSCore")
    ],
    targets: [
        .target(
            name: "WMSData",
            dependencies: ["WMSCore"]
        )
    ]
)
