# HealthKitDataGenerator

A Swift package for generating, importing, and exporting HealthKit data for testing and development purposes.

## Overview

HealthKitDataGenerator is a comprehensive Swift package that provides tools for:

- **Data Generation**: Create realistic sample health data for testing
- **Data Export**: Export HealthKit data to JSON format with flexible configuration
- **Data Import**: Import health data from JSON profiles into HealthKit
- **Profile Management**: Manage and organize health data profiles
- **Utilities**: Helper classes for data manipulation and file management

## Features

### 🏗️ Organized Architecture
- **Modular Design**: Clean separation of concerns with organized modules
- **Core**: Main data generator functionality
- **DataGeneration**: Sample creation and generation logic  
- **DataExport**: Export configuration and targets
- **DataImport**: Profile management and import functionality
- **JSON**: JSON processing utilities
- **Utilities**: Helper classes and extensions
- **Constants**: HealthKit constants and type definitions

### 📊 Data Generation
- Generate realistic health data for multiple days
- Support for various HealthKit sample types:
  - Heart rate and heartbeat series
  - Sleep analysis phases
  - Workout activities
  - Dietary information
  - Blood pressure readings
  - Step counts and energy burned

### 📤 Data Export
- Export HealthKit data to JSON format
- Flexible export configurations
- Support for different export targets (file, memory)
- Configurable date ranges and data filtering

### 📥 Data Import
- Import health data from JSON profiles
- Batch import capabilities
- Progress tracking and error handling
- Profile metadata management

## Requirements

- iOS 16.0+
- Swift 5.10+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "path/to/HealthKitDataGenerator", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Select the version range

## Usage

### Basic Data Generation

```swift
import HealthKitDataGenerator
import HealthKit

// Initialize the data generator
let healthStore = HKHealthStore()
let generator = HealthKitDataGenerator(healthStore: healthStore)

// Generate sample data for 7 days
let sampleData = SampleDataGenerator.generateSamples(7, includeBasalCalories: true)

// Define which sample types to populate
let sampleTypes: Set<HKSampleType> = [
    HKQuantityType.quantityType(forIdentifier: .heartRate)!,
    HKQuantityType.quantityType(forIdentifier: .stepCount)!,
    // Add more types as needed
]

// Populate HealthKit with the generated data
try generator.populate(samplesTypes: sampleTypes, generatedSamples: sampleData)
```

### Data Export

```swift
import HealthKitDataGenerator

// Create export configuration
let config = HealthDataFullExportConfiguration(
    profileName: "MyProfile",
    exportType: .ALL,
    startDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
    endDate: Date(),
    shouldAuthorize: true
)

// Create export target
let exportTarget = JsonSingleDocAsFileExportTarget(
    outputFileName: "/path/to/export.json",
    overwriteIfExist: true
)

// Perform export (implementation depends on your specific needs)
```

### Data Import

```swift
import HealthKitDataGenerator

// Create profile from file
let profileURL = URL(fileURLWithPath: "/path/to/profile.json")
let profile = HealthKitProfile(healthStore: healthStore, fileAtPath: profileURL)

// Create importer
let importer = HealthKitProfileImporter(healthStore: healthStore)

// Import profile
importer.importProfile(
    profile,
    deleteExistingData: false,
    onProgress: { message, progress in
        print("Import progress: \(message)")
    },
    onCompletion: { error in
        if let error = error {
            print("Import failed: \(error)")
        } else {
            print("Import completed successfully")
        }
    }
)
```

## Architecture

The package is organized into focused modules:

```
HealthKitDataGenerator/
├── Core/                     # Main functionality
│   └── HealthKitDataGenerator.swift
├── DataGeneration/           # Sample creation
│   ├── SampleDataGenerator.swift
│   └── SampleCreator.swift
├── DataExport/              # Export functionality
│   ├── ExportConfiguration.swift
│   └── ExportTargets.swift
├── DataImport/              # Import functionality
│   ├── HealthKitProfile.swift
│   ├── HealthKitProfileReader.swift
│   └── HealthKitProfileImporter.swift
├── JSON/                    # JSON processing
│   ├── JsonReader.swift
│   ├── JsonWriter.swift
│   ├── JsonTokenizer.swift
│   ├── JsonHandlerProtocol.swift
│   └── OutputStreams.swift
├── Utilities/               # Helper classes
│   ├── DateExtensions.swift
│   ├── FileNameUtil.swift
│   └── HealthKitStoreCleaner.swift
└── Constants/               # HealthKit constants
    └── HealthKitConstants.swift
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is available under the MIT license. See the LICENSE file for more info.
