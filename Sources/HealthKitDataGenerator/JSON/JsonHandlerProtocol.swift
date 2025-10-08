
import Foundation
import Logging

// MARK: - JSON Handler Protocol

/// Protocol with function that will be called during the json tokenizing process.
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

// MARK: - Default JSON Handler

/// A default implementation of the JsonHandlerProtocol. Use this class if you don't need to listen to every json event.
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

// MARK: - Metadata Output JSON Handler

/// A Json Output Handler that reads the metadata from a profile file
class MetaDataOutputJsonHandler: DefaultJsonHandler {

    var name:String?
    var collectProperties = false
    var metaDataDict:Dictionary<String,AnyObject> = [:]
    var cancel = false

    func getMetaData() -> Dictionary<String,AnyObject> {
        return metaDataDict
    }

    override func name(_ name: String) {
        self.name = name
    }

    override func startObject() {
        collectProperties = name == "metaData"
    }

    override func endObject() {
        if collectProperties {
            collectProperties = false
            cancel = true
        }
    }

    override func stringValue(_ value: String){
        if collectProperties {
            metaDataDict[name!] = value as AnyObject
        }
    }
    override func numberValue(_ value: NSNumber){
        if collectProperties {
            metaDataDict[name!] = value
        }
    }

    override func shouldCancelReadingTheJson() -> Bool {
        return cancel;
    }
}

// MARK: - Sample Output JSON Handler

/// JsonProtocolHandler that reads every HealthKitSampletype from the json stream
public class SampleOutputJsonHandler: JsonHandlerProtocol {

    class SampleContext : CustomStringConvertible {

        let type: JsonContextType
        var parent: SampleContext?
        var dict:Dictionary<String, AnyObject> = [:]
        var name:String? = nil
        var childs : [SampleContext] = []

        var description: String {
            return "name:\(name) type:\(type) dict:\(dict) childs:\(childs)"
        }

        public init(parent: SampleContext? ,type: JsonContextType){
            self.type = type
            self.parent = parent
        }

        func put(_ key:String, value: AnyObject?) {
            dict[key] = value
        }

        func createArrayContext(_ name: String) -> SampleContext {
            let sc = SampleContext(parent: self, type: .array)
            sc.name = name
            childs.append(sc)
            return sc
        }

        func createObjectContext() -> SampleContext {
            let sc = SampleContext(parent: self, type: .object)
            childs.append(sc)
            return sc
        }

        func getStructureAsDict() -> AnyObject {

            if type == .array {
                var result:[AnyObject] = []
                for child in childs {
                    result.append(child.getStructureAsDict())
                }
                return result as AnyObject;
            }

            var resultDict = dict
            for child in childs {
                if child.type == .array {
                    resultDict[child.name!] =  child.getStructureAsDict() as AnyObject?
                }
            }

            return resultDict as AnyObject
        }
    }

    internal func printWithLevel(_ level:Int, string:String){
        var outString = "\(level)"
        for i in 0 ..< level {
            outString += " "
        }
        outString += string
        AppLogger.general.debug("JSON handler output", metadata: ["level": "\(level)", "content": "\(outString)"])
    }

    /// callback for every found HealthKitSample
    let onSample : (_ sample: AnyObject, _ typeName:String) -> Void
    /// save the lastname to decide what is a sample and what is the name of a value
    var lastName = ""
    /// a samplecontext - created for every new sample
    var sampleContext: SampleContext? = nil
    /// the level in the json file
    var level = 0
    /// the healthkit sample type that is currently processed
    var hkTypeName: String? = nil

    public init(onSample: @escaping (_ sample: AnyObject, _ typeName:String) -> Void) {
        self.onSample = onSample
    }

    public func name(_ name: String) {
        lastName = name
    }

    public func startArray() {
        level += 1
        if level == 2 && lastName.hasPrefix("HK") {
            hkTypeName = lastName
        }

        if level > 3 {
            sampleContext = sampleContext!.createArrayContext(lastName)
        }
    }

    public func endArray() {
        if level == 2 {
            hkTypeName = nil
        }
        level -= 1

        sampleContext = sampleContext == nil ? nil : sampleContext!.parent
    }

    public func startObject() {
        level += 1

        if level == 3 {
            // a new HKSample starts
            sampleContext = SampleContext(parent: nil, type: .object)
            sampleContext?.name = hkTypeName
        }

        if level > 3 {
             sampleContext = sampleContext!.createObjectContext()
        }
    }

    public func endObject() {
        if level == 3 {
            // the HKSample ends
            onSample(sampleContext!.getStructureAsDict(), hkTypeName!)
            sampleContext = nil
        }
        sampleContext = sampleContext == nil ? nil : sampleContext!.parent
        level -= 1
    }

    public func stringValue(_ value: String){
        if sampleContext != nil {
            sampleContext!.put(lastName, value:value as AnyObject)
        }
    }

    public func boolValue(_ value: Bool){
        if sampleContext != nil {
            sampleContext!.put(lastName, value:value as AnyObject)
        }
    }

    public func numberValue(_ value: NSNumber){
        if sampleContext != nil {
            sampleContext!.put(lastName, value:value)
        }
    }

    public func nullValue(){
        if sampleContext != nil {
            sampleContext!.put(lastName, value:nil)
        }
    }

    public func shouldCancelReadingTheJson() -> Bool {
        return false
    }
}

