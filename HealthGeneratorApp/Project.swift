import ProjectDescription

let project = Project(
    name: "HealthGeneratorApp",
    organizationName: "Welltory",
    packages: [
        .local(path: "../../Packages/AppleHealthGenerator")
    ],
    settings: .settings(
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release")
        ]
    ),
    targets: [
        .target(
            name: "HealthGeneratorApp",
            destinations: .iOS,
            product: .app,
            bundleId: "com.welltory.healthgpt-demo",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "Health Generator",
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
            sources: ["HealthGeneratorApp/Sources/**"],
            resources: ["HealthGeneratorApp/Resources/**"],
            entitlements: .file(path: "HealthGeneratorApp/HealthGeneratorApp.entitlements"),
            dependencies: [
                .package(product: "AppleHealthGenerator")
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "MMPP2NZU96", // Replace with your Apple Developer Team ID
                    "CODE_SIGN_STYLE": "Automatic",
                    "PROVISIONING_PROFILE_SPECIFIER": "",
                ]
            )
        ),
        .target(
            name: "HealthGeneratorAppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.welltory.healthgpt-demo.tests",
            infoPlist: .default,
            sources: ["HealthGeneratorApp/Tests/**"],
            resources: [],
            dependencies: [.target(name: "HealthGeneratorApp")]
        ),
    ]
)
