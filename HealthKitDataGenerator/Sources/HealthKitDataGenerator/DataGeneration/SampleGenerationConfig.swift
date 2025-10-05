
import Foundation

/// Configuration for generating health samples
public struct SampleGenerationConfig: Codable {
    /// The health profile to use for generation
    public let profile: HealthProfile
    
    /// Date range for sample generation
    public let dateRange: DateRange
    
    /// Which metrics to generate
    public let metricsToGenerate: Set<HealthMetric>
    
    /// Generation pattern (continuous, sparse, etc.)
    public let pattern: GenerationPattern
    
    /// Random seed for reproducible generation
    public let randomSeed: Int?
    
    /// Custom overrides for specific metrics
    public let customOverrides: [String: MetricOverride]?
    
    public init(
        profile: HealthProfile,
        dateRange: DateRange,
        metricsToGenerate: Set<HealthMetric> = Set(HealthMetric.allCases),
        pattern: GenerationPattern = .continuous,
        randomSeed: Int? = nil,
        customOverrides: [String: MetricOverride]? = nil
    ) {
        self.profile = profile
        self.dateRange = dateRange
        self.metricsToGenerate = metricsToGenerate
        self.pattern = pattern
        self.randomSeed = randomSeed
        self.customOverrides = customOverrides
    }
}

// MARK: - Date Range

public struct DateRange: Codable {
    public let startDate: Date
    public let endDate: Date
    
    /// Number of days in the range
    public var numberOfDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return max(1, components.day ?? 1)
    }
    
    public init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
    
    /// Create a range for the last N days
    public static func lastDays(_ days: Int) -> DateRange {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -days, to: end)!
        return DateRange(startDate: start, endDate: end)
    }
    
    /// Create a range for a specific date
    public static func singleDay(_ date: Date) -> DateRange {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return DateRange(startDate: start, endDate: end)
    }
}

// MARK: - Health Metrics

public enum HealthMetric: String, Codable, CaseIterable, Hashable {
    case steps = "steps"
    case heartRate = "heart_rate"
    case heartRateVariability = "heart_rate_variability"
    case sleepAnalysis = "sleep_analysis"
    case workouts = "workouts"
    case activeEnergy = "active_energy"
    case basalEnergy = "basal_energy"
    case bloodPressure = "blood_pressure"
    case bloodGlucose = "blood_glucose"
    case bodyMass = "body_mass"
    case bodyFat = "body_fat"
    case leanBodyMass = "lean_body_mass"
    case water = "water"
    case mindfulMinutes = "mindful_minutes"
    case dietarySugar = "dietary_sugar"
    case dietaryProtein = "dietary_protein"
    case dietaryCarbs = "dietary_carbs"
    case dietaryFat = "dietary_fat"
    case respiratoryRate = "respiratory_rate"
    case oxygenSaturation = "oxygen_saturation"
    
    /// HealthKit identifier mapping
    public var healthKitIdentifier: String {
        switch self {
        case .steps: return "HKQuantityTypeIdentifierStepCount"
        case .heartRate: return "HKQuantityTypeIdentifierHeartRate"
        case .heartRateVariability: return "HKQuantityTypeIdentifierHeartRateVariabilitySDNN"
        case .sleepAnalysis: return "HKCategoryTypeIdentifierSleepAnalysis"
        case .workouts: return "HKWorkoutTypeIdentifier"
        case .activeEnergy: return "HKQuantityTypeIdentifierActiveEnergyBurned"
        case .basalEnergy: return "HKQuantityTypeIdentifierBasalEnergyBurned"
        case .bloodPressure: return "HKCorrelationTypeIdentifierBloodPressure"
        case .bloodGlucose: return "HKQuantityTypeIdentifierBloodGlucose"
        case .bodyMass: return "HKQuantityTypeIdentifierBodyMass"
        case .bodyFat: return "HKQuantityTypeIdentifierBodyFatPercentage"
        case .leanBodyMass: return "HKQuantityTypeIdentifierLeanBodyMass"
        case .water: return "HKQuantityTypeIdentifierDietaryWater"
        case .mindfulMinutes: return "HKCategoryTypeIdentifierMindfulSession"
        case .dietarySugar: return "HKQuantityTypeIdentifierDietarySugar"
        case .dietaryProtein: return "HKQuantityTypeIdentifierDietaryProtein"
        case .dietaryCarbs: return "HKQuantityTypeIdentifierDietaryCarbohydrates"
        case .dietaryFat: return "HKQuantityTypeIdentifierDietaryFatTotal"
        case .respiratoryRate: return "HKQuantityTypeIdentifierRespiratoryRate"
        case .oxygenSaturation: return "HKQuantityTypeIdentifierOxygenSaturation"
        }
    }
}

// MARK: - Generation Pattern

public enum GenerationPattern: String, Codable {
    /// Generate samples for every day in the range
    case continuous = "continuous"
    
    /// Generate samples with random gaps
    case sparse = "sparse"
    
    /// Generate samples only on weekdays
    case weekdaysOnly = "weekdays_only"
    
    /// Generate samples only on weekends
    case weekendsOnly = "weekends_only"
    
    /// Custom pattern with specific days
    case custom = "custom"
    
    /// Should generate data for this day?
    public func shouldGenerateForDay(_ date: Date, customDays: Set<Int>? = nil) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        switch self {
        case .continuous:
            return true
        case .sparse:
            return Int.random(in: 0...100) > 30 // 70% chance
        case .weekdaysOnly:
            return weekday >= 2 && weekday <= 6 // Monday-Friday
        case .weekendsOnly:
            return weekday == 1 || weekday == 7 // Saturday-Sunday
        case .custom:
            let dayOfMonth = calendar.component(.day, from: date)
            return customDays?.contains(dayOfMonth) ?? true
        }
    }
}

// MARK: - Metric Override

public struct MetricOverride: Codable {
    public let multiplier: Double?
    public let fixedValue: Double?
    public let variability: Double? // 0.0-1.0
    
    public init(multiplier: Double? = nil, fixedValue: Double? = nil, variability: Double? = nil) {
        self.multiplier = multiplier
        self.fixedValue = fixedValue
        self.variability = variability
    }
}

// MARK: - Preset Configurations

extension SampleGenerationConfig {
    /// Last 7 days with sporty profile
    public static func lastWeekSporty() -> SampleGenerationConfig {
        return SampleGenerationConfig(
            profile: .sporty,
            dateRange: .lastDays(7)
        )
    }
    
    /// Last 30 days with balanced profile
    public static func lastMonthBalanced() -> SampleGenerationConfig {
        return SampleGenerationConfig(
            profile: .balanced,
            dateRange: .lastDays(30)
        )
    }
    
    /// Last 7 days with stressed profile
    public static func lastWeekStressed() -> SampleGenerationConfig {
        return SampleGenerationConfig(
            profile: .stressed,
            dateRange: .lastDays(7)
        )
    }
    
    /// Custom configuration from JSON (for LLM integration)
    public static func fromJSON(_ jsonString: String) throws -> SampleGenerationConfig {
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SampleGenerationConfig.self, from: data)
    }
    
    /// Export configuration to JSON (for LLM integration)
    public func toJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8)!
    }
}

