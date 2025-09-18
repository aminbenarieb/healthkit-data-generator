//
//  JsonReader.swift
//  Pods
//
//  Created by Michael Seemann on 23.10.15.
//
//

import Foundation

// swiftlint:disable all

/**
 The JsonReader supports different ways to read json.
*/
internal class JsonReader {

    /**
        converts a jsonString to an object.
        - Parameter jsonString: the json string that should be read.
        - Returns: an Object of type AnyObject that the json string defines.
    */
    static func toJsonObject(_ jsonString: String) -> AnyObject {
        let data = jsonString.data(using: String.Encoding.utf8)!
        let result = try! JSONSerialization.jsonObject(with: data, options: .allowFragments)
        return result as AnyObject
    }

    /**
     Converts a jsonString to an object and returns a dictionary for the provided key.
     - Parameter jsonString: the json string that should be read.
     - Parameter returnDictForKey: name of the field that should be returned as Dictionary.
     - Returns: a dictionaray for the key with AnyObject values.
     */
    static func toJsonObject(_ jsonString: String, returnDictForKey: String) -> Dictionary<String, AnyObject> {
        let keyWithDictInDict = JsonReader.toJsonObject(jsonString) as! Dictionary<String, AnyObject>
        return keyWithDictInDict[returnDictForKey] as! Dictionary<String, AnyObject>
    }

    /**
     Converts a jsonString to an object and returns an array for the provided key.
     - Parameter jsonString: the json string that should be read.
     - Parameter returnArrayForKey: name of the field that should be returned as an Array.
     - Returns: an array for the key with AnyObject values.
     */
    static func toJsonObject(_ jsonString: String, returnArrayForKey: String) -> [AnyObject] {
        let keyWithDictInDict = JsonReader.toJsonObject(jsonString) as! Dictionary<String, AnyObject>
        return keyWithDictInDict[returnArrayForKey] as! [AnyObject]
    }

    /**
        Reads a json from a file and triggers events specified by JsonHandlerProtocol. Main objective: low memory consumtion for very large json files. Besides it is possible to stop the parsing process.
        - Parameter fileAtPath: The json file that should be read.
        - Parameter withJsonHandler: an object that implements JsonHandlerProtocol to process the json events.

    */
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

/**
 JsonReaderContext keeps the state while tokenizing a json steam.
*/
internal class JsonReaderContext {
    var type: JsonContextType
    fileprivate var parent: JsonReaderContext?

    var nameOrObject = "" {
        didSet {
            //print("nameOrObject:", nameOrObject)
        }
    }

    var inNameOrObject = false {
        didSet {
            //print("in name or object:", inNameOrObject)
        }
    }

    init(){
        type = .root
    }

    convenience init(parent: JsonReaderContext, type: JsonContextType){
        self.init()
        self.parent = parent
        self.type = type
    }

    func createArrayContext() -> JsonReaderContext {
        //print("create array context")
        return JsonReaderContext(parent: self, type: .array)
    }

    func createObjectContext() -> JsonReaderContext {
        //print("create object context")
        return JsonReaderContext(parent: self, type: .object)
    }

    func popContext() -> JsonReaderContext? {
        parent?.inNameOrObject = false
        return parent
    }
}

/**
 The JsonTokenizer reads a json from smal parts and triggers the events for the JsonHandlerProtocol. The function tokenize may be calld as often as need to process the complete json string.
 There are still some unsupported json features like escaped characters and whitespace.
*/
public class JsonTokenizer {
    // TODO escpaped chars  "b", "f", "n", "r", "t", "\\" whitespace
    let jsonHandler: JsonHandlerProtocol
    var context = JsonReaderContext()



    public init(jsonHandler: JsonHandlerProtocol){
        self.jsonHandler = jsonHandler
    }

    /**
        removes the question marks from a string.
    */
    internal func removeQuestionMarks(_ str: String) -> String{
        var result = str
        result.remove(at: result.startIndex)
        result.remove(at: result.index(before: result.endIndex))
        return result
    }

    /**
        outputs a name.
    */
    internal func writeName(_ context: JsonReaderContext) {
        //print("writeName", context.nameOrObject)
        let name = removeQuestionMarks(context.nameOrObject)
        jsonHandler.name(name)
        context.nameOrObject = ""
        context.inNameOrObject = true
    }

    /**
     outputs a value. Value can be a string, a boolean value a null value or a number.
     */
    internal func writeValue(_ context: JsonReaderContext){
        //print("writeValue", context.nameOrObject)
        let value:String = context.nameOrObject
        context.nameOrObject = ""


        if value.hasPrefix("\"") &&  value.hasSuffix("\""){
            let strValue = removeQuestionMarks(value)
            self.jsonHandler.stringValue(strValue)
        } else if value == "true" {
            self.jsonHandler.boolValue(true)
        } else if value == "false" {
            self.jsonHandler.boolValue(false)
        } else  if value == "null" {
            self.jsonHandler.nullValue()
        } else  {
            // TODO: chekout why this code leaks! with this code 1,5GB Mem  used without 13MB after reading a 70MB GB Json file!!
            // set to en, so that the numbers with . will be parsed correctly
            //let numberFormatter = NSNumberFormatter()
            //numberFormatter.locale = NSLocale(localeIdentifier: "EN")
            //let number = numberFormatter.numberFromString(value)!

            if let intValue = Int(value) {
                jsonHandler.numberValue(NSNumber(value: intValue))
            } else if let doubleValue = Double(value) {
                jsonHandler.numberValue(NSNumber(value: doubleValue))
            }


            //self.jsonHandler.numberValue(number)
        }
    }

    internal func endObject() {
        if context.nameOrObject != "" {
            writeValue(context)
        }
		if let parent = context.popContext() {
			context = parent
		}
        jsonHandler.endObject()
    }

    internal func endArray() {
        if context.nameOrObject != "" {
            writeValue(context)
        }
		if let parent = context.popContext() {
			context = parent
		}
        jsonHandler.endArray()
    }

    /**
        main tokenizer function. The string may have any size.
    */
    public func tokenize(_ toTokenize: String) -> Void {
        for chr in toTokenize {
            //print(chr)
            switch chr {
            case "\"":
                if !context.inNameOrObject {
                    context.inNameOrObject = true
                    context.nameOrObject = ""
                }
                context.nameOrObject += String(chr)
            case "{":
                if context.inNameOrObject && context.nameOrObject.hasPrefix("\"") {
                    context.nameOrObject += String(chr)
                } else {
                    context = context.createObjectContext()
                    jsonHandler.startObject()
                }
            case "}":
                if context.inNameOrObject {
                    if context.nameOrObject.hasPrefix("\"") &&  context.nameOrObject.hasSuffix("\"") {
                        endObject()
                    } else if context.nameOrObject.hasPrefix("\"") &&  !context.nameOrObject.hasSuffix("\""){
                        context.nameOrObject += String(chr)
                    } else {
                        endObject()
                    }
                } else {
                    endObject()
                }
            case "[":
                if !context.inNameOrObject || context.nameOrObject == "" {
                    context = context.createArrayContext()
                    jsonHandler.startArray()
                    context.inNameOrObject = true
                } else {
                    context.nameOrObject += String(chr)
                }
            case "]":
                if context.inNameOrObject {
                    if context.nameOrObject.hasPrefix("\"") &&  context.nameOrObject.hasSuffix("\"") {
                        endArray()
                    } else if context.nameOrObject.hasPrefix("\"") &&  !context.nameOrObject.hasSuffix("\""){
                        context.nameOrObject += String(chr)
                    } else {
                        endArray()
                    }
                } else {
                    endArray()
                }
            case ":":
                if context.inNameOrObject {
                    if context.nameOrObject.hasPrefix("\"") &&  context.nameOrObject.hasSuffix("\"") {
                        writeName(context)
                    } else if context.nameOrObject.hasPrefix("\"") &&  !context.nameOrObject.hasSuffix("\""){
                        context.nameOrObject += String(chr)
                    } else {
                        writeName(context)
                    }
                }
            case ",":
                if context.inNameOrObject  {
                    if context.nameOrObject.hasPrefix("\"") &&  context.nameOrObject.hasSuffix("\"") {
                        writeValue(context)
                    } else if context.nameOrObject.hasPrefix("\"") &&  !context.nameOrObject.hasSuffix("\""){
                        context.nameOrObject += String(chr)
                    } else {
                        writeValue(context)
                    }
                }
            default:
                if context.inNameOrObject && String(chr) != " " && String(chr) != "\n" && String(chr) != "\t" {
                    context.nameOrObject += String(chr)
                }
            }
        }
    }
}

/**
 Protocoll with function that will be called during the json tokenizing process.
*/
public protocol JsonHandlerProtocol {
    // an array starts
    func startArray()
    // an array ended
    func endArray()

    // an object starts
    func startObject()
    // an object ended
    func endObject()

    // a name was tokenized
    func name(_ name: String)
    // a string value was tokenized
    func stringValue(_ value: String)
    // a boolean value was tokenized
    func boolValue(_ value: Bool)
    // a number was tokenized
    func numberValue(_ value: NSNumber)
    // a null value was tokenized
    func nullValue()

    // return true if you want the tokenizer to stop.
    func shouldCancelReadingTheJson() -> Bool
}

/**
 A default impelmentation of the JsonHandlerProtocol. Use this class if you don't need to listen to every json event.
*/
class DefaultJsonHandler : JsonHandlerProtocol {
    func startArray(){}
    func endArray(){}

    func startObject(){}
    func endObject(){}

    func name(_ name: String){}
    func stringValue(_ value: String){}
    func boolValue(_ value: Bool){}
    func numberValue(_ value: NSNumber){}
    func nullValue(){}

    func shouldCancelReadingTheJson() -> Bool {
        return false;
    }
}

/**
 The JsonStringOutputJsonHandler transforms the json parsing events in a json string. Main purpose: make testing of the reader as easy as possible.
*/
class JsonStringOutputJsonHandler: DefaultJsonHandler {

    let memOutputStream : MemOutputStream!
    let jw:JsonWriter!

    var json:String {
        get {
            return jw.getJsonString()
        }
    }

    override init(){
        memOutputStream = MemOutputStream()
        jw = JsonWriter(outputStream: memOutputStream)
    }

    override func startArray(){
        jw.writeStartArray()
    }

    override func endArray(){
        jw.writeEndArray()
    }

    override func startObject() {
        jw.writeStartObject()
    }

    override func endObject() {
        jw.writeEndObject()
    }

    override func name(_ name: String){
        jw.writeFieldName(name)
    }

    override func stringValue(_ value: String) {
        jw.writeString(value)
    }

    override func numberValue(_ value: NSNumber) {
        jw.writeNumber(value)
    }

    override func boolValue(_ value: Bool) {
        jw.writeBool(value)
    }

    override func nullValue() {
        jw.writeNull()
    }

}
