import ProjectDescription

let project = Project(
    name: "HealthDataGeneratorApp",
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
            name: "HealthDataGeneratorApp",
            destinations: .iOS,
            product: .app,
            bundleId: "com.aminbenarieb.health-data-generator",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "Health Data Generator",
                    "CFBundleShortVersionString": "1.0.0",
                    "CFBundleVersion": "1",
                    "CFBundleIconName": "AppIcon",
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "NSHealthShareUsageDescription": "This app needs to read health data to generate and populate Apple Health with sample data for testing and development purposes.",
                    "NSHealthUpdateUsageDescription": "This app needs to write health data to populate Apple Health with sample data for testing and development purposes.",
                    "LSApplicationCategoryType": "public.app-category.healthcare-fitness",
                    "ITSAppUsesNonExemptEncryption": false,
                ]
            ),
            sources: ["HealthDataGeneratorApp/Sources/**"],
            resources: ["HealthDataGeneratorApp/Resources/**"],
            entitlements: .file(path: "HealthDataGeneratorApp/HealthDataGenerator.entitlements"),
            dependencies: [
                .package(product: "HealthDataGenerator")
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
            name: "HealthDataGeneratorAppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.aminbenarieb.health-data-generator.tests",
            infoPlist: .default,
            sources: ["HealthDataGeneratorApp/Tests/**"],
            resources: [],
            dependencies: [.target(name: "HealthDataGeneratorApp")]
        ),
    ]
)
