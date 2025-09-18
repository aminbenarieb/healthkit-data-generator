//
//  HealthKitConstants.swift
//  Pods
//
//  Created by Michael Seemann on 26.10.15.
//
//

import Foundation
import HealthKit

// swiftlint:disable all

public class HealthKitConstants {

    static let UUID                     = "uuid"
    static let WORKOUT_ACTIVITY_TYPE    = "workoutActivityType"
    static let S_DATE                   = "sdate"
    static let E_DATE                   = "edate"
    static let DURATION                 = "duration"
    static let TOTAL_DISTANCE           = "totalDistance"
    static let TOTAL_ENERGY_BURNED      = "totalEnergyBurned"
    static let TYPE                     = "type"
    static let WORKOUT_EVENTS           = "workoutEvents"
    static let UNIT                     = "unit"
    static let VALUE                    = "value"
    static let OBJECTS                  = "objects"
    static let DATE_OF_BIRTH            = "dateOfBirth"
    static let BIOLOGICAL_SEX           = "biologicalSex"
    static let BLOOD_TYPE               = "bloodType"
    static let FITZPATRICK_SKIN_TYPE    = "fitzpatrickSkinType"
    static let META_DATA                = "metaData"
    static let SOURCE                   = "source"
    static let CREATION_DATE            = "creationDate"
    static let PROFILE_NAME             = "profileName"
    static let VERSION                  = "version"
    static let USER_DATA                = "userData"


    static let healthKitCharacteristicsTypes: Set<HKCharacteristicType> = Set(arrayLiteral:
        HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)!,
        HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)!,
        HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.bloodType)!,
        HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.fitzpatrickSkinType)!
    )

    static let healthKitCategoryTypes: Set<HKCategoryType> = Set(arrayLiteral:
        HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!,
        HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.cervicalMucusQuality)!,
        HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.ovulationTestResult)!,
        HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.menstrualFlow)!,
        HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.intermenstrualBleeding)!,
		HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sexualActivity)!,
		HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.mindfulSession)!
//        HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.appleStandHour)!
    )

    // not writable
    static let healthKitCategoryLockedTypes: Set<HKCategoryType> = Set(arrayLiteral:
        HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.appleStandHour)!
    )

    static let healthKitQuantityTypes: Set<HKQuantityType> = Set(arrayLiteral:
        // Body Measurements
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMassIndex)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyFatPercentage)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.leanBodyMass)!,
        // Fitness
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceCycling)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.basalEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.flightsClimbed)!,
        // Vitals
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyTemperature)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.basalBodyTemperature)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureSystolic)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.respiratoryRate)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.restingHeartRate)!,
//        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.walkingHeartRateAverage)!,
        // Results
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.oxygenSaturation)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.peripheralPerfusionIndex)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodGlucose)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.numberOfTimesFallen)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.electrodermalActivity)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.inhalerUsage)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodAlcoholContent)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.forcedVitalCapacity)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.forcedExpiratoryVolume1)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.peakExpiratoryFlowRate)!,
        // Nutrition
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatTotal)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatPolyunsaturated)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatMonounsaturated)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatSaturated)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCholesterol)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietarySodium)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCarbohydrates)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFiber)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietarySugar)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryProtein)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryVitaminA)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryVitaminB6)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryVitaminB12)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryVitaminC)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryVitaminD)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryVitaminE)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryVitaminK)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCalcium)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryIron)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryThiamin)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryRiboflavin)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryNiacin)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFolate)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryBiotin)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryPantothenicAcid)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryPhosphorus)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryIodine)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryMagnesium)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryZinc)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietarySelenium)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCopper)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryManganese)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryChromium)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryMolybdenum)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryChloride)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryPotassium)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCaffeine)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryWater)!,
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.uvExposure)!
    )

    //not writable
    static let healthKitQuantityLockedTypes: Set<HKQuantityType> = Set(arrayLiteral:
                HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.nikeFuel)!
    )

    static let healthKitCorrelationTypes: Set<HKCorrelationType> = Set(arrayLiteral:
        HKObjectType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.bloodPressure)!,
        HKObjectType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.food)!
    )

    static let workoutType = HKObjectType.workoutType()
    
    static let heartbeatSeriesType = HKSeriesType.heartbeat() //HKObjectType.seriesType(forIdentifier: HKDataTypeIdentifierHeartbeatSeries)

    static func allTypes() -> Set<HKObjectType> {
        var allTypes : Set<HKObjectType> = Set()
        allTypes.formUnion((healthKitCharacteristicsTypes as Set<HKObjectType>?)!)
        allTypes.formUnion((healthKitQuantityTypes as Set<HKObjectType>?)!)
        allTypes.formUnion((healthKitCategoryTypes as Set<HKObjectType>?)!)
        allTypes.formUnion((healthKitCorrelationTypes as Set<HKObjectType>?)!)
        allTypes.insert(workoutType)
        return allTypes
    }

    public static func authorizationReadTypes() -> Set<HKObjectType> {
        var authTypes : Set<HKObjectType> = Set()
        authTypes.formUnion((HealthKitConstants.healthKitCharacteristicsTypes as Set<HKObjectType>?)!)
        authTypes.formUnion((HealthKitConstants.healthKitQuantityTypes as Set<HKObjectType>?)!)
        authTypes.formUnion((HealthKitConstants.healthKitQuantityLockedTypes as Set<HKObjectType>?)!)
        authTypes.formUnion((HealthKitConstants.healthKitCategoryTypes as Set<HKObjectType>?)!)
        authTypes.formUnion((HealthKitConstants.healthKitCategoryLockedTypes as Set<HKObjectType>?)!)
        authTypes.insert(HealthKitConstants.workoutType)
        return authTypes
    }

    public static func authorizationWriteTypes() -> Set<HKSampleType> {
         var authTypes : Set<HKSampleType> = Set()
        authTypes.formUnion((HealthKitConstants.healthKitQuantityTypes as Set<HKSampleType>?)!)
        authTypes.formUnion((HealthKitConstants.healthKitCategoryTypes as Set<HKSampleType>?)!)
        authTypes.insert(HealthKitConstants.workoutType)
        authTypes.insert(HealthKitConstants.heartbeatSeriesType)
        return authTypes
    }

}
