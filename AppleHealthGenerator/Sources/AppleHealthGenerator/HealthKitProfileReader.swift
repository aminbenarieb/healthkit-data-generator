//
//  HealthKitProfileReader.swift
//  Pods
//
//  Created by Michael Seemann on 24.10.15.
//
//

import Foundation
import HealthKit

// swiftlint:disable all

/// Utility class to generate Profiles from files in a directory
open class HealthKitProfileReader {

    /**
        Creates an array of profiles that are stored in a folder
        - Parameter folder: Url of the folder
        - Returns: an array of HealthKitProfile objects
    */
    public static func readProfilesFromDisk(_ healthStore: HKHealthStore, _ folder: URL) -> [HealthKitProfile]{

        var profiles:[HealthKitProfile] = []
        let enumerator = FileManager.default.enumerator(atPath: folder.path)
        for file in enumerator! {
            let pathUrl = folder.appendingPathComponent(file as! String)
            if FileManager.default.isReadableFile(atPath: pathUrl.path) && pathUrl.pathExtension == "hsg" {
                profiles.append(HealthKitProfile(healthStore: healthStore, fileAtPath:pathUrl))
            }
        }

        return profiles
    }

}
