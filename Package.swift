// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HealthKitDataGenerator",
    platforms: [
        .iOS("17.0"),
        .macOS("13.0"),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "HealthKitDataGenerator",
            targets: ["HealthKitDataGenerator"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "HealthKitDataGenerator",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ]),
        .testTarget(
            name: "HealthKitDataGeneratorTests",
            dependencies: ["HealthKitDataGenerator"]),
    ],
    swiftLanguageVersions: [.v5]
)
