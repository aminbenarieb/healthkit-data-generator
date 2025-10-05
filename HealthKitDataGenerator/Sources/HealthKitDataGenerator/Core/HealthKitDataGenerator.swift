import Foundation
import HealthKit
import Logging

/// Main class for generating and populating HealthKit data
final public class HealthKitDataGenerator {

    private let healthStore: HKHealthStore
    private let logger = AppLogger.generation
    
    public init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }
    
    /// Generates and populates HealthKit store with sample data using configuration
    /// - Parameters:
    ///   - samplesTypes: Set of sample types to populate
    ///   - config: Configuration specifying profile, date range, and metrics
    public func generateAndPopulate(samplesTypes: Set<HKSampleType>, config: SampleGenerationConfig) throws {
        logger.logGenerationStart(days: config.dateRange.numberOfDays, profile: config.profile.name)
        
        let generatedSamples = SampleDataGenerator.generateSamples(config: config)
        
        let totalSamples = generatedSamples.values.compactMap { $0 as? [[String: Any]] }.reduce(0) { $0 + $1.count }
        logger.info("Generated samples", metadata: ["total": "\(totalSamples)", "types": "\(generatedSamples.keys.count)"])
        
        try populate(samplesTypes: samplesTypes, generatedSamples: generatedSamples)
        
        logger.logGenerationComplete(days: config.dateRange.numberOfDays, samplesGenerated: totalSamples)
    }
    
    /// Generates samples based on configuration without populating HealthKit
    /// - Parameter config: Configuration specifying profile, date range, and metrics
    /// - Returns: Dictionary containing generated sample data
    public func generate(config: SampleGenerationConfig) -> [String: Any] {
        return SampleDataGenerator.generateSamples(config: config)
    }
    
    /// Imports data from LLM-generated JSON
    /// - Parameter jsonString: JSON string conforming to LLM schema
    public func importFromLLMJSON(_ jsonString: String) throws {
        AppLogger.llm.logImportStart(source: "LLM JSON")
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let llmData = try decoder.decode(LLMGenerationData.self, from: data)
        AppLogger.llm.info("Decoded LLM data", metadata: ["version": "\(llmData.schemaVersion)"])
        
        // If generation_config is provided, generate samples
        if let config = llmData.generationConfig {
            AppLogger.llm.info("Using generation config", metadata: ["profile": "\(config.profile.name)"])
            let samples = SampleDataGenerator.generateSamples(config: config)
            let allTypes = HealthKitConstants.authorizationWriteTypes()
            try populate(samplesTypes: allTypes, generatedSamples: samples)
        }
        
        // If direct samples are provided, import them
        if let directSamples = llmData.samples {
            AppLogger.llm.info("Importing direct samples", metadata: ["count": "\(directSamples.count)"])
            try importDirectSamples(directSamples)
        }
        
        AppLogger.llm.logImportComplete(samplesImported: 0) // TODO: track actual count
    }
    
    /// Validates LLM-generated JSON
    /// - Parameter jsonString: JSON string to validate
    /// - Returns: True if valid, throws error if invalid
    public func validateLLMJSON(_ jsonString: String) throws -> Bool {
        AppLogger.validation.info("Validating LLM JSON")
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let llmData = try decoder.decode(LLMGenerationData.self, from: data)
        
        // Validate schema version
        guard llmData.schemaVersion == "1.0" else {
            AppLogger.validation.error("Invalid schema version", metadata: ["version": "\(llmData.schemaVersion)"])
            throw LLMJSONError.unsupportedSchemaVersion(llmData.schemaVersion)
        }
        
        // Validate that at least one of config or samples is provided
        guard llmData.generationConfig != nil || llmData.samples != nil else {
            AppLogger.validation.error("Missing required fields")
            throw LLMJSONError.missingRequiredField("Either generation_config or samples must be provided")
        }
        
        // Validate config if provided
        if let config = llmData.generationConfig {
            try validateConfig(config)
        }
        
        AppLogger.validation.logValidation(isValid: true, message: "LLM JSON is valid")
        return true
    }
        
    /// Populates HealthKit store with generated samples
    /// - Parameters:
    ///   - samplesTypes: Set of sample types to populate
    ///   - generatedSamples: Dictionary containing generated sample data
    public func populate(samplesTypes: Set<HKSampleType>, generatedSamples: [String: Any]) throws {
        let resultJson = try JSONSerialization.data(withJSONObject: generatedSamples,
                                                    options: .withoutEscapingSlashes)
        let resultString = String(data: resultJson, encoding: .utf8)!

        AppLogger.healthKit.info("Starting to populate HealthKit", metadata: [
            "sampleTypes": "\(samplesTypes.count)",
            "metricTypes": "\(generatedSamples.keys.count)"
        ])
        
        var lastSampleType = ""
        var savedCount = 0
        var skippedCount = 0
        
        importSamples(text: resultString) { (sample) in
            let sampleDate = sample.startDate.formatted(date: .abbreviated, time: .omitted)
            
            guard samplesTypes.contains(sample.sampleType) else {
                skippedCount += 1
                AppLogger.healthKit.debug("Skipped sample type", metadata: [
                    "sampleType": "\(sample.sampleType)",
                    "date": "\(sampleDate)"
                ])
                return
            }
            
            if lastSampleType != String(describing: sample.sampleType) {
                lastSampleType = String(describing: sample.sampleType)
                AppLogger.healthKit.info("Importing sample type", metadata: [
                    "sampleType": "\(lastSampleType)",
                    "date": "\(sampleDate)"
                ])
            }

            self.healthStore.save(sample, withCompletion: { (success, error: Error?) in
                if let error = error {
                    AppLogger.healthKit.error("Failed to save sample", metadata: [
                        "sampleType": "\(sample.sampleType)",
                        "date": "\(sampleDate)",
                        "error": "\(error.localizedDescription)"
                    ])
                } else {
                    savedCount += 1
                    AppLogger.healthKit.debug("Saved sample", metadata: [
                        "sampleType": "\(sample.sampleType)",
                        "date": "\(sampleDate)"
                    ])
                }
            })
        }
        
        AppLogger.healthKit.info("Populate complete", metadata: [
            "saved": "\(savedCount)",
            "skipped": "\(skippedCount)"
        ])
    }

    // MARK: - Private Methods

    private func importSamples(text: String, onSample: @escaping (_ sample: HKSample) -> Void) {
        let sampleImportHandler: SampleOutputJsonHandler = SampleOutputJsonHandler { [weak self] (sampleDict: AnyObject, typeName: String) in
            guard let self else { return }
            
            if let creator: any SampleCreator = SampleCreatorRegistry.get(self.healthStore, typeName) {
                let sampleOpt: HKSample? = creator.createSample(sampleDict)
                if let sample = sampleOpt {
                    onSample(sample)
                }
            }
        }

        let tokenizer: JsonTokenizer = JsonTokenizer(jsonHandler: sampleImportHandler)
        tokenizer.tokenize(text)
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }
    
    // MARK: - LLM JSON Support
    
    private func importDirectSamples(_ samples: [[String: Any]]) throws {
        // Convert samples array to JSON string for import
        let jsonData = try JSONSerialization.data(withJSONObject: ["samples": samples], options: [])
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        importSamples(text: jsonString) { sample in
            self.healthStore.save(sample) { success, error in
                if let error = error {
                    AppLogger.healthKit.error("Failed to save sample", metadata: [
                        "error": "\(error.localizedDescription)",
                        "sampleType": "\(sample.sampleType)"
                    ])
                } else {
                    AppLogger.healthKit.debug("Saved sample", metadata: [
                        "sampleType": "\(sample.sampleType)"
                    ])
                }
            }
        }
    }
    
    private func validateConfig(_ config: SampleGenerationConfig) throws {
        let profile = config.profile
        
        // Validate heart rate ranges
        guard profile.restingHeartRateRange.lowerBound < profile.maxHeartRateRange.lowerBound else {
            throw LLMJSONError.physiologicallyImpossible("Resting heart rate must be lower than max heart rate")
        }
        
        // Validate sleep duration
        guard profile.sleepDurationRange.lowerBound >= 4.0 && profile.sleepDurationRange.upperBound <= 12.0 else {
            throw LLMJSONError.invalidValue("Sleep duration must be between 4.0 and 12.0 hours")
        }
        
        // Validate date range
        guard config.dateRange.startDate < config.dateRange.endDate else {
            throw LLMJSONError.invalidValue("Start date must be before end date")
        }
        
        // Validate energy multiplier
        guard profile.basalEnergyMultiplier >= 0.5 && profile.basalEnergyMultiplier <= 1.5 else {
            throw LLMJSONError.invalidValue("Basal energy multiplier must be between 0.5 and 1.5")
        }
    }
}

// MARK: - LLM JSON Types

/// Structure for LLM-generated JSON data
struct LLMGenerationData: Codable {
    let schemaVersion: String
    let generationConfig: SampleGenerationConfig?
    let samples: [[String: Any]]?
    
    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case generationConfig = "generation_config"
        case samples
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(String.self, forKey: .schemaVersion)
        generationConfig = try container.decodeIfPresent(SampleGenerationConfig.self, forKey: .generationConfig)
        
        // Decode samples as array of dictionaries
        if let samplesArray = try? container.decode([[String: AnyCodable]].self, forKey: .samples) {
            samples = samplesArray.map { dict in
                dict.mapValues { $0.value }
            }
        } else {
            samples = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encodeIfPresent(generationConfig, forKey: .generationConfig)
        
        if let samples = samples {
            let codableSamples = samples.map { dict in
                dict.mapValues { AnyCodable($0) }
            }
            try container.encode(codableSamples, forKey: .samples)
        }
    }
}

/// Helper for encoding/decoding Any values
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Unsupported type"))
        }
    }
}

// MARK: - LLM JSON Errors

enum LLMJSONError: Error, LocalizedError {
    case unsupportedSchemaVersion(String)
    case missingRequiredField(String)
    case invalidValue(String)
    case physiologicallyImpossible(String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedSchemaVersion(let version):
            return "Unsupported schema version: \(version). Expected 1.0"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .invalidValue(let message):
            return "Invalid value: \(message)"
        case .physiologicallyImpossible(let message):
            return "Physiologically impossible: \(message)"
        }
    }
}
