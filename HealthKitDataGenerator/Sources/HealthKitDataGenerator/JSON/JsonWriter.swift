//
//  JsonWriter.swift
//  HealthKitDataGenerator
//
//  Created by Michael Seemann on 05.10.15.
//
//

import Foundation

// MARK: - JSON Writer Error

enum JsonWriterError: Error {
    case nsjsonSerializationError(String)
}

// MARK: - JSON Writer Status

enum JsonWriterStatus : Int {
    case ok
    case will_NEED_COMMA
    case will_NEED_COLON
}

// MARK: - JSON Writer Context

/// Context that keeps the state of the json output.
class JsonWriterContext {
    var type: JsonContextType
    var parent: JsonWriterContext?
    var index = 0 // no items written to an array
    var startField = false

    init(){
        type = .root
    }

    convenience init(parent: JsonWriterContext, type: JsonContextType){
        self.init()
        self.parent = parent
        self.type = type
    }

    /// Creates an array in the current context.
    func createArrayContext() -> JsonWriterContext {
        writeValue()
        return JsonWriterContext(parent: self, type: .array)
    }
    
    /// Creates an object in the current context.
    func createObjectContext() -> JsonWriterContext {
        writeValue()
        return JsonWriterContext(parent: self, type: .object)
    }

    func writeField(){
        startField = true
    }

    func writeValue() {
        index += 1
        startField = false
    }

    func willStartArray() -> JsonWriterStatus {
        return willWriteField()
    }

    func willStartObject() -> JsonWriterStatus {
        return willWriteField()
    }

    func willWriteField() -> JsonWriterStatus {
        if startField {
            return .will_NEED_COLON
        }
        if(index > 0){
            return .will_NEED_COMMA
        }
        return .ok
    }

    func willWriteValue() -> JsonWriterStatus {
        if startField {
            return .will_NEED_COLON
        }
        if(index > 0){
            return .will_NEED_COMMA
        }
        return .ok
    }
}

// MARK: - JSON Writer

/// Writer for json data that are very large. The strings are written to a output stream so that they not need to be able to fit the device memory.
internal class JsonWriter {

    var outputStream: OutputStream
    var writerContext = JsonWriterContext()

    /// Creates a JsonWriter Object that writes to the provided OutputStream
    /// @parameter outputStream The stream the Json data will be written to.
    internal init (outputStream: OutputStream) {
        self.outputStream = outputStream
    }

    /// Starts writing a new Array (e.g. '[').
    internal func writeStartArray() {
        let status = writerContext.willStartArray()
        writeCommaOrColon(status)
        writerContext = writerContext.createArrayContext()
        write("[")
    }

    /// Writes the end of a json array (e.g. ']').
    internal func writeEndArray() {
        writerContext = writerContext.parent!
        write("]")
    }

    /// Starts writing a new Object (e.g. '{')
    internal func writeStartObject() {
        let status = writerContext.willStartObject()
        writeCommaOrColon(status)
        writerContext = writerContext.createObjectContext()
        write("{")
    }

    /// Writes the end of a json object (e.g. '}')
    internal func writeEndObject() {
        writerContext = writerContext.parent!
        write("}")
    }

    /// Starts writing a field name - a json string that will be written in quotation marks.
    internal func writeFieldName(_ name: String) {
        let status = writerContext.willWriteField()
        writeCommaOrColon(status)
        writerContext.writeField()
        write("\""+name+"\"")
    }

    internal func writeCommaOrColon(_ status: JsonWriterStatus){
        if status == .will_NEED_COMMA {
            write(",")
        } else if status == .will_NEED_COLON {
            write(":")
        }
    }

    /// Writes a String value. All '"' characters will be escaped.
    internal func writeString(_ text: String?) {
        if let v = text {
            let escapedV = v.replacingOccurrences(of: "\"", with: "\"")
            let status = writerContext.willWriteValue()
            writeCommaOrColon(status)
            writerContext.writeValue()
            write("\""+escapedV+"\"")
        } else  {
            writeNull()
        }
    }

    /// Writes a NSNumber. If the NSNumber-object ist a boolean true/false is written to the stream.
    /// If the NSNumber is nil null will be written
    internal func writeNumber(_ number: NSNumber?) {
        if let v = number {
            let status = writerContext.willWriteValue()
            writeCommaOrColon(status)
            writerContext.writeValue()
            if(v.isBoolNumber()){
                // bool is bridged to nsnumber - but we need to keep true and false and not 1 and 0 in json.
                 write(v.boolValue ? "true": "false")
            } else {
                write(v.stringValue)
            }
        } else  {
            writeNull()
        }
    }

    /// Writes a boolean value to the stream - e.g. true or false. If the value is nil null is written to the stream.
    internal func writeBool(_ value: Bool?) {
        if let v = value {
            let status = writerContext.willWriteValue()
            writeCommaOrColon(status)
            writerContext.writeValue()
            write(v ? "true": "false")
        }else{
            writeNull()
        }
    }

    /// Writes an NSDate object to the stream. JSON did not support a date value. Instead the milliseconds since 01.01.1970 will be used.
    internal func writeDate(_ value: Date?) {
        if let date = value {
            let number = NSNumber(value: date.timeIntervalSince1970*1000 as Double)
            writeNumber(number)
        } else {
            writeNull()
        }
    }

    /// Writes null to the stream.
    internal func writeNull() {
        let status = writerContext.willWriteValue()
        writeCommaOrColon(status)
        writerContext.writeValue()
        write("null")
    }

    /// Serialize an array or a dictionary to json. The dictionary values may be String, NSNumber,
    /// NSDate, NSArray or Dictionary<String, AnyObject>
    /// - Parameter anyObject: Object of type [AnyObject] or Dictionary<String, AnyObject>
    /// - Throws: JsonWriterError if a value is of unsupported type.
    internal func writeObject(_ anyObject: Any) throws {
        if let array = anyObject as? [Any] {
            writeStartArray()
            for element in array {
                if let strValue = element as? String {
                    writeString(strValue)
                } else if let numberValue = element as? NSNumber {
                    writeNumber(numberValue)
                } else if let dateValue = element as? Date {
                    writeDate(dateValue)
                } else if let dictValue = element as?  Dictionary<String, AnyObject> {
                    try writeObject(dictValue as AnyObject)
                } else  {
                    throw JsonWriterError.nsjsonSerializationError("unsupported value type: \(type(of: element))")
                }
            }
            writeEndArray()
        }
        else if let dict = anyObject as? Dictionary<String, AnyObject> {
            writeStartObject()
            for (key, value) in dict {
                //print(key, value, value.dynamicType)
                if let strValue = value as? String {
                    writeField(key, value: strValue)
                } else if let numberValue = value as? NSNumber {
                    writeField(key, value: numberValue)
                } else if let dateValue = value as? Date {
                    writeField(key, value: dateValue)
                } else if let arrayValue = value as? NSArray {
                    writeFieldName(key)
                    try writeObject(arrayValue)
                } else  {
                    throw JsonWriterError.nsjsonSerializationError("unsupported value type: \(type(of: value))")
                }
            }
            writeEndObject()
        }else  {
            throw JsonWriterError.nsjsonSerializationError("unsupported value type: \(type(of: anyObject))")
        }
    }

    /// Writes a complete String Field
    /// - Parameter fieldName: The name of the field
    /// - Parameter value: The String value
    internal func writeField(_ fieldName: String, value: String?) {
        writeFieldName(fieldName)
        writeString(value)
    }

    /// Writes a complete Bool Field
    /// - Parameter fieldName: The name of the field
    /// - Parameter value: The Bool value
    internal func writeField(_ fieldName: String, value: Bool?) {
        writeFieldName(fieldName)
        writeBool(value)
    }

    /// Writes a complete NSNumber Field
    /// - Parameter fieldName: The name of the field
    /// - Parameter value: The NSNumber value
    internal func writeField(_ fieldName: String, value: NSNumber?) {
        writeFieldName(fieldName)
        writeNumber(value)
    }

    /// Writes a complete NSDate Field
    /// - Parameter fieldName: The name of the field
    /// - Parameter value: The NSDate value
    internal func writeField(_ fieldName: String, value: Date?) {
        writeFieldName(fieldName)
        writeDate(value)
    }

    /// Writes a complete Object/Array Field
    /// - Parameter fieldName: The name of the field
    /// - Parameter value: The Object/Array value - see function writeObject for more information.
    internal func writeFieldWithObject(_ fieldName: String, value: Any) throws {
        writeFieldName(fieldName)
        try writeObject(value)
    }

    /// Writes a named arrays.
    internal func writeArrayFieldStart(_ fieldName: String) {
        writeFieldName(fieldName)
        writeStartArray()
    }

    /// Writes a named object.
    internal func writeObjectFieldStart(_ fieldName: String) {
        writeFieldName(fieldName)
        writeStartObject()
    }

    /// The underlying output stream will be closed.
    internal func close() {
        outputStream.close()
    }

    /// Writes the string to the output stream. If the stream is not open the stream will be opened.
    internal func write(_ theString: String) {
        if !outputStream.isOpen() {
            outputStream.open()
        }
        outputStream.write(theString)
    }

    /// Get the JSON String that was written to the outputStream. Keep in mind this writer exists to output very large json data. if one reads the complete String the app may crash because of an out of mem problem.
    internal func getJsonString() -> String {
        close()
        return outputStream.getDataAsString()
    }
}

// MARK: - NSNumber Extensions

/// Adds a method to the class NSNumber to check whether a number is a bool.
extension NSNumber {

    func isBoolNumber() -> Bool {
        let boolID = CFBooleanGetTypeID()
        let numID = CFGetTypeID(self)
        return numID == boolID
    }
}

