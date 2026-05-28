// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "WMSCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "WMSCore", targets: ["WMSCore"])
    ],
    targets: [
        .target(name: "WMSCore"),
        .testTarget(name: "WMSCoreTests", dependencies: ["WMSCore"])
    ]
)
