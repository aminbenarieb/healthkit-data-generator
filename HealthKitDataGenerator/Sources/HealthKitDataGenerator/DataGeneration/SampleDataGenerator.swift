
import Foundation
import HealthKit

/// Generates realistic sample health data using configuration profiles
public class SampleDataGenerator {
    
    // MARK: - Public Methods
    
    /// Generates sample health data based on configuration
    /// - Parameter config: Configuration specifying profile, date range, and metrics
    /// - Returns: Dictionary containing generated sample data
    public static func generateSamples(config: SampleGenerationConfig) -> [String: Any] {
        var result: [String: Any] = [:]
        let calendar = Calendar.current
        
        // Set random seed if provided for reproducibility
        if let seed = config.randomSeed {
            srand48(seed)
        }
        
        // Generate samples for each day in the range
        for dayOffset in 0..<config.dateRange.numberOfDays {
            guard let dayDate = calendar.date(byAdding: .day, value: -dayOffset, to: config.dateRange.endDate) else {
                continue
            }
            
            // Check if we should generate for this day based on pattern
            guard config.pattern.shouldGenerateForDay(dayDate) else {
                continue
            }
            
            // Generate each requested metric
            for metric in config.metricsToGenerate {
                let samples = generateMetric(
                    metric,
                    for: dayDate,
                    profile: config.profile,
                    config: config
                )
                
                let key = metric.healthKitIdentifier
                if var existing = result[key] as? [[String: Any]] {
                    existing.append(contentsOf: samples)
                    result[key] = existing
                } else {
                    result[key] = samples
                }
            }
        }
        
        return result
    }
    
    // MARK: - Metric Generation
    
    private static func generateMetric(
        _ metric: HealthMetric,
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        switch metric {
        case .steps:
            return generateSteps(for: date, profile: profile, config: config)
        case .heartRate:
            return generateHeartRate(for: date, profile: profile, config: config)
        case .heartRateVariability:
            return generateHRV(for: date, profile: profile, config: config)
        case .sleepAnalysis:
            return generateSleep(for: date, profile: profile, config: config)
        case .workouts:
            return generateWorkouts(for: date, profile: profile, config: config)
        case .activeEnergy:
            return generateActiveEnergy(for: date, profile: profile, config: config)
        case .basalEnergy:
            return generateBasalEnergy(for: date, profile: profile, config: config)
        case .bloodPressure:
            return generateBloodPressure(for: date, profile: profile, config: config)
        case .bodyMass:
            return generateBodyMass(for: date, profile: profile, config: config)
        case .water:
            return generateWater(for: date, profile: profile, config: config)
        case .mindfulMinutes:
            return generateMindfulness(for: date, profile: profile, config: config)
        case .dietarySugar:
            return generateDietarySugar(for: date, profile: profile, config: config)
        case .dietaryProtein:
            return generateDietaryProtein(for: date, profile: profile, config: config)
        case .dietaryCarbs:
            return generateDietaryCarbs(for: date, profile: profile, config: config)
        case .dietaryFat:
            return generateDietaryFat(for: date, profile: profile, config: config)
        case .respiratoryRate:
            return generateRespiratoryRate(for: date, profile: profile, config: config)
        case .oxygenSaturation:
            return generateOxygenSaturation(for: date, profile: profile, config: config)
        default:
            return [] // Not yet implemented
        }
    }
    
    // MARK: - Steps Generation
    
    private static func generateSteps(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.current
        var samples: [[String: Any]] = []
        
        // Generate steps throughout the day
        let targetSteps = Int.random(in: profile.dailyStepsRange)
        let numberOfSamples = Int.random(in: 8...15)
        
        for i in 0..<numberOfSamples {
            let hour = 7 + (i * 14 / numberOfSamples) // Spread from 7am to 9pm
            guard let sampleTime = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: date) else {
                continue
            }
            
            let steps = targetSteps / numberOfSamples + Int.random(in: -100...100)
            
            samples.append([
                "sdate": DateFormatter.iso8601.string(from: sampleTime),
                "value": max(0, steps),
                "unit": "count"
            ])
        }
        
        return samples
    }
    
    // MARK: - Heart Rate Generation
    
    private static func generateHeartRate(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.current
        var samples: [[String: Any]] = []
        
        // Generate resting heart rate samples throughout the day
        let restingHR = Int.random(in: profile.restingHeartRateRange)
        
        for hour in 0..<24 {
            for _ in 0..<Int.random(in: 1...3) {
                guard let sampleTime = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: date) else {
                    continue
                }
                
                // Vary heart rate based on time of day and activity
                var hr = restingHR
                if hour >= 7 && hour <= 22 { // Awake hours
                    hr += Int.random(in: 5...20)
                }
                
                samples.append([
                    "sdate": DateFormatter.iso8601.string(from: sampleTime),
                    "value": hr,
                    "unit": "count/min"
                ])
            }
        }
        
        return samples
    }
    
    // MARK: - HRV Generation
    
    private static func generateHRV(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.current
        guard let morningTime = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: date) else {
            return []
        }
        
        let hrv = Int.random(in: profile.heartRateVariability.variabilityRange)
        
        return [[
            "sdate": DateFormatter.iso8601.string(from: morningTime),
            "value": hrv,
            "unit": "ms"
        ]]
    }
    
    // MARK: - Sleep Generation
    
    private static func generateSleep(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.current
        var samples: [[String: Any]] = []
        
        // Calculate sleep duration
        let sleepDuration = Double.random(in: profile.sleepDurationRange)
        let bedtimeHour = Int.random(in: profile.bedtimeRange)
        
        // Sleep start time (previous day if bedtime is late)
        var sleepStart: Date
        if bedtimeHour >= 20 {
            sleepStart = calendar.date(bySettingHour: bedtimeHour, minute: Int.random(in: 0...59), second: 0, of: date)!
        } else {
            let previousDay = calendar.date(byAdding: .day, value: -1, to: date)!
            sleepStart = calendar.date(bySettingHour: bedtimeHour, minute: Int.random(in: 0...59), second: 0, of: previousDay)!
        }
        
        let sleepEnd = sleepStart.addingTimeInterval(sleepDuration * 3600)
        
        // Generate sleep phases based on quality
        let deepSleepPercentage = Double.random(in: profile.sleepQuality.deepSleepPercentage)
        let deepSleepDuration = sleepDuration * deepSleepPercentage
        let remSleepDuration = sleepDuration * 0.20
        let lightSleepDuration = sleepDuration - deepSleepDuration - remSleepDuration
        
        var currentTime = sleepStart
        
        // Light sleep phase 1
        let lightPhase1End = currentTime.addingTimeInterval(lightSleepDuration * 0.3 * 3600)
        samples.append([
            "sdate": DateFormatter.iso8601.string(from: currentTime),
            "edate": DateFormatter.iso8601.string(from: lightPhase1End),
            "value": 2 // Light sleep
        ])
        currentTime = lightPhase1End
        
        // Deep sleep phase
        let deepPhaseEnd = currentTime.addingTimeInterval(deepSleepDuration * 3600)
        samples.append([
            "sdate": DateFormatter.iso8601.string(from: currentTime),
            "edate": DateFormatter.iso8601.string(from: deepPhaseEnd),
            "value": 3 // Deep sleep
        ])
        currentTime = deepPhaseEnd
        
        // REM sleep phase
        let remPhaseEnd = currentTime.addingTimeInterval(remSleepDuration * 3600)
        samples.append([
            "sdate": DateFormatter.iso8601.string(from: currentTime),
            "edate": DateFormatter.iso8601.string(from: remPhaseEnd),
            "value": 4 // REM sleep
        ])
        currentTime = remPhaseEnd
        
        // Light sleep phase 2
        samples.append([
            "sdate": DateFormatter.iso8601.string(from: currentTime),
            "edate": DateFormatter.iso8601.string(from: sleepEnd),
            "value": 2 // Light sleep
        ])
        
        return samples
    }
    
    // MARK: - Workouts Generation
    
    private static func generateWorkouts(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.current
        var samples: [[String: Any]] = []
        
        // Determine if there should be a workout today
        let sessionsPerWeek = profile.workoutFrequency.sessionsPerWeek
        let shouldHaveWorkout = Int.random(in: 0...6) < sessionsPerWeek.upperBound
        
        guard shouldHaveWorkout, !profile.preferredWorkoutTypes.isEmpty else {
            return []
        }
        
        // Select workout type
        let workoutType = profile.preferredWorkoutTypes.randomElement()!
        
        // Generate workout time (morning or evening)
        let isEveningWorkout = Bool.random()
        let startHour = isEveningWorkout ? Int.random(in: 17...19) : Int.random(in: 6...8)
        
        guard let workoutStart = calendar.date(bySettingHour: startHour, minute: Int.random(in: 0...59), second: 0, of: date) else {
            return []
        }
        
        // Workout duration based on type
        let duration: TimeInterval
        let distance: Double
        let energyBurned: Int
        
        switch workoutType {
        case .running:
            duration = TimeInterval(Int.random(in: 30...90) * 60)
            distance = Double.random(in: 5000...15000)
            energyBurned = Int(duration / 60 * 10)
        case .cycling:
            duration = TimeInterval(Int.random(in: 45...120) * 60)
            distance = Double.random(in: 15000...40000)
            energyBurned = Int(duration / 60 * 8)
        case .swimming:
            duration = TimeInterval(Int.random(in: 30...60) * 60)
            distance = Double.random(in: 1000...3000)
            energyBurned = Int(duration / 60 * 12)
        case .walking:
            duration = TimeInterval(Int.random(in: 20...60) * 60)
            distance = Double.random(in: 2000...6000)
            energyBurned = Int(duration / 60 * 5)
        case .yoga, .pilates:
            duration = TimeInterval(Int.random(in: 45...90) * 60)
            distance = 0
            energyBurned = Int(duration / 60 * 3)
        case .strengthTraining:
            duration = TimeInterval(Int.random(in: 45...75) * 60)
            distance = 0
            energyBurned = Int(duration / 60 * 6)
        case .hiit:
            duration = TimeInterval(Int.random(in: 20...45) * 60)
            distance = 0
            energyBurned = Int(duration / 60 * 15)
        default:
            duration = TimeInterval(Int.random(in: 30...60) * 60)
            distance = 0
            energyBurned = Int(duration / 60 * 7)
        }
        
        let workoutEnd = workoutStart.addingTimeInterval(duration)
        
        var workout: [String: Any] = [
            "sdate": DateFormatter.iso8601.string(from: workoutStart),
            "edate": DateFormatter.iso8601.string(from: workoutEnd),
            "workoutActivityType": workoutTypeToHKIdentifier(workoutType),
            "duration": duration,
            "totalEnergyBurned": energyBurned,
            "workoutEvents": []
        ]
        
        if distance > 0 {
            workout["totalDistance"] = distance
        }
        
        samples.append(workout)
        
        return samples
    }
    
    // MARK: - Energy Generation
    
    private static func generateActiveEnergy(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.current
        var samples: [[String: Any]] = []
        
        let targetEnergy = Int.random(in: profile.activeEnergyRange)
        let numberOfSamples = Int.random(in: 6...12)
        
        for i in 0..<numberOfSamples {
            let hour = 7 + (i * 14 / numberOfSamples)
            guard let sampleTime = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: date) else {
                continue
            }
            
            let energy = targetEnergy / numberOfSamples + Int.random(in: -20...20)
            
            samples.append([
                "sdate": DateFormatter.iso8601.string(from: sampleTime),
                "value": max(0, energy),
                "unit": "kcal"
            ])
        }
        
        return samples
    }
    
    private static func generateBasalEnergy(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.current
        var samples: [[String: Any]] = []
        
        // Basal metabolic rate (roughly 1400-1800 kcal/day for average adult)
        let baseBMR = 1600.0
        let dailyBasal = Int(baseBMR * profile.basalEnergyMultiplier)
        
        // Generate hourly basal energy
        for hour in 0..<24 {
            guard let sampleTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) else {
                continue
            }
            
            let hourlyBasal = dailyBasal / 24
            
            samples.append([
                "sdate": DateFormatter.iso8601.string(from: sampleTime),
                "value": hourlyBasal,
                "unit": "kcal"
            ])
        }
        
        return samples
    }
    
    // MARK: - Other Metrics
    
    private static func generateBloodPressure(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.current
        guard let morningTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date) else {
            return []
        }
        
        // Blood pressure correlates with stress and fitness
        let systolic = profile.stressLevel == .veryHigh ? Int.random(in: 130...145) : Int.random(in: 110...125)
        let diastolic = profile.stressLevel == .veryHigh ? Int.random(in: 85...95) : Int.random(in: 70...80)
        
        return [[
            "sdate": DateFormatter.iso8601.string(from: morningTime),
            "systolic": systolic,
            "diastolic": diastolic,
            "unit": "mmHg"
        ]]
    }
    
    private static func generateBodyMass(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.current
        guard let morningTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: date) else {
            return []
        }
        
        // Stable body mass with small daily variation
        let baseMass = 70.0 // kg
        let variation = Double.random(in: -0.5...0.5)
        
        return [[
            "sdate": DateFormatter.iso8601.string(from: morningTime),
            "value": baseMass + variation,
            "unit": "kg"
        ]]
    }
    
    private static func generateWater(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.current
        var samples: [[String: Any]] = []
        
        // Water intake based on hydration level
        let dailyWaterML: ClosedRange<Double> = {
            switch profile.hydrationLevel {
            case .low: return 1000...1500
            case .moderate: return 1500...2500
            case .high: return 2500...3500
            }
        }()
        
        let totalWater = Double.random(in: dailyWaterML)
        let numberOfDrinks = Int.random(in: 6...10)
        
        for i in 0..<numberOfDrinks {
            let hour = 7 + (i * 14 / numberOfDrinks)
            guard let sampleTime = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: date) else {
                continue
            }
            
            let waterAmount = totalWater / Double(numberOfDrinks)
            
            samples.append([
                "sdate": DateFormatter.iso8601.string(from: sampleTime),
                "value": waterAmount,
                "unit": "mL"
            ])
        }
        
        return samples
    }
    
    private static func generateMindfulness(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.current
        
        // More mindfulness for stressed individuals
        let shouldMeditate = profile.stressLevel == .veryHigh ? Bool.random() : (Int.random(in: 0...100) < 30)
        
        guard shouldMeditate else {
            return []
        }
        
        let startHour = Int.random(in: 7...9)
        guard let sessionStart = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: date) else {
            return []
        }
        
        let duration = TimeInterval(Int.random(in: 5...20) * 60)
        let sessionEnd = sessionStart.addingTimeInterval(duration)
        
        return [[
            "sdate": DateFormatter.iso8601.string(from: sessionStart),
            "edate": DateFormatter.iso8601.string(from: sessionEnd),
            "value": 0
        ]]
    }
    
    private static func generateDietarySugar(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.current
        guard let mealTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) else {
            return []
        }
        
        let sugar = profile.dietaryPattern == .keto ? Double.random(in: 10...30) : Double.random(in: 40...80)
        
        return [[
            "sdate": DateFormatter.iso8601.string(from: mealTime),
            "value": sugar,
            "unit": "g"
        ]]
    }
    
    private static func generateDietaryProtein(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.current
        guard let mealTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) else {
            return []
        }
        
        let protein = profile.dietaryPattern == .highProtein ? Double.random(in: 120...180) : Double.random(in: 60...100)
        
        return [[
            "sdate": DateFormatter.iso8601.string(from: mealTime),
            "value": protein,
            "unit": "g"
        ]]
    }
    
    private static func generateDietaryCarbs(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.current
        guard let mealTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) else {
            return []
        }
        
        let carbs = profile.dietaryPattern == .keto ? Double.random(in: 20...50) : Double.random(in: 200...350)
        
        return [[
            "sdate": DateFormatter.iso8601.string(from: mealTime),
            "value": carbs,
            "unit": "g"
        ]]
    }
    
    private static func generateDietaryFat(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.current
        guard let mealTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) else {
            return []
        }
        
        let fat = profile.dietaryPattern == .keto ? Double.random(in: 120...180) : Double.random(in: 50...90)
        
        return [[
            "sdate": DateFormatter.iso8601.string(from: mealTime),
            "value": fat,
            "unit": "g"
        ]]
    }
    
    private static func generateRespiratoryRate(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.current
        guard let morningTime = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: date) else {
            return []
        }
        
        let respiratoryRate = Double.random(in: 12...20)
        
        return [[
            "sdate": DateFormatter.iso8601.string(from: morningTime),
            "value": respiratoryRate,
            "unit": "count/min"
        ]]
    }
    
    private static func generateOxygenSaturation(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.current
        guard let morningTime = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: date) else {
            return []
        }
        
        let oxygenSat = Double.random(in: 95...100)
        
        return [[
            "sdate": DateFormatter.iso8601.string(from: morningTime),
            "value": oxygenSat,
            "unit": "%"
        ]]
    }
    
    // MARK: - Helper Methods
    
    private static func workoutTypeToHKIdentifier(_ type: WorkoutType) -> Int {
        switch type {
        case .running: return 37 // HKWorkoutActivityTypeRunning
        case .cycling: return 13 // HKWorkoutActivityTypeCycling
        case .swimming: return 46 // HKWorkoutActivityTypeSwimming
        case .walking: return 52 // HKWorkoutActivityTypeWalking
        case .yoga: return 57 // HKWorkoutActivityTypeYoga
        case .strengthTraining: return 50 // HKWorkoutActivityTypeTraditionalStrengthTraining
        case .hiit: return 63 // HKWorkoutActivityTypeHighIntensityIntervalTraining
        case .pilates: return 31 // HKWorkoutActivityTypePilates
        case .dancing: return 19 // HKWorkoutActivityTypeDance
        case .sports: return 3 // HKWorkoutActivityTypeAmericanFootball
        }
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}