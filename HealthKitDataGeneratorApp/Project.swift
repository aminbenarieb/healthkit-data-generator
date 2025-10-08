import ProjectDescription

let project = Project(
    name: "HealthKitDataGeneratorApp",
    organizationName: "aminbenarieb",
    packages: [
        .local(path: "../")
    ],
    settings: .settings(
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release")
        ]
    ),
    targets: [
        .target(
            name: "HealthKitDataGeneratorApp",
            destinations: .iOS,
            product: .app,
            bundleId: "com.aminbenarieb.healthkit-data-generator",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "HealthKit Data Generator",
                    "CFBundleShortVersionString": "1.0.0",
                    "CFBundleVersion": "1",
                    "CFBundleIconName": "AppIcon",
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "NSHealthShareUsageDescription": "This app needs to read health data to generate and populate HealthKit with sample data for testing and development purposes.",
                    "NSHealthUpdateUsageDescription": "This app needs to write health data to populate HealthKit with sample data for testing and development purposes.",
                    "LSApplicationCategoryType": "public.app-category.healthcare-fitness",
                    "ITSAppUsesNonExemptEncryption": false,
                ]
            ),
            sources: ["HealthKitDataGeneratorApp/Sources/**"],
            resources: ["HealthKitDataGeneratorApp/Resources/**"],
            entitlements: .file(path: "HealthKitDataGeneratorApp/HealthKitDataGenerator.entitlements"),
            dependencies: [
                .package(product: "HealthKitDataGenerator")
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "5P8935L6RT", // Replace with your Apple Developer Team ID
                    "CODE_SIGN_STYLE": "Automatic",
                    "PROVISIONING_PROFILE_SPECIFIER": "",
                ]
            )
        ),
        .target(
            name: "HealthKitDataGeneratorAppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.aminbenarieb.healthkit-data-generator.tests",
            infoPlist: .default,
            sources: ["HealthKitDataGeneratorApp/Tests/**"],
            resources: [],
            dependencies: [.target(name: "HealthKitDataGeneratorApp")]
        ),
    ]
)
