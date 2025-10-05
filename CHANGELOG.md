# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project structure with Swift Package and iOS app
- GitHub Actions workflows for CI/CD
- Automated release process with proper tagging
- Code quality tools (SwiftLint, CodeQL)
- Comprehensive documentation

## [1.0.0] - 2024-XX-XX

### Added
- **HealthKitDataGenerator Swift Package**
  - Health data generation for various HealthKit data types
  - Configurable data export functionality
  - Health data cleanup capabilities
  - Profile-based data generation
  - JSON import/export functionality

- **HealthGeneratorApp iOS App**
  - SwiftUI-based modern interface
  - HealthKit integration with proper permissions
  - Data generation with customizable sample counts
  - Data cleanup functionality
  - Real-time progress tracking
  - iOS 18.0+ support

- **Development Tools**
  - Tuist for project generation
  - Python scripts for icon generation
  - Comprehensive test coverage
  - GitHub Actions CI/CD pipeline

### Features
- Generate realistic health data including:
  - Heart rate samples
  - Step count data
  - Sleep analysis
  - Workout sessions
  - Body measurements
  - Nutrition data
  - And many more health metrics

- **Data Management**
  - Safe data cleanup (only removes app-generated data)
  - Bulk data generation
  - Progress tracking during operations
  - Error handling and user feedback

- **Architecture**
  - MVVM pattern with SwiftUI
  - Async/await for modern concurrency
  - Modular design with clear separation of concerns
  - Comprehensive error handling

### Technical Details
- **Minimum Requirements**
  - iOS 18.0+
  - Xcode 15.0+
  - Swift 5.10+

- **Dependencies**
  - HealthKit framework
  - SwiftUI
  - Combine
  - OSLog for logging

### Documentation
- Comprehensive README with setup instructions
- Contributing guidelines
- Code documentation and examples
- Architecture overview

[Unreleased]: https://github.com/your-username/health-generator-app/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/your-username/health-generator-app/releases/tag/v1.0.0
