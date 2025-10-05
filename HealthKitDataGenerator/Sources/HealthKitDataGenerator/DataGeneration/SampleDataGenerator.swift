import Foundation
import HealthKit

/// Generates realistic sample health data for testing and development
public class SampleDataGenerator {
    
    // MARK: - Public Methods
    
    /// Generates sample health data for a specified number of days
    /// - Parameters:
    ///   - numberOfDays: Number of days to generate data for
    ///   - includeBasalCalories: Whether to include basal calorie data
    /// - Returns: Dictionary containing generated sample data
    public static func generateSamples(_ numberOfDays: Int, includeBasalCalories: Bool = true) -> [String: Any] {
        var samplesHeartRate: [[String: Any]] = []
        var samplesHeartbeatSeries: [[String: Any]] = []
        var samplesMindfulSession: [[String: Any]] = []
        var samplesSleepPhases: [[String: Any]] = []
        var samplesWorkouts: [[String: Any]] = []
        var samplesDietarySugar: [[String: Any]] = []
        var samplesStepsCount: [[String: Any]] = []
        var samplesBloodPressureDiastolic: [[String: Any]] = []
        var samplesBloodPressureSystolic: [[String: Any]] = []
        var samplesBasalEnergyBurned: [[String: Any]] = []
        var samplesActiveEnergyBurned: [[String: Any]] = []

        let nowDate = Date()
        let calendar = Calendar.current

        for i in 0..<numberOfDays {
            let initialDayDate = calendar.date(byAdding: .day, value: -i, to: nowDate)!
            var currentDate = initialDayDate

            // Generate sleep phases
            let sleepData = generateSleepPhases(for: &currentDate, calendar: calendar, includeBasalCalories: includeBasalCalories)
            samplesSleepPhases.append(contentsOf: sleepData.sleepPhases)
            if includeBasalCalories {
                samplesBasalEnergyBurned.append(contentsOf: sleepData.basalEnergy)
            }

            // Generate mindfulness session
            let mindfulnessData = generateMindfulnessSession(for: &currentDate)
            samplesHeartRate.append(mindfulnessData.heartRate)
            samplesMindfulSession.append(mindfulnessData.session)

            // Generate workouts
            let workoutData = generateWorkouts(for: &currentDate)
            samplesWorkouts.append(contentsOf: workoutData.workouts)
            samplesHeartRate.append(contentsOf: workoutData.heartRates)
            samplesHeartbeatSeries.append(contentsOf: workoutData.heartbeatSeries)
            samplesActiveEnergyBurned.append(contentsOf: workoutData.activeEnergy)
            samplesStepsCount.append(contentsOf: workoutData.steps)

            // Generate dietary data
            let dietaryData = generateDietaryData(for: &currentDate)
            samplesDietarySugar.append(dietaryData)

            // Generate blood pressure data
            let bloodPressureData = generateBloodPressureData(for: &currentDate)
            samplesBloodPressureDiastolic.append(bloodPressureData.diastolic)
            samplesBloodPressureSystolic.append(bloodPressureData.systolic)
        }

        return [
            "HKQuantityTypeIdentifierHeartRate": samplesHeartRate,
            "HKDataTypeIdentifierHeartbeatSeries": samplesHeartbeatSeries,
            "HKCategoryTypeIdentifierMindfulSession": samplesMindfulSession,
            "HKCategoryTypeIdentifierSleepAnalysis": samplesSleepPhases,
            "HKWorkoutTypeIdentifier": samplesWorkouts,
            "HKQuantityTypeIdentifierDietarySugar": samplesDietarySugar,
            "HKQuantityTypeIdentifierStepCount": samplesStepsCount,
            "HKQuantityTypeIdentifierBloodPressureSystolic": samplesBloodPressureSystolic,
            "HKQuantityTypeIdentifierBloodPressureDiastolic": samplesBloodPressureDiastolic,
            "HKQuantityTypeIdentifierBasalEnergyBurned": samplesBasalEnergyBurned,
            "HKQuantityTypeIdentifierActiveEnergyBurned": samplesActiveEnergyBurned
        ]
    }
    
    // MARK: - Private Methods
    
    private static func generateSleepPhases(for currentDate: inout Date, calendar: Calendar, includeBasalCalories: Bool) -> (sleepPhases: [[String: Any]], basalEnergy: [[String: Any]]) {
        var sleepPhases: [[String: Any]] = []
        var basalEnergy: [[String: Any]] = []
        
        let sleepPhasesMinutes: [Int] = [40, 0, 20, 4*60+14, 45, 60+38]
        currentDate = calendar.startOfDay(for: currentDate)
        currentDate -= TimeInterval(2 * 60 * 60) // Subtract 2 hours
        
        for sleepPhase in 0..<6 {
            if sleepPhase == 0 || sleepPhase == 1 {
                continue
            }
            let sleepPhaseMinutes = sleepPhasesMinutes[sleepPhase]
            let sleepPhaseStartDate = currentDate
            let sleepPhaseEndDate = sleepPhaseStartDate.addingTimeInterval(TimeInterval(sleepPhaseMinutes * 60 + Int.random(in: 0...40) * 60))
            
            let sleepPhasesSample: [String: Any] = [
                "sdate": DateFormatter.iso8601.string(from: sleepPhaseStartDate),
                "edate": DateFormatter.iso8601.string(from: sleepPhaseEndDate),
                "value": sleepPhase
            ]
            sleepPhases.append(sleepPhasesSample)
            currentDate = sleepPhaseEndDate
            
            // Add basal energy burned during sleep
            if includeBasalCalories {
                let basalCaloriesPerMinute = 0.9 // Avg basal metabolic rate per minute
                let sleepBasalCalories = Int(Double(sleepPhaseMinutes) * basalCaloriesPerMinute)
                let basalEnergySample: [String: Any] = [
                    "sdate": DateFormatter.iso8601.string(from: sleepPhaseStartDate),
                    "edate": DateFormatter.iso8601.string(from: sleepPhaseEndDate),
                    "unit": "kcal",
                    "value": sleepBasalCalories
                ]
                basalEnergy.append(basalEnergySample)
            }
        }
        
        return (sleepPhases, basalEnergy)
    }
    
    private static func generateMindfulnessSession(for currentDate: inout Date) -> (heartRate: [String: Any], session: [String: Any]) {
        let heartRateValue = Int.random(in: 50...95)
        let mindfulSessionStartDate = currentDate
        let mindfulSessionEndDate = mindfulSessionStartDate.addingTimeInterval(3 * 60)
        
        let heartRateSample: [String: Any] = [
            "unit": "count/min",
            "sdate": DateFormatter.iso8601.string(from: mindfulSessionStartDate),
            "value": heartRateValue
        ]
        
        let mindfulSessionSample: [String: Any] = [
            "sdate": DateFormatter.iso8601.string(from: mindfulSessionStartDate),
            "edate": DateFormatter.iso8601.string(from: mindfulSessionEndDate)
        ]
        
        currentDate = mindfulSessionEndDate
        return (heartRateSample, mindfulSessionSample)
    }
    
    private static func generateWorkouts(for currentDate: inout Date) -> (workouts: [[String: Any]], heartRates: [[String: Any]], heartbeatSeries: [[String: Any]], activeEnergy: [[String: Any]], steps: [[String: Any]]) {
        var workouts: [[String: Any]] = []
        var heartRates: [[String: Any]] = []
        var heartbeatSeries: [[String: Any]] = []
        var activeEnergy: [[String: Any]] = []
        var steps: [[String: Any]] = []
        
        let workoutActivities: [() -> [String: Any]] = [
            { ["type": 35, "stepCount": 20, "totalDistance": Int.random(in: 500...5318)] },
            { ["type": 37, "totalDistance": Int.random(in: 500...5218)] },
            { ["type": 46, "totalDistance": Int.random(in: 500...5218)] },
            { ["type": 52, "totalDistance": Int.random(in: 500...5218)] }
        ]
        
        let workoutsStartDatePrev = currentDate
        for workoutActivityBuild in workoutActivities {
            let workoutActivity = workoutActivityBuild()
            let workoutMinutes = Int.random(in: 30...120)
            let workoutStartDate = workoutsStartDatePrev
            let workoutEndDate = workoutStartDate.addingTimeInterval(TimeInterval(workoutMinutes * 60))
            let workoutEnergyBurned = Int.random(in: 80...230)
            
            // Generate heartbeat series
            let heartbeatData = generateHeartbeatSeries(startDate: workoutStartDate, endDate: workoutEndDate)
            heartbeatSeries.append(heartbeatData)
            
            // Generate heart rate samples during workout
            let workoutHeartRates = generateWorkoutHeartRates(startDate: workoutStartDate, endDate: workoutEndDate)
            heartRates.append(contentsOf: workoutHeartRates)
            
            let workoutsSample: [String: Any] = [
                "workoutActivityType": workoutActivity["type"]!,
                "sdate": DateFormatter.iso8601.string(from: workoutStartDate),
                "edate": DateFormatter.iso8601.string(from: workoutEndDate),
                "duration": workoutMinutes * 60,
                "totalDistance": workoutActivity["totalDistance"]!,
                "totalEnergyBurned": workoutEnergyBurned,
                "stepCount": workoutActivity["stepCount"] ?? 0
            ]
            workouts.append(workoutsSample)
            
            // Add active energy burned during workout
            let activeEnergyWorkout: [String: Any] = [
                "sdate": DateFormatter.iso8601.string(from: workoutStartDate),
                "edate": DateFormatter.iso8601.string(from: workoutEndDate),
                "unit": "kcal",
                "value": workoutEnergyBurned
            ]
            activeEnergy.append(activeEnergyWorkout)
            
            currentDate = workoutEndDate
            
            // Add steps for walking workouts
            if workoutsSample["workoutActivityType"] as? Int == 35 {
                let stepsSample: [String: Any] = [
                    "sdate": DateFormatter.iso8601.string(from: workoutStartDate),
                    "edate": DateFormatter.iso8601.string(from: workoutEndDate),
                    "unit": "count",
                    "value": workoutsSample["stepCount"]!
                ]
                steps.append(stepsSample)
            }
        }
        
        return (workouts, heartRates, heartbeatSeries, activeEnergy, steps)
    }
    
    private static func generateHeartbeatSeries(startDate: Date, endDate: Date) -> [String: Any] {
        var heartbeats: [[String: Any]] = []
        var sampleTime = startDate
        
        while sampleTime < endDate {
            let heartbeatValue = Double.random(in: 50...160)
            let confidence = Int.random(in: 0...3)

            heartbeats.append([
                "timeSinceStart": sampleTime.timeIntervalSince(startDate),
                "value": heartbeatValue,
                "confidence": confidence
            ])

            sampleTime = sampleTime.addingTimeInterval(TimeInterval.random(in: 1...3))
        }
        
        let heartbeatSample: [String: Any] = [
            "sdate": DateFormatter.iso8601.string(from: startDate),
            "edate": DateFormatter.iso8601.string(from: endDate),
            "heartbeats": heartbeats
        ]
        
        return heartbeatSample
    }
    
    private static func generateWorkoutHeartRates(startDate: Date, endDate: Date) -> [[String: Any]] {
        var heartRates: [[String: Any]] = []
        let workoutDuration = endDate.timeIntervalSince(startDate)
        let interval = workoutDuration / 10

        for i in 0..<10 {
            let segmentStartDate = startDate.addingTimeInterval(interval * Double(i))
            let segmentEndDate = startDate.addingTimeInterval(interval * Double(i + 1))

            let heartRateSample: [String: Any] = [
                "unit": "count/min",
                "sdate": DateFormatter.iso8601.string(from: segmentStartDate),
                "edate": DateFormatter.iso8601.string(from: segmentEndDate),
                "value": Double.random(in: 110...180)
            ]
            
            heartRates.append(heartRateSample)
        }
        
        return heartRates
    }
    
    private static func generateDietaryData(for currentDate: inout Date) -> [String: Any] {
        let dietarySugarValue = Int.random(in: 60...500)
        let dietarySugarStartDate = currentDate
        let dietarySugarEndDate = currentDate.addingTimeInterval(3 * 60)
        
        let dietarySugarSample: [String: Any] = [
            "sdate": DateFormatter.iso8601.string(from: dietarySugarStartDate),
            "edate": DateFormatter.iso8601.string(from: dietarySugarEndDate),
            "unit": "g",
            "value": dietarySugarValue
        ]
        
        currentDate = dietarySugarEndDate
        return dietarySugarSample
    }
    
    private static func generateBloodPressureData(for currentDate: inout Date) -> (diastolic: [String: Any], systolic: [String: Any]) {
        let bloodPressureStartDate = currentDate
        let bloodPressureEndDate = currentDate.addingTimeInterval(3 * 60)
        
        let bloodPressureDiastolicValue = Int.random(in: 110...150)
        let bloodPressureDiastolicSample: [String: Any] = [
            "sdate": DateFormatter.iso8601.string(from: bloodPressureStartDate),
            "edate": DateFormatter.iso8601.string(from: bloodPressureEndDate),
            "unit": "mmHg",
            "value": bloodPressureDiastolicValue
        ]
        
        let bloodPressureSystolicValue = Int.random(in: 80...100)
        let bloodPressureSystolicSample: [String: Any] = [
            "sdate": DateFormatter.iso8601.string(from: bloodPressureStartDate),
            "edate": DateFormatter.iso8601.string(from: bloodPressureEndDate),
            "unit": "mmHg",
            "value": bloodPressureSystolicValue
        ]
        
        currentDate = bloodPressureEndDate
        return (bloodPressureDiastolicSample, bloodPressureSystolicSample)
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
