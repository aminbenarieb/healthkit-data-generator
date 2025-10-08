# Usage Examples

## Table of Contents
- [Basic Usage](#basic-usage)
- [Custom Profiles](#custom-profiles)
- [Date Ranges](#date-ranges)
- [Metric Selection](#metric-selection)
- [Generation Patterns](#generation-patterns)
- [LLM Integration](#llm-integration)
- [App Integration](#app-integration)

## Basic Usage

### Using Preset Profiles

```swift
import HealthKitDataGenerator
import HealthKit

let healthStore = HKHealthStore()
let generator = HealthKitDataGenerator(healthStore: healthStore)

// Generate 7 days of data with sporty profile
let config = SampleGenerationConfig(
    profile: .sporty,
    dateRange: .lastDays(7)
)

let allTypes = HealthKitConstants.authorizationWriteTypes()
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

## Custom Profiles

### Creating a Custom Profile

```swift
let marathonTrainer = HealthProfile(
    id: "marathon_trainer",
    name: "Marathon Trainer",
    description: "Training for marathon with high mileage",
    dailyStepsRange: 15000...25000,
    workoutFrequency: .active,
    preferredWorkoutTypes: [.running, .cycling, .yoga],
    sleepDurationRange: 7.5...9.0,
    sleepQuality: .good,
    bedtimeRange: 21...26,
    restingHeartRateRange: 45...55,
    maxHeartRateRange: 180...195,
    heartRateVariability: .high,
    basalEnergyMultiplier: 1.1,
    activeEnergyRange: 800...1500,
    stressLevel: .moderate,
    recoveryRate: .fast,
    dietaryPattern: .highProtein,
    hydrationLevel: .high
)

let config = SampleGenerationConfig(
    profile: marathonTrainer,
    dateRange: .lastDays(30)
)
```

### Modifying Preset Profiles

```swift
// Start with a preset
var customProfile = HealthProfile.balanced

// Create a new profile with modifications
let modifiedProfile = HealthProfile(
    id: "custom_balanced",
    name: "My Balanced Profile",
    description: customProfile.description,
    dailyStepsRange: 10000...15000, // Increased steps
    workoutFrequency: customProfile.workoutFrequency,
    preferredWorkoutTypes: customProfile.preferredWorkoutTypes,
    sleepDurationRange: customProfile.sleepDurationRange,
    sleepQuality: customProfile.sleepQuality,
    bedtimeRange: customProfile.bedtimeRange,
    restingHeartRateRange: customProfile.restingHeartRateRange,
    maxHeartRateRange: customProfile.maxHeartRateRange,
    heartRateVariability: customProfile.heartRateVariability,
    basalEnergyMultiplier: customProfile.basalEnergyMultiplier,
    activeEnergyRange: customProfile.activeEnergyRange,
    stressLevel: customProfile.stressLevel,
    recoveryRate: customProfile.recoveryRate,
    dietaryPattern: customProfile.dietaryPattern,
    hydrationLevel: customProfile.hydrationLevel
)
```

## Date Ranges

### Last N Days

```swift
// Last 7 days
let config = SampleGenerationConfig(
    profile: .balanced,
    dateRange: .lastDays(7)
)

// Last 30 days
let config = SampleGenerationConfig(
    profile: .balanced,
    dateRange: .lastDays(30)
)

// Last 90 days
let config = SampleGenerationConfig(
    profile: .balanced,
    dateRange: .lastDays(90)
)
```

### Specific Date Range

```swift
let calendar = Calendar.current
let startDate = calendar.date(byAdding: .month, value: -1, to: Date())!
let endDate = Date()

let config = SampleGenerationConfig(
    profile: .sporty,
    dateRange: DateRange(startDate: startDate, endDate: endDate)
)
```

### Single Day

```swift
let specificDate = Date() // or any date
let config = SampleGenerationConfig(
    profile: .balanced,
    dateRange: .singleDay(specificDate)
)
```

## Metric Selection

### Generate Specific Metrics Only

```swift
let config = SampleGenerationConfig(
    profile: .sporty,
    dateRange: .lastDays(7),
    metricsToGenerate: [
        .steps,
        .heartRate,
        .sleepAnalysis,
        .workouts
    ]
)
```

### All Metrics Except Some

```swift
var allMetrics = Set(HealthMetric.allCases)
allMetrics.remove(.bloodPressure)
allMetrics.remove(.bloodGlucose)

let config = SampleGenerationConfig(
    profile: .balanced,
    dateRange: .lastDays(7),
    metricsToGenerate: allMetrics
)
```

### Activity Metrics Only

```swift
let activityMetrics: Set<HealthMetric> = [
    .steps,
    .workouts,
    .activeEnergy,
    .heartRate
]

let config = SampleGenerationConfig(
    profile: .sporty,
    dateRange: .lastDays(7),
    metricsToGenerate: activityMetrics
)
```

## Generation Patterns

### Continuous (Every Day)

```swift
let config = SampleGenerationConfig(
    profile: .balanced,
    dateRange: .lastDays(30),
    pattern: .continuous
)
```

### Sparse (Random Gaps)

```swift
let config = SampleGenerationConfig(
    profile: .sedentary,
    dateRange: .lastDays(30),
    pattern: .sparse // 70% coverage
)
```

### Weekdays Only

```swift
let config = SampleGenerationConfig(
    profile: .stressed,
    dateRange: .lastDays(14),
    pattern: .weekdaysOnly
)
```

### Weekends Only

```swift
let config = SampleGenerationConfig(
    profile: .sporty,
    dateRange: .lastDays(14),
    pattern: .weekendsOnly
)
```

<!-- ## Custom Overrides

### Override Specific Metrics

```swift
let config = SampleGenerationConfig(
    profile: .balanced,
    dateRange: .lastDays(7),
    customOverrides: [
        "steps": MetricOverride(
            multiplier: 1.5, // 50% more steps
            variability: 0.2  // Less variation
        ),
        "heart_rate": MetricOverride(
            multiplier: 0.9  // Slightly lower heart rate
        )
    ]
)
```

### Fixed Values

```swift
let config = SampleGenerationConfig(
    profile: .balanced,
    dateRange: .lastDays(7),
    customOverrides: [
        "body_mass": MetricOverride(
            fixedValue: 70.0 // Exactly 70kg every day
        )
    ]
)
```

## Reproducible Generation

### Using Random Seeds

```swift
// Same seed = same data
let config = SampleGenerationConfig(
    profile: .balanced,
    dateRange: .lastDays(7),
    randomSeed: 42
)

// Generate twice with same seed - identical results
let data1 = generator.generate(config: config)
let data2 = generator.generate(config: config)
// data1 == data2
``` -->
## App Integration

### In SwiftUI View

```swift
import SwiftUI
import HealthKitDataGenerator

struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var selectedProfile: HealthProfile = .balanced
    @State private var sampleCount: Int = 7
    
    var body: some View {
        VStack {
            // Profile picker
            Picker("Profile", selection: $selectedProfile) {
                ForEach(HealthProfile.allPresets, id: \.id) { profile in
                    Text(profile.name).tag(profile)
                }
            }
            
            // Sample count
            Stepper("Days: \(sampleCount)", value: $sampleCount, in: 1...90)
            
            // Generate button
            Button("Generate Data") {
                healthKitManager.generateHealthData(
                    count: sampleCount,
                    profile: selectedProfile
                )
            }
            .disabled(healthKitManager.isGeneratingInProgress)
        }
    }
}
```


### JSON Import in App

```swift
struct JSONImportView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var jsonText = ""
    
    var body: some View {
        VStack {
            TextEditor(text: $jsonText)
                .border(Color.gray)
            
            Button("Import JSON") {
                healthKitManager.importFromJSON(jsonText)
            }
            .disabled(healthKitManager.isGeneratingInProgress)
        }
    }
}
```

## Advanced Usage

### Generate Without Populating

```swift
// Generate data but don't save to HealthKit
let samples = generator.generate(config: config)

// Inspect or modify samples
print("Generated \(samples.count) sample types")

// Save later if needed
try generator.populate(samplesTypes: allTypes, generatedSamples: samples)
```

### Combining Multiple Profiles

```swift
// Week 1: Stressed
let config1 = SampleGenerationConfig(
    profile: .stressed,
    dateRange: DateRange(
        startDate: calendar.date(byAdding: .day, value: -14, to: Date())!,
        endDate: calendar.date(byAdding: .day, value: -7, to: Date())!
    )
)

// Week 2: Balanced (recovery)
let config2 = SampleGenerationConfig(
    profile: .balanced,
    dateRange: .lastDays(7)
)

try generator.generateAndPopulate(samplesTypes: allTypes, config: config1)
try generator.generateAndPopulate(samplesTypes: allTypes, config: config2)
```

### Batch Generation

```swift
let profiles: [HealthProfile] = [.sporty, .balanced, .stressed, .sedentary]

for profile in profiles {
    let config = SampleGenerationConfig(
        profile: profile,
        dateRange: .singleDay(Date())
    )
    
    print("Generating for \(profile.name)...")
    try generator.generateAndPopulate(samplesTypes: allTypes, config: config)
}
```