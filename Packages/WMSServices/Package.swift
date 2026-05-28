// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "WMSServices",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "WMSServices", targets: ["WMSServices"])
    ],
    dependencies: [
        .package(path: "../WMSCore")
    ],
    targets: [
        .target(
            name: "WMSServices",
            dependencies: ["WMSCore"]
        ),
        .testTarget(
            name: "WMSServicesTests",
            dependencies: ["WMSServices"]
        )
    ]
)
