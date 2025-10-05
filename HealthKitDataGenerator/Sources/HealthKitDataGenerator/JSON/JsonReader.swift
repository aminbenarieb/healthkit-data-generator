//
//  JsonReader.swift
//  HealthKitDataGenerator
//
//  Created by Michael Seemann on 23.10.15.
//
//

import Foundation

/// The JsonReader supports different ways to read json.
internal class JsonReader {

    /// Converts a jsonString to an object.
    /// - Parameter jsonString: the json string that should be read.
    /// - Returns: an Object of type AnyObject that the json string defines.
    static func toJsonObject(_ jsonString: String) -> AnyObject {
        let data = jsonString.data(using: String.Encoding.utf8)!
        let result = try! JSONSerialization.jsonObject(with: data, options: .allowFragments)
        return result as AnyObject
    }

    /// Converts a jsonString to an object and returns a dictionary for the provided key.
    /// - Parameter jsonString: the json string that should be read.
    /// - Parameter returnDictForKey: name of the field that should be returned as Dictionary.
    /// - Returns: a dictionary for the key with AnyObject values.
    static func toJsonObject(_ jsonString: String, returnDictForKey: String) -> Dictionary<String, AnyObject> {
        let keyWithDictInDict = JsonReader.toJsonObject(jsonString) as! Dictionary<String, AnyObject>
        return keyWithDictInDict[returnDictForKey] as! Dictionary<String, AnyObject>
    }

    /// Converts a jsonString to an object and returns an array for the provided key.
    /// - Parameter jsonString: the json string that should be read.
    /// - Parameter returnArrayForKey: name of the field that should be returned as an Array.
    /// - Returns: an array for the key with AnyObject values.
    static func toJsonObject(_ jsonString: String, returnArrayForKey: String) -> [AnyObject] {
        let keyWithDictInDict = JsonReader.toJsonObject(jsonString) as! Dictionary<String, AnyObject>
        return keyWithDictInDict[returnArrayForKey] as! [AnyObject]
    }

    /// Reads a json from a file and triggers events specified by JsonHandlerProtocol. Main objective: low memory consumption for very large json files. Besides it is possible to stop the parsing process.
    /// - Parameter fileAtPath: The json file that should be read.
    /// - Parameter withJsonHandler: an object that implements JsonHandlerProtocol to process the json events.
    static func readFileAtPath(_ fileAtPath: String, withJsonHandler jsonHandler: JsonHandlerProtocol) -> Void {
        let inStream = InputStream(fileAtPath: fileAtPath)!
        inStream.open()

        let tokenizer = JsonTokenizer(jsonHandler:jsonHandler)

        let bufferSize = 4096
        var buffer = Array<UInt8>(repeating: 0, count: bufferSize)

        while inStream.hasBytesAvailable && !jsonHandler.shouldCancelReadingTheJson() {
            let bytesRead = inStream.read(&buffer, maxLength: bufferSize)
            if bytesRead > 0 {
                let textFileContents = NSString(bytes: &buffer, length: bytesRead, encoding: String.Encoding.utf8.rawValue)
                tokenizer.tokenize(textFileContents as! String)
            }
        }

        inStream.close()
    }
}

