//
//  SampleCreator.swift
//  Pods
//
//  Created by Michael Seemann on 29.10.15.
//
//

import Foundation
import HealthKit

// swiftlint:disable all
// Registry for SampleCreators. E.g. mapping from type to SampleCreator
public class SampleCreatorRegistry {

    /**
     Mapping from HKObjectType Name (String) to SampleCreator.
     - Parameter typeName: the name of the type for what a SampleCreator is needed.
     - Returns: a SampleCreator for the type or nil if no SampleCreator exists for the type or the type is not supported.
    */
    public static func get(_ healthStore: HKHealthStore, _ typeName:String?) -> SampleCreator? {
        var sampleCreator:SampleCreator? = nil

        if let type = typeName {
            if type.hasPrefix("HKCharacteristicTypeIdentifier") {
                // it is not possible to create characteristics - so there is no SampleCreator for characteristics.s
            } else if type.hasPrefix("HKCategoryTypeIdentifier") {
                sampleCreator = CategorySampleCreator(typeName: type)
            } else if type.hasPrefix("HKQuantityTypeIdentifier"){
                sampleCreator = QuantitySampleCreator(typeName: type)
            } else if type.hasPrefix("HKCorrelationTypeIdentifier"){
                sampleCreator = CorrelationSampleCreator(healthStore: healthStore, typeName: type)
            } else if type.hasPrefix("HKWorkoutTypeIdentifier"){
                sampleCreator = WorkoutSampleCreator()
            }
            else if typeName == "HKDataTypeIdentifierHeartbeatSeries" {
                sampleCreator = HeartbeatSeriesSampleCreator(healthStore: healthStore)
            }
            else {
                print("unsupported", typeName)
            }
        }
        return sampleCreator
    }
}

// protocol for the SampleCreator
public protocol SampleCreator {

    /**
     Creates a sample for the provided json dictionary. The sample is ready
     to save to the healthkit store. if anything goes wrong nil is returned.
     - Parameter sampleDict: the json dictionary containing a complete sample (inluding sub structures)
     - Returns: a HealthKit Sample that can be saved to the Health store or nil.
    */
    func createSample(_ sampleDict:AnyObject) -> HKSample?
}

// abstract class implementation
extension SampleCreator {

    /**
     Reads the start date an end date from a json dictionary and returns a tupel of start date and end date.
     If the dictionary did not contain a end date the end date is the same as the start date.
     - Parameter dict: The Json dictionary for a sample
     - Returns: a tupel with the start date and the end date
    */
    func dictToTimeframe(_ dict:Dictionary<String, AnyObject>) -> (sDate:Date, eDate:Date) {

		let startDate: Date
		if let timestamp = dict[HealthKitConstants.S_DATE] as? Double {
			startDate = Date(timeIntervalSince1970: timestamp / 1000)
		} else if let stringDate = dict[HealthKitConstants.S_DATE] as? String {
            startDate = (try? stringDate.date(.isoDateTimeSeconds)) ?? Date()
		} else {
			startDate = Date()
		}

		let endDate: Date
		if let timestamp = dict[HealthKitConstants.E_DATE] as? Double {
			endDate = Date(timeIntervalSince1970: timestamp / 1000)
		} else if let stringDate = dict[HealthKitConstants.E_DATE] as? String {
			endDate = (try? stringDate.date(.isoDateTimeSeconds)) ?? Date()
		} else {
			endDate = startDate
		}

        return (startDate, endDate)
    }

    /**
     Converts a json dictionary into a Category Sample
     - Parameter dict: the json dictionary of a sample
     - Parameter forType: the concrete category type that should be created
     - Returns: the CategorySample. Ready to save to the Health Store.
    */
    func dictToCategorySample(_ dict:Dictionary<String, AnyObject>, forType type: HKCategoryType) -> HKCategorySample {
        let value = dict[HealthKitConstants.VALUE] as? Int ?? 0
        let dates = dictToTimeframe(dict)

        return HKCategorySample(type: type, value: value, start: dates.sDate , end: dates.eDate)
    }

    /**
     Converts a json dictionary into a Quantity Sample
     - Parameter dict: the json dictionary of a sample
     - Parameter forType: the concrete quantity type that should be created
     - Returns: the QuantitySample. Ready to save to the Health Store.
     */
    func dictToQuantitySample(_ dict:Dictionary<String, AnyObject>, forType type: HKQuantityType) -> HKQuantitySample {

        let dates = dictToTimeframe(dict)

        let value   = dict[HealthKitConstants.VALUE] as! Double
        let strUnit = dict[HealthKitConstants.UNIT] as? String

        let hkUnit = HKUnit(from: strUnit!)
        let quantity = HKQuantity(unit: hkUnit, doubleValue: value)

        return HKQuantitySample(type: type, quantity: quantity, start: dates.sDate, end: dates.eDate)
    }
}

/// a catgeory sample creator
class CategorySampleCreator : SampleCreator {
    let type: HKCategoryType

    init(typeName:String){
        self.type = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: typeName))!
    }

    func createSample(_ sampleDict: AnyObject) -> HKSample? {
        if let dict = sampleDict as? Dictionary<String, AnyObject> {
            return dictToCategorySample(dict, forType:type)
        }
        return nil
    }
}

/// a quantity sample creator
class QuantitySampleCreator : SampleCreator {
    let type: HKQuantityType

    init(typeName:String){
        self.type = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: typeName))!
    }

    func createSample(_ sampleDict: AnyObject) -> HKSample? {

        if let dict = sampleDict as? Dictionary<String, AnyObject> {
            return dictToQuantitySample(dict, forType:type)
        }
        return nil
    }

}

/// a correlation sample creator
class CorrelationSampleCreator : SampleCreator {
    private let type: HKCorrelationType
    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore, typeName: String){
        self.type = HKObjectType.correlationType(forIdentifier: HKCorrelationTypeIdentifier(rawValue: typeName))!
        self.healthStore = healthStore
    }

    func createSample(_ sampleDict: AnyObject) -> HKSample? {

        if let dict = sampleDict as? Dictionary<String, AnyObject> {
            let dates = dictToTimeframe(dict)

            var objects: Set<HKSample> = []

            if let objectsArray = dict[HealthKitConstants.OBJECTS] as? [AnyObject] {
                for object in objectsArray {
                    if let subDict = object as? Dictionary<String, AnyObject> {
                        let subTypeName = subDict[HealthKitConstants.TYPE] as? String
                        if let creator = SampleCreatorRegistry.get(healthStore, subTypeName) {
                            let sampleOpt = creator.createSample(subDict as AnyObject)
                            if let sample = sampleOpt {
                                objects.insert(sample)
                            }
                        }
                    }
                }
            }

            if objects.count == 0 {
                // no samples - no correlation
                return nil
            }

            return HKCorrelation(type: type, start: dates.sDate, end: dates.eDate, objects: objects)
        }
        return nil
    }
}

/// a workout sample creator
class WorkoutSampleCreator : SampleCreator {
    let type = HKObjectType.workoutType()

    func createSample(_ sampleDict: AnyObject) -> HKSample? {

        if let dict = sampleDict as? Dictionary<String, AnyObject> {
            let dates = dictToTimeframe(dict)

            let activityTypeRawValue = dict[HealthKitConstants.WORKOUT_ACTIVITY_TYPE] as? UInt
            let activityType = HKWorkoutActivityType(rawValue: activityTypeRawValue!)

            let duration = dict[HealthKitConstants.DURATION] as? TimeInterval
            let totalDistance = dict[HealthKitConstants.TOTAL_DISTANCE] as? Double // always HKUnit.meterUnit()
            let totalEnergyBurned = dict[HealthKitConstants.TOTAL_ENERGY_BURNED] as? Double //always HKUnit.kilocalorieUnit()

            var events:[HKWorkoutEvent] = []

            if let workoutEventsArray = dict[HealthKitConstants.WORKOUT_EVENTS] as? [AnyObject] {
                for workoutEvent in workoutEventsArray {
                    if let subDict = workoutEvent as? Dictionary<String, AnyObject> {
                        let eventTypeRaw = subDict[HealthKitConstants.TYPE] as? Int
                        let eventType = HKWorkoutEventType(rawValue: eventTypeRaw!)!
						let startDate = dictToTimeframe(subDict).sDate
                        events.append(HKWorkoutEvent(type: eventType, date: startDate))
                    }
                }
            }
            if events.count > 0 {
                return HKWorkout(activityType: activityType!, start: dates.sDate, end: dates.eDate, workoutEvents: events, totalEnergyBurned: HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: totalEnergyBurned!), totalDistance: HKQuantity(unit: HKUnit.meter(), doubleValue: totalDistance!), metadata: nil)
            } else {
                return HKWorkout(activityType: activityType!, start: dates.sDate, end: dates.eDate, duration: duration!, totalEnergyBurned: HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: totalEnergyBurned!), totalDistance: HKQuantity(unit: HKUnit.meter(), doubleValue: totalDistance!), metadata: nil)
            }
        }
        return nil
    }

}

/// a heartbeat  series sample creater
class HeartbeatSeriesSampleCreator: SampleCreator {
    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    func createSample(_ sampleDict: AnyObject) -> HKSample? {
        // 1️⃣ Parse input dictionary
        guard let dict = sampleDict as? [String: Any],
              let startString = dict["sdate"] as? String,
              let endString   = dict["edate"] as? String,
              let heartbeats  = dict["heartbeats"] as? [[String: Any]]
        else {
            print("HeartbeatSeriesSampleCreator: invalid dictionary structure")
            return nil
        }

        // 2️⃣ Parse dates
        let startDate = (try? startString.date(.isoDateTimeSeconds)) ?? Date()
        let endDate   = (try? endString.date(.isoDateTimeSeconds)) ?? startDate

        // 3️⃣ Create the builder
        let builder = HKHeartbeatSeriesBuilder(healthStore: healthStore, device: nil, start: startDate)

        // 4️⃣ For each heartbeat, add to builder
        for hb in heartbeats {
            guard let offset = hb["timeSinceStart"] as? TimeInterval else { continue }

            // Confidence must be an Int from [0..3]. We'll clamp just in case
            let rawConfidence = hb["confidence"] as? Int ?? 0
            let confidence = max(0, min(rawConfidence, 3))
            // precededByGap is optional logic (hardcode to `false` here)
            let precededByGap = false

            builder.addHeartbeatWithTimeInterval(
                sinceSeriesStartDate: offset,
                precededByGap: precededByGap) { success, error in
                    if let error {
                        print("Error during addHeartbeatWithTimeInterval: \(error.localizedDescription)")
                    }
                    guard success else {
                        print("Failed to add addHeartbeatWithTimeInterval")
                        return
                    }
                }
        }

        // 5️⃣ Synchronously finish the series using a dispatch group
        let group = DispatchGroup()
        group.enter()

        var resultSample: HKHeartbeatSeriesSample?
        var finishError: Error?

        builder.finishSeries/*(endDate: endDate)*/ { sample, error in
            finishError = error
            resultSample = sample
            group.leave()
        }

        // Wait for asynchronous builder to complete
        group.wait()

        // 6️⃣ Check error and return the created sample
        if let err = finishError {
            print("HeartbeatSeriesSampleCreator: error finishing builder –", err.localizedDescription)
            return nil
        }
        if let sample = resultSample {
            return sample
        } else {
            return nil
        }
    }
}