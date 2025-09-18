//
//  HealthKitStoreCleaner.swift
//  Pods
//
//  Created by Michael Seemann on 26.10.15.
//
//

import Foundation
import HealthKit

// swiftlint:disable all

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


public class HealthKitStoreCleaner {

    let healthStore: HKHealthStore

    public init(healthStore: HKHealthStore){
        self.healthStore = healthStore
    }


    /*
     healthStore.deleteObjectsOfType results to
     Error Domain=NSCocoaErrorDomain Code=4097 "connection to service named com.apple.healthd.server" UserInfo={NSDebugDescription=connection to service named com.apple.healthd.server
     in the simulator -> query and delete with healthStore.deleteObjects works :(
    */
    /**
        Cleans all HealthKIt data from the healthkit store that are created by this app.
        - Parameter onProgress: callback that informs about the cleaning progress
    */
    public func clean( _ onProgress: @escaping (_ message: String, _ progressInPercent: Double?)->Void){

        let source = HKSource.default()
        let predicate = HKQuery.predicateForObjects(from: source)

        let allTypes = HealthKitConstants.authorizationWriteTypes()

        for type in allTypes {

            let semaphore = DispatchSemaphore(value: 0)

            onProgress("deleting \(type)", nil)

            let queryCountLimit = 10000
            var result : (anchor:HKQueryAnchor?, count:Int?) = (anchor:nil, count: -1)
            repeat {
                let query = HKAnchoredObjectQuery(
                    type: type,
                    predicate: predicate,
                    anchor: result.anchor,
                    limit: queryCountLimit) {
                        (query, results, deleted, newAnchor, error) -> Void in

                        if results?.count > 0 {
                            self.healthStore.delete(results!, withCompletion: {
                                (success:Bool, error:Error?) -> Void in
                                if success {
									if results?.isEmpty == false {
										onProgress("deleted \(results?.count ?? 0) from \(type)", nil)
									}
                                } else {
									onProgress("ERROR deleting \(type), \(String(describing: error?.localizedDescription))", nil)
                                }
                                semaphore.signal()
                            })
                        } else {
                             semaphore.signal()
                        }

                        result.anchor = newAnchor
                        result.count = results?.count
                }

                healthStore.execute(query)

                _ = semaphore.wait(timeout: DispatchTime.distantFuture)

            } while result.count != 0 || result.count==queryCountLimit

        }

    }
}
