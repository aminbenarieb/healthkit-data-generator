import Foundation
import Logging

/// Logging wrapper for HealthKitDataGenerator package using swift-log
/// Follows Apple's best practices for structured logging
public enum AppLogger {
    
    // MARK: - Package Loggers (SPM)
    
    private static let packageSubsystem = "com.welltory.healthkit-data-generator.package"
    
    /// Logger for data generation operations
    public static let generation = Logger(label: "\(packageSubsystem).generation")
    
    /// Logger for data import operations
    public static let dataImport = Logger(label: "\(packageSubsystem).import")
    
    /// Logger for data export operations
    public static let dataExport = Logger(label: "\(packageSubsystem).export")
    
    /// Logger for validation operations
    public static let validation = Logger(label: "\(packageSubsystem).validation")
    
    /// Logger for JSON parsing and LLM integration
    public static let llm = Logger(label: "\(packageSubsystem).llm")
    
    /// Logger for HealthKit store operations
    public static let healthKit = Logger(label: "\(packageSubsystem).healthkit")
    
    /// Logger for profile operations
    public static let profile = Logger(label: "\(packageSubsystem).profile")
    
    /// Logger for general operations
    public static let general = Logger(label: "\(packageSubsystem).general")
    
    // MARK: - Bootstrap
    
    /// Bootstrap the logging system with a specific log handler
    /// Call this once at app startup
    public static func bootstrap(logLevel: Logger.Level = .info) {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = logLevel
            return handler
        }
    }
}

// MARK: - App Loggers (Separate Subsystem)

/// Logging for the iOS app (separate from package)
public enum AppUILogger {
    
    private static let appSubsystem = "com.welltory.healthkit-data-generator.app"
    
    /// Logger for UI operations
    public static let ui = Logger(label: "\(appSubsystem).ui")
    
    /// Logger for app lifecycle
    public static let lifecycle = Logger(label: "\(appSubsystem).lifecycle")
    
    /// Logger for user actions
    public static let userAction = Logger(label: "\(appSubsystem).user-action")
    
    /// Logger for HealthKit authorization
    public static let authorization = Logger(label: "\(appSubsystem).authorization")
}

// MARK: - Logging Helpers

extension Logger {
    /// Log generation start
    public func logGenerationStart(days: Int, profile: String) {
        self.info("🚀 Starting generation", metadata: [
            "days": "\(days)",
            "profile": "\(profile)"
        ])
    }
    
    /// Log generation complete
    public func logGenerationComplete(days: Int, samplesGenerated: Int) {
        self.info("✅ Generation complete", metadata: [
            "days": "\(days)",
            "samples": "\(samplesGenerated)"
        ])
    }
    
    /// Log generation error
    public func logGenerationError(_ error: Error) {
        self.error("❌ Generation failed", metadata: [
            "error": "\(error.localizedDescription)"
        ])
    }
    
    /// Log import start
    public func logImportStart(source: String) {
        self.info("📥 Starting import", metadata: [
            "source": "\(source)"
        ])
    }
    
    /// Log import complete
    public func logImportComplete(samplesImported: Int) {
        self.info("✅ Import complete", metadata: [
            "samples": "\(samplesImported)"
        ])
    }
    
    /// Log validation result
    public func logValidation(isValid: Bool, message: String = "") {
        if isValid {
            self.info("✅ Validation passed", metadata: message.isEmpty ? [:] : ["message": "\(message)"])
        } else {
            self.warning("⚠️ Validation failed", metadata: message.isEmpty ? [:] : ["message": "\(message)"])
        }
    }
    
    /// Log metric generation
    public func logMetric(metric: String, count: Int, date: Date) {
        self.debug("📊 Generated metric", metadata: [
            "metric": "\(metric)",
            "count": "\(count)",
            "date": "\(date.formatted())"
        ])
    }
    
    /// Log HealthKit save
    public func logHealthKitSave(sampleType: String, success: Bool) {
        if success {
            self.debug("💾 Saved to HealthKit", metadata: ["type": "\(sampleType)"])
        } else {
            self.warning("⚠️ Failed to save", metadata: ["type": "\(sampleType)"])
        }
    }
}

// MARK: - Log File Export

extension AppLogger {
    /// Export logs to a file
    /// Note: swift-log doesn't provide built-in log retrieval
    /// You'll need to configure a file-based log handler for this to work
    public static func configureFileLogging(logDirectory: URL) throws {
        let packageLogFile = logDirectory.appendingPathComponent("package.log")
        
        LoggingSystem.bootstrap { label in
            let fileHandler = try? FileLogHandler(label: label, localFile: packageLogFile)
            return fileHandler ?? StreamLogHandler.standardOutput(label: label)
        }
    }
}

// MARK: - File Log Handler

/// Simple file-based log handler
struct FileLogHandler: LogHandler {
    let label: String
    let fileHandle: FileHandle
    
    var logLevel: Logger.Level = .info
    var metadata: Logger.Metadata = [:]
    
    init(label: String, localFile: URL) throws {
        self.label = label
        
        // Create file if it doesn't exist
        if !FileManager.default.fileExists(atPath: localFile.path) {
            FileManager.default.createFile(atPath: localFile.path, contents: nil)
        }
        
        self.fileHandle = try FileHandle(forWritingTo: localFile)
        self.fileHandle.seekToEndOfFile()
    }
    
    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }
    
    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let mergedMetadata = self.metadata.merging(metadata ?? [:]) { $1 }
        let metadataString = mergedMetadata.isEmpty ? "" : " \(mergedMetadata)"
        
        let logLine = "[\(timestamp)] [\(level)] [\(label)] \(message)\(metadataString)\n"
        
        if let data = logLine.data(using: .utf8) {
            fileHandle.write(data)
        }
    }
}
