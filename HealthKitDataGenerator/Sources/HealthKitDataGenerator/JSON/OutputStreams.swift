
import Foundation

// MARK: - Output Stream Protocol

/// Replacement for NSOutputStream. What's wrong with NSOutputStream? It is an abstract class by definition - but i think
/// it should be a protocol. So we can easily create different implementations like MemOutputStream or FileOutputStream and add
/// Buffer mechanisms.
protocol OutputStream {
    var outputStream: Foundation.OutputStream { get }
    func open()
    func close()
    func isOpen() -> Bool
    func write(_ theString: String)
    func getDataAsString() -> String
}

// MARK: - Output Stream Extension

/// Abstract Class implementation of the output stream
extension OutputStream {

    fileprivate func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        return self.outputStream.write(buffer, maxLength: len)
    }

    fileprivate func stringToData(_ theString: String) -> Data {
        return theString.data(using: String.Encoding.utf8)!
    }

    func write(_ theString: String) {
        let data = stringToData(theString)
        write((data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count), maxLength: data.count)
    }

    func open(){
        outputStream.open()
    }

    func close() {
        outputStream.close()
    }

    func isOpen() -> Bool {
        return outputStream.streamStatus == Stream.Status.open
    }
}

// MARK: - Memory Output Stream

/// A memory output stream. Caution: the resulting json string must fit in the device mem!
internal class MemOutputStream : OutputStream {

    var outputStream: Foundation.OutputStream

    init(){
        self.outputStream = Foundation.OutputStream.toMemory()
    }

    func getDataAsString() -> String {
        close()
        let data = outputStream.property(forKey: Stream.PropertyKey.dataWrittenToMemoryStreamKey)

        return NSString(data: data as! Data, encoding: String.Encoding.utf8.rawValue) as! String
    }
}

// MARK: - File Output Stream

/// A file output stream. The stream will overwrite any existing file content.
internal class FileOutputStream : OutputStream {
    var outputStream: Foundation.OutputStream
    var fileAtPath: String

    init(fileAtPath: String){
        self.fileAtPath = fileAtPath
        self.outputStream =  Foundation.OutputStream.init(toFileAtPath: fileAtPath, append: false)!
    }

    func getDataAsString() -> String {
        close()
        return try! NSString(contentsOfFile: fileAtPath, encoding: String.Encoding.utf8.rawValue) as String
    }
}

