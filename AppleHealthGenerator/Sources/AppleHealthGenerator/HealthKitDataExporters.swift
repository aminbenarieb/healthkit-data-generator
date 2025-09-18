//
//  DataExporter.swift
//  Pods
//
//  Created by Michael Seemann on 07.10.15.
//
//

import Foundation
import HealthKit

// swiftlint:disable all

/// Protocol that every data export must conform to.
internal protocol DataExporter {
    var message: String {get}
    func export(_ healthStore: HKHealthStore, exportTargets: [ExportTarget]) throws -> Void
}

/// convenience base class for dataexporter
internal class BaseDataExporter {
    var healthQueryError: NSError?  = nil
    var exportError: Error?     = nil
    var exportConfiguration: ExportConfiguration
    let sortDescriptor              = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

    internal init(exportConfiguration: ExportConfiguration){
        self.exportConfiguration = exportConfiguration
    }

    func rethrowCollectedErrors() throws {

        // throw collected errors in the completion block
        if healthQueryError != nil {
            print(healthQueryError)
            throw ExportError.dataWriteError(healthQueryError?.description)
        }
        if let throwableError = exportError {
            throw throwableError
        }
    }
}

/// exports the metadata for a profile
internal class MetaDataExporter : BaseDataExporter, DataExporter {

    internal var message = "exporting metadata"

    internal func export(_ healthStore: HKHealthStore, exportTargets: [ExportTarget]) throws {
        for exportTarget in exportTargets {
            try exportTarget.writeMetaData(creationDate: Date(), profileName: exportConfiguration.profileName, version:"1.0.0")
        }
    }
}

/// exports the userdata (characteristics) of the healthkit store
internal class UserDataExporter: BaseDataExporter, DataExporter {

    internal var message = "exporting user data"

    internal func export(_ healthStore: HKHealthStore, exportTargets: [ExportTarget]) throws {
        var userData = Dictionary<String, AnyObject>()

        if let birthDay = try? healthStore.dateOfBirthComponents() {
            userData[HealthKitConstants.DATE_OF_BIRTH] = birthDay.description as AnyObject
        }

        if let sex = try? healthStore.biologicalSex(), sex.biologicalSex != HKBiologicalSex.notSet {
            userData[HealthKitConstants.BIOLOGICAL_SEX] = sex.biologicalSex.rawValue as AnyObject
        }

        if let bloodType = try? healthStore.bloodType(), bloodType.bloodType != HKBloodType.notSet {
            userData[HealthKitConstants.BLOOD_TYPE] = bloodType.bloodType.rawValue as AnyObject
        }

        if let fitzpatrick = try? healthStore.fitzpatrickSkinType(), fitzpatrick.skinType != HKFitzpatrickSkinType.notSet {
            userData[HealthKitConstants.FITZPATRICK_SKIN_TYPE] = fitzpatrick.skinType.rawValue as AnyObject
        }

        for exportTarget in exportTargets {
            try exportTarget.writeUserData(userData)
        }
    }
}

/// exports quanity types
internal class QuantityTypeDataExporter: BaseDataExporter, DataExporter {
    internal var message:String = ""

    var type : HKQuantityType
    var unit: HKUnit

    let queryCountLimit = 10000

    internal init(exportConfiguration: ExportConfiguration, type: HKQuantityType, unit: HKUnit){
        self.type = type
        self.unit = unit
        self.message = "exporting \(type)"
        super.init(exportConfiguration: exportConfiguration)
    }

    func writeResults(_ results: [HKSample]?, exportTargets: [ExportTarget], error: NSError?) -> Void {
        if error != nil {
            self.healthQueryError = error
        } else {
            do {
                for sample in results as! [HKQuantitySample] {

                    let value = sample.quantity.doubleValue(for: self.unit)

                    for exportTarget in exportTargets {
                        var dict: Dictionary<String, AnyObject> = [:]
                        if exportConfiguration.exportUuids {
                            dict[HealthKitConstants.UUID] = sample.uuid.uuidString as AnyObject
                        }
                        dict[HealthKitConstants.S_DATE] = sample.startDate as AnyObject
                        dict[HealthKitConstants.VALUE] = value as AnyObject
                        dict[HealthKitConstants.UNIT] = unit.description as AnyObject

                        if sample.startDate != sample.endDate {
                            dict[HealthKitConstants.E_DATE] = sample.endDate as AnyObject
                        }
                        if let context = sample.metadata?[HKMetadataKeyHeartRateMotionContext] as? NSNumber{
                            dict[HealthKitConstants.META_DATA] = context as AnyObject
                        }
                        dict[HealthKitConstants.SOURCE] = sample.sourceRevision.source.name as AnyObject
                        try exportTarget.writeDictionary(dict);
                    }
                }
            } catch let err {
                self.exportError = err
            }
        }
    }

    func anchorQuery(_ healthStore: HKHealthStore, exportTargets: [ExportTarget], anchor : HKQueryAnchor?) throws -> (anchor:HKQueryAnchor?, count:Int?) {

        let semaphore = DispatchSemaphore(value: 0)
        var resultAnchor: HKQueryAnchor?
        var resultCount: Int?
        let query = HKAnchoredObjectQuery(
            type: type,
            predicate: exportConfiguration.getPredicate(),
            anchor: anchor ,
            limit: queryCountLimit) { (query, results, deleted, newAnchor, error) -> Void in

                self.writeResults(results, exportTargets: exportTargets, error: error as? NSError)

                resultAnchor = newAnchor
                resultCount = results?.count
                semaphore.signal()
            }

        healthStore.execute(query)

        semaphore.wait(timeout: DispatchTime.distantFuture)

        try rethrowCollectedErrors()

        return (anchor:resultAnchor, count: resultCount)
    }


    internal func export(_ healthStore: HKHealthStore, exportTargets: [ExportTarget]) throws {
        for exportTarget in exportTargets {
            try exportTarget.startWriteType(type)
        }

        var result : (anchor:HKQueryAnchor?, count:Int?) = (anchor:nil, count: -1)
        repeat {
            result = try anchorQuery(healthStore, exportTargets: exportTargets, anchor:result.anchor)

        } while result.count != 0 || result.count==queryCountLimit

        for exportTarget in exportTargets {
            try exportTarget.endWriteType()
        }
     }
}

/// exports category types
internal class CategoryTypeDataExporter: BaseDataExporter, DataExporter {
    internal var message:String = ""
    var type : HKCategoryType
    let queryCountLimit = 10000

    internal init(exportConfiguration: ExportConfiguration, type: HKCategoryType){
        self.type = type
        self.message = "exporting \(type)"
        super.init(exportConfiguration: exportConfiguration)
    }

    func writeResults(_ results: [HKCategorySample]?, exportTargets: [ExportTarget], error: NSError?) -> Void {
        if error != nil {
            self.healthQueryError = error
        } else {
            do {
                for sample in results ?? [HKCategorySample]() {

                    for exportTarget in exportTargets {
                        var dict: Dictionary<String, AnyObject> = [:]
                        if exportConfiguration.exportUuids {
                            dict[HealthKitConstants.UUID] = sample.uuid.uuidString as AnyObject
                        }
                        dict[HealthKitConstants.S_DATE] = sample.startDate as AnyObject
                        dict[HealthKitConstants.VALUE] = sample.value as AnyObject
                        if sample.startDate != sample.endDate {
                            dict[HealthKitConstants.E_DATE] = sample.endDate as AnyObject
                        }
                        try exportTarget.writeDictionary(dict);
                    }
                }
            } catch let err {
                self.exportError = err
            }
        }
    }

    func anchorQuery(_ healthStore: HKHealthStore, exportTargets: [ExportTarget], anchor : HKQueryAnchor?) throws -> (anchor:HKQueryAnchor?, count:Int?) {

        let semaphore = DispatchSemaphore(value: 0)
        var resultAnchor: HKQueryAnchor?
        var resultCount: Int?
        let query = HKAnchoredObjectQuery(
            type: type,
            predicate: exportConfiguration.getPredicate(),
            anchor: anchor ,
            limit: queryCountLimit) { (query, results, deleted, newAnchor, error) -> Void in

                if(error != nil){
                    if (error as! NSError).code == 5 {
                        self.writeResults(results as? [HKCategorySample], exportTargets: exportTargets, error: nil)
                        resultAnchor = newAnchor
                        resultCount = results?.count ?? 0
                        semaphore.signal()
                    }else{
                        self.writeResults(results as? [HKCategorySample], exportTargets: exportTargets, error: error as? NSError)
                        resultAnchor = newAnchor
                        resultCount = results?.count ?? 0
                        semaphore.signal()
                    }
                }else{
                    self.writeResults(results as? [HKCategorySample], exportTargets: exportTargets, error: nil)

                    resultAnchor = newAnchor
                    resultCount = results?.count ?? 0
                    semaphore.signal()
                }
            }

        healthStore.execute(query)

        semaphore.wait(timeout: DispatchTime.distantFuture)

        try rethrowCollectedErrors()

        return (anchor:resultAnchor, count: resultCount)
    }


    internal func export(_ healthStore: HKHealthStore, exportTargets: [ExportTarget]) throws {
        for exportTarget in exportTargets {
            try exportTarget.startWriteType(type)
        }
        var result : (anchor:HKQueryAnchor?, count:Int?) = (anchor:nil, count: -1)
        repeat {
            result = try anchorQuery(healthStore, exportTargets: exportTargets, anchor:result.anchor)
        } while result.count != 0 || result.count==queryCountLimit

        for exportTarget in exportTargets {
            try exportTarget.endWriteType()
        }

    }
}

/// exports correlation types
internal class CorrelationTypeDataExporter: BaseDataExporter, DataExporter {
    internal var message:String = ""
    var type : HKCorrelationType
    let queryCountLimit = 10000
    let typeMap: [HKQuantityType : HKUnit]

    internal init(exportConfiguration: ExportConfiguration, type: HKCorrelationType, typeMap: [HKQuantityType : HKUnit]){
        self.type = type
        self.message = "exporting \(type)"
        self.typeMap = typeMap
        super.init(exportConfiguration: exportConfiguration)
    }

    func writeResults(_ results: [HKCorrelation], exportTargets: [ExportTarget], error: NSError?) -> Void {
        if error != nil {
            self.healthQueryError = error
        } else {
            do {
                for sample in results  {

                    var dict: Dictionary<String, AnyObject> = [:]
                    if exportConfiguration.exportUuids {
                        dict[HealthKitConstants.UUID] = sample.uuid.uuidString as AnyObject
                    }
                    dict[HealthKitConstants.S_DATE] = sample.startDate as AnyObject
                    if sample.startDate != sample.endDate {
                        dict[HealthKitConstants.E_DATE] = sample.endDate as AnyObject
                    }
                    var subSampleArray:[AnyObject] = []

                    // possible types are: HKQuantitySamples and HKCategorySamples
                    for subsample in sample.objects {

                        var sampleDict: Dictionary<String, AnyObject> = [:]
                        if exportConfiguration.exportUuids {
                            sampleDict[HealthKitConstants.UUID] = subsample.uuid.uuidString as AnyObject
                        }

                        sampleDict[HealthKitConstants.S_DATE] = subsample.startDate as AnyObject
                        if subsample.startDate != subsample.endDate {
                            sampleDict[HealthKitConstants.E_DATE] = subsample.endDate as AnyObject
                        }
                        sampleDict[HealthKitConstants.TYPE] = subsample.sampleType.identifier as AnyObject

                        if let quantitySample = subsample as? HKQuantitySample {
                            let unit = self.typeMap[quantitySample.quantityType]!
                            sampleDict[HealthKitConstants.UNIT] = unit.description as AnyObject
                            sampleDict[HealthKitConstants.VALUE] = quantitySample.quantity.doubleValue(for: unit) as AnyObject

                        } else if let categorySample = subsample as? HKCategorySample {
                            sampleDict[HealthKitConstants.VALUE] = categorySample.value as AnyObject
                        } else {
                            throw ExportError.illegalArgumentError("unsupported correlation type \(subsample.sampleType.identifier)")
                        }

                        subSampleArray.append(sampleDict as AnyObject)
                    }

                    dict[HealthKitConstants.OBJECTS] = subSampleArray as AnyObject

                    for exportTarget in exportTargets {
                        try exportTarget.writeDictionary(dict);
                    }

                }
            } catch let err {
                self.exportError = err
            }
        }
    }

    func anchorQuery(_ healthStore: HKHealthStore, exportTargets: [ExportTarget], anchor : HKQueryAnchor?) throws -> (anchor:HKQueryAnchor?, count:Int?) {

        let semaphore = DispatchSemaphore(value: 0)
        var resultAnchor: HKQueryAnchor?
        var resultCount: Int?
        let query = HKAnchoredObjectQuery(
            type: type,
            predicate: exportConfiguration.getPredicate(),
            anchor: anchor ,
            limit: queryCountLimit) {
                (query, results, deleted, newAnchor, error) -> Void in

                self.writeResults(results as! [HKCorrelation], exportTargets: exportTargets, error: error as? NSError)
                resultAnchor = newAnchor
                resultCount = results?.count
                semaphore.signal()

        }

        healthStore.execute(query)

        semaphore.wait(timeout: DispatchTime.distantFuture)

        try rethrowCollectedErrors()

        return (anchor:resultAnchor, count: resultCount)
    }

    internal func export(_ healthStore: HKHealthStore, exportTargets: [ExportTarget]) throws {
        for exportTarget in exportTargets {
            try exportTarget.startWriteType(type)
        }

        var result : (anchor:HKQueryAnchor?, count:Int?) = (anchor:nil, count: -1)
        repeat {
            result = try anchorQuery(healthStore, exportTargets: exportTargets, anchor:result.anchor)
        } while result.count != 0 || result.count==queryCountLimit

        for exportTarget in exportTargets {
            try exportTarget.endWriteType()
        }

    }

}

/// exports workout data
internal class WorkoutDataExporter: BaseDataExporter, DataExporter {
    internal var message = "exporting workouts data"

    func writeResults(_ results: [HKWorkout], exportTargets:[ExportTarget], error: NSError?) -> Void {
        if error != nil {
            self.healthQueryError = error
        } else {
            do {
                for exportTarget in exportTargets {
                    try exportTarget.startWriteType(HKObjectType.workoutType())
                }

                for sample in results {

                    var dict: Dictionary<String, AnyObject> = [:]
                    if exportConfiguration.exportUuids {
                        dict[HealthKitConstants.UUID]               = sample.uuid.uuidString as AnyObject
                    }
                    dict[HealthKitConstants.WORKOUT_ACTIVITY_TYPE]  = sample.workoutActivityType.rawValue as AnyObject
                    dict[HealthKitConstants.S_DATE]                 = sample.startDate as AnyObject
                    if sample.startDate != sample.endDate {
                        dict[HealthKitConstants.E_DATE]             = sample.endDate as AnyObject
                    }
                    dict[HealthKitConstants.DURATION]               = sample.duration as AnyObject // seconds
                    dict[HealthKitConstants.TOTAL_DISTANCE]         = sample.totalDistance?.doubleValue(for: HKUnit.meter()) as AnyObject
                    dict[HealthKitConstants.TOTAL_ENERGY_BURNED]    = sample.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) as AnyObject

                    var workoutEvents: [Dictionary<String, AnyObject>] = []
                    for event in sample.workoutEvents ?? [] {
                        var workoutEvent: Dictionary<String, AnyObject> = [:]

                        workoutEvent[HealthKitConstants.TYPE]       =  event.type.rawValue as AnyObject
                        workoutEvent[HealthKitConstants.S_DATE]     = event.date as AnyObject
                        workoutEvents.append(workoutEvent)
                    }

                    dict[HealthKitConstants.WORKOUT_EVENTS]         = workoutEvents as AnyObject

                    for exportTarget in exportTargets {
                        try exportTarget.writeDictionary(dict);
                    }
                }

                for exportTarget in exportTargets {
                    try exportTarget.endWriteType()
                }

            } catch let err {
                self.exportError = err
            }
        }
    }


    internal func export(_ healthStore: HKHealthStore, exportTargets: [ExportTarget]) throws {

        let semaphore = DispatchSemaphore(value: 0)

        let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: exportConfiguration.getPredicate(), limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) { (query, results, error) -> Void in
            if(error != nil){
                if (error! as NSError).code == 5 {
                    self.writeResults([HKWorkout](), exportTargets:exportTargets, error:nil)
                    semaphore.signal()
                }else{
                    self.writeResults([HKWorkout](), exportTargets:exportTargets, error:error as NSError?)
                    semaphore.signal()
                }
            }else{
                self.writeResults(results as! [HKWorkout], exportTargets:exportTargets, error:error as NSError?)
                semaphore.signal()
            }

        }

        healthStore.execute(query)

        // wait for asyn call to complete
        semaphore.wait(timeout: DispatchTime.distantFuture)

        try rethrowCollectedErrors()
    }
}
