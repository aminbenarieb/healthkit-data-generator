
import Foundation
import HealthKit
import Logging

// MARK: - Import Errors

/// Errors the importer can create
public enum ImportError: Error {
    /// the type of the profile is not supported
    case unsupportedType(String)
    /// HealthKit is not available on the device
    case healthDataNotAvailable
}

// MARK: - HealthKit Profile Importer

/// Importer for a healthkit profile
open class HealthKitProfileImporter {

    let healthStore: HKHealthStore
    let importQueue = OperationQueue()

    /// Provide your instance of the HKHealthStore
    public init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
        self.importQueue.maxConcurrentOperationCount = 1
        self.importQueue.qualityOfService = QualityOfService.userInteractive
    }

    /// Import a profile in the healthkit store. The import is done on a different thread. You should sync the
    /// callback calls with the main thread if you are updating the ui.
    /// - Parameter profile: the profile to import
    /// - Parameter deleteExistingData: indicates whether the existing healthdata should be deleted before the import (it can only be deleted, what was previously imported by this app).
    /// - Parameter onProgress: callback for progress messages
    /// - Parameter onCompletion: callback if the import has finished. The error is nil if everything went well.
    open func importProfile (
        _ profile: HealthKitProfile,
        deleteExistingData: Bool,
        onProgress: @escaping (_ message: String, _ progressInPercent: NSNumber?)->Void,
        onCompletion: @escaping (_ error: Error?)-> Void) {

            if !HKHealthStore.isHealthDataAvailable() {
                onCompletion(ImportError.healthDataNotAvailable)
                return
            }

            healthStore.requestAuthorization(toShare: HealthKitConstants.authorizationWriteTypes(), read: nil) {
                (success, error) -> Void in
                /// TODO success error handling

                self.importQueue.addOperation(){

                    // check that the type is one of the supported profile types
                    let metaData = profile.loadMetaData()
                    let strExpectedType = String(describing: JsonSingleDocExportTarget.self)
                    if metaData.type != strExpectedType {
                        onCompletion(ImportError.unsupportedType("\(strExpectedType) is only supported"))
                        return
                    }

                    // delete all existing data from healthkit store - if requested.
                    if deleteExistingData {

                        HealthKitStoreCleaner(healthStore: self.healthStore).clean(){(message:String, progressInPercent: Double?) in
                            onProgress(message, progressInPercent == nil ? nil : NSNumber(value: progressInPercent!/2))
                        }

                    }
                    onProgress("Start importing", nil)

                    var lastSampleType = ""
                    try! profile.importSamples(){
                        (sample: HKSample) in
                        //print(sample)

                        if lastSampleType != String(describing: sample.sampleType) {
                            lastSampleType = String(describing: sample.sampleType)
                            onProgress("importing \(lastSampleType)", nil)
                        }

                        self.healthStore.save(sample, withCompletion: {
                            (success:Bool, error:Error?) in
                            if !success {
                                if let error = error {
                                    AppLogger.healthKit.error("Failed to save sample", metadata: [
                                        "error": "\(error.localizedDescription)",
                                        "sampleType": "\(sample.sampleType)"
                                    ])
                                }
                            } else {
                                AppLogger.healthKit.debug("Saved sample", metadata: [
                                    "sampleType": "\(sample.sampleType)"
                                ])
                            }

                        })
                    }

                    onProgress("Import done", 1.0)

                    onCompletion(nil)
                }
            }
    }
}


