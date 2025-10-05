# Health Generator App

[![CI](https://github.com/aminbenarieb/health-generator-app/actions/workflows/ci.yml/badge.svg)](https://github.com/aminbenarieb/health-generator-app/actions/workflows/ci.yml)
[![Release](https://github.com/aminbenarieb/health-generator-app/actions/workflows/release.yml/badge.svg)](https://github.com/aminbenarieb/health-generator-app/actions/workflows/release.yml)
[![CodeQL](https://github.com/aminbenarieb/health-generator-app/actions/workflows/codeql.yml/badge.svg)](https://github.com/aminbenarieb/health-generator-app/actions/workflows/codeql.yml)
[![Swift 5.10](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://swift.org)
[![iOS 18.0+](https://img.shields.io/badge/iOS-18.0+-blue.svg)](https://developer.apple.com/ios/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A modern SwiftUI app for generating and managing Apple Health data, featuring both a Swift Package and iOS application for comprehensive health data testing and development.

## 🌟 Features

- 🏥 **HealthKit Integration**: Seamlessly connects with Apple Health
- 🔧 **Data Generation**: Create sample health data with customizable count
- 🧹 **Data Cleanup**: Clean all app-generated health data from HealthKit
- 📱 **Modern UI**: Built with SwiftUI and iOS 18 design patterns
- 🔒 **Privacy Focused**: Proper HealthKit permissions and user control
- 📦 **Swift Package**: Reusable HealthKitDataGenerator package
- 🚀 **CI/CD Ready**: Complete GitHub Actions workflows

## Requirements

- iOS 18.0+
- Xcode 15.0+
- Swift 5.10+

## Setup

1. Clone or download the project
2. Navigate to the project directory:
   ```bash
   cd HealthGeneratorApp
   ```
3. Generate the Xcode project using Tuist:
   ```bash
   tuist generate
   ```
4. Open the workspace:
   ```bash
   open HealthGeneratorApp.xcworkspace
   ```

## Project Structure

The project is organized using Tuist for project generation and includes:

- **SwiftUI Interface**: Modern, accessible UI built with SwiftUI
- **HealthKit Manager**: Centralized health data management
- **SPM Dependencies**: Uses HealthKitDataGenerator package from the parent workspace
- **Proper Entitlements**: Configured for HealthKit access

## Usage

1. **Grant Permissions**: The app will request HealthKit permissions on first launch
2. **Generate Data**: Enter the number of samples you want to generate and tap "Generate Health Data"
3. **Clean Data**: Remove all app-generated data by tapping "Clean Health Data"

## Features in Detail

### Data Generation
- Generates various types of health data including:
  - Heart rate samples
  - Step count
  - Sleep analysis
  - Workout data
  - And many more health metrics

### Data Cleanup
- Safely removes only data created by this app
- Shows progress during cleanup process
- Preserves existing health data from other sources

## Architecture

- **MVVM Pattern**: Uses ObservableObject for state management
- **Async/Await**: Modern concurrency for HealthKit operations
- **Modular Design**: Separation of concerns with dedicated managers
- **Error Handling**: Comprehensive error handling and user feedback

## HealthKit Permissions

The app requests the following HealthKit permissions:
- Read access to all available health data types
- Write access to all writable health data types

## Development

Built with modern iOS development practices:
- SwiftUI for UI
- Combine for reactive programming
- HealthKit for health data
- OSLog for logging
- SPM for dependency management

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details on how to:

- Set up the development environment
- Submit bug reports and feature requests
- Create pull requests
- Follow our coding standards

## 📋 Project Structure

```
health-generator-app/
├── HealthKitDataGenerator/          # Swift Package for health data generation
│   ├── Sources/HealthKitDataGenerator/
│   └── Tests/HealthKitDataGeneratorTests/
├── HealthGeneratorApp/            # SwiftUI iOS application
│   ├── HealthGeneratorApp/Sources/
│   └── HealthGeneratorApp/Tests/
├── .github/workflows/             # CI/CD workflows
├── CONTRIBUTING.md               # Contributing guidelines
├── CHANGELOG.md                  # Version history
└── LICENSE                       # MIT license
```

## 🚀 Installation

### Swift Package Manager

Add the HealthKitDataGenerator package to your project:

```swift
dependencies: [
    .package(url: "https://github.com/aminbenarieb/health-generator-app", from: "1.0.0")
]
```

### Clone and Build

```bash
git clone https://github.com/aminbenarieb/health-generator-app.git
cd health-generator-app/HealthGeneratorApp
tuist generate
open HealthGeneratorApp.xcworkspace
```

## 📖 Usage Examples

### Swift Package Usage

```swift
import HealthKitDataGenerator

let generator = HealthKitDataGenerator()
try await generator.generateHealthData(sampleCount: 100)
```

### iOS App

1. Install and launch the Health Generator app
2. Grant HealthKit permissions
3. Enter desired sample count
4. Tap "Generate Health Data"
5. Use "Clean Health Data" to remove generated samples

## 🔧 Development

### Prerequisites

- macOS 14.0+
- Xcode 15.0+
- Swift 5.10+
- Tuist (for iOS app)

### Quick Start

```bash
# Clone the repository
git clone https://github.com/aminbenarieb/health-generator-app.git
cd health-generator-app

# Build and test Swift Package
cd HealthKitDataGenerator
swift build && swift test

# Generate and build iOS app
cd ../HealthGeneratorApp
tuist generate
# Open in Xcode and build
```

## 📈 Roadmap

- [ ] Additional health data types support
- [ ] Custom data profiles
- [ ] Export/import functionality
- [ ] macOS companion app
- [ ] Apple Watch integration

## 🐛 Issues and Support

- 🐛 [Report bugs](https://github.com/aminbenarieb/health-generator-app/issues/new?template=bug_report.md)
- 💡 [Request features](https://github.com/aminbenarieb/health-generator-app/issues/new?template=feature_request.md)
- 💬 [Discussions](https://github.com/aminbenarieb/health-generator-app/discussions)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Apple HealthKit framework
- SwiftUI and Combine
- Tuist for project generation
- GitHub Actions for CI/CD
