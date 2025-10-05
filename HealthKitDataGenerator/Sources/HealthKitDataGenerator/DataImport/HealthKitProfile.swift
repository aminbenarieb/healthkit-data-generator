
import Foundation
import HealthKit

// MARK: - Profile Metadata

/// MetaData of a profile
open class HealthKitProfileMetaData {
    /// the name of the profile
    fileprivate(set) open var profileName: String?
    /// the date the profile was exported
    fileprivate(set) open var creationDate: Date?
    /// the version of the profile
    fileprivate(set) open var version: String?
    /// the type of the profile
    fileprivate(set) open var type: String?
}

// MARK: - HealthKit Profile

/// A healthkit Profile - can be used to read data from the profile and import the profile into the healthkit store.
open class HealthKitProfile : CustomStringConvertible {

    private let healthStore: HKHealthStore
    
    let fileAtPath: URL
    /// the name of the profile file - without any path components
    fileprivate(set) open var fileName: String
    /// the size of the profile file in bytes
    fileprivate(set) open var fileSize:UInt64?

    let fileReadQueue = OperationQueue()

    /// for textual representation of this object
    open var description: String {
        return "\(fileName) \(fileSize)"
    }

    /// Constructor for a profile
    /// - Parameter fileAtPath: the Url of the profile in the file system
    public init(healthStore: HKHealthStore, fileAtPath: URL){
        fileReadQueue.maxConcurrentOperationCount = 1
        fileReadQueue.qualityOfService = QualityOfService.userInteractive
        self.fileAtPath = fileAtPath
        self.fileName   = self.fileAtPath.lastPathComponent
        self.healthStore = healthStore
        let attr:NSDictionary? = try! FileManager.default.attributesOfItem(atPath: fileAtPath.path) as NSDictionary
        if let _attr = attr {
            self.fileSize = _attr.fileSize();
        }
    }

    /// Load the MetaData of a profile. If the metadata have been read the reading is
    /// interrupted - by this way also very large files are supported too.
    /// - Returns: the HealthKitProfileMetaData that were read from the profile.
    internal func loadMetaData() -> HealthKitProfileMetaData {
        let result          = HealthKitProfileMetaData()
        let metaDataOutput  = MetaDataOutputJsonHandler()

        JsonReader.readFileAtPath(self.fileAtPath.path, withJsonHandler: metaDataOutput)

        let metaData = metaDataOutput.getMetaData()

        if let dateTime = metaData["creationDate"] as? NSNumber {
            result.creationDate = Date(timeIntervalSince1970: dateTime.doubleValue/1000)
        }

        result.profileName  = metaData["profileName"] as? String
        result.version      = metaData["version"] as? String
        result.type         = metaData["type"] as? String

        return result
    }

    /// Load the MetaData of a profile. If the metadata have been read the reading is
    /// interrupted - by this way also very large files are supported too.
    /// - Parameter asynchronous: if true the metadata will be read asynchronously. If false the read will be synchronous.
    /// - Parameter callback: is called if the metadata have been read.
    open func loadMetaData(_ asynchronous:Bool, callback:@escaping (_ metaData: HealthKitProfileMetaData) -> Void ){

        if asynchronous {
            fileReadQueue.addOperation(){
                callback(self.loadMetaData())
            }
        } else {
            callback(loadMetaData())
        }
    }

    /// Reads all samples from the profile and fires the callback onSample on every sample.
    /// - Parameter onSample: the callback is called on every sample.
    func importSamples(_ onSample: @escaping (_ sample: HKSample) -> Void) throws {

        let sampleImportHandler = SampleOutputJsonHandler(){ [weak self]
            (sampleDict:AnyObject, typeName: String) in
            guard let self else { return }
            
            if let creator = SampleCreatorRegistry.get(self.healthStore, typeName) {
                let sampleOpt:HKSample? = creator.createSample(sampleDict)
                if let sample = sampleOpt {
                    onSample(sample)
                }
            }
        }

        JsonReader.readFileAtPath(self.fileAtPath.path, withJsonHandler: sampleImportHandler)
    }

    /// Removes the profile from the file system
    open func deleteFile() throws {
        try FileManager.default.removeItem(atPath: fileAtPath.path)
    }
}

