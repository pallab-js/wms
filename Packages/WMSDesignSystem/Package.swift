// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "WMSDesignSystem",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "WMSDesignSystem", targets: ["WMSDesignSystem"])
    ],
    targets: [
        .target(name: "WMSDesignSystem")
    ]
)
