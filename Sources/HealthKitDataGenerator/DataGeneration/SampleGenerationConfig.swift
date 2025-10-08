
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
    public static func lastDays(_ days: UInt) -> DateRange {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: min(0, -Int(days)), to: end)!
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

public enum GenerationPattern: String, Codable, CaseIterable {
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
    public let enabled: Bool?
    public let customRange: ClosedRangeWrapper?
    public let timePattern: TimePattern?
    
    public init(
        multiplier: Double? = nil,
        fixedValue: Double? = nil,
        variability: Double? = nil,
        enabled: Bool? = nil,
        customRange: ClosedRangeWrapper? = nil,
        timePattern: TimePattern? = nil
    ) {
        self.multiplier = multiplier
        self.fixedValue = fixedValue
        self.variability = variability
        self.enabled = enabled
        self.customRange = customRange
        self.timePattern = timePattern
    }
}

/// Wrapper for ClosedRange to make it Codable
public struct ClosedRangeWrapper: Codable {
    public let lowerBound: Double
    public let upperBound: Double
    
    public init(lowerBound: Double, upperBound: Double) {
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }
    
    public init(_ range: ClosedRange<Double>) {
        self.lowerBound = range.lowerBound
        self.upperBound = range.upperBound
    }
    
    public var range: ClosedRange<Double> {
        return lowerBound...upperBound
    }
}

/// Time patterns for metric generation
public enum TimePattern: String, Codable {
    case constant = "constant"
    case morningPeak = "morning_peak"
    case middayPeak = "midday_peak"
    case eveningPeak = "evening_peak"
    case nightPeak = "night_peak"
    
    /// Get multiplier for given hour (0-23)
    public func multiplier(for hour: Int) -> Double {
        switch self {
        case .constant:
            return 1.0
        case .morningPeak: // Peak at 6-10 AM
            if hour >= 6 && hour <= 10 {
                return 1.5
            } else if hour >= 4 && hour <= 12 {
                return 1.2
            }
            return 0.8
        case .middayPeak: // Peak at 11 AM - 2 PM
            if hour >= 11 && hour <= 14 {
                return 1.5
            } else if hour >= 9 && hour <= 16 {
                return 1.2
            }
            return 0.8
        case .eveningPeak: // Peak at 5-9 PM
            if hour >= 17 && hour <= 21 {
                return 1.5
            } else if hour >= 15 && hour <= 23 {
                return 1.2
            }
            return 0.8
        case .nightPeak: // Peak at 10 PM - 2 AM
            if hour >= 22 || hour <= 2 {
                return 1.5
            } else if hour >= 20 || hour <= 4 {
                return 1.2
            }
            return 0.8
        }
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

// MARK: - Enhanced Date Range Types

extension DateRange {
    /// Create a range for specific dates only
    public static func specificDates(_ dates: [Date]) -> DateRange {
        guard let start = dates.min(), let end = dates.max() else {
            return DateRange(startDate: Date(), endDate: Date())
        }
        return DateRange(startDate: start, endDate: end)
    }
    
    /// Create a range with excluded dates (gaps)
    public static func rangeWithGaps(start: Date, end: Date, excludeDates: [Date]) -> DateRange {
        return DateRange(startDate: start, endDate: end)
    }
    
    /// Create a range for weekdays only
    public static func weekdaysOnly(start: Date, end: Date) -> DateRange {
        return DateRange(startDate: start, endDate: end)
    }
    
    /// Create a range for weekends only
    public static func weekendsOnly(start: Date, end: Date) -> DateRange {
        return DateRange(startDate: start, endDate: end)
    }
    
    /// Create a range for this week
    public static func thisWeek() -> DateRange {
        let calendar = Calendar.current
        let now = Date()
        // Last 7 days (rolling week, consistent with LLM provider)
        let weekStart = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        return DateRange(startDate: weekStart, endDate: now)
    }
    
    /// Create a range for this month
    public static func thisMonth() -> DateRange {
        let calendar = Calendar.current
        let now = Date()
        // Last 30 days (rolling month, consistent with LLM provider)
        let monthStart = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        return DateRange(startDate: monthStart, endDate: now)
    }
}

// MARK: - Enhanced Generation Patterns

extension GenerationPattern {
    /// Create a sparse pattern with custom probability
    public static func sparseWithProbability(_ probability: Double) -> GenerationPattern {
        return .sparse // Will be enhanced in shouldGenerateForDay
    }
    
    /// Check if should generate for day with custom probability
    public func shouldGenerateForDay(_ date: Date, customDays: Set<Int>? = nil, sparseProbability: Double = 0.7) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        switch self {
        case .continuous:
            return true
        case .sparse:
            return Double.random(in: 0...1) < sparseProbability
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

// MARK: - Advanced Generation Patterns

/// Advanced patterns for more realistic data generation
public enum AdvancedPattern: String, Codable {
    /// Generate with custom probability (0.0-1.0)
    case sparseCustom = "sparse_custom"
    
    /// More data in specific months
    case seasonal = "seasonal"
    
    /// Gradual increase/decrease over time
    case progressive = "progressive"
    
    /// Every Nth day
    case everyNthDay = "every_nth_day"
    
    /// Cyclical pattern (weekly, monthly)
    case cyclical = "cyclical"
}

/// Configuration for advanced patterns
public struct AdvancedPatternConfig: Codable {
    public let pattern: AdvancedPattern
    public let sparseProbability: Double?
    public let peakMonths: [Int]?
    public let startMultiplier: Double?
    public let endMultiplier: Double?
    public let interval: Int?
    public let cyclePeriod: Int?
    
    public init(
        pattern: AdvancedPattern,
        sparseProbability: Double? = nil,
        peakMonths: [Int]? = nil,
        startMultiplier: Double? = nil,
        endMultiplier: Double? = nil,
        interval: Int? = nil,
        cyclePeriod: Int? = nil
    ) {
        self.pattern = pattern
        self.sparseProbability = sparseProbability
        self.peakMonths = peakMonths
        self.startMultiplier = startMultiplier
        self.endMultiplier = endMultiplier
        self.interval = interval
        self.cyclePeriod = cyclePeriod
    }
    
    /// Check if should generate for day based on advanced pattern
    public func shouldGenerateForDay(_ date: Date, totalDays: Int, currentDay: Int) -> Bool {
        let calendar = Calendar.current
        
        switch pattern {
        case .sparseCustom:
            let probability = sparseProbability ?? 0.7
            return Double.random(in: 0...1) < probability
            
        case .seasonal:
            let month = calendar.component(.month, from: date)
            if let peaks = peakMonths {
                return peaks.contains(month)
            }
            return true
            
        case .progressive:
            // Always generate, but multiplier changes over time
            return true
            
        case .everyNthDay:
            let dayInterval = interval ?? 2
            return currentDay % dayInterval == 0
            
        case .cyclical:
            let period = cyclePeriod ?? 7
            return currentDay % period < period / 2
        }
    }
    
    /// Get multiplier for this day (for progressive patterns)
    public func getMultiplier(for currentDay: Int, totalDays: Int) -> Double {
        guard pattern == .progressive else { return 1.0 }
        
        let start = startMultiplier ?? 1.0
        let end = endMultiplier ?? 1.0
        let progress = Double(currentDay) / Double(max(1, totalDays))
        
        return start + (end - start) * progress
    }
}

