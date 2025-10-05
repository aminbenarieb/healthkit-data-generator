# HealthKit Data Generator - LLM-Driven Feature Implementation Plan

## Overview
This document outlines the implementation plan for adding flexible, profile-based, and LLM-driven data generation capabilities to the HealthKit Data Generator.

## ✅ Completed

### 1. Core Models Created
- **HealthProfile.swift** - Comprehensive health persona model with:
  - Activity patterns (steps, workouts, workout types)
  - Sleep patterns (duration, quality, bedtime)
  - Heart rate patterns (resting, max, HRV)
  - Energy and calories
  - Stress and recovery metrics
  - Nutrition patterns
  - 4 preset profiles: `sporty`, `stressed`, `balanced`, `sedentary`

- **SampleGenerationConfig.swift** - Flexible configuration model with:
  - Profile selection
  - Date range specification
  - Metric selection (20+ health metrics)
  - Generation patterns (continuous, sparse, weekdays, weekends, custom)
  - Custom overrides per metric
  - JSON import/export for LLM integration

## 🚧 Next Steps

### 2. Refactor SampleDataGenerator
**File**: `HealthKitDataGenerator/Sources/HealthKitDataGenerator/DataGeneration/SampleDataGenerator.swift`

**Changes needed**:
```swift
// Add new method signature
public static func generateSamples(
    config: SampleGenerationConfig
) -> [String: Any]

// Keep existing method for backward compatibility
public static func generateSamples(
    _ numberOfDays: Int, 
    includeBasalCalories: Bool = true
) -> [String: Any] {
    // Delegate to new method with default config
    let config = SampleGenerationConfig(
        profile: .balanced,
        dateRange: .lastDays(numberOfDays)
    )
    return generateSamples(config: config)
}
```

### 3. Create LLM JSON Schema
**File**: `HealthKitDataGenerator/Sources/HealthKitDataGenerator/DataGeneration/LLMJSONSchema.swift`

**Purpose**: Define the JSON schema that LLMs (like Apple Foundation Model) can generate

**Example schema**:
```json
{
  "schema_version": "1.0",
  "generation_config": {
    "profile": {
      "id": "custom",
      "name": "Marathon Trainer",
      "dailyStepsRange": {"lowerBound": 15000, "upperBound": 25000},
      "workoutFrequency": "active",
      ...
    },
    "dateRange": {
      "startDate": "2025-01-01T00:00:00Z",
      "endDate": "2025-01-07T23:59:59Z"
    },
    "metricsToGenerate": ["steps", "heart_rate", "workouts", "sleep_analysis"],
    "pattern": "continuous"
  },
  "samples": [
    {
      "type": "HKQuantityTypeIdentifierStepCount",
      "date": "2025-01-01T10:30:00Z",
      "value": 15234,
      "unit": "count"
    },
    ...
  ]
}
```

### 4. Update HealthKitDataGenerator
**File**: `HealthKitDataGenerator/Sources/HealthKitDataGenerator/Core/HealthKitDataGenerator.swift`

**Add methods**:
```swift
// Generate from config
public func generate(config: SampleGenerationConfig) throws -> [String: Any]

// Import from LLM-generated JSON
public func importFromLLMJSON(_ jsonString: String) throws

// Validate LLM JSON before import
public func validateLLMJSON(_ jsonString: String) throws -> Bool
```

### 5. Create Plugin Architecture
**File**: `HealthKitDataGenerator/Sources/HealthKitDataGenerator/DataGeneration/SampleGeneratorProtocol.swift`

**Purpose**: Allow extensibility for new sample types

```swift
public protocol SampleGeneratorProtocol {
    var metricType: HealthMetric { get }
    func generate(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]]
}

// Registry for plugins
public class SampleGeneratorRegistry {
    private static var generators: [HealthMetric: SampleGeneratorProtocol] = [:]
    
    public static func register(_ generator: SampleGeneratorProtocol) {
        generators[generator.metricType] = generator
    }
    
    public static func generator(for metric: HealthMetric) -> SampleGeneratorProtocol? {
        return generators[metric]
    }
}
```

### 6. App UI Enhancements

#### Profile Selector View
**File**: `HealthKitDataGeneratorApp/HealthKitDataGenerator/Sources/ProfileSelectorView.swift`

```swift
struct ProfileSelectorView: View {
    @Binding var selectedProfile: HealthProfile
    @State private var showingCustomProfile = false
    
    var body: some View {
        VStack {
            // Preset profiles
            ForEach(HealthProfile.allPresets, id: \.id) { profile in
                ProfileCard(profile: profile, isSelected: selectedProfile.id == profile.id)
                    .onTapGesture {
                        selectedProfile = profile
                    }
            }
            
            // Custom profile button
            Button("Create Custom Profile") {
                showingCustomProfile = true
            }
        }
    }
}
```

#### Date Range Picker
**File**: `HealthKitDataGeneratorApp/HealthKitDataGenerator/Sources/DateRangePicker.swift`

```swift
struct DateRangePicker: View {
    @Binding var dateRange: DateRange
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    var body: some View {
        VStack {
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
            
            // Quick presets
            HStack {
                Button("Last 7 Days") { /* ... */ }
                Button("Last 30 Days") { /* ... */ }
                Button("Last 90 Days") { /* ... */ }
            }
        }
    }
}
```

#### Metric Selector
**File**: `HealthKitDataGeneratorApp/HealthKitDataGenerator/Sources/MetricSelectorView.swift`

```swift
struct MetricSelectorView: View {
    @Binding var selectedMetrics: Set<HealthMetric>
    
    var body: some View {
        List {
            ForEach(HealthMetric.allCases, id: \.self) { metric in
                Toggle(metric.rawValue.capitalized, isOn: Binding(
                    get: { selectedMetrics.contains(metric) },
                    set: { isOn in
                        if isOn {
                            selectedMetrics.insert(metric)
                        } else {
                            selectedMetrics.remove(metric)
                        }
                    }
                ))
            }
        }
    }
}
```

#### JSON Import View
**File**: `HealthKitDataGeneratorApp/HealthKitDataGenerator/Sources/JSONImportView.swift`

```swift
struct JSONImportView: View {
    @State private var jsonText = ""
    @State private var isValidating = false
    @State private var validationResult: Result<Bool, Error>?
    
    var body: some View {
        VStack {
            Text("Import from Foundation Model")
                .font(.headline)
            
            TextEditor(text: $jsonText)
                .border(Color.gray)
                .frame(height: 300)
            
            Button("Validate JSON") {
                validateJSON()
            }
            
            Button("Import Data") {
                importJSON()
            }
            .disabled(validationResult == nil)
        }
    }
}
```

### 7. Documentation

#### API Documentation
**File**: `HealthKitDataGenerator/Documentation/API_GUIDE.md`

- Profile creation guide
- Configuration examples
- LLM integration guide
- Plugin development guide

#### LLM Integration Guide
**File**: `HealthKitDataGenerator/Documentation/LLM_INTEGRATION.md`

- JSON schema specification
- Example prompts for Foundation Model
- Validation rules
- Error handling

#### Examples
**File**: `HealthKitDataGenerator/Documentation/EXAMPLES.md`

```swift
// Example 1: Generate last week for sporty profile
let config = SampleGenerationConfig.lastWeekSporty()
let samples = try generator.generate(config: config)

// Example 2: Custom profile with specific metrics
let customProfile = HealthProfile(...)
let config = SampleGenerationConfig(
    profile: customProfile,
    dateRange: .lastDays(30),
    metricsToGenerate: [.steps, .heartRate, .sleepAnalysis]
)

// Example 3: Import from LLM JSON
let llmJSON = """
{
  "generation_config": { ... },
  "samples": [ ... ]
}
"""
try generator.importFromLLMJSON(llmJSON)
```

## Implementation Priority

1. **High Priority** (Week 1):
   - ✅ HealthProfile model
   - ✅ SampleGenerationConfig model
   - Refactor SampleDataGenerator to use config
   - Basic UI for profile selection

2. **Medium Priority** (Week 2):
   - LLM JSON schema
   - JSON import/export functionality
   - Date range and metric selectors in UI
   - Documentation

3. **Low Priority** (Week 3):
   - Plugin architecture
   - Advanced UI features
   - Additional preset profiles
   - Comprehensive examples

## Testing Strategy

1. **Unit Tests**:
   - Profile model tests
   - Config model tests
   - JSON serialization tests
   - Generator tests with different configs

2. **Integration Tests**:
   - End-to-end generation with profiles
   - LLM JSON import tests
   - UI interaction tests

3. **LLM Testing**:
   - Test with actual Foundation Model outputs
   - Validate schema compliance
   - Error handling for malformed JSON

## Git Branch Strategy

Current branch: `feature/app-renaming-and-ui-improvements`

Suggested new branches:
- `feature/profile-based-generation` - Core models and generator refactoring
- `feature/llm-integration` - LLM JSON schema and import
- `feature/ui-enhancements` - Profile selector and import UI
- `feature/plugin-architecture` - Extensibility framework

## Notes

- All new code should maintain backward compatibility
- Existing `generateSamples(_ numberOfDays:)` method should delegate to new config-based method
- JSON schema should be versioned for future extensibility
- UI should be accessible and follow iOS design guidelines
- Documentation should include examples for both programmatic and LLM usage

## Questions to Resolve

1. Should we support real-time generation (streaming) for long date ranges?
2. How should we handle conflicts between profile defaults and custom overrides?
3. Should we cache generated samples for reproducibility?
4. What's the maximum date range we should support?
5. Should we add validation for physiologically impossible values?

---

**Status**: In Progress
**Last Updated**: October 5, 2025
**Next Review**: After completing High Priority items
