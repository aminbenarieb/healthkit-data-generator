// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppleHealthGenerator",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AppleHealthGenerator",
            targets: ["AppleHealthGenerator"]),
    ],
    dependencies: [
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AppleHealthGenerator",
            dependencies: [
            ]),
        .testTarget(
            name: "AppleHealthGeneratorTests",
            dependencies: ["AppleHealthGenerator"]),
    ],
    swiftLanguageVersions: [.v5]
)
