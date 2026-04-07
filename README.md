# Health Data Generator

<!-- 
[![Release](https://github.com/aminbenarieb/healthkit-data-generator/actions/workflows/release.yml/badge.svg)](https://github.com/aminbenarieb/healthkit-data-generator/actions/workflows/release.yml)
[![CodeQL](https://github.com/aminbenarieb/healthkit-data-generator/actions/workflows/codeql.yml/badge.svg)](https://github.com/aminbenarieb/healthkit-data-generator/actions/workflows/codeql.yml)
[![Swift 5.10](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://swift.org)
[![iOS 18.0+](https://img.shields.io/badge/iOS-18.0+-blue.svg)](https://developer.apple.com/ios/) -->
[![CI](https://github.com/aminbenarieb/healthkit-data-generator/actions/workflows/ci.yml/badge.svg)](https://github.com/aminbenarieb/healthkit-data-generator/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Faminbenarieb%2Fhealthkit-data-generator%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/aminbenarieb/healthkit-data-generator)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Faminbenarieb%2Fhealthkit-data-generator%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/aminbenarieb/healthkit-data-generator)
[![Tuist Preview](https://tuist.dev/amin-benarieb-work/healthkit-data-generator/previews/latest/badge.svg)](https://tuist.dev/<your-account>/<your-project>/previews/latest)

## Overview

HealthDataGenerator is a comprehensive Swift package that provides tools for:

- **Data Generation**: Create realistic sample health data for testing
- **Data Export**: Export Health data to JSON format with flexible configuration
- **Data Import**: Import health data from JSON profiles into Apple Health

### Why use this?

- Seed Apple Health with realistic data in minutes
- Perfect for screenshots, demos, UI tests, and QA
- AI-powered configs: “Create 2 weeks of marathon training” → ready-to-use samples

## Demo Videos

| Manual Generation  | LLM Generation  | 
|---------|---------|
| <video width="320" height="240" src="https://github.com/user-attachments/assets/2e953227-0b84-4c1f-90af-cfdbc43583e6"></video>  |   <video width="320" height="240" src="https://github.com/user-attachments/assets/5b808db3-4ae7-4188-a687-505a9b71b5da"></video> | 


## Acknowledgments

This project is inspired by and builds upon the excellent work done in [healthkit-sample-generator](https://github.com/mseemann/healthkit-sample-generator) by Michael Seemann. While this SPM package is a complete rewrite with modern Swift features, LLM integration, and enhanced functionality, we acknowledge the foundational concepts and approaches from the original project.

## Installation

### Swift Package Manager

Add the HealthDataGenerator package to your project:

```swift
dependencies: [
    .package(url: "https://github.com/aminbenarieb/healthkit-data-generator", from: "0.1.0")
]
```

### Building the app
This project uses [Tuist](https://tuist.io). Refer to their website to install it, then run `tuist generate`.

## Usage

### Preset Profiles

```swift
import HealthDataGenerator
import HealthKit

let healthStore = HKHealthStore()
let generator = HealthDataGenerator(healthStore: healthStore)

// Generate 7 days of data with sporty profile
let config = SampleGenerationConfig(
    profile: .sporty,
    dateRange: .lastDays(7)
)

let allTypes = HealthConstants.authorizationWriteTypes()
try generator.generateAndPopulate(samplesTypes: allTypes, config: config)
```

### Quick Presets

```swift
// Last week - sporty profile
let config1 = SampleGenerationConfig.lastWeekSporty()

// Last month - balanced profile
let config2 = SampleGenerationConfig.lastMonthBalanced()

// Last week - stressed profile
let config3 = SampleGenerationConfig.lastWeekStressed()

try generator.generateAndPopulate(samplesTypes: allTypes, config: config1)
```

### Comprehensive Examples

This repository includes a SwiftUI demo app (`HealthDataGeneratorApp/`) showcasing all package features with an intuitive interface for both manual and AI-powered health data generation.

For detailed usage examples covering all features, see [USAGE_EXAMPLES.md](USAGE_EXAMPLES.md) which includes custom profiles, date ranges, metric selection, generation patterns, LLM integration, and app integration examples.

### 🤖 AI-Powered Health Data Generation

The `LLMManager` enables AI-powered health data generation from natural language descriptions. It supports multiple LLM providers through a unified interface and automatically routes requests to the best available provider.

```swift
import HealthDataGenerator
import HealthKit

let healthStore = HKHealthStore()
let llmManager = LLMManager()

// Generate health data from natural language
let response = try await llmManager.generateHealthConfig(from: 
    "Create 2 weeks of marathon training data for an athlete with high activity, excellent sleep, and high-protein diet"
)

// Import the generated configuration
let generator = HealthDataGenerator(healthStore: healthStore)
try generator.importFromLLMJSON(response.json)
```

#### Current LLM Provider
Apple Foundation Model (iOS 26.0+): Native integration with Apple's on-device AI model

#### Extending with Custom Providers
You can add custom LLM providers by implementing the LLMProvider protocol:
```swift
class CustomLLMProvider: LLMProvider {
    let identifier = "custom_provider"
    let name = "Custom LLM"
    var isAvailable: Bool { true }
    
    func generateHealthConfig(from prompt: String) async throws -> String {
        // Your custom LLM integration
        return generatedJSON
    }
    
    func canHandle(_ prompt: String) -> Bool {
        // Determine if this provider can handle the request
        return true
    }
}

// Register your provider
llmManager.register(CustomLLMProvider())
```

The generated JSON follows the schema defined in [LLM_JSON_SCHEMA.md](LLM_JSON_SCHEMA.md), supporting both configuration-based generation and direct sample specification.

<!-- ### Data Export

```swift
import HealthDataGenerator


```

### Data Import

```swift
import HealthDataGenerator

``` -->


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
