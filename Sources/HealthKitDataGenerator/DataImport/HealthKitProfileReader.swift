
import Foundation
import HealthKit

enum HealthKitProfileReaderError: Error {
    case couldNotReadFolder(URL)
    case couldNotReadFile(URL)
}

/// Utility class to generate Profiles from files in a directory
open class HealthKitProfileReader {

    /// Creates an array of profiles that are stored in a folder
    /// - Parameter folder: Url of the folder
    /// - Returns: an array of HealthKitProfile objects
    public static func readProfilesFromDisk(_ healthStore: HKHealthStore, _ folder: URL) throws -> [HealthKitProfile]  {

        var profiles:[HealthKitProfile] = []
        guard let enumerator = FileManager.default.enumerator(atPath: folder.path) else {
            throw HealthKitProfileReaderError.couldNotReadFolder(folder)
        }
        for file in enumerator {
            let pathUrl = folder.appendingPathComponent(file as! String)
            if FileManager.default.isReadableFile(atPath: pathUrl.path) && pathUrl.pathExtension == "json" {
                profiles.append(try HealthKitProfile(healthStore: healthStore, fileAtPath:pathUrl))
            }
        }

        return profiles
    }
}

