import Foundation
import HealthKit

final public class HealthKitDataGenerator {

    private let healthStore: HKHealthStore
    
    public init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    public func populate(count: Int, samplesTypes: Set<HKSampleType>) throws {
        try populate(samplesTypes: samplesTypes, generatedSamples: generateSamples(count))
    }
    
    public func populate(count: Int, samplesTypes: Set<HKSampleType>, includeBasalCalories: Bool = true) throws {
        try populate(samplesTypes: samplesTypes, generatedSamples: generateSamples(count, includeBasalCalories: includeBasalCalories))
    }
        
    public func populate(samplesTypes: Set<HKSampleType>, generatedSamples: [String: Any]) throws {
        let resultJson = try JSONSerialization.data(withJSONObject: generatedSamples,
                                                    options: .withoutEscapingSlashes)
        let resultString = String(data: resultJson, encoding: .utf8)!

        var lastSampleType = ""
        importSamples(text: resultString) { (sample) in
            guard samplesTypes.contains(sample.sampleType) else {
                print("HealthKitDataGenerator: skipped \(sample.sampleType)")
                return
            }
            if lastSampleType != String(describing: sample.sampleType) {
                lastSampleType = String(describing: sample.sampleType)
                print("HealthKitDataGenerator: importing \(lastSampleType)")
            }

            self.healthStore.save(sample, withCompletion: { (success, error: Error?) in
                if let error = error {
                    print("HealthKitDataGenerator: \(sample.sampleType) - ", error.localizedDescription)
                }
                else {
                    print("HealthKitDataGenerator: \(sample.sampleType) - ", success)
                }
            })
        }
    }

    private func formatTimestamp(_ timestamp: Date) -> String {
        timestamp.string(.isoDateTimeSeconds)
    }

    private func generateSamples(_ n: Int, includeBasalCalories: Bool = true) -> [String: Any] {
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

        for i in 0..<n {
            let initialDayDate = calendar.date(byAdding: .day, value: -i, to: nowDate)!
            var currentDate = initialDayDate

            // START: Sleep Phases
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
                    "sdate": formatTimestamp(sleepPhaseStartDate),
                    "edate": formatTimestamp(sleepPhaseEndDate),
                    "value": sleepPhase
                ]
                samplesSleepPhases.append(sleepPhasesSample)
                currentDate = sleepPhaseEndDate
                
                // Add basal energy burned during sleep
                if includeBasalCalories {
                    let basalCaloriesPerMinute = 0.9 // Avg basal metabolic rate per minute
                    let sleepBasalCalories = Int(Double(sleepPhaseMinutes) * basalCaloriesPerMinute)
                    let basalEnergySample: [String: Any] = [
                        "sdate": formatTimestamp(sleepPhaseStartDate),
                        "edate": formatTimestamp(sleepPhaseEndDate),
                        "unit": "kcal",
                        "value": sleepBasalCalories
                    ]
                    samplesBasalEnergyBurned.append(basalEnergySample)
                }
            }
            // END

            // START: Mindfulness Sessions
            let heartRateValue = Int.random(in: 50...95)
            let mindfulSessionStartDate = currentDate
            let mindfulSessionEndDate = mindfulSessionStartDate.addingTimeInterval(3 * 60)
            let heartRateSample: [String: Any] = [
                "unit": "count/min",
                "sdate": formatTimestamp(mindfulSessionStartDate),
                "value": heartRateValue
            ]
            let mindfulSessionSample: [String: Any] = [
                "sdate": formatTimestamp(mindfulSessionStartDate),
                "edate": formatTimestamp(mindfulSessionEndDate)
            ]
            samplesHeartRate.append(heartRateSample)
            samplesMindfulSession.append(mindfulSessionSample)
            currentDate = mindfulSessionEndDate
            // END

            // START: Workouts
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
                //let heartRateValue = Int.random(in: 80...180)
                let workoutStartDate = workoutsStartDatePrev
                let workoutEndDate = workoutStartDate.addingTimeInterval(TimeInterval(workoutMinutes * 60))
                let workoutEnergyBurned = Int.random(in: 80...230)
                // START: Heartbeats
                let heartbeatStartDate = workoutStartDate
                let heartbeatEndDate = workoutEndDate

                var heartbeats: [[String: Any]] = []
                var heartbeatValues: [Double] = []
                var sampleTime = heartbeatStartDate
                
                
                while sampleTime < heartbeatEndDate {
                    let heartbeatValue = Double.random(in: 50...160) // Simulated heart rate in BPM
                    let confidence = Int.random(in: 0...3) // Confidence levels (0 = lowest, 3 = highest)

                    heartbeatValues.append(heartbeatValue)
                    heartbeats.append([
                        "timeSinceStart": sampleTime.timeIntervalSince(heartbeatStartDate),
                        "value": heartbeatValue,
                        "confidence": confidence
                    ])

                    sampleTime = sampleTime.addingTimeInterval(TimeInterval.random(in: 1...3)) // 1-3 sec intervals
                }
                let heartbeatSample: [String: Any] = [
                    "sdate": formatTimestamp(heartbeatStartDate),
                    "edate": formatTimestamp(heartbeatEndDate),
                    "heartbeats": heartbeats
                ]
                // END
                let averageBPM = heartbeatValues.reduce(0, +) / Double(heartbeatValues.count)
                let heartRateSample: [String: Any] = [
                    "unit": "count/min",
                    "sdate": formatTimestamp(workoutStartDate),
                    "edate": formatTimestamp(workoutEndDate),
                    "value": averageBPM
                ]
                // START: Heart rates for today workout
                let workoutDuration = workoutEndDate.timeIntervalSince(workoutStartDate) // Total workout time
                let interval = workoutDuration / 10 // Divide into 10 equal intervals

                for i in 0..<10 {
                    let segmentStartDate = workoutStartDate.addingTimeInterval(interval * Double(i))
                    let segmentEndDate = workoutStartDate.addingTimeInterval(interval * Double(i + 1))

                    let heartRateSample: [String: Any] = [
                        "unit": "count/min",
                        "sdate": formatTimestamp(segmentStartDate),
                        "edate": formatTimestamp(segmentEndDate),
                        "value": Double.random(in: 110...180)
                    ]
                    
                    samplesHeartRate.append(heartRateSample)
                }
                // END
                let workoutsSample: [String: Any] = [
                    "workoutActivityType": workoutActivity["type"]!,
                    "sdate": formatTimestamp(workoutStartDate),
                    "edate": formatTimestamp(workoutEndDate),
                    "duration": workoutMinutes * 60,
                    "totalDistance": workoutActivity["totalDistance"]!,
                    "totalEnergyBurned": workoutEnergyBurned,
                    "stepCount": workoutActivity["stepCount"] ?? 0
                ]
                samplesHeartRate.append(heartRateSample)
                samplesHeartbeatSeries.append(heartbeatSample)
                samplesWorkouts.append(workoutsSample)
                
                // Add active energy burned during workout
                let activeEnergyWorkout: [String: Any] = [
                    "sdate": formatTimestamp(workoutStartDate),
                    "edate": formatTimestamp(workoutEndDate),
                    "unit": "kcal",
                    "value": workoutEnergyBurned
                ]
                samplesActiveEnergyBurned.append(activeEnergyWorkout)
                
                currentDate = workoutEndDate
                // START: Steps
                if workoutsSample["workoutActivityType"] as? Int == 35 {
                    let stepsSample: [String: Any] = [
                        "sdate": formatTimestamp(workoutStartDate),
                        "edate": formatTimestamp(workoutEndDate),
                        "unit": "count",
                        "value": workoutsSample["stepCount"]!
                    ]
                    samplesStepsCount.append(stepsSample)
                }
                // END
            }
            // END

            // START: Dietary
            // START: SUGAR
            let dietarySugarValue = Int.random(in: 60...500)
            let dietarySugarStartDate = currentDate
            let dietarySugarEndDate = currentDate.addingTimeInterval(3 * 60)
            let dietarySugarSample: [String: Any] = [
                "sdate": formatTimestamp(dietarySugarStartDate),
                "edate": formatTimestamp(dietarySugarEndDate),
                "unit": "g",
                "value": dietarySugarValue
            ]
            samplesDietarySugar.append(dietarySugarSample)
            currentDate = dietarySugarEndDate
            // END

            // START: Blood pressure
            let bloodPressureStartDate = currentDate
            let bloodPressureEndDate = currentDate.addingTimeInterval(3 * 60)
            // DIASTOLIC
            let bloodPressureDiastolicValue = Int.random(in: 110...150)
            let bloodPressureDiastolicSample: [String: Any] = [
                "sdate": formatTimestamp(bloodPressureStartDate),
                "edate": formatTimestamp(bloodPressureEndDate),
                "unit": "mmHg",
                "value": bloodPressureDiastolicValue
            ]
            samplesBloodPressureDiastolic.append(bloodPressureDiastolicSample)
            // SYSTOLIC
            let bloodPressureSystolicValue = Int.random(in: 80...100)
            let bloodPressureSystolicSample: [String: Any] = [
                "sdate": formatTimestamp(bloodPressureStartDate),
                "edate": formatTimestamp(bloodPressureEndDate),
                "unit": "mmHg",
                "value": bloodPressureSystolicValue
            ]
            samplesBloodPressureSystolic.append(bloodPressureSystolicSample)
            currentDate = bloodPressureEndDate
            // END
        }

        let result: [String: Any] = [
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

        return result
    }

    private func importSamples(text: String, onSample: @escaping (_ sample: HKSample) -> Void) {
           let sampleImportHandler = SampleOutputJsonHandler { [weak self] (sampleDict: AnyObject, typeName: String) in
               guard let self else { return }
               
               if let creator = SampleCreatorRegistry.get(self.healthStore, typeName) {
                   let sampleOpt: HKSample? = creator.createSample(sampleDict)
                   if let sample = sampleOpt {
                       onSample(sample)
                   }
               }
           }

           let tokenizer = JsonTokenizer(jsonHandler: sampleImportHandler)
           tokenizer.tokenize(text)
       }

}
