// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "WarehouseOS",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "WarehouseOS", targets: ["WarehouseOSApp"])
    ],
    dependencies: [
        .package(path: "Packages/WMSCore"),
        .package(path: "Packages/WMSData"),
        .package(path: "Packages/WMSServices"),
        .package(path: "Packages/WMSFeatures"),
        .package(path: "Packages/WMSDesignSystem")
    ],
    targets: [
        .executableTarget(
            name: "WarehouseOSApp",
            dependencies: [
                "WMSCore",
                "WMSData",
                "WMSServices",
                "WMSFeatures",
                "WMSDesignSystem"
            ],
            path: "Sources/WarehouseOSApp"
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "WMSCore",
                "WMSData",
                "WMSServices"
            ],
            path: "Tests/IntegrationTests"
        )
    ]
)
