# LLM JSON Schema for HealthKit Data Generation

## Overview

This document defines the JSON schema that Large Language Models (like Apple Foundation Model) can generate to create health data. The schema supports both configuration-based generation and direct sample specification.

## Schema Version

Current version: `1.0`

## Top-Level Structure

```json
{
  "schema_version": "1.0",
  "generation_config": { ... },
  "samples": [ ... ] // Optional: direct sample specification
}
```

## Generation Config Schema

### Complete Example

```json
{
  "schema_version": "1.0",
  "generation_config": {
    "profile": {
      "id": "marathon_trainer",
      "name": "Marathon Trainer",
      "description": "Training for marathon with high mileage",
      "dailyStepsRange": {
        "lowerBound": 15000,
        "upperBound": 25000
      },
      "workoutFrequency": "active",
      "preferredWorkoutTypes": ["running", "cycling", "yoga"],
      "sleepDurationRange": {
        "lowerBound": 7.5,
        "upperBound": 9.0
      },
      "sleepQuality": "good",
      "bedtimeRange": {
        "lowerBound": 22,
        "upperBound": 23
      },
      "restingHeartRateRange": {
        "lowerBound": 45,
        "upperBound": 55
      },
      "maxHeartRateRange": {
        "lowerBound": 180,
        "upperBound": 195
      },
      "heartRateVariability": "high",
      "basalEnergyMultiplier": 1.1,
      "activeEnergyRange": {
        "lowerBound": 800,
        "upperBound": 1500
      },
      "stressLevel": "moderate",
      "recoveryRate": "fast",
      "dietaryPattern": "high_protein",
      "hydrationLevel": "high"
    },
    "dateRange": {
      "startDate": "2025-01-01T00:00:00Z",
      "endDate": "2025-01-07T23:59:59Z"
    },
    "metricsToGenerate": [
      "steps",
      "heart_rate",
      "workouts",
      "sleep_analysis",
      "active_energy",
      "basal_energy"
    ],
    "pattern": "continuous",
    "randomSeed": 42,
    "customOverrides": {
      "steps": {
        "multiplier": 1.2,
        "variability": 0.3
      }
    },
    "advancedPattern": {
      "type": "seasonal",
      "peakMonths": [6, 7, 8],
      "sparseProbability": 0.7,
      "startMultiplier": 0.8,
      "endMultiplier": 1.2,
      "interval": 2,
      "cyclePeriod": 7
    }
  }
}
```

## Field Definitions

### Profile Fields

| Field | Type | Required | Values | Description |
|-------|------|----------|--------|-------------|
| `id` | string | Yes | Any unique string | Profile identifier |
| `name` | string | Yes | Any string | Human-readable name |
| `description` | string | Yes | Any string | Profile description |
| `dailyStepsRange` | Range | Yes | 0-50000 | Daily step count range |
| `workoutFrequency` | enum | Yes | `sedentary`, `light`, `moderate`, `active`, `athlete` | Workout frequency |
| `preferredWorkoutTypes` | array | Yes | See workout types | Preferred workout types |
| `sleepDurationRange` | Range | Yes | 4.0-12.0 hours | Sleep duration range |
| `sleepQuality` | enum | Yes | `poor`, `fair`, `good`, `excellent` | Sleep quality |
| `bedtimeRange` | Range | Yes | 0-23 hours | Bedtime hour range |
| `restingHeartRateRange` | Range | Yes | 40-100 bpm | Resting heart rate |
| `maxHeartRateRange` | Range | Yes | 120-220 bpm | Max heart rate |
| `heartRateVariability` | enum | Yes | `low`, `moderate`, `high` | HRV level |
| `basalEnergyMultiplier` | number | Yes | 0.5-1.5 | Basal energy multiplier |
| `activeEnergyRange` | Range | Yes | 0-3000 kcal | Active energy range |
| `stressLevel` | enum | Yes | `low`, `moderate`, `high`, `very_high` | Stress level |
| `recoveryRate` | enum | Yes | `slow`, `average`, `fast` | Recovery rate |
| `dietaryPattern` | enum | Yes | See dietary patterns | Diet type |
| `hydrationLevel` | enum | Yes | `low`, `moderate`, `high` | Hydration level |

### Workout Types

- `running`
- `cycling`
- `swimming`
- `walking`
- `yoga`
- `strength_training`
- `hiit`
- `pilates`
- `dancing`
- `sports`

### Dietary Patterns

- `standard`
- `vegetarian`
- `vegan`
- `keto`
- `mediterranean`
- `high_protein`

### Metrics to Generate

All available metrics:
- `steps`
- `heart_rate`
- `heart_rate_variability`
- `sleep_analysis`
- `workouts`
- `active_energy`
- `basal_energy`
- `blood_pressure`
- `blood_glucose`
- `body_mass`
- `body_fat`
- `lean_body_mass`
- `water`
- `mindful_minutes`
- `dietary_sugar`
- `dietary_protein`
- `dietary_carbs`
- `dietary_fat`
- `respiratory_rate`
- `oxygen_saturation`

### Generation Patterns

- `continuous` - Generate for every day
- `sparse` - Generate with random gaps (70% coverage)
- `weekdays_only` - Monday-Friday only
- `weekends_only` - Saturday-Sunday only
- `custom` - Custom day selection

### Enhanced Date Range Types

- `last_days` - Last N days (requires `days` field)
- `this_week` - Current week (Monday-Sunday)
- `this_month` - Current month
- `weekdays_only` - Weekdays only in date range
- `weekends_only` - Weekends only in date range
- `specific_dates` - Specific dates only

### Advanced Patterns

- `sparse_custom` - Custom probability (0.0-1.0)
- `seasonal` - More data in specific months
- `progressive` - Gradual increase/decrease over time
- `every_nth_day` - Every 2nd, 3rd, etc. day
- `cyclical` - Weekly/monthly cycles

### Enhanced Metric Overrides

- `multiplier` - Multiply profile values
- `fixedValue` - Use fixed value instead
- `variability` - Randomness (0.0-1.0)
- `enabled` - Turn metric on/off
- `customRange` - Override profile range
- `timePattern` - When during day metric peaks

## Direct Sample Specification

You can also specify samples directly instead of using generation config:

```json
{
  "schema_version": "1.0",
  "samples": [
    {
      "type": "HKQuantityTypeIdentifierStepCount",
      "date": "2025-01-01T10:30:00Z",
      "value": 15234,
      "unit": "count"
    },
    {
      "type": "HKQuantityTypeIdentifierHeartRate",
      "date": "2025-01-01T10:30:00Z",
      "value": 72,
      "unit": "count/min"
    },
    {
      "type": "HKWorkoutTypeIdentifier",
      "startDate": "2025-01-01T07:00:00Z",
      "endDate": "2025-01-01T08:00:00Z",
      "workoutActivityType": 37,
      "duration": 3600,
      "totalDistance": 10000,
      "totalEnergyBurned": 450
    },
    {
      "type": "HKCategoryTypeIdentifierSleepAnalysis",
      "startDate": "2025-01-01T23:00:00Z",
      "endDate": "2025-01-02T07:00:00Z",
      "value": 0
    }
  ]
}
```

## Example Prompts for Foundation Model

### Example 1: Generate Training Week

**Prompt**:
```
Generate a week of health data for a marathon runner who is in peak training. 
They run 6 days a week, average 50-70 miles per week, have excellent sleep, 
and maintain a high-protein diet. Start from January 1, 2025.
```

**Expected JSON Output**:
```json
{
  "schema_version": "1.0",
  "generation_config": {
    "profile": {
      "id": "marathon_peak_training",
      "name": "Marathon Peak Training",
      "description": "Peak marathon training phase",
      "dailyStepsRange": {"lowerBound": 18000, "upperBound": 30000},
      "workoutFrequency": "active",
      "preferredWorkoutTypes": ["running", "yoga"],
      "sleepDurationRange": {"lowerBound": 8.0, "upperBound": 9.5},
      "sleepQuality": "excellent",
      "bedtimeRange": {"lowerBound": 21, "upperBound": 22},
      "restingHeartRateRange": {"lowerBound": 42, "upperBound": 50},
      "maxHeartRateRange": {"lowerBound": 185, "upperBound": 200},
      "heartRateVariability": "high",
      "basalEnergyMultiplier": 1.15,
      "activeEnergyRange": {"lowerBound": 1000, "upperBound": 1800},
      "stressLevel": "moderate",
      "recoveryRate": "fast",
      "dietaryPattern": "high_protein",
      "hydrationLevel": "high"
    },
    "dateRange": {
      "startDate": "2025-01-01T00:00:00Z",
      "endDate": "2025-01-07T23:59:59Z"
    },
    "metricsToGenerate": [
      "steps", "heart_rate", "workouts", "sleep_analysis", 
      "active_energy", "basal_energy", "water"
    ],
    "pattern": "continuous"
  }
}
```

### Example 2: Stressed Professional

**Prompt**:
```
Create health data for a stressed software engineer working long hours. 
Poor sleep (5-6 hours), high stress, minimal exercise, irregular eating.
Generate data for the past 2 weeks.
```

**Expected JSON Output**:
```json
{
  "schema_version": "1.0",
  "generation_config": {
    "profile": {
      "id": "stressed_engineer",
      "name": "Stressed Software Engineer",
      "description": "High stress, poor work-life balance",
      "dailyStepsRange": {"lowerBound": 2000, "upperBound": 5000},
      "workoutFrequency": "sedentary",
      "preferredWorkoutTypes": ["walking"],
      "sleepDurationRange": {"lowerBound": 5.0, "upperBound": 6.5},
      "sleepQuality": "poor",
      "bedtimeRange": {"lowerBound": 1, "upperBound": 3},
      "restingHeartRateRange": {"lowerBound": 75, "upperBound": 90},
      "maxHeartRateRange": {"lowerBound": 165, "upperBound": 180},
      "heartRateVariability": "low",
      "basalEnergyMultiplier": 0.95,
      "activeEnergyRange": {"lowerBound": 150, "upperBound": 400},
      "stressLevel": "very_high",
      "recoveryRate": "slow",
      "dietaryPattern": "standard",
      "hydrationLevel": "low"
    },
    "dateRange": {
      "startDate": "2024-12-22T00:00:00Z",
      "endDate": "2025-01-05T23:59:59Z"
    },
    "metricsToGenerate": [
      "steps", "heart_rate", "sleep_analysis", "mindful_minutes"
    ],
    "pattern": "continuous"
  }
}
```

## Validation Rules

1. **Date Ranges**: `endDate` must be after `startDate`
2. **Numeric Ranges**: `lowerBound` must be ≤ `upperBound`
3. **Heart Rate**: Resting HR < Max HR
4. **Sleep Duration**: 4.0 ≤ hours ≤ 12.0
5. **Bedtime**: 0 ≤ hour ≤ 23
6. **Energy Multiplier**: 0.5 ≤ multiplier ≤ 1.5
7. **ISO 8601 Dates**: All dates must be valid ISO 8601 format

## Apple Foundation Model Integration

### Natural Language to JSON Conversion

The schema is designed to work seamlessly with Apple Foundation Model for natural language processing:

#### Example 1: Marathon Training
**Natural Language Input:**
```
"Create health data for a marathon runner in peak training. They run 6 days a week, average 50-70 miles per week, have excellent sleep, and maintain a high-protein diet. Start from January 1, 2025."
```

**Foundation Model Output:**
```json
{
  "schema_version": "1.0",
  "generation_config": {
    "profile": {
      "id": "marathon_peak_training",
      "name": "Marathon Peak Training",
      "description": "Peak marathon training phase",
      "dailyStepsRange": {"lowerBound": 18000, "upperBound": 30000},
      "workoutFrequency": "active",
      "preferredWorkoutTypes": ["running", "yoga"],
      "sleepDurationRange": {"lowerBound": 8.0, "upperBound": 9.5},
      "sleepQuality": "excellent",
      "bedtimeRange": {"lowerBound": 21, "upperBound": 22},
      "restingHeartRateRange": {"lowerBound": 42, "upperBound": 50},
      "maxHeartRateRange": {"lowerBound": 185, "upperBound": 200},
      "heartRateVariability": "high",
      "basalEnergyMultiplier": 1.15,
      "activeEnergyRange": {"lowerBound": 1000, "upperBound": 1800},
      "stressLevel": "moderate",
      "recoveryRate": "fast",
      "dietaryPattern": "high_protein",
      "hydrationLevel": "high"
    },
    "dateRange": {
      "type": "last_days",
      "startDate": "2025-01-01T00:00:00Z",
      "endDate": "2025-01-07T23:59:59Z",
      "days": 7
    },
    "metricsToGenerate": [
      "steps", "heart_rate", "workouts", "sleep_analysis", 
      "active_energy", "basal_energy", "water"
    ],
    "pattern": "continuous",
    "advancedPattern": {
      "type": "progressive",
      "startMultiplier": 0.8,
      "endMultiplier": 1.2
    },
    "customOverrides": {
      "steps": {
        "timePattern": "morning_peak",
        "multiplier": 1.2
      }
    }
  }
}
```

#### Example 2: Recovery Week
**Natural Language Input:**
```
"Generate a recovery week for an athlete. Reduced activity, more sleep, no intense workouts, focus on gentle movement."
```

**Foundation Model Output:**
```json
{
  "schema_version": "1.0",
  "generation_config": {
    "profile": {
      "id": "recovery_athlete",
      "name": "Recovery Athlete",
      "description": "Athlete in recovery phase",
      "dailyStepsRange": {"lowerBound": 5000, "upperBound": 8000},
      "workoutFrequency": "light",
      "preferredWorkoutTypes": ["walking", "yoga"],
      "sleepDurationRange": {"lowerBound": 8.5, "upperBound": 10.0},
      "sleepQuality": "excellent",
      "bedtimeRange": {"lowerBound": 21, "upperBound": 22},
      "restingHeartRateRange": {"lowerBound": 50, "upperBound": 60},
      "maxHeartRateRange": {"lowerBound": 160, "upperBound": 175},
      "heartRateVariability": "high",
      "basalEnergyMultiplier": 1.0,
      "activeEnergyRange": {"lowerBound": 200, "upperBound": 400},
      "stressLevel": "low",
      "recoveryRate": "fast",
      "dietaryPattern": "mediterranean",
      "hydrationLevel": "high"
    },
    "dateRange": {
      "type": "last_days",
      "startDate": "2025-01-01T00:00:00Z",
      "endDate": "2025-01-07T23:59:59Z",
      "days": 7
    },
    "metricsToGenerate": [
      "steps", "heart_rate", "sleep_analysis", "mindful_minutes"
    ],
    "pattern": "continuous",
    "customOverrides": {
      "workouts": {
        "enabled": false
      },
      "active_energy": {
        "multiplier": 0.3
      },
      "sleep_analysis": {
        "customRange": {"lowerBound": 8.5, "upperBound": 10.0}
      }
    }
  }
}
```

### Foundation Model Prompt Templates

#### Training Program Template
```
"Create health data for [persona] training for [event]. 
- Duration: [timeframe]
- Activity level: [intensity]
- Focus: [specific goals]
- Constraints: [limitations]"
```

#### Seasonal Pattern Template
```
"Generate [timeframe] of health data for [persona] with [seasonal pattern].
- Peak months: [months]
- Activity focus: [activities]
- Sleep pattern: [sleep description]"
```

#### Recovery Template
```
"Create recovery data for [persona] after [event/injury].
- Duration: [timeframe]
- Activity reduction: [percentage]
- Focus: [recovery activities]
- Sleep priority: [sleep emphasis]"
```

## Error Handling

### Invalid JSON Structure
```json
{
  "error": "invalid_schema",
  "message": "Missing required field: profile.dailyStepsRange",
  "field": "profile.dailyStepsRange"
}
```

### Invalid Values
```json
{
  "error": "invalid_value",
  "message": "restingHeartRateRange.lowerBound (120) exceeds maximum allowed (100)",
  "field": "profile.restingHeartRateRange.lowerBound",
  "value": 120,
  "allowed_range": "40-100"
}
```

### Physiologically Impossible
```json
{
  "error": "physiologically_impossible",
  "message": "Resting heart rate (90) is higher than max heart rate (85)",
  "fields": ["restingHeartRateRange", "maxHeartRateRange"]
}
```

## Best Practices for LLM Generation

1. **Be Specific**: Include specific numeric ranges based on the persona
2. **Consider Correlations**: High activity should correlate with higher calorie burn
3. **Realistic Patterns**: Sleep quality should align with stress levels
4. **Temporal Consistency**: Don't generate impossible sequences (e.g., workout during sleep)
5. **Use Presets**: When possible, reference preset profiles and customize

## Integration Example

```swift
// In your app
let llmResponse = """
{
  "schema_version": "1.0",
  "generation_config": { ... }
}
"""

do {
    let config = try SampleGenerationConfig.fromJSON(llmResponse)
    let generator = HealthKitDataGenerator(healthStore: healthStore)
    let samples = try generator.generate(config: config)
    try generator.populate(samplesTypes: shareTypes, generatedSamples: samples)
} catch {
    print("Failed to import LLM data: \(error)")
}
```

## Version History

- **1.0** (2025-01-05): Initial schema definition

---

For questions or suggestions, please open an issue on GitHub.
