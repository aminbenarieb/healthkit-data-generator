//
//  ExportTarget.swift
//  Pods
//
//  Created by Michael Seemann on 16.10.15.
//
//

import Foundation
import HealthKit

// swiftlint:disable all

/// a protocol every ExportTarget must conform to.
public protocol ExportTarget {
    /// is the ExportTarget instance valid - see implementations for details
    func isValid() -> Bool
    /// the export has started
    func startExport() throws -> Void
    /// the export has ended
    func endExport() throws -> Void

    /// output the metadata of the profile
    func writeMetaData(creationDate: Date, profileName: String, version: String) throws -> Void
    /// output the user data from healthkit
    func writeUserData(_ userData: Dictionary <String, AnyObject>) throws -> Void
    /// start writing a type
    func startWriteType(_ type:HKSampleType) throws -> Void
    /// end writing a type
    func endWriteType() throws -> Void
    /// write a dictionary to the output - e.g. a dict of the sample data
    func writeDictionary(_ entry:Dictionary <String, AnyObject>) throws -> Void
}

/// An export target that generetes a single json doc for the whole data.
open class JsonSingleDocExportTarget  {

    fileprivate(set) var jsonWriter: JsonWriter

    init(outputStream: OutputStream){
        self.jsonWriter = JsonWriter(outputStream: outputStream)
    }

    /// see ExportTarget Protocol
    open func startExport() -> Void {
        jsonWriter.writeStartObject()
    }

    /// see ExportTarget Protocol
    open func endExport() {
        jsonWriter.writeEndObject()
        jsonWriter.close()
    }

    /// see ExportTarget Protocol
    open func writeMetaData(creationDate: Date, profileName: String, version: String) {

        jsonWriter.writeObjectFieldStart(HealthKitConstants.META_DATA)

        jsonWriter.writeField(HealthKitConstants.CREATION_DATE, value: creationDate)
        jsonWriter.writeField(HealthKitConstants.PROFILE_NAME, value: profileName)
        jsonWriter.writeField(HealthKitConstants.VERSION, value: version)
        jsonWriter.writeField(HealthKitConstants.TYPE, value: String(describing: JsonSingleDocExportTarget.self))

        jsonWriter.writeEndObject()
    }

    /// see ExportTarget Protocol
    open func writeUserData(_ userData: Dictionary <String, AnyObject>) throws {
        try jsonWriter.writeFieldWithObject(HealthKitConstants.USER_DATA, value: userData)
    }

    /// see ExportTarget Protocol
    open func startWriteType(_ type:HKSampleType) -> Void {
        jsonWriter.writeArrayFieldStart(type.identifier)
    }

    /// see ExportTarget Protocol
    open func endWriteType() -> Void {
        jsonWriter.writeEndArray()
    }

    /// see ExportTarget Protocol
    open func writeDictionary(_ entry:Dictionary <String, AnyObject>) throws -> Void {
        try jsonWriter.writeObject(entry)
    }
}

/// an export target that creates a single json doc within a file
open class JsonSingleDocAsFileExportTarget : JsonSingleDocExportTarget, ExportTarget {

    /// the full path of the ouput file
    fileprivate(set) open var outputFileName: String
    fileprivate(set) var overwriteIfExist = false

    /**
        Instantiate a JsonSingleDocAsFileExportTarget.
        - Parameter outputFileName: the full path of the output file
        - Parameter overwriteIfExist: should the file be overwritten if it already exist.
    */
    public init(outputFileName: String, overwriteIfExist:Bool){
        self.outputFileName = outputFileName
        let outputStream = FileOutputStream.init(fileAtPath: outputFileName)
        self.overwriteIfExist = overwriteIfExist
        super.init(outputStream: outputStream)
    }

    /**
        Check the validity of the ExportTarget.
        - Returns: true if the file does not already exist or overwrite is allowed.
    */
    open func isValid() -> Bool {
        var valid = true

        // if the outputFileName already exists, the state is only valid, if overwrite is allowed
        if FileManager.default.fileExists(atPath: outputFileName) {
            valid = valid && overwriteIfExist
        }

        return valid
    }
}

/// an export target that creates a single json doc in memory
open class JsonSingleDocInMemExportTarget: JsonSingleDocExportTarget, ExportTarget {

    /// create a JsonSingleDocExportTarget in Mem
    public init(){
        super.init(outputStream: MemOutputStream())
    }

    /// is always valid
    open func isValid() -> Bool {
        return true
    }

    /// see ExportTarget Protocol
    open func getJsonString() -> String {
        return jsonWriter.getJsonString()
    }
}
