// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FredKit-iOS",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "FredKit-iOS",
            targets: ["FredKit-iOS"])
    ],
    dependencies: [
        .package(url: "https://github.com/frogg/FredKitCharts.git", .upToNextMajor(from: "4.0.3")),
        .package(url: "https://github.com/frogg/FredKit.git", from: "0.0.32"),
        .package(url: "https://github.com/frogg/FredKitTabBarSplitView.git", from: "0.0.1")
    ],
    
    targets: [
        .target(
            name: "FredKit-iOS",
            dependencies: [
                .product(
                    name: "Charts",
                    package: "FredKitCharts",
                    condition: .when(platforms: [.iOS, .macCatalyst])
                ),
                "FredKit"
            ]
        ),
        .testTarget(
            name: "FredKit-iOSTests",
            dependencies: ["FredKit-iOS"]),
    ]
)
