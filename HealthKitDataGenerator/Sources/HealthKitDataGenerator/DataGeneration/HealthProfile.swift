
import Foundation

/// Represents a health profile persona with characteristic patterns
public struct HealthProfile: Codable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let description: String
    
    // Activity patterns
    public let dailyStepsRange: ClosedRange<Int>
    public let workoutFrequency: WorkoutFrequency
    public let preferredWorkoutTypes: [WorkoutType]
    
    // Sleep patterns
    public let sleepDurationRange: ClosedRange<TimeInterval> // in hours
    public let sleepQuality: SleepQuality
    public let bedtimeRange: ClosedRange<Int> // hour of day (0-23)
    
    // Heart rate patterns
    public let restingHeartRateRange: ClosedRange<Int>
    public let maxHeartRateRange: ClosedRange<Int>
    public let heartRateVariability: HeartRateVariability
    
    // Energy and calories
    public let basalEnergyMultiplier: Double // 0.8-1.2 (below/above average)
    public let activeEnergyRange: ClosedRange<Int>
    
    // Stress and recovery
    public let stressLevel: StressLevel
    public let recoveryRate: RecoveryRate
    
    // Nutrition
    public let dietaryPattern: DietaryPattern
    public let hydrationLevel: HydrationLevel
    
    public init(
        id: String,
        name: String,
        description: String,
        dailyStepsRange: ClosedRange<Int>,
        workoutFrequency: WorkoutFrequency,
        preferredWorkoutTypes: [WorkoutType],
        sleepDurationRange: ClosedRange<TimeInterval>,
        sleepQuality: SleepQuality,
        bedtimeRange: ClosedRange<Int>,
        restingHeartRateRange: ClosedRange<Int>,
        maxHeartRateRange: ClosedRange<Int>,
        heartRateVariability: HeartRateVariability,
        basalEnergyMultiplier: Double,
        activeEnergyRange: ClosedRange<Int>,
        stressLevel: StressLevel,
        recoveryRate: RecoveryRate,
        dietaryPattern: DietaryPattern,
        hydrationLevel: HydrationLevel
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.dailyStepsRange = dailyStepsRange
        self.workoutFrequency = workoutFrequency
        self.preferredWorkoutTypes = preferredWorkoutTypes
        self.sleepDurationRange = sleepDurationRange
        self.sleepQuality = sleepQuality
        self.bedtimeRange = bedtimeRange
        self.restingHeartRateRange = restingHeartRateRange
        self.maxHeartRateRange = maxHeartRateRange
        self.heartRateVariability = heartRateVariability
        self.basalEnergyMultiplier = basalEnergyMultiplier
        self.activeEnergyRange = activeEnergyRange
        self.stressLevel = stressLevel
        self.recoveryRate = recoveryRate
        self.dietaryPattern = dietaryPattern
        self.hydrationLevel = hydrationLevel
    }
}

// MARK: - Supporting Types

public enum WorkoutFrequency: String, Codable {
    case sedentary = "sedentary"           // 0-1 times per week
    case light = "light"                   // 2-3 times per week
    case moderate = "moderate"             // 4-5 times per week
    case active = "active"                 // 6-7 times per week
    case athlete = "athlete"               // Multiple times per day
    
    public var sessionsPerWeek: ClosedRange<Int> {
        switch self {
        case .sedentary: return 0...1
        case .light: return 2...3
        case .moderate: return 4...5
        case .active: return 6...7
        case .athlete: return 7...14
        }
    }
}

public enum WorkoutType: String, Codable {
    case running = "running"
    case cycling = "cycling"
    case swimming = "swimming"
    case walking = "walking"
    case yoga = "yoga"
    case strengthTraining = "strength_training"
    case hiit = "hiit"
    case pilates = "pilates"
    case dancing = "dancing"
    case sports = "sports"
}

public enum SleepQuality: String, Codable {
    case poor = "poor"
    case fair = "fair"
    case good = "good"
    case excellent = "excellent"
    
    public var deepSleepPercentage: ClosedRange<Double> {
        switch self {
        case .poor: return 0.10...0.15
        case .fair: return 0.15...0.20
        case .good: return 0.20...0.25
        case .excellent: return 0.25...0.30
        }
    }
}

public enum HeartRateVariability: String, Codable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    
    public var variabilityRange: ClosedRange<Int> {
        switch self {
        case .low: return 20...40
        case .moderate: return 40...60
        case .high: return 60...100
        }
    }
}

public enum StressLevel: String, Codable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case veryHigh = "very_high"
}

public enum RecoveryRate: String, Codable {
    case slow = "slow"
    case average = "average"
    case fast = "fast"
}

public enum DietaryPattern: String, Codable {
    case standard = "standard"
    case vegetarian = "vegetarian"
    case vegan = "vegan"
    case keto = "keto"
    case mediterranean = "mediterranean"
    case highProtein = "high_protein"
}

public enum HydrationLevel: String, Codable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
}

// MARK: - Preset Profiles

extension HealthProfile {
    /// Athletic profile: High activity, excellent recovery
    public static let sporty = HealthProfile(
        id: "sporty",
        name: "Athletic",
        description: "Active lifestyle with regular intense workouts and excellent recovery",
        dailyStepsRange: 12000...18000,
        workoutFrequency: .active,
        preferredWorkoutTypes: [.running, .cycling, .strengthTraining, .hiit],
        sleepDurationRange: 7.5...9.0,
        sleepQuality: .excellent,
        bedtimeRange: 22...23,
        restingHeartRateRange: 45...55,
        maxHeartRateRange: 180...195,
        heartRateVariability: .high,
        basalEnergyMultiplier: 1.1,
        activeEnergyRange: 600...1200,
        stressLevel: .low,
        recoveryRate: .fast,
        dietaryPattern: .highProtein,
        hydrationLevel: .high
    )
    
    /// Stressed profile: High stress, poor sleep, irregular activity
    public static let stressed = HealthProfile(
        id: "stressed",
        name: "Stressed Professional",
        description: "High stress levels with irregular sleep and activity patterns",
        dailyStepsRange: 3000...7000,
        workoutFrequency: .light,
        preferredWorkoutTypes: [.walking, .yoga],
        sleepDurationRange: 5.0...6.5,
        sleepQuality: .poor,
        bedtimeRange: 0...2,
        restingHeartRateRange: 70...85,
        maxHeartRateRange: 170...185,
        heartRateVariability: .low,
        basalEnergyMultiplier: 0.95,
        activeEnergyRange: 200...500,
        stressLevel: .veryHigh,
        recoveryRate: .slow,
        dietaryPattern: .standard,
        hydrationLevel: .low
    )
    
    /// Balanced profile: Moderate activity, good sleep, healthy lifestyle
    public static let balanced = HealthProfile(
        id: "balanced",
        name: "Balanced Lifestyle",
        description: "Well-rounded healthy lifestyle with consistent patterns",
        dailyStepsRange: 8000...12000,
        workoutFrequency: .moderate,
        preferredWorkoutTypes: [.walking, .yoga, .cycling, .swimming],
        sleepDurationRange: 7.0...8.5,
        sleepQuality: .good,
        bedtimeRange: 22...24,
        restingHeartRateRange: 60...70,
        maxHeartRateRange: 170...185,
        heartRateVariability: .moderate,
        basalEnergyMultiplier: 1.0,
        activeEnergyRange: 400...800,
        stressLevel: .moderate,
        recoveryRate: .average,
        dietaryPattern: .mediterranean,
        hydrationLevel: .moderate
    )
    
    /// Sedentary profile: Low activity, average sleep
    public static let sedentary = HealthProfile(
        id: "sedentary",
        name: "Sedentary",
        description: "Low activity levels with minimal exercise",
        dailyStepsRange: 2000...5000,
        workoutFrequency: .sedentary,
        preferredWorkoutTypes: [.walking],
        sleepDurationRange: 6.5...8.0,
        sleepQuality: .fair,
        bedtimeRange: 23...25,
        restingHeartRateRange: 70...80,
        maxHeartRateRange: 160...175,
        heartRateVariability: .low,
        basalEnergyMultiplier: 0.9,
        activeEnergyRange: 100...300,
        stressLevel: .moderate,
        recoveryRate: .slow,
        dietaryPattern: .standard,
        hydrationLevel: .low
    )
    
    /// All available presets
    public static let allPresets: [HealthProfile] = [
        .sporty,
        .stressed,
        .balanced,
        .sedentary
    ]
    
    /// Get preset by ID
    public static func preset(withId id: String) -> HealthProfile? {
        return allPresets.first { $0.id == id }
    }
}

