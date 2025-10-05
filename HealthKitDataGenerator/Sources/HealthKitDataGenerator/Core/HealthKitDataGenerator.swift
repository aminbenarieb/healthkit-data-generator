import Foundation
import HealthKit

/// Main class for generating and populating HealthKit data
final public class HealthKitDataGenerator {

    private let healthStore: HKHealthStore
    
    public init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }
    
    /// Generates and populates HealthKit store with sample data
    /// - Parameters:
    ///   - samplesTypes: Set of sample types to populate
    ///   - numberOfDays: Number of days to generate data for (default: 7)
    ///   - includeBasalCalories: Whether to include basal calorie data (default: true)
    public func generateAndPopulate(samplesTypes: Set<HKSampleType>, numberOfDays: Int = 7, includeBasalCalories: Bool = true) throws {
        let generatedSamples = SampleDataGenerator.generateSamples(numberOfDays, includeBasalCalories: includeBasalCalories)
        try populate(samplesTypes: samplesTypes, generatedSamples: generatedSamples)
    }
        
    /// Populates HealthKit store with generated samples
    /// - Parameters:
    ///   - samplesTypes: Set of sample types to populate
    ///   - generatedSamples: Dictionary containing generated sample data
    public func populate(samplesTypes: Set<HKSampleType>, generatedSamples: [String: Any]) throws {
        let resultJson = try JSONSerialization.data(withJSONObject: generatedSamples,
                                                    options: .withoutEscapingSlashes)
        let resultString = String(data: resultJson, encoding: .utf8)!

        var lastSampleType = ""
        importSamples(text: resultString) { (sample) in
            guard samplesTypes.contains(sample.sampleType) else {
                print("HealthKitDataGenerator: skipped \(sample.sampleType)")
                return
            }
            if lastSampleType != String(describing: sample.sampleType) {
                lastSampleType = String(describing: sample.sampleType)
                print("HealthKitDataGenerator: importing \(lastSampleType)")
            }

            self.healthStore.save(sample, withCompletion: { (success, error: Error?) in
                if let error = error {
                    print("HealthKitDataGenerator: \(sample.sampleType) - ", error.localizedDescription)
                }
                else {
                    print("HealthKitDataGenerator: \(sample.sampleType) - ", success)
                }
            })
        }
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
}
