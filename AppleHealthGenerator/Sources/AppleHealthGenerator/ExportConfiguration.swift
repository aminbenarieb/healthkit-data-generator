//
//  ExportConfiguration.swift
//  Pods
//
//  Created by Michael Seemann on 16.10.15.
//
//

import Foundation
import HealthKit

// swiftlint:disable all

/**
    Description of what should be exported.
*/
public protocol ExportConfiguration {
    /// what should be exported - see HealthDataToExportType
    var exportType:HealthDataToExportType {get}
    /// the name of the profile
    var profileName:String {get}
    /// should uuids be exported or not
    var exportUuids:Bool {get}
    /// export start date
    var startDate:Date {get}
    /// export end date
    var endDate:Date {get}
    /// should authorize HK parameters from user or not
    var shouldAuthorize:Bool {get}

}

// possible configuration extension:
// export correlations even if they are present in the correlation type section
// export endDate always - even if the endDate and startDate are the same

internal extension ExportConfiguration {

    func getPredicate() -> NSPredicate? {

//        let predicateNoCorreltion = HKQuery.predicateForObjectsWithNoCorrelation()
        //let predicateNoCorreltion = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date().addingTimeInterval(-60 * 60 * 23)),end: Calendar.current.startOfDay(for: Date()),options: .strictEndDate)
        let predicateNoCorreltion = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)

        switch exportType {
        case .ALL:
            return predicateNoCorreltion
        case .ADDED_BY_THIS_APP:
            return NSCompoundPredicate(andPredicateWithSubpredicates: [predicateNoCorreltion, HKQuery.predicateForObjects(from: HKSource.default())])
        case .GENERATED_BY_THIS_APP:
            return NSCompoundPredicate(andPredicateWithSubpredicates: [predicateNoCorreltion, HKQuery.predicateForObjects(withMetadataKey: "GeneratorSource", allowedValues: ["HSG"])])
        }

    }
}

/**
    Epxort the whole Data from first Entry up to the current Date. E.g. full means the whole period of time.
*/
public struct HealthDataFullExportConfiguration : ExportConfiguration {

    /// what should be exported - see HealthDataToExportType
    public var exportType = HealthDataToExportType.ALL // required
    /// the name of the profile
    public var profileName: String // required
    /// should uuids be exported or not
    public var exportUuids = false

    public var startDate: Date // required

    public var endDate: Date // required

    public var shouldAuthorize: Bool // required

    /**
        instantiate a HealthDataFullExportConfiguration.
        - Parameter profileName: the name of the profile
        - Parameter exportType: what should be exported. see HealthDataToExportType
    */
    public init(profileName:String, exportType: HealthDataToExportType, startDate: Date, endDate: Date, shouldAuthorize: Bool){
        self.profileName = profileName
        self.exportType = exportType
        self.startDate = startDate
        self.endDate = endDate
        self.shouldAuthorize = shouldAuthorize
    }
}
