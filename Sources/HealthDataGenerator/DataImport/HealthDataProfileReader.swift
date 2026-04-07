
import Foundation
import HealthKit

enum HealthDataProfileReaderError: Error {
    case couldNotReadFolder(URL)
    case couldNotReadFile(URL)
}

/// Utility class to generate Profiles from files in a directory
open class HealthDataProfileReader {

    /// Creates an array of profiles that are stored in a folder
    /// - Parameter folder: Url of the folder
    /// - Returns: an array of HealthDataProfile objects
    public static func readProfilesFromDisk(_ healthStore: HKHealthStore, _ folder: URL) throws -> [HealthDataProfile]  {

        var profiles:[HealthDataProfile] = []
        guard let enumerator = FileManager.default.enumerator(atPath: folder.path) else {
            throw HealthDataProfileReaderError.couldNotReadFolder(folder)
        }
        for file in enumerator {
            let pathUrl = folder.appendingPathComponent(file as! String)
            if FileManager.default.isReadableFile(atPath: pathUrl.path) && pathUrl.pathExtension == "json" {
                profiles.append(try HealthDataProfile(healthStore: healthStore, fileAtPath:pathUrl))
            }
        }

        return profiles
    }
}

