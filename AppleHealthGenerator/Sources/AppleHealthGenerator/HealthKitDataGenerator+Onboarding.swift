import Foundation
import HealthKit

extension HealthKitDataGenerator {
    
    public func generateOnboardingSamples(_ days: Int, sparse: Bool = false, includeBasalCalories: Bool = true) -> [String: Any] {
        // 1. Prepare data arrays
        var heartRateSamples: [[String: Any]] = []
        var heartbeatSeries: [[String: Any]] = []
        var sleepPhases: [[String: Any]] = []
        var workouts: [[String: Any]] = []
        var steps: [[String: Any]] = []
        var basalEnergyBurned: [[String: Any]] = []
        var samplesActiveEnergyBurned: [[String: Any]] = []

        let now = Date()
        let calendar = Calendar.current

        // Sleep phase definitions based on typical cycles:
        let awake = HKCategoryValueSleepAnalysis.awake.rawValue
        let core = HKCategoryValueSleepAnalysis.asleepCore.rawValue
        let deep = HKCategoryValueSleepAnalysis.asleepDeep.rawValue
        let rem = HKCategoryValueSleepAnalysis.asleepREM.rawValue
        let sleepCyclePattern: [(phase: Int, min: Int, max: Int)] = [
            (awake, 1, 5), // Awake
            (deep, 30, 50), // Deep
            (core, 70, 90), // Core
            (rem, 10, 20), // REM
        ]
        let cyclesPerNight = 4
        let phaseHeartRate: [Int: ClosedRange<Double>] = [
            awake: 60...80, // Awake: slightly elevated
            deep: 43...46,  // Deep: lowest
            core: 49...53,  // Core: moderate
            rem: 56...63   // REM: variable, can be higher than deep/core
        ]
        let phaseCaloriesPerMinute: [Int: Double] = [
            awake: 1.2, // Awake: higher basal rate
            deep: 0.8,  // Deep: lowest
            core: 1.0,  // Core: moderate
            rem: 1.1   // REM: slightly higher than core
        ]
        for dayOffset in 0..<days {
            if sparse && Bool.random() {
                continue // Skip some days randomly if sparse
            }
            var dayDate = calendar.startOfDay(for: now)
            dayDate = calendar.date(byAdding: .day, value: -dayOffset, to: dayDate)!
            let sleepDuration = Double.random(in: 7.0...8.5) * 3600 // 7-8.5 hours
            let sleepStart = dayDate.addingTimeInterval(11 * 3600 - sleepDuration)
            let sleepEnd = sleepStart.addingTimeInterval(sleepDuration)
            var phaseStart = sleepStart
            for cycle in 0..<cyclesPerNight {
                for (phase, minMins, maxMins) in sleepCyclePattern {
                    let mins = Int.random(in: minMins...maxMins)
                    let phaseEnd = phaseStart.addingTimeInterval(TimeInterval(mins * 60))
                    if phaseEnd > sleepEnd { break }
                    sleepPhases.append([
                        "sdate": formatTimestamp(phaseStart),
                        "edate": formatTimestamp(phaseEnd),
                        "value": phase
                    ])
                    // Add basal energy burned during sleep, phase-specific
                    if includeBasalCalories, let kcalPerMin = phaseCaloriesPerMinute[phase] {
                        let sleepBasalCalories = Int(Double(mins) * kcalPerMin)
                        basalEnergyBurned.append([
                            "sdate": formatTimestamp(phaseStart),
                            "edate": formatTimestamp(phaseEnd),
                            "unit": "kcal",
                            "value": sleepBasalCalories
                        ])
                    }
                    // Generate heartbeat data, phase-specific
                    let hrRange = phaseHeartRate[phase]!
                    let phaseHeartRates = makeHeartRatesData(phaseStart, phaseEnd, hrRange)
                    heartRateSamples.append(contentsOf: phaseHeartRates)
                    //heartbeatSeries.append(hbs)
                    phaseStart = phaseEnd
                    if phaseStart >= sleepEnd { break }
                }
                if phaseStart >= sleepEnd { break }
            }
            // 4. Random workout or rest day
            if true {
                let workoutStart = dayDate.addingTimeInterval(Double.random(in: 9...18) * 3600)
                let workoutLength = Int.random(in: 30...90) * 60
                let workoutEnd = workoutStart.addingTimeInterval(TimeInterval(workoutLength))
                let workoutType = [37, 46, 52].randomElement() ?? 37
                let workoutEnergyBurned = Int.random(in: 100...400)
                
                workouts.append([
                    "workoutActivityType": workoutType,
                    "sdate": formatTimestamp(workoutStart),
                    "edate": formatTimestamp(workoutEnd),
                    "duration": workoutLength,
                    "totalDistance": Int.random(in: 1000...5000),
                    "totalEnergyBurned": workoutEnergyBurned,
                    "stepCount": Int.random(in: 1000...8000)
                ])

                // Higher BPM range: 100–180
                let (wkHeartRates, wkHbs) = makeHeartbeatData(workoutStart, workoutEnd, 100...180)
                heartRateSamples.append(contentsOf: wkHeartRates)
                heartbeatSeries.append(wkHbs)

                // Add active energy burned during workout
                let activeEnergyWorkout: [String: Any] = [
                    "sdate": formatTimestamp(workoutStart),
                    "edate": formatTimestamp(workoutEnd),
                    "unit": "kcal",
                    "value": workoutEnergyBurned
                ]
                samplesActiveEnergyBurned.append(activeEnergyWorkout)
                
                steps.append([
                    "sdate": formatTimestamp(workoutStart),
                    "edate": formatTimestamp(workoutEnd),
                    "unit": "count",
                    "value": Int.random(in: 1000...8000)
                ])
            } else {
                // Light steps if no workout
                // Morning
                steps.append([
                    "sdate": formatTimestamp(dayDate.addingTimeInterval(10 * 3600)),
                    "edate": formatTimestamp(dayDate.addingTimeInterval(12 * 3600)),
                    "unit": "count",
                    "value": Int.random(in: 2000...5000)
                ])
                
                // Evening
                steps.append([
                    "sdate": formatTimestamp(dayDate.addingTimeInterval(18 * 3600)),
                    "edate": formatTimestamp(dayDate.addingTimeInterval(20 * 3600)),
                    "unit": "count",
                    "value": Int.random(in: 2000...5000)
                ])
            }
        }

        return [
            "HKQuantityTypeIdentifierHeartRate": heartRateSamples,
            "HKDataTypeIdentifierHeartbeatSeries": heartbeatSeries,
            "HKCategoryTypeIdentifierSleepAnalysis": sleepPhases,
            "HKWorkoutTypeIdentifier": workouts,
            "HKQuantityTypeIdentifierStepCount": steps,
            "HKQuantityTypeIdentifierBasalEnergyBurned": basalEnergyBurned,
            "HKQuantityTypeIdentifierActiveEnergyBurned": samplesActiveEnergyBurned
        ]
    }

    // Helper to generate heart rate samples and a HeartbeatSeries
    private func makeHeartbeatData(
        _ start: Date,
        _ end: Date,
        _ range: ClosedRange<Double>
    ) -> ([[String: Any]], [String: Any]) {
        var sampleTime = start
        var heartRates: [[String: Any]] = []
        var heartbeatPoints: [[String: Any]] = []
        
        while sampleTime < end {
            let value = Double.random(in: range)
            heartbeatPoints.append([
                "timeSinceStart": sampleTime.timeIntervalSince(start),
                "value": value,
                "confidence": Int.random(in: 0...3)
            ])
            // Create average snapshots every minute
            if Int(sampleTime.timeIntervalSince(start)) % 60 == 0 {
                heartRates.append([
                    "unit": "count/min",
                    "sdate": formatTimestamp(sampleTime),
                    "edate": formatTimestamp(sampleTime.addingTimeInterval(60)),
                    "value": value
                ])
            }
            sampleTime = sampleTime.addingTimeInterval(Double.random(in: 5...30))
        }
        
        let heartbeatSeries = [
            "sdate": formatTimestamp(start),
            "edate": formatTimestamp(end),
            "heartbeats": heartbeatPoints
        ] as [String : Any]
        return (heartRates, heartbeatSeries)
    }

        // Helper to generate heart rate samples and a HeartbeatSeries
    private func makeHeartRatesData(
        _ start: Date,
        _ end: Date,
        _ range: ClosedRange<Double>,
        _ frequencySec: Int = 60
    ) -> [[String: Any]] {
        var sampleTime = start
        var heartRates: [[String: Any]] = []
        var heartbeatPoints: [[String: Any]] = []
        
        while sampleTime < end {
            let value: Double = Double.random(in: range)

            if Int(sampleTime.timeIntervalSince(start)) % frequencySec == 0 {
                heartRates.append([
                    "unit": "count/min",
                    "sdate": formatTimestamp(sampleTime),
                    "edate": formatTimestamp(sampleTime.addingTimeInterval(60)),
                    "value": value
                ])
            }
            sampleTime = sampleTime.addingTimeInterval(Double.random(in: 5...30))
        }
        
        return heartRates
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }
    
}
