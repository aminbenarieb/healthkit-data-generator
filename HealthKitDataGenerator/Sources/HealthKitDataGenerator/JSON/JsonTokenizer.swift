//
//  JsonTokenizer.swift
//  HealthKitDataGenerator
//
//  Created by Michael Seemann on 23.10.15.
//
//

import Foundation

// MARK: - JSON Context Types

enum JsonContextType : Int {
    case root
    case array
    case object
}

// MARK: - JSON Reader Context

/// JsonReaderContext keeps the state while tokenizing a json steam.
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

// MARK: - JSON Tokenizer

/// The JsonTokenizer reads a json from small parts and triggers the events for the JsonHandlerProtocol. The function tokenize may be called as often as needed to process the complete json string.
/// There are still some unsupported json features like escaped characters and whitespace.
public class JsonTokenizer {
    // TODO escaped chars  "b", "f", "n", "r", "t", "\\" whitespace
    let jsonHandler: JsonHandlerProtocol
    var context = JsonReaderContext()

    public init(jsonHandler: JsonHandlerProtocol){
        self.jsonHandler = jsonHandler
    }

    /// Removes the question marks from a string.
    internal func removeQuestionMarks(_ str: String) -> String{
        var result = str
        result.remove(at: result.startIndex)
        result.remove(at: result.index(before: result.endIndex))
        return result
    }

    /// Outputs a name.
    internal func writeName(_ context: JsonReaderContext) {
        //print("writeName", context.nameOrObject)
        let name = removeQuestionMarks(context.nameOrObject)
        jsonHandler.name(name)
        context.nameOrObject = ""
        context.inNameOrObject = true
    }

    /// Outputs a value. Value can be a string, a boolean value a null value or a number.
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
            // TODO: checkout why this code leaks! with this code 1,5GB Mem  used without 13MB after reading a 70MB GB Json file!!
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

    /// Main tokenizer function. The string may have any size.
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

