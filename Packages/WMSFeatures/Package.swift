// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "WMSFeatures",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "WMSFeatures", targets: ["WMSFeatures"])
    ],
    dependencies: [
        .package(path: "../WMSCore"),
        .package(path: "../WMSServices"),
        .package(path: "../WMSDesignSystem")
    ],
    targets: [
        .target(
            name: "WMSFeatures",
            dependencies: ["WMSCore", "WMSServices", "WMSDesignSystem"],
            path: "Sources"
        )
    ]
)
